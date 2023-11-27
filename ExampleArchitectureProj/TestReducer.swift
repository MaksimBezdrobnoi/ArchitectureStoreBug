import Foundation
import Combine

enum ErrorActive {
    case someError
}

public struct TestReducer: Reducer {

    public struct State: Equatable {
        var errorActive: Bool = false
        public init() {}
    }

    public enum Action: Equatable {
        case getError
        case setupError(Bool)
        case resignError
    }

    public init() {}

    public func reduce(into state: inout State, action: Action) -> EffectPublisher<Action> {
        switch action {
        case .getError:
            return Just("")
                .ignoreOutput()
                .delay(for: .seconds(0.5), scheduler: DispatchQueue.main)
                .andThen(justReturn: Action.setupError(true))
                .eraseToEffect()


        case .setupError(let error):
            state.errorActive = error
            return .none

        case .resignError:
            state.errorActive = false
            return .none
        }
    }
}

public extension Publisher where Output == Never {

    func setOutputType<NewOutput>(
        to outputType: NewOutput.Type
    ) -> Publishers.Map<Self, NewOutput> {
        map { _ -> NewOutput in }
    }

    func andThen<T, P: Publisher>(
        _ publisher: P
    ) -> AnyPublisher<T, Failure> where P.Output == T, P.Failure == Failure {
        setOutputType(to: T.self)
            .compactMap { $0 }
            .append(publisher)
            .eraseToAnyPublisher()
    }

    func andThen<T, P: Publisher>(
        _ publisher: P
    ) -> AnyPublisher<T, Failure> where P.Output == T, P.Failure == Never {
        andThen(publisher.setFailureType(to: Failure.self))
    }

    func andThen<Element>(justReturn output: Element) -> AnyPublisher<Element, Failure> {
        andThen(Just(output))
    }
}
