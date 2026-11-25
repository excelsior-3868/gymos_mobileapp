import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

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
  List<Offer> get offers => _offers;

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
    ]);
  }

  Future<void> fetchMe() async {
    _isLoadingMe = true;
    _meError = null;
    notifyListeners();
    try {
      final res = await ApiService.get('/portal/me');
      if (res != null) {
        _me = MeResponse.fromJson(res);
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
    await fetchMe();
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
    notifyListeners();
  }
}
