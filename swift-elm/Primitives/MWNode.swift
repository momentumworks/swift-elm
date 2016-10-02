
import Cocoa
import RxSwift

enum MWNode {
    case view(MWComponentBase, [MWNode])
    case button(MWComponentBase, MWButtonComponent.Model, MWButtonComponent.Context)
    case textField(MWComponentBase, MWTextFieldComponent.Model, MWTextFieldComponent.Context)

    func flatten() -> Array<MWNode> {
        switch self {
        case .view(_, let children):
            return [ self ] + children.flatMap { child in child.flatten() }
        case _:
            return [ self ]
        }
    }

    func base() -> MWComponentBase {
        switch self {
        case .view(let base, _):
            return base
        case .button(let base, _, _):
            return base
        case .textField(let base, _, _):
            return base
        }
    }

    func model() -> Any? {
        switch self {
        case .view(_, _):
            return nil
        case .button(_, let model, _):
            return model
        case .textField(_, let model, _):
            return model
        }
    }

    func createNSView() -> NSView {
        switch self {
        case .view(let base, _):
            return MWViewComponent.create(base.frame, model: nil)
        case .button(let base, let model, _):
            return MWButtonComponent.create(base.frame, model: model)
        case .textField(let base, let model, _):
            return MWTextFieldComponent.create(base.frame, model: model)
        }
    }

    func wireUpNSView(_ nsView: NSView) -> PublishSubject<Any>? {
        switch (self, nsView) {
        case (.button(_, _, let context), _ as NSButton):
            return MWButtonComponent.wireUp(context, nsView: nsView)
        case (.textField(_, _, let context), _ as NSTextField):
            return MWTextFieldComponent.wireUp(context, nsView: nsView)
        case _:
            return nil
        }
    }
}
