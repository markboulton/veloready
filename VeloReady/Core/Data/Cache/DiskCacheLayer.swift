import Foundation

/// Disk-based cache layer with size-based storage strategy
///
/// **Purpose:**
/// Persistent cache for data that survives app restarts. Automatically chooses
/// optimal storage mechanism based on data size.
///
/// **Storage Strategy:**
/// - Small data (<50KB): UserDefaults (fast, simple)
/// - Large data (≥50KB): FileManager (scalable, no size limits)
///
/// **Features:**
/// - Automatic storage selection
/// - Persistent across app restarts
/// - Uses CacheEncodingHelper for serialization
/// - Metadata tracking (timestamps, sizes)
///
/// **Performance:**
/// - UserDefaults: ~1ms read/write (plist-based)
/// - FileManager: ~5-10ms read/write (JSON files)
/// - Both are async to avoid blocking
actor DiskCacheLayer: CacheLayer {
    
    // MARK: - Configuration
    
    private let userDefaultsKey = "DiskCacheLayer.Cache"
    private let metadataKey = "DiskCacheLayer.Metadata"
    private let cacheDirectory: URL
    private let sizeThreshold = 50 * 1024 // 50KB threshold
    
    // MARK: - Initialization
    
    init() {
        // Create cache directory
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cachesDirectory.appendingPathComponent("VeloReadyCache", isDirectory: true)
        
        // Ensure directory exists
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - CacheLayer Protocol
    
    func get<T: Sendable>(key: String, ttl: TimeInterval) async -> T? {
        // Get raw data first
        var data: Data?
        var source: String?

        // Try UserDefaults first (fast path)
        if let metadata = getMetadata(key: key), metadata.isValid(ttl: ttl) {
            if let cache = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String],
               let base64String = cache[key],
               let decoded = Data(base64Encoded: base64String) {
                data = decoded
                source = "UserDefaults"
            }
        }

        // Try FileManager if not found in UserDefaults
        if data == nil {
            let fileURL = cacheDirectory.appendingPathComponent(key.sanitizedForFilename())
            if FileManager.default.fileExists(atPath: fileURL.path),
               let timestamp = getFileTimestamp(key: key),
               Date().timeIntervalSince(timestamp) < ttl,
               let fileData = try? Data(contentsOf: fileURL) {
                data = fileData
                source = "FileManager"
            }
        }

        // If we have data, try to decode it
        if let data = data, let source = source {
            // Try to decode as versioned entry first (new format)
            if let versionedEntry = try? JSONDecoder().decode(VersionedCacheEntry.self, from: data) {
                // Check version compatibility
                if !versionedEntry.isCompatible {
                    Logger.warning("⚠️ [CACHE VERSION MISMATCH] Key: \(key) - Cache version \(versionedEntry.version), current version \(VersionedCacheEntry.currentVersion)")
                    Logger.warning("⚠️ [CACHE VERSION] Invalidating old cache entry - This triggers an API refetch")
                    await remove(key: key)
                    return nil
                }

                // Version is compatible, decode the inner data
                let innerData = versionedEntry.data
                let expectedType = String(describing: T.self)

                // Check if data type matches (helps debugging)
                if versionedEntry.dataType != expectedType {
                    Logger.trace("💾 [DiskCache] Type info: stored=\(versionedEntry.dataType), requested=\(expectedType)")
                }

                // Decode based on expected type
                // T must be Decodable to use JSONDecoder, but protocol only requires Sendable
                // Check at runtime if T conforms to Decodable
                if let decodableType = T.self as? any Decodable.Type {
                    if let decoded = try? JSONDecoder().decode(decodableType, from: innerData) as? T {
                        Logger.debug("💾 [DiskCache HIT] \(key) (source: \(source), version: \(versionedEntry.version))")
                        return decoded
                    }
                }

                // Version matched but decode failed - likely a type mismatch
                Logger.warning("⚠️ [CACHE DECODE FAILURE] Key: \(key) - Type mismatch. Stored: \(versionedEntry.dataType), Requested: \(expectedType)")
                Logger.warning("⚠️ [CACHE DECODE] This triggers an API refetch. Source: \(source), Size: \(innerData.count) bytes")
                await remove(key: key)
                return nil
            }

            // Fallback: Try to decode as unversioned data (legacy format)
            // This maintains backward compatibility with old cache entries
            Logger.trace("💾 [DiskCache] Attempting legacy decode for \(key)")

            // Try common types in order of likelihood
            if let decoded = try? JSONDecoder().decode([Activity].self, from: data) as? T {
                Logger.debug("💾 [DiskCache HIT] \(key) (source: \(source), legacy format)")
                return decoded
            }

            if let decoded = try? JSONDecoder().decode(Activity.self, from: data) as? T {
                Logger.debug("💾 [DiskCache HIT] \(key) (source: \(source), legacy format)")
                return decoded
            }

            if let decoded = try? JSONDecoder().decode([StravaActivity].self, from: data) as? T {
                Logger.debug("💾 [DiskCache HIT] \(key) (source: \(source), legacy format)")
                return decoded
            }

            if let decoded = try? JSONDecoder().decode(Double.self, from: data) as? T {
                Logger.debug("💾 [DiskCache HIT] \(key) (source: \(source), legacy format)")
                return decoded
            }

            if let decoded = try? JSONDecoder().decode(Int.self, from: data) as? T {
                Logger.debug("💾 [DiskCache HIT] \(key) (source: \(source), legacy format)")
                return decoded
            }

            if let decoded = try? JSONDecoder().decode(String.self, from: data) as? T {
                Logger.debug("💾 [DiskCache HIT] \(key) (source: \(source), legacy format)")
                return decoded
            }

            // Both versioned and legacy decode failed
            Logger.warning("⚠️ [CACHE DECODE FAILURE] Key: \(key) - Could not decode as versioned or legacy format")
            Logger.warning("⚠️ [CACHE DECODE] This triggers an API refetch. Source: \(source), Size: \(data.count) bytes")
            await remove(key: key)
        }

        // Don't log individual layer misses - CacheOrchestrator logs final result
        return nil
    }
    
    func set<T: Sendable>(key: String, value: T, cachedAt: Date) async {
        do {
            // Encode value
            guard let encodable = value as? Encodable else {
                Logger.warning("⚠️ [DiskCache] Value for \(key) is not Encodable")
                return
            }

            let data = try await CacheEncodingHelper.shared.encode(encodable)

            // Wrap in versioned entry to track type and schema version
            let dataType = String(describing: type(of: value))
            let versionedEntry = VersionedCacheEntry(
                dataType: dataType,
                cachedAt: cachedAt,
                data: data
            )

            // Encode the versioned wrapper
            let wrappedData = try JSONEncoder().encode(versionedEntry)

            // Choose storage based on size (check wrapped size)
            if wrappedData.count < sizeThreshold {
                try await setInUserDefaults(key: key, data: wrappedData, cachedAt: cachedAt)
                Logger.debug("💾 [DiskCache SET] \(key) → UserDefaults (\(wrappedData.count) bytes, type: \(dataType), v\(VersionedCacheEntry.currentVersion))")
            } else {
                try await setInFileManager(key: key, data: wrappedData, cachedAt: cachedAt)
                Logger.debug("💾 [DiskCache SET] \(key) → FileManager (\(wrappedData.count / 1024)KB, type: \(dataType), v\(VersionedCacheEntry.currentVersion))")
            }
        } catch {
            Logger.error("❌ [DiskCache] Failed to set \(key): \(error)")
        }
    }
    
    func remove(key: String) async {
        // Remove from both storage mechanisms
        await removeFromUserDefaults(key: key)
        await removeFromFileManager(key: key)
        Logger.debug("🗑️ [DiskCache REMOVE] \(key)")
    }
    
    func removeMatching(pattern: String) async {
        // Remove from UserDefaults
        await removeFromUserDefaultsMatching(pattern: pattern)
        
        // Remove from FileManager
        await removeFromFileManagerMatching(pattern: pattern)
        
        Logger.debug("🗑️ [DiskCache CLEAR] Pattern: \(pattern)")
    }
    
    func contains(key: String, ttl: TimeInterval) async -> Bool {
        // Check UserDefaults
        if let metadata = getMetadata(key: key) {
            let age = Date().timeIntervalSince(metadata.cachedAt)
            if age < ttl {
                return true
            }
        }
        
        // Check FileManager
        if fileExists(key: key) {
            if let timestamp = getFileTimestamp(key: key) {
                let age = Date().timeIntervalSince(timestamp)
                return age < ttl
            }
        }
        
        return false
    }
    
    // MARK: - UserDefaults Storage
    
    
    private func setInUserDefaults(key: String, data: Data, cachedAt: Date) async throws {
        // Load existing cache
        var cache = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String] ?? [:]
        
        // Store as base64
        cache[key] = data.base64EncodedString()
        UserDefaults.standard.set(cache, forKey: userDefaultsKey)
        
        // Update metadata
        setMetadata(key: key, cachedAt: cachedAt, size: data.count)
    }
    
    private func removeFromUserDefaults(key: String) async {
        var cache = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String] ?? [:]
        cache.removeValue(forKey: key)
        UserDefaults.standard.set(cache, forKey: userDefaultsKey)
        
        removeMetadata(key: key)
    }
    
    private func removeFromUserDefaultsMatching(pattern: String) async {
        var cache = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String] ?? [:]
        
        if pattern == "*" {
            cache.removeAll()
            UserDefaults.standard.set(cache, forKey: userDefaultsKey)
            UserDefaults.standard.removeObject(forKey: metadataKey)
            return
        }
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let keysToRemove = cache.keys.filter { key in
            let range = NSRange(key.startIndex..., in: key)
            return regex.firstMatch(in: key, range: range) != nil
        }
        
        for key in keysToRemove {
            cache.removeValue(forKey: key)
            removeMetadata(key: key)
        }
        
        UserDefaults.standard.set(cache, forKey: userDefaultsKey)
    }
    
    // MARK: - FileManager Storage
    
    
    private func setInFileManager(key: String, data: Data, cachedAt: Date) async throws {
        let fileURL = cacheDirectory.appendingPathComponent(key.sanitizedForFilename())
        try data.write(to: fileURL)
        
        // Update metadata
        setMetadata(key: key, cachedAt: cachedAt, size: data.count)
    }
    
    private func removeFromFileManager(key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent(key.sanitizedForFilename())
        try? FileManager.default.removeItem(at: fileURL)
        
        removeMetadata(key: key)
    }
    
    private func removeFromFileManagerMatching(pattern: String) async {
        guard let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        if pattern == "*" {
            for fileURL in files {
                try? FileManager.default.removeItem(at: fileURL)
            }
            return
        }
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        for fileURL in files {
            let filename = fileURL.lastPathComponent
            let range = NSRange(filename.startIndex..., in: filename)
            if regex.firstMatch(in: filename, range: range) != nil {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
    
    private func fileExists(key: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent(key.sanitizedForFilename())
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    private func getFileTimestamp(key: String) -> Date? {
        return getMetadata(key: key)?.cachedAt
    }
    
    // MARK: - Metadata Management
    
    private func getMetadata(key: String) -> CacheMetadata? {
        guard let metadata = UserDefaults.standard.dictionary(forKey: metadataKey) as? [String: [String: Any]],
              let entry = metadata[key],
              let timestamp = entry["cachedAt"] as? TimeInterval else {
            return nil
        }
        
        let size = entry["size"] as? Int ?? 0
        return CacheMetadata(cachedAt: Date(timeIntervalSince1970: timestamp), size: size)
    }
    
    private func setMetadata(key: String, cachedAt: Date, size: Int) {
        var metadata = UserDefaults.standard.dictionary(forKey: metadataKey) as? [String: [String: Any]] ?? [:]
        metadata[key] = [
            "cachedAt": cachedAt.timeIntervalSince1970,
            "size": size
        ]
        UserDefaults.standard.set(metadata, forKey: metadataKey)
    }
    
    private func removeMetadata(key: String) {
        var metadata = UserDefaults.standard.dictionary(forKey: metadataKey) as? [String: [String: Any]] ?? [:]
        metadata.removeValue(forKey: key)
        UserDefaults.standard.set(metadata, forKey: metadataKey)
    }
}

// MARK: - Supporting Types

private struct CacheMetadata {
    let cachedAt: Date
    let size: Int
    let version: Int = 1  // Version for future format changes
    
    func isValid(ttl: TimeInterval) -> Bool {
        return Date().timeIntervalSince(cachedAt) < ttl
    }
}

// MARK: - String Extensions

private extension String {
    /// Sanitize string for use as filename
    /// Replaces unsafe characters with underscores
    func sanitizedForFilename() -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}
