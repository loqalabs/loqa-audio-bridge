# Release Process Documentation

This document outlines the release process for @loqalabs/loqa-audio-bridge. This is internal documentation for package maintainers.

## Table of Contents

- [Version Numbering](#version-numbering)
- [Pre-Release Checklist](#pre-release-checklist)
- [Release Steps](#release-steps)
- [Post-Release Validation](#post-release-validation)
- [Rollback Procedure](#rollback-procedure)
- [Communication](#communication)

## Version Numbering

@loqalabs/loqa-audio-bridge follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html) (MAJOR.MINOR.PATCH).

### MAJOR Version (x.0.0)

Increment MAJOR version for **breaking API changes** that require consumers to modify their code.

**Examples:**

- Removing or renaming exported functions, hooks, or types
- Changing function signatures (removing parameters, changing return types)
- Updating minimum Expo Modules API version with breaking changes
- Changing peer dependency requirements (e.g., requiring React Native 0.80+ instead of 0.72+)
- Modifying event data structures or native module interfaces

**Release Process:** Requires MIGRATION.md update with detailed upgrade instructions.

### MINOR Version (0.x.0)

Increment MINOR version for **new features and non-breaking enhancements**.

**Examples:**

- Adding new exported functions, hooks, or TypeScript interfaces
- Adding new optional parameters to existing functions (with defaults)
- Adding new audio streaming features (e.g., noise cancellation)
- Improving performance without changing public APIs
- Adding new example app demonstrations
- Updating documentation with new best practices

**Release Process:** Standard release process with CHANGELOG.md update.

### PATCH Version (0.0.x)

Increment PATCH version for **bug fixes and documentation updates**.

**Examples:**

- Fixing audio streaming bugs or memory leaks
- Correcting TypeScript type definitions
- Updating README.md, API.md, or INTEGRATION_GUIDE.md
- Fixing iOS/Android native code bugs without API changes
- Dependency security updates (if non-breaking)
- CI/CD pipeline improvements

**Release Process:** Expedited release process for critical bug fixes.

## Pre-Release Checklist

Complete ALL items before creating a release tag:

### 1. Code Quality

- [ ] All tests passing locally: `npm test`
- [ ] All tests passing in CI: GitHub Actions workflow green
- [ ] Zero TypeScript compilation errors: `npm run build`
- [ ] Zero linting errors: `npm run lint`
- [ ] Zero format issues: `npm run format -- --check`
- [ ] Module structure validation passing: `npm run validate:structure`

### 2. Documentation

- [ ] CHANGELOG.md updated with version entry and release date
- [ ] CHANGELOG.md includes all user-facing changes (Added, Changed, Fixed, etc.)
- [ ] README.md version references updated (if applicable)
- [ ] API.md updated for any API changes
- [ ] INTEGRATION_GUIDE.md updated for integration changes
- [ ] MIGRATION.md updated for breaking changes (MAJOR versions only)

### 3. Version Bump

- [ ] package.json version updated via `npm version [major|minor|patch]`
- [ ] Version number follows semantic versioning rules
- [ ] Git tag created automatically by `npm version`

### 4. Testing

- [ ] Example app tested on iOS physical device
- [ ] Example app tested on Android physical device
- [ ] Fresh Expo app integration tested (following INTEGRATION_GUIDE.md)
- [ ] Audio streaming functionality verified on both platforms
- [ ] No regressions in existing features

### 5. Package Validation

- [ ] `npm pack` creates tarball successfully
- [ ] Tarball size <500 KB (excluding node_modules)
- [ ] No test files in tarball (extract and verify)
- [ ] All required files present (build/, src/, ios/, android/, docs)

## Release Steps

Follow these steps to publish a new version to npm:

### Step 1: Update Version

Use npm's built-in versioning command:

```bash
# For PATCH release (bug fixes)
npm version patch

# For MINOR release (new features)
npm version minor

# For MAJOR release (breaking changes)
npm version major
```

This command will:

- Update `package.json` version field
- Create a git commit with message "v0.x.x"
- Create a git tag "v0.x.x"

### Step 2: Review Changes

```bash
# Verify version updated correctly
cat package.json | grep version

# Review git tag
git tag -l -n1

# Review CHANGELOG.md entry
cat CHANGELOG.md | head -n 30
```

### Step 3: Push Commit and Tag

Push the version commit and tag to GitHub:

```bash
# Push version commit to main branch
git push origin main

# Push version tag (triggers automated publish workflow)
git push origin v0.x.x
```

**IMPORTANT:** Pushing the tag triggers the automated npm publishing workflow via GitHub Actions.

### Step 4: Monitor GitHub Actions

1. Go to [GitHub Actions page](https://github.com/loqalabs/loqa-audio-bridge/actions)
2. Find the "Publish npm Package" workflow run
3. Monitor workflow progress:
   - ✅ CI validation (lint, test, build)
   - ✅ Package validation (no test files)
   - ✅ npm publish
   - ✅ GitHub Release creation

**Estimated Duration:** 5-10 minutes

### Step 5: Verify npm Publication

```bash
# Check package appears on npm registry
npm view @loqalabs/loqa-audio-bridge

# Verify correct version published
npm view @loqalabs/loqa-audio-bridge version

# Test installation in fresh directory
cd /tmp
npx create-expo-app test-install
cd test-install
npx expo install @loqalabs/loqa-audio-bridge
```

### Step 6: Verify GitHub Release

1. Go to [GitHub Releases](https://github.com/loqalabs/loqa-audio-bridge/releases)
2. Verify release created with:
   - Release title: v0.x.x
   - Tarball attached as asset
   - Auto-generated release notes from commits

### Step 7: Announce Release (Optional)

For MAJOR or significant MINOR releases:

- [ ] Post announcement in Loqa Slack #engineering channel
- [ ] Update Voiceline project documentation
- [ ] Notify integration teams of new version

## Post-Release Validation

Complete within 1 hour of release:

### Installation Test

```bash
# Test installation from npm registry
npx expo install @loqalabs/loqa-audio-bridge

# Verify correct version installed
npm list @loqalabs/loqa-audio-bridge
```

**Expected:** Package installs successfully in <60 seconds.

### Fresh Expo App Integration Test

Follow [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) from scratch:

```bash
npx create-expo-app test-integration
cd test-integration
npx expo install @loqalabs/loqa-audio-bridge
npx expo prebuild
```

**Expected:** Integration completes in <30 minutes with zero manual configuration.

### Example App Verification

```bash
cd example
npm install
npx expo run:ios
npx expo run:android
```

**Expected:** Example app runs successfully on both platforms with audio streaming working.

## Rollback Procedure

If a critical bug is discovered after publishing:

### Step 1: Assess Impact (Within 1 Hour)

- [ ] Identify bug severity (Critical, High, Medium, Low)
- [ ] Determine affected versions
- [ ] Estimate number of users impacted
- [ ] Decide: Deprecate and patch, or immediate rollback

### Step 2: Deprecate Problematic Version (Within 4 Hours)

```bash
# Mark version as deprecated on npm
npm deprecate @loqalabs/loqa-audio-bridge@0.3.x "Critical bug: [description]. Use 0.3.y instead."
```

**Effect:** Users see warning on installation, but package still installable.

### Step 3: Publish Patch Release (Within 24 Hours)

```bash
# Fix bug in codebase
git checkout -b hotfix/critical-bug
# ... make fixes ...
git commit -m "Fix critical bug: [description]"
git push origin hotfix/critical-bug

# Merge to main after review
git checkout main
git merge hotfix/critical-bug

# Publish patch release
npm version patch
git push origin main
git push origin v0.3.y
```

### Step 4: Communicate Issue

- [ ] Post GitHub Issue describing bug and fix
- [ ] Update CHANGELOG.md with bug fix entry
- [ ] Announce in Loqa Slack #engineering
- [ ] Notify affected integration teams

### Step 5: Monitor Adoption

```bash
# Check download stats weekly
npm view @loqalabs/loqa-audio-bridge

# Verify deprecated version downloads declining
# Verify patch version downloads increasing
```

## Communication

### Internal Communication (Loqa Labs)

- **Slack Channel:** #engineering
- **Audience:** Development team, product managers
- **Frequency:** All MAJOR releases, significant MINOR releases, critical PATCH releases

**Template:**

```
🚀 New Release: @loqalabs/loqa-audio-bridge v0.x.x

**Changes:**
- [Summary from CHANGELOG.md]

**Action Required:**
- [Migration steps for breaking changes, if any]

**Links:**
- npm: https://www.npmjs.com/package/@loqalabs/loqa-audio-bridge
- Changelog: [link]
```

### External Communication (npm/GitHub)

- **Platform:** npm registry, GitHub Releases
- **Audience:** External package consumers
- **Content:** CHANGELOG.md entries, auto-generated release notes

### Emergency Communication (Critical Bugs)

- **Timeline:** Within 4 hours of discovery
- **Channels:** GitHub Issue, Slack, npm deprecation notice
- **Content:** Bug description, affected versions, workaround, ETA for fix

## References

- [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
- [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
- [npm Publishing Guide](https://docs.npmjs.com/cli/v10/commands/npm-publish)
- [GitHub Actions Workflows](.github/workflows/)

---

**Document Version:** 1.0
**Last Updated:** 2025-11-13
**Maintained By:** Anna Barnes (anna@loqalabs.com)
