
import Foundation

func timeAndLog<T>(_ label: String) -> (() -> T) -> T {
    func timeFn(_ fn: () -> T) -> T {
        let start = Date()
        let result = fn()
        let timeTaken = Date().timeIntervalSince(start)
        let formatted = NSString(format: "%.6f", timeTaken)
        NSLog("\(label) completed in \(formatted)s")
        return result
    }
    
    return timeFn
}
