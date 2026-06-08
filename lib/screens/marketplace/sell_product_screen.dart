import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/marketplace_provider.dart';
import '../../services/supabase_service.dart';

class SellProductScreen extends ConsumerStatefulWidget {
  const SellProductScreen({super.key});

  @override
  ConsumerState<SellProductScreen> createState() => _SellProductScreenState();
}

class _SellProductScreenState extends ConsumerState<SellProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();
  final _stockController = TextEditingController();

  String _selectedCategory = 'crop';
  bool _isSubmitting = false;

  /// Picked image files (max 3)
  final List<XFile> _pickedImages = [];

  /// Upload progress flag — separate from _isSubmitting so UI is granular
  bool _isUploadingImages = false;

  static const int _maxImages = 3;

  static const _categories = [
    ('crop', 'ফসল'),
    ('fertilizer', 'সার'),
    ('insecticide', 'কীটনাশক'),
    ('tool', 'সরঞ্জাম'),
    ('other', 'অন্যান্য'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // ── Image picking ──────────────────────────────────────────

  Future<void> _pickImages() async {
    if (_pickedImages.length >= _maxImages) return;

    final picker = ImagePicker();
    final remaining = _maxImages - _pickedImages.length;

    // Show bottom sheet: camera or gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppTheme.primaryGreen),
              title: const Text('ক্যামেরা'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.primaryGreen),
              title: const Text('গ্যালারি'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      if (source == ImageSource.gallery && remaining > 1) {
        // Multi-pick from gallery when slots remain
        final picked = await picker.pickMultiImage(imageQuality: 80);
        if (picked.isEmpty) return;
        setState(() {
          _pickedImages.addAll(
            picked.take(remaining),
          );
        });
      } else {
        final picked = await picker.pickImage(source: source, imageQuality: 80);
        if (picked == null) return;
        setState(() => _pickedImages.add(picked));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ছবি নির্বাচন করা যায়নি।'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  // ── Upload all picked images to Supabase Storage ───────────

  Future<List<String>> _uploadImages() async {
    if (_pickedImages.isEmpty) return [];
    setState(() => _isUploadingImages = true);

    final service = SupabaseService();
    final urls = <String>[];

    for (final xfile in _pickedImages) {
      final bytes = await xfile.readAsBytes();
      final ext = xfile.name.split('.').last.toLowerCase();
      final url = await service.uploadProductImage(bytes, ext);
      urls.add(url);
    }

    setState(() => _isUploadingImages = false);
    return urls;
  }

  // ── Form submit ────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      // 1. Upload images first (returns [] if none picked)
      final imageUrls = await _uploadImages();

      // 2. Delegate to provider — addProduct calls SupabaseService.createProduct
      await ref.read(marketplaceProvider.notifier).addProduct(
            title: _titleController.text.trim(),
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            category: _selectedCategory,
            price: double.parse(_priceController.text.trim()),
            unit: _unitController.text.trim(),
            stock: int.parse(_stockController.text.trim()),
            images: imageUrls,
          );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.market,
        (route) => route.settings.name == AppRouter.home,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('"${_titleController.text.trim()}" বাজারে যোগ করা হয়েছে!'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('পণ্য যোগ করা যায়নি। আবার চেষ্টা করুন।'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        title: const Text('পণ্য বিক্রি করুন',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 20),
            _buildCard(
              title: 'পণ্যের তথ্য',
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: 'পণ্যের নাম *',
                  hint: 'যেমন: আমন ধান, ইউরিয়া সার',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'পণ্যের নাম দিন' : null,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _descController,
                  label: 'বিবরণ',
                  hint: 'পণ্য সম্পর্কে বিস্তারিত লিখুন...',
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                _buildDropdown<String>(
                  label: 'ধরন *',
                  value: _selectedCategory,
                  items: _categories
                      .map((c) =>
                          DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'মূল্য ও স্টক',
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _priceController,
                        label: 'মূল্য (৳) *',
                        hint: '০',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'মূল্য দিন';
                          final parsed = double.tryParse(v);
                          if (parsed == null || parsed <= 0) {
                            return 'সঠিক মূল্য দিন';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _unitController,
                        label: 'একক *',
                        hint: 'কেজি, প্যাকেট...',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'একক দিন' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _stockController,
                  label: 'স্টক পরিমাণ *',
                  hint: '০',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'স্টক দিন';
                    if (int.tryParse(v) == null || int.parse(v) < 0) {
                      return 'সঠিক স্টক দিন';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed:
                    (_isSubmitting || _isUploadingImages) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: (_isSubmitting || _isUploadingImages)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isUploadingImages
                                ? 'ছবি আপলোড হচ্ছে...'
                                : 'প্রকাশ হচ্ছে...',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      )
                    : const Text('পণ্য প্রকাশ করুন',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Image picker widget ────────────────────────────────────

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail row (shown only when images exist)
        if (_pickedImages.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pickedImages.length +
                  (_pickedImages.length < _maxImages ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                // "Add more" tile at the end
                if (index == _pickedImages.length) {
                  return _buildAddMoreTile();
                }
                return _buildImageThumbnail(index);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_pickedImages.length}/$_maxImages ছবি যোগ করা হয়েছে',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ] else
          // Empty state — full-width tap target
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_photo_alternate_outlined,
                        color: AppTheme.primaryGreen, size: 30),
                  ),
                  const SizedBox(height: 10),
                  const Text('ছবি যোগ করুন',
                      style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text('সর্বোচ্চ $_maxImages টি ছবি',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageThumbnail(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(_pickedImages[index].path),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        // Primary badge on first image
        if (index == 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('মূল',
                  style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
      ],
    );
  }

  Widget _buildAddMoreTile() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: AppTheme.primaryGreen, size: 26),
            SizedBox(height: 4),
            Text('যোগ করুন',
                style: TextStyle(color: AppTheme.primaryGreen, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ── Shared form widgets (unchanged) ───────────────────────

  Widget _buildCard({required String title, required List<Widget> children}) {
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
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAF8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide:
              const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAF8),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              borderSide:
                  const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
            ),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppTheme.primaryGreen),
        ),
      ],
    );
  }
}
