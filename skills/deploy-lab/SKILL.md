---
name: foundry:deploy-lab
description: Prepare a lab for RHDP deployment. Runs validation, creates or updates AgnosticV catalog item, and generates deployment instructions. Use when asked to "deploy my lab", "publish to RHDP", "create a catalog item", "prepare for summit", or "push to production".
context: main
model: claude-sonnet-4-6
---

# Deploy Lab - Prepare for RHDP Deployment

Validates the lab and prepares it for deployment on Red Hat Demo Platform.

## Workflow

1. **Run validation**: Invoke `/foundry:validate-lab` (all stages except skipped)
2. **Check Git status**: Ensure everything is committed and pushed
3. **Create/update AgnosticV catalog**: Delegate to `agnosticv:catalog-builder` if available
4. **Generate description.adoc**: For the catalog listing
5. **Provide deployment instructions**: How to test in dev, promote to prod

## Deployment Stages

### Dev (testing)
- Creates dev.yaml with reduced resources
- Points to the current branch
- Provides RHDP catalog link for dev testing

### Test (staging)
- Creates test.yaml
- Points to a tagged release
- Instructions for RHDP team review

### Prod (live)
- Creates prod.yaml with access controls
- Points to the production branch/tag
- Instructions for Summit/event submission

## Pre-deployment Checklist

- [ ] All validation stages pass (or have documented skips)
- [ ] Content reviewed for accuracy
- [ ] Setup scripts tested (provisioned and verified at least once)
- [ ] Health check script generated and webhook URL configured
- [ ] Git repo pushed to rhpds organization (or accessible public repo)
- [ ] README.md updated with lab description
