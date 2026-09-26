-- scratch buffer for composing a single draft comment/reply. saving adds it
-- to state.draft.draft_comments; nothing touches the network here.
local state = require("pr_review.state")

local M = {}

---@param opts { path: string, line: integer, side: "LEFT"|"RIGHT", reply_to: integer?, start_line: integer?, commit_id: string, existing_index: integer?, existing_body: string? }
function M.open(opts)
    vim.cmd("belowright 10split")
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    vim.bo[bufnr].filetype = "prreview"
    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].bufhidden = "wipe"
    pcall(vim.api.nvim_buf_set_name, bufnr, string.format("pr-review://comment/%s:%d", opts.path, opts.line))

    local loc = opts.start_line and string.format("%s:%d-%d", opts.path, opts.start_line, opts.line)
        or string.format("%s:%d", opts.path, opts.line)
    local action = opts.existing_index and "editing" or (opts.reply_to and ("replying to comment #" .. opts.reply_to)) or "commenting"
    local header = string.format(
        "# %s on %s (%s) -- write below, <localleader>s to save, q to cancel",
        action,
        loc,
        opts.side
    )

    local body_lines = opts.existing_body and vim.split(opts.existing_body, "\n", { plain = true }) or { "" }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.list_extend({ header }, body_lines))
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    vim.cmd.startinsert()

    local function save()
        local lines = vim.api.nvim_buf_get_lines(bufnr, 1, -1, false)
        local body = vim.trim(table.concat(lines, "\n"))
        if body == "" then
            vim.notify("pr_review: empty comment, not saving", vim.log.levels.WARN)
            return
        end
        local comment = {
            path = opts.path,
            line = opts.line,
            side = opts.side,
            body = body,
            reply_to = opts.reply_to,
            start_line = opts.start_line,
            commit_id = opts.commit_id,
        }
        if opts.existing_index then
            state.update_draft_comment(opts.existing_index, comment)
        else
            state.add_draft_comment(comment)
        end
        vim.notify("pr_review: comment drafted locally (not yet submitted)")
        vim.cmd.close()
    end

    vim.keymap.set("n", "<localleader>s", save, { buffer = bufnr, desc = "save draft comment" })
    vim.keymap.set("n", "q", function()
        vim.cmd.close()
    end, { buffer = bufnr, desc = "cancel comment" })
end

return M
