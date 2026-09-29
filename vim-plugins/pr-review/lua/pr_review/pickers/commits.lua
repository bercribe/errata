-- fzf-lua picker for PR commits. supports selecting a range (multi-select)
-- rather than only single commit-vs-parent, per the "commit range"
-- requirement. selecting a range is sticky: it sets pr_review.range and
-- hands off to the files picker, which then diffs/marks-read against that
-- range instead of the full PR.
local state = require("pr_review.state")
local range = require("pr_review.range")

local M = {}

---@param sha string
---@return string
local function icon_for(sha)
    local tag = state.draft.read_commits[sha]
    if tag == "explicit" then
        return "R  "
    elseif tag == "implicit" then
        return "R* "
    end
    return "  U"
end

---@param fzf_cb fun(entry: string?)
local function get_contents(fzf_cb)
    for _, c in ipairs(state.remote.commits or {}) do
        local subject = (c.message or ""):match("^[^\n]*") or ""
        fzf_cb(string.format("%s %s %s", icon_for(c.sha), c.sha:sub(1, 8), subject))
    end
    fzf_cb()
end

---Extracts the abbreviated sha shown in the entry and resolves it back to
---the full sha, so everything downstream (state storage, git revs) works
---with one consistent (full) representation.
---@param entry string
---@return string
local function sha_from_entry(entry)
    local short = entry:match("^...%s(%x+)")
    for _, c in ipairs(state.remote.commits or {}) do
        if c.sha:sub(1, #short) == short then
            return c.sha
        end
    end
    return short
end

---@param sha string
---@return integer?
local function commit_index(sha)
    for i, c in ipairs(state.remote.commits or {}) do
        if c.sha == sha then
            return i
        end
    end
end

function M.open()
    -- deferred: see the same note in pickers/files.lua
    local fzf = require("fzf-lua")
    fzf.fzf_exec(get_contents, {
        prompt = "PR Commits> ",
        fzf_opts = { ["--multi"] = true },
        actions = {
            ["default"] = function(selected)
                local shas = vim.tbl_map(sha_from_entry, selected)
                table.sort(shas, function(a, b)
                    return commit_index(a) < commit_index(b)
                end)

                local left, right
                if #shas == 1 then
                    left, right = shas[1] .. "^", shas[1]
                else
                    left, right = shas[1], shas[#shas]
                end
                range.set(left, right)
                require("pr_review.pickers.files").open()
            end,
            ["left"] = {
                fn = function(selected)
                    for _, entry in ipairs(selected) do
                        state.mark_commit_read(sha_from_entry(entry))
                    end
                end,
                reload = true,
            },
            ["right"] = {
                fn = function(selected)
                    for _, entry in ipairs(selected) do
                        state.mark_commit_unread(sha_from_entry(entry))
                    end
                end,
                reload = true,
            },
            ["ctrl-y"] = {
                fn = function(selected)
                    vim.fn.setreg('+', sha_from_entry(selected[1]))
                end,
                exec_silent = true,
            }
        },
    })
end

return M
