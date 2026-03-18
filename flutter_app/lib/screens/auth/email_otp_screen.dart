import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';

/// Shows after page 2 of signup.
/// User enters the 6-digit OTP sent to [email].
/// On success, calls [onVerified] with the emailToken from the backend
/// so the signup flow can pass it to register().
class EmailOtpScreen extends StatefulWidget {
  final String email;
  final void Function(String emailToken) onVerified;

  const EmailOtpScreen({
    super.key,
    required this.email,
    required this.onVerified,
  });

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final AuthService _authService = AuthService();

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _resending = false;
  String? _error;

  int _resendCountdown = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    final code = _otp;
    if (code.length < 6) {
      setState(() => _error = 'Please enter the full 6-digit code.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _authService.verifyEmailOtp(widget.email, code);
      final success = result['success'] == true || result['verified'] == true;
      if (success) {
        final token = result['emailToken']?.toString() ?? '';
        widget.onVerified(token);
      } else {
        setState(() => _error = result['message']?.toString() ?? 'Invalid code. Try again.');
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response!.data['message']?.toString()
          : null;
      setState(() => _error = msg ?? 'Verification failed. Check your connection.');
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await _authService.sendEmailOtp(widget.email);
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code has been sent.')),
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response!.data['message']?.toString()
          : null;
      if (mounted) {
        setState(() => _error = msg ?? 'Could not resend. Try again.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not resend. Try again.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Widget _buildDigitBox(int index, ColorScheme scheme) {
    return SizedBox(
      width: 46,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: scheme.onSurface),
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.length == 1 && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() => _error = null);
          // Auto-submit when last digit is entered
          if (index == 5 && value.isNotEmpty) {
            _verify();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read_outlined,
                size: 64, color: scheme.primary),
            const SizedBox(height: 24),
            const Text(
              'Verify your email',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'We sent a 6-digit code to\n${widget.email}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 36),

            // OTP digit boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => _buildDigitBox(i, scheme)),
            ),

            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: TextStyle(color: scheme.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Verify',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Resend
            GestureDetector(
              onTap: _resendCountdown == 0 ? _resend : null,
              child: _resending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _resendCountdown > 0
                          ? 'Resend code in ${_resendCountdown}s'
                          : 'Resend code',
                      style: TextStyle(
                        fontSize: 14,
                        color: _resendCountdown == 0
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        fontWeight: _resendCountdown == 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
