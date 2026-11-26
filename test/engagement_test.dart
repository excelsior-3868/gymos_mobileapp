import 'package:flutter_test/flutter_test.dart';
import 'package:gymos_mobile/models/models.dart';
import 'package:gymos_mobile/utils/freeze_utils.dart';

void main() {
  group('FreezeRequest.fromJson', () {
    test('parses a full active freeze', () {
      final f = FreezeRequest.fromJson({
        'id': 'f1',
        'memberId': 'm1',
        'membershipId': 'ms1',
        'startDate': '2026-12-01',
        'endDate': '2026-12-03',
        'freezeDays': 3,
        'reason': 'Out of town',
        'status': 'active',
        'originalEndDate': '2026-12-01',
        'extendedEndDate': '2026-12-04',
        'actualEndDate': null,
        'actualFreezeDays': null,
        'reviewNote': null,
        'reviewedAt': '2026-11-26T10:15:00.000Z',
        'createdAt': '2026-11-26T09:00:00.000Z',
      });
      expect(f.status, 'active');
      expect(f.freezeDays, 3);
      expect(f.extendedEndDate, '2026-12-04');
      expect(f.actualFreezeDays, isNull);
      expect(f.reviewNote, isNull);
    });

    test('tolerates missing / odd fields', () {
      final f = FreezeRequest.fromJson({'id': 7, 'freezeDays': '5', 'actualFreezeDays': 2});
      expect(f.id, '7');
      expect(f.freezeDays, 5);
      expect(f.actualFreezeDays, 2);
      expect(f.status, 'pending');
      expect(f.startDate, '');
    });
  });

  group('NoticeboardResponse.fromJson', () {
    test('parses notices, events and member of the month', () {
      final r = NoticeboardResponse.fromJson({
        'notices': [
          {
            'id': 'n1',
            'title': 'Deadlift Challenge',
            'content': '<b>Register</b>',
            'category': 'event',
            'eventDate': '2026-12-05',
            'eventTime': '07:00 AM - 10:00 AM',
            'location': 'Main Floor',
            'isPinned': true,
            'expiresAt': '2026-12-06',
            'createdAt': '2026-11-26T08:30:00.000Z',
          },
        ],
        'upcomingEvents': [],
        'memberOfTheMonth': {
          'id': 'a1',
          'month': '2026-11',
          'monthLabel': 'November 2026',
          'title': 'FitMaxim Member of the Month',
          'giftHamper': 'Hamper',
          'attendanceDays': 26,
          'onTimeRenewal': true,
          'referralCount': 2,
          'disciplineScore': 390,
          'hamperDelivered': false,
          'publishedAt': '2026-11-26T10:00:00.000Z',
          'winner': {'id': 'w', 'fullName': 'Aarav Sharma', 'registrationNumber': 'GYM-0124', 'photoUrl': null},
          'isCurrentMember': true,
        },
      });
      expect(r.notices.single.isPinned, isTrue);
      expect(r.notices.single.content, '<b>Register</b>'); // kept verbatim, rendered as plain text
      expect(r.upcomingEvents, isEmpty);
      expect(r.memberOfTheMonth!.winner.fullName, 'Aarav Sharma');
      expect(r.memberOfTheMonth!.winner.photoUrl, isNull);
      expect(r.memberOfTheMonth!.isCurrentMember, isTrue);
    });

    test('handles empty payload', () {
      final r = NoticeboardResponse.fromJson({});
      expect(r.notices, isEmpty);
      expect(r.memberOfTheMonth, isNull);
    });
  });

  group('MeResponse freeze fields', () {
    test('defaults when absent and parses when present', () {
      final base = {
        'member': {'id': 'm', 'registrationNumber': 'GYM-1', 'fullName': 'A'},
        'services': [],
      };
      final none = MeResponse.fromJson(base);
      expect(none.activeFreeze, isNull);
      expect(none.pendingFreezeCount, 0);
      expect(none.memberOfTheMonth, isNull);

      final some = MeResponse.fromJson({
        ...base,
        'membership': {'id': 'x', 'frozenDays': 3, 'package': <String, dynamic>{}},
        'upcomingFreeze': {'id': 'f', 'startDate': '2026-12-01', 'endDate': '2026-12-03', 'freezeDays': 3},
        'pendingFreezeCount': 1,
      });
      expect(some.membership!.frozenDays, 3);
      expect(some.upcomingFreeze!.freezeDays, 3);
      expect(some.pendingFreezeCount, 1);
    });
  });

  group('FreezeUtils', () {
    test('inclusive day count', () {
      final s = FreezeUtils.parseYmd('2026-12-01');
      final e = FreezeUtils.parseYmd('2026-12-03');
      expect(FreezeUtils.inclusiveDays(s, e), 3);
      expect(FreezeUtils.inclusiveDays(s, s), 1);
    });

    test('end date from duration', () {
      final s = FreezeUtils.parseYmd('2026-12-01');
      expect(FreezeUtils.ymd(FreezeUtils.endDateForDays(s, 3)), '2026-12-03');
      expect(FreezeUtils.ymd(FreezeUtils.endDateForDays(s, 1)), '2026-12-01');
      expect(FreezeUtils.ymd(FreezeUtils.endDateForDays(s, 14)), '2026-12-14');
    });

    test('expiry preview extends by frozen days', () {
      final end = FreezeUtils.parseYmd('2026-12-01');
      expect(FreezeUtils.ymd(FreezeUtils.newExpiry(end, 3)), '2026-12-04');
    });

    test('works across month/year boundaries', () {
      final s = FreezeUtils.parseYmd('2026-12-30');
      expect(FreezeUtils.ymd(FreezeUtils.endDateForDays(s, 5)), '2027-01-03');
      expect(FreezeUtils.inclusiveDays(s, FreezeUtils.parseYmd('2027-01-03')), 5);
    });
  });
}
