# Critical Learning: Metro Bundler Module Resolution with file:.. Dependencies

**Date**: 2025-11-17
**Story**: 3-4-implement-example-app-audio-streaming-demo
**Impact**: CRITICAL - Blocks all file:.. dependency usage in example apps and consumer apps

## Problem Summary

When implementing the example app for loqa-audio-bridge, we encountered a runtime error where exported functions from the module were undefined (`addAudioSampleListener is not a function`), despite:
- The functions being correctly exported in the TypeScript source
- The TypeScript compilation succeeding without errors
- The compiled JavaScript having all the correct exports
- The example app's node_modules containing the correct compiled code

## Root Cause

**Metro bundler was resolving the ROOT-LEVEL TypeScript source file (`index.ts`) instead of the compiled JavaScript file (`build/index.js`).**

### Why This Happened

1. **File Structure**: The module had BOTH:
   - A root-level `index.ts` (11,651 bytes) with all API exports
   - A compiled `build/index.js` (319 lines) that package.json pointed to

2. **Metro's Resolution Strategy**: When using `file:..` dependencies, npm creates a symlink that includes ALL files from the source package, including:
   - Source TypeScript files (`.ts`)
   - Compiled JavaScript files (`.js`)

3. **TypeScript Preference**: Metro bundler **preferentially resolves TypeScript source files** over compiled JavaScript when both exist, even when `package.json` specifies `"main": "build/index.js"`.

4. **Import Path Failures**: The root `index.ts` contained imports like:
   ```typescript
   import LoqaAudioBridgeModule from './src/LoqaAudioBridgeModule';
   import { StreamErrorCode } from './src/types';
   ```

   When Metro tried to bundle this source file directly, these paths failed because Metro doesn't resolve them the same way TypeScript does during compilation.

## The Fix

### 1. Eliminate Root-Level Source Files

**Moved** `index.ts` → `src/api.ts`

This ensures NO TypeScript source files exist at the package root where Metro might find them.

### 2. Update Source Entry Point

Changed `src/index.ts` from native module re-exports to:
```typescript
// Export the full API from api.ts
export * from './api';
```

### 3. Fix Import Paths

Updated all imports in `src/api.ts` to use relative paths within `src/`:
```typescript
// BEFORE (broken in root index.ts)
import LoqaAudioBridgeModule from './src/LoqaAudioBridgeModule';
import { StreamErrorCode } from './src/types';

// AFTER (works in src/api.ts)
import LoqaAudioBridgeModule from './LoqaAudioBridgeModule';
import { StreamErrorCode } from './types';
```

### 4. Update TypeScript Configuration

Changed `tsconfig.json` to only compile from `src/` and `hooks/`:
```json
{
  "include": ["./src", "./hooks"],
  "exclude": ["**/__mocks__/*", "**/__tests__/*", "**/__rsc_tests__/*", "./example"]
}
```

### 5. Rebuild and Verify

After rebuilding, the compiled `build/index.js`:
- Contains all 319 lines of exported API code
- Has all functions properly exported
- Metro now correctly resolves this file (no root-level TypeScript to confuse it)

## Verification

**Before Fix**:
- Metro bundled 792 modules
- Runtime error: `addAudioSampleListener is not a function (it is undefined)`
- App crashed on mount

**After Fix**:
- Metro bundled 726 modules (66 fewer = removed incorrect source resolution)
- Zero runtime errors
- App launches successfully with all functions available

## Standard Expo Module Structure

This fix aligns with the CORRECT Expo module structure:

```
my-expo-module/
├── src/                    # ✅ ALL TypeScript source goes here
│   ├── index.ts           # Entry point (re-exports from api.ts)
│   ├── api.ts             # Main API implementation
│   ├── types.ts           # Type definitions
│   └── *.ts               # Other source files
├── hooks/                  # ✅ React hooks (if any)
│   └── *.ts
├── build/                  # ✅ Compiled output (gitignored, npm published)
│   ├── index.js           # Compiled entry point
│   ├── index.d.ts         # Type declarations
│   └── **/*.js            # All compiled files
├── ios/                    # Native iOS code
├── android/                # Native Android code
├── example/                # Example app (gitignored, not published)
├── package.json            # ✅ "main": "build/index.js"
├── tsconfig.json           # ✅ "include": ["./src", "./hooks"]
└── README.md

❌ NEVER HAVE:
├── index.ts               # Root-level TypeScript confuses Metro!
├── api.ts                 # Root-level TypeScript confuses Metro!
```

## Critical Rules for Expo Modules

### Rule 1: No Root-Level TypeScript
**NEVER** place TypeScript source files (`.ts`, `.tsx`) at the package root. They MUST be in `src/` or `hooks/`.

### Rule 2: Package Entry Point
`package.json` MUST point to compiled JavaScript:
```json
{
  "main": "build/index.js",
  "types": "build/index.d.ts"
}
```

### Rule 3: TypeScript Config
Only compile from source directories:
```json
{
  "include": ["./src", "./hooks"],
  "outDir": "./build"
}
```

### Rule 4: Publish Compiled Code
`.npmignore` should include source but NOT build:
```
src/
*.ts
*.tsx
!build/
```

### Rule 5: file:.. Dependency Behavior
When using `file:..` dependencies (common for example apps during development):
- npm creates a **symlink** that includes ALL files from the source package
- Metro will scan this symlink and **prefer TypeScript over JavaScript**
- This is different from published npm packages where only published files are available

## Impact on Epic 2 Stories

### Story 2-1: TypeScript Migration
**No Changes Needed** - The source code structure was correct.

### Story 2-2 & 2-4: iOS/Android Implementation
**No Changes Needed** - Native code was correctly placed in `ios/` and `android/`.

### Story 2-3: Test Exclusions
**VALIDATED** - This issue confirms why test exclusions are critical. If test files had been in the root, they would have caused similar Metro resolution issues.

### Story 2-5, 2-6, 2-7: Test Migration
**No Changes Needed** - Tests were correctly placed in subdirectories and excluded from compilation.

### Story 2-8: Zero Warnings
**Additional Fix Required** - The root `index.ts` file was a structural issue that should have been caught during the zero-warnings pass. However, TypeScript compilation succeeded because the file was valid TypeScript - the issue only manifested at Metro bundling time.

**Recommendation**: Add a lint rule or documentation check to ensure no `.ts` files exist at package root (except configuration files like `jest.config.ts`).

## Implications for Voiceline Team

### Critical Risk
If the Voiceline app uses `file:..` dependencies for local development (which is common for testing unreleased modules), they will hit this exact issue if the module structure is incorrect.

### Prevention Checklist
Before integrating loqa-audio-bridge into Voiceline:

1. ✅ Verify NO `.ts` files at module root (except config files)
2. ✅ Verify `package.json` `main` points to `build/index.js`
3. ✅ Verify `tsconfig.json` only includes `src/` and `hooks/`
4. ✅ Run `npm pack` and inspect the tarball contents
5. ✅ Test with `file:..` dependency in a fresh Expo app
6. ✅ Verify Metro bundles without errors
7. ✅ Verify all exported functions are available at runtime

### Published Package vs file:.. Dependency

**Published to npm** (safer):
- Only includes files specified in `package.json` `files` field or not in `.npmignore`
- Metro can only see published files (typically just `build/`, not `src/`)
- Less likely to have resolution issues

**file:.. Dependency** (higher risk):
- Includes ALL files from source directory (even .gitignored build artifacts)
- Metro sees EVERYTHING including source TypeScript
- Must follow strict module structure rules

## Timeline of Discovery

1. **Initial Error**: `addAudioSampleListener is not a function (it is undefined)`
2. **First Hypothesis**: Metro cache issue - cleared cache, rebuilt - ERROR PERSISTED
3. **Second Hypothesis**: Module export bug - verified exports in code - CODE WAS CORRECT
4. **Third Hypothesis**: TypeScript compilation issue - checked tsconfig - MISSED ROOT INDEX.TS
5. **Fourth Hypothesis**: Build output verification - found correct exports in `build/index.js`
6. **Key Discovery**: Found root-level `index.ts` file (11.6KB) that shouldn't exist
7. **Verification**: Checked node_modules symlink - confirmed root `index.ts` was present
8. **Root Cause Identified**: Metro resolving root TypeScript instead of compiled JavaScript
9. **Fix Applied**: Moved `index.ts` → `src/api.ts`, updated imports, rebuilt
10. **Result**: App launches successfully, zero errors, all functions available

## Testing Recommendations

### For Epic 3 Story 3-5 (Documentation)
Document this module structure in the integration guide with clear warnings about Metro bundler behavior.

### For Epic 5 Story 5-2 (CI/CD)
Add automated checks:
```bash
# Check for root-level TypeScript files (except config)
ROOT_TS=$(find . -maxdepth 1 -name "*.ts" ! -name "*.config.ts" ! -name "jest.setup.ts")
if [ ! -z "$ROOT_TS" ]; then
  echo "ERROR: Root-level TypeScript files detected. Move to src/"
  echo "$ROOT_TS"
  exit 1
fi
```

### For Future Stories
When creating any new Expo module or updating existing ones:
1. Always follow the standard Expo module structure
2. Test with `file:..` dependency BEFORE publishing
3. Verify Metro bundling succeeds
4. Verify runtime function availability

## References

- **Expo Module Structure**: https://docs.expo.dev/modules/module-api/
- **Metro Bundler Resolution**: https://facebook.github.io/metro/docs/resolution
- **TypeScript Module Resolution**: https://www.typescriptlang.org/docs/handbook/module-resolution.html

## Conclusion

This was a **critical structural issue** that would have blocked all downstream consumers of the module. The fix is simple but the discovery process was complex because:
- TypeScript compilation succeeded (the source was valid)
- The compiled output was correct (exports were present)
- The error only appeared at Metro bundling time with `file:..` dependencies

**Key Takeaway**: Expo modules MUST follow the standard structure with ALL TypeScript source in `src/` or `hooks/` directories. Root-level TypeScript files will cause Metro bundler resolution failures when used with `file:..` dependencies.
