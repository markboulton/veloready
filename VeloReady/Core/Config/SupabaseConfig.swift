import Foundation

/// Supabase configuration for VeloReady
/// Manages authentication and API communication with the backend
enum SupabaseConfig {
    /// Supabase project URL
    static let url = "https://your-project.supabase.co"
    
    /// Supabase anonymous key (public, safe to embed in app)
    static let anonKey = "your-anon-key-here"
    
    /// Check if Supabase is configured
    static var isConfigured: Bool {
        return !url.contains("your-project") && !anonKey.contains("your-anon-key")
    }
}
