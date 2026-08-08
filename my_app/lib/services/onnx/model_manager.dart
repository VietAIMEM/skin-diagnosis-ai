import 'package:flutter/services.dart';
import 'package:onnxruntime_v2/onnxruntime_v2.dart';

import 'onnx_service.dart';

/// Manages loading and caching of the two ONNX models.
class ModelManager {
  final Map<String, OnnxSession> _sessions = {};
  bool _envInitialized = false;

  Future<void> _ensureEnv() async {
    if (_envInitialized) return;
    OrtEnv.instance.init();
    _envInitialized = true;
  }

  /// Loads the model with [assetPath] and caches the session.
  Future<OnnxSession> getSession(
    String assetPath, {
    required String modelId,
  }) async {
    final cached = _sessions[assetPath];
    if (cached != null) return cached;
    await _ensureEnv();
    final session = await _createSession(assetPath, modelId);
    _sessions[assetPath] = session;
    return session;
  }

  Future<OnnxSession> _createSession(String assetPath, String modelId) async {
    final bytes = await rootBundle.load(assetPath);
    final modelBytes = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    return OnnxSession.create(
      modelAssetPath: assetPath,
      modelId: modelId,
      modelBytes: modelBytes,
    );
  }

  /// Returns true when the requested model session is ready.
  bool isLoaded(String assetPath) => _sessions.containsKey(assetPath);

  /// Releases all sessions.
  Future<void> disposeAll() async {
    for (final s in _sessions.values) {
      s.release();
    }
    _sessions.clear();
  }
}
