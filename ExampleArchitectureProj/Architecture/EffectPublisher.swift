import Combine

public struct EffectPublisher<Action> {
    enum Operation {
        case none
        case publisher(AnyPublisher<Action, Never>)
    }

    let operation: Operation
}

public extension EffectPublisher {
    static var none: Self {
        Self(operation: .none)
    }

    static func fireAndForget(_ work: @escaping () throws -> Void) -> Self {
        Deferred {
            try? work()
            return Empty<Output, Never>(completeImmediately: true)
        }
        .eraseToEffect()
    }
}
