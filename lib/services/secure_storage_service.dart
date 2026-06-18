import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for managing JWT and refresh tokens
/// 
/// Uses platform-specific keychains:
/// - iOS: Keychain
/// - Android: Android Keystore
/// 
/// Requirements: 1.6, 33.2
class SecureStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _deviceTokenKey = 'device_token';
  
  /// Flutter Secure Storage instance with default options
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  
  /// Singleton instance
  static final SecureStorageService _instance = SecureStorageService._internal();
  
  /// Factory constructor returns singleton instance
  factory SecureStorageService() {
    return _instance;
  }
  
  /// Private constructor for singleton
  SecureStorageService._internal();
  
  // ============================================================================
  // Token Storage Methods
  // ============================================================================
  
  /// Save access token (JWT) to secure storage
  /// 
  /// Requirements: 1.6
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }
  
  /// Save refresh token to secure storage
  /// 
  /// Requirements: 1.6
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }
  
  /// Save token expiry timestamp
  /// 
  /// Stores the DateTime when the access token expires
  Future<void> saveTokenExpiry(DateTime expiryTime) async {
    await _storage.write(
      key: _tokenExpiryKey,
      value: expiryTime.toIso8601String(),
    );
  }
  
  /// Get access token from secure storage
  /// 
  /// Returns null if no token is stored
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }
  
  /// Get refresh token from secure storage
  /// 
  /// Returns null if no token is stored
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }
  
  /// Get token expiry timestamp
  /// 
  /// Returns null if no expiry is stored
  Future<DateTime?> getTokenExpiry() async {
    final expiryString = await _storage.read(key: _tokenExpiryKey);
    if (expiryString == null) return null;
    return DateTime.parse(expiryString);
  }
  
  /// Check if access token exists
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
  
  /// Check if access token is expired or about to expire
  /// 
  /// Returns true if token expires within the next 5 minutes
  /// or if expiry time is not available
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    
    // Consider token expired if it expires within 5 minutes
    final now = DateTime.now();
    final expiryThreshold = now.add(const Duration(minutes: 5));
    
    return expiry.isBefore(expiryThreshold);
  }
  
  /// Clear all tokens from secure storage
  /// 
  /// Used during logout or when token refresh fails
  /// Requirements: 1.7
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _tokenExpiryKey),
    ]);
  }
  
  // ============================================================================
  // Device Token Storage Methods
  // ============================================================================
  
  /// Save device token (FCM/APNs) to secure storage
  /// 
  /// Used to detect token changes for re-registration
  /// Requirements: 37.5
  Future<void> saveDeviceToken(String token) async {
    await _storage.write(key: _deviceTokenKey, value: token);
  }
  
  /// Get device token from secure storage
  /// 
  /// Returns null if no token is stored
  Future<String?> getDeviceToken() async {
    return await _storage.read(key: _deviceTokenKey);
  }
  
  /// Check if device token has changed
  /// 
  /// Compares current token with stored token
  /// Returns true if tokens differ or no stored token exists
  Future<bool> hasDeviceTokenChanged(String currentToken) async {
    final storedToken = await getDeviceToken();
    return storedToken != currentToken;
  }
  
  /// Clear device token from secure storage
  /// 
  /// Used during logout to remove device token
  /// Requirements: 37.6
  Future<void> clearDeviceToken() async {
    await _storage.delete(key: _deviceTokenKey);
  }
  
  /// Clear all secure storage data
  /// 
  /// Use with caution - removes all data from secure storage
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
