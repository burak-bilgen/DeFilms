import Foundation

enum SnapshotBaselines {
    // Approved baselines live here.
    //
    // Workflow:
    // 1. Run a visual reference UI test with UITest.RecordSnapshots=1.
    // 2. The test fails intentionally and prints a ready-to-paste baseline entry.
    // 3. Review the attached screenshot in the Xcode test report.
    // 4. If approved, paste the printed line below.
    // 5. Re-run without UITest.RecordSnapshots to assert against the stored baseline.
    //
    // Example:
    // "onboarding-light": .init(width: 1290, height: 2796, hash: "0123abcd...")
    static let values: [String: SnapshotFingerprint] = [:]
}
