import Combine

extension EffectPublisher: Publisher {
    public typealias Output = Action
    public typealias Failure = Never

    private var publisher: AnyPublisher<Action, Never> {
        switch operation {
        case .none:
            return Empty().eraseToAnyPublisher()

        case .publisher(let publisher):
            return publisher
        }
    }

    public func receive<S: Combine.Subscriber>(
        subscriber: S
    ) where S.Input == Action, S.Failure == Never {
        publisher.subscribe(subscriber)
    }
}

public extension Publisher where Failure == Never {
    func eraseToEffect() -> EffectPublisher<Output> {
        EffectPublisher(self)
    }
}

private extension EffectPublisher {
    init<P: Publisher>(_ publisher: P) where P.Output == Output, P.Failure == Never {
        operation = .publisher(publisher.eraseToAnyPublisher())
    }
}
