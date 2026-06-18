import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/lang_provider.dart';
import '../../providers/marketplace_provider.dart';

String _t(bool bn, String bangla, String english) => bn ? bangla : english;

String _price(bool bn, double amount) =>
    bn ? '৳${amount.toStringAsFixed(0)}' : 'Taka ${amount.toStringAsFixed(0)}';

class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key});

  String _paymentLabel(String method, bool bn) {
    switch (method) {
      case 'bkash':
        return 'bKash';
      case 'cash':
        return _t(bn, 'ক্যাশ অন ডেলিভারি', 'Cash on Delivery');
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(langProvider);
    final orders =
        (ModalRoute.of(context)!.settings.arguments as List<OrderEntry>?) ?? [];

    final total = orders.fold<double>(0, (s, o) => s + o.total);
    const deliveryFee = 60.0;
    final grandTotal = total + deliveryFee;
    final paymentMethod =
        orders.isNotEmpty ? orders.first.paymentMethod : 'cash';
    final address = orders.isNotEmpty ? orders.first.deliveryAddress : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          _t(bn, 'অর্ডার নিশ্চিত', 'Order Confirmed'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Success block ─────────────────────────────────────
          Center(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppTheme.primaryGreen, size: 64),
                ),
                const SizedBox(height: 20),
                Text(
                  _t(bn, 'অর্ডার সফলভাবে দেওয়া হয়েছে!',
                      'Order Placed Successfully!'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _t(
                    bn,
                    'আপনার অর্ডার প্রক্রিয়াধীন আছে।\nশীঘ্রই বিক্রেতা নিশ্চিত করবেন।',
                    'Your order is being processed.\nThe seller will confirm shortly.',
                  ),
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),

          // ── Ordered items ─────────────────────────────────────
          _SectionCard(
            title: _t(bn, '${orders.length}টি পণ্য অর্ডার হয়েছে',
                '${orders.length} item(s) ordered'),
            child: Column(
              children: orders.map((order) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: order.product.primaryImage != null
                            ? Image.network(
                                order.product.primaryImage!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _imgFallback(),
                              )
                            : _imgFallback(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.product.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('${order.quantity} ${order.product.unit}',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        _price(bn, order.total),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1A1A1A)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // ── Price breakdown ───────────────────────────────────
          _SectionCard(
            title: _t(bn, 'মূল্য বিবরণ', 'Price Breakdown'),
            child: Column(
              children: [
                _Row(
                  label: _t(bn, 'পণ্যের মূল্য', 'Product Price'),
                  value: _price(bn, total),
                ),
                const SizedBox(height: 8),
                _Row(
                  label: _t(bn, 'ডেলিভারি চার্জ', 'Delivery Fee'),
                  value: _price(bn, deliveryFee),
                  valueColor: Colors.grey.shade600,
                ),
                Divider(height: 20, thickness: 1, color: Colors.grey.shade200),
                _Row(
                  label: _t(bn, 'সর্বমোট পরিশোধ', 'Grand Total'),
                  value: _price(bn, grandTotal),
                  labelBold: true,
                  valueColor: AppTheme.primaryGreen,
                  valueBold: true,
                  valueFontSize: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Delivery & payment info ───────────────────────────
          _SectionCard(
            title: _t(bn, 'ডেলিভারি ও পেমেন্ট', 'Delivery & Payment'),
            child: Column(
              children: [
                _Row(
                  label: _t(bn, 'পেমেন্ট পদ্ধতি', 'Payment Method'),
                  value: _paymentLabel(paymentMethod, bn),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(bn, 'ঠিকানা', 'Address'),
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const Spacer(),
                    Expanded(
                      child: Text(
                        address.isEmpty ? '—' : address,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1A1A1A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_empty_rounded,
                          color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _t(
                            bn,
                            'বিক্রেতা শীঘ্রই আপনার অর্ডার নিশ্চিত করবেন',
                            'The seller will confirm your order shortly.',
                          ),
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Action buttons ────────────────────────────────────
          ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRouter.orders,
              (route) => route.settings.name == AppRouter.home,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _t(bn, 'আমার অর্ডার দেখুন', 'View My Orders'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRouter.market,
              (route) => route.settings.name == AppRouter.home,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: const BorderSide(color: AppTheme.primaryGreen),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _t(bn, 'বাজারে ফিরে যান', 'Back to Market'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _imgFallback() => Container(
        width: 56,
        height: 56,
        color: Colors.grey.shade100,
        child:
            Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 28),
      );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool labelBold;
  final bool valueBold;
  final Color? valueColor;
  final double? valueFontSize;

  const _Row({
    required this.label,
    required this.value,
    this.labelBold = false,
    this.valueBold = false,
    this.valueColor,
    this.valueFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: labelBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                color: labelBold
                    ? const Color(0xFF1A1A1A)
                    : Colors.grey.shade600)),
        Text(value,
            style: TextStyle(
                fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
                fontSize: valueFontSize ?? 14,
                color: valueColor ?? const Color(0xFF1A1A1A))),
      ],
    );
  }
}
