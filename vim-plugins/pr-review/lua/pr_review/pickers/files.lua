-- fzf-lua picker for changed files, modeled on fzf-lua's own git_status
-- picker: a toggle action with reload=true keeps the list open and re-reads
-- live state instead of a persistent sidebar.
--
-- scoped to pr_review.range's currently focused commit range (full PR by
-- default, or a specific range selected via the commits picker).
local state = require("pr_review.state")
local diff = require("pr_review.diff")
local git = require("pr_review.git")
local range = require("pr_review.range")

local M = {}

---"read" for this range means path's effective watermark (own explicit
---mark, extended by any contiguous commit-level coverage past it) is at or
---beyond `right` -- not just an exact match, so being ahead (e.g. already
---read through head) while browsing an earlier sub-range still counts.
---
---Distinguishes *why* it's read: "x" means the file's own watermark
---covers it directly, so unmarking (right) will visibly change this icon.
---"c" means it's read only via commit-level coverage -- unmarking the file
---itself won't change this icon at all, since the coverage comes from
---read_commits, not read_files.
---@param path string
---@param right string
---@return string icon
local function icon_for(path, status, right)
    local own = state.draft.read_files[path]
    if own and (own.at_sha == right or git.is_ancestor(right, own.at_sha)) then
        return string.format("%s  ", status)
    end

    local through = state.effective_watermark(path)
    if through and (through == right or git.is_ancestor(right, through)) then
        return string.format("%s* ", status)
    end

    return string.format("  %s", status)
end

---@param left string
---@param right string
---@param fzf_cb fun(entry: string?)
local function get_contents(left, right, fzf_cb)
    local file_statuses = git.changed_file_statuses(left, right) or {}
    for _, fs in ipairs(file_statuses) do
        local path = fs.path
        local status = fs.status
        fzf_cb(string.format("%s %s", icon_for(path, status, right), path))
    end
    fzf_cb()
end

---@param entry string
---@return string
local function path_from_entry(entry)
    return entry:match("^...%s(.+)$")
end

function M.open()
    -- deferred: don't require fzf-lua until the picker actually opens.
    -- pr_review.pickers.files gets required unconditionally by things like
    -- pickers/commits.lua's default action, and eagerly requiring an
    -- optional runtime dependency at module-load time breaks in any
    -- context that doesn't already have fzf-lua on the runtimepath (e.g.
    -- a build-time nvim invocation with a stray $PR_REVIEW_DIR inherited).
    local fzf = require("fzf-lua")
    local left, right, is_full = range.current()

    fzf.fzf_exec(function(fzf_cb)
        get_contents(left, right, fzf_cb)
    end, {
        prompt = is_full and "PR Files> " or string.format("PR Files (%s..%s)> ", left:sub(1, 8), right:sub(1, 8)),
        fzf_opts = { ["--multi"] = true },
        actions = {
            ["default"] = function(selected)
                diff.open(left, right, path_from_entry(selected[1]))
            end,
            ["left"] = {
                fn = function(selected)
                    for _, entry in ipairs(selected) do
                        local path = path_from_entry(entry)
                        local ok, err = state.mark_file_read(path, left, right)
                        if not ok then
                            vim.notify("pr_review: " .. err, vim.log.levels.WARN)
                        end
                    end
                end,
                reload = true,
            },
            ["right"] = {
                -- retreats the watermark to this range's left edge, rather
                -- than clearing it entirely -- so unmarking within an
                -- earlier sub-range doesn't discard coverage you already
                -- established from further back (or further ahead, for
                -- that matter -- just this range's slice becomes unread
                -- again)
                fn = function(selected)
                    for _, entry in ipairs(selected) do
                        local path = path_from_entry(entry)
                        local ok, err = state.mark_file_unread(path, left)
                        if not ok then
                            vim.notify("pr_review: " .. err, vim.log.levels.WARN)
                        end
                    end
                end,
                reload = true,
            },
        },
    })
end

return M
