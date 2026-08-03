#!/usr/bin/env bash
# Turns the branching rules into rules GitHub actually enforces.
#
# CI can only report; a push is stopped by branch protection, and that lives in
# the repository settings. Run this once, after `gh auth login`.
#
#   ./Tools/protect-branches.sh [owner/repo]
#
# NOTE ON PLANS: protected branches are free for PUBLIC repositories, but on a
# PRIVATE repository they require GitHub Pro, Team or Enterprise. On a private
# repo on the free plan this script will fail with a 403, and the branching model
# stays a convention that CI reports on rather than a rule that GitHub enforces.
set -euo pipefail

REPO="${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
echo "protecting branches on $REPO"

protect() {
  local branch="$1" reviews="$2"
  gh api -X PUT "repos/$REPO/branches/$branch/protection" \
    -H "Accept: application/vnd.github+json" \
    -F "required_status_checks[strict]=true" \
    -F "required_status_checks[contexts][]=Build and test" \
    -F "required_status_checks[contexts][]=Branch policy" \
    -F "enforce_admins=false" \
    -F "required_pull_request_reviews[required_approving_review_count]=$reviews" \
    -F "restrictions=" \
    -F "allow_force_pushes=false" \
    -F "allow_deletions=false" \
    >/dev/null
  echo "  $branch: pull request required, CI must be green, force-push and deletion blocked"
}

# main takes releases only, and only through a pull request.
protect main 0
# develop is the integration branch: same gate, so nothing lands untested.
protect develop 0

# Squash is the merge strategy for feature branches (one feature, one commit).
gh api -X PATCH "repos/$REPO" \
  -F allow_squash_merge=true \
  -F allow_merge_commit=false \
  -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true \
  >/dev/null
echo "  repository: squash-only merges, head branch deleted after merge"

echo
echo "Done. Two things this script deliberately does NOT do:"
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
