import Foundation

/// Versioned wrapper for cache entries to prevent decode failures
///
/// **Purpose:**
/// Tracks data type and version to gracefully handle cache invalidation when models change.
/// Prevents silent decode failures that trigger unnecessary API refetches.
///
/// **Problem Solved:**
/// Without versioning, when we change Activity or StravaActivity models, cached data
/// becomes invalid but we don't know until decode fails. This triggers API refetches
/// and wastes rate limits.
///
/// **Solution:**
/// Wrap cached data with metadata:
/// - version: Schema version (increment when models change)
/// - dataType: Type name (e.g., "[Activity]", "Double")
/// - cachedAt: Timestamp for TTL checking
/// - data: The actual encoded value
///
/// **Usage:**
/// ```swift
/// // Storing
/// let entry = VersionedCacheEntry(
///     version: 1,
///     dataType: String(describing: type(of: value)),
///     cachedAt: Date(),
///     data: encodedData
/// )
///
/// // Loading
/// if entry.version != VersionedCacheEntry.currentVersion {
///     // Invalidate old version
///     return nil
/// }
/// ```
struct VersionedCacheEntry: Codable {
    /// Current cache schema version - increment when Activity/StravaActivity models change
    /// Version history:
    /// - v1: Initial implementation with type tracking
    static let currentVersion: Int = 1

    /// Schema version this entry was created with
    let version: Int

    /// Type name of the cached value (e.g., "[Activity]", "Double", "String")
    /// Used to verify we're decoding to the correct type
    let dataType: String

    /// When this entry was cached (for TTL checking)
    let cachedAt: Date

    /// The actual encoded data
    let data: Data

    /// Check if this entry is compatible with current schema version
    var isCompatible: Bool {
        return version == Self.currentVersion
    }

    /// Check if this entry is still valid given a TTL
    func isValid(ttl: TimeInterval) -> Bool {
        let age = Date().timeIntervalSince(cachedAt)
        return age < ttl && isCompatible
    }

    /// Create a versioned cache entry
    /// - Parameters:
    ///   - version: Schema version (use VersionedCacheEntry.currentVersion)
    ///   - dataType: Type name from String(describing:)
    ///   - cachedAt: Timestamp when data was cached
    ///   - data: Encoded data
    init(version: Int = currentVersion, dataType: String, cachedAt: Date, data: Data) {
        self.version = version
        self.dataType = dataType
        self.cachedAt = cachedAt
        self.data = data
    }
}
