-- single source of truth for remote.json (read-only snapshot from GitHub)
-- and state.json (local draft: comments, read-marks). both live in
-- $PR_REVIEW_DIR, set by pr-review.sh before nvim starts.
local git = require("pr_review.git")

local M = {}

local dir = vim.env.PR_REVIEW_DIR
if not dir then
    vim.notify("pr_review: $PR_REVIEW_DIR not set, state will not persist", vim.log.levels.WARN)
end

local remote_path = dir and (dir .. "/remote.json")
local state_path = dir and (dir .. "/state.json")

---@param path string?
---@return any|nil
local function read_json(path)
    if not path then
        return nil
    end
    local f = io.open(path, "r")
    if not f then
        return nil
    end
    local content = f:read("*a")
    f:close()
    if content == "" then
        return nil
    end
    local ok, decoded = pcall(vim.json.decode, content)
    if not ok then
        return nil
    end
    return decoded
end

---@param path string?
---@param tbl any
local function write_json(path, tbl)
    if not path then
        return
    end
    local f, err = io.open(path, "w")
    if not f then
        error(string.format("pr_review: failed to write %s: %s", path, err or "unknown error"))
    end
    f:write(vim.json.encode(tbl))
    f:close()
end

local default_draft = {
    session_head_sha = nil,
    -- nil means "no decision chosen yet" -- submit.lua treats that as
    -- "leave as a pending draft on GitHub" rather than defaulting to a
    -- finalized COMMENT review
    review_event = nil,
    review_body = "",
    draft_comments = {},
    read_files = {},
    read_commits = {},
}

M.remote = read_json(remote_path) or {}
M.draft = vim.tbl_deep_extend("force", default_draft, read_json(state_path) or {})

function M.save()
    write_json(state_path, M.draft)
end

function M.save_remote()
    write_json(remote_path, M.remote)
end

---Starting from `from` (a sha already known to be covered -- typically a
---file's own watermark, or the PR base if it has none), returns the
---furthest point additionally covered by commits marked read contiguously
---after `from`. Stops at the first gap. Returns `from` itself if nothing
---extends past it (including if `from` isn't found in the commit list at
---all, e.g. after a force-push).
---@param from string
---@return string
function M.commits_read_through(from)
    local base = M.remote.pr and M.remote.pr.base_sha
    local counting = from == base
    local through = from
    for _, c in ipairs(M.remote.commits or {}) do
        if counting then
            if not M.is_commit_read(c.sha) then
                break
            end
            through = c.sha
        elseif c.sha == from then
            counting = true
        end
    end
    return through
end

---The furthest point `path` is covered through: its own explicit watermark
---(or the PR base, if never marked read), extended by any commits marked
---read contiguously after that point.
---@param path string
---@return string|nil
function M.effective_watermark(path)
    local existing = M.draft.read_files[path]
    local base = existing and existing.at_sha or (M.remote.pr and M.remote.pr.base_sha)
    if not base then
        return nil
    end
    return M.commits_read_through(base)
end

---Whether marking `path` read at `right_rev`, having viewed the diff from
---`left_rev`, actually covers everything since path's effective watermark
---(see above). Rejects marks that would silently skip over unseen changes.
---`left_rev` is allowed to start at or before that watermark (i.e. be an
---ancestor of it) -- covering more history than strictly necessary is
---harmless, only gaps aren't.
---@param path string
---@param left_rev string
---@return boolean ok, string? err
local function can_mark_file_read(path, left_rev)
    local required_left = M.effective_watermark(path)
    if not required_left then
        return false, "no baseline to compare against (PR not fetched yet?)"
    end

    if left_rev ~= required_left and not git.is_ancestor(left_rev, required_left) then
        return false,
            string.format(
                "diff starts at %s, but %s's effective watermark is %s -- view the full range first",
                left_rev:sub(1, 8),
                path,
                required_left:sub(1, 8)
            )
    end
    return true, nil
end

---After a file's watermark advances, checks whether any not-yet-read
---commits are now fully covered by file-level review (every file that
---commit touches has an effective watermark reaching at least that
---commit), and marks those commits read too. This is a one-shot mutation
---triggered by the file write, not a live derivation inside
---is_commit_read() -- doing it there would make is_commit_read and
---effective_watermark call into each other with no cycle protection.
---A single forward pass (oldest commit first) is enough to reach a fixed
---point, since promoting an earlier commit in the loop is immediately
---visible (via is_commit_read) to the later commits checked afterward.
local function promote_fully_covered_commits()
    for _, c in ipairs(M.remote.commits or {}) do
        if not M.is_commit_read(c.sha) then
            local touched = git.changed_files(c.sha .. "^", c.sha) or {}
            local all_covered = #touched > 0
            for _, path in ipairs(touched) do
                local through = M.effective_watermark(path)
                if not (through and (through == c.sha or git.is_ancestor(c.sha, through))) then
                    all_covered = false
                    break
                end
            end
            if all_covered then
                -- tagged "implicit", not via mark_commit_read, so it stays
                -- distinguishable from a direct user mark and can later be
                -- reverted by demote_uncovered_commits
                M.draft.read_commits[c.sha] = "implicit"
            end
        end
    end
end

---@param path string
---@param left_rev string revision the diff you just viewed started from
---@param right_rev string revision the diff you just viewed ended at; becomes
---  the new watermark
---@return boolean ok, string? err
function M.mark_file_read(path, left_rev, right_rev)
    local ok, err = can_mark_file_read(path, left_rev)
    if not ok then
        return false, err
    end

    -- never let a read walk the watermark backwards, regardless of what
    -- can_mark_file_read (which only validates left_rev) would otherwise
    -- allow
    local existing = M.draft.read_files[path]
    if existing and right_rev ~= existing.at_sha and not git.is_ancestor(existing.at_sha, right_rev) then
        return false,
            string.format(
                "would move %s's watermark backwards (currently %s, tried %s)",
                path,
                existing.at_sha:sub(1, 8),
                right_rev:sub(1, 8)
            )
    end

    M.draft.read_files[path] = { at_sha = right_rev }
    promote_fully_covered_commits()
    M.save()
    return true, nil
end

---Inverse of promote_fully_covered_commits: after a file's watermark
---retreats, checks whether any commit that was only ever *implicitly*
---promoted (never explicitly marked by the user) is no longer justified,
---and reverts it to unread. Explicit marks are left alone -- they're a
---durable assertion independent of file-level bookkeeping, per
---mark_commit_read's doc comment.
local function demote_uncovered_commits()
    for _, c in ipairs(M.remote.commits or {}) do
        if M.draft.read_commits[c.sha] == "implicit" then
            -- clear first: effective_watermark's commit-coverage walk goes
            -- through is_commit_read, which would otherwise see this exact
            -- tag and self-confirm ("c is covered because c is marked
            -- read") instead of answering honestly
            M.draft.read_commits[c.sha] = nil

            local touched = git.changed_files(c.sha .. "^", c.sha) or {}
            local all_covered = #touched > 0
            for _, path in ipairs(touched) do
                local through = M.effective_watermark(path)
                if not (through and (through == c.sha or git.is_ancestor(c.sha, through))) then
                    all_covered = false
                    break
                end
            end
            if all_covered then
                M.draft.read_commits[c.sha] = "implicit" -- still justified, restore
            end
            -- else: leave cleared, genuinely demoted
        end
    end
end

---@param path string
---@param left_rev string? retreat the watermark to this point instead of
---  clearing it entirely; omit to fully clear (unread from scratch)
---@return boolean ok, string? err
function M.mark_file_unread(path, left_rev)
    if left_rev then
        -- inverse of mark_file_read's guard: never let an unmark walk the
        -- watermark forwards
        local existing = M.draft.read_files[path]
        if existing and left_rev ~= existing.at_sha and not git.is_ancestor(left_rev, existing.at_sha) then
            return false,
                string.format(
                    "would move %s's watermark forward (currently %s, tried %s)",
                    path,
                    existing.at_sha:sub(1, 8),
                    left_rev:sub(1, 8)
                )
        end
        M.draft.read_files[path] = { at_sha = left_rev }
    else
        M.draft.read_files[path] = nil
    end
    demote_uncovered_commits()
    M.save()
    return true, nil
end

---Marks a commit read as a direct, durable user action. Always tags it
---"explicit" (even upgrading a prior "implicit" tag) -- an explicit mark is
---an independent assertion that survives file-level bookkeeping changes,
---unlike commits promoted automatically by mark_file_read.
---@param sha string
function M.mark_commit_read(sha)
    M.draft.read_commits[sha] = "explicit"
    M.save()
end

---@param sha string
function M.mark_commit_unread(sha)
    M.draft.read_commits[sha] = nil
    M.save()
end

---@param sha string
---@return boolean
function M.is_commit_read(sha)
    return M.draft.read_commits[sha] ~= nil
end

---`line`/`side` are the *end* of the comment's range (GitHub's own
---convention); `start_line` is optional and marks a multi-line comment,
---always on the same side as `line`. `commit_id` is the diff's right-hand
---revision at the moment the comment was drafted -- not necessarily the
---PR's current head, e.g. if drafted against a sticky sub-range -- so
---submit.lua can anchor each comment to the commit it was actually written
---against, rather than one commit for the whole batch.
---@param comment { path: string, line: integer, side: "LEFT"|"RIGHT", body: string, reply_to: integer?, start_line: integer?, commit_id: string }
function M.add_draft_comment(comment)
    table.insert(M.draft.draft_comments, comment)
    M.save()
end

---@param index integer
---@param comment table
function M.update_draft_comment(index, comment)
    M.draft.draft_comments[index] = comment
    M.save()
end

---@param index integer
function M.remove_draft_comment(index)
    table.remove(M.draft.draft_comments, index)
    M.save()
end

function M.clear_draft_comments()
    M.draft.draft_comments = {}
    M.save()
end

return M
