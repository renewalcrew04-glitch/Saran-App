import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/s_cycle_service.dart';

// ── Brand tokens ───────────────────────────────────────────────────────────────
const _kBg        = Color(0xFF060B14);
const _kCard      = Color(0xFF111827);
const _kBorder    = Color(0xFF1E2535);
const _kPrimary   = Color(0xFFFF8132);
const _kPrimaryLt = Color(0xFFFF9D5C);
const _kText      = Color(0xFFF1F5F9);
const _kMuted     = Color(0xFF64748B);
const _kSubtext   = Color(0xFF94A3B8);
const _kRose      = Color(0xFFBE185D);
const _kRoseLt    = Color(0xFFF472B6);

class SCycleScreen extends StatefulWidget {
  const SCycleScreen({super.key});

  @override
  State<SCycleScreen> createState() => _SCycleScreenState();
}

class _SCycleScreenState extends State<SCycleScreen> {
  bool _loading = true;
  bool _saving = false;

  int _daysUntilPeriod = 28;
  String _motivation = "Your body is strong.";

  List<Map<String, dynamic>> _history = [];

  // Bottomsheet state
  String? _selectedMood;
  final Set<String> _selectedSymptoms = {};
  bool _periodStartedToday = false;

  final List<Map<String, String>> _moods = [
    {"key": "happy", "emoji": "😊"},
    {"key": "calm", "emoji": "😌"},
    {"key": "tired", "emoji": "🥱"},
    {"key": "sad", "emoji": "😟"},
    {"key": "cry", "emoji": "😭"},
    {"key": "pain", "emoji": "⚡"},
  ];

  final List<String> _symptoms = [
    "Cramps",
    "Headache",
    "Bloating",
    "Cravings",
    "Fatigue",
    "Back Pain",
    "Mood Swings",
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;
      if (user == null) return;

      final summary = await SCycleService.getSummary(user.uid);
      final history = await SCycleService.getHistory(user.uid);

      if (!mounted) return;

      setState(() {
        _daysUntilPeriod = (summary["daysUntilPeriod"] ?? 28) as int;
        _motivation = (summary["motivation"] ?? "Your body is strong.").toString();
        _history = history;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _markPeriodStarted() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;
      if (user == null) return;

      setState(() => _saving = true);

      await SCycleService.markPeriodStarted(userId: user.uid);

      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Period started saved ✅"),
          backgroundColor: _kCard,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to save period start ❌"),
          backgroundColor: _kCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openLogBottomSheet() {
    setState(() {
      _selectedMood = null;
      _selectedSymptoms.clear();
      _periodStartedToday = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Log Today",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _kText,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: _kSubtext, size: 20),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Mood label
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "How are you feeling?",
                    style: TextStyle(
                      fontSize: 13,
                      color: _kSubtext,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _moods.map((m) {
                    final isActive = _selectedMood == m["key"];
                    return GestureDetector(
                      onTap: () => setSheetState(() => _selectedMood = m["key"]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: isActive ? _kRose : const Color(0xFF1A2235),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isActive ? _kRoseLt : _kBorder,
                            width: isActive ? 2 : 1,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: _kRose.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          m["emoji"] ?? "🙂",
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Symptoms label
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Any symptoms?",
                    style: TextStyle(
                      fontSize: 13,
                      color: _kSubtext,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _symptoms.map((s) {
                    final active = _selectedSymptoms.contains(s);
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          if (active) {
                            _selectedSymptoms.remove(s);
                          } else {
                            _selectedSymptoms.add(s);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: active ? _kRose : const Color(0xFF1A2235),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: active ? _kRoseLt : _kBorder,
                          ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : _kSubtext,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Period started toggle
                GestureDetector(
                  onTap: () {
                    setSheetState(
                        () => _periodStartedToday = !_periodStartedToday);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _periodStartedToday
                          ? _kRose.withOpacity(0.12)
                          : const Color(0xFF1A2235),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            _periodStartedToday ? _kRose : _kBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.water_drop_outlined,
                          color:
                              _periodStartedToday ? _kRoseLt : _kSubtext,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Period Started",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: _kText,
                            ),
                          ),
                        ),
                        Switch(
                          value: _periodStartedToday,
                          onChanged: (v) {
                            setSheetState(() => _periodStartedToday = v);
                          },
                          activeColor: _kRose,
                          inactiveThumbColor: _kMuted,
                          inactiveTrackColor: _kBorder,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Buttons row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setSheetState(() => _periodStartedToday = true);
                        },
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2235),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _kBorder),
                          ),
                          child: const Text(
                            "Period Started",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _kText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _saving
                            ? null
                            : () async {
                                await _saveLogFromSheet();
                              },
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kPrimaryLt, _kPrimary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40FF8132),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Save Log",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveLogFromSheet() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;
      if (user == null) return;

      if (_selectedMood == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Select your mood first 🙂"),
            backgroundColor: _kCard,
          ),
        );
        return;
      }

      setState(() => _saving = true);

      await SCycleService.saveDailyLog(
        userId: user.uid,
        mood: _selectedMood!,
        symptoms: _selectedSymptoms.toList(),
        periodStarted: _periodStartedToday,
      );

      if (!mounted) return;
      setState(() => _saving = false);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Saved successfully ✅"),
          backgroundColor: _kCard,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final msg = e
          .toString()
          .replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Failed to save log: ${msg.length > 60 ? '${msg.substring(0, 60)}…' : msg}"),
          backgroundColor: _kCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(dynamic value) {
    try {
      final dt = DateTime.parse(value.toString());
      final day = dt.day.toString().padLeft(2, '0');
      final mon = dt.month.toString().padLeft(2, '0');
      final yr = dt.year.toString();
      return "$day/$mon/$yr";
    } catch (_) {
      return value.toString();
    }
  }

  Future<void> _deleteLogFromHistory(Map<String, dynamic> item) async {
    final id = item["_id"]?.toString();
    if (id == null || id.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _kBorder),
        ),
        title: const Text(
          "Delete log?",
          style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          "This log entry will be removed. This cannot be undone.",
          style: TextStyle(color: _kSubtext, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel",
                style: TextStyle(color: _kSubtext)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete",
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await SCycleService.deleteLog(id);
      if (!mounted) return;
      await _loadAll();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Log deleted"),
          backgroundColor: _kCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              "Failed to delete: ${e.toString().replaceFirst('Exception: ', '')}"),
          backgroundColor: _kCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openEditLogSheet(Map<String, dynamic> item) {
    final id = item["_id"]?.toString();
    if (id == null || id.isEmpty) return;
    final currentMood = (item["mood"] ?? "").toString();
    final currentSymptoms = (item["symptoms"] ?? []) as List<dynamic>;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EditLogSheetContent(
        logId: id,
        initialMood: currentMood.isEmpty ? null : currentMood,
        initialSymptoms:
            currentSymptoms.map((s) => s.toString()).toList(),
        moods: _moods,
        symptoms: _symptoms,
        onSaved: () async {
          if (!context.mounted) return;
          final messenger = ScaffoldMessenger.of(context);
          await _loadAll();
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(
              content: Text("Log updated ✅"),
              backgroundColor: _kCard,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  String _moodEmoji(String mood) {
    return _moods
            .firstWhere((m) => m["key"] == mood,
                orElse: () => {"emoji": "🙂"})["emoji"] ??
        "🙂";
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: _kSubtext, size: 20),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'S-Cycle',
                        style: TextStyle(
                          color: _kText,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Cycle tracker & daily logs',
                        style: TextStyle(color: _kSubtext, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: user == null
                  ? const Center(
                      child: Text("Not logged in",
                          style: TextStyle(color: _kSubtext)))
                  : RefreshIndicator(
                      color: _kPrimary,
                      backgroundColor: _kCard,
                      onRefresh: _loadAll,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        child: _loading
                            ? const SizedBox(
                                height: 400,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: _kPrimary,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // ── Summary card ──────────────────
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _kRose.withOpacity(0.25),
                                          _kRose.withOpacity(0.05),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(22),
                                      border: Border.all(
                                          color: _kRose.withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(
                                                  right: 8),
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _kRoseLt,
                                              ),
                                            ),
                                            const Text(
                                              'NEXT CYCLE',
                                              style: TextStyle(
                                                color: _kRoseLt,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '$_daysUntilPeriod',
                                          style: TextStyle(
                                            fontSize: 56,
                                            fontWeight: FontWeight.w900,
                                            color: _kRoseLt,
                                            height: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'days until period',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _kSubtext,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: _kRose
                                                    .withOpacity(0.2)),
                                          ),
                                          child: Text(
                                            _motivation,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _kSubtext,
                                              fontStyle: FontStyle.italic,
                                              fontWeight: FontWeight.w500,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // ── Action buttons ────────────────
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: _saving
                                              ? null
                                              : _markPeriodStarted,
                                          child: Container(
                                            height: 48,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: _kCard,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                  color: _kRose
                                                      .withOpacity(0.4)),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                    Icons
                                                        .water_drop_outlined,
                                                    color: _kRoseLt,
                                                    size: 18),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _saving
                                                      ? "Saving…"
                                                      : "Period Started",
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    color: _kText,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: _openLogBottomSheet,
                                          child: Container(
                                            height: 48,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              gradient:
                                                  const LinearGradient(
                                                colors: [
                                                  _kPrimaryLt,
                                                  _kPrimary
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x40FF8132),
                                                  blurRadius: 10,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.add,
                                                    color: Colors.white,
                                                    size: 18),
                                                SizedBox(width: 6),
                                                Text(
                                                  "Log Symptoms",
                                                  style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // ── Predictions card ──────────────
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _kCard,
                                      borderRadius:
                                          BorderRadius.circular(18),
                                      border:
                                          Border.all(color: _kBorder),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                                Icons.calendar_month_outlined,
                                                color: _kPrimaryLt,
                                                size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              "Predictions",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                                color: _kText,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        _PredictionRow(
                                          label: "Next Period",
                                          value:
                                              "In $_daysUntilPeriod days",
                                        ),
                                        const SizedBox(height: 12),
                                        const _PredictionRow(
                                          label: "Fertility Window",
                                          value: "Feb 1 - Feb 7",
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // ── Nutrition tip ─────────────────
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _kCard,
                                      borderRadius:
                                          BorderRadius.circular(18),
                                      border:
                                          Border.all(color: _kBorder),
                                    ),
                                    child: const Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('💛',
                                            style:
                                                TextStyle(fontSize: 18)),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Nutrition Tip",
                                                style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.w900,
                                                  fontSize: 13,
                                                  color: _kText,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "Avoid excessive salt to reduce bloating",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: _kSubtext,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // ── History heading ───────────────
                                  Row(
                                    children: [
                                      const Text(
                                        "History",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: _kText,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (_history.isNotEmpty)
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _kPrimary
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${_history.length}',
                                            style: const TextStyle(
                                              color: _kPrimaryLt,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // ── History list ──────────────────
                                  if (_history.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: _kCard,
                                        borderRadius:
                                            BorderRadius.circular(18),
                                        border: Border.all(
                                            color: _kBorder),
                                      ),
                                      child: const Text(
                                        "No logs yet. Start logging today 💛",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _kSubtext,
                                        ),
                                      ),
                                    )
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _history.length,
                                      itemBuilder: (context, index) {
                                        final item = _history[index];
                                        final date = _formatDate(
                                            item["date"] ??
                                                item["createdAt"] ??
                                                "");
                                        final mood = (item["mood"] ?? "")
                                            .toString();
                                        final symptoms =
                                            (item["symptoms"] ?? [])
                                                as List<dynamic>;
                                        final started = (item[
                                                        "periodStarted"] ??
                                                    item["isPeriodStart"] ??
                                                    false) ==
                                                true;

                                        return Container(
                                          margin: const EdgeInsets.only(
                                              bottom: 10),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: _kCard,
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                                color: _kBorder),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      date,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 13,
                                                        color: _kText,
                                                      ),
                                                    ),
                                                  ),
                                                  if (started)
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              right: 4),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10,
                                                          vertical: 5),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: _kRose
                                                            .withOpacity(
                                                                0.15),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    999),
                                                        border: Border.all(
                                                            color: _kRose
                                                                .withOpacity(
                                                                    0.4)),
                                                      ),
                                                      child: const Text(
                                                        "Period Started",
                                                        style: TextStyle(
                                                          color: _kRoseLt,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  PopupMenuButton<String>(
                                                    icon: const Icon(
                                                        Icons.more_horiz,
                                                        size: 22,
                                                        color: _kMuted),
                                                    padding: EdgeInsets.zero,
                                                    color: _kCard,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      side: const BorderSide(
                                                          color: _kBorder),
                                                    ),
                                                    onSelected: (value) {
                                                      if (value == 'edit') {
                                                        _openEditLogSheet(
                                                            item);
                                                      }
                                                      if (value ==
                                                          'delete') {
                                                        _deleteLogFromHistory(
                                                            item);
                                                      }
                                                    },
                                                    itemBuilder: (ctx) => [
                                                      const PopupMenuItem(
                                                        value: 'edit',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                                Icons
                                                                    .edit_outlined,
                                                                size: 18,
                                                                color:
                                                                    _kSubtext),
                                                            SizedBox(
                                                                width: 10),
                                                            Text("Edit",
                                                                style: TextStyle(
                                                                    color:
                                                                        _kText)),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                                Icons
                                                                    .delete_outline,
                                                                size: 18,
                                                                color: Color(
                                                                    0xFFEF4444)),
                                                            SizedBox(
                                                                width: 10),
                                                            Text(
                                                              "Delete",
                                                              style: TextStyle(
                                                                  color: Color(
                                                                      0xFFEF4444)),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Text(
                                                    _moodEmoji(mood),
                                                    style: const TextStyle(
                                                        fontSize: 16),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    mood,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: _kSubtext,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (symptoms.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children:
                                                      symptoms.map((s) {
                                                    return Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 10,
                                                              vertical: 5),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: const Color(
                                                            0xFF1A2235),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    999),
                                                        border: Border.all(
                                                            color: _kBorder),
                                                      ),
                                                      child: Text(
                                                        s.toString(),
                                                        style:
                                                            const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: _kSubtext,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                ],
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

// ── Prediction Row ──────────────────────────────────────────────────────────────
class _PredictionRow extends StatelessWidget {
  final String label;
  final String value;

  const _PredictionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kSubtext,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: _kText,
          ),
        ),
      ],
    );
  }
}

// ── Edit Log Sheet ──────────────────────────────────────────────────────────────
class _EditLogSheetContent extends StatefulWidget {
  final String logId;
  final String? initialMood;
  final List<String> initialSymptoms;
  final List<Map<String, String>> moods;
  final List<String> symptoms;
  final VoidCallback onSaved;

  const _EditLogSheetContent({
    required this.logId,
    required this.initialMood,
    required this.initialSymptoms,
    required this.moods,
    required this.symptoms,
    required this.onSaved,
  });

  @override
  State<_EditLogSheetContent> createState() => _EditLogSheetContentState();
}

class _EditLogSheetContentState extends State<_EditLogSheetContent> {
  late String? selectedMood;
  late Set<String> selectedSymptoms;

  @override
  void initState() {
    super.initState();
    selectedMood = widget.initialMood;
    selectedSymptoms = Set<String>.from(widget.initialSymptoms);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _kBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Row(
            children: [
              const Expanded(
                child: Text(
                  "Edit log",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _kText,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: _kSubtext, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Mood",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: _kSubtext,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.moods.map((m) {
              final key = m["key"] as String;
              final isSelected = selectedMood == key;
              return GestureDetector(
                onTap: () => setState(() => selectedMood = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? _kRose : const Color(0xFF1A2235),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? _kRoseLt : _kBorder,
                    ),
                  ),
                  child: Text(
                    "${m["emoji"]} $key",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _kSubtext,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Symptoms",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: _kSubtext,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.symptoms.map((s) {
              final isSelected = selectedSymptoms.contains(s);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedSymptoms.remove(s);
                    } else {
                      selectedSymptoms.add(s);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kRose
                        : const Color(0xFF1A2235),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? _kRoseLt : _kBorder,
                    ),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isSelected ? Colors.white : _kSubtext,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: () async {
              if (selectedMood == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Select your mood first 🙂"),
                    backgroundColor: _kCard,
                  ),
                );
                return;
              }
              try {
                await SCycleService.updateLog(
                  logId: widget.logId,
                  mood: selectedMood!,
                  symptoms: selectedSymptoms.toList(),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                widget.onSaved();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        "Failed to update: ${e.toString().replaceFirst('Exception: ', '')}"),
                    backgroundColor: _kCard,
                  ),
                );
              }
            },
            child: Container(
              width: double.infinity,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPrimaryLt, _kPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40FF8132),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                "Save changes",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
