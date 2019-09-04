import Combine
import SwiftUI
import CombineFeedback

class ViewModel<State, Action, Event>: ObservableObject {
    private let input = Feedback<State, Change>.input
    private var cancelable: Cancellable? = nil
    internal let objectWillChange = PassthroughSubject<Void, Never>()
    private(set) var state: State

    init<S: Scheduler>(
        initial: State,
        feedbacks: [Feedback<State, Event>],
        scheduler: S,
        reducer: @escaping (State, Change) -> State
    ) {
        state = initial
        cancelable = Publishers.system(
            initial: initial,
            feedbacks: feedbacks.map { $0.mapEvent(Change.system) } + [input.feedback],
            scheduler: scheduler,
            reduce: reducer
        ).sink { [weak self] state in
            guard let self = self else { return }
            self.objectWillChange.send()
            self.state = state
        }
    }

    deinit {
        cancelable?.cancel()
    }

    enum Change {
        case ui(Action)
        case system(Event)
    }

    func send(action: Action) {
        input.observer(.ui(action))
    }

    func action<T>(
        for keyPath: KeyPath<State, T>
    ) -> Optional<(T) -> Action> {
        return nil
    }

    func binding<T>(
        _ keyPath: KeyPath<State, T>
    ) -> Binding<T> {
        return Binding<T>(
            get: { self.state[keyPath: keyPath] },
            set: { value in
                if let action = self.action(for: keyPath) {
                    self.send(action: action(value))
                }
            }
        )
    }
}

extension Feedback {
    func mapEvent<U>(_ f: @escaping (Event) -> U) -> Feedback<State, U> {
        return Feedback<State, U>(events: { state -> AnyPublisher<U, Never> in
            self.events(state).map(f).eraseToAnyPublisher()
        })
    }

    static var input: (feedback: Feedback, observer: (Event) -> Void) {
        let subject = PassthroughSubject<Event, Never>()
        let feedback = Feedback(events: { _ in
            return subject
        })
        return (feedback, subject.send)
    }
}
