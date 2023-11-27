import Combine
import Foundation

public typealias StoreOf<R: Reducer> = Store<R.State, R.Action>

public final class Store<State, Action> {
    private(set) var state: CurrentValueSubject<State, Never>
    private var effectCancellables: [UUID: AnyCancellable] = [:]
    private var bufferedActions: [Action] = []
    private var isSending = false
    private let reducer: any Reducer<State, Action>

    public init<R: Reducer>(
        initialState: @autoclosure () -> R.State,
        reducer: R
    ) where R.State == State, R.Action == Action {
        state = CurrentValueSubject(initialState())
        self.reducer = reducer

        reducer.prependActions.forEach { _ = self.send($0) }
    }

    deinit {
        effectCancellables.values.forEach { $0.cancel() }
        effectCancellables.removeAll()
    }

    public func send(
        _ action: Action,
        originatingFrom originatingAction: Action? = nil
    ) -> Task<Void, Never>? {
        bufferedActions.append(action)
        guard !isSending else { return nil }

        isSending = true
        var currentState = state.value
        let tasks = Box<[Task<Void, Never>]>(wrappedValue: [])
        defer {
            withExtendedLifetime(bufferedActions) {
                bufferedActions.removeAll()
            }
            state.value = currentState
            isSending = false
            if !bufferedActions.isEmpty {
                if let task = send(
                    bufferedActions.removeLast(), originatingFrom: originatingAction
                ) {
                    tasks.wrappedValue.append(task)
                }
            }
        }

        var index = bufferedActions.startIndex
        while index < bufferedActions.endIndex {
            defer { index += 1 }
            let action = bufferedActions[index]
            let effect = reducer.reduce(into: &currentState, action: action)

            switch effect.operation {
            case .none:
                break

            case .publisher(let publisher):
                var didComplete = false
                let boxedTask = Box<Task<Void, Never>?>(wrappedValue: nil)
                let uuid = UUID()
                let effectCancellable =
                    publisher
                        .handleEvents(receiveCancel: { [weak self] in
                            self?.effectCancellables[uuid] = nil
                        })
                        .sink(
                            receiveCompletion: { [weak self] _ in
                                boxedTask.wrappedValue?.cancel()
                                didComplete = true
                                self?.effectCancellables[uuid] = nil
                            },
                            receiveValue: { [weak self] effectAction in
                                guard let self else { return }
                                if let task = self.send(effectAction, originatingFrom: action) {
                                    tasks.wrappedValue.append(task)
                                }
                            }
                        )

                if !didComplete {
                    let task = Task<Void, Never> { @MainActor in
                        for await _ in AsyncStream<Void>.never {}
                        effectCancellable.cancel()
                    }
                    boxedTask.wrappedValue = task
                    tasks.wrappedValue.append(task)
                    effectCancellables[uuid] = effectCancellable
                }
            }
        }

        guard !tasks.wrappedValue.isEmpty else { return nil }
        return Task { @MainActor in
            await withTaskCancellationHandler {
                var index = tasks.wrappedValue.startIndex
                while index < tasks.wrappedValue.endIndex {
                    defer { index += 1 }
                    await tasks.wrappedValue[index].value
                }
            } onCancel: {
                var index = tasks.wrappedValue.startIndex
                while index < tasks.wrappedValue.endIndex {
                    defer { index += 1 }
                    tasks.wrappedValue[index].cancel()
                }
            }
        }
    }
}
