# Branch Protection Configuration

This document describes how to configure branch protection rules for the `main` branch to enforce CI validation.

## Required Status Checks

Configure the following status checks to be required before merging to `main`:

### Status Check Names

1. **Lint & Format Check** - `lint`
2. **TypeScript Tests & Build** - `test-ts`
3. **iOS Build** - `build-ios`
4. **Android Build** - `build-android`
5. **Package Validation** - `validate-package`

## Configuration Steps

1. Go to repository Settings
2. Navigate to **Branches** section
3. Click **Add rule** for branch `main`
4. Configure the following settings:

### Branch Protection Settings

- ✅ **Require a pull request before merging**

  - Require approvals: 1 (recommended)
  - Dismiss stale pull request approvals when new commits are pushed

- ✅ **Require status checks to pass before merging**

  - Require branches to be up to date before merging
  - Status checks that are required:
    - `lint`
    - `test-ts`
    - `build-ios`
    - `build-android`
    - `validate-package`

- ✅ **Require conversation resolution before merging** (optional but recommended)

- ✅ **Do not allow bypassing the above settings** (recommended)

## Verification

After configuring branch protection:

1. Create a test PR with intentional lint error
2. Verify that PR shows "Required status checks" and blocks merge
3. Fix the error and verify PR becomes mergeable

## Notes

- All 5 jobs run in parallel for optimal performance (<10 min total)
- Jobs use dependency caching to speed up execution
- Zero-warning enforcement on iOS and Android builds
- Package validation prevents test files from shipping to npm
