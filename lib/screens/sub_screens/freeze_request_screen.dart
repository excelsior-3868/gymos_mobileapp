import 'package:flutter/material.dart';
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
  late DateTime _start;
  int _days = 3;
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  /// Today's calendar date in Nepal time, as UTC midnight.
  DateTime get _today => FreezeUtils.dateOnly(AppFormat.toNepalTime(DateTime.now()));

  DateTime get _end => FreezeUtils.endDateForDays(_start, _days);

  @override
  void initState() {
    super.initState();
    _start = _today;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GymProvider>().fetchFreezeRequests();
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

  Future<void> _pickEnd() async {
    final last = _start.add(const Duration(days: FreezeUtils.maxFreezeDays - 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _asLocal(_end),
      firstDate: _asLocal(_start),
      lastDate: _asLocal(last),
    );
    if (picked != null) {
      setState(() => _days = FreezeUtils.inclusiveDays(_start, picked).clamp(1, FreezeUtils.maxFreezeDays));
    }
  }

  Future<void> _submit() async {
    final gym = context.read<GymProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await gym.submitFreezeRequest(
        startDate: FreezeUtils.ymd(_start),
        endDate: FreezeUtils.ymd(_end),
        reason: _reasonCtrl.text,
      );
      if (!mounted) return;
      _reasonCtrl.clear();
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
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => Future.wait([gym.fetchFreezeRequests(), gym.fetchMe()]),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, top + 8, 16, bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(title: 'Freeze plan', onBack: () => Navigator.pop(context)),
              const SizedBox(height: 12),
              _infoCard(),
              const SizedBox(height: 16),
              if (canRequestFreeze(membership)) ...[
                _buildForm(membership!),
                const SizedBox(height: 24),
              ] else ...[
                const AppCard(
                  child: EmptyStateView(
                    icon: Icons.ac_unit,
                    title: 'Freeze not available',
                    message: 'Freezing needs an active, date-based membership. Session packs and expired plans can’t be frozen.',
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const SectionHeader(title: 'Request history', icon: Icons.history),
              const SizedBox(height: 12),
              _buildHistory(gym),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard() {
    return AppCard(
      backgroundColor: kFreezeSoft,
      borderColor: const Color(0xFFB5E4EE),
      child: const Row(
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
    );
  }

  Widget _quickChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primarySoft,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.primary : AppColors.textMuted,
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

  Widget _buildForm(MembershipView m) {
    final membershipEnd = FreezeUtils.parseYmd(m.endDate);
    final today = _today;
    final newExpiry = FreezeUtils.newExpiry(membershipEnd, _days);
    final startOffset = _start.difference(today).inDays;
    final startPastExpiry = _start.isAfter(membershipEnd);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('New freeze request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _dateField('Start date', _start, () => _pickStart(membershipEnd)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _quickChip('Today', startOffset == 0, () => setState(() => _start = today)),
              _quickChip('Tomorrow', startOffset == 1, () => setState(() => _start = today.add(const Duration(days: 1)))),
              _quickChip('In 3 days', startOffset == 3, () => setState(() => _start = today.add(const Duration(days: 3)))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _dateField('End date', _end, _pickEnd)),
              const SizedBox(width: 10),
              _stepper(),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final d in const [3, 5, 7, 14])
                _quickChip('$d days', _days == d, () => setState(() => _days = d)),
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
                  : 'Freezing $_days day${_days == 1 ? '' : 's'} (${AppFormat.formatDateShort(FreezeUtils.ymd(_start))} – ${AppFormat.formatDateShort(FreezeUtils.ymd(_end))}) '
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
              hintText: 'e.g., Going out of town for 3 days for work',
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
            onPress: _submit,
          ),
        ],
      ),
    );
  }

  Widget _stepper() {
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
          btn(Icons.remove, _days > 1 ? () => setState(() => _days--) : null),
          Text('$_days', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          btn(Icons.add, _days < FreezeUtils.maxFreezeDays ? () => setState(() => _days++) : null),
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
