//
//  CombineExtHelpers.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Combine
import CombineExt
import Foundation

// MARK: - Publisher Convenience Extensions (using CombineExt)

extension Publisher {

    /// Ignore all output and only complete or fail.
    /// Useful for fire-and-forget side effects.
    func asVoid() -> Publishers.Map<Self, Void> {
        map { _ in }
    }

    /// Materialize the publisher into `Event<Output, Failure>`,
    /// turning errors into values so downstream never fails.
    ///
    /// Usage:
    /// ```swift
    /// apiPublisher
    ///     .materializeResults()
    ///     .sink { event in
    ///         switch event {
    ///         case .value(let data): handleData(data)
    ///         case .failure(let err): handleError(err)
    ///         case .finished: break
    ///         }
    ///     }
    /// ```
    func materializeResults() -> AnyPublisher<Event<Output, Failure>, Never> {
        self.materialize().eraseToAnyPublisher()
    }

    /// Assigns output to a published property using a weak reference,
    /// preventing retain cycles. Requires `Failure == Never`.
    func assignWeak<Root: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<Root, Output>,
        on object: Root
    ) -> AnyCancellable where Failure == Never {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }

    /// Retry with an exponential backoff delay.
    ///
    /// Usage:
    /// ```swift
    /// networkPublisher
    ///     .retryWithDelay(retries: 3, delay: 1.0)
    /// ```
    func retryWithDelay(
        retries: Int,
        delay: TimeInterval,
        scheduler: some Scheduler = DispatchQueue.main
    ) -> AnyPublisher<Output, Failure> {
        self.retry(retries) { attempt in
            let backoff = delay * pow(2.0, Double(attempt))
            return Just(())
                .delay(for: .seconds(backoff), scheduler: scheduler)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Publisher where Failure == Never

extension Publisher where Failure == Never {

    /// Receive on main queue — shorthand for `.receive(on: DispatchQueue.main)`.
    func onMain() -> Publishers.ReceiveOn<Self, DispatchQueue> {
        receive(on: DispatchQueue.main)
    }

    /// Sink with only a value handler (ignoring completion since Failure == Never).
    func sinkValue(_ handler: @escaping (Output) -> Void) -> AnyCancellable {
        sink(receiveValue: handler)
    }
}

// MARK: - Publisher where Output == Bool

extension Publisher where Output == Bool, Failure == Never {

    /// Negate all emitted Bool values.
    func negate() -> Publishers.Map<Self, Bool> {
        map { !$0 }
    }
}

// MARK: - Collection of Publishers

extension Collection where Element: Publisher {

    /// Merge all publishers in the collection into a single stream.
    ///
    /// Usage:
    /// ```swift
    /// let publishers = urls.map { networkService.fetch($0) }
    /// publishers
    ///     .mergeAll()
    ///     .collect()
    ///     .sink { results in ... }
    /// ```
    func mergeAll() -> AnyPublisher<Element.Output, Element.Failure> {
        MergeMany(self).eraseToAnyPublisher()
    }

    /// Zip all publishers, emitting an array when all complete.
    /// ⚠️ Only works with up to a reasonable number of publishers.
    func zipAll() -> AnyPublisher<[Element.Output], Element.Failure> {
        self.zip().eraseToAnyPublisher()
    }
}

// MARK: - Subject Convenience

extension PassthroughSubject {

    /// Send a value and immediately complete.
    func sendAndComplete(_ value: Output) {
        send(value)
        send(completion: .finished)
    }
}

// MARK: - CancellableStore

/// A lightweight store for AnyCancellable subscriptions.
/// Use as an alternative to `Set<AnyCancellable>` with a cleaner API.
///
/// Usage:
/// ```swift
/// class MyViewModel {
///     private let cancellables = CancellableStore()
///
///     func bind() {
///         somePublisher
///             .sink { ... }
///             .store(in: cancellables)
///     }
/// }
/// ```
final class CancellableStore {
    private var cancellables = Set<AnyCancellable>()

    func store(_ cancellable: AnyCancellable) {
        cancellables.insert(cancellable)
    }

    func cancelAll() {
        cancellables.removeAll()
    }

    deinit {
        cancelAll()
    }
}

extension AnyCancellable {
    func store(in store: CancellableStore) {
        store.store(self)
    }
}
