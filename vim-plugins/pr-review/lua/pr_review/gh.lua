-- thin synchronous wrapper around the `gh` CLI. all calls block: this is
-- intentional per the local-first design, network happens at well-defined
-- points (fetch, submit) rather than scattered through the session.
local M = {}

---@param args string[] arguments passed to `gh` (not including "gh" itself)
---@param opts? { input?: string }
---@return string|nil stdout, string|nil err
local function run(args, opts)
    opts = opts or {}
    local cmd = { "gh" }
    vim.list_extend(cmd, args)

    local result = vim.system(cmd, { text = true, stdin = opts.input }):wait()
    if result.code ~= 0 then
        local err = vim.trim(result.stderr or "")
        return nil, err ~= "" and err or ("gh exited with code " .. result.code)
    end
    return result.stdout, nil
end

---Run a gh command, returning raw stdout.
---@param args string[]
---@param opts? { input?: string }
---@return string|nil, string|nil
function M.raw(args, opts)
    return run(args, opts)
end

---Run a gh command, decoding stdout as JSON.
---@param args string[]
---@param opts? { input?: string }
---@return any|nil, string|nil
function M.json(args, opts)
    local out, err = run(args, opts)
    if not out then
        return nil, err
    end
    local ok, decoded = pcall(vim.json.decode, out)
    if not ok then
        return nil, "failed to decode gh output as json: " .. tostring(decoded)
    end
    return decoded, nil
end

---Call `gh api`, decoding the response as JSON.
---@param path string e.g. "repos/owner/repo/pulls/1/files"
---@param opts? { method?: string, paginate?: boolean, input?: table }
---@return any|nil, string|nil
function M.api(path, opts)
    opts = opts or {}
    local args = { "api", path }
    if opts.paginate then
        table.insert(args, "--paginate")
    end
    if opts.method then
        vim.list_extend(args, { "-X", opts.method })
    end

    local input
    if opts.input then
        vim.list_extend(args, { "--input", "-" })
        input = vim.json.encode(opts.input)
    end

    return M.json(args, { input = input })
end

---@param number integer
---@param fields string[]
---@return any|nil, string|nil
function M.pr_view(number, fields)
    return M.json({ "pr", "view", tostring(number), "--json", table.concat(fields, ",") })
end

return M
