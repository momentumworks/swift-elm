
import Cocoa
import RxSwift

protocol MWNativeComponent: MWComponent {
    static func create(frame: NSRect, model: Model?) -> NSView
    static func wireUp(context: Context, nsView: NSView) -> PublishSubject<Any>? // has to be of type Any because Swift doesn't support variance
}

// MARK: Parent view

class MWViewComponent: MWNativeComponent {
    typealias Model = Array<MWNode>
    class func initModel() -> Model {
        return []
    }

    enum Action {
        case NoOp
    }

    class func update(action: Action, model: Model) -> Model { return model }

    typealias Context = NSNull

    class func view(context: Context, model: Model, base: MWComponentBase) -> MWNode {
        return MWNode.View(base, model)
    }

    class func create(frame: NSRect, model: Model?) -> NSView {
        let nsView = NSView(frame: frame)
        return nsView
    }

    class func wireUp(context: Context, nsView: NSView) -> PublishSubject<Any>? { return nil }
}

// MARK: Button

class MWButtonComponent: MWNativeComponent {
    typealias Model = String
    class func initModel() -> Model {
        return ""
    }

    enum Action {
        case NoOp
    }

    class func update(action: Action, model: Model) -> Model { return model }

    struct Context {
        let onTap: () -> ()
    }

    class func view(context: Context, model: Model, base: MWComponentBase) -> MWNode {
        return MWNode.Button(base, model, context)
    }

    class func create(frame: NSRect, model: Model?) -> NSView {
        let nsButton = NSButton(frame: frame)
        nsButton.title = model!
        return nsButton
    }

    class func wireUp(context: Context, nsView: NSView) -> PublishSubject<Any>? {
        let nsButton = nsView as! NSButton

        nsButton.rx_tap.subscribeNext({
            context.onTap()
        }).addDisposableTo(disposeBag)

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
        case Update(String)
    }

    class func update(action: Action, model: Model) -> Model {
        switch action {
        case .Update(let newModel):
            return newModel
        }
    }

    struct Context : DispatchContext {
        let dispatch: Action -> ()
    }

    class func view(context: Context, model: Model, base: MWComponentBase) -> MWNode {
        return MWNode.TextField(base, model, context)
    }

    class func create(frame: NSRect, model: Model?) -> NSView {
        let nsTextField = NSTextField(frame: frame)
        return nsTextField
    }

    class func wireUp(context: Context, nsView: NSView) -> PublishSubject<Any>? {
        let channel = PublishSubject<Any>()
        let nsTextField = nsView as! NSTextField

        channel.map{"\($0)"}.subscribe(nsTextField.rx_text).addDisposableTo(disposeBag)
        nsTextField.rx_text.subscribeNext({ text in
            context.dispatch(Action.Update(text))
        }).addDisposableTo(disposeBag)

        return channel
    }
}

extension MWTextFieldComponent.Action : Equatable {}
func ==(lhs: MWTextFieldComponent.Action, rhs: MWTextFieldComponent.Action) -> Bool {
    switch (lhs, rhs) {
    case (let .Update(newLeft), let .Update(newRight)):
        return newLeft == newRight
    }
}