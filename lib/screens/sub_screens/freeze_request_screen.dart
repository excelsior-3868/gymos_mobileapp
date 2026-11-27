import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/gym_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/freeze_utils.dart';
import '../../widgets/engagement_widgets.dart';
import '../../widgets/ui_components.dart';

/// Whether the member may request a freeze (calendar-based, not session-based).
bool canRequestFreeze(MembershipView? m) =>
    m != null && (m.status == 'active' || m.status == 'frozen') && m.totalSessions == null && m.daysLeft >= 0;

({String label, Color fg, Color bg}) freezeStatusStyle(String status) {
  switch (status) {
    case 'pending':
      return (label: 'Pending Approval', fg: AppColors.warning, bg: AppColors.warningSoft);
    case 'approved':
      return (label: 'Scheduled', fg: AppColors.info, bg: AppColors.infoSoft);
    case 'active':
      return (label: 'Frozen Now', fg: kFreeze, bg: kFreezeSoft);
    case 'completed':
      return (label: 'Completed', fg: AppColors.success, bg: AppColors.successSoft);
    case 'rejected':
      return (label: 'Declined', fg: AppColors.danger, bg: AppColors.dangerSoft);
    default:
      return (label: AppFormat.titleCase(status), fg: AppColors.textMuted, bg: AppColors.surfaceAlt);
  }
}

class FreezeRequestScreen extends StatefulWidget {
  const FreezeRequestScreen({super.key});

  @override
  State<FreezeRequestScreen> createState() => _FreezeRequestScreenState();
}

class _FreezeRequestScreenState extends State<FreezeRequestScreen> {
  int _tab = 0; // 0 = New request, 1 = Request history
  late DateTime _start;
  int _days = 3;
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  /// Today's calendar date in Nepal time, as UTC midnight.
  DateTime get _today => FreezeUtils.dateOnly(AppFormat.toNepalTime(DateTime.now()));

  @override
  void initState() {
    super.initState();
    _start = _today;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final gym = context.read<GymProvider>();
      gym.fetchFreezeRequests();
      gym.fetchFreezePolicy();
    });
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  DateTime _asLocal(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _pickStart(DateTime membershipEnd) async {
    final first = _today;
    final last = membershipEnd.isBefore(first) ? first : membershipEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: _asLocal(_start.isBefore(first) ? first : (_start.isAfter(last) ? last : _start)),
      firstDate: _asLocal(first),
      lastDate: _asLocal(last),
    );
    if (picked != null) setState(() => _start = FreezeUtils.dateOnly(picked));
  }

  Future<void> _pickEnd(int maxAllowedDays) async {
    final cap = maxAllowedDays.clamp(1, FreezeUtils.maxFreezeDays);
    final effectiveDays = _days.clamp(1, cap);
    final last = _start.add(Duration(days: cap - 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _asLocal(FreezeUtils.endDateForDays(_start, effectiveDays)),
      firstDate: _asLocal(_start),
      lastDate: _asLocal(last),
    );
    if (picked != null) {
      setState(() => _days = FreezeUtils.inclusiveDays(_start, picked).clamp(1, cap));
    }
  }

  Future<void> _submit(int maxAllowedDays) async {
    final cap = maxAllowedDays.clamp(1, FreezeUtils.maxFreezeDays);
    final effectiveDays = _days.clamp(1, cap);
    if (effectiveDays > maxAllowedDays) {
      setState(() => _error = 'You can freeze at most $maxAllowedDays day${maxAllowedDays == 1 ? '' : 's'}.');
      return;
    }
    final gym = context.read<GymProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await gym.submitFreezeRequest(
        startDate: FreezeUtils.ymd(_start),
        endDate: FreezeUtils.ymd(FreezeUtils.endDateForDays(_start, effectiveDays)),
        reason: _reasonCtrl.text,
      );
      if (!mounted) return;
      _reasonCtrl.clear();
      setState(() => _tab = 1);
      messenger.showSnackBar(const SnackBar(content: Text('Freeze request sent for admin approval.')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cancel(FreezeRequest r) async {
    final gym = context.read<GymProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel freeze request?'),
        content: Text('${AppFormat.formatDate(r.startDate)} → ${AppFormat.formatDate(r.endDate)} (${r.freezeDays} days)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel request', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await gym.cancelFreezeRequest(r.id);
      messenger.showSnackBar(const SnackBar(content: Text('Freeze request cancelled.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gym = Provider.of<GymProvider>(context);
    final membership = gym.me?.membership;
    final policy = gym.freezePolicy;
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    final policyBlocked = policy != null && (!policy.enabled || !policy.canFreeze || policy.remainingDays <= 0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => Future.wait([
          gym.fetchFreezeRequests(),
          gym.fetchFreezePolicy(),
          gym.fetchMe(),
        ]),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, top + 8, 16, bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(title: 'Freeze plan', onBack: () => Navigator.pop(context)),
              const SizedBox(height: 12),
              _buildTabSwitcher(gym.freezeRequests.length),
              const SizedBox(height: 16),
              if (_tab == 0) ...[
                _infoCard(policy),
                const SizedBox(height: 16),
                if (gym.isLoadingFreezePolicy && policy == null && canRequestFreeze(membership)) ...[
                  const LoadingBlock(),
                ] else if (policyBlocked) ...[
                  AppCard(
                    child: EmptyStateView(
                      icon: Icons.ac_unit,
                      title: !policy.enabled ? 'Freeze unavailable' : 'Freeze limit reached',
                      message: !policy.enabled
                          ? 'Membership freezing is currently disabled for your plan.'
                          : 'You have used ${policy.usedDays} of ${policy.maxDays} freeze day${policy.maxDays == 1 ? '' : 's'} allowed for your ${policy.cycleLabel.isNotEmpty ? policy.cycleLabel : 'current'} plan.',
                    ),
                  ),
                ] else if (canRequestFreeze(membership)) ...[
                  _buildForm(membership!, policy),
                ] else ...[
                  const AppCard(
                    child: EmptyStateView(
                      icon: Icons.ac_unit,
                      title: 'Freeze not available',
                      message: 'Freezing needs an active, date-based membership. Session packs and expired plans can’t be frozen.',
                    ),
                  ),
                ],
              ] else ...[
                _buildHistory(gym),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher(int historyCount) {
    Widget tabBtn(int index, IconData icon, String label, {int badge = 0}) {
      final selected = _tab == index;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_tab != index) {
              HapticFeedback.selectionClick();
              setState(() => _tab = index);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: selected ? AppColors.primary : AppColors.textMuted),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: selected ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                if (badge > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          tabBtn(0, Icons.ac_unit, 'New request'),
          tabBtn(1, Icons.history, 'Request history', badge: historyCount),
        ],
      ),
    );
  }

  Widget _infoCard(FreezeAllowance? policy) {
    final cycleText = (policy != null && policy.cycleLabel.isNotEmpty)
        ? '${policy.cycleLabel} plan'
        : 'Your plan';
    return AppCard(
      backgroundColor: kFreezeSoft,
      borderColor: const Color(0xFFB5E4EE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBubble(name: Icons.ac_unit, color: kFreeze, bg: Colors.white),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Going out of town? Request a freeze. Once approved by admin, your frozen days won\'t count toward expiry.',
                  style: TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.text),
                ),
              ),
            ],
          ),
          if (policy != null && policy.enabled && policy.maxDays > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_outlined, size: 16, color: kFreeze),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$cycleText: ${policy.remainingDays} of ${policy.maxDays} freeze day${policy.maxDays == 1 ? '' : 's'} remaining',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime d, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(
                    AppFormat.formatDate(FreezeUtils.ymd(d)),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(MembershipView m, FreezeAllowance? policy) {
    final maxAllowedDays = (policy != null && policy.remainingDays > 0)
        ? policy.remainingDays.clamp(1, FreezeUtils.maxFreezeDays)
        : FreezeUtils.maxFreezeDays;
    final effectiveDays = _days.clamp(1, maxAllowedDays);
    final effectiveEnd = FreezeUtils.endDateForDays(_start, effectiveDays);

    final membershipEnd = FreezeUtils.parseYmd(m.endDate);
    final newExpiry = FreezeUtils.newExpiry(membershipEnd, effectiveDays);
    final startPastExpiry = _start.isAfter(membershipEnd);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('New freeze request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              if (policy != null && policy.maxDays > 0)
                Text(
                  'Max $maxAllowedDays day${maxAllowedDays == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _dateField('Start date', _start, () => _pickStart(membershipEnd)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _dateField('End date', effectiveEnd, () => _pickEnd(maxAllowedDays))),
              const SizedBox(width: 10),
              _stepper(effectiveDays, maxAllowedDays),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: startPastExpiry ? AppColors.dangerSoft : kFreezeSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              startPastExpiry
                  ? 'Start date can’t be after your current expiry (${AppFormat.formatDate(m.endDate)}).'
                  : 'Freezing $effectiveDays day${effectiveDays == 1 ? '' : 's'} (${AppFormat.formatDateShort(FreezeUtils.ymd(_start))} – ${AppFormat.formatDateShort(FreezeUtils.ymd(effectiveEnd))}) '
                      'extends your expiry from ${AppFormat.formatDate(m.endDate)} → ${AppFormat.formatDate(FreezeUtils.ymd(newExpiry))} once approved by admin.',
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.text),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reasonCtrl,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'e.g., Going out of town for work',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.danger))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          AppButton(
            title: 'Submit freeze request',
            icon: Icons.ac_unit,
            loading: _submitting,
            disabled: startPastExpiry,
            onPress: () => _submit(maxAllowedDays),
          ),
        ],
      ),
    );
  }

  Widget _stepper(int effectiveDays, int maxAllowedDays) {
    Widget btn(IconData icon, VoidCallback? onTap) => IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          visualDensity: VisualDensity.compact,
        );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove, effectiveDays > 1 ? () => setState(() => _days = effectiveDays - 1) : null),
          Text('$effectiveDays', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          btn(Icons.add, effectiveDays < maxAllowedDays ? () => setState(() => _days = effectiveDays + 1) : null),
        ],
      ),
    );
  }

  Widget _buildHistory(GymProvider gym) {
    final list = gym.freezeRequests;
    if (gym.isLoadingFreeze && list.isEmpty) return const LoadingBlock();
    if (gym.freezeError != null && list.isEmpty) {
      return ErrorStateView(message: gym.freezeError, onRetry: gym.fetchFreezeRequests);
    }
    if (list.isEmpty) {
      return const AppCard(
        child: EmptyStateView(
          icon: Icons.history_toggle_off,
          title: 'No freeze requests yet',
          message: 'Your freeze requests and their status will appear here.',
        ),
      );
    }
    return Column(
      children: [for (final r in list) Padding(padding: const EdgeInsets.only(bottom: 10), child: _historyCard(r))],
    );
  }

  Widget _historyCard(FreezeRequest r) {
    final s = freezeStatusStyle(r.status);
    final early = r.actualFreezeDays != null && r.actualFreezeDays != r.freezeDays;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${AppFormat.formatDate(r.startDate)} → ${AppFormat.formatDate(r.endDate)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text(s.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: s.fg)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            early
                ? '${r.freezeDays} days requested · ${r.actualFreezeDays} actually frozen'
                : '${r.freezeDays} day${r.freezeDays == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          if (r.originalEndDate != null && r.extendedEndDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Expiry: ${AppFormat.formatDate(r.originalEndDate)} → ${AppFormat.formatDate(r.extendedEndDate)}',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
          if (r.reason != null && r.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('“${r.reason}”', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.text)),
          ],
          if (r.reviewNote != null && r.reviewNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Text('Admin note: ${r.reviewNote}', style: const TextStyle(fontSize: 12.5, color: AppColors.text)),
            ),
          ],
          if (r.status == 'pending') ...[
            const SizedBox(height: 10),
            AppButton(title: 'Cancel Request', variant: ButtonVariant.danger, small: true, onPress: () => _cancel(r)),
          ],
        ],
      ),
    );
  }
}
