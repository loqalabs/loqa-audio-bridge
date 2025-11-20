# Story 2.10: Validate Expo Module Structure for Metro Bundler Compatibility

**Epic**: 2 - Code Migration & Quality Fixes
**Story Key**: 2-10-validate-expo-module-structure
**Story Type**: Quality / Validation
**Status**: ready-for-dev
**Created**: 2025-11-17
**Priority**: MEDIUM - Prevents Metro bundler issues discovered in Story 3-4

---

## User Story

As a developer,
I want to validate that the module structure follows Expo conventions,
So that Metro bundler can correctly resolve the compiled code (prevents Story 3-4 issue).

---

## Context

**Discovery**: Story 3-4 revealed that root-level TypeScript files cause Metro bundler to resolve source instead of compiled JavaScript, causing runtime failures despite zero TypeScript compilation warnings.

**Gap in Story 2-8**: Zero compilation warnings validates type correctness but NOT module structure or Metro bundler compatibility.

**See**: CRITICAL-LEARNINGS-METRO-BUNDLER.md, EPIC-2-RE-EVALUATION.md

---

## Acceptance Criteria

**Given** the module has been migrated and compiled (Epic 2 complete)
**When** I run module structure validation checks
**Then** the following structural rules are enforced:

### AC1: No Root-Level TypeScript Files

**When** I check for root-level TypeScript files (except config files):

```bash
find . -maxdepth 1 -name "*.ts" ! -name "*.config.ts" ! -name "jest.setup.ts"
```

**Then** the command returns empty (no root-level TypeScript source files)

**And** all TypeScript source files are in `src/` or `hooks/` directories

### AC2: TypeScript Config Compiles Only from Source Directories

**When** I check `tsconfig.json` includes:

```bash
grep '"include":' tsconfig.json
```

**Then** it contains only `["./src"]` or `["./src", "./hooks"]`

**And** it does NOT include root-level files like `["./index.ts"]`

### AC3: Package.json Points to Compiled JavaScript

**When** I check `package.json` main entry point:

```bash
grep '"main":' package.json
```

**Then** it points to `"build/index.js"` (compiled output)

**And** it does NOT point to TypeScript source like `"index.ts"` or `"src/index.ts"`

### AC4: Compiled Output Exists and Contains Exports

**When** I check the compiled output:

```bash
ls -la build/index.js
grep "export" build/index.js
```

**Then** `build/index.js` exists and is not empty

**And** it contains the expected module exports (e.g., `startAudioStream`, `stopAudioStream`)

---

## Tasks/Subtasks

### Task 1: Create Module Structure Validation Script

- [ ] Create `scripts/validate-module-structure.sh`
- [ ] Add shebang and error handling:

  ```bash
  #!/bin/bash
  set -e  # Exit on error

  echo "🔍 Validating Expo Module Structure..."
  ```

- [ ] Make script executable: `chmod +x scripts/validate-module-structure.sh`

### Task 2: Implement Root-Level TypeScript Check

- [ ] Add check for root-level TypeScript files:
  ```bash
  echo "1️⃣ Checking for root-level TypeScript files..."
  ROOT_TS=$(find . -maxdepth 1 -name "*.ts" ! -name "*.config.ts" ! -name "jest.setup.ts" ! -name "*.d.ts")
  if [ ! -z "$ROOT_TS" ]; then
    echo "❌ ERROR: Root-level TypeScript files detected. Move to src/"
    echo "$ROOT_TS"
    exit 1
  fi
  echo "✅ No root-level TypeScript files found"
  ```

### Task 3: Implement tsconfig.json Validation

- [ ] Add check for tsconfig.json includes:
  ```bash
  echo "2️⃣ Checking tsconfig.json includes..."
  if ! grep -q '"include": \["./src"\]' tsconfig.json && \
     ! grep -q '"include": \["./src", "./hooks"\]' tsconfig.json; then
    echo "❌ ERROR: tsconfig.json must only compile from ./src (and optionally ./hooks)"
    echo "Current includes:"
    grep '"include":' tsconfig.json
    exit 1
  fi
  echo "✅ tsconfig.json includes are correct"
  ```

### Task 4: Implement package.json Main Entry Validation

- [ ] Add check for package.json main entry:
  ```bash
  echo "3️⃣ Checking package.json main entry..."
  if ! grep -q '"main": "build/index.js"' package.json; then
    echo "❌ ERROR: package.json main must point to build/index.js"
    echo "Current main:"
    grep '"main":' package.json
    exit 1
  fi
  echo "✅ package.json main entry is correct"
  ```

### Task 5: Implement Compiled Output Validation

- [ ] Add check for compiled output:

  ```bash
  echo "4️⃣ Checking compiled output..."
  if [ ! -f "build/index.js" ]; then
    echo "❌ ERROR: build/index.js does not exist. Run 'npm run build'"
    exit 1
  fi

  if [ ! -s "build/index.js" ]; then
    echo "❌ ERROR: build/index.js is empty"
    exit 1
  fi

  # Check for expected exports
  if ! grep -q "export" build/index.js && ! grep -q "exports" build/index.js; then
    echo "⚠️  WARNING: No exports found in build/index.js"
  fi

  echo "✅ Compiled output exists and contains exports"
  ```

### Task 6: Add Success Summary

- [ ] Add final success message:
  ```bash
  echo ""
  echo "✅ Module structure validation PASSED!"
  echo "   - No root-level TypeScript files"
  echo "   - tsconfig.json compiles only from src/"
  echo "   - package.json points to build/index.js"
  echo "   - Compiled output exists and valid"
  exit 0
  ```

### Task 7: Test Validation Script

- [ ] Navigate to module root
- [ ] Run validation script: `./scripts/validate-module-structure.sh`
- [ ] Verify all checks pass
- [ ] Test with intentionally broken structure to verify error detection

### Task 8: Add to package.json Scripts

- [ ] Add validation script to package.json:
  ```json
  {
    "scripts": {
      "validate:structure": "./scripts/validate-module-structure.sh"
    }
  }
  ```
- [ ] Test running via npm: `npm run validate:structure`

### Task 9: Update Epic 5 CI/CD Story

- [ ] Document that Story 5-2 (CI/CD) should include module structure validation
- [ ] Add to CI pipeline checklist:
  ```yaml
  - name: Validate Module Structure
    run: npm run validate:structure
  ```

### Task 10: Document in README

- [ ] Add "Module Structure Validation" section to development docs
- [ ] Explain why this validation is necessary (Metro bundler compatibility)
- [ ] Include instructions for running validation locally

---

## Dev Notes

### Technical Context

**Why This Story Exists**: Story 3-4 discovered that TypeScript compilation success doesn't guarantee Metro bundler compatibility. This story adds structural validation to prevent Metro resolution issues.

**Relationship to Story 2-8**: Story 2-8 validates zero compilation warnings (type correctness). This story validates module structure (bundler compatibility). Both are required for production readiness.

**Metro Bundler Behavior**: When using `file:..` dependencies (common for local development and example apps), npm creates symlinks that include ALL files. Metro preferentially resolves TypeScript source files over compiled JavaScript, even when `package.json` specifies `"main": "build/index.js"`.

### Standard Expo Module Structure

```
loqa-audio-bridge/
├── src/                    ✅ ALL TypeScript source goes here
│   ├── index.ts           ✅ Entry point (re-exports from api.ts)
│   ├── api.ts             ✅ Main API implementation
│   ├── types.ts           ✅ Type definitions
│   └── *.ts               ✅ Other source files
├── hooks/                  ✅ React hooks (if any)
│   └── *.ts
├── build/                  ✅ Compiled output (gitignored, npm published)
│   ├── index.js           ✅ Compiled entry point
│   ├── index.d.ts         ✅ Type declarations
│   └── **/*.js            ✅ All compiled files
├── ios/                    ✅ Native iOS code
├── android/                ✅ Native Android code
├── example/                ✅ Example app (gitignored, not published)
├── package.json            ✅ "main": "build/index.js"
├── tsconfig.json           ✅ "include": ["./src"]
├── jest.config.ts          ✅ Config file (allowed at root)
└── README.md

❌ NEVER HAVE:
├── index.ts               ❌ Root-level TypeScript confuses Metro!
├── api.ts                 ❌ Root-level TypeScript confuses Metro!
```

### Why Root-Level TypeScript is Problematic

**Example Scenario**:

1. **Root-level index.ts** contains:

   ```typescript
   import LoqaAudioBridgeModule from './src/LoqaAudioBridgeModule';
   export * from './src/types';
   ```

2. **TypeScript compilation** (`npx tsc`) succeeds:

   - Compiles to `build/index.js`
   - Resolves `./src/*` paths correctly
   - Zero errors, zero warnings ✅

3. **Metro bundler** with `file:..` dependency:
   - Sees both `index.ts` (root) and `build/index.js`
   - Preferentially resolves `index.ts` (TypeScript source)
   - Tries to bundle `index.ts` directly
   - Fails to resolve `./src/*` paths (different resolution strategy)
   - Runtime error: `addAudioSampleListener is not a function` ❌

**The Fix**:

- Move `index.ts` → `src/api.ts`
- Update `src/index.ts` to `export * from './api'`
- Now Metro only sees `build/index.js` at root level
- Metro correctly bundles compiled output ✅

### Validation vs Compilation

| Check Type      | What It Validates                  | Tool           | Story      |
| --------------- | ---------------------------------- | -------------- | ---------- |
| **Compilation** | Type correctness, syntax           | `npx tsc`      | Story 2-8  |
| **Linting**     | Code style, best practices         | `npm run lint` | Story 2-8  |
| **Structure**   | Module layout, Metro compatibility | This script    | Story 2-10 |
| **Runtime**     | End-to-end functionality           | Example app    | Story 3-4  |

All four are required for production readiness.

### CI/CD Integration (Epic 5)

This validation should be added to the CI pipeline (Story 5-2):

```yaml
name: Module Quality Checks
jobs:
  validate:
    steps:
      - name: TypeScript Compilation
        run: npx tsc --noEmit

      - name: Linting
        run: npm run lint

      - name: Module Structure Validation # NEW
        run: npm run validate:structure

      - name: Unit Tests
        run: npm test
```

### Prevention Checklist for Future Modules

When creating new Expo modules or refactoring existing ones:

1. ✅ Generate with `create-expo-module` (correct structure from start)
2. ✅ Keep ALL TypeScript source in `src/` or `hooks/`
3. ✅ Never create root-level `.ts` files (except config files)
4. ✅ Run `npm run validate:structure` before committing
5. ✅ Test with `file:..` dependency before publishing
6. ✅ Verify Metro bundling succeeds in example app

---

## Cross-References

- **Story 3-4**: Where Metro bundler issue was discovered
- **Story 2-8**: Zero compilation warnings (type correctness)
- **CRITICAL-LEARNINGS-METRO-BUNDLER.md**: Full documentation of the issue
- **EPIC-2-RE-EVALUATION.md**: Recommendation to create this story
- **Story 5-2**: CI/CD pipeline (should include this validation)

---

## Definition of Done

- [ ] `scripts/validate-module-structure.sh` created and executable
- [ ] Check 1: No root-level TypeScript files (except config)
- [ ] Check 2: tsconfig.json includes only src/ (and optionally hooks/)
- [ ] Check 3: package.json main points to build/index.js
- [ ] Check 4: Compiled output exists and contains exports
- [ ] Validation script added to package.json scripts
- [ ] Script tested - all checks pass for current module
- [ ] Script tested with broken structure - correctly detects errors
- [ ] Documentation added to README (validation instructions)
- [ ] Epic 5 Story 5-2 updated to include structural validation in CI
- [ ] Story status updated in sprint-status.yaml (ready-for-dev → done)

---

## Success Metrics

**Before This Story**:

- TypeScript compilation succeeds
- Linting passes
- But Metro bundler can still fail at runtime

**After This Story**:

- All compilation/linting checks pass
- Module structure validated
- Metro bundler compatibility ensured
- Runtime failures prevented

**Impact**: Prevents Metro bundler issues that would block all downstream consumers including Voiceline team.
