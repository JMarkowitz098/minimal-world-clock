import Foundation

/// Where the app keeps what the user chose (the Clock and Compare windows' zones, later
/// settings). Values are stored as JSON data by key. Reading is lenient: missing, corrupt, or
/// unknown data reads as `nil`, and callers fall back to their defaults.
public protocol SettingsStore: AnyObject {
    func data(forKey key: String) -> Data?
    func setData(_ data: Data?, forKey key: String)
    /// Called when a saved value can't be read (it then reads as `nil`), so the app can log it:
    /// otherwise a lost setting is invisible. Core can't log itself (Foundation only).
    func reportUnreadable(key: String, error: any Error)
}

/// Keys used in a `SettingsStore`. Never rename one: saved data from older versions uses it.
public enum SettingsKey {
    public static let clockZone = "clockZone"
    public static let compareZoneA = "compareZoneA"
    public static let compareZoneB = "compareZoneB"
}

extension SettingsStore {
    /// Does nothing; stores that can report (the app's) override it.
    public func reportUnreadable(key: String, error: any Error) {}

    /// The value saved under `key`, or `nil` when there is none or it doesn't decode (reported
    /// with `reportUnreadable`).
    public func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            reportUnreadable(key: key, error: error)
            return nil
        }
    }

    /// Saves `value` under `key`; `nil` removes it. If `value` fails to encode, the saved
    /// value is left as it was rather than erased.
    public func save<T: Encodable>(_ value: T?, forKey key: String) {
        guard let value else { return setData(nil, forKey: key) }
        guard let data = try? JSONEncoder().encode(value) else { return }
        setData(data, forKey: key)
    }

    /// The zone shown in the Clock window.
    public var clockZone: Zone? {
        get { load(Zone.self, forKey: SettingsKey.clockZone) }
        set { save(newValue, forKey: SettingsKey.clockZone) }
    }

    /// The Compare window's first zone (the one the scrubber sets the time in). Saved apart
    /// from `compareZoneB`, so one unreadable zone doesn't lose the other.
    public var compareZoneA: Zone? {
        get { load(Zone.self, forKey: SettingsKey.compareZoneA) }
        set { save(newValue, forKey: SettingsKey.compareZoneA) }
    }

    /// The Compare window's second zone.
    public var compareZoneB: Zone? {
        get { load(Zone.self, forKey: SettingsKey.compareZoneB) }
        set { save(newValue, forKey: SettingsKey.compareZoneB) }
    }
}

/// Persists settings in `UserDefaults` (the standard defaults in the app).
public final class UserDefaultsSettingsStore: SettingsStore {
    private let defaults: UserDefaults
    private let onUnreadable: (String, any Error) -> Void

    /// - Parameter onUnreadable: called with the key and error when a saved value can't be read;
    ///   the app logs it.
    public init(defaults: UserDefaults = .standard, onUnreadable: @escaping (String, any Error) -> Void = { _, _ in }) {
        self.defaults = defaults
        self.onUnreadable = onUnreadable
    }

    public func reportUnreadable(key: String, error: any Error) {
        onUnreadable(key, error)
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
