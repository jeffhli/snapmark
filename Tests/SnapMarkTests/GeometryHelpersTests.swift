import AppKit
@testable import SnapMarkLib

func runGeometryHelpersTests() {
    suite("GeometryHelpers")

    test("normalizedRect with positive direction") {
        let rect = GeometryHelpers.normalizedRect(from: CGPoint(x: 10, y: 20), to: CGPoint(x: 50, y: 60))
        try expectApprox(rect.origin.x, 10)
        try expectApprox(rect.origin.y, 20)
        try expectApprox(rect.width, 40)
        try expectApprox(rect.height, 40)
    }

    test("normalizedRect with negative direction") {
        let rect = GeometryHelpers.normalizedRect(from: CGPoint(x: 100, y: 100), to: CGPoint(x: 50, y: 50))
        try expectApprox(rect.origin.x, 50)
        try expectApprox(rect.origin.y, 50)
        try expectApprox(rect.width, 50)
        try expectApprox(rect.height, 50)
    }

    test("normalizedRect same point gives zero size") {
        let rect = GeometryHelpers.normalizedRect(from: CGPoint(x: 42, y: 42), to: CGPoint(x: 42, y: 42))
        try expectApprox(rect.width, 0)
        try expectApprox(rect.height, 0)
    }

    test("normalizedRect mixed direction") {
        let rect = GeometryHelpers.normalizedRect(from: CGPoint(x: 10, y: 80), to: CGPoint(x: 90, y: 20))
        try expectApprox(rect.origin.x, 10)
        try expectApprox(rect.origin.y, 20)
        try expectApprox(rect.width, 80)
        try expectApprox(rect.height, 60)
    }

    test("distance 3-4-5 triangle") {
        let d = GeometryHelpers.distance(CGPoint(x: 0, y: 0), CGPoint(x: 3, y: 4))
        try expectApprox(d, 5.0)
    }

    test("distance zero between same points") {
        let d = GeometryHelpers.distance(CGPoint(x: 7, y: 7), CGPoint(x: 7, y: 7))
        try expectApprox(d, 0)
    }

    test("distance is symmetric") {
        let a = CGPoint(x: 1, y: 2)
        let b = CGPoint(x: 5, y: 8)
        try expectApprox(GeometryHelpers.distance(a, b), GeometryHelpers.distance(b, a))
    }

    test("distance with negative coordinates") {
        let d = GeometryHelpers.distance(CGPoint(x: -3, y: -4), CGPoint(x: 0, y: 0))
        try expectApprox(d, 5.0)
    }

    test("angle horizontal right is 0") {
        let a = GeometryHelpers.angle(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 10, y: 0))
        try expectApprox(a, 0)
    }

    test("angle straight up is pi/2") {
        let a = GeometryHelpers.angle(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 0, y: 10))
        try expectApprox(a, .pi / 2)
    }

    test("angle 45 degrees") {
        let a = GeometryHelpers.angle(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 10, y: 10))
        try expectApprox(a, .pi / 4)
    }

    test("expanded rect grows by margin") {
        let rect = CGRect(x: 10, y: 10, width: 20, height: 20)
        let expanded = GeometryHelpers.expanded(rect, by: 5)
        try expectApprox(expanded.origin.x, 5)
        try expectApprox(expanded.origin.y, 5)
        try expectApprox(expanded.width, 30)
        try expectApprox(expanded.height, 30)
    }

    test("expanded with zero margin is identity") {
        let rect = CGRect(x: 10, y: 10, width: 20, height: 20)
        let expanded = GeometryHelpers.expanded(rect, by: 0)
        try expect(expanded == rect)
    }

    test("pointNearLine — point on line") {
        try expect(GeometryHelpers.pointNearLine(point: CGPoint(x: 5, y: 0),
                                                  lineStart: .zero, lineEnd: CGPoint(x: 10, y: 0), threshold: 1))
    }

    test("pointNearLine — point slightly off within threshold") {
        try expect(GeometryHelpers.pointNearLine(point: CGPoint(x: 5, y: 1.5),
                                                  lineStart: .zero, lineEnd: CGPoint(x: 10, y: 0), threshold: 2))
    }

    test("pointNearLine — point far away") {
        try expect(!GeometryHelpers.pointNearLine(point: CGPoint(x: 5, y: 10),
                                                   lineStart: .zero, lineEnd: CGPoint(x: 10, y: 0), threshold: 2))
    }

    test("pointNearLine — degenerate zero-length line near") {
        try expect(GeometryHelpers.pointNearLine(point: CGPoint(x: 1, y: 0),
                                                  lineStart: .zero, lineEnd: .zero, threshold: 2))
    }

    test("pointNearLine — degenerate zero-length line far") {
        try expect(!GeometryHelpers.pointNearLine(point: CGPoint(x: 10, y: 0),
                                                   lineStart: .zero, lineEnd: .zero, threshold: 2))
    }
}
