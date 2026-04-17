import AppKit
@testable import SnapMarkLib

// ── Main entry point for the test executable ──

print("SnapMark Test Suite")
print(String(repeating: "═", count: 50))

runGeometryHelpersTests()
runAnnotationHistoryTests()
runAnnotationTests()
runImageExporterTests()
runIntegrationTests()

printSummary()

// Exit with non-zero code if any tests failed
exit(failedTests.isEmpty ? 0 : 1)
