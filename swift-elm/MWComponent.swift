
import Foundation

struct MWComponentBase {
    let id: String
    let parentId: String?
    let frame: NSRect
}

protocol MWComponent {
    associatedtype Model
    associatedtype Action
    associatedtype Context

    static func initModel() -> Model
    static func update(_ action: Action, model: Model) -> Model
    static func view(_ context: Context, model: Model, base: MWComponentBase) -> MWNode
}
