-- pr-review: local-first github PR review workflow.
-- activated only when $PR_REVIEW_DIR is set, see plugin/pr_review.lua.
local M = {}

---@return table? diff info { side, left_rev, right_rev, path } if the
---current buffer is a diff pane opened by pr_review.diff, else nil
local function diff_info_here()
    return vim.b.pr_review_diff
end

local function mark_read_here()
    local info = diff_info_here()
    if not info then
        vim.notify("pr_review: not in a diff buffer", vim.log.levels.WARN)
        return
    end
    local ok, err = require("pr_review.state").mark_file_read(info.path, info.left_rev, info.right_rev)
    if ok then
        vim.notify("pr_review: marked read through " .. info.right_rev:sub(1, 8))
    else
        vim.notify("pr_review: " .. err, vim.log.levels.WARN)
    end
end

---@param reply_to integer?
---@param cmd_opts table? nvim_create_user_command's opts, for range info
local function comment_at_cursor(reply_to, cmd_opts)
    local info = diff_info_here()
    if not info then
        vim.notify("pr_review: not in a diff buffer", vim.log.levels.WARN)
        return
    end

    local line1, line2
    if cmd_opts and cmd_opts.range and cmd_opts.range > 0 then
        line1, line2 = cmd_opts.line1, cmd_opts.line2
    else
        local cur = vim.api.nvim_win_get_cursor(0)[1]
        line1, line2 = cur, cur
    end

    -- anchor to whichever commit actually last touched this line, not just
    -- the diff's edge -- for a narrowed sub-range, the edge may not be
    -- responsible for this line at all (e.g. an unchanged context line).
    -- blame the LEFT side under its own historical name (left_path), since
    -- info.path is always the file's *current* name and won't exist yet at
    -- left_rev if the file was renamed later in the range.
    local git = require("pr_review.git")
    local side_rev = info.side == "RIGHT" and info.right_rev or info.left_rev
    local blame_path = info.side == "RIGHT" and info.path or info.left_path
    local commit_id = git.blame_commit(side_rev, blame_path, line2) or side_rev

    -- blame isn't range-aware: if this line hasn't changed within the
    -- range you're currently viewing, it can walk further back than
    -- intended -- even past the PR's own base into unrelated mainline
    -- history, which GitHub's review API would reject as an invalid
    -- commit_id. clamp back up to the left edge of the diff you were
    -- actually looking at (which is base_sha itself for the default full
    -- PR range, or a later commit if you're browsing a narrowed sub-range).
    if commit_id ~= info.left_rev and git.is_ancestor(commit_id, info.left_rev) then
        commit_id = info.left_rev
    end

    -- resolve the path as it actually existed at commit_id, which may
    -- differ from info.path (always the file's current/right-side name)
    -- if a rename happened somewhere between commit_id and there. keeps
    -- (commit_id, path) mutually consistent regardless of exactly how
    -- GitHub validates that pairing -- we're never claiming a name that
    -- didn't exist at the commit we're anchoring to.
    local submit_path = git.find_rename(commit_id, info.right_rev, info.path) or info.path

    require("pr_review.comment").open({
        path = submit_path,
        line = line2,
        start_line = line1 ~= line2 and line1 or nil,
        side = info.side,
        reply_to = reply_to,
        commit_id = commit_id,
    })
end

---@return table? thread matching the cursor's current path/line/side
local function thread_at_cursor()
    local info = diff_info_here()
    if not info then
        return nil
    end
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local state = require("pr_review.state")
    for _, thread in ipairs(state.remote.threads or {}) do
        if thread.path == info.path and thread.line == line and thread.side == info.side then
            return thread
        end
    end
end

local function show_threads()
    local state = require("pr_review.state")
    local info = diff_info_here()

    local threads = {}
    for _, t in ipairs(state.remote.threads or {}) do
        if not info or t.path == info.path then
            table.insert(threads, t)
        end
    end

    local drafts = {}
    for _, c in ipairs(state.draft.draft_comments) do
        if not info or c.path == info.path then
            table.insert(drafts, c)
        end
    end

    if #threads == 0 and #drafts == 0 then
        vim.notify("pr_review: no threads or drafts" .. (info and " for this file" or ""))
        return
    end

    local lines = {}
    for _, t in ipairs(threads) do
        table.insert(lines, string.format("%s:%d", t.path, t.line))
        for _, c in ipairs(t.comments) do
            table.insert(lines, string.format("  %s: %s", c.user or "?", (c.body or ""):gsub("\n", " ")))
        end
        table.insert(lines, "")
    end

    if #drafts > 0 then
        table.insert(lines, "-- drafts (not yet submitted) --")
        for _, c in ipairs(drafts) do
            local loc = c.start_line and string.format("%s:%d-%d", c.path, c.start_line, c.line)
                or string.format("%s:%d", c.path, c.line)
            local kind = c.reply_to and string.format("reply to #%d", c.reply_to) or c.side
            table.insert(lines, string.format("%s (%s)", loc, kind))
            table.insert(lines, "  " .. (c.body or ""):gsub("\n", " "))
            table.insert(lines, "")
        end
    end

    vim.cmd("botright new")
    local bufnr = vim.api.nvim_get_current_buf()
    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].bufhidden = "wipe"
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].modifiable = false
end

---Prompts for the review decision (and an optional summary) before
---handing off to pr_review.submit. Defaults to leaving the review as a
---pending draft -- inspectable on GitHub's web UI, not finalized -- rather
---than immediately publishing anything.
local function submit_review()
    local choice = vim.fn.confirm("Review decision:", "&Draft (leave pending)\n&Comment\n&Approve\n&Request Changes", 1)
    if choice == 0 then
        return
    end

    local state = require("pr_review.state")
    -- choice 1 (Draft) leaves review_event nil; see submit.lua for what that means
    state.draft.review_event = ({ [2] = "COMMENT", [3] = "APPROVE", [4] = "REQUEST_CHANGES" })[choice]
    state.draft.review_body = vim.fn.input("Review summary (optional): ")
    state.save()

    local sok, serr = require("pr_review.submit").run()
    if sok then
        vim.notify("pr_review: review submitted" .. (choice == 1 and " as a pending draft" or ""))
    else
        vim.notify("pr_review: " .. serr, vim.log.levels.WARN)
    end
end

function M.setup()
    local fetch = require("pr_review.fetch")

    local ok, err = fetch.run()
    if not ok then
        vim.notify("pr_review: " .. err, vim.log.levels.ERROR)
    end

    vim.api.nvim_create_user_command("PrReviewFiles", function()
        require("pr_review.pickers.files").open()
    end, {})

    vim.api.nvim_create_user_command("PrReviewCommits", function()
        require("pr_review.pickers.commits").open()
    end, {})

    vim.api.nvim_create_user_command("PrReviewComment", function(cmd_opts)
        comment_at_cursor(nil, cmd_opts)
    end, { range = true })

    vim.api.nvim_create_user_command("PrReviewReply", function()
        local thread = thread_at_cursor()
        if not thread then
            vim.notify("pr_review: no thread under cursor", vim.log.levels.WARN)
            return
        end
        comment_at_cursor(thread.root_id)
    end, {})

    vim.api.nvim_create_user_command("PrReviewThreads", show_threads, {})

    vim.api.nvim_create_user_command("PrReviewDrafts", function()
        require("pr_review.pickers.drafts").open()
    end, {})

    vim.api.nvim_create_user_command("PrReviewMarkRead", mark_read_here, {})

    vim.api.nvim_create_user_command("PrReviewRangeReset", function()
        require("pr_review.range").clear()
        vim.notify("pr_review: back to full PR range")
    end, {})

    vim.api.nvim_create_user_command("PrReviewRefresh", function()
        local rok, rerr = fetch.run()
        if rok then
            vim.notify("pr_review: refreshed")
        else
            vim.notify("pr_review: " .. rerr, vim.log.levels.ERROR)
        end
    end, {})

    vim.api.nvim_create_user_command("PrReviewSubmit", submit_review, {})

    local maps = {
        { "<leader>rf", "PrReviewFiles",      "pr-review: files" },
        { "<leader>rc", "PrReviewCommits",    "pr-review: commits" },
        { "<leader>rn", "PrReviewComment",    "pr-review: comment" },
        { "<leader>rr", "PrReviewReply",      "pr-review: reply" },
        { "<leader>rt", "PrReviewThreads",    "pr-review: threads" },
        { "<leader>rd", "PrReviewDrafts",     "pr-review: drafts" },
        { "<leader>rv", "PrReviewMarkRead",   "pr-review: mark read" },
        { "<leader>rx", "PrReviewRangeReset", "pr-review: reset range" },
        { "<leader>rs", "PrReviewSubmit",     "pr-review: submit" },
        { "<leader>rR", "PrReviewRefresh",    "pr-review: refresh" },
    }
    for _, map in ipairs(maps) do
        vim.keymap.set("n", map[1], "<cmd>" .. map[2] .. "<CR>", { desc = map[3] })
    end

    -- visual-mode comment on the selected range: leading `:` auto-inserts
    -- '<,'> so PrReviewComment's range info is populated
    vim.keymap.set("v", "<leader>rn", ":PrReviewComment<CR>", { desc = "pr-review: comment on selection" })
end

return M
