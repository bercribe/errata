-- two-pane diff viewer. deliberately not buffer-lifecycle-managed: every
-- window here is either the real worktree file (when the right rev is current
-- HEAD) or a plain read-only scratch buffer.
local git = require("pr_review.git")

local M = {}

---@param rev string
---@param path string
---@return string[]
local function show_lines(rev, path)
    local result = vim.system({ "git", "show", string.format("%s:%s", rev, path) }, { text = true }):wait()
    if result.code ~= 0 then
        return { string.format("<%s does not exist at %s>", path, rev:sub(1, 8)) }
    end
    return vim.split(result.stdout, "\n", { plain = true })
end

---@param path string
---@return string
local function detect_filetype(path)
    return vim.filetype.match({ filename = path }) or ""
end

---@param bufnr integer
---@param side "LEFT"|"RIGHT"
---@param left_rev string
---@param right_rev string
---@param path string canonical (current/right-side) path
---@param left_path string the file's name at left_rev -- same as `path`
---  unless it was renamed somewhere in the range
local function tag_buffer(bufnr, side, left_rev, right_rev, path, left_path)
    -- both bounds (and both path spellings) are stored on *both* panes, not
    -- just this side's own rev/name -- so that marking the file read can
    -- prove the full range was viewed, and so that blame (which needs the
    -- file's name *as it existed at whichever rev it's blaming*) can find
    -- the right path regardless of which pane the comment was made from
    vim.b[bufnr].pr_review_diff =
        { side = side, left_rev = left_rev, right_rev = right_rev, path = path, left_path = left_path }
end

---@param win integer
---@param rev string
---@param left_rev string
---@param right_rev string
---@param path string canonical path, used for buffer tagging (comments/
---  read-tracking always refer to the file's current/right-side name)
---@param side "LEFT"|"RIGHT"
---@param left_path string
---@param content_path string? actual path to read content from, if
---  different from `path` (e.g. the old name of a renamed file, on the
---  left/base side)
---@return integer bufnr
local function open_scratch_side(win, rev, left_rev, right_rev, path, side, left_path, content_path)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(win, bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, show_lines(rev, content_path or path))
    vim.bo[bufnr].filetype = detect_filetype(content_path or path)
    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].modifiable = false
    tag_buffer(bufnr, side, left_rev, right_rev, path, left_path)
    return bufnr
end

---Opens a two-pane diff of `path` between `left_rev` and `right_rev` in a
---new tab. `path` is the file's name as of `right_rev` (its canonical name
---for comments/read-tracking); if it was renamed somewhere in the range,
---the left/base side is fetched under its old name instead.
---@param left_rev string
---@param right_rev string
---@param path string
function M.open(left_rev, right_rev, path)
    local left_path = git.find_rename(left_rev, right_rev, path) or path
    if left_path ~= path then
        vim.notify(string.format("pr_review: %s was renamed from %s", path, left_path))
    end

    vim.cmd("tabnew")
    local right_win = vim.api.nvim_get_current_win()

    local head = git.head_sha()
    local right_bufnr
    if right_rev == head and vim.uv.fs_stat(path) then
        vim.cmd.edit(vim.fn.fnameescape(path))
        right_bufnr = vim.api.nvim_get_current_buf()
        tag_buffer(right_bufnr, "RIGHT", left_rev, right_rev, path, left_path)
    else
        right_bufnr = open_scratch_side(right_win, right_rev, left_rev, right_rev, path, "RIGHT", left_path)
    end

    vim.cmd("leftabove vsplit")
    local left_win = vim.api.nvim_get_current_win()
    open_scratch_side(left_win, left_rev, left_rev, right_rev, path, "LEFT", left_path, left_path)

    vim.api.nvim_win_call(left_win, function()
        vim.cmd.diffthis()
    end)
    vim.api.nvim_win_call(right_win, function()
        vim.cmd.diffthis()
    end)
    vim.api.nvim_set_current_win(right_win)
end

return M
