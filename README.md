# 🌿 Stale Branch Cleanup

Automated GitHub Actions workflow to detect and delete stale branches older than **90 days** across all repositories — safely, with dry-run support and full audit logging.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [How It Works](#how-it-works)
- [Setup](#setup)
- [Usage](#usage)
- [Configuration](#configuration)
- [Output Example](#output-example)
- [Safety Guardrails](#safety-guardrails)

---

## Overview

Over time, repositories accumulate abandoned feature branches that clutter the branch list and create confusion. This project automates the cleanup process by:

- Scanning all your repositories weekly
- Identifying branches with no activity for 90+ days
- Printing a full report before any deletion
- Deleting stale branches only on manual approval

---

## Features

- ✅ Runs on a **weekly schedule** (every Sunday)
- ✅ **Dry-run by default** — prints report without deleting
- ✅ **Manual trigger** with option to enable actual deletion
- ✅ Skips **protected branches** (main, master, develop)
- ✅ Skips branches with **open Pull Requests**
- ✅ Handles **pagination** — works across repos with many branches
- ✅ Full **audit log** with branch name, last commit date, and days old
- ✅ Uses `gh` CLI — clean, readable, no curl hacks

---

## Project Structure

```
.
├── .github/
│   ├── workflows/
│   │   └── stale-branch-cleanup.yml   # Workflow trigger and schedule
│   └── scripts/
│       └── delete_stale_branches.sh   # Core cleanup script
└── README.md
```

---

## How It Works

For every branch across all repositories, the script runs through this decision tree:

```
For each branch:
│
├── Is it main / master / develop?
│   ├── YES → Skip ⏭️
│   └── NO  → Continue
│
├── Does it have an open Pull Request?
│   ├── YES → Skip ⏭️
│   └── NO  → Continue
│
├── Get last commit date
│   └── Calculate: Today - Last Commit = Days Old
│
├── Is Days Old > 90?
│   ├── NO  → Not stale, Skip ⏭️
│   └── YES → Mark as stale 🔴
│
└── DRY_RUN = true  → Print only
    DRY_RUN = false → Delete branch 🗑️
```

---

## Setup

### 1. Clone this repository

```bash
git clone https://github.com/YOUR_USERNAME/stale-branch-cleanup.git
cd stale-branch-cleanup
```

### 2. Create a GitHub Personal Access Token (PAT)

Go to:
```
GitHub → Settings → Developer Settings → Personal Access Tokens → Fine-grained tokens → Generate new token
```

Set the following permissions:
| Permission | Access |
|---|---|
| Repository access | All repositories |
| Contents | Read and Write |
| Metadata | Read only |
| Pull Requests | Read only |

> ⚠️ Copy the token immediately — you won't see it again.

### 3. Add Token as a Repository Secret

Go to:
```
Repo → Settings → Secrets and Variables → Actions → New repository secret
```

| Name | Value |
|---|---|
| `GH_TOKEN` | Your PAT token from step 2 |

### 4. Make the script executable

```bash
chmod +x .github/scripts/delete_stale_branches.sh
```

### 5. Push to GitHub

```bash
git add .
git commit -m "feat: add stale branch cleanup workflow"
git push origin main
```

---

## Usage

### Scheduled Run (Automatic — Every Sunday)

The workflow runs automatically every Sunday at midnight UTC.

- Always runs in **dry-run mode**
- Prints a full report of stale branches
- Does **not** delete anything

### Manual Run (With Deletion Option)

Go to:
```
Repo → Actions → Stale Branch Cleanup → Run workflow
```

Select:
| Option | Result |
|---|---|
| `dry_run = true` | Print report only |
| `dry_run = false` | Print report + delete stale branches |

> ✅ Recommended: Always run with `dry_run = true` first to review before deleting.

---

## Configuration

Edit these variables at the top of `delete_stale_branches.sh`:

```bash
# Number of days before a branch is considered stale
THRESHOLD_DAYS=90

# Branches that will never be deleted
PROTECTED_BRANCHES=("main" "master" "develop")

# Default mode — true = report only, false = delete
DRY_RUN=${DRY_RUN:-true}
```

---

## Output Example

```

==============================================
   STALE BRANCH CLEANUP
   Threshold  : 90 days
   Dry Run    : false
   Started At : Sun Jun 28 20:44:16 IST 2026
==============================================

🔍 Fetching all repositories...

📦 Repo: legendrbhub/learninghub
----------------------------------------------
   🔴 feature/tp                               Last Commit: 2021-12-24T18:59:51Z      Days Old: 1647
      ✅ Deleted: feature/tp
   🔴 hotfix/cd                                Last Commit: 2021-12-24T18:59:51Z      Days Old: 1647
      ✅ Deleted: hotfix/cd
   ⏭️  Skipping protected: master
   🔴 stakebt                                  Last Commit: 2021-12-24T18:59:51Z      Days Old: 1647
      ✅ Deleted: stakebt

📦 Repo: legendrbhub/argocd-kubernetes-deployment
----------------------------------------------
   ⏭️  Skipping protected: main
   ✅ No stale branches found

📦 Repo: legendrbhub/python-projects
----------------------------------------------
   ⏭️  Skipping protected: main
   ✅ No stale branches found

📦 Repo: legendrbhub/cloudformation-aws-web-hosting
----------------------------------------------
   ⏭️  Skipping protected: main
   ✅ No stale branches found

📦 Repo: legendrbhub/terraform-aws-hosted-website
----------------------------------------------
   ⏭️  Skipping protected: main
   ✅ No stale branches found

==============================================
   SUMMARY
----------------------------------------------
   Total Stale Branches Found : 3
   Total Deleted              : 3
   Completed At               : Sun Jun 28 20:44:31 IST 2026
==============================================

```

---

## Safety Guardrails

| Guardrail | Description |
|---|---|
| 🔒 Protected branches | `main`, `master`, `develop` are never deleted |
| 🔒 Open PR check | Branches with open PRs are always skipped |
| 🔒 Dry-run default | Scheduled runs never delete automatically |
| 🔒 Manual approval | Deletion requires explicit manual trigger with `dry_run=false` |
| 🔒 Full audit log | Every action is printed with branch name, date, and age |

---

## Author

**Rushikesh** — Senior DevOps / SRE Engineer  
[GitHub](https://github.com/legendrbhub) • [LinkedIn](https://www.linkedin.com/in/rushikeshbhoir)