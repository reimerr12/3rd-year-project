import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../services/supabase_service.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(8, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(8, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 60;

  String? _phone;
  String? _email;

  bool get _isEmail => _email != null;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _phone = args?['phone'] as String?;
    _email = args?['email'] as String?;
  }

  void _startCountdown() async {
    while (mounted && _resendCountdown > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _resendCountdown--);
    }
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    if (value.length == 1 && index < 7) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_otpCode.length == 8) {
      _verify();
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  Future<void> _verify() async {
    final code = _otpCode;
    if (code.length < 8) {
      setState(() => _errorMessage = '৮ সংখ্যার কোড দিন');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = SupabaseService();
      AppUser? user;

      if (_isEmail) {
        user = await service.verifyEmailOtp(_email!, code);
      } else {
        user = await service.verifyPhoneOtp(_phone!, code);
      }

      if (!mounted) return;

      if (user == null || user.name.isEmpty) {
        Navigator.pushNamed(
          context,
          AppRouter.register,
          arguments: {
            if (_phone != null) 'phone': _phone,
            if (_email != null) 'email': _email,
            'isNew': true,
          },
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.home,
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0) return;
    setState(() => _isResending = true);
    try {
      final service = SupabaseService();
      if (_isEmail) {
        await service.requestEmailOtp(_email!);
      } else {
        await service.requestPhoneOtp(_phone!);
      }
      setState(() => _resendCountdown = 60);
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('নতুন OTP পাঠানো হয়েছে'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'পুনরায় পাঠাতে ব্যর্থ হয়েছে');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('Invalid') || raw.contains('invalid')) {
      return 'কোডটি ভুল, আবার চেষ্টা করুন';
    }
    if (raw.contains('expired')) return 'কোডটির মেয়াদ শেষ, নতুন কোড নিন';
    if (raw.contains('network')) return 'ইন্টারনেট সংযোগ নেই';
    return 'কিছু একটা সমস্যা হয়েছে';
  }

  String get _maskedDestination {
    if (_isEmail) {
      final parts = _email!.split('@');
      if (parts.length == 2) {
        final name = parts[0];
        final masked =
            name.length > 2 ? '${name.substring(0, 2)}***' : '${name[0]}***';
        return '$masked@${parts[1]}';
      }
      return _email!;
    }
    if (_phone != null && _phone!.length >= 4) {
      return '******${_phone!.substring(_phone!.length - 4)}';
    }
    return _phone ?? '';
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _isEmail
                      ? Icons.mark_email_read_outlined
                      : Icons.sms_outlined,
                  color: AppTheme.primaryGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'OTP যাচাই করুন',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_maskedDestination ${_isEmail ? 'ইমেইলে' : 'নম্বরে'} একটি ৮ সংখ্যার কোড পাঠানো হয়েছে',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 36),

              // 8 OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  8,
                  (i) => _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    onChanged: (v) => _onDigitEntered(i, v),
                    onBackspace: () => _onBackspace(i),
                  ),
                ),
              ),

              const SizedBox(height: 12),

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

              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verify,
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
                          'যাচাই করুন',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: _resendCountdown > 0
                    ? Text(
                        'পুনরায় পাঠান ($_resendCountdown সেকেন্ড)',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                      )
                    : TextButton(
                        onPressed: _isResending ? null : _resend,
                        child: _isResending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryGreen,
                                ),
                              )
                            : const Text(
                                'OTP পুনরায় পাঠান',
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 48,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
