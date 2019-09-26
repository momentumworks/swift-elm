
import Cocoa
import RxSwift

protocol MWNativeComponent: MWComponent {
    static func create(_ frame: NSRect, model: Model?) -> NSView
    static func wireUp(_ context: Context, nsView: NSView) -> PublishSubject<Any>? // has to be of type Any because Swift doesn't support variance
}

// MARK: Parent view

class MWViewComponent: MWNativeComponent {
    typealias Model = Array<MWNode>
    class func initModel() -> Model {
        return []
    }

    enum Action {
        case noOp
    }

    class func update(_ action: Action, model: Model) -> Model { return model }

    typealias Context = NSNull

    class func view(_ context: Context, model: Model, base: MWComponentBase) -> MWNode {
        return MWNode.view(base, model)
    }

    class func create(_ frame: NSRect, model: Model?) -> NSView {
        let nsView = NSView(frame: frame)
        return nsView
    }

    class func wireUp(_ context: Context, nsView: NSView) -> PublishSubject<Any>? { return nil }
}

// MARK: Button

class MWButtonComponent: MWNativeComponent {
    typealias Model = String
    class func initModel() -> Model {
        return ""
    }

    enum Action {
        case noOp
    }

    class func update(_ action: Action, model: Model) -> Model { return model }

    struct Context {
        let onTap: () -> ()
    }

    class func view(_ context: Context, model: Model, base: MWComponentBase) -> MWNode {
        return MWNode.button(base, model, context)
    }

    class func create(_ frame: NSRect, model: Model?) -> NSView {
        let nsButton = NSButton(frame: frame)
        nsButton.title = model!
        return nsButton
    }

    class func wireUp(_ context: Context, nsView: NSView) -> PublishSubject<Any>? {
        let nsButton = nsView as! NSButton

        nsButton.rx.tap.subscribe(onNext: {
            context.onTap()
				}).disposed(by: disposeBag)

        return nil
    }
}

// MARK: TextField

class MWTextFieldComponent: MWNativeComponent {
    typealias Model = String
    class func initModel() -> Model {
        return ""
    }

    enum Action {
        case update(String)
    }

    class func update(_ action: Action, model: Model) -> Model {
        switch action {
        case .update(let newModel):
            return newModel
        }
    }

    struct Context : DispatchContext {
        let dispatch: (Action) -> ()
    }

    class func view(_ context: Context, model: Model, base: MWComponentBase) -> MWNode {
        return MWNode.textField(base, model, context)
    }

    class func create(_ frame: NSRect, model: Model?) -> NSView {
        let nsTextField = NSTextField(frame: frame)
        return nsTextField
    }

    class func wireUp(_ context: Context, nsView: NSView) -> PublishSubject<Any>? {
        let channel = PublishSubject<Any>()
        let nsTextField = nsView as! NSTextField

			channel.map{"\($0)"}.subscribe(nsTextField.rx.text)
				.disposed(by: disposeBag)

        nsTextField.rx.text.subscribe(onNext: { text in
					context.dispatch(Action.update(text!))
				}).disposed(by: disposeBag)

        return channel
    }
}

extension MWTextFieldComponent.Action : Equatable {}
func ==(lhs: MWTextFieldComponent.Action, rhs: MWTextFieldComponent.Action) -> Bool {
    switch (lhs, rhs) {
    case (let .update(newLeft), let .update(newRight)):
        return newLeft == newRight
    }
}
