import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import 'email_otp_screen.dart';

// ── Brand constants (theme-invariant) ─────────────────────────────────────────
const _kPrimary  = Color(0xFFFF8132);
const _kError    = Color(0xFFFF4D4D);
const _kSuccess  = Color(0xFF4CAF50);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Page 1
  final _usernameController = TextEditingController();
  final _nameController     = TextEditingController();

  // Page 2
  final _emailController    = TextEditingController();
  final _mobileController   = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword     = true;
  bool _emailValid          = false;

  // Page 3
  DateTime? _dob;

  // Page 4
  String? _gender;
  File?   _selfie;
  bool    _agreeToTerms     = false;
  bool    _agreeToDisclosure = false;

  int _page = 0;

  final _picker      = ImagePicker();
  final _authService = AuthService();

  // Username check state
  bool   _usernameChecking = false;
  bool?  _usernameAvailable;
  String? _usernameMessage;
  List<String> _usernameSuggestions = [];
  Timer? _usernameDebounce;
  int    _usernameCheckSeq = 0;

  // Email availability check state
  bool   _emailChecking = false;
  bool?  _emailAvailable;
  String? _emailTakenMessage;
  Timer? _emailDebounce;
  int    _emailCheckSeq = 0;

  // OTP state
  bool    _emailOtpVerified = false;
  String? _emailToken;

  late final AnimationController _fadeCtrl;

  // ── Theme-aware color getters ───────────────────────────────────────────────
  ColorScheme get _cs => Theme.of(context).colorScheme;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // Page/scaffold background
  Color get _surface => _cs.surface;

  // Card / input container background
  Color get _cardBg => _isDark ? const Color(0xFF131927) : _cs.surfaceContainerHighest;

  // Border color
  Color get _border => _cs.outline;

  // Primary text
  Color get _textColor => _cs.onSurface;

  // Secondary / hint text
  Color get _subtextColor => _cs.onSurfaceVariant;

  // ── Init / Dispose ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _emailController.addListener(() {
      final text = _emailController.text.trim();
      final valid = _isValidEmail(text);
      if (valid != _emailValid) setState(() => _emailValid = valid);
      _onEmailChanged(text);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email);

  bool _isValidMobile(String mobile) =>
      mobile.isEmpty || RegExp(r'^\d{10}$').hasMatch(mobile);

  int get _passwordStrength {
    final p = _passwordController.text;
    int s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) s++;
    return s;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _kError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Username check ─────────────────────────────────────────────────────────

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    if (value.trim().isEmpty) {
      _usernameCheckSeq++;
      setState(() {
        _usernameChecking = false;
        _usernameAvailable = null;
        _usernameMessage = null;
        _usernameSuggestions = [];
      });
      return;
    }
    setState(() {
      _usernameChecking = true;
      _usernameAvailable = null;
      _usernameMessage = null;
      _usernameSuggestions = [];
    });
    _usernameDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _checkUsername(value),
    );
  }

  Future<void> _checkUsername(String value) async {
    final seq = ++_usernameCheckSeq;
    final result = await _authService.checkUsernameAvailability(value);
    if (!mounted || seq != _usernameCheckSeq) return;
    final available = result['available'] == true;
    final msg = result['message']?.toString() ?? '';
    setState(() {
      _usernameChecking  = false;
      _usernameAvailable = available;
      _usernameMessage   = available
          ? (msg.isNotEmpty ? msg : 'Username is available')
          : (msg == 'Username is taken' ? 'Username not available' : (msg.isNotEmpty ? msg : 'Username not available'));
    });
    if (!available) _loadSuggestions(value);
  }

  Future<void> _loadSuggestions(String value) async {
    final s = await _authService.getUsernameSuggestions(value);
    if (!mounted) return;
    setState(() => _usernameSuggestions = s);
  }

  void _useSuggestion(String s) {
    _usernameController.text = s;
    _onUsernameChanged(s);
  }

  // ── Email availability check ────────────────────────────────────────────────

  void _onEmailChanged(String value) {
    _emailDebounce?.cancel();
    if (!_isValidEmail(value)) {
      _emailCheckSeq++;
      setState(() {
        _emailChecking = false;
        _emailAvailable = null;
        _emailTakenMessage = null;
      });
      return;
    }
    setState(() {
      _emailChecking = true;
      _emailAvailable = null;
      _emailTakenMessage = null;
    });
    _emailDebounce = Timer(
      const Duration(milliseconds: 600),
      () => _checkEmail(value),
    );
  }

  Future<void> _checkEmail(String value) async {
    final seq = ++_emailCheckSeq;
    final result = await _authService.checkEmailAvailability(value);
    if (!mounted || seq != _emailCheckSeq) return;
    final available = result['available'] != false;
    final msg = result['message']?.toString() ?? '';
    setState(() {
      _emailChecking = false;
      _emailAvailable = available;
      _emailTakenMessage = available ? null : (msg.isNotEmpty ? msg : 'Email is already registered');
    });
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  bool _validatePage1() {
    if (_usernameController.text.trim().isEmpty) {
      _showError('Please enter a username'); return false;
    }
    if (_usernameAvailable != true) {
      _showError(_usernameMessage ?? 'Please choose an available username'); return false;
    }
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your profile name'); return false;
    }
    return true;
  }

  bool _validatePage2() {
    if (!_emailValid) {
      _showError('Please enter a valid email address'); return false;
    }
    if (_emailAvailable == false) {
      _showError(_emailTakenMessage ?? 'Email is already registered'); return false;
    }
    final mob = _mobileController.text.trim();
    if (!_isValidMobile(mob)) {
      _showError('Mobile number must be exactly 10 digits'); return false;
    }
    if (_passwordController.text.length < 8) {
      _showError('Password must be at least 8 characters'); return false;
    }
    if (!RegExp(r'[A-Z]').hasMatch(_passwordController.text)) {
      _showError('Password must contain at least one uppercase letter'); return false;
    }
    if (!RegExp(r'[0-9]').hasMatch(_passwordController.text)) {
      _showError('Password must contain at least one number'); return false;
    }
    return true;
  }

  bool _validatePage3() {
    if (_dob == null) { _showError('Please select your date of birth'); return false; }
    final age = DateTime.now().difference(_dob!).inDays ~/ 365;
    if (age < 18) { _showError('You must be at least 18 years old'); return false; }
    return true;
  }

  bool _validatePage4() {
    if (_selfie == null) { _showError('Please take a live selfie'); return false; }
    if (_gender == null) { _showError('Please select your gender'); return false; }
    if (!_agreeToTerms) { _showError('Please agree to Terms & Privacy Policy'); return false; }
    if (!_agreeToDisclosure) { _showError('Please accept the disclosure'); return false; }
    return true;
  }

  // ── OTP flow ───────────────────────────────────────────────────────────────

  Future<void> _goToNextPageAfterOtp() async {
    final email = _emailController.text.trim();
    setState(() => _emailOtpVerified = false);
    bool otpSent = false;
    try {
      await _authService.sendEmailOtp(email);
      otpSent = true;
    } on DioException catch (e) {
      final rawMsg = e.response?.data is Map
          ? e.response!.data['message']?.toString()
          : null;
      // Show user-friendly message (not raw SMTP error) with option to skip
      if (mounted) {
        final skip = await _showOtpFailureDialog();
        if (skip == true && mounted) { _nextPage(); return; }
      }
      debugPrint('OTP send failed: $rawMsg');
    } catch (e) {
      if (mounted) {
        final skip = await _showOtpFailureDialog();
        if (skip == true && mounted) { _nextPage(); return; }
      }
      debugPrint('OTP send error: $e');
    }
    if (!otpSent || !mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.97,
        minChildSize: 0.5,
        builder: (__, _) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: EmailOtpScreen(
            email: email,
            onVerified: (token) {
              setState(() { _emailOtpVerified = true; _emailToken = token; });
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
    if (_emailOtpVerified && mounted) _nextPage();
  }

  Future<bool?> _showOtpFailureDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email verification unavailable'),
        content: const Text(
          'We could not send a verification email right now. '
          'You can continue without email verification or try again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
            child: const Text('Continue anyway'),
          ),
        ],
      ),
    );
  }

  // ── Selfie & DOB ───────────────────────────────────────────────────────────

  Future<void> _pickSelfie() async {
    final img = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );
    if (img != null) setState(() => _selfie = File(img.path));
  }

  Future<void> _pickDOB() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      initialDate: DateTime(2000),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: _kPrimary,
                  surface: _cardBg,
                  onSurface: _textColor,
                )
              : ColorScheme.light(
                  primary: _kPrimary,
                  surface: _surface,
                  onSurface: _textColor,
                ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _dob = d);
  }

  // ── Signup ─────────────────────────────────────────────────────────────────

  Future<void> _handleSignup() async {
    if (!_validatePage4()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final ok = await auth.register(
        _usernameController.text.trim().toLowerCase(),
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _gender ?? '',
        _dob?.toIso8601String() ?? '',
        _selfie?.path ?? '',
        emailToken: _emailToken,
      );
      if (ok && mounted) {
        if (_gender == 'trans_woman') {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              icon: const Icon(Icons.verified_user_outlined, color: _kPrimary, size: 40),
              title: const Text('Verification Pending', textAlign: TextAlign.center),
              content: const Text(
                'We will verify manually, please wait for 10 minutes.\n\nYou can complete your profile while we review your selfie.',
                textAlign: TextAlign.center,
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Complete Profile'),
                  ),
                ),
              ],
            ),
          );
        }
        if (mounted) {
          context.go('/create-profile', extra: {
            'name':     _nameController.text.trim(),
            'username': _usernameController.text.trim().toLowerCase(),
          });
        }
      }
    } catch (e) {
      String msg = 'Signup failed. Try again.';
      if (e is DioException && e.response?.data is Map) {
        final s = (e.response!.data as Map)['message']?.toString();
        if (s != null && s.isNotEmpty) msg = s;
      } else {
        msg = e.toString().replaceFirst('Exception: ', '');
      }
      _showError(msg);
    }
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  Widget _field({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: child,
  );

  InputDecoration _dec({
    required String hint,
    Widget? prefix,
    Widget? prefixIcon,
    Widget? suffix,
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _subtextColor),
        prefixIcon: prefixIcon,
        prefix: prefix,
        suffixIcon: suffixIcon,
        suffix: suffix,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      );

  TextStyle get _fieldStyle => TextStyle(color: _textColor, fontSize: 15);

  Widget _nextBtn({required VoidCallback onPressed, String label = 'Next'}) =>
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _stepDots() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(4, (i) => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _page == i ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _page == i ? _kPrimary : _border,
        borderRadius: BorderRadius.circular(4),
      ),
    )),
  );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textColor, size: 20),
          onPressed: _page == 0
              ? () => context.go('/login')
              : () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _stepDots(),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (v) => setState(() => _page = v),
          children: [
            _pageOne(),
            _pageTwo(),
            _pageThree(),
            _pageFour(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1 — Username & Profile Name
  // ══════════════════════════════════════════════════════════════════════════
  Widget _pageOne() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Create Account',
            style: TextStyle(
              color: _textColor,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a username and your display name',
            style: TextStyle(color: _subtextColor, fontSize: 15),
          ),
          const SizedBox(height: 40),

          // Username
          _field(
            child: TextFormField(
              controller: _usernameController,
              style: _fieldStyle,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              onChanged: _onUsernameChanged,
              decoration: _dec(
                hint: 'Username',
                prefixIcon: Icon(Icons.alternate_email_rounded, color: _subtextColor, size: 20),
                suffixIcon: _usernameChecking
                    ? Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                        ),
                      )
                    : _usernameAvailable == true
                        ? const Icon(Icons.check_circle_rounded, color: _kSuccess, size: 22)
                        : _usernameAvailable == false
                            ? const Icon(Icons.cancel_rounded, color: _kError, size: 22)
                            : null,
              ),
            ),
          ),

          if (_usernameMessage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _usernameAvailable == true ? Icons.check_circle_outline : Icons.info_outline_rounded,
                  size: 15,
                  color: _usernameAvailable == true ? _kSuccess : _kError,
                ),
                const SizedBox(width: 6),
                Text(
                  _usernameMessage!,
                  style: TextStyle(
                    fontSize: 13,
                    color: _usernameAvailable == true ? _kSuccess : _kError,
                  ),
                ),
              ],
            ),
          ],

          if (_usernameSuggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Try:', style: TextStyle(color: _subtextColor, fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _usernameSuggestions
                        .map((s) => GestureDetector(
                              onTap: () => _useSuggestion(s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _kPrimary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
                                ),
                                child: Text('@$s',
                                    style: const TextStyle(
                                      color: _kPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          // Profile Name
          _field(
            child: TextFormField(
              controller: _nameController,
              style: _fieldStyle,
              textCapitalization: TextCapitalization.words,
              decoration: _dec(
                hint: 'Profile Name',
                prefixIcon: Icon(Icons.badge_outlined, color: _subtextColor, size: 20),
              ),
            ),
          ),

          const SizedBox(height: 40),
          _nextBtn(onPressed: () { if (_validatePage1()) _nextPage(); }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 2 — Email, Mobile, Password
  // ══════════════════════════════════════════════════════════════════════════
  Widget _pageTwo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Contact & Security',
            style: TextStyle(color: _textColor, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text('Your email will be verified', style: TextStyle(color: _subtextColor, fontSize: 15)),
          const SizedBox(height: 36),

          // Email
          _field(
            child: TextFormField(
              controller: _emailController,
              style: _fieldStyle,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: _dec(
                hint: 'Email address',
                prefixIcon: Icon(Icons.email_outlined, color: _subtextColor, size: 20),
                suffixIcon: _emailController.text.isEmpty
                    ? null
                    : _emailChecking
                        ? Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                            ),
                          )
                        : _emailAvailable == false
                            ? const Icon(Icons.cancel_rounded, color: _kError, size: 22)
                            : _emailValid
                                ? const Icon(Icons.check_circle_rounded, color: _kSuccess, size: 22)
                                : const Icon(Icons.cancel_rounded, color: _kError, size: 22),
              ),
            ),
          ),

          if (_emailTakenMessage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 15, color: _kError),
                const SizedBox(width: 6),
                Text(
                  _emailTakenMessage!,
                  style: const TextStyle(fontSize: 13, color: _kError),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Mobile — optional, +91 prefix, 10 digits
          _field(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: _border)),
                  ),
                  child: Text('+91', style: TextStyle(color: _textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _mobileController,
                    style: _fieldStyle,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Mobile number (optional)',
                      hintStyle: TextStyle(color: _subtextColor),
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
                      suffixIcon: _mobileController.text.length == 10
                          ? const Icon(Icons.check_circle_rounded, color: _kSuccess, size: 20)
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('10-digit Indian mobile number', style: TextStyle(color: _subtextColor, fontSize: 12)),
          ),

          const SizedBox(height: 16),

          // Password
          _field(
            child: TextFormField(
              controller: _passwordController,
              style: _fieldStyle,
              obscureText: _obscurePassword,
              onChanged: (_) => setState(() {}),
              decoration: _dec(
                hint: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded, color: _subtextColor, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _subtextColor,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ),

          // Password strength
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PasswordStrengthIndicator(password: _passwordController.text),
          ],

          const SizedBox(height: 16),

          // Password requirements
          _PasswordRequirements(password: _passwordController.text),

          const SizedBox(height: 36),
          _nextBtn(
            onPressed: () {
              if (_validatePage2()) _goToNextPageAfterOtp();
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 3 — Date of Birth
  // ══════════════════════════════════════════════════════════════════════════
  Widget _pageThree() {
    final hasDob = _dob != null;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Date of Birth',
            style: TextStyle(color: _textColor, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text('You must be at least 18 years old to join', style: TextStyle(color: _subtextColor, fontSize: 15)),
          const SizedBox(height: 48),

          // DOB display card
          GestureDetector(
            onTap: _pickDOB,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasDob ? _kPrimary.withValues(alpha: 0.5) : _border,
                  width: hasDob ? 1.5 : 1,
                ),
              ),
              child: hasDob
                  ? Column(
                      children: [
                        Text(
                          '${_dob!.day}',
                          style: const TextStyle(color: _kPrimary, fontSize: 64, fontWeight: FontWeight.w900, height: 1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${months[_dob!.month - 1]} ${_dob!.year}',
                          style: TextStyle(color: _textColor, fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${DateTime.now().difference(_dob!).inDays ~/ 365} years old',
                            style: const TextStyle(color: _kPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(Icons.cake_rounded, color: _subtextColor, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to select your birthday',
                          style: TextStyle(color: _subtextColor, fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 24),

          if (hasDob)
            Center(
              child: TextButton(
                onPressed: _pickDOB,
                child: Text('Change date', style: TextStyle(color: _subtextColor)),
              ),
            ),

          SizedBox(height: hasDob ? 16 : 48),
          _nextBtn(onPressed: () { if (_validatePage3()) _nextPage(); }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 4 — Women Verification
  // ══════════════════════════════════════════════════════════════════════════
  Widget _pageFour() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
                ),
                child: const Text('Women Only', style: TextStyle(color: _kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Verify Your Identity',
            style: TextStyle(color: _textColor, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            'SARAN is a safe space for women. A live selfie is used to verify your identity using AI.',
            style: TextStyle(color: _subtextColor, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Selfie area
          Center(
            child: GestureDetector(
              onTap: _pickSelfie,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selfie != null ? _kPrimary : _border,
                        width: 2.5,
                      ),
                    ),
                  ),
                  // Selfie or placeholder
                  CircleAvatar(
                    radius: 84,
                    backgroundColor: _cardBg,
                    backgroundImage: _selfie != null ? FileImage(_selfie!) : null,
                    child: _selfie == null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.face_retouching_natural_rounded, color: _subtextColor, size: 40),
                              const SizedBox(height: 8),
                              Text('Live Selfie', style: TextStyle(color: _subtextColor, fontSize: 12)),
                            ],
                          )
                        : null,
                  ),
                  // Camera badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: _surface, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Center(
            child: Text(
              'Look straight • Good lighting • No filters',
              style: TextStyle(color: _subtextColor, fontSize: 12),
            ),
          ),

          if (_selfie != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _pickSelfie,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retake selfie'),
                style: TextButton.styleFrom(foregroundColor: _subtextColor),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Verification notice (AI for female, manual for trans_woman)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _gender == 'trans_woman' ? Icons.verified_user_outlined : Icons.auto_awesome_rounded,
                  color: _kPrimary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _gender == 'trans_woman'
                        ? 'Your selfie will be reviewed manually by our team within 10 minutes to verify your identity.'
                        : 'Our AI will verify that you are a woman. This selfie is used only for verification and is not stored publicly.',
                    style: TextStyle(color: _subtextColor, fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Gender selection
          Text('I identify as', style: TextStyle(color: _subtextColor, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              _genderChip('Female', 'female', Icons.female_rounded),
              const SizedBox(width: 12),
              _genderChip('Trans Woman', 'trans_woman', Icons.transgender_rounded),
            ],
          ),

          const SizedBox(height: 28),

          // Terms & Privacy
          _CheckRow(
            value: _agreeToTerms,
            onChanged: (v) => setState(() => _agreeToTerms = v),
            child: Wrap(
              children: [
                Text('I agree to the ', style: TextStyle(color: _subtextColor, fontSize: 13)),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('https://saranapp.com/terms-of-use.html'), mode: LaunchMode.externalApplication),
                  child: const Text('Terms of Use',
                      style: TextStyle(color: _kPrimary, fontSize: 13, fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline, decorationColor: _kPrimary)),
                ),
                Text(' and ', style: TextStyle(color: _subtextColor, fontSize: 13)),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('https://saranapp.com/privacy-policy.html'), mode: LaunchMode.externalApplication),
                  child: const Text('Privacy Policy',
                      style: TextStyle(color: _kPrimary, fontSize: 13, fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline, decorationColor: _kPrimary)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Disclosure
          _CheckRow(
            value: _agreeToDisclosure,
            onChanged: (v) => setState(() => _agreeToDisclosure = v),
            child: Text(
              'I understand that SARAN is exclusively for women. I confirm that I am female or a trans woman and that my selfie will be verified by AI to maintain platform safety.',
              style: TextStyle(color: _subtextColor, fontSize: 13, height: 1.4),
            ),
          ),

          const SizedBox(height: 32),

          Consumer<AuthProvider>(
            builder: (_, auth, __) => SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _handleSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Create Account ✦', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderChip(String label, String value, IconData icon) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? _kPrimary.withValues(alpha: 0.15) : _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _kPrimary : _border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? _kPrimary : _subtextColor, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? _kPrimary : _textColor,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// ── Check row ──────────────────────────────────────────────────────────────────
class _CheckRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget child;
  const _CheckRow({required this.value, required this.onChanged, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: (v) => onChanged(v!),
            activeColor: _kPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            side: BorderSide(color: cs.outline, width: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Padding(padding: const EdgeInsets.only(top: 2), child: child)),
      ],
    );
  }
}

// ── Password strength indicator ────────────────────────────────────────────────
class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const _PasswordStrengthIndicator({required this.password});

  int get _score {
    int s = 0;
    if (password.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(password)) s++;
    if (RegExp(r'[0-9]').hasMatch(password)) s++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) s++;
    return s;
  }

  Color _color(int s) => switch (s) {
    1 => const Color(0xFFFF4D4D),
    2 => const Color(0xFFFF8C00),
    3 => const Color(0xFFFFD600),
    _ => const Color(0xFF4CAF50),
  };

  String _label(int s) => switch (s) {
    0 => 'Too short',
    1 => 'Weak',
    2 => 'Fair',
    3 => 'Good',
    _ => 'Strong',
  };

  @override
  Widget build(BuildContext context) {
    final s = _score;
    final color = _color(s);
    final inactiveColor = Theme.of(context).colorScheme.outline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ...List.generate(4, (i) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 5,
                margin: EdgeInsets.only(right: i < 3 ? 5 : 0),
                decoration: BoxDecoration(
                  color: i < s ? color : inactiveColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            )),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _label(s),
                key: ValueKey(s),
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Password requirements checklist ───────────────────────────────────────────
class _PasswordRequirements extends StatelessWidget {
  final String password;
  const _PasswordRequirements({required this.password});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131927) : cs.surfaceContainerHighest;

    final checks = [
      (RegExp(r'.{8,}').hasMatch(password),       'At least 8 characters'),
      (RegExp(r'[A-Z]').hasMatch(password),        'One uppercase letter'),
      (RegExp(r'[0-9]').hasMatch(password),        'One number'),
      (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password), 'One special character (optional)'),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: checks.map((c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Icon(
                c.$1 ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: c.$1 ? _kSuccess : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(c.$2, style: TextStyle(fontSize: 13, color: c.$1 ? cs.onSurface : cs.onSurfaceVariant)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
