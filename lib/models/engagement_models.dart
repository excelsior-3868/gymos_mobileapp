// Models for membership freeze, Member of the Month and the noticeboard.

int _asInt(dynamic v) => v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

Map<String, dynamic>? _asMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : null;

const Duration _nepalOffset = Duration(hours: 5, minutes: 45);

/// Returns true if [rawTimestamp] falls on the same Nepal (UTC+5:45) calendar day as [now].
bool _isSameNepalDay(String rawTimestamp, [DateTime? now]) {
  final parsed = DateTime.tryParse(rawTimestamp);
  if (parsed == null) return false;
  final itemNpt = parsed.toUtc().add(_nepalOffset);
  final todayNpt = (now ?? DateTime.now()).toUtc().add(_nepalOffset);
  return itemNpt.year == todayNpt.year &&
      itemNpt.month == todayNpt.month &&
      itemNpt.day == todayNpt.day;
}

class FreezeRequest {
  final String id;
  final String memberId;
  final String membershipId;
  final String startDate;
  final String endDate;
  final int freezeDays;
  final String status;
  final String createdAt;
  final int? actualFreezeDays;
  final String? reason;
  final String? originalEndDate;
  final String? extendedEndDate;
  final String? actualEndDate;
  final String? reviewNote;
  final String? reviewedAt;

  const FreezeRequest({
    required this.id,
    required this.memberId,
    required this.membershipId,
    required this.startDate,
    required this.endDate,
    required this.freezeDays,
    required this.status,
    required this.createdAt,
    this.actualFreezeDays,
    this.reason,
    this.originalEndDate,
    this.extendedEndDate,
    this.actualEndDate,
    this.reviewNote,
    this.reviewedAt,
  });

  factory FreezeRequest.fromJson(Map<String, dynamic> json) {
    return FreezeRequest(
      id: json['id']?.toString() ?? '',
      memberId: json['memberId']?.toString() ?? '',
      membershipId: json['membershipId']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      freezeDays: _asInt(json['freezeDays']),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt']?.toString() ?? '',
      actualFreezeDays: json['actualFreezeDays'] == null ? null : _asInt(json['actualFreezeDays']),
      reason: json['reason']?.toString(),
      originalEndDate: json['originalEndDate']?.toString(),
      extendedEndDate: json['extendedEndDate']?.toString(),
      actualEndDate: json['actualEndDate']?.toString(),
      reviewNote: json['reviewNote']?.toString(),
      reviewedAt: json['reviewedAt']?.toString(),
    );
  }

  static FreezeRequest? tryParse(dynamic v) {
    final m = _asMap(v);
    return m == null ? null : FreezeRequest.fromJson(m);
  }
}

class FreezeAllowance {
  final bool enabled;
  final String membershipId;
  final String membershipStatus;
  final String membershipEndDate;
  final String packageName;
  final String billingCycle;
  final String cycleLabel;
  final int maxDays;
  final int usedDays;
  final int remainingDays;
  final bool canFreeze;

  const FreezeAllowance({
    required this.enabled,
    required this.membershipId,
    required this.membershipStatus,
    required this.membershipEndDate,
    required this.packageName,
    required this.billingCycle,
    required this.cycleLabel,
    required this.maxDays,
    required this.usedDays,
    required this.remainingDays,
    required this.canFreeze,
  });

  factory FreezeAllowance.fromJson(Map<String, dynamic> json) {
    final src = _asMap(json['allowance']) ?? json;
    return FreezeAllowance(
      enabled: src['enabled'] != false,
      membershipId: src['membershipId']?.toString() ?? '',
      membershipStatus: src['membershipStatus']?.toString() ?? '',
      membershipEndDate: src['membershipEndDate']?.toString() ?? '',
      packageName: src['packageName']?.toString() ?? '',
      billingCycle: src['billingCycle']?.toString() ?? '',
      cycleLabel: src['cycleLabel']?.toString() ?? '',
      maxDays: _asInt(src['maxDays']),
      usedDays: _asInt(src['usedDays']),
      remainingDays: _asInt(src['remainingDays']),
      canFreeze: src['canFreeze'] == true,
    );
  }

  static FreezeAllowance? tryParse(dynamic v) {
    final m = _asMap(v);
    if (m == null) return null;
    final inner = _asMap(m['allowance']) ?? m;
    if (inner.isEmpty) return null;
    return FreezeAllowance.fromJson(inner);
  }
}

class MotmWinner {
  final String id;
  final String fullName;
  final String registrationNumber;
  final String? photoUrl;

  const MotmWinner({
    required this.id,
    required this.fullName,
    required this.registrationNumber,
    this.photoUrl,
  });

  factory MotmWinner.fromJson(Map<String, dynamic> json) {
    return MotmWinner(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      registrationNumber: json['registrationNumber']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString(),
    );
  }
}

class MemberOfTheMonth {
  final String id;
  final String month;
  final String monthLabel;
  final String title;
  final String giftHamper;
  final String publishedAt;
  final String? message;
  final int attendanceDays;
  final int referralCount;
  final int disciplineScore;
  final bool onTimeRenewal;
  final bool hamperDelivered;
  final bool isCurrentMember;
  final MotmWinner winner;

  const MemberOfTheMonth({
    required this.id,
    required this.month,
    required this.monthLabel,
    required this.title,
    required this.giftHamper,
    required this.publishedAt,
    this.message,
    required this.attendanceDays,
    required this.referralCount,
    required this.disciplineScore,
    required this.onTimeRenewal,
    required this.hamperDelivered,
    required this.isCurrentMember,
    required this.winner,
  });

  factory MemberOfTheMonth.fromJson(Map<String, dynamic> json) {
    return MemberOfTheMonth(
      id: json['id']?.toString() ?? '',
      month: json['month']?.toString() ?? '',
      monthLabel: json['monthLabel']?.toString() ?? '',
      title: json['title']?.toString() ?? 'FitMaxim Member of the Month',
      giftHamper: json['giftHamper']?.toString() ?? '',
      publishedAt: json['publishedAt']?.toString() ?? '',
      message: json['message']?.toString(),
      attendanceDays: _asInt(json['attendanceDays']),
      referralCount: _asInt(json['referralCount']),
      disciplineScore: _asInt(json['disciplineScore']),
      onTimeRenewal: json['onTimeRenewal'] == true,
      hamperDelivered: json['hamperDelivered'] == true,
      isCurrentMember: json['isCurrentMember'] == true,
      winner: MotmWinner.fromJson(_asMap(json['winner']) ?? {}),
    );
  }

  /// True only on the calendar day (Nepal time) this announcement was published.
  bool isAnnouncedToday([DateTime? now]) => _isSameNepalDay(publishedAt, now);

  /// Alias kept for callers checking whether the announcement is still for today.
  bool isWithinDay([DateTime? now]) => isAnnouncedToday(now);

  static MemberOfTheMonth? tryParse(dynamic v) {
    final m = _asMap(v);
    return m == null ? null : MemberOfTheMonth.fromJson(m);
  }
}

class NoticeItem {
  final String id;
  final String title;
  final String content;
  final String category;
  final String createdAt;
  final String? eventDate;
  final String? eventTime;
  final String? location;
  final String? expiresAt;
  final bool isPinned;

  const NoticeItem({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    this.eventDate,
    this.eventTime,
    this.location,
    this.expiresAt,
    this.isPinned = false,
  });

  factory NoticeItem.fromJson(Map<String, dynamic> json) {
    return NoticeItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      category: json['category']?.toString() ?? 'notice',
      createdAt: json['createdAt']?.toString() ?? '',
      eventDate: json['eventDate']?.toString(),
      eventTime: json['eventTime']?.toString(),
      location: json['location']?.toString(),
      expiresAt: json['expiresAt']?.toString(),
      isPinned: json['isPinned'] == true,
    );
  }

  /// True only on the calendar day (Nepal time) this notice was posted.
  bool isAnnouncedToday([DateTime? now]) => _isSameNepalDay(createdAt, now);
}

class NoticeboardResponse {
  final List<NoticeItem> notices;
  final List<NoticeItem> upcomingEvents;
  final MemberOfTheMonth? memberOfTheMonth;

  const NoticeboardResponse({
    this.notices = const [],
    this.upcomingEvents = const [],
    this.memberOfTheMonth,
  });

  factory NoticeboardResponse.fromJson(Map<String, dynamic> json) {
    List<NoticeItem> list(dynamic v) => v is List
        ? v.whereType<Map>().map((e) => NoticeItem.fromJson(Map<String, dynamic>.from(e))).toList()
        : <NoticeItem>[];
    return NoticeboardResponse(
      notices: list(json['notices']),
      upcomingEvents: list(json['upcomingEvents']),
      memberOfTheMonth: MemberOfTheMonth.tryParse(json['memberOfTheMonth']),
    );
  }
}
