
protocol DispatchContext {
    typealias Action
    var dispatch: Action -> () { get }
}