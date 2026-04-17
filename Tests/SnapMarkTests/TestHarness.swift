import Foundation

// Lightweight test harness that works without XCTest or Testing framework
// Runs as a standalone executable

var totalTests = 0
var passedTests = 0
var failedTests: [(String, String)] = []  // (testName, message)
var currentSuite = ""

func suite(_ name: String) {
    currentSuite = name
    print("\n━━━ \(name) ━━━")
}

func test(_ name: String, _ body: () throws -> Void) {
    totalTests += 1
    let fullName = "\(currentSuite)/\(name)"
    do {
        try body()
        passedTests += 1
        print("  ✓ \(name)")
    } catch {
        failedTests.append((fullName, "\(error)"))
        print("  ✗ \(name) — \(error)")
    }
}

func testAsync(_ name: String, _ body: () async throws -> Void) async {
    totalTests += 1
    let fullName = "\(currentSuite)/\(name)"
    do {
        try await body()
        passedTests += 1
        print("  ✓ \(name)")
    } catch {
        failedTests.append((fullName, "\(error)"))
        print("  ✗ \(name) — \(error)")
    }
}

struct AssertionError: Error, CustomStringConvertible {
    let description: String
}

func expect(_ condition: Bool, _ message: String = "assertion failed", file: String = #file, line: Int = #line) throws {
    guard condition else {
        throw AssertionError(description: "\(message) (\(URL(fileURLWithPath: file).lastPathComponent):\(line))")
    }
}

func expectEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "", file: String = #file, line: Int = #line) throws {
    guard a == b else {
        let msg = message.isEmpty ? "expected \(a) == \(b)" : "\(message): expected \(a) == \(b)"
        throw AssertionError(description: "\(msg) (\(URL(fileURLWithPath: file).lastPathComponent):\(line))")
    }
}

func expectApprox(_ a: CGFloat, _ b: CGFloat, tolerance: CGFloat = 0.001, _ message: String = "", file: String = #file, line: Int = #line) throws {
    guard abs(a - b) < tolerance else {
        let msg = message.isEmpty ? "expected \(a) ≈ \(b)" : "\(message): expected \(a) ≈ \(b)"
        throw AssertionError(description: "\(msg) (\(URL(fileURLWithPath: file).lastPathComponent):\(line))")
    }
}

func expectNotNil<T>(_ value: T?, _ message: String = "expected non-nil", file: String = #file, line: Int = #line) throws -> T {
    guard let v = value else {
        throw AssertionError(description: "\(message) (\(URL(fileURLWithPath: file).lastPathComponent):\(line))")
    }
    return v
}

func printSummary() {
    print("\n" + String(repeating: "═", count: 50))
    print("Results: \(passedTests)/\(totalTests) passed, \(failedTests.count) failed")
    if !failedTests.isEmpty {
        print("\nFailed tests:")
        for (name, msg) in failedTests {
            print("  ✗ \(name): \(msg)")
        }
    }
    print(String(repeating: "═", count: 50))
}
