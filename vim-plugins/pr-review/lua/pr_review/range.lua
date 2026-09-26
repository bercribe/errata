-- ephemeral "currently focused commit range" for the files picker. not
-- persisted to state.json -- this is a UI mode for the current nvim
-- session, not part of your review's durable intent. selecting a range in
-- the commits picker sets this; the files picker then diffs and validates
-- read-marks against it instead of the full PR range.
local M = {}

local left, right

---@param l string
---@param r string
function M.set(l, r)
  left, right = l, r
end

---Resets to the full PR range (base..head).
function M.clear()
  left, right = nil, nil
end

---@return string left, string right, boolean is_full_range
function M.current()
  local state = require("pr_review.state")
  local pr = state.remote.pr or {}
  return left or pr.base_sha, right or pr.head_sha, left == nil
end

return M
