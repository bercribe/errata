-- the other deliberate network round-trip: pushes local draft state (new
-- comments/replies) to GitHub as one or more reviews, then clears the
-- drafts.
--
-- GitHub's review-creation endpoint takes exactly one `commit_id`, applied
-- to every comment in that call. Comments drafted against different ranges
-- (e.g. via the sticky commit-range picker) are anchored to different
-- commits, so they can't always be submitted in a single call -- this
-- groups them by their recorded commit_id and issues one review per group.
local gh = require("pr_review.gh")
local state = require("pr_review.state")

local M = {}

local function owner_repo_number()
    local owner = vim.env.PR_REVIEW_OWNER
    local repo = vim.env.PR_REVIEW_REPO
    local n = tonumber(vim.env.PR_REVIEW_NUMBER)
    return owner, repo, n
end

---Groups top-level (non-reply) draft comments by the commit they were
---drafted against, and builds one review-creation payload per group. The
---overall summary body/event (if any) always rides along with the group
---anchored to `session_head` -- your review's own baseline, i.e. the PR as
---you actually saw it -- creating that group if no comments happen to be
---anchored there. Anchoring the decision to the live current head instead
---would risk silently approving commits that landed after you started and
---that you may never have looked at.
---
---`review_event == nil` means "leave every resulting review pending" (a
---draft, inspectable on GitHub's web UI, not finalized) -- GitHub only
---does this when the `event` field is absent from the request entirely,
---not merely set to "COMMENT", so no group gets an `event` key at all in
---that case.
---@param draft_comments table[]
---@param session_head string
---@param review_body string
---@param review_event string?
---@return table[] inputs -- one per POST .../reviews call needed
local function build_review_inputs(draft_comments, session_head, review_body, review_event)
    local groups_order, groups = {}, {}
    for _, c in ipairs(draft_comments) do
        if not c.reply_to then
            local cid = c.commit_id or session_head
            if not groups[cid] then
                groups[cid] = {}
                table.insert(groups_order, cid)
            end
            local comment = { path = c.path, line = c.line, side = c.side, body = c.body }
            if c.start_line then
                comment.start_line = c.start_line
                comment.start_side = c.side
            end
            table.insert(groups[cid], comment)
        end
    end

    local wants_summary = review_body ~= "" or (review_event ~= nil and review_event ~= "COMMENT")
    if wants_summary and not groups[session_head] then
        groups[session_head] = {}
        table.insert(groups_order, session_head)
    end

    local inputs = {}
    for _, cid in ipairs(groups_order) do
        local is_summary_group = wants_summary and cid == session_head
        local input = {
            commit_id = cid,
            body = is_summary_group and review_body or "",
        }
        if review_event ~= nil then
            input.event = is_summary_group and review_event or "COMMENT"
        end
        if #groups[cid] > 0 then
            input.comments = groups[cid]
        end
        table.insert(inputs, input)
    end
    return inputs
end

---@return boolean ok, string? err
function M.run()
    local owner, repo, n = owner_repo_number()
    if not owner or not repo or not n then
        return false, "pr_review: missing PR_REVIEW_OWNER/PR_REVIEW_REPO/PR_REVIEW_NUMBER"
    end
    local repo_path = string.format("repos/%s/%s", owner, repo)

    local review_body = state.draft.review_body or ""
    local review_event = state.draft.review_event -- nil means leave pending
    local has_comments = #state.draft.draft_comments > 0
    local wants_summary = review_body ~= "" or (review_event ~= nil and review_event ~= "COMMENT")
    if not has_comments and not wants_summary then
        return false, "nothing to submit"
    end

    -- cheap head-only check, not a full refetch, to catch drift right before
    -- posting anything
    local head, herr = gh.pr_view(n, { "headRefOid" })
    if not head then
        return false, "failed to check PR head: " .. (herr or "unknown error")
    end
    local current_head = head.headRefOid

    if state.draft.session_head_sha and current_head ~= state.draft.session_head_sha then
        local choice = vim.fn.confirm(
            string.format(
                "PR has new commits since you started (%s -> %s). Comments may be misplaced. Submit anyway?",
                assert(state.draft.session_head_sha):sub(1, 8),
                current_head:sub(1, 8)
            ),
            "&Yes\n&No",
            2
        )
        if choice ~= 1 then
            return false, "submit cancelled"
        end
    end

    -- NOTE: submitting multiple reviews (or replies) is multiple sequential
    -- network calls; a failure partway through leaves whatever succeeded
    -- already live on GitHub, but draft_comments only gets cleared on full
    -- success -- so retrying after a partial failure would resubmit the
    -- earlier, already-successful groups too. no idempotency tracking here
    -- yet, worth knowing if a submit ever fails midway.
    -- current_head is only used for the drift check above; the review
    -- itself is anchored to session_head_sha (falling back to current_head
    -- only if it's somehow unset, e.g. state.json predates this field)
    local session_head = state.draft.session_head_sha or current_head
    local inputs = build_review_inputs(state.draft.draft_comments, session_head, review_body, review_event)
    for _, input in ipairs(inputs) do
        local _, rerr = gh.api(string.format("%s/pulls/%d/reviews", repo_path, n), {
            method = "POST",
            input = input,
        })
        if rerr then
            return false, string.format("failed to submit review (commit %s): %s", input.commit_id:sub(1, 8), rerr)
        end
    end

    for _, c in ipairs(state.draft.draft_comments) do
        if c.reply_to then
            local _, rerr = gh.api(string.format("%s/pulls/%d/comments/%d/replies", repo_path, n, c.reply_to), {
                method = "POST",
                input = { body = c.body },
            })
            if rerr then
                return false, "failed to submit reply to comment " .. c.reply_to .. ": " .. rerr
            end
        end
    end

    state.clear_draft_comments()
    return true, nil
end

return M
