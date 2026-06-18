import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/lang_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../services/payment_service.dart';
import '../payment/bkash_webview_screen.dart';

String _t(bool bn, String bangla, String english) => bn ? bangla : english;

String _price(bool bn, double amount) =>
    bn ? '৳${amount.toStringAsFixed(0)}' : 'Taka ${amount.toStringAsFixed(0)}';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedPayment = 'bkash';
  final _addressController = TextEditingController();
  bool _isPlacing = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  List<
      ({
        String id,
        String labelBn,
        String labelEn,
        String subtitleBn,
        String subtitleEn,
        IconData icon,
        Color color
      })> get _paymentOptions => [
        (
          id: 'bkash',
          labelBn: 'বিকাশ',
          labelEn: 'bKash',
          subtitleBn: 'মোবাইল ব্যাংকিং',
          subtitleEn: 'Mobile Banking',
          icon: Icons.phone_android_rounded,
          color: const Color(0xFFE2136E),
        ),
        (
          id: 'cash',
          labelBn: 'ক্যাশ অন ডেলিভারি',
          labelEn: 'Cash on Delivery',
          subtitleBn: 'পণ্য পেলে পরিশোধ',
          subtitleEn: 'Pay when you receive',
          icon: Icons.payments_outlined,
          color: const Color(0xFF2E7D32),
        ),
      ];

  Future<void> _confirmOrder(bool bn) async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _t(bn, 'ডেলিভারি ঠিকানা দিন', 'Please enter a delivery address')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedPayment == 'bkash') {
      await _confirmWithBkash(bn);
    } else {
      await _confirmDirect(bn);
    }
  }

  Future<void> _confirmWithBkash(bool bn) async {
    final cart = ref.read(marketplaceProvider).cart;
    if (cart.isEmpty) return;

    final total =
        cart.fold<double>(0, (sum, e) => sum + e.product.price * e.quantity) +
            60.0;

    setState(() => _isPlacing = true);

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final invoiceNo = BkashPaymentService.generateInvoiceNumber('MKT');
      final paymentResult = await BkashPaymentService().initiate(
        amount: total,
        invoiceNumber: invoiceNo,
      );

      setState(() => _isPlacing = false);

      final trxId = await nav.push<String>(
        MaterialPageRoute(
          builder: (_) => BkashWebViewScreen(
            bkashUrl: paymentResult.bkashUrl,
            paymentId: paymentResult.paymentId,
            bn: bn,
          ),
        ),
      );

      if (trxId == null) return;

      setState(() => _isPlacing = true);

      final placedOrders =
          await ref.read(marketplaceProvider.notifier).placeOrders(
                paymentMethod: 'bkash',
                deliveryAddress: _addressController.text.trim(),
                transactionId: trxId,
              );

      if (!mounted) return;
      setState(() => _isPlacing = false);

      nav.pushReplacementNamed(
        AppRouter.orderConfirmation,
        arguments: placedOrders,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacing = false);
      messenger.showSnackBar(
        SnackBar(
          content:
              Text(_t(bn, 'পেমেন্ট ব্যর্থ হয়েছে: $e', 'Payment failed: $e')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDirect(bool bn) async {
    setState(() => _isPlacing = true);

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final placedOrders =
          await ref.read(marketplaceProvider.notifier).placeOrders(
                paymentMethod: _selectedPayment,
                deliveryAddress: _addressController.text.trim(),
              );
      if (!mounted) return;
      setState(() => _isPlacing = false);

      nav.pushReplacementNamed(
        AppRouter.orderConfirmation,
        arguments: placedOrders,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacing = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_t(bn, 'অর্ডার দেওয়া যায়নি। আবার চেষ্টা করুন।',
              'Could not place order. Please try again.')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(langProvider);
    final state = ref.watch(marketplaceProvider);
    final cart = state.cart;
    final subtotal =
        cart.fold<double>(0, (sum, e) => sum + e.product.price * e.quantity);
    const deliveryFee = 60.0;
    final total = subtotal + deliveryFee;

    final selectedOption =
        _paymentOptions.firstWhere((o) => o.id == _selectedPayment);
    final buttonColor = selectedOption.color;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t(bn, 'পেমেন্ট', 'Payment'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Order summary ─────────────────────────────────────
          _buildCard(
            title: _t(bn, 'অর্ডার সারসংক্ষেপ', 'Order Summary'),
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
                                Text(
                                  '${item.quantity} ${item.product.unit}',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _price(bn, item.product.price * item.quantity),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    )),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 4),
                _PriceRow(
                  label: _t(bn, 'পণ্যের মূল্য', 'Product Price'),
                  amount: subtotal,
                  bn: bn,
                ),
                const SizedBox(height: 6),
                _PriceRow(
                  label: _t(bn, 'ডেলিভারি চার্জ', 'Delivery Fee'),
                  amount: deliveryFee,
                  bn: bn,
                  amountColor: Colors.grey.shade700,
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 6),
                _PriceRow(
                  label: _t(bn, 'সর্বমোট', 'Grand Total'),
                  amount: total,
                  bn: bn,
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

          // ── Delivery address ──────────────────────────────────
          _buildCard(
            title: _t(bn, 'ডেলিভারি ঠিকানা', 'Delivery Address'),
            child: TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _t(
                  bn,
                  'বাড়ি নম্বর, রাস্তা, এলাকা, জেলা লিখুন...',
                  'House no., road, area, district...',
                ),
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

          // ── Payment method ────────────────────────────────────
          _buildCard(
            title: _t(bn, 'পেমেন্ট পদ্ধতি', 'Payment Method'),
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
                              Text(
                                bn ? option.labelBn : option.labelEn,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isSelected
                                        ? option.color
                                        : const Color(0xFF1A1A1A)),
                              ),
                              Text(
                                bn ? option.subtitleBn : option.subtitleEn,
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 12),
                              ),
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

          // ── bKash sandbox hint ────────────────────────────────
          if (_selectedPayment == 'bkash') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 15, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t(
                        bn,
                        'স্যান্ডবক্স: ওয়ালেট 01770618575 · PIN 12121 · OTP 123456',
                        'Sandbox: Wallet 01770618575 · PIN 12121 · OTP 123456',
                      ),
                      style: const TextStyle(fontSize: 11, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),

          // ── Confirm button ────────────────────────────────────
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isPlacing ? null : () => _confirmOrder(bn),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isPlacing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _t(bn, 'অর্ডার দেওয়া হচ্ছে...', 'Placing order...'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : Text(
                      _selectedPayment == 'bkash'
                          ? _t(
                              bn,
                              'বিকাশে পেমেন্ট করুন — ${_price(bn, total)}',
                              'Pay with bKash — ${_price(bn, total)}',
                            )
                          : _t(
                              bn,
                              '${_price(bn, total)} পরিশোধ করুন',
                              'Pay ${_price(bn, total)}',
                            ),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
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
  final bool bn;
  final TextStyle? labelStyle;
  final Color? amountColor;
  final TextStyle? amountStyle;

  const _PriceRow({
    required this.label,
    required this.amount,
    required this.bn,
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
        Text(
          bn
              ? '৳${amount.toStringAsFixed(0)}'
              : 'Taka ${amount.toStringAsFixed(0)}',
          style: amountStyle ??
              TextStyle(
                color: amountColor ?? const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
        ),
      ],
    );
  }
}
