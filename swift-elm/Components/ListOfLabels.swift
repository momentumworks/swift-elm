
import Cocoa
import RxSwift
import RxCocoa

class ListOfLabels: MWComponent {
    typealias ID = Int

    // Model
    struct Model {
        let labels: Array<(ID, LinkedLabels.Model)>
        let nextID: Int
    }

    class func initModel() -> Model {
        return Model (
        labels: [(1, LinkedLabels.initModel())],
                nextID: 2
        )
    }

    // Update
    enum Action {
        case Insert
        case Remove(ID)
        case Update(ID, LinkedLabels.Action)
    }

    class func update(action: Action, model: Model) -> Model {
        switch action {
        case .Insert:
            return Model (
            labels: model.labels + [(model.nextID, LinkedLabels.initModel())],
                    nextID: model.nextID + 1
            )

        case .Remove(let id):
            return Model (
            labels: model.labels.filter{ (labelID, _) in labelID != id },
                    nextID: model.nextID
            )

        case .Update(let id, let llAction):
            let updateLabel =   { (labelID: ID, label: String) -> (ID, LinkedLabels.Model) in
                if (labelID == id) { return (labelID, LinkedLabels.update(llAction, model: label)) }
                else { return (labelID, label) }
            }
            return Model (
            labels: model.labels.map { (labelID, label) in updateLabel(labelID, label) },
                    nextID: model.nextID
            )

        }

    }

    struct Context : DispatchContext {
        let dispatch: Action -> ()
    }

    // View
    class func view(context: Context, model: Model, base: MWComponentBase) -> MWNode {
        let addButton = MWButtonComponent.view(MWButtonComponent.Context(onTap: {context.dispatch(Action.Insert)}),
                model: "Add",
                base: MWComponentBase(id: "addButton", parentId: base.id, frame: NSRect(x: 10, y: 300, width: 50, height: 30)))
        let children = model.labels.enumerate().map { (index, idWithLabel) -> MWNode in
            let (id, label) = idWithLabel
            let linkedLabelsBase = MWComponentBase(id: "\(base.id)-child-\(id)", parentId: base.id, frame: NSRect(x: 10, y: 10 + (40 * index), width: 250, height: 40))
            return LinkedLabels.view(LinkedLabels.Context(dispatch: { context.dispatch(Action.Update(id, $0)) }, onDelete: { context.dispatch(Action.Remove(id)) }),
                    model: label,
                    base: linkedLabelsBase)
        } + [ addButton ]

        return MWViewComponent.view(NSNull(), model: children, base: MWComponentBase(id: base.id, parentId: base.parentId, frame: base.frame))
    }
}

extension ListOfLabels.Action : Equatable {}
func ==(lhs: ListOfLabels.Action, rhs: ListOfLabels.Action) -> Bool {
    switch (lhs, rhs) {
    case (let .Update(newLeftID, newLeftAction), let .Update(newRightID, newRightAction)):
        return newLeftID == newRightID &&
                newLeftAction == newRightAction
    case _:
        return false
    }
}