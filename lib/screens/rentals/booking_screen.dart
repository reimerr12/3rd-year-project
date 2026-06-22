import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/rental.dart';
import '../../providers/rental_provider.dart';
import '../../services/supabase_service.dart';
import '../../services/payment_service.dart';
import '../payment/bkash_webview_screen.dart';

String _t(bool bn, String bangla, String english) => bn ? bangla : english;

Future<LatLng?> _geocodeLocation(String query) async {
  try {
    final encoded = Uri.encodeComponent(query);
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encoded&region=BD&key=${AppConstants.googleMapsApiKey}';
    final res = await Dio().get(url);
    final body = res.data as Map<String, dynamic>;
    final results = body['results'] as List?;
    if (results == null || results.isEmpty) return null;
    final loc = (results.first as Map)['geometry']['location'];
    return LatLng(
        (loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
  } catch (_) {
    return null;
  }
}

const _kDivisionCoords = {
  'ঢাকা': LatLng(23.8103, 90.4125),
  'চট্টগ্রাম': LatLng(22.3569, 91.7832),
  'রাজশাহী': LatLng(24.3745, 88.6042),
  'খুলনা': LatLng(22.8456, 89.5403),
  'বরিশাল': LatLng(22.7010, 90.3535),
  'সিলেট': LatLng(24.8949, 91.8687),
  'রংপুর': LatLng(25.7439, 89.2752),
  'ময়মনসিংহ': LatLng(24.7471, 90.4203),
  'Dhaka': LatLng(23.8103, 90.4125),
  'Chittagong': LatLng(22.3569, 91.7832),
  'Rajshahi': LatLng(24.3745, 88.6042),
  'Khulna': LatLng(22.8456, 89.5403),
  'Barisal': LatLng(22.7010, 90.3535),
  'Sylhet': LatLng(24.8949, 91.8687),
  'Rangpur': LatLng(25.7439, 89.2752),
  'Mymensingh': LatLng(24.7471, 90.4203),
};

const _kPaymentOptions = [
  (
    id: 'bkash',
    label: 'বিকাশ',
    labelEn: 'bKash',
    subtitle: 'মোবাইল ব্যাংকিং',
    subtitleEn: 'Mobile Banking',
    icon: Icons.phone_android_rounded,
    color: Color(0xFFE2136E),
  ),
  (
    id: 'cash',
    label: 'নগদ অর্থ',
    labelEn: 'Cash on Delivery',
    subtitle: 'সরঞ্জাম পেলে পরিশোধ',
    subtitleEn: 'Pay on equipment handover',
    icon: Icons.payments_outlined,
    color: Color(0xFF2E7D32),
  ),
];

// BOOKING SCREEN
class BookingScreen extends ConsumerStatefulWidget {
  final EquipmentModel equipment;
  final bool bn;

  const BookingScreen({
    super.key,
    required this.equipment,
    this.bn = true,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _notesController = TextEditingController();
  String _selectedPayment = 'bkash';
  bool _isLoading = false;

  List<BookingModel> _existingBookings = [];
  bool _bookingsLoading = true;
  Set<DateTime> _bookedDates = {};

  static final _dateFmt = DateFormat('d MMM yyyy');
  static final _currencyFmt =
      NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 0);

  EquipmentModel get eq => widget.equipment;
  bool get bn => widget.bn;

  @override
  void initState() {
    super.initState();
    _loadExistingBookings();
  }

  Future<void> _loadExistingBookings() async {
    try {
      final bookings =
          await SupabaseService.instance.fetchEquipmentBookings(eq.id);
      final bookedDates = <DateTime>{};
      for (final b in bookings) {
        DateTime cur = b.startDate;
        while (!cur.isAfter(b.endDate)) {
          bookedDates.add(DateTime(cur.year, cur.month, cur.day));
          cur = cur.add(const Duration(days: 1));
        }
      }
      if (mounted) {
        setState(() {
          _existingBookings = bookings;
          _bookedDates = bookedDates;
          _bookingsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _bookingsLoading = false);
    }
  }

  bool _isDateBooked(DateTime day) =>
      _bookedDates.contains(DateTime(day.year, day.month, day.day));

  bool _rangeOverlapsBooking(DateTime start, DateTime end) {
    DateTime cur = start;
    while (!cur.isAfter(end)) {
      if (_isDateBooked(cur)) return true;
      cur = cur.add(const Duration(days: 1));
    }
    return false;
  }

  int get _durationDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  double get _totalCost => eq.ratePerDay * _durationDays;

  bool get _canBook =>
      _startDate != null &&
      _endDate != null &&
      _durationDays >= eq.minBookingDays;

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final firstDate = isStart ? now : (_startDate ?? now);
    final initialDate = isStart
        ? (_startDate ?? now)
        : (_endDate ?? firstDate.add(Duration(days: eq.minBookingDays - 1)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
      selectableDayPredicate: (day) => !_isDateBooked(day),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryGreen,
            onSurface: AppTheme.darkGreen,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
        if (_endDate != null && _rangeOverlapsBooking(picked, _endDate!)) {
          _endDate = null;
        }
      } else {
        if (_startDate != null && _rangeOverlapsBooking(_startDate!, picked)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_t(
              bn,
              'নির্বাচিত পরিসরে বুকড তারিখ রয়েছে। অনুগ্রহ করে আবার নির্বাচন করুন।',
              'Your selected range includes already-booked dates. Please choose again.',
            )),
            backgroundColor: AppTheme.errorRed,
          ));
          return;
        }
        _endDate = picked;
      }
    });
  }

  // Main confirm handler
  Future<void> _confirmBooking() async {
    if (!_canBook) return;
    if (_selectedPayment == 'bkash') {
      await _confirmWithBkash();
    } else {
      await _confirmDirect();
    }
  }

  // bKash flow
  Future<void> _confirmWithBkash() async {
    setState(() => _isLoading = true);

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final invoiceNo = BkashPaymentService.generateInvoiceNumber('RNT');
      final paymentResult = await BkashPaymentService().initiate(
        amount: _totalCost,
        invoiceNumber: invoiceNo,
      );

      setState(() => _isLoading = false);

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

      setState(() => _isLoading = true);

      ref.invalidate(myBookingsProvider);

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccessDialog(trxId: trxId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      messenger.showSnackBar(SnackBar(
        content:
            Text('${_t(bn, "পেমেন্ট ব্যর্থ হয়েছে", "Payment failed")}: $e'),
        backgroundColor: AppTheme.errorRed,
      ));
    }
  }

  // Cash flow
  Future<void> _confirmDirect() async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.instance.placeBooking(
        equipmentId: eq.id,
        ratePerDay: eq.ratePerDay,
        startDate: _startDate!,
        endDate: _endDate!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        paymentMethod: _selectedPayment,
      );
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${_t(bn, "বুকিং ব্যর্থ হয়েছে", "Booking failed")}: $e'),
        backgroundColor: AppTheme.errorRed,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Success dialog
  void _showSuccessDialog({String? trxId}) {
    final nav = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Text(_t(bn, 'বুকিং সফল!', 'Booking Confirmed!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bn
                  ? '${eq.name} সফলভাবে বুক করা হয়েছে।\n'
                      '${_dateFmt.format(_startDate!)} — ${_dateFmt.format(_endDate!)}\n'
                      'মোট: ${_currencyFmt.format(_totalCost)}'
                  : '${eq.name} has been booked successfully.\n'
                      '${_dateFmt.format(_startDate!)} — ${_dateFmt.format(_endDate!)}\n'
                      'Total: ${_currencyFmt.format(_totalCost)}',
            ),
            if (trxId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2136E).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFE2136E).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text('💳', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t(bn, 'বিকাশ ট্র্যানজেকশন আইডি',
                                'bKash Transaction ID'),
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFFE2136E)),
                          ),
                          Text(
                            trxId,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE2136E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              nav.pop();
              nav.pop();
            },
            child: Text(
              _t(bn, 'ঠিক আছে', 'OK'),
              style: const TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _openMapSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EquipmentMapSheet(equipment: eq, bn: bn),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption =
        _kPaymentOptions.firstWhere((o) => o.id == _selectedPayment);
    final buttonColor = selectedOption.color;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _t(bn, 'সরঞ্জাম বুকিং', 'Equipment Booking'),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EquipmentSummaryCard(
              equipment: eq,
              bn: bn,
              onViewMap: (eq.locationText != null || eq.division != null)
                  ? _openMapSheet
                  : null,
            ),
            const SizedBox(height: 20),

            if (_bookingsLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_existingBookings.isNotEmpty) ...[
              _SectionHeader(
                  title: _t(bn, 'বুকড তারিখসমূহ', 'Already Booked Dates')),
              const SizedBox(height: 8),
              _BookedDatesList(bookings: _existingBookings, bn: bn),
              const SizedBox(height: 20),
            ],

            _SectionHeader(
                title: _t(bn, 'তারিখ নির্বাচন করুন', 'Select Dates')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DatePickerTile(
                    label: _t(bn, 'শুরুর তারিখ', 'Start Date'),
                    placeholder: _t(bn, 'নির্বাচন করুন', 'Select'),
                    date: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerTile(
                    label: _t(bn, 'শেষের তারিখ', 'End Date'),
                    placeholder: _t(bn, 'নির্বাচন করুন', 'Select'),
                    date: _endDate,
                    onTap: () => _pickDate(isStart: false),
                    enabled: _startDate != null,
                  ),
                ),
              ],
            ),
            if (_startDate != null && _durationDays < eq.minBookingDays)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _t(
                    bn,
                    'সর্বনিম্ন ${eq.minBookingDays} দিনের বুকিং প্রয়োজন',
                    'Minimum ${eq.minBookingDays} day booking required',
                  ),
                  style:
                      const TextStyle(color: AppTheme.errorRed, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),

            _SectionHeader(title: _t(bn, 'খরচের সারসংক্ষেপ', 'Cost Summary')),
            const SizedBox(height: 8),
            _CostSummaryCard(
              ratePerDay: eq.ratePerDay,
              durationDays: _durationDays,
              totalCost: _totalCost,
              bn: bn,
            ),
            const SizedBox(height: 20),

            _buildCard(
              title: _t(bn, 'পেমেন্ট পদ্ধতি', 'Payment Method'),
              child: Column(
                children: _kPaymentOptions.map((option) {
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
                          color:
                              isSelected ? option.color : Colors.grey.shade200,
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
                            child: Icon(option.icon,
                                color: option.color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bn ? option.label : option.labelEn,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isSelected
                                        ? option.color
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                                Text(
                                  bn ? option.subtitle : option.subtitleEn,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
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
                              color: isSelected
                                  ? option.color
                                  : Colors.transparent,
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

            // bKash sandbox hint
            if (_selectedPayment == 'bkash') ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 15, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'স্যান্ডবক্স: ওয়ালেট 01770618575 · PIN 12121 · OTP 123456',
                        style: TextStyle(fontSize: 11, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Notes
            _SectionHeader(
                title: _t(bn, 'মন্তব্য (ঐচ্ছিক)', 'Notes (optional)')),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _t(
                  bn,
                  'কোনো বিশেষ চাহিদা জানান...',
                  'Any special requirements...',
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.primaryGreen, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Confirm button — color matches selected payment
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_canBook && !_isLoading) ? _confirmBooking : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: buttonColor.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        _canBook
                            ? (_selectedPayment == 'bkash'
                                ? '${_t(bn, "বিকাশে পেমেন্ট করুন", "Pay with bKash")} — ${_currencyFmt.format(_totalCost)}'
                                : '${_t(bn, "বুকিং নিশ্চিত করুন", "Confirm Booking")} — ${_currencyFmt.format(_totalCost)}')
                            : _t(bn, 'তারিখ নির্বাচন করুন', 'Select Dates'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
}

// ===========================================================================
// EQUIPMENT MAP SHEET
// ===========================================================================

class _EquipmentMapSheet extends StatefulWidget {
  final EquipmentModel equipment;
  final bool bn;
  const _EquipmentMapSheet({required this.equipment, required this.bn});

  @override
  State<_EquipmentMapSheet> createState() => _EquipmentMapSheetState();
}

class _EquipmentMapSheetState extends State<_EquipmentMapSheet> {
  LatLng? _coords;
  bool _loading = true;
  bool _approximate = false;
  GoogleMapController? _mapController;

  EquipmentModel get eq => widget.equipment;
  bool get bn => widget.bn;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    final parts = <String>[
      if (eq.locationText != null && eq.locationText!.isNotEmpty)
        eq.locationText!,
      if (eq.division != null && eq.division!.isNotEmpty) eq.division!,
      'Bangladesh',
    ];
    final coords = await _geocodeLocation(parts.join(', '));
    if (mounted) {
      setState(() {
        _coords = coords ?? _divisionFallback();
        _approximate = coords == null;
        _loading = false;
      });
    }
  }

  LatLng _divisionFallback() =>
      _kDivisionCoords[eq.division] ?? const LatLng(23.8103, 90.4125);

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.borderGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on,
                      color: AppTheme.primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(eq.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (eq.locationText != null || eq.division != null)
                        Text(
                          [eq.locationText, eq.division]
                              .whereType<String>()
                              .join(', '),
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (_approximate && !_loading)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _t(
                        bn,
                        'সঠিক অবস্থান পাওয়া যায়নি। বিভাগের আনুমানিক অবস্থান দেখানো হচ্ছে।',
                        'Exact location not found. Showing approximate division centre.',
                      ),
                      style: const TextStyle(fontSize: 11, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                            color: AppTheme.primaryGreen),
                        const SizedBox(height: 12),
                        Text(
                          _t(bn, 'অবস্থান খুঁজছে...', 'Finding location...'),
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : _coords == null
                    ? Center(
                        child: Text(
                          _t(bn, 'মানচিত্রে অবস্থান দেখানো সম্ভব হয়নি',
                              'Unable to show location on map'),
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(24)),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _coords!,
                            zoom: _approximate ? 10 : 14,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId(eq.id),
                              position: _coords!,
                              infoWindow: InfoWindow(
                                title: eq.name,
                                snippet: eq.locationText ??
                                    eq.division ??
                                    'Bangladesh',
                              ),
                            ),
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: true,
                          mapToolbarEnabled: false,
                          onMapCreated: (c) => _mapController = c,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SUB-WIDGETS (unchanged)
// ===========================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.darkGreen,
      ),
    );
  }
}

class _EquipmentSummaryCard extends StatelessWidget {
  final EquipmentModel equipment;
  final bool bn;
  final VoidCallback? onViewMap;

  const _EquipmentSummaryCard({
    required this.equipment,
    required this.bn,
    this.onViewMap,
  });

  static final _fmt =
      NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 0);

  String _typeLabel(String type) => bn
      ? (EquipmentType.fromValue(type)?.labelBn ?? type)
      : (EquipmentType.fromValue(type)?.labelEn ?? type);

  IconData _equipmentIcon(String type) {
    switch (type) {
      case 'tractor':
        return Icons.agriculture;
      case 'truck':
        return Icons.local_shipping;
      case 'pump':
        return Icons.water;
      default:
        return Icons.construction;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _equipmentIcon(equipment.type),
                  color: AppTheme.primaryGreen,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(equipment.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(_typeLabel(equipment.type),
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary)),
                    if (equipment.locationText != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            equipment.locationText!,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],
                    if (equipment.ownerPhone != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.phone,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 2),
                        Text(equipment.ownerPhone!,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ]),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmt.format(equipment.ratePerDay),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  Text(_t(bn, '/দিন', '/day'),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          if (onViewMap != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onViewMap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_outlined,
                        size: 16, color: Color(0xFF1A73E8)),
                    const SizedBox(width: 6),
                    Text(
                      _t(bn, 'মানচিত্রে অবস্থান দেখুন', 'View Location on Map'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookedDatesList extends StatelessWidget {
  final List<BookingModel> bookings;
  final bool bn;
  const _BookedDatesList({required this.bookings, required this.bn});

  static final _fmt = DateFormat('d MMM yyyy');

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'active':
        return AppTheme.primaryGreen;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _statusLabel(String status, bool bn) {
    switch (status) {
      case 'pending':
        return bn ? 'অপেক্ষমাণ' : 'Pending';
      case 'confirmed':
        return bn ? 'নিশ্চিত' : 'Confirmed';
      case 'active':
        return bn ? 'সক্রিয়' : 'Active';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.block,
                    size: 14, color: AppTheme.errorRed.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _t(bn, 'এই তারিখগুলো ক্যালেন্ডারে অনুপলব্ধ থাকবে',
                        'These dates are unavailable in the calendar'),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.errorRed.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...bookings.map((b) {
            final color = _statusColor(b.status);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month,
                      size: 15, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_fmt.format(b.startDate)}  →  ${_fmt.format(b.endDate)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      _statusLabel(b.status, bn),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final String placeholder;
  final DateTime? date;
  final VoidCallback onTap;
  final bool enabled;

  const _DatePickerTile({
    required this.label,
    required this.placeholder,
    required this.date,
    required this.onTap,
    this.enabled = true,
  });

  static final _fmt = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? AppTheme.primaryGreen : AppTheme.borderGrey,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                )),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.calendar_today,
                  size: 15,
                  color: date != null
                      ? AppTheme.primaryGreen
                      : AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                date != null ? _fmt.format(date!) : placeholder,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      date != null ? FontWeight.w600 : FontWeight.normal,
                  color: date != null
                      ? AppTheme.darkGreen
                      : AppTheme.textSecondary,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _CostSummaryCard extends StatelessWidget {
  final double ratePerDay;
  final int durationDays;
  final double totalCost;
  final bool bn;

  const _CostSummaryCard({
    required this.ratePerDay,
    required this.durationDays,
    required this.totalCost,
    required this.bn,
  });

  static final _fmt =
      NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          _CostRow(
            label: _t(bn, 'প্রতিদিনের ভাড়া', 'Daily Rate'),
            value: _fmt.format(ratePerDay),
          ),
          const SizedBox(height: 6),
          _CostRow(
            label: _t(bn, 'মোট দিন', 'Total Days'),
            value: durationDays > 0
                ? '$durationDays ${_t(bn, "দিন", "days")}'
                : '—',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3), height: 1),
          ),
          _CostRow(
            label: _t(bn, 'মোট খরচ', 'Total Cost'),
            value: durationDays > 0 ? _fmt.format(totalCost) : '—',
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _CostRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
            color: isTotal ? AppTheme.darkGreen : AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? AppTheme.primaryGreen : AppTheme.darkGreen,
          ),
        ),
      ],
    );
  }
}
