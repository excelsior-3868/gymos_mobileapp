import 'dart:async';
import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/config.dart';

class GymProvider extends ChangeNotifier {
  MeResponse? _me;
  AttendanceResponse? _attendance;
  FitnessResponse? _fitness;
  List<ClassSession> _classes = [];
  BillingResponse? _billing;
  List<NotificationItem> _notifications = [];
  ReferralsResponse? _referrals;
  List<PackageInfo> _packages = [];
  List<MembershipView> _membershipHistory = [];
  List<Offer> _offers = [];
  List<FreezeRequest> _freezeRequests = [];
  NoticeboardResponse? _noticeboard;

  bool _isLoadingFreeze = false;
  bool _isLoadingNoticeboard = false;
  String? _freezeError;
  String? _noticeboardError;

  bool _isLoadingMe = false;
  bool _isLoadingAttendance = false;
  bool _isLoadingFitness = false;
  bool _isLoadingClasses = false;
  bool _isLoadingBilling = false;
  bool _isLoadingNotifications = false;
  bool _isLoadingReferrals = false;
  bool _isLoadingPackages = false;
  bool _isLoadingHistory = false;

  String? _meError;
  String? _attendanceError;
  String? _fitnessError;
  String? _classesError;
  String? _billingError;
  String? _notificationsError;
  String? _referralsError;

  MeResponse? get me => _me;
  AttendanceResponse? get attendance => _attendance;
  FitnessResponse? get fitness => _fitness;
  List<ClassSession> get classes => _classes;
  BillingResponse? get billing => _billing;
  List<NotificationItem> get notifications => _notifications;
  ReferralsResponse? get referrals => _referrals;
  List<PackageInfo> get packages => _packages;
  List<MembershipView> get membershipHistory => _membershipHistory;
  /// Only offers still inside their validity period; re-evaluated on every read
  /// so an offer disappears once its end date passes, even without a refetch.
  List<Offer> get offers {
    final now = DateTime.now();
    return _offers.where((o) => o.isValidAt(now)).toList();
  }

  List<FreezeRequest> get freezeRequests => _freezeRequests;
  FreezeAllowance? _freezePolicy;
  FreezeAllowance? get freezePolicy => _freezePolicy;
  bool _isLoadingFreezePolicy = false;
  bool get isLoadingFreezePolicy => _isLoadingFreezePolicy;
  NoticeboardResponse? get noticeboard => _noticeboard;
  bool get isLoadingFreeze => _isLoadingFreeze;
  bool get isLoadingNoticeboard => _isLoadingNoticeboard;
  String? get freezeError => _freezeError;
  String? get noticeboardError => _noticeboardError;

  /// Latest Member of the Month regardless of age (used for Noticeboard history).
  MemberOfTheMonth? get latestMemberOfTheMonth =>
      _noticeboard?.memberOfTheMonth ?? _me?.memberOfTheMonth;

  /// Member of the Month shown in today's spotlight / Home banner — only visible
  /// on the calendar day the announcement was published.
  MemberOfTheMonth? get memberOfTheMonth {
    final m = latestMemberOfTheMonth;
    return (m != null && m.isAnnouncedToday()) ? m : null;
  }

  bool get isLoadingMe => _isLoadingMe;
  bool get isLoadingAttendance => _isLoadingAttendance;
  bool get isLoadingFitness => _isLoadingFitness;
  bool get isLoadingClasses => _isLoadingClasses;
  bool get isLoadingBilling => _isLoadingBilling;
  bool get isLoadingNotifications => _isLoadingNotifications;
  bool get isLoadingReferrals => _isLoadingReferrals;
  bool get isLoadingPackages => _isLoadingPackages;
  bool get isLoadingHistory => _isLoadingHistory;

  String? get meError => _meError;
  String? get attendanceError => _attendanceError;
  String? get fitnessError => _fitnessError;
  String? get classesError => _classesError;
  String? get billingError => _billingError;
  String? get notificationsError => _notificationsError;
  String? get referralsError => _referralsError;

  Future<void> fetchAll() async {
    await Future.wait([
      fetchMe(),
      fetchAttendance(),
      fetchFitness(),
      fetchBilling(),
      fetchNotifications(),
      fetchReferrals(),
      fetchPackages(),
      fetchMembershipHistory(),
      fetchOffers(),
      fetchNoticeboard(),
      fetchFreezeRequests(),
      fetchFreezePolicy(),
    ]);
  }

  /// Refreshes everything a freeze/award/event/notice push can affect.
  Future<void> refreshEngagement() async {
    await Future.wait([
      fetchMe(),
      fetchFreezeRequests(),
      fetchFreezePolicy(),
      fetchNoticeboard(),
      fetchNotifications(),
    ]);
  }

  Future<void>? _noticeboardInFlight;

  /// Concurrent callers (e.g. fetchAll + the login spotlight) share one request.
  Future<void> fetchNoticeboard() {
    return _noticeboardInFlight ??= _fetchNoticeboard().whenComplete(() => _noticeboardInFlight = null);
  }

  Future<void> _fetchNoticeboard() async {
    _isLoadingNoticeboard = true;
    _noticeboardError = null;
    notifyListeners();
    try {
      final res = await ApiService.get('/portal/noticeboard');
      if (res is Map) {
        _noticeboard = NoticeboardResponse.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      _noticeboardError = e.toString();
    } finally {
      _isLoadingNoticeboard = false;
      notifyListeners();
    }
  }

  Future<void> fetchFreezeRequests() async {
    _isLoadingFreeze = true;
    _freezeError = null;
    notifyListeners();
    try {
      final res = await ApiService.get('/portal/freeze-requests');
      if (res is List) {
        _freezeRequests = res
            .whereType<Map>()
            .map((e) => FreezeRequest.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      _freezeError = e.toString();
    } finally {
      _isLoadingFreeze = false;
      notifyListeners();
    }
  }

  Future<void> fetchFreezePolicy() async {
    _isLoadingFreezePolicy = true;
    notifyListeners();
    try {
      final res = await ApiService.get('/portal/freeze-policy');
      final parsed = FreezeAllowance.tryParse(res);
      if (parsed != null) {
        _freezePolicy = parsed;
      }
    } catch (_) {
      // Keep last known policy on transient errors.
    } finally {
      _isLoadingFreezePolicy = false;
      notifyListeners();
    }
  }

  /// Throws [ApiException] with the backend's message on validation errors.
  Future<void> submitFreezeRequest({
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    final trimmed = reason?.trim() ?? '';
    await ApiService.post('/portal/freeze-requests', body: {
      'startDate': startDate,
      'endDate': endDate,
      if (trimmed.isNotEmpty) 'reason': trimmed,
    });
    await Future.wait([fetchFreezeRequests(), fetchFreezePolicy(), fetchMe()]);
  }

  Future<void> cancelFreezeRequest(String id) async {
    await ApiService.delete('/portal/freeze-requests/$id');
    await Future.wait([fetchFreezeRequests(), fetchFreezePolicy(), fetchMe()]);
  }

  Future<void> _precacheAvatar(String? uri, {bool forceReload = false}) async {
    final url = AppConfig.mediaUrl(uri);
    if (url == null || url.isEmpty) return;
    try {
      final provider = NetworkImage(url);
      if (forceReload) {
        await provider.evict();
      }
      final completer = Completer<void>();
      final stream = provider.resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (_, _) {
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.complete();
        },
        onError: (_, _) {
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.complete();
        },
      );
      stream.addListener(listener);
      await completer.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          stream.removeListener(listener);
        },
      );
    } catch (_) {
      // Never block home screen rendering if avatar prefetch fails.
    }
  }

  Future<void> fetchMe({bool forceAvatarReload = false}) async {
    _isLoadingMe = true;
    _meError = null;
    notifyListeners();
    try {
      final res = await ApiService.get('/portal/me');
      if (res != null) {
        final nextMe = MeResponse.fromJson(res);
        final prevPhoto = _me?.member.photoUrl;
        final nextPhoto = nextMe.member.photoUrl;
        // Pre-load the avatar into Flutter's ImageCache before revealing the home page
        // so it renders on the very first frame alongside the rest of the header.
        if (nextPhoto != null &&
            nextPhoto.isNotEmpty &&
            (_me == null || nextPhoto != prevPhoto || forceAvatarReload)) {
          await _precacheAvatar(nextPhoto, forceReload: forceAvatarReload);
        }
        _me = nextMe;
      }
    } catch (e) {
      _meError = e.toString();
    } finally {
      _isLoadingMe = false;
      notifyListeners();
    }
  }

  Future<void> fetchAttendance() async {
    _isLoadingAttendance = true;
    _attendanceError = null;
    notifyListeners();
    try {
      final res = await ApiService.get('/portal/attendance');
      if (res != null) {
        _attendance = AttendanceResponse.fromJson(res);
      }
    } catch (e) {
      _attendanceError = e.toString();
    } finally {
      _isLoadingAttendance = false;
      notifyListeners();
    }
  }

  Future<void> fetchFitness() async {
    _isLoadingFitness = true;
    _fitnessError = null;
    notifyListeners();
    try {
      final res = await ApiService.get('/portal/fitness');
      if (res != null) {
        _fitness = FitnessResponse.fromJson(res);
      }
    } catch (e) {
      _fitnessError = e.toString();
    } finally {
      _isLoadingFitness = false;
      notifyListeners();
    }
  }

  Future<void> fetchClasses() async {
    _isLoadingClasses = true;
    _classesError = null;
    notifyListeners();
    try {
      final res = await ApiService.get('/portal/classes');
      if (res is List) {
        _classes = res.map((e) => ClassSession.fromJson(e)).toList();
      }
    } catch (e) {
      _classesError = e.toString();
    } finally {
      _isLoadingClasses = false;
      notifyListeners();
    }
  }

  Future<void> fetchBilling() async {
    _isLoadingBilling = true;
    _billingError = null;
    notifyListeners();
    try {
      final res = await ApiService.get('/portal/billing');
      if (res != null) {
        _billing = BillingResponse.fromJson(res);
      }
    } catch (e) {
      _billingError = e.toString();
    } finally {
      _isLoadingBilling = false;
      notifyListeners();
    }
  }

  Future<void> fetchNotifications() async {
    _isLoadingNotifications = true;
    _notificationsError = null;
    notifyListeners();
    try {
      final res = await ApiService.get('/portal/notifications');
      if (res is List) {
        _notifications = res.map((e) => NotificationItem.fromJson(e)).toList();
      }
    } catch (e) {
      _notificationsError = e.toString();
    } finally {
      _isLoadingNotifications = false;
      notifyListeners();
    }
  }

  Future<void> fetchReferrals() async {
    _isLoadingReferrals = true;
    _referralsError = null;
    notifyListeners();
    try {
      final res = await ApiService.get('/portal/referrals');
      if (res != null) {
        _referrals = ReferralsResponse.fromJson(res);
      }
    } catch (e) {
      _referralsError = e.toString();
    } finally {
      _isLoadingReferrals = false;
      notifyListeners();
    }
  }

  Future<void> fetchPackages() async {
    _isLoadingPackages = true;
    notifyListeners();
    try {
      final res = await ApiService.get('/portal/packages');
      if (res is List) {
        _packages = res.map((e) => PackageInfo.fromJson(e)).toList();
      }
    } catch (_) {
    } finally {
      _isLoadingPackages = false;
      notifyListeners();
    }
  }

  Future<void> fetchOffers() async {
    try {
      final res = await ApiService.get('/portal/offers');
      if (res is Map && res['offers'] is List) {
        _offers = (res['offers'] as List)
            .map((e) => Offer.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {
      // Offers are optional; on failure keep whatever was loaded before.
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchMembershipHistory() async {
    _isLoadingHistory = true;
    notifyListeners();
    try {
      final res = await ApiService.get('/portal/membership/history');
      if (res is List) {
        _membershipHistory = res.map((e) => MembershipView.fromJson(e)).toList();
      }
    } catch (_) {
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> bookClass(int scheduleId, String date) async {
    await ApiService.post('/portal/classes/book', body: {
      'scheduleId': scheduleId,
      'bookingDate': date,
    });
    await fetchClasses();
  }

  Future<void> cancelBooking(int bookingId) async {
    await ApiService.delete('/portal/classes/bookings/$bookingId');
    await fetchClasses();
  }

  Future<void> markNotificationRead(dynamic id) async {
    await ApiService.put('/portal/notifications/$id/read');
    await Future.wait([fetchNotifications(), fetchMe()]);
  }

  Future<void> markAllNotificationsRead() async {
    await ApiService.put('/portal/notifications/all/read');
    await Future.wait([fetchNotifications(), fetchMe()]);
  }

  Future<void> uploadProfilePhoto(String filePath, {String mime = 'image/jpeg'}) async {
    await ApiService.uploadFile('/portal/me/photo', 'photo', filePath, mime: mime);
    await fetchMe(forceAvatarReload: true);
  }

  Future<void> removeProfilePhoto() async {
    await ApiService.delete('/portal/me/photo');
    await fetchMe();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await ApiService.put('/portal/me', body: data);
    await fetchMe();
  }

  void clearData() {
    _me = null;
    _attendance = null;
    _fitness = null;
    _classes = [];
    _billing = null;
    _notifications = [];
    _referrals = null;
    _packages = [];
    _membershipHistory = [];
    _offers = [];
    _freezeRequests = [];
    _freezePolicy = null;
    _noticeboard = null;
    notifyListeners();
  }
}
