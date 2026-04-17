import XCTest
@testable import SnapMark

final class SnapMarkTests: XCTestCase {
    func testNormalizedRect() {
        let rect = GeometryHelpers.normalizedRect(from: CGPoint(x: 100, y: 100),
                                                   to: CGPoint(x: 50, y: 50))
        XCTAssertEqual(rect.origin.x, 50)
        XCTAssertEqual(rect.origin.y, 50)
        XCTAssertEqual(rect.width, 50)
        XCTAssertEqual(rect.height, 50)
    }

    func testDistance() {
        let d = GeometryHelpers.distance(CGPoint(x: 0, y: 0), CGPoint(x: 3, y: 4))
        XCTAssertEqual(d, 5, accuracy: 0.001)
    }

    func testAnnotationHistory() {
        let history = AnnotationHistory(maxDepth: 5)
        let a1 = RectangleAnnotation(origin: .zero, end: CGPoint(x: 10, y: 10))
        let a2 = RectangleAnnotation(origin: .zero, end: CGPoint(x: 20, y: 20))

        history.push([a1])
        XCTAssertTrue(history.canUndo)
        XCTAssertFalse(history.canRedo)

        if let state = history.undo(current: [a1, a2]) {
            XCTAssertEqual(state.count, 1)
            XCTAssertTrue(history.canRedo)
        } else {
            XCTFail("Undo should return state")
        }
    }

    func testPointNearLine() {
        let near = GeometryHelpers.pointNearLine(
            point: CGPoint(x: 5, y: 1),
            lineStart: CGPoint(x: 0, y: 0),
            lineEnd: CGPoint(x: 10, y: 0),
            threshold: 2
        )
        XCTAssertTrue(near)

        let far = GeometryHelpers.pointNearLine(
            point: CGPoint(x: 5, y: 10),
            lineStart: CGPoint(x: 0, y: 0),
            lineEnd: CGPoint(x: 10, y: 0),
            threshold: 2
        )
        XCTAssertFalse(far)
    }
}
