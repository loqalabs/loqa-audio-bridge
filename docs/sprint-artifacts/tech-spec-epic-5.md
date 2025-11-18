# Epic Technical Specification: Distribution & CI/CD

Date: 2025-11-14
Author: Anna
Epic ID: 5
Status: Draft

---

## Overview

Epic 5 focuses on establishing the **production distribution and continuous integration/continuous deployment (CI/CD) infrastructure** for @loqalabs/loqa-audio-bridge. This epic transforms the working module from Epic 2-3 and documented module from Epic 4 into a production-ready npm package with automated quality gates, multi-platform build validation, and reliable release processes.

The primary deliverables include npm package configuration with proper exclusions, GitHub Actions CI/CD pipelines for automated testing and publishing, EAS Build validation for cloud builds, and comprehensive release process documentation. This infrastructure ensures every release is high quality, properly tested, and installable via a single `npx expo install` command.

## Objectives and Scope

### In Scope

**Package Configuration & Publishing (Stories 5.1, 5.3)**
- npm package.json configuration with proper main/types entries
- .npmignore file with multi-layered test exclusions (implements Architecture Decision 3)
- Package validation ensuring no test files ship to production
- Automated npm publishing triggered by git tags (semantic versioning)
- Public scoped package under @loqalabs organization

**Continuous Integration Pipeline (Story 5.2)**
- GitHub Actions workflow for every PR and main branch push
- Automated linting, TypeScript tests, and build validation
- iOS build job (Xcode on macOS runners)
- Android build job (Gradle on Ubuntu runners)
- Package validation job enforcing test exclusion policies

**Cloud Build Validation (Story 5.4)**
- EAS Build compatibility testing (Expo Application Services)
- Validation that module works in cloud build environment
- Documentation of EAS Build requirements and configuration

**Release Process Documentation (Story 5.5)**
- CHANGELOG.md following Keep a Changelog format
- RELEASING.md with semantic versioning guidelines
- Pre-release checklist and post-release validation steps
- Version numbering policy and rollback procedures

### Out of Scope

**Not included in Epic 5:**
- Pre-commit hooks or Git hooks (deferred to v0.4.0)
- Automated version bumping tools (manual via `npm version`)
- npm package provenance/attestation (future security enhancement)
- Multi-version support matrix testing (test only latest Expo/RN)
- CDN distribution or alternative package registries
- Docker-based local build environments
- Performance benchmarking in CI (covered in Epic 3 testing)

### Success Criteria

**Epic 5 is complete when:**
1. ✅ Package configured for npm with all test files excluded (validated via `npm pack` inspection)
2. ✅ GitHub Actions CI pipeline passes on all PRs and main pushes
3. ✅ Automated npm publishing workflow successfully publishes v0.3.0 via git tag
4. ✅ Package installable via `npx expo install @loqalabs/loqa-audio-bridge`
5. ✅ EAS Build successfully builds iOS and Android without special configuration
6. ✅ CHANGELOG.md and RELEASING.md documentation complete and reviewed
7. ✅ Package appears on npm registry: https://www.npmjs.com/package/@loqalabs/loqa-audio-bridge

## System Architecture Alignment

Epic 5 implements **Architecture Decisions 3 and 4** from the Architecture Document:

### Decision 3: Multi-Layered Test Exclusion (Critical)

Epic 5 implements the **CI validation layer** (Layer 4) of the test exclusion strategy that prevents the v0.2.0 failure where test files shipped to clients causing XCTest import errors.

**Four-Layer Defense (Epic 5 implements Layer 4):**
1. **Layer 1 (Epic 2)**: iOS Podspec exclusions (`s.exclude_files`)
2. **Layer 2 (Epic 2)**: Android Gradle auto-exclusion (src/test, src/androidTest)
3. **Layer 3 (Epic 5)**: .npmignore exclusions (Story 5.1)
4. **Layer 4 (Epic 5)**: CI validation pipeline (Story 5.2) - **Epic 5 responsibility**

**Story 5.2 CI Validation Implementation:**
```yaml
# .github/workflows/ci.yml
validate-package:
  runs-on: ubuntu-latest
  steps:
    - run: npm pack
    - name: Validate no test files in package
      run: |
        tar -xzf loqalabs-loqa-audio-bridge-*.tgz
        cd package
        # FAIL if test files found
        if find . -name "*.test.ts" -o -name "*.spec.ts" | grep .; then
          echo "ERROR: Test files in package!"
          exit 1
        fi
        # FAIL if test directories exist
        if [ -d "__tests__" ] || [ -d "ios/Tests" ]; then
          echo "ERROR: Test directories in package!"
          exit 1
        fi
```

This automated validation runs on **every PR and push to main**, preventing regressions.

### Decision 4: Git Tag-Based Publishing

Epic 5 implements the **automated npm publishing strategy** via GitHub Actions triggered by semantic version git tags.

**Publishing Workflow (Story 5.3):**
1. Developer updates version in package.json (e.g., `0.3.0`)
2. Developer commits and creates git tag: `git tag v0.3.0`
3. Developer pushes tag: `git push origin v0.3.0`
4. GitHub Actions automatically runs CI validation
5. If validation passes, publishes to npm registry
6. Creates GitHub Release with tarball and auto-generated notes

**Rationale:**
- Manual version tagging prevents accidental publishes
- Automated validation ensures quality gate before publish
- Git tags provide version audit trail
- Aligns with Loqa monorepo release patterns

### Expo Autolinking Compatibility

Epic 5 ensures the package structure supports **Expo autolinking** (validated in Epic 3):
- `expo-module.config.json` present in package root
- `LoqaAudioBridge.podspec` present for iOS CocoaPods
- `android/build.gradle` configured with proper module package name
- No manual configuration required by consumers

### EAS Build Compatibility (Story 5.4)

Epic 5 validates compatibility with **Expo Application Services (EAS) cloud builds**:
- Package works in EAS remote build environment (macOS for iOS, Linux for Android)
- No custom eas.json configuration required beyond standard Expo settings
- Autolinking functions identically to local builds
- Validates **FR38** (Work with EAS Build without special configuration)

## Detailed Design

### Services and Modules

Epic 5 configures and orchestrates the following services and modules for distribution:

| Component | Responsibility | Configuration Files | Owner |
|-----------|----------------|---------------------|-------|
| **npm Registry** | Public package hosting and distribution | package.json, .npmignore | npm (external) |
| **GitHub Actions CI** | Automated testing and validation | .github/workflows/ci.yml | GitHub (external) |
| **GitHub Actions CD** | Automated publishing and releases | .github/workflows/publish-npm.yml | GitHub (external) |
| **EAS Build Service** | Cloud-based native builds | eas.json (consumer-side) | Expo (external) |
| **Package Validation** | Automated test file exclusion checks | CI script in validate-package job | Epic 5 |
| **Version Management** | Semantic versioning and tagging | CHANGELOG.md, RELEASING.md | Epic 5 |

**Module Responsibilities:**

**Story 5.1 - npm Package Configuration:**
- Configures package.json with proper entry points (main, types)
- Defines files whitelist for npm package contents
- Creates .npmignore for defensive exclusion of test files
- Sets publishConfig for public scoped package access

**Story 5.2 - GitHub Actions CI Pipeline:**
- Lint job: Validates code style and formatting
- Test job: Runs TypeScript unit tests
- iOS build job: Compiles Swift native module on macOS
- Android build job: Compiles Kotlin native module on Linux
- Package validation job: Ensures no test files in tarball

**Story 5.3 - Automated Publishing:**
- Triggered by git tag push (v*.*.*)
- Runs full CI validation before publish
- Publishes to npm registry with NPM_TOKEN
- Creates GitHub Release with tarball attachment

**Story 5.4 - EAS Build Validation:**
- Tests module in EAS remote build environment
- Validates autolinking works identically to local builds
- Documents any EAS-specific requirements (expected: none)

**Story 5.5 - Release Documentation:**
- CHANGELOG.md: Version history and breaking changes
- RELEASING.md: Step-by-step release process
- Pre-release checklist and post-release validation

### Data Models and Contracts

Epic 5 works with the following data structures and contracts:

**npm Package Metadata (package.json):**
```json
{
  "name": "@loqalabs/loqa-audio-bridge",
  "version": "0.3.0",
  "description": "Production-grade Expo native module...",
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
    "MIGRATION.md",
    "CHANGELOG.md",
    "LICENSE"
  ],
  "publishConfig": {
    "access": "public"
  },
  "peerDependencies": {
    "expo": ">=52.0.0",
    "expo-modules-core": "*",
    "react": ">=18.0.0",
    "react-native": ">=0.72.0"
  }
}
```

**npm Package Contents Contract:**
- ✅ MUST include: Compiled JS (build/), TypeScript source (src/), native code (ios/, android/)
- ✅ MUST include: Configuration (expo-module.config.json, LoqaAudioBridge.podspec)
- ✅ MUST include: Documentation (README.md, API.md, INTEGRATION_GUIDE.md, MIGRATION.md)
- ❌ MUST exclude: Test files (__tests__/, *.test.ts, ios/Tests/, android/src/test/)
- ❌ MUST exclude: Development files (example/, .github/, tsconfig.json, .eslintrc.js)
- ❌ MUST exclude: Build artifacts (node_modules/, *.tgz)

**GitHub Actions Workflow Events:**
```yaml
# CI Trigger Contract
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

# CD Trigger Contract
on:
  push:
    tags:
      - 'v*.*.*'  # Semantic version tags only
```

**EAS Build Configuration (eas.json):**
```json
{
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "production": {
      "distribution": "store"
    }
  }
}
```

**CHANGELOG.md Format Contract (Keep a Changelog):**
```markdown
## [0.3.0] - 2025-11-14

### Added
- List of new features

### Changed
- List of changes

### Deprecated
- List of deprecated features

### Removed
- List of removed features

### Fixed
- List of bug fixes

### Security
- List of security fixes
```

### APIs and Interfaces

Epic 5 integrates with the following external APIs and services:

**npm Registry API:**
- **Endpoint**: https://registry.npmjs.org/
- **Authentication**: NPM_TOKEN (stored in GitHub Secrets)
- **Operation**: `npm publish --access public`
- **Input**: Tarball from `npm pack`
- **Output**: Package published at https://www.npmjs.com/package/@loqalabs/loqa-audio-bridge
- **Error Handling**: Publish fails if version already exists, token invalid, or package validation fails

**GitHub Actions API:**
- **Triggers**: Webhook-based (PR, push, tag)
- **Runners**: ubuntu-latest (Linux), macos-latest (macOS for iOS builds)
- **Secrets**: NPM_TOKEN (write:packages scope)
- **Artifacts**: Tarball files attached to GitHub Releases
- **Status Checks**: Required for PR merge (configured via branch protection)

**GitHub Releases API:**
```yaml
- name: Create GitHub Release
  uses: softprops/action-gh-release@v1
  with:
    files: loqalabs-loqa-audio-bridge-*.tgz
    generate_release_notes: true
```

**EAS Build API:**
- **Command**: `eas build --platform ios|android --profile development`
- **Authentication**: Expo account token (eas login)
- **Build Environment**: Remote macOS (iOS), Remote Linux (Android)
- **Output**: .ipa (iOS), .apk/.aab (Android)
- **Validation**: Module must autolink without special eas.json configuration

**Xcode Build Tools (CI):**
```bash
xcodebuild \
  -workspace ios/LoqaAudioBridge.xcworkspace \
  -scheme LoqaAudioBridge \
  clean build
```
- **Platform**: macOS runners only
- **Exit Code**: 0 = success, non-zero = build failure
- **Warnings**: Must be zero (enforced by Story 2.8)

**Gradle Build Tools (CI):**
```bash
cd android && ./gradlew clean build
```
- **Platform**: ubuntu-latest runners
- **JDK**: Temurin 17
- **Exit Code**: 0 = success, non-zero = build failure
- **Warnings**: Must be zero (enforced by Story 2.8)

### Workflows and Sequencing

**Workflow 1: npm Package Publishing (Story 5.3)**

```
Developer Workstation                 GitHub Actions                npm Registry
        │                                    │                            │
        │ 1. npm version patch               │                            │
        │    (updates package.json)          │                            │
        │                                    │                            │
        │ 2. git commit -m "Release v0.3.1"  │                            │
        │                                    │                            │
        │ 3. git tag v0.3.1                  │                            │
        │                                    │                            │
        │ 4. git push origin v0.3.1 ─────────►                            │
        │                                    │                            │
        │                                    │ 5. Detect tag push         │
        │                                    │    (v*.*.* pattern)        │
        │                                    │                            │
        │                                    │ 6. Checkout code           │
        │                                    │                            │
        │                                    │ 7. npm ci (install deps)   │
        │                                    │                            │
        │                                    │ 8. npm run lint            │
        │                                    │    (validate code style)   │
        │                                    │                            │
        │                                    │ 9. npm test                │
        │                                    │    (run TypeScript tests)  │
        │                                    │                            │
        │                                    │ 10. npm run build          │
        │                                    │     (compile TypeScript)   │
        │                                    │                            │
        │                                    │ 11. npm pack               │
        │                                    │     (create tarball)       │
        │                                    │                            │
        │                                    │ 12. Validate package       │
        │                                    │     (check no test files)  │
        │                                    │                            │
        │                                    │ 13. npm publish ───────────► 14. Publish package
        │                                    │     --access public         │     (v0.3.1 live)
        │                                    │                            │
        │                                    │ 15. Create GitHub Release  │
        │                                    │     (attach tarball)       │
        │                                    │                            │
        │ 16. Verify on npm ◄────────────────┼────────────────────────────┘
        │     (manual check)                 │
        │                                    │
        ▼                                    ▼
```

**Workflow 2: CI Validation on Pull Request (Story 5.2)**

```
Developer                GitHub                   CI Jobs (parallel)
    │                       │                            │
    │ 1. Create PR          │                            │
    │ ──────────────────────►                            │
    │                       │                            │
    │                       │ 2. Trigger CI workflows    │
    │                       ├────────────────────────────►
    │                       │                            │
    │                       │              ┌─────────────┴─────────────┐
    │                       │              │                           │
    │                       │         Lint Job                    Test Job
    │                       │              │                           │
    │                       │         npm run lint              npm test
    │                       │              │                           │
    │                       │              └─────────────┬─────────────┘
    │                       │                            │
    │                       │              ┌─────────────┴─────────────┐
    │                       │              │                           │
    │                       │         iOS Build                  Android Build
    │                       │         (macOS)                    (Linux)
    │                       │         xcodebuild                 ./gradlew
    │                       │              │                           │
    │                       │              └─────────────┬─────────────┘
    │                       │                            │
    │                       │                      Package Validation
    │                       │                      (check test exclusion)
    │                       │                            │
    │                       │ 3. All jobs complete       │
    │                       ◄────────────────────────────┘
    │                       │
    │ 4. Review status      │
    │ ◄─────────────────────┤
    │    (✅ all passed)    │
    │                       │
    │ 5. Merge PR           │
    │ ──────────────────────►
    │                       │
    ▼                       ▼
```

**Workflow 3: EAS Build Validation (Story 5.4)**

```
Developer Workstation        EAS Build Service          Build Output
        │                           │                        │
        │ 1. npx create-expo-app    │                        │
        │    test-eas               │                        │
        │                           │                        │
        │ 2. npx expo install       │                        │
        │    @loqalabs/loqa-audio-  │                        │
        │    bridge                 │                        │
        │                           │                        │
        │ 3. eas build --platform   │                        │
        │    ios --profile dev ─────►                        │
        │                           │                        │
        │                           │ 4. Clone repository    │
        │                           │                        │
        │                           │ 5. npm install         │
        │                           │    (install module)    │
        │                           │                        │
        │                           │ 6. npx expo prebuild   │
        │                           │    (autolinking)       │
        │                           │                        │
        │                           │ 7. pod install (iOS)   │
        │                           │    or gradle (Android) │
        │                           │                        │
        │                           │ 8. xcodebuild (iOS)    │
        │                           │    or gradle build     │
        │                           │                        │
        │                           │ 9. Archive .ipa/.apk ──► 10. Upload artifact
        │                           │                        │
        │ 11. Download build ◄──────┴────────────────────────┘
        │     (install on device)   │
        │                           │
        │ 12. Test audio streaming  │
        │     (verify works)        │
        │                           │
        ▼                           ▼
```

**Sequencing Constraints:**

1. **Story 5.1 must precede 5.2**: Package configuration must be finalized before CI can validate it
2. **Story 5.2 must precede 5.3**: CI pipeline must be working before automated publishing
3. **Story 5.3 must precede 5.4**: Package must be published to npm before EAS Build can install it
4. **Story 5.5 can run in parallel**: Documentation can be written alongside 5.1-5.4

## Non-Functional Requirements

### Performance

**NFR-P1: CI Pipeline Execution Time**
- **Target**: CI pipeline completes in <10 minutes for standard PRs
- **Measurement**: GitHub Actions workflow duration from trigger to completion
- **Optimization Strategy**: Run jobs in parallel (lint, test, iOS build, Android build, package validation)
- **Validation**: Monitor GitHub Actions metrics dashboard

**NFR-P2: npm Package Size**
- **Target**: Package tarball <500 KB (excluding node_modules)
- **Measurement**: Output of `npm pack` command
- **Impact**: Smaller packages install faster and reduce bandwidth costs
- **Validation**: Package validation job checks tarball size

**NFR-P3: npm Install Time**
- **Target**: `npx expo install @loqalabs/loqa-audio-bridge` completes in <60 seconds on standard internet connection
- **Measurement**: Time from command start to package installed confirmation
- **Reference**: PRD NFR2 requirement
- **Validation**: Manual testing during Story 5.4

**NFR-P4: Publishing Latency**
- **Target**: Automated publish workflow completes in <15 minutes from tag push
- **Measurement**: GitHub Actions CD workflow duration
- **Steps**: CI validation (10 min) + npm publish (1 min) + GitHub Release (1 min)
- **Validation**: Monitor publish workflow runs

### Security

**NFR-S1: NPM Token Security**
- **Requirement**: NPM_TOKEN stored securely in GitHub Secrets (not in code)
- **Scope**: write:packages permission only (principle of least privilege)
- **Rotation**: Token rotated every 90 days (manual process)
- **Validation**: Code review ensures no hardcoded tokens

**NFR-S2: Package Integrity**
- **Requirement**: Published package contains only intended files (no accidental secrets)
- **Validation**: Package validation job scans for .env files, credentials.json, API keys
- **Prevention**: .npmignore excludes common secret file patterns
- **Audit**: Manual review of `npm pack` output before first publish

**NFR-S3: Dependency Vulnerability Scanning**
- **Requirement**: No high/critical severity vulnerabilities in dependencies
- **Tool**: GitHub Dependabot (automatic PR creation for updates)
- **Policy**: Critical vulnerabilities patched within 7 days
- **Validation**: `npm audit` runs in CI pipeline (informational only in v0.3.0)

**NFR-S4: Code Signing and Provenance**
- **Current State**: Not implemented in v0.3.0
- **Future Enhancement**: npm package provenance (v0.4.0+)
- **Rationale**: npm provenance requires npm CLI 9.5+ and GitHub-hosted publishing
- **Reference**: https://docs.npmjs.com/generating-provenance-statements

### Reliability/Availability

**NFR-R1: CI Pipeline Reliability**
- **Target**: 95% success rate on valid PRs (failures only due to code issues, not infrastructure)
- **Measurement**: Percentage of CI runs that complete without infrastructure errors
- **Mitigation**: Use stable GitHub Actions runner images (ubuntu-latest, macos-latest)
- **Monitoring**: GitHub Actions status history

**NFR-R2: npm Registry Availability**
- **Dependency**: npm registry uptime (99.9% SLA from npmjs.com)
- **Failure Mode**: Publish workflow fails if registry down
- **Recovery**: Automatic retry via workflow re-run
- **Alternative**: None (npm is single point of dependency)

**NFR-R3: Package Installation Success Rate**
- **Target**: 100% successful installs on supported Expo/RN versions
- **Validation**: Autolinking tests (Story 3.1, 3.2) + EAS Build validation (Story 5.4)
- **Error Handling**: Clear error messages if peer dependencies unsatisfied
- **Reference**: PRD NFR5 (autolinking works 100% of time)

**NFR-R4: Rollback Capability**
- **Requirement**: Ability to revert to previous version if critical bug found
- **Process**: `npm deprecate @loqalabs/loqa-audio-bridge@0.3.x "Critical bug, use 0.3.y"`
- **Timeline**: Deprecation notice posted within 4 hours of bug discovery
- **Patch Release**: Bug fix version published within 24 hours

### Observability

**NFR-O1: CI/CD Pipeline Visibility**
- **Logs**: All GitHub Actions jobs output detailed logs
- **Retention**: Logs retained for 90 days (GitHub default)
- **Access**: Public logs for open source repository
- **Alerts**: Email notification on publish workflow failure

**NFR-O2: Package Download Metrics**
- **Source**: npm registry analytics (https://www.npmjs.com/package/@loqalabs/loqa-audio-bridge)
- **Metrics**: Weekly downloads, version distribution, download trends
- **Monitoring**: Manual review monthly
- **Usage**: Inform deprecation decisions and prioritize compatibility

**NFR-O3: Build Failure Notifications**
- **Trigger**: CI pipeline failure on main branch
- **Channel**: GitHub notification to repository maintainers
- **Response**: Investigate and fix within 24 hours
- **Escalation**: If blocking releases, escalate to architect (Winston)

**NFR-O4: Release Audit Trail**
- **Git Tags**: Every release tagged with semantic version (v0.3.0, v0.3.1)
- **GitHub Releases**: Every publish creates GitHub Release with auto-generated notes
- **CHANGELOG.md**: Human-readable version history
- **Provenance**: Git commit hash linked to published npm version (via package.json version field)

## Dependencies and Integrations

### External Service Dependencies

| Service | Version/API | Purpose | SLA/Reliability | Mitigation |
|---------|-------------|---------|-----------------|------------|
| **npm Registry** | REST API v1 | Package hosting and distribution | 99.9% uptime | None (critical dependency) |
| **GitHub Actions** | Cloud runners | CI/CD automation | 99.95% uptime | Manual local builds if blocked |
| **GitHub Container Registry** | - | Runner images (ubuntu-latest, macos-latest) | 99.95% uptime | None (infrastructure dependency) |
| **EAS Build** | Expo SDK 52+ | Cloud build validation | 99% uptime | Local builds sufficient for validation |
| **CocoaPods CDN** | trunk.cocoapods.org | iOS dependency resolution | 99.5% uptime | Fallback to local pod cache |
| **Maven Central** | - | Android dependency resolution | 99.9% uptime | Gradle local cache |

### Build Tool Dependencies

**Node.js Ecosystem:**
```json
{
  "devDependencies": {
    "typescript": "^5.3.0",
    "eslint": "^8.0.0",
    "prettier": "^3.0.0",
    "expo-module-scripts": "^5.0.7"
  }
}
```

**iOS Build Dependencies:**
- Xcode 14+ or 15+ (macOS runners come pre-installed)
- CocoaPods 1.11+ (auto-installed by GitHub Actions)
- Swift 5.4+ (bundled with Xcode)

**Android Build Dependencies:**
- JDK 17 (Temurin distribution)
- Gradle 8.x (wrapper included in project)
- Android SDK API 34 (auto-downloaded by Gradle)
- Kotlin 1.8+ (configured in build.gradle)

### GitHub Actions Marketplace Dependencies

| Action | Version | Purpose | Reliability |
|--------|---------|---------|-------------|
| `actions/checkout@v4` | v4 | Clone repository | ✅ Stable |
| `actions/setup-node@v4` | v4 | Install Node.js | ✅ Stable |
| `actions/setup-java@v4` | v4 | Install JDK for Android builds | ✅ Stable |
| `softprops/action-gh-release@v1` | v1 | Create GitHub Releases | ✅ Stable |

**Update Policy:** Pin to major versions (e.g., @v4) to get bug fixes but avoid breaking changes

### Integration Points

**Epic 1-2 Dependencies (Prerequisites):**
- Epic 5 requires package.json configured (Story 1.2)
- Epic 5 requires iOS podspec with test exclusions (Story 2.3)
- Epic 5 requires zero compilation warnings (Story 2.8)
- Epic 5 requires all tests passing (Stories 2.5, 2.6, 2.7)

**Epic 3 Dependencies (Validation):**
- Story 5.4 validates EAS Build using autolinking from Epic 3
- CI pipeline builds use same structure validated in Stories 3.1-3.2

**Epic 4 Dependencies (Documentation):**
- CHANGELOG.md (Story 5.5) references MIGRATION.md from Story 4.4
- Release process assumes README.md exists from Story 4.1

### Credential and Secret Management

| Secret Name | Scope | Storage | Rotation |
|-------------|-------|---------|----------|
| `NPM_TOKEN` | Publish to npm registry | GitHub repository secrets | Every 90 days |
| `GITHUB_TOKEN` | Create releases (auto-provided) | GitHub Actions environment | Automatic |

**NPM_TOKEN Setup Process:**
1. Login to npmjs.com with Loqa Labs account
2. Navigate to Access Tokens settings
3. Generate Automation token with "Publish" permission
4. Copy token to GitHub repository settings → Secrets → NPM_TOKEN
5. Document rotation date in team wiki

### Package Distribution Dependencies

**Installation Methods:**
- Primary: `npx expo install @loqalabs/loqa-audio-bridge` (uses npm registry)
- Alternative: `npm install @loqalabs/loqa-audio-bridge` (also uses npm)
- Development: `npm install /path/to/loqa-audio-bridge` (local testing)

**Registry Mirrors:**
- No alternative registries configured (npm only)
- Future consideration: GitHub Packages as backup (v0.4.0+)

## Acceptance Criteria (Authoritative)

### Story 5.1: Configure npm Package for Publishing

**AC-5.1.1: package.json Configuration**
- ✅ GIVEN package.json exists
- ✅ WHEN I inspect metadata fields
- ✅ THEN "main" points to "build/index.js"
- ✅ AND "types" points to "build/index.d.ts"
- ✅ AND "files" array includes: build/, src/, ios/, android/, hooks/, expo-module.config.json, LoqaAudioBridge.podspec, README.md, API.md, INTEGRATION_GUIDE.md, MIGRATION.md, CHANGELOG.md, LICENSE
- ✅ AND "publishConfig.access" is "public"

**AC-5.1.2: .npmignore Exclusions**
- ✅ GIVEN .npmignore file exists
- ✅ WHEN I run `npm pack` and extract tarball
- ✅ THEN __tests__/ directory is absent
- ✅ AND ios/Tests/ directory is absent
- ✅ AND example/ directory is absent
- ✅ AND .github/ directory is absent
- ✅ AND no *.test.ts or *.spec.ts files present
- ✅ AND tsconfig.json, .eslintrc.js, .prettierrc absent

**AC-5.1.3: Package Size Validation**
- ✅ GIVEN tarball created via `npm pack`
- ✅ WHEN I check file size
- ✅ THEN size is <500 KB (excluding node_modules)

**Traceability:** FR21, FR22, FR23

---

### Story 5.2: Create GitHub Actions CI Pipeline

**AC-5.2.1: CI Workflow Triggers**
- ✅ GIVEN .github/workflows/ci.yml exists
- ✅ WHEN I create a pull request to main
- ✅ THEN CI workflow triggers automatically
- ✅ AND when I push to main branch
- ✅ THEN CI workflow triggers automatically

**AC-5.2.2: Lint Job**
- ✅ GIVEN CI workflow running
- ✅ WHEN lint job executes
- ✅ THEN `npm run lint` passes with zero errors
- ✅ AND `npm run format -- --check` passes

**AC-5.2.3: TypeScript Test Job**
- ✅ GIVEN CI workflow running
- ✅ WHEN test job executes
- ✅ THEN `npm test` passes with all tests green
- ✅ AND `npm run build` compiles successfully

**AC-5.2.4: iOS Build Job**
- ✅ GIVEN CI workflow running on macos-latest
- ✅ WHEN iOS build job executes
- ✅ THEN `pod install` succeeds in ios/ directory
- ✅ AND `xcodebuild -workspace ios/LoqaAudioBridge.xcworkspace -scheme LoqaAudioBridge clean build` succeeds
- ✅ AND build completes with zero warnings

**AC-5.2.5: Android Build Job**
- ✅ GIVEN CI workflow running on ubuntu-latest
- ✅ WHEN Android build job executes
- ✅ THEN JDK 17 installed successfully
- ✅ AND `./gradlew clean build` in android/ succeeds
- ✅ AND build completes with zero warnings

**AC-5.2.6: Package Validation Job**
- ✅ GIVEN CI workflow running
- ✅ WHEN package validation job executes
- ✅ THEN `npm pack` creates tarball
- ✅ AND validation script extracts and inspects contents
- ✅ AND script FAILS if *.test.ts, *.spec.ts, or *Tests.swift files found
- ✅ AND script FAILS if __tests__/, ios/Tests/, or example/ directories found
- ✅ AND script PASSES if no test files present
- ✅ AND validation confirms podspec has exclude_files directive

**AC-5.2.7: CI Pipeline Timing**
- ✅ GIVEN all CI jobs running in parallel
- ✅ WHEN workflow completes
- ✅ THEN total duration is <10 minutes

**Traceability:** FR9, FR21, Architecture Decision 3 (Layer 4)

---

### Story 5.3: Create Automated npm Publishing Workflow

**AC-5.3.1: Publishing Trigger**
- ✅ GIVEN .github/workflows/publish-npm.yml exists
- ✅ WHEN I create and push git tag matching `v*.*.*` pattern
- ✅ THEN publish workflow triggers automatically
- ✅ AND when I push non-version tag (e.g., `test-tag`)
- ✅ THEN publish workflow does NOT trigger

**AC-5.3.2: Pre-Publish Validation**
- ✅ GIVEN publish workflow triggered by tag v0.3.0
- ✅ WHEN workflow executes
- ✅ THEN npm ci, npm run lint, npm test, npm run build all run
- ✅ AND package validation runs (same as Story 5.2)
- ✅ AND if any validation fails, publish is aborted

**AC-5.3.3: npm Publish Execution**
- ✅ GIVEN all validations passed
- ✅ WHEN npm publish runs
- ✅ THEN command is `npm publish --access public`
- ✅ AND NPM_TOKEN secret used for authentication
- ✅ AND package published to https://www.npmjs.com/package/@loqalabs/loqa-audio-bridge
- ✅ AND version matches tag (e.g., tag v0.3.0 → version 0.3.0)

**AC-5.3.4: GitHub Release Creation**
- ✅ GIVEN npm publish succeeded
- ✅ WHEN GitHub Release step executes
- ✅ THEN release created with tag as title
- ✅ AND tarball file attached as asset
- ✅ AND release notes auto-generated from commits since last tag

**AC-5.3.5: Post-Publish Validation**
- ✅ GIVEN publish workflow completed
- ✅ WHEN I run `npx expo install @loqalabs/loqa-audio-bridge` in fresh Expo project
- ✅ THEN package installs successfully
- ✅ AND correct version installed (matches tag)

**Traceability:** FR21, FR22, FR24, Architecture Decision 4

---

### Story 5.4: Validate EAS Build Compatibility

**AC-5.4.1: EAS Build Setup**
- ✅ GIVEN package published to npm (Story 5.3 complete)
- ✅ WHEN I create fresh Expo project: `npx create-expo-app eas-test`
- ✅ THEN project created successfully
- ✅ AND when I run `npx expo install @loqalabs/loqa-audio-bridge`
- ✅ THEN package installs from npm registry

**AC-5.4.2: iOS EAS Build**
- ✅ GIVEN package installed in test project
- ✅ WHEN I run `eas build --platform ios --profile development`
- ✅ THEN EAS cloud build starts
- ✅ AND build logs show LoqaAudioBridge autolinking detected
- ✅ AND `pod install` succeeds in cloud environment
- ✅ AND xcodebuild succeeds with zero errors
- ✅ AND .ipa file generated and downloadable

**AC-5.4.3: Android EAS Build**
- ✅ GIVEN package installed in test project
- ✅ WHEN I run `eas build --platform android --profile development`
- ✅ THEN EAS cloud build starts
- ✅ AND build logs show LoqaAudioBridge autolinking detected
- ✅ AND Gradle build succeeds with zero errors
- ✅ AND .apk file generated and downloadable

**AC-5.4.4: No Special Configuration Required**
- ✅ GIVEN EAS builds successful
- ✅ WHEN I review eas.json configuration
- ✅ THEN no custom buildConfiguration for loqa-audio-bridge
- ✅ AND no special plugins or environment variables required
- ✅ AND standard Expo eas.json sufficient

**AC-5.4.5: Runtime Validation**
- ✅ GIVEN .ipa and .apk downloaded from EAS
- ✅ WHEN I install on physical iOS device
- ✅ THEN app launches successfully
- ✅ AND audio streaming functionality works (basic test)
- ✅ AND when I install on physical Android device
- ✅ THEN app launches successfully
- ✅ AND audio streaming functionality works (basic test)

**Traceability:** FR38

---

### Story 5.5: Create CHANGELOG.md and Release Process Documentation

**AC-5.5.1: CHANGELOG.md Format**
- ✅ GIVEN CHANGELOG.md file created in project root
- ✅ WHEN I inspect contents
- ✅ THEN format follows Keep a Changelog specification
- ✅ AND includes ## [0.3.0] - 2025-11-14 section
- ✅ AND subsections: Added, Changed, Fixed, Deprecated, Removed, Security
- ✅ AND references MIGRATION.md for upgrade instructions

**AC-5.5.2: v0.3.0 Changelog Content**
- ✅ GIVEN CHANGELOG.md v0.3.0 section
- ✅ WHEN I review entries
- ✅ THEN "Added" lists: npm packaging, CI/CD, documentation, example app, test exclusion
- ✅ AND "Fixed" lists: Swift required keyword, deprecated iOS API, test file shipping
- ✅ AND "Changed" lists: Package renamed to @loqalabs/loqa-audio-bridge, structure regenerated

**AC-5.5.3: RELEASING.md Process Documentation**
- ✅ GIVEN RELEASING.md file created in project root
- ✅ WHEN I review contents
- ✅ THEN semantic versioning rules documented (MAJOR.MINOR.PATCH)
- ✅ AND pre-release checklist includes: tests passing, CHANGELOG updated, version bumped, docs updated, example tested
- ✅ AND release steps documented: `npm version [type]`, `git push origin v*.*.*`, verify publish
- ✅ AND post-release validation checklist: installable via npm, fresh Expo integration works

**AC-5.5.4: Version Numbering Policy**
- ✅ GIVEN RELEASING.md documentation
- ✅ WHEN I review versioning section
- ✅ THEN MAJOR version for breaking API changes clearly defined
- ✅ AND MINOR version for new features, non-breaking enhancements
- ✅ AND PATCH version for bug fixes, documentation updates

**AC-5.5.5: Rollback Procedure**
- ✅ GIVEN RELEASING.md documentation
- ✅ WHEN I review rollback section
- ✅ THEN `npm deprecate` command documented with example
- ✅ AND timeline specified: deprecation within 4 hours, patch within 24 hours
- ✅ AND communication plan: GitHub Issues, Voiceline Slack notification

**Traceability:** FR24, FR25

## Traceability Mapping

| Acceptance Criteria | Spec Section | Component | Test Strategy |
|---------------------|--------------|-----------|---------------|
| **AC-5.1.1**: package.json config | Data Models → npm Package Metadata | package.json | Manual inspection + CI validation |
| **AC-5.1.2**: .npmignore exclusions | Architecture Alignment → Decision 3 Layer 3 | .npmignore | Package validation job (automated) |
| **AC-5.1.3**: Package size <500KB | NFR-P2 | Tarball | Package validation job |
| **AC-5.2.1**: CI triggers | APIs → GitHub Actions Workflow Events | .github/workflows/ci.yml | Test PR creation |
| **AC-5.2.2**: Lint job | Services → CI Pipeline → Lint | npm run lint | CI execution |
| **AC-5.2.3**: TypeScript tests | Services → CI Pipeline → Test | npm test | CI execution |
| **AC-5.2.4**: iOS build | APIs → Xcode Build Tools | xcodebuild | CI execution (macOS runner) |
| **AC-5.2.5**: Android build | APIs → Gradle Build Tools | ./gradlew | CI execution (ubuntu runner) |
| **AC-5.2.6**: Package validation | Architecture Alignment → Decision 3 Layer 4 | CI validation script | CI execution + manual verification |
| **AC-5.2.7**: CI timing <10 min | NFR-P1 | Parallel job execution | GitHub Actions metrics |
| **AC-5.3.1**: Publish trigger | APIs → GitHub Actions Workflow Events | .github/workflows/publish-npm.yml | Test tag push |
| **AC-5.3.2**: Pre-publish validation | Workflows → Workflow 1 Steps 8-12 | CI validation in publish workflow | Workflow execution |
| **AC-5.3.3**: npm publish | APIs → npm Registry API | npm publish command | Publish workflow execution |
| **AC-5.3.4**: GitHub Release | APIs → GitHub Releases API | softprops/action-gh-release | Workflow execution |
| **AC-5.3.5**: Post-publish install | NFR-R3 | npm registry + autolinking | Fresh Expo project test |
| **AC-5.4.1**: EAS setup | Dependencies → EAS Build Service | EAS Build API | Manual EAS build trigger |
| **AC-5.4.2**: iOS EAS build | Workflows → Workflow 3 | EAS remote macOS builder | Cloud build execution |
| **AC-5.4.3**: Android EAS build | Workflows → Workflow 3 | EAS remote Linux builder | Cloud build execution |
| **AC-5.4.4**: No special config | Architecture Alignment → EAS Compatibility | eas.json | Configuration review |
| **AC-5.4.5**: Runtime validation | NFR-R3 | Audio streaming module | Physical device testing |
| **AC-5.5.1**: CHANGELOG format | Data Models → CHANGELOG.md Contract | CHANGELOG.md | Manual review |
| **AC-5.5.2**: v0.3.0 content | Services → Release Documentation | CHANGELOG.md v0.3.0 section | Content review |
| **AC-5.5.3**: RELEASING.md | Services → Release Documentation | RELEASING.md | Manual review |
| **AC-5.5.4**: Version policy | NFR-O4 | Semantic versioning rules | Documentation review |
| **AC-5.5.5**: Rollback procedure | NFR-R4 | npm deprecate process | Process documentation |

**Coverage Summary:**
- 25 Acceptance Criteria mapped to technical specifications
- 10 Functional Requirements covered (FR9, FR21-25, FR34-38)
- 4 Architecture Decisions implemented (Decision 3 Layer 3-4, Decision 4)
- 16 Non-Functional Requirements validated (Performance: 4, Security: 4, Reliability: 4, Observability: 4)

## Risks, Assumptions, Open Questions

### Risks

**RISK-1: npm Registry Downtime During Release**
- **Probability**: Low (npm 99.9% uptime SLA)
- **Impact**: High (blocks v0.3.0 launch)
- **Mitigation**: Schedule release during npm off-peak hours (avoid Monday mornings UTC)
- **Contingency**: Workflow re-run after registry recovery (automated retry)

**RISK-2: GitHub Actions macOS Runner Availability**
- **Probability**: Medium (macOS runners sometimes queued during peak)
- **Impact**: Medium (CI delays, not blocking)
- **Mitigation**: Use self-hosted macOS runner if persistent issues (v0.4.0+)
- **Monitoring**: GitHub Actions queue time metrics

**RISK-3: Test Files Accidentally Shipped Despite Multi-Layer Exclusion**
- **Probability**: Low (4 layers of defense)
- **Impact**: High (repeats v0.2.0 failure)
- **Mitigation**: Manual tarball inspection before first publish (Story 5.1)
- **Detection**: CI package validation job catches this (Story 5.2)
- **Recovery**: Immediate patch release with corrected .npmignore

**RISK-4: Breaking Change in Expo Modules Core During Epic 5**
- **Probability**: Low (Expo 52-54 stable)
- **Impact**: Medium (requires code updates in Epic 2)
- **Mitigation**: Pin expo-modules-core to specific version in peerDependencies
- **Monitoring**: Dependabot alerts for expo-modules-core updates

**RISK-5: EAS Build Fails Due to Cloud Environment Differences**
- **Probability**: Low (autolinking tested locally in Epic 3)
- **Impact**: Medium (delays Story 5.4 completion)
- **Mitigation**: Test EAS Build early in Epic 5 (don't wait until Story 5.4)
- **Fallback**: Document EAS Build requirements if custom config needed (contradicts FR38 but acceptable if unavoidable)

### Assumptions

**ASSUME-1: npm Account Access**
- **Assumption**: Loqa Labs has npm account with publish permissions for @loqalabs scope
- **Validation**: Verify account access before Story 5.1
- **Dependency**: Cannot publish without npm account

**ASSUME-2: GitHub Actions Enabled**
- **Assumption**: GitHub repository has Actions enabled (not disabled by org policy)
- **Validation**: Check repository settings → Actions → Allow all actions
- **Dependency**: CI/CD workflows require Actions enabled

**ASSUME-3: NPM_TOKEN Available**
- **Assumption**: NPM automation token can be generated and stored in GitHub Secrets
- **Validation**: Generate token during Story 5.1, store in Secrets
- **Security**: Token has publish-only scope (not admin)

**ASSUME-4: EAS Account Access**
- **Assumption**: Loqa Labs has Expo account with EAS Build access
- **Validation**: Login with `eas login` during Story 5.4
- **Cost**: EAS Build has free tier sufficient for validation (limited builds/month)

**ASSUME-5: Example App from Epic 3 Runs Successfully**
- **Assumption**: Epic 3 example app validates autolinking works correctly
- **Validation**: Epic 3 Story 3.5 acceptance criteria met
- **Dependency**: EAS Build validation (Story 5.4) relies on working module

**ASSUME-6: Documentation from Epic 4 Complete**
- **Assumption**: README.md, API.md, INTEGRATION_GUIDE.md exist and accurate
- **Validation**: Epic 4 stories 4.1-4.3 complete
- **Impact**: CHANGELOG.md references these docs

### Open Questions

**QUESTION-1: Should we publish v0.3.0-beta first?**
- **Context**: Allows Voiceline team to test before public release
- **Options**: (A) Publish 0.3.0-beta.1 with beta tag, (B) Direct to 0.3.0
- **Recommendation**: Option A (beta release) for safety
- **Decision Required**: Product Manager approval
- **Timeline**: Resolve before Story 5.3

**QUESTION-2: Who approves first npm publish?**
- **Context**: First publish is irreversible (cannot unpublish after 72 hours)
- **Options**: (A) Anna self-approves, (B) Require Winston review, (C) Require PM review
- **Recommendation**: Option C (PM approval) for v0.3.0, then Option A for patches
- **Decision Required**: PM clarification
- **Impact**: Affects Story 5.3 execution

**QUESTION-3: Should CI run on forks (external contributors)?**
- **Context**: Public repo may receive external PRs in future
- **Security Risk**: Forks could attempt to exfiltrate NPM_TOKEN via CI
- **Options**: (A) Require manual approval for fork CI runs, (B) Disable fork CI
- **Recommendation**: Option A (manual approval)
- **Decision Required**: Before repository goes public
- **GitHub Setting**: Settings → Actions → Fork pull request workflows from outside collaborators

**QUESTION-4: What is the npm package.json "repository" URL format?**
- **Context**: Loqa is a monorepo; loqa-audio-bridge is in modules/ subdirectory
- **Options**:
  - (A) "https://github.com/loqalabs/loqa" (root repo)
  - (B) "https://github.com/loqalabs/loqa/tree/main/modules/loqa-audio-bridge" (subdirectory)
- **Recommendation**: Option B for accuracy
- **Decision Required**: Story 5.1 execution
- **Impact**: npm registry "Repository" link

**QUESTION-5: Should we enable npm package provenance?**
- **Context**: npm provenance provides cryptographic proof of publish source
- **Requirement**: Requires npm CLI 9.5+ and GitHub-hosted publishing
- **Current State**: Not implemented in v0.3.0 (NFR-S4)
- **Options**: (A) Enable now if feasible, (B) Defer to v0.4.0
- **Recommendation**: Option B (defer) - reduces Epic 5 scope
- **Decision Required**: Product Manager prioritization

## Test Strategy Summary

### Unit Testing (Existing - Epic 2)
- **Scope**: TypeScript API layer, buffer utilities, React hooks
- **Framework**: Jest + @testing-library/react-native
- **Coverage**: 80% (baseline from v0.2.0)
- **Epic 5 Validation**: CI pipeline runs `npm test` (Story 5.2)

### Integration Testing (Epic 3)
- **Scope**: Autolinking validation, example app functionality
- **Platforms**: iOS (simulator + device), Android (emulator + device)
- **Epic 5 Validation**: EAS Build downloads and device testing (Story 5.4)

### CI/CD Pipeline Testing (Epic 5 - New)

**Test Type 1: CI Workflow Validation**
- **Method**: Create test PR with intentional lint error
- **Expected Result**: Lint job fails, PR blocked from merge
- **Validation**: Story 5.2 AC-5.2.2

**Test Type 2: Package Exclusion Testing**
- **Method**: Temporarily add test file to package, trigger CI
- **Expected Result**: Package validation job fails with clear error
- **Validation**: Story 5.2 AC-5.2.6

**Test Type 3: Publish Workflow Dry Run**
- **Method**: Create test tag (v0.3.0-test), observe workflow without actual publish
- **Expected Result**: Workflow runs validation steps but skips publish
- **Validation**: Story 5.3 AC-5.3.1

**Test Type 4: EAS Build Smoke Test**
- **Method**: Fresh Expo app + package install + `eas build --platform ios`
- **Expected Result**: Build succeeds, .ipa installs on device, audio streams
- **Validation**: Story 5.4 AC-5.4.2, AC-5.4.5

### Manual Testing Checklist (Pre-Release)

**Before Story 5.3 (First Publish):**
- [ ] Extract npm pack tarball and manually inspect contents
- [ ] Verify no test files present (grep -r "*.test.ts")
- [ ] Verify no __tests__/ or ios/Tests/ directories
- [ ] Check tarball size <500 KB
- [ ] Verify package.json metadata accurate (name, version, description)
- [ ] Test local install: `npm install /path/to/tarball.tgz` in fresh Expo app
- [ ] Build iOS app with local install
- [ ] Build Android app with local install
- [ ] Verify audio streaming works in both builds

**After Story 5.3 (Post-Publish):**
- [ ] Install from npm: `npx expo install @loqalabs/loqa-audio-bridge`
- [ ] Verify correct version installed
- [ ] Build iOS app with npm install
- [ ] Build Android app with npm install
- [ ] Check npm registry page: https://www.npmjs.com/package/@loqalabs/loqa-audio-bridge
- [ ] Verify README renders correctly on npm
- [ ] Check GitHub Release created with tarball attached
- [ ] Test installation on Windows (if cross-platform dev team)

### Regression Testing

**Scope:** Ensure Epic 5 changes don't break Epic 1-4 work
- [ ] TypeScript compilation still works (`npm run build`)
- [ ] All unit tests pass (`npm test`)
- [ ] Linting passes (`npm run lint`)
- [ ] iOS native module compiles (xcodebuild)
- [ ] Android native module compiles (./gradlew build)
- [ ] Example app runs on iOS (npx expo run:ios)
- [ ] Example app runs on Android (npx expo run:android)
- [ ] Autolinking still works (no manual steps required)

### Performance Testing

**CI Pipeline Performance:**
- **Baseline**: Record initial CI run duration for each job
- **Target**: <10 minutes total (NFR-P1)
- **Monitoring**: GitHub Actions timing metrics per job
- **Optimization**: If >10 min, investigate slowest job and optimize

**npm Install Performance:**
- **Test**: Fresh Expo project, time `npx expo install @loqalabs/loqa-audio-bridge`
- **Target**: <60 seconds on standard connection (NFR-P3)
- **Variables**: Network speed, npm cache state
- **Validation**: Test on 3 different machines/networks

### Security Testing

**Secret Scanning:**
- **Tool**: GitHub secret scanning (automatic)
- **Manual**: Grep tarball for common secret patterns (.env, API_KEY, token)
- **Validation**: Story 5.1 AC-5.1.2

**Dependency Audit:**
- **Tool**: `npm audit` (run in CI)
- **Threshold**: Zero high/critical vulnerabilities
- **Remediation**: Update vulnerable dependencies or document acceptable risk

### Acceptance Testing

**End-to-End User Journey:**
1. User finds package on npm
2. User reads README
3. User runs `npx expo install @loqalabs/loqa-audio-bridge`
4. User follows quick start example
5. User builds app successfully
6. User's app streams audio correctly

**Success Criteria:** Complete journey in <30 minutes (PRD goal)

---

**Epic 5 Test Coverage Summary:**
- ✅ Automated: CI pipeline (lint, test, build, package validation)
- ✅ Integration: EAS Build validation (cloud environment)
- ✅ Manual: Pre-publish tarball inspection, post-publish verification
- ✅ Regression: Epic 1-4 functionality unchanged
- ✅ Performance: CI timing, npm install speed
- ✅ Security: Secret scanning, dependency audit
- ✅ Acceptance: End-to-end user journey (<30 min)
