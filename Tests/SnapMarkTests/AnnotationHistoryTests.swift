import AppKit
@testable import SnapMarkLib

func runAnnotationHistoryTests() {
    suite("AnnotationHistory")

    test("initial state has no undo/redo") {
        let h = AnnotationHistory()
        try expect(!h.canUndo)
        try expect(!h.canRedo)
    }

    test("push enables undo") {
        let h = AnnotationHistory()
        h.push([RectangleAnnotation(origin: .zero, end: CGPoint(x: 10, y: 10))])
        try expect(h.canUndo)
        try expect(!h.canRedo)
    }

    test("undo returns previous state") {
        let h = AnnotationHistory()
        let a1 = RectangleAnnotation(origin: .zero, end: CGPoint(x: 10, y: 10))
        let a2 = RectangleAnnotation(origin: CGPoint(x: 20, y: 20), end: CGPoint(x: 40, y: 40))
        h.push([a1])
        let state = try expectNotNil(h.undo(current: [a1, a2]))
        try expectEqual(state.count, 1)
    }

    test("undo enables redo") {
        let h = AnnotationHistory()
        h.push([RectangleAnnotation(origin: .zero, end: CGPoint(x: 10, y: 10))])
        _ = h.undo(current: [])
        try expect(h.canRedo)
    }

    test("redo returns undone state") {
        let h = AnnotationHistory()
        let a1 = RectangleAnnotation(origin: .zero, end: CGPoint(x: 10, y: 10))
        let a2 = RectangleAnnotation(origin: CGPoint(x: 20, y: 20), end: CGPoint(x: 40, y: 40))
        h.push([a1])
        _ = h.undo(current: [a1, a2])
        let state = try expectNotNil(h.redo(current: [a1]))
        try expectEqual(state.count, 2)
    }

    test("push clears redo stack") {
        let h = AnnotationHistory()
        h.push([RectangleAnnotation(origin: .zero, end: CGPoint(x: 10, y: 10))])
        h.push([RectangleAnnotation(origin: .zero, end: CGPoint(x: 20, y: 20))])
        _ = h.undo(current: [])
        try expect(h.canRedo)
        h.push([RectangleAnnotation(origin: .zero, end: CGPoint(x: 50, y: 50))])
        try expect(!h.canRedo)
    }

    test("multiple undo steps") {
        let h = AnnotationHistory()
        let mk = { RectangleAnnotation(origin: .zero, end: CGPoint(x: 10, y: 10)) }
        h.push([])
        h.push([mk()])
        h.push([mk(), mk()])
        let current = [mk(), mk(), mk()]

        let s2 = try expectNotNil(h.undo(current: current))
        try expectEqual(s2.count, 2)
        let s1 = try expectNotNil(h.undo(current: s2))
        try expectEqual(s1.count, 1)
        let s0 = try expectNotNil(h.undo(current: s1))
        try expectEqual(s0.count, 0)
        try expect(h.undo(current: s0) == nil, "should be nil at bottom of stack")
    }

    test("undo on empty returns nil") {
        let h = AnnotationHistory()
        try expect(h.undo(current: []) == nil)
    }

    test("redo on empty returns nil") {
        let h = AnnotationHistory()
        try expect(h.redo(current: []) == nil)
    }

    test("maxDepth enforced") {
        let h = AnnotationHistory(maxDepth: 3)
        let mk = { (i: Int) in RectangleAnnotation(origin: CGPoint(x: CGFloat(i), y: 0), end: CGPoint(x: CGFloat(i) + 10, y: 10)) }
        h.push([mk(0)])
        h.push([mk(1)])
        h.push([mk(2)])
        h.push([mk(3)])  // should drop the first

        var current: [Annotation] = [mk(4)]
        var count = 0
        while let state = h.undo(current: current) {
            current = state
            count += 1
        }
        try expectEqual(count, 3)
    }

    test("clear removes all state") {
        let h = AnnotationHistory()
        h.push([RectangleAnnotation(origin: .zero, end: CGPoint(x: 10, y: 10))])
        _ = h.undo(current: [])
        h.clear()
        try expect(!h.canUndo)
        try expect(!h.canRedo)
    }

    test("undo copies are independent of mutations") {
        let h = AnnotationHistory()
        let original = RectangleAnnotation(origin: .zero, end: CGPoint(x: 10, y: 10))
        h.push([original])
        original.origin = CGPoint(x: 999, y: 999)
        let restored = try expectNotNil(h.undo(current: []))
        let r = try expectNotNil(restored.first as? RectangleAnnotation)
        try expectApprox(r.origin.x, 0)
    }
}
