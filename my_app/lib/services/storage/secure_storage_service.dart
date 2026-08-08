import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores sensitive data (API keys) using platform secure storage.
class SecureStorageService {
  static const _apiKeyKey = 'llm_api_key';

  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> readApiKey() => _storage.read(key: _apiKeyKey);

  Future<void> writeApiKey(String value) =>
      _storage.write(key: _apiKeyKey, value: value);

  Future<void> deleteApiKey() => _storage.delete(key: _apiKeyKey);
}
