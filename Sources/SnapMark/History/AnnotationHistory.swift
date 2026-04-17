import Foundation

final class AnnotationHistory {
    private var undoStack: [[Annotation]] = []
    private var redoStack: [[Annotation]] = []
    private let maxDepth: Int

    init(maxDepth: Int = Constants.maxUndoDepth) {
        self.maxDepth = maxDepth
    }

    func push(_ state: [Annotation]) {
        let snapshot = state.map { $0.copy() }
        undoStack.append(snapshot)
        if undoStack.count > maxDepth {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    func undo(current: [Annotation]) -> [Annotation]? {
        guard !undoStack.isEmpty else { return nil }
        let state = undoStack.removeLast()
        redoStack.append(current.map { $0.copy() })
        return state
    }

    func redo(current: [Annotation]) -> [Annotation]? {
        guard !redoStack.isEmpty else { return nil }
        let state = redoStack.removeLast()
        undoStack.append(current.map { $0.copy() })
        return state
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
