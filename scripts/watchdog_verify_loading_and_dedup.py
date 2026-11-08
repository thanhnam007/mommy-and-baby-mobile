# -*- coding: utf-8 -*-
"""
Watchdog verification script:
1. Verifies LoadingButton widget exists and has expected parameters.
2. Verifies ApiClient has inFlightMutations and activeRequestsNotifier.
3. Verifies MainLayout has top slim linear progress bar.
4. Verifies QuickLogSheet, ActivityDetailSheet, GrowthView, PumpingFormSheet, BabyPickerSheet, RemindersView have loading states.
5. Verifies canonical flutter test passes with 0 failures.
"""
import os
import sys
import subprocess

REPO_DIR = r"F:\work\mommy-and-baby-mobile"
errors = []

print("=== 1. Checking LoadingButton Widget ===")
loading_btn_path = os.path.join(REPO_DIR, "lib", "core", "widgets", "loading_button.dart")
if not os.path.exists(loading_btn_path):
    errors.append("Missing loading_button.dart")
else:
    with open(loading_btn_path, "r", encoding="utf-8") as f:
        content = f.read()
    assert "class LoadingButton" in content
    assert "CircularProgressIndicator" in content
    assert "debounce" in content.lower() or "_lastPressedAt" in content
    print("[PASS] LoadingButton widget is properly implemented")

print("\n=== 2. Checking ApiClient In-Flight Interceptor ===")
api_client_path = os.path.join(REPO_DIR, "lib", "core", "network", "api_client.dart")
with open(api_client_path, "r", encoding="utf-8") as f:
    api_content = f.read()
assert "activeRequestsNotifier" in api_content, "Missing activeRequestsNotifier"
assert "_inFlightMutations" in api_content, "Missing _inFlightMutations"
assert "isMutating" in api_content, "Missing isMutating check"
assert "DioExceptionType.cancel" in api_content, "Missing cancellation on duplicate"
print("[PASS] ApiClient In-Flight deduplication and request counter verified")

print("\n=== 3. Checking MainLayout Global Progress Bar ===")
main_layout_path = os.path.join(REPO_DIR, "lib", "views", "main_layout.dart")
with open(main_layout_path, "r", encoding="utf-8") as f:
    ml_content = f.read()
assert "activeRequestsNotifier" in ml_content, "Missing activeRequestsNotifier in MainLayout"
assert "LinearProgressIndicator" in ml_content, "Missing LinearProgressIndicator in MainLayout"
print("[PASS] MainLayout top slim progress indicator verified")

print("\n=== 4. Checking Modal Sheets Loading States ===")
checks = [
    ("lib/views/quick_log/quick_log_sheet.dart", ["_isSubmitting", "_isSleepingToggleLoading", "_isFeedingToggleLoading"]),
    ("lib/views/timeline/activity_detail_sheet.dart", ["_isFinishingFeeding", "_isFinishingSleep", "_isDeleting", "_isSaving"]),
    ("lib/views/growth/growth_view.dart", ["isSaving", "Đang lưu số đo..."]),
    ("lib/views/pumping/widgets/pumping_form_sheet.dart", ["_isSaving", "Future<void> Function"]),
    ("lib/views/babies/baby_picker_sheet.dart", ["isCreating", "Đang tạo hồ sơ..."]),
    ("lib/views/reminders/reminders_view.dart", ["isCreating", "Đang tạo nhắc nhở..."]),
]

for rel_path, required_tokens in checks:
    full_path = os.path.join(REPO_DIR, rel_path.replace("/", os.sep))
    with open(full_path, "r", encoding="utf-8") as f:
        f_content = f.read()
    for token in required_tokens:
        if token not in f_content:
            errors.append(f"File {rel_path} missing token: {token}")
        else:
            print(f"[PASS] {rel_path} contains: {token}")

print("\n=== 5. Running Canonical Flutter Tests ===")
proc = subprocess.run("flutter test", cwd=REPO_DIR, capture_output=True, text=True, shell=True)
if proc.returncode == 0 and "All tests passed!" in proc.stdout:
    print("[PASS] Flutter test suite passed completely!")
else:
    errors.append(f"Flutter tests failed (code {proc.returncode}):\n{proc.stdout}\n{proc.stderr}")

print("\n=== Summary ===")
if errors:
    print(f"FAILED with {len(errors)} errors:")
    for err in errors:
        print(f"  - {err}")
    sys.exit(1)
else:
    print("ALL 5 WATCHDOG VERIFICATION CHECKS PASSED PERFECTLY!")
    sys.exit(0)
