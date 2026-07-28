//
//  CombineExtHelpers.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Combine
import Foundation

// MARK: - Publisher Convenience Extensions

extension Publisher {

    /// Ignore all output and only complete or fail.
    func asVoid() -> Publishers.Map<Self, Void> {
        map { _ in }
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

    /// Retry with a fixed delay between attempts.
    func retryWithDelay(
        retries: Int,
        delay: TimeInterval
    ) -> AnyPublisher<Output, Failure> {
        self.catch { error -> AnyPublisher<Output, Failure> in
            guard retries > 0 else {
                return Fail(error: error).eraseToAnyPublisher()
            }
            return Just(())
                .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
                .flatMap { _ in
                    self.retryWithDelay(retries: retries - 1, delay: delay * 2)
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Publisher where Failure == Never

extension Publisher where Failure == Never {

    /// Receive on main queue — shorthand.
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
    func mergeAll() -> AnyPublisher<Element.Output, Element.Failure> {
        Publishers.MergeMany(self).eraseToAnyPublisher()
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
