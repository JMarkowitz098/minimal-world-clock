import Foundation

/// Where the app keeps what the user chose (the Clock window's zone, later Compare's zones and
/// settings). Values are stored as JSON data by key. Reading is lenient: missing, corrupt, or
/// unknown data reads as `nil`, and callers fall back to their defaults.
public protocol SettingsStore: AnyObject {
    func data(forKey key: String) -> Data?
    func setData(_ data: Data?, forKey key: String)
}

/// Keys used in a `SettingsStore`. Never rename one: saved data from older versions uses it.
public enum SettingsKey {
    public static let clockZone = "clockZone"
}

extension SettingsStore {
    /// The value saved under `key`, or `nil` when there is none or it doesn't decode.
    public func value<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// Saves `value` under `key`; `nil` removes it.
    public func setValue<T: Encodable>(_ value: T?, forKey key: String) {
        setData(value.flatMap { try? JSONEncoder().encode($0) }, forKey: key)
    }

    /// The zone shown in the Clock window.
    public var clockZone: Zone? {
        get { value(Zone.self, forKey: SettingsKey.clockZone) }
        set { setValue(newValue, forKey: SettingsKey.clockZone) }
    }
}

/// Persists settings in `UserDefaults` (the standard defaults in the app).
public final class UserDefaultsSettingsStore: SettingsStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    public func setData(_ data: Data?, forKey key: String) {
        defaults.set(data, forKey: key)
    }
}

/// Keeps settings in memory only. For tests and snapshots.
public final class InMemorySettingsStore: SettingsStore {
    private var storage: [String: Data] = [:]

    public init() {}

    public func data(forKey key: String) -> Data? {
        storage[key]
    }

    public func setData(_ data: Data?, forKey key: String) {
        storage[key] = data
    }
}
