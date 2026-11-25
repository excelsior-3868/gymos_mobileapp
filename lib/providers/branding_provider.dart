import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/config.dart';
import '../services/storage_service.dart';

/// Gym name / logo come from the admin Settings page (served by /portal/branding).
/// The last good response is cached on device so the name and logo still show
/// when the server is briefly unreachable, and failed fetches are retried.
class BrandingProvider extends ChangeNotifier {
  static const _cacheKey = 'gymos_branding_cache';
  static const _fallbackName = 'GymOS';

  BrandingResponse? _branding;
  bool _isLoading = false;
  bool _settled = false; // true once a fetch has finished (success or final failure)
  int _runId = 0;

  BrandingResponse? get branding => _branding;
  bool get isLoading => _isLoading;

  /// Gym name from settings. Blank while the very first load is in flight (so the
  /// placeholder "GymOS" never flashes); falls back only if nothing was ever loaded.
  String get gymName {
    final n = _branding?.gymName.trim() ?? '';
    if (n.isNotEmpty) return n;
    return _settled ? _fallbackName : '';
  }

  String? get logoUrl => AppConfig.mediaUrl(_branding?.logoUrl);
  String? get address => _branding?.gymAddress;
  String? get phone => _branding?.supportPhone;

  BrandingProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadCache();
    await fetchBranding();
  }

  Future<void> _loadCache() async {
    try {
      final raw = await StorageService.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        _branding = BrandingResponse.fromJson(jsonDecode(raw));
        notifyListeners();
      }
    } catch (_) {
      // Ignore a corrupt cache.
    }
  }

  /// Fetches branding, retrying with backoff. Call again after the server URL changes.
  Future<void> fetchBranding() async {
    final run = ++_runId; // a newer call supersedes this one
    _isLoading = true;
    notifyListeners();

    const delays = [Duration(seconds: 2), Duration(seconds: 5), Duration(seconds: 10)];
    for (var attempt = 0; attempt <= delays.length; attempt++) {
      try {
        final res = await ApiService.get('/portal/branding');
        if (run != _runId) return;
        if (res is Map) {
          _branding = BrandingResponse.fromJson(Map<String, dynamic>.from(res));
          await StorageService.setString(_cacheKey, jsonEncode(res));
        }
        break;
      } catch (_) {
        if (run != _runId) return;
        if (attempt == delays.length) break;
        await Future.delayed(delays[attempt]);
        if (run != _runId) return;
      }
    }

    _isLoading = false;
    _settled = true;
    notifyListeners();
  }
}
