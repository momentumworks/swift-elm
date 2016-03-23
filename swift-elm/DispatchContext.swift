
protocol DispatchContext {
    associatedtype Action
    var dispatch: Action -> () { get }
}