// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Collects the first value from an `AsyncStream`, racing against a timeout.
/// Returns `nil` if the timeout fires first.
func firstValue<T: Sendable>(
    from stream: AsyncStream<T>,
    timeout: Duration = .seconds(10)
) async -> T? {
    await withTaskGroup(of: T?.self) { group in
        group.addTask {
            for await value in stream { return value }
            return nil
        }
        group.addTask {
            try? await Task.sleep(for: timeout)
            return nil
        }
        let result = await group.next() ?? nil
        group.cancelAll()
        return result
    }
}

/// Collects up to `count` values from an `AsyncStream`, racing against a timeout.
/// Returns whatever was collected when either the count is reached or the timeout fires.
func collectValues<T: Sendable>(
    from stream: AsyncStream<T>,
    count: Int,
    timeout: Duration = .seconds(10)
) async -> [T] {
    await withTaskGroup(of: [T].self) { group in
        group.addTask {
            var collected: [T] = []
            for await value in stream {
                collected.append(value)
                if collected.count >= count { break }
            }
            return collected
        }
        group.addTask {
            try? await Task.sleep(for: timeout)
            return []
        }
        let result = await group.next() ?? []
        group.cancelAll()
        return result
    }
}

/// Returns the first event from an `AsyncStream` matching a predicate, racing against a timeout.
/// Returns `nil` if the timeout fires first or no matching event arrives.
func firstEvent<T: Sendable>(
    from stream: AsyncStream<T>,
    timeout: Duration = .seconds(10),
    matching predicate: @Sendable @escaping (T) -> Bool
) async -> T? {
    await withTaskGroup(of: T?.self) { group in
        group.addTask {
            for await value in stream where predicate(value) {
                return value
            }
            return nil
        }
        group.addTask {
            try? await Task.sleep(for: timeout)
            return nil
        }
        let result = await group.next() ?? nil
        group.cancelAll()
        return result
    }
}

/// Collects events from an `AsyncStream` until a predicate on the accumulated array is satisfied,
/// racing against a timeout. Returns whatever was collected when either the predicate is met
/// or the timeout fires.
func collectEvents<T: Sendable>(
    from stream: AsyncStream<T>,
    timeout: Duration = .seconds(10),
    until predicate: @Sendable @escaping ([T]) -> Bool
) async -> [T] {
    await withTaskGroup(of: [T].self) { group in
        group.addTask {
            var collected: [T] = []
            for await value in stream {
                collected.append(value)
                if predicate(collected) { break }
            }
            return collected
        }
        group.addTask {
            try? await Task.sleep(for: timeout)
            return []
        }
        let result = await group.next() ?? []
        group.cancelAll()
        return result
    }
}
