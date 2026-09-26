-- the one deliberate network round-trip at session start (or explicit
-- refresh): pulls PR metadata, files, commits and existing review comments
-- into remote.json. everything after this is local until submit.
local gh = require("pr_review.gh")
local state = require("pr_review.state")

local M = {}

local function owner_repo_number()
    local owner = vim.env.PR_REVIEW_OWNER
    local repo = vim.env.PR_REVIEW_REPO
    local n = tonumber(vim.env.PR_REVIEW_NUMBER)
    return owner, repo, n
end

---Groups a flat REST review-comments list into threads by root comment id.
---@param comments table[]
---@return table[]
local function group_threads(comments)
    local threads = {}
    local thread_by_root = {}
    for _, c in ipairs(comments) do
        local root_id = c.in_reply_to_id or c.id
        local thread = thread_by_root[root_id]
        if not thread then
            thread = {
                root_id = root_id,
                path = c.path,
                line = c.line or c.original_line,
                side = c.side,
                comments = {},
            }
            thread_by_root[root_id] = thread
            table.insert(threads, thread)
        end
        table.insert(thread.comments, {
            id = c.id,
            in_reply_to_id = c.in_reply_to_id,
            user = c.user and c.user.login,
            body = c.body,
            created_at = c.created_at,
        })
    end
    for _, thread in ipairs(threads) do
        table.sort(thread.comments, function(a, b)
            return a.id < b.id
        end)
    end
    return threads
end

---@return boolean ok, string? err
function M.run()
    local owner, repo, n = owner_repo_number()
    if not owner or not repo or not n then
        return false, "pr_review: missing PR_REVIEW_OWNER/PR_REVIEW_REPO/PR_REVIEW_NUMBER"
    end
    local repo_path = string.format("repos/%s/%s", owner, repo)

    local pr, err = gh.pr_view(n, { "number", "title", "body", "headRefOid", "baseRefOid", "headRefName", "baseRefName" })
    if not pr then
        return false, "failed to fetch PR: " .. (err or "unknown error")
    end

    local files, ferr = gh.api(string.format("%s/pulls/%d/files", repo_path, n), { paginate = true })
    if not files then
        return false, "failed to fetch files: " .. (ferr or "unknown error")
    end

    local commits, cerr = gh.api(string.format("%s/pulls/%d/commits", repo_path, n), { paginate = true })
    if not commits then
        return false, "failed to fetch commits: " .. (cerr or "unknown error")
    end

    local comments, cmerr = gh.api(string.format("%s/pulls/%d/comments", repo_path, n), { paginate = true })
    if not comments then
        return false, "failed to fetch comments: " .. (cmerr or "unknown error")
    end

    local head_sha = pr.headRefOid
    local prev_head = state.draft.session_head_sha

    state.remote = {
        fetched_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        pr = {
            number = pr.number,
            title = pr.title,
            body = pr.body,
            head_sha = head_sha,
            base_sha = pr.baseRefOid,
            head_ref = pr.headRefName,
            base_ref = pr.baseRefName,
        },
        files = vim.tbl_map(function(f)
            return { path = f.filename, status = f.status, additions = f.additions, deletions = f.deletions }
        end, files),
        commits = vim.tbl_map(function(c)
            return {
                sha = c.sha,
                message = c.commit.message,
                author = c.commit.author and c.commit.author.name,
                date = c.commit.author and c.commit.author.date,
            }
        end, commits),
        threads = group_threads(comments),
    }
    state.save_remote()

    if not prev_head then
        -- first fetch for this session: establish the baseline for drift checks
        state.draft.session_head_sha = head_sha
        state.save()
    elseif prev_head ~= head_sha then
        -- deliberately not auto-updated: surfaced so you can decide what to do,
        -- see pr_review.submit for the corresponding check at submit time
        vim.notify(
            string.format(
                "pr_review: PR has new commits since you started reviewing (%s -> %s). read-marks may be stale.",
                prev_head:sub(1, 8),
                head_sha:sub(1, 8)
            ),
            vim.log.levels.WARN
        )
    end

    return true, nil
end

return M
