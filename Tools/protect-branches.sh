#!/usr/bin/env bash
# Turns the branching rules into rules GitHub actually enforces.
#
# CI can only report; a push is stopped by branch protection, and that lives in
# the repository settings. Run this once, after `gh auth login`.
#
#   ./Tools/protect-branches.sh [owner/repo]
#
# Protected branches are free for public repositories. On a PRIVATE repository
# they require GitHub Pro, Team or Enterprise, and this script will answer 403.
set -euo pipefail

REPO="${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
echo "protecting branches on $REPO"

# The names below must match the job names CI reports, exactly:
#   Branch policy / Build and test / Documentation
protect() {
  local branch="$1"
  gh api -X PUT "repos/$REPO/branches/$branch/protection" \
    -H "Accept: application/vnd.github+json" --input - >/dev/null <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["Branch policy", "Build and test", "Documentation"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
JSON
  echo "  $branch: pull request required, all three checks must pass, force-push and deletion blocked"
}

protect main       # releases only, and only through a pull request
protect develop    # the integration branch: nothing lands untested

# Squash is the merge strategy for feature branches (one feature, one commit).
# A release from develop into main is the exception — merge it, do not squash,
# or the two histories drift apart. GitHub keeps merge commits available for that
# only if allow_merge_commit stays true.
gh api -X PATCH "repos/$REPO" \
  -F allow_squash_merge=true \
  -F allow_merge_commit=true \
  -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true \
  >/dev/null
echo "  repository: squash and merge commits allowed, rebase off, branch deleted after merge"

echo
echo "Two things this script deliberately does NOT do:"
echo
echo "  1. Tags. Branch protection covers refs/heads only, so anyone with write"
echo "     access can still push refs/tags/*. To restrict that, add a repository"
echo "     ruleset targeting tags with \"restrict creations\" (Settings -> Rules ->"
echo "     Rulesets -> New tag ruleset), granting bypass to whoever cuts releases."
echo "     It is left to the UI on purpose: the payload needs a bypass actor id"
echo "     that differs per repository, and a wrong one locks releases out."
echo
echo "  2. The default branch. Set it to develop in the repository settings if you"
echo "     want new pull requests to target it by default."
