-- only activate inside a pr-review session (see errata's pr-review.sh),
-- never in ordinary editing. wrapped in pcall as a second line of
-- defense: if $PR_REVIEW_DIR is ever inherited somewhere unexpected (e.g.
-- a stray leftover in the shell a nix build gets run from), this should
-- degrade to a caught error rather than aborting whatever nvim invocation
-- picked it up.
if vim.env.PR_REVIEW_DIR then
    local ok, err = pcall(function()
        require("pr_review").setup()
    end)
    if not ok then
        vim.notify("pr_review: failed to activate: " .. tostring(err), vim.log.levels.ERROR)
    end
end
