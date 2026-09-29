-- local git calls into the worktree (nvim's cwd, set by pr-review.sh). these
-- never touch the network -- they operate on refs/commits already fetched by
-- `gh pr checkout` at session start.
local M = {}

---@param args string[]
---@return string|nil, string|nil
local function run(args)
    local cmd = { "git" }
    vim.list_extend(cmd, args)

    local result = vim.system(cmd, { text = true }):wait()
    if result.code ~= 0 then
        local err = vim.trim(result.stderr or "")
        return nil, err ~= "" and err or ("git exited with code " .. result.code)
    end
    return vim.trim(result.stdout or ""), nil
end

---@return string|nil, string|nil
function M.head_sha()
    return run({ "rev-parse", "HEAD" })
end

---@param a string
---@param b string
---@return string|nil, string|nil
function M.merge_base(a, b)
    return run({ "merge-base", a, b })
end

---Whether `a` is an ancestor of (or the same commit as) `b`.
---@param a string
---@param b string
---@return boolean
function M.is_ancestor(a, b)
    local result = vim.system({ "git", "merge-base", "--is-ancestor", a, b }, { text = true }):wait()
    return result.code == 0
end

---If `path` (as named at `b`) was renamed at some point between `a` and
---`b`, returns its old name at `a`; otherwise nil (not renamed, or not
---changed at all in that range).
---@param a string
---@param b string
---@param path string
---@return string|nil
function M.find_rename(a, b, path)
    local out = run({ "diff", "--name-status", "-M", a, b })
    if not out then
        return nil
    end
    for line in out:gmatch("[^\n]+") do
        local status, old_path, new_path = line:match("^(R%d*)\t(.-)\t(.+)$")
        if status and new_path == path then
            return old_path
        end
    end
    return nil
end

---The commit that most recently touched `line` of `path`, as it appears in
---the blob at `rev`. Used to anchor a comment to the commit actually
---responsible for that line, rather than just whichever revision happens
---to be the right-hand edge of the diff you were browsing -- for a
---narrowed sub-range, that edge may not have touched this line at all.
---@param rev string
---@param path string
---@param line integer
---@return string|nil
function M.blame_commit(rev, path, line)
    local out = run({ "blame", "--porcelain", "-L", string.format("%d,%d", line, line), rev, "--", path })
    if not out then
        return nil
    end
    return out:match("^(%x+)")
end

---@param a string
---@param b string
---@return table[]|nil, string|nil
function M.changed_file_statuses(a, b)
    local out, err = run({ "diff", "--name-status", a, b })
    if not out then
        return nil, err
    end
    if out == "" then
        return {}
    end
    local files = {}
    for line in out:gmatch("[^\n]+") do
        local status, path = line:match("^([^%s]).-([^%s]*)$")
        if status and path then
            table.insert(files, { path = path, status = status })
        end
    end
    return files
end

---Paths that differ between two revisions.
---@param a string
---@param b string
---@return string[]|nil, string|nil
function M.changed_files(a, b)
    local out, err = M.changed_file_statuses(a, b)
    if not out then
        return nil, err
    end
    return vim.tbl_map(function(f)
        return f.path
    end, out)
end

return M
