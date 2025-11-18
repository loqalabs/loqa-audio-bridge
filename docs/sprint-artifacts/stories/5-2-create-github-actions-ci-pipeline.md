# Story 5.2: Create GitHub Actions CI Pipeline

Status: ready-for-dev

## Story

As a package maintainer,
I want automated CI validation on every PR and push,
So that code quality is maintained and regressions are caught early.

## Acceptance Criteria

1. **Workflow triggers** on:
   - Pull requests to main branch
   - Pushes to main branch

2. **Lint Job** includes:
   - Checkout code
   - Setup Node.js
   - Install dependencies with `npm ci`
   - Run linter: `npm run lint`
   - Run formatter check: `npm run format -- --check`

3. **TypeScript Tests Job** includes:
   - Checkout code
   - Setup Node.js
   - Install dependencies with `npm ci`
   - Run tests: `npm test`
   - Build TypeScript: `npm run build` (verify compilation)

4. **iOS Build Job** includes:
   - Runs on macos-latest
   - Install CocoaPods dependencies
   - Build with xcodebuild (clean build)
   - Verifies zero warnings

5. **Android Build Job** includes:
   - Runs on ubuntu-latest
   - Setup Java (Temurin distribution, version 17)
   - Build with Gradle (clean build)
   - Verifies zero warnings

6. **Package Validation Job** includes:
   - Build package: `npm pack`
   - Extract tarball for inspection
   - Validate no test files in package (*.test.ts, *.spec.ts)
   - Validate no test directories (__tests__, ios/Tests, example)
   - Fail build if test files found

7. **All jobs must pass** for PR to be mergeable (branch protection)

8. **CI badge added to README** showing build status

9. **Workflow completes** in <10 minutes total

## Tasks / Subtasks

- [ ] Create .github/workflows/ci.yml (AC: 1)
  - [ ] Configure workflow triggers (PR and push to main)
  - [ ] Set workflow name and description

- [ ] Implement Lint Job (AC: 2)
  - [ ] Add job definition: lint
  - [ ] Runs on ubuntu-latest
  - [ ] Checkout code action
  - [ ] Setup Node.js action
  - [ ] Run npm ci
  - [ ] Run npm run lint
  - [ ] Run npm run format -- --check

- [ ] Implement TypeScript Tests Job (AC: 3)
  - [ ] Add job definition: test-ts
  - [ ] Runs on ubuntu-latest
  - [ ] Checkout code action
  - [ ] Setup Node.js action
  - [ ] Run npm ci
  - [ ] Run npm test
  - [ ] Run npm run build

- [ ] Implement iOS Build Job (AC: 4)
  - [ ] Add job definition: build-ios
  - [ ] Runs on macos-latest
  - [ ] Checkout code
  - [ ] Install CocoaPods dependencies (cd ios && pod install)
  - [ ] Run xcodebuild with clean build
  - [ ] Check for zero warnings

- [ ] Implement Android Build Job (AC: 5)
  - [ ] Add job definition: build-android
  - [ ] Runs on ubuntu-latest
  - [ ] Checkout code
  - [ ] Setup Java (Temurin, version 17)
  - [ ] Run Gradle clean build
  - [ ] Check for zero warnings

- [ ] Implement Package Validation Job (AC: 6)
  - [ ] Add job definition: validate-package
  - [ ] Runs on ubuntu-latest
  - [ ] Checkout and setup Node.js
  - [ ] Run npm ci and npm run build
  - [ ] Run npm pack
  - [ ] Extract tarball
  - [ ] Validate no *.test.ts or *.spec.ts files
  - [ ] Validate no test directories
  - [ ] Fail with clear error if validation fails

- [ ] Configure branch protection (AC: 7)
  - [ ] Document required status checks
  - [ ] Add instructions for repository settings

- [ ] Add CI badge to README (AC: 8)
  - [ ] Generate badge URL
  - [ ] Update README.md with badge

- [ ] Optimize workflow performance (AC: 9)
  - [ ] Add dependency caching
  - [ ] Run jobs in parallel where possible
  - [ ] Test workflow execution time (<10 min target)

## Dev Notes

- Use latest GitHub Actions versions (@v4)
- Cache dependencies for faster builds (actions/cache)
- Run jobs in parallel for speed (lint, test-ts, build-ios, build-android run concurrently)
- Use matrix strategy for testing multiple Expo/RN versions (future enhancement)
- Package validation implements architecture Decision 3 (Layer 4: CI validation)

### Project Structure Notes

**File Location:**
- Create: `.github/workflows/ci.yml`

**Dependencies:**
- Requires Story 5.1 (npm package config) for package validation
- Requires Story 1.4 (linting config) for lint job
- Requires Story 2.5 (TypeScript tests) for test job
- Requires Story 2.2 (iOS Swift) for iOS build job
- Requires Story 2.4 (Android Kotlin) for Android build job

**Alignment with Architecture:**
- Implements Decision 3 Layer 4: CI-based validation (automated package content checks)
- Supports FR9 (zero compilation warnings) enforcement
- Enables automated quality gates for releases

### Learnings from Previous Story

**From Story 5.1 (configure-npm-package-for-publishing):**

Key integration points:
- Package validation job uses same `npm pack` command
- Validates same exclusion rules (no tests, no example)
- Ensures .npmignore and files array work correctly
- Automated check prevents regression in test exclusion

### References

- Epic breakdown: [Source: docs/loqa-audio-bridge/epics.md#Story-5.2]
- Architecture Decision 3: [Source: docs/loqa-audio-bridge/architecture.md#Test-Exclusion]
- Story 5.1 (package config): [Source: docs/loqa-audio-bridge/sprint-artifacts/stories/5-1-configure-npm-package-for-publishing.md]

## Dev Agent Record

### Context Reference

- [5-2-create-github-actions-ci-pipeline.context.xml](stories/5-2-create-github-actions-ci-pipeline.context.xml)

### Agent Model Used

Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Debug Log References

### Completion Notes List

### File List
