
import Cocoa
import RxSwift
import RxCocoa

typealias App = ListOfLabels

enum AppAction {
    case initApp
    case action(App.Action)
}

extension AppAction : Equatable {}
func ==(lhs: AppAction, rhs: AppAction) -> Bool {
    // For the action enums, we only want this to return true in cases where we want to suppress repeated calls of the same action
    switch (lhs, rhs) {
    case (let .action(left), let .action(right)):
        return left == right
    case _:
        return false
    }
}

let disposeBag = DisposeBag()

func render(_ hostView: NSView, base: MWComponentBase) {
    let appChannel = PublishSubject<AppAction>()
    var appNodes = Dictionary<String, NSView>()
    var appNodeKeys = Set<String>()
    var appStreams = Dictionary<String, PublishSubject<Any>>()
    
    let loop = appChannel.distinctUntilChanged().scan(App.initModel()) { (model, appAction) in
        let updatedModel: App.Model
        print(appAction)
        switch appAction {
        case .initApp:
            updatedModel = model
        case .action(let action):
            updatedModel = App.update(action, model: model)
        }
        return updatedModel
    }
    
    loop.subscribe(onNext: { model in
        timeAndLog("Updating model")({
            
            let updatedRoot = timeAndLog("Building the Virtual DOM")({
                App.view(App.Context(dispatch: { appChannel.onNext(AppAction.action($0)) }),
                    model: model,
                    base: base)
            })
            
            let allNodes = timeAndLog("Flattening the Virtual DOM")({ updatedRoot.flatten() })
            let allNodeIds = timeAndLog("Fetching all node IDs")({
                Set(allNodes.map { $0.base().id })
            })
            
            var addedNodes = Array<MWNode>()
            var updatedNodes = Array<MWNode>()
            
            timeAndLog("Calculating the added and updated nodes")({
                for node in allNodes {
                    if (appNodes[node.base().id] == nil) {
                        addedNodes.append(node)
                    } else {
                        updatedNodes.append(node)
                    }
                }
            })
            
          let removedNodeIds = timeAndLog("Calculating the removed nodes")({
                appNodeKeys.subtracting(allNodeIds)
            })
            
            timeAndLog("Rendering the new nodes")({
                for vnode in addedNodes {
                    // Create the node first, add it to the dict, and wire it up at the end,
                    // otherwise doing so earlier will cause an infinite loop here
                    let v = vnode.createNSView()
                    let vnodeId = vnode.base().id
                    appNodes[vnodeId] = v
                    appNodeKeys.insert(vnodeId)
                    if (vnode.base().parentId != nil) {
                        appNodes[vnode.base().parentId!]!.addSubview(v)
                    } else {
                        hostView.addSubview(v)
                    }
                    
                    let stream = vnode.wireUpNSView(v)
                    appStreams[vnodeId] = stream
                    
                    // This next step causes the loop to run again, which we don't want.
                    stream?.on(.next(vnode.model()!))
                }
            })
            
            timeAndLog("Removing the deleted nodes")({
                for vnodeId in removedNodeIds {
                    appNodes[vnodeId]?.removeFromSuperview()
                    appNodes.removeValue(forKey: vnodeId)
                    appNodeKeys.remove(vnodeId)
                    let toBeDisposed = appStreams.removeValue(forKey: vnodeId)
                    toBeDisposed?.on(.completed)
                    toBeDisposed?.dispose()
                }
            })
            
            timeAndLog("Updating the updated nodes")({
                for vnode in updatedNodes {
                    let vnodeId = vnode.base().id
                    let view = appNodes[vnodeId]
                    view?.frame = vnode.base().frame
                    
                    if (vnode.model() != nil) {
                        appStreams[vnodeId]?.on(.next(vnode.model()!))
                    }
                }
            })
        })
		}).disposed(by: disposeBag)
    
    appChannel.on(.next(AppAction.initApp))
}

// MARK: AppDelegate

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    let disposeBag = DisposeBag()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let rootNode = NSView(frame: self.window.contentView!.bounds)
        let appBase = MWComponentBase(id: "app", parentId: nil, frame: self.window.contentView!.bounds)
        render(rootNode, base: appBase)
        window.contentView!.addSubview(rootNode)
        window.makeKeyAndOrderFront(nil)
    }
}
