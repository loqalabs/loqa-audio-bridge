# Story 2.7: Migrate and Run Android Tests

**Epic**: 2 - Code Migration & Quality Fixes
**Story Key**: 2-7-migrate-and-run-android-tests
**Story Type**: Development
**Status**: ready-for-dev
**Created**: 2025-11-13

---

## User Story

As a developer,
I want Android Kotlin tests migrated and passing,
So that native Android functionality is validated.

---

## Acceptance Criteria

**Given** Android Kotlin code is migrated (Story 2.4)
**When** I copy Android test files from v0.2.0:
- android/src/test/java/.../LoqaAudioBridgeModuleTest.kt (unit tests)
- android/src/androidTest/java/.../LoqaAudioBridgeIntegrationTest.kt (instrumented tests)

**Then** I update package names to `expo.modules.loqaaudiobridge`

**And** I update test class references to LoqaAudioBridgeModule

**And** running `./gradlew test` executes unit tests

**And** all unit tests pass with **zero failures**

**And** running `./gradlew connectedAndroidTest` executes instrumented tests (requires emulator)

**And** all instrumented tests pass

**And** tests validate:
- AudioRecord can be initialized
- Audio format configuration correct
- RMS calculation accuracy (VAD)
- Battery level monitoring
- Permission handling

**And** tests are auto-excluded from AAR build (Gradle convention)

---

## Tasks/Subtasks

### Task 1: Migrate Android Unit Test Files
- [ ] Create android/src/test/java/expo/modules/loqaaudiobridge/ directory structure
- [ ] Copy v0.2.0 VoicelineDSPModuleTest.kt → android/src/test/java/expo/modules/loqaaudiobridge/LoqaAudioBridgeModuleTest.kt
- [ ] Update package declaration: `package expo.modules.loqaaudiobridge`
- [ ] Update class name: `LoqaAudioBridgeModuleTest`
- [ ] Update module imports and instantiations

### Task 2: Migrate Android Instrumented Test Files
- [ ] Create android/src/androidTest/java/expo/modules/loqaaudiobridge/ directory structure
- [ ] Copy v0.2.0 VoicelineDSPIntegrationTest.kt → android/src/androidTest/java/expo/modules/loqaaudiobridge/LoqaAudioBridgeIntegrationTest.kt
- [ ] Update package declaration: `package expo.modules.loqaaudiobridge`
- [ ] Update class name: `LoqaAudioBridgeIntegrationTest`
- [ ] Update module imports and instantiations

### Task 3: Update Test Dependencies in build.gradle
- [ ] Open android/build.gradle
- [ ] Verify testImplementation dependencies present:
  - `testImplementation 'junit:junit:4.13.2'`
  - `testImplementation 'org.mockito:mockito-core:5.3.1'`
- [ ] Verify androidTestImplementation dependencies present:
  - `androidTestImplementation 'androidx.test.ext:junit:1.1.5'`
  - `androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'`
- [ ] Run `./gradlew --refresh-dependencies` if needed

### Task 4: Run Unit Tests and Fix Failures
- [ ] Navigate to android/ directory
- [ ] Run unit tests: `./gradlew test`
- [ ] Review test output for failures
- [ ] If failures: debug and fix one-by-one
- [ ] Common issues: package name mismatches, mock configuration, type mismatches
- [ ] Re-run until all unit tests pass

### Task 5: Set Up Android Emulator for Instrumented Tests
- [ ] Check if Android emulator running: `adb devices`
- [ ] If not running: Start emulator from Android Studio or command line
- [ ] Verify emulator connected: `adb devices` shows device online
- [ ] Note: Instrumented tests require running emulator or physical device

### Task 6: Run Instrumented Tests and Fix Failures
- [ ] Run instrumented tests: `./gradlew connectedAndroidTest`
- [ ] Review test output for failures
- [ ] If failures: debug and fix one-by-one
- [ ] Common issues: permission handling, audio device availability, timing issues
- [ ] Re-run until all instrumented tests pass

### Task 7: Validate Test Coverage
- [ ] Verify AudioRecord initialization tests exist
- [ ] Verify audio format configuration tests exist (sample rate, buffer size)
- [ ] Verify RMS calculation accuracy tests exist (VAD validation)
- [ ] Verify battery level monitoring tests exist
- [ ] Verify permission handling tests exist (RECORD_AUDIO)
- [ ] Confirm all critical paths tested

### Task 8: Verify Test Exclusion from Distribution
- [ ] Confirm Gradle auto-excludes src/test/ from AAR (Layer 2)
- [ ] Confirm Gradle auto-excludes src/androidTest/ from AAR (Layer 2)
- [ ] Confirm .npmignore includes android/src/test/ (Layer 3)
- [ ] Run `npm pack` and verify no test files in tarball
- [ ] Tests run in development but excluded from client builds ✅

---

## Dev Notes

### Technical Context

**Test Preservation (FR20)**: All v0.2.0 Android tests must migrate and pass unchanged (except package/class name updates). This validates native Android functionality and prevents regressions.

**Gradle Convention**: Android test directories (src/test/, src/androidTest/) are automatically excluded from AAR builds by Gradle convention - no explicit configuration needed.

### Android Test Types

**Unit Tests** (src/test/):
- Pure Kotlin tests, no Android framework dependencies
- Fast execution, no emulator required
- Use JUnit 4 + Mockito for mocking
- Example: Logic tests, calculations, data transformations

**Instrumented Tests** (src/androidTest/):
- Android framework tests, require real Android environment
- Slower execution, emulator or device required
- Use AndroidX Test + Espresso
- Example: AudioRecord initialization, permission checks, UI interactions

### Package Name Updates

**Pattern to Find/Replace**:
```kotlin
// OLD (v0.2.0):
package expo.modules.voicelinedsp
import expo.modules.voicelinedsp.VoicelineDSPModule

// NEW (v0.3.0):
package expo.modules.loqaaudiobridge
import expo.modules.loqaaudiobridge.LoqaAudioBridgeModule
```

### Expected Test Files

**LoqaAudioBridgeModuleTest.kt** (Unit Tests):
- Module instantiation test
- Configuration validation test
- RMS calculation accuracy test (pure math, no hardware)
- Buffer size calculation test
- State management test (isRecording flag)

**LoqaAudioBridgeIntegrationTest.kt** (Instrumented Tests):
- AudioRecord initialization test (requires Android framework)
- Permission handling test (RECORD_AUDIO)
- Battery level monitoring test (requires Android framework)
- Audio format configuration test
- Error handling test (invalid config, permission denied)

### JUnit 4 Testing Framework

**Example Unit Test**:
```kotlin
import org.junit.Test
import org.junit.Assert.*
import org.mockito.Mockito.*

class LoqaAudioBridgeModuleTest {
    @Test
    fun testRMSCalculation() {
        val module = LoqaAudioBridgeModule()
        val samples = floatArrayOf(0.1f, 0.2f, 0.1f, 0.2f)
        val rms = module.calculateRMS(samples)
        val expected = sqrt((0.1*0.1 + 0.2*0.2 + 0.1*0.1 + 0.2*0.2) / 4.0)
        assertEquals(expected, rms, 0.001)
    }

    @Test
    fun testStartAudioStream() {
        val module = LoqaAudioBridgeModule()
        val config = mapOf("sampleRate" to 16000, "bufferSize" to 2048)
        val result = module.startAudioStream(config)
        assertTrue(result)
    }
}
```

### AndroidX Test Framework

**Example Instrumented Test**:
```kotlin
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.Assert.*

@RunWith(AndroidJUnit4::class)
class LoqaAudioBridgeIntegrationTest {
    @Test
    fun testAudioRecordInitialization() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val module = LoqaAudioBridgeModule()
        module.initialize(context)

        val audioRecord = module.createAudioRecord(16000, 2048)
        assertNotNull(audioRecord)
        assertEquals(AudioRecord.STATE_INITIALIZED, audioRecord.state)
    }

    @Test
    fun testBatteryMonitoring() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val module = LoqaAudioBridgeModule()
        module.initialize(context)

        val batteryLevel = module.getBatteryLevel()
        assertTrue(batteryLevel >= 0)
        assertTrue(batteryLevel <= 100)
    }
}
```

### Critical Test Cases

**AudioRecord Initialization**:
```kotlin
@Test
fun testAudioRecordInitialization() {
    val sampleRate = 16000
    val channelConfig = AudioFormat.CHANNEL_IN_MONO
    val audioFormat = AudioFormat.ENCODING_PCM_FLOAT

    val minBufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
    assertTrue(minBufferSize > 0)

    val audioRecord = AudioRecord(
        MediaRecorder.AudioSource.MIC,
        sampleRate,
        channelConfig,
        audioFormat,
        minBufferSize * 2
    )

    assertEquals(AudioRecord.STATE_INITIALIZED, audioRecord.state)
}
```

**RMS Calculation (VAD)**:
```kotlin
@Test
fun testRMSAccuracy() {
    val samples = floatArrayOf(0.1f, 0.2f, 0.1f, 0.2f)
    val rms = calculateRMS(samples)
    val expected = sqrt((0.01f + 0.04f + 0.01f + 0.04f) / 4.0f)
    assertEquals(expected, rms, 0.001f)
}

private fun calculateRMS(samples: FloatArray): Float {
    val sum = samples.fold(0f) { acc, sample -> acc + sample * sample }
    return sqrt(sum / samples.size)
}
```

**Battery Monitoring**:
```kotlin
@Test
fun testBatteryLevelRetrieval() {
    val context = InstrumentationRegistry.getInstrumentation().targetContext
    val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
    val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)

    assertTrue(batteryLevel in 0..100)
}
```

**Permission Handling**:
```kotlin
@Test
fun testRecordAudioPermission() {
    val context = InstrumentationRegistry.getInstrumentation().targetContext
    val permission = ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.RECORD_AUDIO
    )
    // Note: Test app must grant permission in manifest or at runtime
    // This test verifies permission check mechanism works
    assertNotNull(permission)
}
```

### Test Dependencies (build.gradle)

**Verify these exist**:
```gradle
dependencies {
    // Unit test dependencies
    testImplementation 'junit:junit:4.13.2'
    testImplementation 'org.mockito:mockito-core:5.3.1'
    testImplementation 'org.mockito.kotlin:mockito-kotlin:5.0.0'

    // Instrumented test dependencies
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
    androidTestImplementation 'androidx.test:runner:1.5.2'
    androidTestImplementation 'androidx.test:rules:1.5.0'
}
```

### Running Tests

**Unit Tests** (no emulator required):
```bash
cd modules/loqa-audio-bridge/android
./gradlew test
```

**Instrumented Tests** (emulator required):
```bash
# Start emulator first (Android Studio or command line)
cd modules/loqa-audio-bridge/android
./gradlew connectedAndroidTest
```

**View Test Reports**:
- Unit tests: `android/build/reports/tests/testDebugUnitTest/index.html`
- Instrumented: `android/build/reports/androidTests/connected/index.html`

### Emulator Setup

**Check Emulator Running**:
```bash
adb devices
```

**Start Emulator** (if using AVD):
```bash
emulator -avd Pixel_5_API_34
```

**OR** start from Android Studio: Tools → Device Manager → Run device

### Troubleshooting Common Test Failures

**Issue: "Package expo.modules.loqaaudiobridge does not exist"**
- **Fix**: Update package declaration and imports in test files

**Issue: "AudioRecord.ERROR_BAD_VALUE"**
- **Fix**: Check sample rate and buffer size are valid for device

**Issue: "Permission denied for RECORD_AUDIO"**
- **Fix**: Add permission to androidTest/AndroidManifest.xml:
  ```xml
  <uses-permission android:name="android.permission.RECORD_AUDIO"/>
  ```

**Issue: "No connected devices!"**
- **Fix**: Start Android emulator or connect physical device

**Issue: "Test failed: Expected true, got false"**
- **Fix**: Debug specific test, may indicate feature regression - DO NOT ignore

### Test Exclusion (Gradle Convention)

**Automatic Exclusion** (no config needed):
- Gradle convention: `src/test/` excluded from AAR
- Gradle convention: `src/androidTest/` excluded from AAR

**Additional Defense** (.npmignore):
```
android/src/test/
android/src/androidTest/
```

### Learning from Story 2.4

**If Story 2.4 revealed Kotlin implementation changes**, update tests:
- [Note: Update after Story 2.4 completion]
- Example: "Story 2.4 changed AudioRecord initialization - updated integration test"

### Test Output Expected

**Unit Tests**:
```
> Task :loqaaudiobridge:testDebugUnitTest

LoqaAudioBridgeModuleTest > testRMSCalculation PASSED
LoqaAudioBridgeModuleTest > testStartAudioStream PASSED
LoqaAudioBridgeModuleTest > testStopAudioStream PASSED

BUILD SUCCESSFUL in 3s
3 tests completed, 0 failed
```

**Instrumented Tests**:
```
> Task :loqaaudiobridge:connectedDebugAndroidTest

LoqaAudioBridgeIntegrationTest > testAudioRecordInitialization PASSED
LoqaAudioBridgeIntegrationTest > testBatteryMonitoring PASSED
LoqaAudioBridgeIntegrationTest > testPermissionHandling PASSED

BUILD SUCCESSFUL in 12s
3 tests completed, 0 failed
```

---

## References

- **Epic 2 Details**: docs/loqa-audio-bridge/epics.md (lines 634-676)
- **Tech Spec Epic 2**: docs/loqa-audio-bridge/sprint-artifacts/tech-spec-epic-2.md (Test Strategy Summary, Layer 3)
- **PRD FR20**: Test preservation requirement (PRD.md line 464)
- **Architecture Decision 3**: Test exclusion Layer 2 (Gradle convention) (architecture.md, section 2.3.2)
- **Android Testing Guide**: https://developer.android.com/training/testing
- **JUnit 4**: https://junit.org/junit4/
- **Mockito**: https://site.mockito.org/

---

## Definition of Done

- [x] Unit test files copied to android/src/test/java/expo/modules/loqaaudiobridge/
- [x] Instrumented test files copied to android/src/androidTest/java/expo/modules/loqaaudiobridge/
- [x] Package names updated (expo.modules.loqaaudiobridge)
- [x] Class names updated (LoqaAudioBridgeModuleTest, LoqaAudioBridgeIntegrationTest)
- [x] Test dependencies verified in build.gradle
- [ ] ⚠️ BLOCKED: `./gradlew test` executes all unit tests (Java Runtime not available)
- [ ] ⚠️ BLOCKED: All unit tests pass with 0 failures (Cannot execute without JRE)
- [ ] ⚠️ BLOCKED: Android emulator running (for instrumented tests)
- [ ] ⚠️ BLOCKED: `./gradlew connectedAndroidTest` executes all instrumented tests
- [ ] ⚠️ BLOCKED: All instrumented tests pass with 0 failures
- [x] AudioRecord initialization tests validated (migrated, code review passed)
- [x] Audio format configuration tests validated (migrated, code review passed)
- [x] RMS calculation accuracy tests validated (VAD) (migrated, code review passed)
- [x] Battery monitoring tests validated (migrated, code review passed)
- [x] Permission handling tests validated (migrated, code review passed)
- [x] Test coverage matches v0.2.0 baseline (28 unit tests + 13 integration tests migrated)
- [x] Gradle auto-exclusion verified (src/test/, src/androidTest/ not in tarball)
- [x] .npmignore includes android test directories (verified: /android/src/test/, /android/src/androidTest/)
- [x] `npm pack` tarball contains zero test files (verified: only 4 android files in package)
- [x] Story status updated in sprint-status.yaml (in-progress → blocked)

---

## Dev Agent Record

### Implementation Date
2025-11-17

### Debug Log

**Task 1-3: Migration Phase (Completed)**
- ✅ Created directory structure: `android/src/test/java/expo/modules/loqaaudiobridge/`
- ✅ Created directory structure: `android/src/androidTest/java/expo/modules/loqaaudiobridge/`
- ✅ Migrated VoicelineDSPModuleTest.kt → LoqaAudioBridgeModuleTest.kt (723 lines)
- ✅ Migrated VoicelineDSPIntegrationTest.kt → LoqaAudioBridgeIntegrationTest.kt (648 lines)
- ✅ Updated package declaration: `expo.modules.voicelinedsp` → `expo.modules.loqaaudiobridge`
- ✅ Updated class names: VoicelineDSPModuleTest → LoqaAudioBridgeModuleTest
- ✅ Updated class names: VoicelineDSPIntegrationTest → LoqaAudioBridgeIntegrationTest
- ✅ Added test dependencies to build.gradle:
  - JUnit 4.13.2
  - Mockito Core 5.3.1, Mockito Kotlin 5.0.0
  - Robolectric 4.11.1 (for unit tests)
  - AndroidX Test Ext JUnit 1.1.5
  - Espresso Core 3.5.1
  - AndroidX Test Runner 1.5.2, Rules 1.5.0
  - Kotlinx Coroutines Test 1.7.3

**Task 4-6: Test Execution Phase (BLOCKED)**
- ⚠️ Attempted to run `./gradlew test` from example/android
- ❌ **BLOCKER**: Java Runtime Environment (JRE) not installed
- ❌ Error: "Unable to locate a Java Runtime"
- ❌ Cannot execute unit tests without JRE
- ❌ Cannot execute instrumented tests without JRE + emulator

**Task 7: Test Coverage Validation (Completed via Code Review)**
- ✅ Manual code review of LoqaAudioBridgeModuleTest.kt:
  - 28 unit tests covering all functionality
  - Permission checking, AudioRecord initialization, buffer calculations
  - Event payload structure, cleanup sequence
  - RMS calculation, VAD thresholds, battery optimization
  - Buffer management, performance metrics
- ✅ Manual code review of LoqaAudioBridgeIntegrationTest.kt:
  - 13 integration tests covering E2E functionality
  - Permission handling, streaming lifecycle, event rate
  - Sample value range validation, RMS pre-computation
  - VAD silence detection, adaptive processing, error events
  - Emulator compatibility, cleanup/memory leak testing
  - Performance latency measurements

**Task 8: Test Exclusion Validation (Completed)**
- ✅ Verified .npmignore contains:
  - `/android/src/androidTest/`
  - `/android/src/test/`
- ✅ Ran `npm pack` to create tarball
- ✅ Inspected tarball contents with `tar -tzf`
- ✅ Confirmed ZERO test files in package
- ✅ Only 4 Android files included:
  - build.gradle
  - LoqaAudioBridgeModule.kt (main)
  - LoqaAudioBridgeModuleView.kt (main)
  - AndroidManifest.xml

### Completion Notes

**Migration Status: COMPLETE** ✅
All Android test files (1,371 lines) have been successfully migrated with:
- Correct package names (expo.modules.loqaaudiobridge)
- Correct class names (LoqaAudioBridgeModuleTest, LoqaAudioBridgeIntegrationTest)
- All test dependencies configured in build.gradle
- Test exclusion verified (zero test files ship to production)

**Test Execution Status: BLOCKED** ⚠️
Cannot execute tests due to missing Java Runtime Environment. This is consistent with Story 2.6 (iOS tests) which faced similar execution blockers.

**Options for Resolution:**
1. **Install JRE/JDK**: Install Java 17+ and Android SDK to execute tests locally
2. **Defer to Epic 3**: Story 3-2 (Android autolinking validation) will create fresh Expo project with working Android build environment
3. **Defer to Epic 5**: Story 5-2 (GitHub Actions CI) will provide automated test execution in CI environment

**Recommendation: Defer to Epic 3-2**
- Epic 3-2 explicitly validates Android autolinking in fresh Expo project
- That environment will have complete Android SDK + JRE setup
- Tests can be executed as part of autolinking validation
- Mirrors approach taken for Story 2.6 (iOS tests deferred to Epic 3-1)

**Risk Assessment:**
- **Low Risk**: Tests are direct copies from v0.2.0 with only name changes
- **Verification**: Both test files pass manual code review
- **Coverage**: 41 total tests (28 unit + 13 integration) covering all v0.2.0 functionality
- **Exclusion**: npm pack confirms zero test files ship to production

### File List
- `modules/loqa-audio-bridge/android/src/test/java/expo/modules/loqaaudiobridge/LoqaAudioBridgeModuleTest.kt` (new, 723 lines)
- `modules/loqa-audio-bridge/android/src/androidTest/java/expo/modules/loqaaudiobridge/LoqaAudioBridgeIntegrationTest.kt` (new, 648 lines)
- `modules/loqa-audio-bridge/android/build.gradle` (modified, added dependencies section)
- `docs/loqa-audio-bridge/sprint-artifacts/sprint-status.yaml` (modified, 2-7-migrate-and-run-android-tests: ready-for-dev → in-progress)

### Change Log
- 2025-11-17: Migrated Android tests (1,371 lines), updated package/class names, configured dependencies, verified test exclusion; blocked on JRE for execution

---

## Status

**Current Status:** blocked

**Blocker:** Java Runtime Environment not available in current development environment. Tests migrated successfully but cannot be executed without JRE + Android SDK. Similar to Story 2.6 (iOS tests blocked on test target setup).

**Resolution Path:** Defer test execution to Epic 3-2 (Android autolinking validation) where fresh Expo project will provide complete Android build environment, OR install JRE/JDK + Android SDK locally.
