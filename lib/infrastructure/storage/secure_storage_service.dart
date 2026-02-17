import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // ignore: unused_field
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.unlocked,
      synchronizable: false,
    ),
  );

  static const _keyPrefix = 'gladden_key_';

  Future<void> saveApiKey(String providerId, String apiKey) async {
    try {
      print('SecureStorage: Writing key for $providerId...');
      await _storage.write(key: '$_keyPrefix$providerId', value: apiKey);
      print('SecureStorage: Write successful for $providerId');
    } catch (e) {
      print('SecureStorage: Error writing key for $providerId: $e');
      rethrow;
    }
  }

  Future<String?> getApiKey(String providerId) async {
    try {
      final key = await _storage.read(key: '$_keyPrefix$providerId');
      print('SecureStorage: Read key for $providerId: ${key != null ? 'Found' : 'Not Found'}');
      return key;
    } catch (e) {
      print('SecureStorage: Error reading key for $providerId: $e');
      return null;
    }
  }

  Future<void> deleteApiKey(String providerId) async {
    await _storage.delete(key: '$_keyPrefix$providerId');
  }

  Future<Map<String, String>> getAllKeys() async {
    try {
      print('SecureStorage: Reading all keys...');
      final all = await _storage.readAll();
      print('SecureStorage: Read all successful. Count: ${all.length}');
      
      final filtered = Map.fromEntries(
        all.entries
            .where((e) => e.key.startsWith(_keyPrefix))
            .map((e) => MapEntry(e.key.replaceFirst(_keyPrefix, ''), e.value)),
      );
      print('SecureStorage: Filtered keys count: ${filtered.length}');
      return filtered;
    } catch (e) {
      print('SecureStorage: Error reading all keys: $e');
      rethrow;
    }
  }
}
