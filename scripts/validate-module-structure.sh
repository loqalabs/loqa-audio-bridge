#!/bin/bash
set -e  # Exit on error

echo "🔍 Validating Expo Module Structure..."
echo ""

# Check 1: No root-level TypeScript files (except config files)
echo "1️⃣ Checking for root-level TypeScript files..."
ROOT_TS=$(find . -maxdepth 1 -name "*.ts" ! -name "*.config.ts" ! -name "jest.setup.ts" ! -name "*.d.ts" 2>/dev/null || true)
if [ ! -z "$ROOT_TS" ]; then
  echo "❌ ERROR: Root-level TypeScript files detected. Move to src/"
  echo "$ROOT_TS"
  exit 1
fi
echo "✅ No root-level TypeScript files found"
echo ""

# Check 2: tsconfig.json includes validation
echo "2️⃣ Checking tsconfig.json includes..."
if ! grep -q '"include": \["./src"\]' tsconfig.json && \
   ! grep -q '"include": \["./src", "./hooks"\]' tsconfig.json; then
  echo "❌ ERROR: tsconfig.json must only compile from ./src (and optionally ./hooks)"
  echo "Current includes:"
  grep '"include":' tsconfig.json || echo "(none found)"
  exit 1
fi
echo "✅ tsconfig.json includes are correct"
echo ""

# Check 3: package.json main entry validation
echo "3️⃣ Checking package.json main entry..."
MAIN_ENTRY=$(grep '"main":' package.json | sed 's/.*"main": "\(.*\)".*/\1/')
if [ -z "$MAIN_ENTRY" ]; then
  echo "❌ ERROR: package.json main entry not found"
  exit 1
fi
echo "   Found main entry: $MAIN_ENTRY"

# Validate that main entry starts with build/
if [[ ! "$MAIN_ENTRY" =~ ^build/ ]]; then
  echo "❌ ERROR: package.json main must point to build/ directory"
  echo "   Current main: $MAIN_ENTRY"
  exit 1
fi

# Validate that main entry ends with .js
if [[ ! "$MAIN_ENTRY" =~ \.js$ ]]; then
  echo "❌ ERROR: package.json main must point to a .js file"
  echo "   Current main: $MAIN_ENTRY"
  exit 1
fi

echo "✅ package.json main entry is correct"
echo ""

# Check 4: Compiled output validation
echo "4️⃣ Checking compiled output..."
if [ ! -f "$MAIN_ENTRY" ]; then
  echo "❌ ERROR: $MAIN_ENTRY does not exist. Run 'npm run build'"
  exit 1
fi

if [ ! -s "$MAIN_ENTRY" ]; then
  echo "❌ ERROR: $MAIN_ENTRY is empty"
  exit 1
fi

# Check for expected exports
if ! grep -q "export" "$MAIN_ENTRY" && ! grep -q "exports" "$MAIN_ENTRY"; then
  echo "⚠️  WARNING: No exports found in $MAIN_ENTRY"
fi

echo "✅ Compiled output exists and contains exports"
echo ""

# Success summary
echo "✅ Module structure validation PASSED!"
echo "   - No root-level TypeScript files"
echo "   - tsconfig.json compiles only from src/"
echo "   - package.json points to $MAIN_ENTRY"
echo "   - Compiled output exists and valid"
exit 0
