import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/gym_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/ui_components.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String _tab = 'invoices';
  final Set<String> _expandedInvoices = {};

  void _toggleInvoice(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedInvoices.contains(id)) {
        _expandedInvoices.remove(id);
      } else {
        _expandedInvoices.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gym = Provider.of<GymProvider>(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (gym.isLoadingBilling && gym.billing == null) {
      return const Scaffold(body: LoadingBlock());
    }

    if (gym.billingError != null && gym.billing == null) {
      return Scaffold(
        body: ErrorStateView(
          message: gym.billingError,
          onRetry: () => gym.fetchBilling(),
        ),
      );
    }

    final billing = gym.billing;
    final invoices = billing?.invoices ?? [];
    final payments = billing?.payments ?? [];

    final totalDue = invoices.fold<double>(
      0.0,
      (sum, inv) => sum + (inv.status == 'paid' ? 0.0 : (double.tryParse(inv.balance) ?? 0.0)),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => gym.fetchBilling(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, bottomPadding + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                title: 'Billing & payments',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),

              // Outstanding Banner Card
              AppCard(
                backgroundColor: totalDue > 0 ? AppColors.warningSoft : AppColors.successSoft,
                borderColor: Colors.transparent,
                child: Row(
                  children: [
                    IconBubble(
                      name: totalDue > 0 ? Icons.account_balance_wallet_outlined : Icons.done_all,
                      color: totalDue > 0 ? AppColors.warning : AppColors.success,
                      bg: Colors.white.withOpacity(0.6),
                      size: 48,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            totalDue > 0 ? 'Outstanding balance' : 'All settled',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppFormat.money(totalDue),
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                          ),
                          if (totalDue > 0)
                            const Text(
                              'Pay at the front desk or via eSewa / Khalti.',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Segmented Tab Picker
              SegmentedPicker<String>(
                options: [
                  (value: 'invoices', label: 'Invoices (${invoices.length})', icon: Icons.receipt_long_outlined),
                  (value: 'payments', label: 'Payments (${payments.length})', icon: Icons.payments_outlined),
                ],
                selected: _tab,
                onSelected: (val) => setState(() => _tab = val),
              ),
              const SizedBox(height: 16),

              // Content
              if (_tab == 'invoices')
                invoices.isEmpty
                    ? const AppCard(
                        child: EmptyStateView(
                          icon: Icons.receipt_long_outlined,
                          title: 'No invoices yet',
                          message: 'Invoices from renewals and services will appear here.',
                        ),
                      )
                    : Column(
                        children: invoices.map((inv) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildInvoiceCard(inv),
                        )).toList(),
                      )
              else
                payments.isEmpty
                    ? const AppCard(
                        child: EmptyStateView(
                          icon: Icons.credit_card_outlined,
                          title: 'No payments yet',
                          message: 'Your payment receipts will appear here.',
                        ),
                      )
                    : AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: payments.asMap().entries.map((entry) {
                            final i = entry.key;
                            final p = entry.value;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: i > 0
                                    ? const Border(top: BorderSide(color: AppColors.border, width: 0.8))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  const IconBubble(
                                    name: Icons.check_circle_outline,
                                    color: AppColors.success,
                                    bg: AppColors.successSoft,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppFormat.money(p.amount),
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          '${AppFormat.titleCase(p.method)} · ${AppFormat.formatDateTime(p.createdAt)}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                        ),
                                        if (p.transactionId != null && p.transactionId!.isNotEmpty)
                                          Text(
                                            'Ref ${p.transactionId}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textFaint),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceView inv) {
    final isExpanded = _expandedInvoices.contains(inv.id);
    final balanceNum = double.tryParse(inv.balance) ?? 0.0;
    final isOwing = balanceNum > 0 && inv.status != 'paid';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _toggleInvoice(inv.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const IconBubble(name: Icons.description_outlined),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.invoiceNumber,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            AppFormat.formatDate(inv.createdAt),
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppFormat.money(inv.totalAmount),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        AppBadge(
                          text: AppFormat.titleCase(inv.status),
                          tone: getStatusTone(inv.status),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isOwing) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppFormat.money(inv.balance)} balance${inv.dueDate != null ? " · due ${AppFormat.formatDate(inv.dueDate)}" : ""}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Center(
                  child: Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.textFaint,
                  ),
                ),
              ],
            ),
          ),

          // Expanded items breakdown
          if (isExpanded) ...[
            const Divider(color: AppColors.border, height: 16),
            ...inv.items.map((it) => _buildInvoiceLine(it.description ?? 'Item', AppFormat.money(it.amount))),
            if ((double.tryParse(inv.discountAmount ?? '0') ?? 0) > 0)
              _buildInvoiceLine('Discount', '− ${AppFormat.money(inv.discountAmount)}', color: AppColors.success),
            if ((double.tryParse(inv.taxAmount ?? '0') ?? 0) > 0)
              _buildInvoiceLine('Tax', AppFormat.money(inv.taxAmount)),
            _buildInvoiceLine('Total', AppFormat.money(inv.totalAmount), isBold: true),
            _buildInvoiceLine('Paid', AppFormat.money(inv.paidAmount), color: AppColors.success),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceLine(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
