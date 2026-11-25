class Member {
  final String id;
  final String registrationNumber;
  final String fullName;
  final String? email;
  final String phone;
  final String? dob;
  final String? photoUrl;
  final String? address;
  final String? bloodGroup;
  final String? emergencyContact;
  final String? healthConditions;
  final String? fitnessGoals;
  final String? targetBodyShape;
  final String registrationDate;
  final bool? isActive;
  final bool? mustChangePassword;

  Member({
    required this.id,
    required this.registrationNumber,
    required this.fullName,
    this.email,
    required this.phone,
    this.dob,
    this.photoUrl,
    this.address,
    this.bloodGroup,
    this.emergencyContact,
    this.healthConditions,
    this.fitnessGoals,
    this.targetBodyShape,
    required this.registrationDate,
    this.isActive,
    this.mustChangePassword,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id']?.toString() ?? '',
      registrationNumber: json['registrationNumber']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? '',
      dob: json['dob'],
      photoUrl: json['photoUrl'],
      address: json['address'],
      bloodGroup: json['bloodGroup'],
      emergencyContact: json['emergencyContact'],
      healthConditions: json['healthConditions'],
      fitnessGoals: json['fitnessGoals'],
      targetBodyShape: json['targetBodyShape'],
      registrationDate: json['registrationDate'] ?? '',
      isActive: json['isActive'],
      mustChangePassword: json['mustChangePassword'] == true,
    );
  }
}

class PackageInfo {
  final int id;
  final String name;
  final String? description;
  final String price;
  final int durationDays;
  final String billingCycle;
  final String accessScope;
  final List<String> includedServices;
  final String? startTime;
  final String? endTime;
  final int? sessionCount;

  PackageInfo({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.durationDays,
    required this.billingCycle,
    required this.accessScope,
    required this.includedServices,
    this.startTime,
    this.endTime,
    this.sessionCount,
  });

  factory PackageInfo.fromJson(Map<String, dynamic> json) {
    return PackageInfo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      price: json['price']?.toString() ?? '0',
      durationDays: json['durationDays'] is int ? json['durationDays'] : int.tryParse(json['durationDays']?.toString() ?? '0') ?? 0,
      billingCycle: json['billingCycle'] ?? 'monthly',
      accessScope: json['accessScope'] ?? 'all',
      includedServices: (json['includedServices'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      startTime: json['startTime'],
      endTime: json['endTime'],
      sessionCount: json['sessionCount'],
    );
  }
}

class MembershipView {
  final String id;
  final String status;
  final String startDate;
  final String endDate;
  final int daysLeft;
  final double progress;
  final String? paidAmount;
  final String? dueAmount;
  final int? totalSessions;
  final int? usedSessions;
  final PackageInfo package;

  MembershipView({
    required this.id,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.daysLeft,
    required this.progress,
    this.paidAmount,
    this.dueAmount,
    this.totalSessions,
    this.usedSessions,
    required this.package,
  });

  factory MembershipView.fromJson(Map<String, dynamic> json) {
    return MembershipView(
      id: json['id']?.toString() ?? '',
      status: json['status'] ?? 'active',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      daysLeft: (json['daysLeft'] is num ? (json['daysLeft'] as num).toInt() : int.tryParse(json['daysLeft']?.toString() ?? '0')) ?? 0,
      progress: (json['progress'] is num ? (json['progress'] as num).toDouble() : double.tryParse(json['progress']?.toString() ?? '0.0')) ?? 0.0,
      paidAmount: json['paidAmount']?.toString(),
      dueAmount: json['dueAmount']?.toString(),
      totalSessions: json['totalSessions'] is int ? json['totalSessions'] : int.tryParse(json['totalSessions']?.toString() ?? ''),
      usedSessions: json['usedSessions'] is int ? json['usedSessions'] : int.tryParse(json['usedSessions']?.toString() ?? ''),
      package: PackageInfo.fromJson(json['package'] ?? {}),
    );
  }
}

class ServiceView {
  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final String? status;
  final Map<String, dynamic>? metadata;

  ServiceView({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.status,
    this.metadata,
  });

  factory ServiceView.fromJson(Map<String, dynamic> json) {
    return ServiceView(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      status: json['status'],
      metadata: json['metadata'],
    );
  }
}

class MeResponse {
  final Member member;
  final MembershipView? membership;
  final List<ServiceView> services;
  final int unreadNotifications;
  final String outstandingInvoices;

  MeResponse({
    required this.member,
    this.membership,
    required this.services,
    required this.unreadNotifications,
    required this.outstandingInvoices,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      member: Member.fromJson(json['member'] ?? {}),
      membership: json['membership'] != null ? MembershipView.fromJson(json['membership']) : null,
      services: (json['services'] as List<dynamic>?)?.map((s) => ServiceView.fromJson(s)).toList() ?? [],
      unreadNotifications: json['unreadNotifications'] is int ? json['unreadNotifications'] : int.tryParse(json['unreadNotifications']?.toString() ?? '0') ?? 0,
      outstandingInvoices: json['outstandingInvoices']?.toString() ?? '0',
    );
  }
}

class InvoiceItem {
  final String? description;
  final String amount;

  InvoiceItem({this.description, required this.amount});

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'],
      amount: json['amount']?.toString() ?? '0',
    );
  }
}

class InvoiceView {
  final String id;
  final String invoiceNumber;
  final String? status;
  final String subtotal;
  final String? discountAmount;
  final String? taxAmount;
  final String totalAmount;
  final String paidAmount;
  final String balance;
  final String? dueDate;
  final String createdAt;
  final List<InvoiceItem> items;

  InvoiceView({
    required this.id,
    required this.invoiceNumber,
    this.status,
    required this.subtotal,
    this.discountAmount,
    this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.balance,
    this.dueDate,
    required this.createdAt,
    required this.items,
  });

  factory InvoiceView.fromJson(Map<String, dynamic> json) {
    return InvoiceView(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      status: json['status'],
      subtotal: json['subtotal']?.toString() ?? '0',
      discountAmount: json['discountAmount']?.toString(),
      taxAmount: json['taxAmount']?.toString(),
      totalAmount: json['totalAmount']?.toString() ?? '0',
      paidAmount: json['paidAmount']?.toString() ?? '0',
      balance: json['balance']?.toString() ?? '0',
      dueDate: json['dueDate'],
      createdAt: json['createdAt'] ?? '',
      items: (json['items'] as List<dynamic>?)?.map((e) => InvoiceItem.fromJson(e)).toList() ?? [],
    );
  }
}

class PaymentView {
  final String id;
  final String amount;
  final String method;
  final String? transactionId;
  final String createdAt;

  PaymentView({
    required this.id,
    required this.amount,
    required this.method,
    this.transactionId,
    required this.createdAt,
  });

  factory PaymentView.fromJson(Map<String, dynamic> json) {
    return PaymentView(
      id: json['id']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      method: json['method'] ?? 'cash',
      transactionId: json['transactionId'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class BillingResponse {
  final List<InvoiceView> invoices;
  final List<PaymentView> payments;

  BillingResponse({required this.invoices, required this.payments});

  factory BillingResponse.fromJson(Map<String, dynamic> json) {
    return BillingResponse(
      invoices: (json['invoices'] as List<dynamic>?)?.map((e) => InvoiceView.fromJson(e)).toList() ?? [],
      payments: (json['payments'] as List<dynamic>?)?.map((e) => PaymentView.fromJson(e)).toList() ?? [],
    );
  }
}

class AttendanceRecord {
  final int id;
  final String checkInTime;
  final String? checkOutTime;
  final String? method;
  final String? status;
  final String? reason;

  AttendanceRecord({
    required this.id,
    required this.checkInTime,
    this.checkOutTime,
    this.method,
    this.status,
    this.reason,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      checkInTime: json['checkInTime'] ?? '',
      checkOutTime: json['checkOutTime'],
      method: json['method'],
      status: json['status'],
      reason: json['reason'],
    );
  }
}

class AttendanceResponse {
  final int streak;
  final int thisMonth;
  final int totalLast120Days;
  final List<String> visitDates;
  final List<AttendanceRecord> recent;

  AttendanceResponse({
    required this.streak,
    required this.thisMonth,
    required this.totalLast120Days,
    required this.visitDates,
    required this.recent,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return AttendanceResponse(
      streak: stats['streak'] is int ? stats['streak'] : int.tryParse(stats['streak']?.toString() ?? '0') ?? 0,
      thisMonth: stats['thisMonth'] is int ? stats['thisMonth'] : int.tryParse(stats['thisMonth']?.toString() ?? '0') ?? 0,
      totalLast120Days: stats['totalLast120Days'] is int ? stats['totalLast120Days'] : int.tryParse(stats['totalLast120Days']?.toString() ?? '0') ?? 0,
      visitDates: (json['visitDates'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      recent: (json['recent'] as List<dynamic>?)?.map((e) => AttendanceRecord.fromJson(e)).toList() ?? [],
    );
  }
}

class RoutineExercise {
  final String? exerciseId;
  final String name;
  final int sets;
  final String reps;
  final int restSeconds;
  final String notes;

  RoutineExercise({
    this.exerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.notes,
  });

  factory RoutineExercise.fromJson(Map<String, dynamic> json) {
    return RoutineExercise(
      exerciseId: json['exerciseId']?.toString(),
      name: json['name'] ?? '',
      sets: json['sets'] is int ? json['sets'] : int.tryParse(json['sets']?.toString() ?? '3') ?? 3,
      reps: json['reps']?.toString() ?? '10',
      restSeconds: json['restSeconds'] is int ? json['restSeconds'] : int.tryParse(json['restSeconds']?.toString() ?? '60') ?? 60,
      notes: json['notes'] ?? '',
    );
  }
}

class RoutineDay {
  final bool isRestDay;
  final String label;
  final List<RoutineExercise> exercises;

  RoutineDay({
    required this.isRestDay,
    required this.label,
    required this.exercises,
  });

  factory RoutineDay.fromJson(Map<String, dynamic> json) {
    return RoutineDay(
      isRestDay: json['isRestDay'] == true,
      label: json['label'] ?? '',
      exercises: (json['exercises'] as List<dynamic>?)?.map((e) => RoutineExercise.fromJson(e)).toList() ?? [],
    );
  }
}

class WorkoutRoutine {
  final int version;
  final Map<String, RoutineDay> days;

  WorkoutRoutine({required this.version, required this.days});

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as Map<String, dynamic>? ?? {};
    final mappedDays = <String, RoutineDay>{};
    for (final key in rawDays.keys) {
      if (rawDays[key] is Map<String, dynamic>) {
        mappedDays[key.toLowerCase()] = RoutineDay.fromJson(rawDays[key]);
      }
    }
    return WorkoutRoutine(
      version: json['version'] is int ? json['version'] : 1,
      days: mappedDays,
    );
  }
}

class WorkoutPlan {
  final String id;
  final String name;
  final String? description;
  final String? difficulty;
  final String? targetBodyShape;
  final WorkoutRoutine? routine;
  final String? details;

  WorkoutPlan({
    required this.id,
    required this.name,
    this.description,
    this.difficulty,
    this.targetBodyShape,
    this.routine,
    this.details,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      difficulty: json['difficulty'],
      targetBodyShape: json['targetBodyShape'],
      routine: json['routine'] != null ? WorkoutRoutine.fromJson(json['routine']) : null,
      details: json['details'],
    );
  }
}

class DietPlan {
  final String id;
  final String name;
  final String? description;
  final String? targetGoal;
  final int? calories;
  final String? details;

  DietPlan({
    required this.id,
    required this.name,
    this.description,
    this.targetGoal,
    this.calories,
    this.details,
  });

  factory DietPlan.fromJson(Map<String, dynamic> json) {
    return DietPlan(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      targetGoal: json['targetGoal'],
      calories: json['calories'] is int ? json['calories'] : int.tryParse(json['calories']?.toString() ?? ''),
      details: json['details'],
    );
  }
}

class FitnessResponse {
  final WorkoutPlan? workout;
  final DietPlan? diet;

  FitnessResponse({this.workout, this.diet});

  factory FitnessResponse.fromJson(Map<String, dynamic> json) {
    return FitnessResponse(
      workout: json['workout'] != null ? WorkoutPlan.fromJson(json['workout']) : null,
      diet: json['diet'] != null ? DietPlan.fromJson(json['diet']) : null,
    );
  }
}

class ClassSession {
  final int scheduleId;
  final String date;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String className;
  final String? category;
  final String? description;
  final int durationMinutes;
  final String? trainerName;
  final int capacity;
  final int booked;
  final int? myBookingId;

  ClassSession({
    required this.scheduleId,
    required this.date,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.className,
    this.category,
    this.description,
    required this.durationMinutes,
    this.trainerName,
    required this.capacity,
    required this.booked,
    this.myBookingId,
  });

  factory ClassSession.fromJson(Map<String, dynamic> json) {
    return ClassSession(
      scheduleId: json['scheduleId'] is int ? json['scheduleId'] : int.tryParse(json['scheduleId']?.toString() ?? '0') ?? 0,
      date: json['date'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      className: json['className'] ?? '',
      category: json['category'],
      description: json['description'],
      durationMinutes: json['durationMinutes'] is int ? json['durationMinutes'] : int.tryParse(json['durationMinutes']?.toString() ?? '60') ?? 60,
      trainerName: json['trainerName'],
      capacity: json['capacity'] is int ? json['capacity'] : int.tryParse(json['capacity']?.toString() ?? '20') ?? 20,
      booked: json['booked'] is int ? json['booked'] : int.tryParse(json['booked']?.toString() ?? '0') ?? 0,
      myBookingId: json['myBookingId'] is int ? json['myBookingId'] : int.tryParse(json['myBookingId']?.toString() ?? ''),
    );
  }
}

class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String? type;
  final String? status;
  final String createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    this.status,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'],
      status: json['status'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class RewardCode {
  final String code;
  final String generatedAt;

  RewardCode({required this.code, required this.generatedAt});

  factory RewardCode.fromJson(Map<String, dynamic> json) {
    return RewardCode(
      code: json['code'] ?? '',
      generatedAt: json['generatedAt'] ?? '',
    );
  }
}

class ReferredMember {
  final String name;
  final String? status;
  final String createdAt;

  ReferredMember({required this.name, this.status, required this.createdAt});

  factory ReferredMember.fromJson(Map<String, dynamic> json) {
    return ReferredMember(
      name: json['name'] ?? '',
      status: json['status'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class ReferralsResponse {
  final int total;
  final int towardsNextReward;
  final int milestone;
  final String referralCode;
  final List<RewardCode> rewardCodes;
  final List<ReferredMember> referred;

  ReferralsResponse({
    required this.total,
    required this.towardsNextReward,
    required this.milestone,
    required this.referralCode,
    required this.rewardCodes,
    required this.referred,
  });

  factory ReferralsResponse.fromJson(Map<String, dynamic> json) {
    return ReferralsResponse(
      total: json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      towardsNextReward: json['towardsNextReward'] is int ? json['towardsNextReward'] : int.tryParse(json['towardsNextReward']?.toString() ?? '0') ?? 0,
      milestone: json['milestone'] is int ? json['milestone'] : int.tryParse(json['milestone']?.toString() ?? '5') ?? 5,
      referralCode: json['referralCode'] ?? '',
      rewardCodes: (json['rewardCodes'] as List<dynamic>?)?.map((e) => RewardCode.fromJson(e)).toList() ?? [],
      referred: (json['referred'] as List<dynamic>?)?.map((e) => ReferredMember.fromJson(e)).toList() ?? [],
    );
  }
}

class BrandingResponse {
  final String gymName;
  final String? primaryColor;
  final String? gymAddress;
  final String? supportPhone;
  final String? logoUrl;

  BrandingResponse({
    required this.gymName,
    this.primaryColor,
    this.gymAddress,
    this.supportPhone,
    this.logoUrl,
  });

  factory BrandingResponse.fromJson(Map<String, dynamic> json) {
    return BrandingResponse(
      gymName: json['gymName'] ?? 'GymOS',
      primaryColor: json['primaryColor'],
      gymAddress: json['gymAddress'],
      supportPhone: json['supportPhone'],
      logoUrl: json['logoUrl'],
    );
  }
}

class OtpChallenge {
  final String challenge;
  final int expiresIn;
  final String? devCode;

  OtpChallenge({required this.challenge, required this.expiresIn, this.devCode});

  factory OtpChallenge.fromJson(Map<String, dynamic> json) {
    return OtpChallenge(
      challenge: json['challenge'] ?? '',
      expiresIn: json['expiresIn'] is int ? json['expiresIn'] : int.tryParse(json['expiresIn']?.toString() ?? '300') ?? 300,
      devCode: json['devCode'],
    );
  }
}

class OfferBonus {
  final String billingCycle;
  final int bonusDays;

  OfferBonus({required this.billingCycle, required this.bonusDays});

  factory OfferBonus.fromJson(Map<String, dynamic> json) => OfferBonus(
        billingCycle: json['billingCycle']?.toString() ?? '',
        bonusDays: json['bonusDays'] is int
            ? json['bonusDays']
            : int.tryParse(json['bonusDays']?.toString() ?? '0') ?? 0,
      );

  String get shortLabel {
    switch (billingCycle) {
      case 'monthly':
        return '1M';
      case 'quarterly':
        return '3M';
      case 'half_yearly':
        return '6M';
      case 'yearly':
        return '1Y';
      default:
        return billingCycle;
    }
  }

  String get cycleLabel {
    switch (billingCycle) {
      case 'monthly':
        return 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'half_yearly':
        return 'Half-yearly';
      case 'yearly':
        return 'Yearly';
      default:
        return billingCycle;
    }
  }
}

class Offer {
  final String id;
  final String type;
  final String title;
  final String? description;
  final String startDate;
  final String endDate;
  final int daysLeft;
  final bool eligible;
  final List<OfferBonus> bonuses;

  Offer({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.daysLeft,
    required this.eligible,
    required this.bonuses,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        startDate: json['startDate']?.toString() ?? '',
        endDate: json['endDate']?.toString() ?? '',
        daysLeft: json['daysLeft'] is int
            ? json['daysLeft']
            : int.tryParse(json['daysLeft']?.toString() ?? '0') ?? 0,
        eligible: json['eligible'] == true,
        bonuses: ((json['bonuses'] as List?) ?? [])
            .map((e) => OfferBonus.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
