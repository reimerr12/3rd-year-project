import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/lang_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../services/supabase_service.dart';

String _t(bool bn, String bangla, String english) => bn ? bangla : english;

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
  final List<XFile> _pickedImages = [];
  bool _isUploadingImages = false;

  static const int _maxImages = 3;

  List<({String key, String labelBn, String labelEn})> get _categories => [
        (key: 'crop', labelBn: 'ফসল', labelEn: 'Crops'),
        (key: 'fertilizer', labelBn: 'সার', labelEn: 'Fertilizer'),
        (key: 'insecticide', labelBn: 'কীটনাশক', labelEn: 'Insecticide'),
        (key: 'tool', labelBn: 'সরঞ্জাম', labelEn: 'Tools'),
        (key: 'other', labelBn: 'অন্যান্য', labelEn: 'Other'),
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

  Future<void> _pickImages(bool bn) async {
    if (_pickedImages.length >= _maxImages) return;

    final picker = ImagePicker();
    final remaining = _maxImages - _pickedImages.length;

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
              title: Text(_t(bn, 'ক্যামেরা', 'Camera')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.primaryGreen),
              title: Text(_t(bn, 'গ্যালারি', 'Gallery')),
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
        final picked = await picker.pickMultiImage(imageQuality: 80);
        if (picked.isEmpty) return;
        setState(() {
          _pickedImages.addAll(picked.take(remaining));
        });
      } else {
        final picked = await picker.pickImage(source: source, imageQuality: 80);
        if (picked == null) return;
        setState(() => _pickedImages.add(picked));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _t(bn, 'ছবি নির্বাচন করা যায়নি।', 'Could not select image.')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

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

  Future<void> _submit(bool bn) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final imageUrls = await _uploadImages();

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
          content: Text(_t(
            bn,
            '"${_titleController.text.trim()}" বাজারে যোগ করা হয়েছে!',
            '"${_titleController.text.trim()}" has been listed in the market!',
          )),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t(bn, 'পণ্য যোগ করা যায়নি। আবার চেষ্টা করুন।',
              'Could not add product. Please try again.')),
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
    final bn = ref.watch(langProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        title: Text(
          _t(bn, 'পণ্য বিক্রি করুন', 'Sell a Product'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
            _buildImagePicker(bn),
            const SizedBox(height: 20),
            _buildCard(
              title: _t(bn, 'পণ্যের তথ্য', 'Product Details'),
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: _t(bn, 'পণ্যের নাম *', 'Product Name *'),
                  hint: _t(bn, 'যেমন: আমন ধান, ইউরিয়া সার',
                      'e.g. Aman Rice, Urea Fertilizer'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? _t(bn, 'পণ্যের নাম দিন', 'Enter product name')
                      : null,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _descController,
                  label: _t(bn, 'বিবরণ', 'Description'),
                  hint: _t(bn, 'পণ্য সম্পর্কে বিস্তারিত লিখুন...',
                      'Write details about the product...'),
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                _buildDropdown(bn),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: _t(bn, 'মূল্য ও স্টক', 'Price & Stock'),
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _priceController,
                        label: _t(bn, 'মূল্য (৳) *', 'Price (Taka) *'),
                        hint: '0',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return _t(bn, 'মূল্য দিন', 'Enter price');
                          }
                          final parsed = double.tryParse(v);
                          if (parsed == null || parsed <= 0) {
                            return _t(
                                bn, 'সঠিক মূল্য দিন', 'Enter a valid price');
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
                        label: _t(bn, 'একক *', 'Unit *'),
                        hint: _t(bn, 'কেজি, প্যাকেট...', 'kg, packet...'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? _t(bn, 'একক দিন', 'Enter unit')
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _stockController,
                  label: _t(bn, 'স্টক পরিমাণ *', 'Stock Quantity *'),
                  hint: '0',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return _t(bn, 'স্টক দিন', 'Enter stock');
                    }
                    if (int.tryParse(v) == null || int.parse(v) < 0) {
                      return _t(
                          bn, 'সঠিক স্টক দিন', 'Enter a valid stock amount');
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
                onPressed: (_isSubmitting || _isUploadingImages)
                    ? null
                    : () => _submit(bn),
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
                                ? _t(bn, 'ছবি আপলোড হচ্ছে...',
                                    'Uploading images...')
                                : _t(bn, 'প্রকাশ হচ্ছে...', 'Publishing...'),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      )
                    : Text(
                        _t(bn, 'পণ্য প্রকাশ করুন', 'Publish Product'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Image picker widget ────────────────────────────────────

  Widget _buildImagePicker(bool bn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_pickedImages.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pickedImages.length +
                  (_pickedImages.length < _maxImages ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == _pickedImages.length) {
                  return _buildAddMoreTile(bn);
                }
                return _buildImageThumbnail(index, bn);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              bn,
              '${_pickedImages.length}/$_maxImages ছবি যোগ করা হয়েছে',
              '${_pickedImages.length}/$_maxImages image(s) added',
            ),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ] else
          GestureDetector(
            onTap: () => _pickImages(bn),
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
                  Text(
                    _t(bn, 'ছবি যোগ করুন', 'Add Photos'),
                    style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  Text(
                    _t(bn, 'সর্বোচ্চ $_maxImages টি ছবি',
                        'Maximum $_maxImages photos'),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageThumbnail(int index, bool bn) {
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
              child: Text(
                _t(bn, 'মূল', 'Main'),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddMoreTile(bool bn) {
    return GestureDetector(
      onTap: () => _pickImages(bn),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined,
                color: AppTheme.primaryGreen, size: 26),
            const SizedBox(height: 4),
            Text(
              _t(bn, 'যোগ করুন', 'Add More'),
              style:
                  const TextStyle(color: AppTheme.primaryGreen, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared form widgets ────────────────────────────────────

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

  Widget _buildDropdown(bool bn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(bn, 'ধরন *', 'Category *'),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          items: _categories
              .map((c) => DropdownMenuItem(
                    value: c.key,
                    child: Text(bn ? c.labelBn : c.labelEn),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
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
