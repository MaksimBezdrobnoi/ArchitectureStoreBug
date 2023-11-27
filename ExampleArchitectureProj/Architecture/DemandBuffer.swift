import Combine
import Darwin

internal final class DemandBuffer<S: Subscriber>: @unchecked Sendable {
    private let subscriber: S
    private let lock: os_unfair_lock_t
    private var buffer = [S.Input]()
    private var demandState = Demand()

    init(subscriber: S) {
        self.subscriber = subscriber
        lock = os_unfair_lock_t.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
    }

    deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
    }

    func buffer(value: S.Input) -> Subscribers.Demand {
        switch demandState.requested {
        case .unlimited:
            return subscriber.receive(value)
        default:
            buffer.append(value)
            return flush()
        }
    }

    func demand(_ demand: Subscribers.Demand) -> Subscribers.Demand {
        flush(adding: demand)
    }

    private func flush(adding newDemand: Subscribers.Demand? = nil) -> Subscribers.Demand {
        lock.sync {
            newDemand.map { demandState.requested += $0 }

            // If buffer isn't ready for flushing, return immediately
            guard demandState.requested > 0 || newDemand == Subscribers.Demand.none
            else { return .none }

            while !buffer.isEmpty, demandState.processed < demandState.requested {
                demandState.requested += subscriber.receive(buffer.remove(at: 0))
                demandState.processed += 1
            }

            let sentDemand = demandState.requested - demandState.sent
            demandState.sent += sentDemand
            return sentDemand
        }
    }

    private struct Demand {
        var processed: Subscribers.Demand = .none
        var requested: Subscribers.Demand = .none
        var sent: Subscribers.Demand = .none
    }
}
