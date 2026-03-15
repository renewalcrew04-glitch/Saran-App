import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _pageController = PageController();

  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();

  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  final bool _obscureConfirmPassword = true;

  bool _agreeToTerms = false;

  String? _gender;
  DateTime? _dob;

  File? _selfie;

  int _page = 0;

  final picker = ImagePicker();
  final AuthService _authService = AuthService();

  bool _usernameChecking = false;
  bool? _usernameAvailable;
  String? _usernameMessage;
  List<String> _usernameSuggestions = [];
  Timer? _usernameDebounce;

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
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
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () => _checkUsername(value));
  }

  Future<void> _checkUsername(String value) async {
    final result = await _authService.checkUsernameAvailability(value);
    if (!mounted) return;
    final available = result['available'] == true;
    final backendMessage = result['message']?.toString() ?? '';
    setState(() {
      _usernameChecking = false;
      _usernameAvailable = available;
      // When taken or invalid, show a clear message; otherwise use backend message
      if (available) {
        _usernameMessage = backendMessage.isNotEmpty ? backendMessage : 'Username is available';
      } else {
        _usernameMessage = backendMessage == 'Username is taken'
            ? 'Username not available'
            : (backendMessage.isNotEmpty ? backendMessage : 'Username not available');
      }
    });
    // Load suggestions whenever username is not available (taken or invalid pattern)
    if (_usernameAvailable == false) {
      _loadSuggestions(value);
    }
  }

  Future<void> _loadSuggestions(String value) async {
    final suggestions = await _authService.getUsernameSuggestions(value);
    if (!mounted) return;
    setState(() => _usernameSuggestions = suggestions);
  }

  void _useSuggestion(String suggestion) {
    _usernameController.text = suggestion;
    _onUsernameChanged(suggestion);
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _validatePage1() {
    final uname = _usernameController.text.trim();
    if (uname.isEmpty) {
      _showError("Please enter a username");
      return false;
    }
    if (_usernameAvailable != true) {
      _showError(_usernameMessage ?? "Please choose an available username");
      return false;
    }

    if (_nameController.text.trim().isEmpty) {
      _showError("Please enter your full name");
      return false;
    }

    return true;
  }

  bool _validatePage2() {
    if (_emailController.text.trim().isEmpty) {
      _showError("Please enter your email");
      return false;
    }

    if (!_emailController.text.contains("@")) {
      _showError("Enter a valid email");
      return false;
    }

    if (_passwordController.text.length < 6) {
      _showError("Password must be at least 6 characters");
      return false;
    }

    return true;
  }

  bool _validatePage3() {
    if (_dob == null) {
      _showError("Please select your date of birth");
      return false;
    }

    return true;
  }

  bool _validatePage4() {
    if (_selfie == null) {
      _showError("Please take a selfie for verification");
      return false;
    }

    if (_gender == null) {
      _showError("Please select your gender");
      return false;
    }

    if (!_agreeToTerms) {
      _showError("Please agree to the Terms and Privacy Policy");
      return false;
    }

    return true;
  }

  Future<void> _pickSelfie() async {
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selfie = File(image.path);
      });
    }
  }

  Future<void> _pickDOB() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );

    if (date != null) {
      setState(() {
        _dob = date;
      });
    }
  }

  Future<void> _handleSignup() async {
    if (!_validatePage4()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.register(
        _usernameController.text.trim().toLowerCase(),
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _gender ?? '',
        _dob?.toIso8601String() ?? '',
        _selfie?.path ?? '',
      );

      if (success && mounted) {
        context.go('/home');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Widget glossyField({required Widget child}) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: child,
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
        leading: _page == 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/login'),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                },
              ),
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (v) => setState(() => _page = v),
          children: [
            _pageOne(scheme),
            _pageTwo(scheme),
            _pageThree(scheme),
            _pageFour(scheme),
          ],
        ),
      ),
    );
  }

  /// PAGE 1
  Widget _pageOne(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Create Account",
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            glossyField(
              child: TextFormField(
                controller: _usernameController,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                onChanged: _onUsernameChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  hintText: "Username",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(18),
                  suffixIcon: _usernameChecking
                      ? const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _usernameAvailable == true
                          ? Icon(Icons.check_circle, color: scheme.primary, size: 22)
                          : _usernameAvailable == false
                              ? Icon(Icons.cancel, color: scheme.error, size: 22)
                              : null,
                ),
              ),
            ),
            if (_usernameMessage != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      _usernameAvailable == true ? Icons.check_circle_outline : Icons.info_outline,
                      size: 16,
                      color: _usernameAvailable == true
                          ? scheme.primary
                          : _usernameAvailable == false
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _usernameMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _usernameAvailable == true
                              ? scheme.primary
                              : _usernameAvailable == false
                                  ? scheme.error
                                  : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_usernameSuggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      "Try:",
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    ..._usernameSuggestions.map(
                      (s) => InkWell(
                        onTap: () => _useSuggestion(s),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '@$s',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            glossyField(
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.badge_outlined),
                  hintText: "Full Name",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(18),
                ),
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                if (_validatePage1()) {
                  _nextPage();
                }
              },
              child: const Text("Next"),
            )
          ],
        ),
      ),
    );
  }

  /// PAGE 2
  Widget _pageTwo(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            glossyField(
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: "Email",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(18),
                ),
              ),
            ),

            const SizedBox(height: 18),

            glossyField(
              child: TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: "Mobile (optional)",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(18),
                ),
              ),
            ),

            const SizedBox(height: 18),

            glossyField(
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  hintText: "Password",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(18),
                ),
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                if (_validatePage2()) {
                  _nextPage();
                }
              },
              child: const Text("Next"),
            )
          ],
        ),
      ),
    );
  }

  /// PAGE 3 DOB
  Widget _pageThree(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              "Your Birthday",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            glossyField(
              child: ListTile(
                leading: const Icon(Icons.cake_outlined),
                title: Text(
                  _dob == null
                      ? "Select Date of Birth"
                      : "${_dob!.day}/${_dob!.month}/${_dob!.year}",
                ),
                onTap: _pickDOB,
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                if (_validatePage3()) {
                  _nextPage();
                }
              },
              child: const Text("Next"),
            )
          ],
        ),
      ),
    );
  }

  /// PAGE 4
  Widget _pageFour(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const Text(
              "Verify Yourself",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            Center(
              child: GestureDetector(
                onTap: _pickSelfie,
                child: CircleAvatar(
                  radius: 65,
                  backgroundColor: scheme.surfaceContainerHighest,
                  backgroundImage: _selfie != null ? FileImage(_selfie!) : null,
                  child: _selfie == null
                      ? Icon(Icons.camera_alt,
                          size: 32, color: scheme.primary)
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 30),

            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: InputDecoration(
                labelText: "Gender",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: const [
                DropdownMenuItem(value: "female", child: Text("Female")),
                DropdownMenuItem(value: "trans_woman", child: Text("Trans Woman")),
                DropdownMenuItem(value: "male", child: Text("Male")),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),

            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (v) => setState(() => _agreeToTerms = v!),
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      children: [

                        const TextSpan(text: "I agree to the "),

                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () async {
                              await launchUrl(
                                Uri.parse(
                                    "https://saranapp.com/terms-of-use.html"),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            child: Text(
                              "Terms of Use",
                              style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),

                        const TextSpan(text: " and "),

                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () async {
                              await launchUrl(
                                Uri.parse(
                                    "https://saranapp.com/privacy-policy.html"),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            child: Text(
                              "Privacy Policy",
                              style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),

                        const TextSpan(
                          text:
                              ". SARAN is committed to maintaining a safe and respectful environment for women.",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Consumer<AuthProvider>(
              builder: (_, auth, __) => SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: auth.isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}