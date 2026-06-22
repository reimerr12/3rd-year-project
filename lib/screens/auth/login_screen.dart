import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../services/supabase_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _usePhone = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleMethod(bool usePhone) {
    if (_usePhone == usePhone) return;
    setState(() {
      _usePhone = usePhone;
      _errorMessage = null;
    });
    _animController.forward(from: 0);
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = SupabaseService();

      if (_usePhone) {
        final phone = _phoneController.text.trim();
        if (phone.isEmpty) {
          setState(() => _errorMessage = 'ফোন নম্বর দিন');
          return;
        }
        await service.requestPhoneOtp(phone);
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRouter.otp,
            arguments: {'phone': phone},
          );
        }
      } else {
        final email = _emailController.text.trim().toLowerCase();
        if (email.isEmpty) {
          setState(() => _errorMessage = 'ইমেইল দিন');
          return;
        }
        final emailRegex = RegExp(r'^[a-z0-9._]+@[a-z0-9.-]+\.[a-z]{2,}$');
        if (!emailRegex.hasMatch(email)) {
          setState(() => _errorMessage = 'সঠিক ইমেইল দিন');
          return;
        }
        await service.requestEmailOtp(email);
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRouter.otp,
            arguments: {'email': email},
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('network')) return 'ইন্টারনেট সংযোগ নেই';
    if (raw.contains('too many') || raw.contains('rate')) {
      return 'অনেকবার চেষ্টা হয়েছে, একটু অপেক্ষা করুন';
    }
    if (raw.contains('invalid') || raw.contains('Invalid')) {
      return 'সঠিক তথ্য দিন';
    }
    return 'কিছু একটা সমস্যা হয়েছে, আবার চেষ্টা করুন';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'কৃষিবন্ধু',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'আপনার কৃষি সহায়ক',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 40),

              // Toggle
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _ToggleButton(
                      label: 'ফোন',
                      icon: Icons.phone_outlined,
                      active: _usePhone,
                      onTap: () => _toggleMethod(true),
                    ),
                    _ToggleButton(
                      label: 'ইমেইল',
                      icon: Icons.email_outlined,
                      active: !_usePhone,
                      onTap: () => _toggleMethod(false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Animated form
              FadeTransition(
                opacity: _fadeAnim,
                child: _usePhone ? _buildPhoneForm() : _buildEmailForm(),
              ),
              const SizedBox(height: 12),

              // Error
              if (_errorMessage != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 20),

              // Submit
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'OTP পাঠান',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ফোন নম্বর',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))
          ],
          decoration: _inputDecoration(
            hint: '+8801XXXXXXXXX',
            icon: Icons.phone_outlined,
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 8),
        const Text(
          'আপনার নম্বরে একটি OTP কোড পাঠানো হবে',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ইমেইল',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(
            hint: 'name@example.com',
            icon: Icons.email_outlined,
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 8),
        const Text(
          'আপনার ইমেইলে একটি OTP কোড পাঠানো হবে',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? AppTheme.primaryGreen : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppTheme.primaryGreen : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
