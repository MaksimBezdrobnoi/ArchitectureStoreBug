import Combine
import SwiftUI

public typealias ViewStoreOf<R: Reducer> = ViewStore<R.State, R.Action>

public final class ViewStore<ViewState, ViewAction>: ObservableObject {
    public var state: ViewState { _state.value }

    private let _send: (ViewAction) -> Task<Void, Never>?
    private let _state: CurrentValueRelay<ViewState>
    private var viewCancellable: AnyCancellable?

    public init(_ store: Store<ViewState, ViewAction>) {
        _send = { store.send($0) }
        _state = CurrentValueRelay(store.state.value)

        viewCancellable = store.state
            .sink { [weak objectWillChange, weak _state] state in
                guard let objectWillChange, let _state else { return }
                objectWillChange.send()
                _state.value = state
            }
    }

    @discardableResult
    public func send(_ action: ViewAction) -> Task<Void, Never>? {
        _send(action)
    }

    public func bind<LocalState>(
        for keyPath: KeyPath<ViewState, LocalState>,
        onChange: @escaping (LocalState) -> ViewAction
    ) -> Binding<LocalState> {
        Binding(
            get: { [weak self] in
                guard let self else { fatalError("Can't get viewStore \(Self.self)") }
                return self.state[keyPath: keyPath]
            },
            set: { [weak self] newValue in
                guard let self else { fatalError("Can't set viewStore \(Self.self)") }
                _ = self._send(onChange(newValue))
            }
        )
    }
}
