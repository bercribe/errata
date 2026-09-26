-- fzf-lua picker for your own not-yet-submitted draft comments. `ctrl-e`
-- edits (reopens the compose buffer prefilled); `ctrl-x` deletes.
local state = require("pr_review.state")

local M = {}

---@param index integer
---@param c table draft comment
---@return string
local function format_entry(index, c)
    local loc = c.start_line and string.format("%s:%d-%d", c.path, c.start_line, c.line)
        or string.format("%s:%d", c.path, c.line)
    local kind = c.reply_to and string.format("reply to #%d", c.reply_to) or c.side
    local preview = (c.body or ""):gsub("\n", " ")
    return string.format("[%d] %s (%s) -- %s", index, loc, kind, preview)
end

---@param entry string
---@return integer?
local function index_from_entry(entry)
    return tonumber(entry:match("^%[(%d+)%]"))
end

---@param fzf_cb fun(entry: string?)
local function get_contents(fzf_cb)
    for i, c in ipairs(state.draft.draft_comments) do
        fzf_cb(format_entry(i, c))
    end
    fzf_cb()
end

function M.open()
    -- deferred: see the same note in pickers/files.lua
    local fzf = require("fzf-lua")
    fzf.fzf_exec(get_contents, {
        prompt = "PR Drafts> ",
        actions = {
            ["default"] = function(selected)
                local c = state.draft.draft_comments[index_from_entry(selected[1])]
                if not c then
                    return
                end
                require("pr_review.diff").open(c.commit_id .. "^", c.commit_id, c.path)
            end,
            ["ctrl-e"] = function(selected)
                local idx = index_from_entry(selected[1])
                local c = state.draft.draft_comments[idx]
                if not c then
                    return
                end
                require("pr_review.comment").open({
                    path = c.path,
                    line = c.line,
                    start_line = c.start_line,
                    side = c.side,
                    reply_to = c.reply_to,
                    commit_id = c.commit_id,
                    existing_index = idx,
                    existing_body = c.body,
                })
            end,
            ["ctrl-x"] = {
                fn = function(selected)
                    local idx = index_from_entry(selected[1])
                    if not idx then
                        return
                    end
                    state.remove_draft_comment(idx)
                end,
                reload = true,
            },
        },
    })
end

return M
