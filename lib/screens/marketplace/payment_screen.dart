import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/marketplace_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedPayment = 'bkash';
  final _addressController = TextEditingController();
  bool _isPlacing = false;

  static const _paymentOptions = [
    (
      id: 'bkash',
      label: 'বিকাশ',
      subtitle: 'মোবাইল ব্যাংকিং',
      icon: Icons.phone_android_rounded,
      color: Color(0xFFE2136E),
    ),
    (
      id: 'sslcommerz',
      label: 'SSLCommerz',
      subtitle: 'কার্ড / নেট ব্যাংকিং',
      icon: Icons.credit_card_rounded,
      color: Color(0xFF1565C0),
    ),
    (
      id: 'cash',
      label: 'ক্যাশ অন ডেলিভারি',
      subtitle: 'পণ্য পেলে পরিশোধ',
      icon: Icons.payments_outlined,
      color: Color(0xFF2E7D32),
    ),
  ];

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _confirmOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ডেলিভারি ঠিকানা দিন'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPlacing = true);
    try {
      final placedOrders =
          await ref.read(marketplaceProvider.notifier).placeOrders(
                paymentMethod: _selectedPayment,
                deliveryAddress: _addressController.text.trim(),
              );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRouter.orderConfirmation,
        arguments: placedOrders,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অর্ডার দেওয়া যায়নি। আবার চেষ্টা করুন।'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceProvider);
    final cart = state.cart;
    final subtotal =
        cart.fold<double>(0, (sum, e) => sum + e.product.price * e.quantity);
    const deliveryFee = 60.0;
    final total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('পেমেন্ট',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            title: 'অর্ডার সারসংক্ষেপ',
            child: Column(
              children: [
                ...cart.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item.product.primaryImage != null
                                ? Image.network(
                                    item.product.primaryImage!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _imgFallback(),
                                  )
                                : _imgFallback(),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                Text('${item.quantity} ${item.product.unit}',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(
                            '৳${(item.product.price * item.quantity).toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    )),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 4),
                _PriceRow(label: 'পণ্যের মূল্য', amount: subtotal),
                const SizedBox(height: 6),
                _PriceRow(
                    label: 'ডেলিভারি চার্জ',
                    amount: deliveryFee,
                    amountColor: Colors.grey.shade700),
                const SizedBox(height: 10),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 6),
                _PriceRow(
                  label: 'সর্বমোট',
                  amount: total,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A)),
                  amountStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'ডেলিভারি ঠিকানা',
            child: TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'বাড়ি নম্বর, রাস্তা, এলাকা, জেলা লিখুন...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAF8),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppTheme.primaryGreen, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'পেমেন্ট পদ্ধতি',
            child: Column(
              children: _paymentOptions.map((option) {
                final isSelected = _selectedPayment == option.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPayment = option.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? option.color.withValues(alpha: 0.06)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? option.color : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: option.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              Icon(option.icon, color: option.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(option.label,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isSelected
                                          ? option.color
                                          : const Color(0xFF1A1A1A))),
                              Text(option.subtitle,
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? option.color
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                            color:
                                isSelected ? option.color : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 12)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isPlacing ? null : _confirmOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isPlacing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        ),
                        SizedBox(width: 12),
                        Text('অর্ডার দেওয়া হচ্ছে...',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : Text('৳${total.toStringAsFixed(0)} পরিশোধ করুন',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
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

  Widget _imgFallback() => Container(
        width: 48,
        height: 48,
        color: Colors.grey.shade100,
        child:
            Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 24),
      );
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final TextStyle? labelStyle;
  final Color? amountColor;
  final TextStyle? amountStyle;

  const _PriceRow({
    required this.label,
    required this.amount,
    this.labelStyle,
    this.amountColor,
    this.amountStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: labelStyle ??
                TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        Text('৳${amount.toStringAsFixed(0)}',
            style: amountStyle ??
                TextStyle(
                  color: amountColor ?? const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                )),
      ],
    );
  }
}
