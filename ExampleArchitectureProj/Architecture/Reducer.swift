public protocol Reducer<State, Action> {
    associatedtype State
    associatedtype Action

    var prependActions: [Action] { get }
    func reduce(into state: inout State, action: Action) -> EffectPublisher<Action>
}

public extension Reducer {
    var prependActions: [Action] { [] }
}
