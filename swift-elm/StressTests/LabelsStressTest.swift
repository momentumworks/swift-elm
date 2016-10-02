
import Cocoa
import RxSwift
import RxCocoa

class LabelsStressTest: MWComponent {
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
    }

    // View
    class func view(_ context: Context, model: Model, base: MWComponentBase) -> MWNode {
        let parentBase = MWComponentBase(id: base.id, parentId: base.parentId, frame: base.frame)

        let children = (0...999).map { index -> MWNode in
            let height = 40
            let width = 100
            let xOffset = (index / 10) * (width + 5)
            let yOffset = (index % 10) * (height + 5)
            return MWTextFieldComponent.view(MWTextFieldComponent.Context(dispatch: { context.dispatch(Action.update($0)) }),
                    model: model,
                    base: MWComponentBase(id: "\(base.id)-\(index)", parentId: parentBase.id, frame: NSRect(x: xOffset, y: yOffset, width: width, height: height)))
        }

        return MWViewComponent.view(NSNull(), model: children, base: parentBase)
    }
}

extension LabelsStressTest.Action : Equatable {}
func ==(lhs: LabelsStressTest.Action, rhs: LabelsStressTest.Action) -> Bool {
    switch (lhs, rhs) {
    case (let .update(newLeft), let .update(newRight)):
        return newLeft == newRight
    }
}
