
import Foundation

func timeAndLog<T>(label: String) -> (() -> T) -> T {
    func timeFn(fn: () -> T) -> T {
        let start = NSDate()
        let result = fn()
        let timeTaken = NSDate().timeIntervalSinceDate(start)
        let formatted = NSString(format: "%.6f", timeTaken)
        NSLog("\(label) completed in \(formatted)s")
        return result
    }
    
    return timeFn
}