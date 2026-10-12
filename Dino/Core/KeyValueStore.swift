import Foundation

/// The narrow slice of UserDefaults this store needs, so tests can run against
/// an in-memory double instead of the app's real defaults.
public protocol KeyValueStore: AnyObject {
    func integer(forKey key: String) -> Int
    func string(forKey key: String) -> String?
    func object(forKey key: String) -> Any?
    func stringArray(forKey key: String) -> [String]?
    func set(_ value: Int, forKey key: String)
    func set(_ value: Any?, forKey key: String)
    func removeObject(forKey key: String)
    func removeAllObjects()
}

extension UserDefaults: KeyValueStore {
    public func removeAllObjects() {
        // Removes values from this app/suite; global system preferences are read-only here.
        for key in dictionaryRepresentation().keys { removeObject(forKey: key) }
    }
}

/// A dictionary-backed store for tests.
public final class InMemoryKeyValueStore: KeyValueStore {
    private var storage: [String: Any]

    public init(_ initial: [String: Any] = [:]) {
        storage = initial
    }

    public func integer(forKey key: String) -> Int { (storage[key] as? Int) ?? 0 }
    public func string(forKey key: String) -> String? { storage[key] as? String }
    public func object(forKey key: String) -> Any? { storage[key] }
    public func stringArray(forKey key: String) -> [String]? { storage[key] as? [String] }
    public func set(_ value: Int, forKey key: String) { storage[key] = value }
    public func set(_ value: Any?, forKey key: String) { storage[key] = value }
    public func removeObject(forKey key: String) { storage.removeValue(forKey: key) }
    public func removeAllObjects() { storage.removeAll() }
}
