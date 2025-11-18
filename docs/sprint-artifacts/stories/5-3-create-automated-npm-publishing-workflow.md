# Story 5.3: Create Automated npm Publishing Workflow

Status: ready-for-dev

## Story

As a package maintainer,
I want automated npm publishing triggered by git tags,
So that releases are repeatable and validated.

## Acceptance Criteria

1. **Workflow triggers** on:
   - Git tags matching pattern `v*.*.*` (e.g., v0.3.0, v0.3.1)

2. **Workflow includes CI validation** before publishing:
   - Run npm ci
   - Run npm run lint
   - Run npm test
   - Run npm run build

3. **Package validation step** runs:
   - Execute npm pack
   - Run same validation from Story 5.2 (no test files in package)
   - Fail publishing if validation fails

4. **Publishing step** executes:
   - Run `npm publish --access public`
   - Uses NPM_TOKEN secret for authentication
   - Publishes to npm registry

5. **GitHub Release created** automatically:
   - Uses softprops/action-gh-release
   - Attaches tarball file
   - Generates release notes automatically

6. **Test publishing workflow** works end-to-end:
   - Update version in package.json to 0.3.0
   - Commit: `git commit -m "Release v0.3.0"`
   - Tag: `git tag v0.3.0`
   - Push tag: `git push origin v0.3.0`
   - GitHub Actions runs automatically
   - Package publishes to npm successfully
   - GitHub Release created with tarball attached

7. **NPM_TOKEN secret** configured in GitHub repository settings

8. **Published package** installable via `npx expo install @loqalabs/loqa-audio-bridge`

## Tasks / Subtasks

- [ ] Create .github/workflows/publish-npm.yml (AC: 1)
  - [ ] Configure workflow name: "Publish to npm"
  - [ ] Set trigger: push tags matching v*.*.*

- [ ] Implement CI validation step (AC: 2)
  - [ ] Checkout code
  - [ ] Setup Node.js (version 18)
  - [ ] Configure npm registry URL
  - [ ] Run npm ci
  - [ ] Run npm run lint
  - [ ] Run npm test
  - [ ] Run npm run build

- [ ] Implement package validation step (AC: 3)
  - [ ] Run npm pack
  - [ ] Extract and validate tarball
  - [ ] Reuse validation logic from Story 5.2
  - [ ] Fail with clear error if validation fails

- [ ] Implement npm publishing step (AC: 4)
  - [ ] Run npm publish --access public
  - [ ] Use NODE_AUTH_TOKEN environment variable
  - [ ] Reference NPM_TOKEN secret

- [ ] Implement GitHub Release creation (AC: 5)
  - [ ] Add softprops/action-gh-release action
  - [ ] Attach tarball file
  - [ ] Enable automatic release notes generation

- [ ] Configure repository secrets (AC: 7)
  - [ ] Document NPM_TOKEN setup process
  - [ ] Create instructions for generating npm token
  - [ ] Add token to GitHub repository secrets

- [ ] Test publishing workflow (AC: 6)
  - [ ] Create test tag following semantic versioning
  - [ ] Push tag and monitor workflow execution
  - [ ] Verify npm publish succeeds
  - [ ] Verify GitHub Release created
  - [ ] Check tarball attached to release

- [ ] Validate published package (AC: 8)
  - [ ] Test installation: npx expo install @loqalabs/loqa-audio-bridge
  - [ ] Verify package contents on npm registry
  - [ ] Test autolinking in fresh project

## Dev Notes

- **Requires npm account** and authentication token
- **Use `npm publish --access public`** for scoped packages (@loqalabs/*)
- **Tag format enforces semantic versioning** (v*.*.*  pattern)
- **Aligns with architecture Decision 4** (git tag-based publishing)
- **Security**: NPM_TOKEN stored as GitHub secret, never committed to repo
- **Idempotency**: Publishing same version twice will fail (npm prevents overwrites)

### Project Structure Notes

**File Location:**
- Create: `.github/workflows/publish-npm.yml`

**Dependencies:**
- Requires Story 5.1 (npm package config) for package.json setup
- Requires Story 5.2 (CI pipeline) for validation logic to reuse
- Requires Stories 4.1-4.4 (documentation) for complete package
- Requires Epic 1-4 complete for all source files

**Alignment with Architecture:**
- Supports FR21 (Publish to npm as @loqalabs/loqa-audio-bridge)
- Supports FR22 (Support `npx expo install` installation)
- Supports FR24 (Follow semantic versioning)
- Implements Decision 4: Git tag-based release automation

### Learnings from Previous Story

**From Story 5.2 (create-github-actions-ci-pipeline):**

Key integration points:
- Reuse CI validation jobs (lint, test, build) before publishing
- Reuse package validation logic from validate-package job
- Same Node.js version (18) for consistency
- Same dependency caching strategy for performance
- Ensures all CI checks pass before npm publish happens

### References

- Epic breakdown: [Source: docs/loqa-audio-bridge/epics.md#Story-5.3]
- Architecture Decision 4: [Source: docs/loqa-audio-bridge/architecture.md#Release-Automation]
- Story 5.1 (package config): [Source: docs/loqa-audio-bridge/sprint-artifacts/stories/5-1-configure-npm-package-for-publishing.md]
- Story 5.2 (CI pipeline): [Source: docs/loqa-audio-bridge/sprint-artifacts/stories/5-2-create-github-actions-ci-pipeline.md]

## Dev Agent Record

### Context Reference

- [5-3-create-automated-npm-publishing-workflow.context.xml](stories/5-3-create-automated-npm-publishing-workflow.context.xml)

### Agent Model Used

Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Debug Log References

### Completion Notes List

### File List
