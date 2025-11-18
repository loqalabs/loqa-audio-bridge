# Story 5.1: Configure npm Package for Publishing

Status: ready-for-dev

## Story

As a package maintainer,
I want the package configured for npm publishing,
So that users can install via `npx expo install`.

## Acceptance Criteria

1. **package.json includes complete npm metadata**:
   ```json
   {
     "name": "@loqalabs/loqa-audio-bridge",
     "version": "0.3.0",
     "description": "Production-grade Expo native module for real-time audio streaming",
     "main": "build/index.js",
     "types": "build/index.d.ts",
     "files": [
       "build/",
       "src/",
       "ios/",
       "android/",
       "hooks/",
       "expo-module.config.json",
       "LoqaAudioBridge.podspec",
       "README.md",
       "API.md",
       "INTEGRATION_GUIDE.md",
       "CHANGELOG.md",
       "LICENSE"
     ],
     "publishConfig": {
       "access": "public"
     }
   }
   ```

2. **.npmignore includes all test/development files**:
   ```
   __tests__/
   *.test.ts
   *.test.tsx
   *.spec.ts
   example/
   .github/
   tsconfig.json
   .eslintrc.js
   .prettierrc
   ios/Tests/
   android/src/test/
   android/src/androidTest/
   *.tgz
   node_modules/
   ```

3. **Running `npm pack` creates tarball**:
   - Tarball created: `loqalabs-loqa-audio-bridge-0.3.0.tgz`
   - Tarball size <500 KB (excluding node_modules)

4. **Tarball inspection shows correct contents**:
   - ✅ build/ directory present with compiled JS and .d.ts
   - ✅ src/ directory present with TypeScript source
   - ✅ ios/ directory present (excluding ios/Tests/)
   - ✅ android/ directory present (excluding test directories)
   - ✅ Documentation files present (README, API.md, etc.)
   - ❌ __tests__/ directory absent
   - ❌ example/ directory absent
   - ❌ .github/ directory absent
   - ❌ No *Tests.swift or *Test.swift files

## Tasks / Subtasks

- [ ] Configure package.json for npm publishing (AC: 1)
  - [ ] Set name to @loqalabs/loqa-audio-bridge
  - [ ] Set version to 0.3.0
  - [ ] Add description field
  - [ ] Set main to build/index.js
  - [ ] Set types to build/index.d.ts
  - [ ] Add files whitelist array
  - [ ] Add publishConfig with access: public

- [ ] Create .npmignore file (AC: 2)
  - [ ] Add test directories and files
  - [ ] Add example/ directory
  - [ ] Add .github/ directory
  - [ ] Add config files (tsconfig, eslint, prettier)
  - [ ] Add iOS test directories
  - [ ] Add Android test directories
  - [ ] Add build artifacts (*.tgz, node_modules)

- [ ] Test package creation (AC: 3)
  - [ ] Run npm pack
  - [ ] Verify tarball created successfully
  - [ ] Check tarball size (<500 KB target)

- [ ] Validate package contents (AC: 4)
  - [ ] Extract tarball: `tar -xzf loqalabs-loqa-audio-bridge-*.tgz`
  - [ ] Verify build/ directory present
  - [ ] Verify src/ directory present
  - [ ] Verify ios/ directory present (no Tests/)
  - [ ] Verify android/ directory present (no test dirs)
  - [ ] Verify documentation files present
  - [ ] Confirm test files absent
  - [ ] Confirm example/ absent
  - [ ] Confirm .github/ absent
  - [ ] Confirm no Swift test files

- [ ] Document package configuration (AC: 1, 2, 3, 4)
  - [ ] Add comments to package.json files array
  - [ ] Document .npmignore purpose
  - [ ] Create validation checklist for future releases

## Dev Notes

- **"files" whitelist approach** ensures only intended files ship
- **.npmignore provides additional safety** (defense in depth)
- **Aligns with architecture Decision 3** (multi-layer test exclusion)
- **FR23 requirement**: package includes all source and native implementations
- **Multi-layer exclusion strategy**:
  - Layer 1: podspec exclusions (Story 2.3)
  - Layer 2: .npmignore
  - Layer 3: package.json files whitelist

### Project Structure Notes

**File Locations:**
- package.json: `/loqa-audio-bridge/package.json` (already exists, needs updates)
- .npmignore: `/loqa-audio-bridge/.npmignore` (create new)

**Dependencies:**
- Requires Epic 1-4 complete (all source files and docs ready)
- Requires Story 2.3 (iOS podspec test exclusions) for iOS test exclusion
- Requires Stories 4.1-4.4 (documentation) for docs to include

**Alignment with Architecture:**
- Supports FR21 (Publish to npm as @loqalabs/loqa-audio-bridge)
- Supports FR22 (Support `npx expo install` installation)
- Supports FR23 (Include all source code and native implementations in package)
- Implements Decision 3: Multi-layered test exclusion strategy

### References

- Epic breakdown: [Source: docs/loqa-audio-bridge/epics.md#Story-5.1]
- Architecture Decision 3: [Source: docs/loqa-audio-bridge/architecture.md#Test-Exclusion]
- Story 2.3 (podspec exclusions): [Source: docs/loqa-audio-bridge/sprint-artifacts/stories/2-3-implement-ios-podspec-test-exclusions.md]

## Dev Agent Record

### Context Reference

- [5-1-configure-npm-package-for-publishing.context.xml](stories/5-1-configure-npm-package-for-publishing.context.xml)

### Agent Model Used

Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Debug Log References

### Completion Notes List

### File List
