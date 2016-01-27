
import Cocoa
import RxSwift

enum MWNode {
    case View(MWComponentBase, [MWNode])
    case Button(MWComponentBase, MWButtonComponent.Model, MWButtonComponent.Context)
    case TextField(MWComponentBase, MWTextFieldComponent.Model, MWTextFieldComponent.Context)

    func flatten() -> Array<MWNode> {
        switch self {
        case .View(_, let children):
            return [ self ] + children.flatMap { child in child.flatten() }
        case _:
            return [ self ]
        }
    }

    func base() -> MWComponentBase {
        switch self {
        case .View(let base, _):
            return base
        case .Button(let base, _, _):
            return base
        case .TextField(let base, _, _):
            return base
        }
    }

    func model() -> Any? {
        switch self {
        case .View(_, _):
            return nil
        case .Button(_, let model, _):
            return model
        case .TextField(_, let model, _):
            return model
        }
    }

    func createNSView() -> NSView {
        switch self {
        case .View(let base, _):
            return MWViewComponent.create(base.frame, model: nil)
        case .Button(let base, let model, _):
            return MWButtonComponent.create(base.frame, model: model)
        case .TextField(let base, let model, _):
            return MWTextFieldComponent.create(base.frame, model: model)
        }
    }

    func wireUpNSView(nsView: NSView) -> PublishSubject<Any>? {
        switch (self, nsView) {
        case (.Button(_, _, let context), _ as NSButton):
            return MWButtonComponent.wireUp(context, nsView: nsView)
        case (.TextField(_, _, let context), _ as NSTextField):
            return MWTextFieldComponent.wireUp(context, nsView: nsView)
        case _:
            return nil
        }
    }
}