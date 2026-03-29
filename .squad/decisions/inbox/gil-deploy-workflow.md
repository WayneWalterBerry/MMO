# Decision: Deploy-on-Merge Workflow

**Author:** Gil (Web Engineer)  
**Date:** 2026-09-01  
**Category:** CI/CD  
**Status:** 🟢 Active

## Summary

Created `.github/workflows/squad-deploy.yml` — an automated deploy pipeline that triggers on push to `main` (after PR merge). It runs the full sharded test suite, builds engine + meta bundles via PowerShell, and pushes to `WayneWalterBerry/WayneWalterBerry.github.io` → `play/`.

## Impact

| Who | What |
|-----|------|
| **All squad members** | Merging to `main` now auto-deploys. No manual `web/deploy.ps1` needed for routine deploys. |
| **Nelson / QA** | Test gate runs before deploy — broken code won't reach Pages. |
| **Wayne** | Must configure `PAGES_DEPLOY_TOKEN` secret (fine-grained PAT with Contents read+write on the Pages repo). |
| **Gil** | Manual deploys still available via `web/deploy.ps1` for hotfixes or local testing. |

## Secret Requirement

Repository secret `PAGES_DEPLOY_TOKEN` must be configured:
- Fine-grained PAT scoped to `WayneWalterBerry/WayneWalterBerry.github.io`
- Permission: Contents (read & write)
- Set in MMO repo → Settings → Secrets → Actions

## Design Decisions

1. **Sharded tests mirror squad-ci.yml** — same 6-shard matrix for consistency.
2. **No-op deploy guard** — if build produces identical files, no commit is pushed.
3. **BUILD_TIMESTAMP logged** — printed to Actions output for post-deploy verification.
4. **Cross-repo auth via x-access-token** — standard GitHub PAT pattern for pushing to a different repo.
