import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../features/settings/screens/close_friends_screen.dart';
import '../../features/settings/services/settings_api.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sos_provider.dart';
import '../../services/sos_service.dart';

// ── Design tokens ──────────────────────────────────────────────────────────
// Functional red colors kept as-is (brand/emergency color)
const _kRed        = Color(0xFFE53935);
const _kRedLight   = Color(0xFFEF5350);
const _kRedDark    = Color(0xFFB71C1C);
const _kRedBorder  = Color(0xFFEF5350);
// Dark-only variants for label and selected-card background
// (used with isDark checks in build methods)
const _kLabelDark    = Color(0xFFEF5350);
const _kActiveBgDark = Color(0xFF1A0A0A);

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with TickerProviderStateMixin {
  bool _sendToCloseFriends = true;
  bool _sendToNearby       = false;
  bool _isSending          = false;

  int _closeFriendsCount = 0;
  final _settingsApi = SettingsApi();

  final _situationCtrl = TextEditingController();

  // ── Animation controllers ─────────────────────────────────────────────
  // Three sonar-ripple rings staggered evenly across the 2 s cycle.
  // Each ring goes 0→1 independently; stagger = 2000 / 3 ≈ 667 ms.
  static const _ringMs  = 2000;
  static const _stagger = _ringMs ~/ 3;          // 667 ms

  AnimationController? _ring1;
  AnimationController? _ring2;
  AnimationController? _ring3;

  // Gentle button-breathe: scale 1.0 ↔ 1.05 at 1.4 s
  AnimationController? _breatheCtrl;
  Animation<double>?   _breatheAnim;

  @override
  void initState() {
    super.initState();

    // ── Ripple rings ──────────────────────────────────────────────────
    final dur = Duration(milliseconds: _ringMs);

    _ring1 = AnimationController(vsync: this, duration: dur)..repeat();
    _ring2 = AnimationController(vsync: this, duration: dur)..repeat();
    _ring3 = AnimationController(vsync: this, duration: dur)..repeat();

    // Offset each ring so they're evenly distributed in time
    Future.delayed(Duration(milliseconds: _stagger),     () { if (mounted) _ring2?.repeat(); });
    Future.delayed(Duration(milliseconds: _stagger * 2), () { if (mounted) _ring3?.repeat(); });

    // Pre-advance rings 2 & 3 so they start at the right phase immediately
    _ring2?.value = _stagger / _ringMs;
    _ring3?.value = (_stagger * 2) / _ringMs;

    // ── Button breathe ────────────────────────────────────────────────
    final bc = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _breatheCtrl = bc;
    _breatheAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: bc, curve: Curves.easeInOut),
    );

    _loadCloseFriends();
  }

  @override
  void dispose() {
    _ring1?.dispose();
    _ring2?.dispose();
    _ring3?.dispose();
    _breatheCtrl?.dispose();
    _situationCtrl.dispose();
    super.dispose();
  }

  // ── Load close friends count ───────────────────────────────────────────
  Future<void> _loadCloseFriends() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    _settingsApi.setToken(auth.token!);
    try {
      final list = await _settingsApi.getCloseFriends();
      if (mounted) setState(() => _closeFriendsCount = list.length);
    } catch (_) {
      if (mounted) setState(() => _closeFriendsCount = 0);
    }
  }

  // ── Location ───────────────────────────────────────────────────────────
  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _error("Location services are disabled");
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _error("Location permission denied");
      return false;
    }
    return true;
  }

  // ── Send SOS ───────────────────────────────────────────────────────────
  Future<void> _sendSOS() async {
    final sosProvider = context.read<SosProvider>();
    if (sosProvider.isActive) { _error("SOS already active"); return; }
    if (!_sendToCloseFriends && !_sendToNearby) {
      _error("Select at least one alert option"); return;
    }
    if (_sendToCloseFriends && _closeFriendsCount == 0) {
      _error("No close friends added"); return;
    }

    setState(() => _isSending = true);
    final token     = context.read<AuthProvider>().token;
    final messenger = ScaffoldMessenger.of(context);

    try {
      Position? position;
      if (_sendToNearby) {
        if (!await _ensureLocationPermission()) return;
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
      }

      final payload = {
        "sendToCloseFriends": _sendToCloseFriends,
        "sendToNearby":       _sendToNearby,
        "message":            _situationCtrl.text.trim(),
        "location": position == null
            ? null
            : {"lat": position.latitude, "lng": position.longitude},
        "radiusKm": _sendToNearby ? 2 : null,
      };

      if (!mounted) return;
      final response = await SosService.sendSOS(token, payload);
      if (!mounted) return;

      sosProvider.activate(response["sosId"] as String);
      messenger.showSnackBar(const SnackBar(
        content: Text("Emergency alert sent"),
        backgroundColor: _kRed,
      ));
    } catch (e) {
      final msg = e is Exception
          ? e.toString().replaceFirst("Exception: ", "").trim()
          : "Failed to send SOS";
      if (msg.startsWith("ALREADY_ACTIVE:")) {
        final id = msg.replaceFirst("ALREADY_ACTIVE:", "").trim();
        if (id.isNotEmpty) sosProvider.activate(id);
        if (mounted) {
          setState(() {});
          messenger.showSnackBar(const SnackBar(
            content: Text("SOS already active. Tap to cancel."),
            backgroundColor: Colors.orange,
          ));
        }
        return;
      }
      _error(msg);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Cancel SOS ─────────────────────────────────────────────────────────
  Future<void> _cancelSOS() async {
    final sosProvider = context.read<SosProvider>();
    if (sosProvider.sosId == null) return;
    final token     = context.read<AuthProvider>().token;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SosService.cancelSOS(token, sosProvider.sosId!);
      sosProvider.deactivate();
      if (mounted) messenger.showSnackBar(
        const SnackBar(content: Text("SOS cancelled")),
      );
    } catch (e) {
      _error(e is Exception
          ? e.toString().replaceFirst("Exception: ", "").trim()
          : "Failed to cancel SOS");
    }
  }

  void _error(String msg) {
    final short = msg.length > 100 ? '${msg.substring(0, 100)}…' : msg;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(short), backgroundColor: Colors.red),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sosActive = context.watch<SosProvider>().isActive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bg = isDark ? const Color(0xFF0A0005) : Theme.of(context).scaffoldBackgroundColor;
    final card = isDark ? const Color(0xFF110810) : cs.surfaceContainerLow;
    final border = isDark ? const Color(0xFF1E1520) : cs.outlineVariant;
    final text = isDark ? const Color(0xFFF1F5F9) : cs.onSurface;
    final muted = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;
    final label = isDark ? _kLabelDark : cs.error;
    final activeBg = isDark ? _kActiveBgDark : cs.errorContainer.withOpacity(0.15);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            children: [
              // ── "EMERGENCY SOS" label ──────────────────────────────────
              Text(
                'EMERGENCY SOS',
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),

              const SizedBox(height: 32),

              // ── SOS sonar-ripple button ────────────────────────────────
              _SosPulseButton(
                ring1:     _ring1     ?? const AlwaysStoppedAnimation(0.0),
                ring2:     _ring2     ?? const AlwaysStoppedAnimation(0.33),
                ring3:     _ring3     ?? const AlwaysStoppedAnimation(0.67),
                breathe:   _breatheAnim ?? const AlwaysStoppedAnimation(1.0),
                isSending: _isSending,
                isActive:  sosActive,
                onTap: sosActive ? _cancelSOS : _sendSOS,
              ),

              const SizedBox(height: 32),

              // ── Headline ───────────────────────────────────────────────
              Text(
                sosActive ? 'SOS is Active' : 'Your safety is\nour priority',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: text,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                sosActive
                    ? 'Tap the button above to cancel the alert'
                    : 'Press the button to send an\nemergency alert to your trusted circle',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // ── Top row cards: Close Friends | Nearby Users ────────────
              Row(
                children: [
                  Expanded(
                    child: _OptionCard(
                      icon: '🤝',
                      title: 'Close Friends',
                      subtitle: _closeFriendsCount == 0
                          ? 'No friends added'
                          : '$_closeFriendsCount ${_closeFriendsCount == 1 ? "person" : "people"}',
                      selected: _sendToCloseFriends,
                      disabled: sosActive,
                      onTap: () {
                        if (sosActive) return;
                        if (!_sendToCloseFriends && _closeFriendsCount == 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CloseFriendsScreen(),
                            ),
                          ).then((_) => _loadCloseFriends());
                          return;
                        }
                        setState(() => _sendToCloseFriends = !_sendToCloseFriends);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OptionCard(
                      icon: '📍',
                      title: 'Nearby Users',
                      subtitle: 'Within 2km',
                      selected: _sendToNearby,
                      disabled: sosActive,
                      onTap: () {
                        if (!sosActive) {
                          setState(() => _sendToNearby = !_sendToNearby);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Full-width: Share Live Location ────────────────────────
              _OptionCard(
                icon: '🗺️',
                title: 'Share Live Location',
                subtitle: 'Real-time GPS tracking to trusted contacts',
                selected: _sendToNearby || _sendToCloseFriends,
                disabled: sosActive,
                fullWidth: true,
                onTap: () {},
              ),

              // ── Describe Situation + Send/Cancel (inactive only) ──────
              if (!sosActive) ...[
                const SizedBox(height: 24),

                // Label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DESCRIBE SITUATION (OPTIONAL)',
                    style: TextStyle(
                      color: label,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Text area
                TextField(
                  controller: _situationCtrl,
                  maxLines: 4,
                  minLines: 4,
                  style: TextStyle(color: text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tell us what\'s happening...',
                    hintStyle: TextStyle(color: muted, fontSize: 14),
                    filled: true,
                    fillColor: card,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: border, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _kRedBorder, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Send Emergency Alert button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: _isSending ? null : _sendSOS,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF5350), Color(0xFFB71C1C)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _kRed.withValues(alpha: 0.40),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _isSending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Send Emergency Alert',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Cancel text button
                GestureDetector(
                  onTap: () => _situationCtrl.clear(),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Cancel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],

              // ── Active SOS cancel hint ─────────────────────────────────
              if (sosActive) ...[
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _cancelSOS,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: _kRedBorder, width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                      color: activeBg,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Cancel SOS',
                      style: TextStyle(
                        color: _kRedBorder,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── SOS sonar-ripple button ────────────────────────────────────────────────
// Mirrors HTML: sos-circle-outer (static soft ring) + 3 staggered sonar rings
// that expand from the button edge outward and fade, matching the CSS ripple.
class _SosPulseButton extends StatelessWidget {
  /// Each ring is an Animation<double> going 0 → 1 on repeat.
  final Animation<double> ring1;
  final Animation<double> ring2;
  final Animation<double> ring3;
  /// Gentle scale breathe for the inner button (1.0 ↔ 1.05).
  final Animation<double> breathe;
  final bool isSending;
  final bool isActive;
  final VoidCallback onTap;

  const _SosPulseButton({
    required this.ring1,
    required this.ring2,
    required this.ring3,
    required this.breathe,
    required this.isSending,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ring1, ring2, ring3, breathe]),
      builder: (_, __) {
        return GestureDetector(
          onTap: isSending ? null : onTap,
          child: SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(
              painter: _SonarPainter(
                r1: ring1.value,
                r2: ring2.value,
                r3: ring3.value,
              ),
              child: Center(
                child: Transform.scale(
                  scale: breathe.value,
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFEF5350), Color(0xFFC62828)],
                        center: Alignment(-0.3, -0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kRed.withValues(alpha: 0.55),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: _kRed.withValues(alpha: 0.25),
                          blurRadius: 48,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: isSending
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            isActive ? '✕' : 'SOS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Paints the static outer-glow disc (sos-circle-outer in HTML) plus
/// three staggered sonar rings that expand outward and fade to nothing.
class _SonarPainter extends CustomPainter {
  /// Each value is 0.0 → 1.0 (ring lifetime progress).
  final double r1, r2, r3;

  const _SonarPainter({required this.r1, required this.r2, required this.r3});

  // Button radius in logical px (half of 112 px button)
  static const double _btnR    = 56.0;
  // Max ripple radius
  static const double _maxR    = 116.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ── Static sos-circle-outer: soft red disc + subtle border ────────────
    // background: rgba(239,68,68,0.08)
    canvas.drawCircle(
      center, 96,
      Paint()
        ..color = _kRed.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    // border-color: rgba(239,68,68,0.20)
    canvas.drawCircle(
      center, 96,
      Paint()
        ..color = _kRed.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── Three sonar ripple rings ───────────────────────────────────────────
    // Each ring starts at _btnR (button edge), expands to _maxR, fades out.
    // Easing: ease-out expansion (fast start, slow end) via sqrt curve.
    for (final t in [r1, r2, r3]) {
      final eased  = _easeOut(t);                          // 0 → 1 eased
      final radius = _btnR + (_maxR - _btnR) * eased;     // 56 → 116 px
      final alpha  = (0.45 * (1.0 - eased)).clamp(0.0, 1.0); // fade out

      if (alpha < 0.01) continue;

      // Filled translucent disc (matches HTML bg:rgba(239,68,68,0.08) style)
      canvas.drawCircle(
        center, radius,
        Paint()
          ..color = _kRed.withValues(alpha: alpha * 0.22)
          ..style = PaintingStyle.fill,
      );

      // Crisp ring stroke (matches HTML border)
      canvas.drawCircle(
        center, radius,
        Paint()
          ..color = _kRed.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 - 1.4 * eased,   // thick → thin as it travels
      );
    }
  }

  // Ease-out: fast exit, slow arrival
  static double _easeOut(double t) => 1.0 - (1.0 - t) * (1.0 - t);

  @override
  bool shouldRepaint(_SonarPainter old) =>
      old.r1 != r1 || old.r2 != r2 || old.r3 != r3;
}

// ── Option card (Close Friends / Nearby Users / Share Location) ────────────
class _OptionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool disabled;
  final bool fullWidth;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.disabled,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final card = isDark ? const Color(0xFF110810) : cs.surfaceContainerLow;
    final activeBg = isDark ? _kActiveBgDark : cs.errorContainer.withOpacity(0.15);
    final borderCol = isDark ? const Color(0xFF1E1520) : cs.outlineVariant;
    final text = isDark ? const Color(0xFFF1F5F9) : cs.onSurface;
    final muted = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: fullWidth ? 14 : 16,
        ),
        decoration: BoxDecoration(
          color: selected ? activeBg : card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _kRedBorder : borderCol,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: fullWidth
            ? Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            )),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                            )),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 10),
                  Text(title,
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                      )),
                ],
              ),
      ),
    );
  }
}
