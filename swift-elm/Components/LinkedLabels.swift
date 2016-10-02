
import Cocoa
import RxSwift
import RxCocoa

class LinkedLabels: MWComponent {
    // Model
    typealias Model = String
    class func initModel() -> Model {
        return MWTextFieldComponent.initModel()
    }

    // Update
    enum Action {
        case update(MWTextFieldComponent.Action)
    }

    class func update(_ action: Action, model: Model) -> Model {
        switch action {
        case .update(let tfAction):
            return MWTextFieldComponent.update(tfAction, model: model)
        }
    }

    struct Context : DispatchContext {
        let dispatch: (Action) -> ()
        let onDelete: () -> ()
    }

    // View
    class func view(_ context: Context, model: Model, base: MWComponentBase) -> MWNode {
        let size = base.frame.size
        let parentBase = MWComponentBase(id: base.id, parentId: base.parentId, frame: base.frame)

        let left = MWTextFieldComponent.view(MWTextFieldComponent.Context(dispatch: {context.dispatch(Action.update($0))}),
                model: model,
                base: MWComponentBase(id: "\(base.id)-left",  parentId: parentBase.id, frame: NSRect(x: 0,   y: 0, width: 100, height: size.height)))
        let right = MWTextFieldComponent.view(MWTextFieldComponent.Context(dispatch: {context.dispatch(Action.update($0))}),
                model: model,
                base: MWComponentBase(id: "\(base.id)-right", parentId: parentBase.id, frame: NSRect(x: 110, y: 0, width: 100, height: size.height)))
        let deleteButton = MWButtonComponent.view(MWButtonComponent.Context(onTap: {context.onDelete()}),
                model: "-",
                base: MWComponentBase(id: "\(base.id)-delete", parentId: parentBase.id, frame: NSRect(x: 230, y: 5, width: 20, height: 30)))

        return MWViewComponent.view(NSNull(), model: [left, right, deleteButton], base: parentBase)
    }
}

extension LinkedLabels.Action : Equatable {}
func ==(lhs: LinkedLabels.Action, rhs: LinkedLabels.Action) -> Bool {
    switch (lhs, rhs) {
    case (let .update(newLeft), let .update(newRight)):
        return newLeft == newRight
    }
}
