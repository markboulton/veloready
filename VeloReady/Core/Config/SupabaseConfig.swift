import Foundation

/// Supabase configuration for VeloReady
/// 
/// Note: The iOS app doesn't directly communicate with Supabase.
/// All Supabase operations (user creation, token generation) are handled
/// by the backend during OAuth. The app only stores and uses the JWT tokens
/// returned by the backend.
enum SupabaseConfig {
    // No configuration needed - backend handles all Supabase operations
}
