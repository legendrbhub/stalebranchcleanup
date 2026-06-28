#!/bin/bash

# ============================================================
# Script  : delete_stale_branches.sh
# Purpose : Delete stale branches older than 90 days
#           across all repositories
# Auth    : GH_TOKEN secret (gh CLI handles auth automatically)
# ============================================================

# --------------------
# Configuration
# --------------------
THRESHOLD_DAYS=90
DRY_RUN=${DRY_RUN:-true}
PROTECTED_BRANCHES=("main" "master" "develop")

# --------------------
# Validate token
# --------------------
if [[ -z "$GH_TOKEN" ]]; then
  echo "❌ ERROR: GH_TOKEN is not set. Exiting."
  exit 1
fi

# --------------------
# Helper: Check if branch is protected
# --------------------
is_protected() {
  local branch="$1"
  for protected in "${PROTECTED_BRANCHES[@]}"; do
    if [[ "$branch" == "$protected" ]]; then
      return 0
    fi
  done
  return 1
}

# --------------------
# Helper: Check if branch has open PR
# --------------------
has_open_pr() {
  local owner="$1"
  local repo="$2"
  local branch="$3"

  pr_count=$(gh pr list \
    --repo "$owner/$repo" \
    --state open \
    --head "$branch" \
    --json number \
    --jq 'length')

  [[ "$pr_count" -gt 0 ]]
}

# --------------------
# Main
# --------------------
echo ""
echo "=============================================="
echo "   STALE BRANCH CLEANUP"
echo "   Threshold  : $THRESHOLD_DAYS days"
echo "   Dry Run    : $DRY_RUN"
echo "   Started At : $(date)"
echo "=============================================="
echo ""

TOTAL_STALE=0
TOTAL_DELETED=0

# --------------------
# Get all repos
# --------------------
echo "🔍 Fetching all repositories..."

repos=$(gh repo list --limit 1000 --json nameWithOwner --jq '.[].nameWithOwner')

if [[ -z "$repos" ]]; then
  echo "❌ No repositories found. Exiting."
  exit 1
fi

# --------------------
# Loop each repo
# --------------------
while IFS= read -r full_repo; do

  OWNER=$(echo "$full_repo" | cut -d'/' -f1)
  REPO=$(echo "$full_repo" | cut -d'/' -f2)

  echo ""
  echo "📦 Repo: $full_repo"
  echo "----------------------------------------------"

  branches=$(gh api \
    "repos/$OWNER/$REPO/branches" \
    --paginate \
    --jq '.[].name')

  if [[ -z "$branches" ]]; then
    echo "   ✅ No branches found"
    continue
  fi

  FOUND_STALE=false

  while IFS= read -r branch; do

    # Skip protected branches
    if is_protected "$branch"; then
      echo "   ⏭️  Skipping protected: $branch"
      continue
    fi

    # Get last commit date for this branch
    last_commit_date=$(gh api \
      "repos/$OWNER/$REPO/commits/$branch" \
      --jq '.commit.author.date')

    if [[ -z "$last_commit_date" ]]; then
      continue
    fi

    # Calculate days old
    last_commit_epoch=$(date -d "$last_commit_date" +%s 2>/dev/null || \
                        date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_commit_date" +%s)
    current_epoch=$(date +%s)
    days_old=$(( (current_epoch - last_commit_epoch) / 86400 ))

    # Skip if not stale
    if [[ "$days_old" -le "$THRESHOLD_DAYS" ]]; then
      continue
    fi

    # Skip if open PR exists
    if has_open_pr "$OWNER" "$REPO" "$branch"; then
      echo "   ⏭️  Skipping (open PR): $branch"
      continue
    fi

    # Branch is stale — print it
    FOUND_STALE=true
    ((TOTAL_STALE++))
    printf "   🔴 %-40s Last Commit: %-25s Days Old: %s\n" \
      "$branch" "$last_commit_date" "$days_old"

    # Delete or dry run
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "      [DRY-RUN] Would delete: $branch"
    else
      gh api \
        --method DELETE \
        "repos/$OWNER/$REPO/git/refs/heads/$branch"

      if [[ $? -eq 0 ]]; then
        echo "      ✅ Deleted: $branch"
        ((TOTAL_DELETED++))
      else
        echo "      ❌ Failed to delete: $branch"
      fi
    fi

  done <<< "$branches"

  if [[ "$FOUND_STALE" == "false" ]]; then
    echo "   ✅ No stale branches found"
  fi

done <<< "$repos"

echo ""
echo "=============================================="
echo "   SUMMARY"
echo "----------------------------------------------"
echo "   Total Stale Branches Found : $TOTAL_STALE"
if [[ "$DRY_RUN" == "true" ]]; then
echo "   Mode                       : DRY RUN (nothing deleted)"
else
echo "   Total Deleted              : $TOTAL_DELETED"
fi
echo "   Completed At               : $(date)"
echo "=============================================="
echo ""