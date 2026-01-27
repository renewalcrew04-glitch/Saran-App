import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/s_cycle_service.dart';

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

  Future<void> _fetchHistoryOnly() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;
      if (user == null) return;

      final history = await SCycleService.getHistory(user.uid);

      if (!mounted) return;
      setState(() {
        _history = history;
      });
    } catch (_) {}
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
        const SnackBar(content: Text("Period started saved ✅")),
      );

      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save period start ❌")),
      );
    }
  }

  void _openLogBottomSheet() {
    // reset sheet state
    setState(() {
      _selectedMood = null;
      _selectedSymptoms.clear();
      _periodStartedToday = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 14,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Log Today",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.black),
                    )
                  ],
                ),

                const SizedBox(height: 6),

                // Mood
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "How are you feeling?",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _moods.map((m) {
                    final isActive = _selectedMood == m["key"];
                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        setSheetState(() {
                          _selectedMood = m["key"];
                        });
                      },
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isActive ? Colors.black : const Color(0xFFEDEDED),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          m["emoji"] ?? "🙂",
                          style: TextStyle(
                            fontSize: 22,
                            color: isActive ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // Symptoms
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Any symptoms?",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _symptoms.map((s) {
                    final active = _selectedSymptoms.contains(s);
                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        setSheetState(() {
                          if (active) {
                            _selectedSymptoms.remove(s);
                          } else {
                            _selectedSymptoms.add(s);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: active ? Colors.black : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: active ? Colors.black : const Color(0xFFEDEDED),
                          ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // Period started toggle
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setSheetState(() {
                      _periodStartedToday = !_periodStartedToday;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEDEDED)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.water_drop_outlined,
                          color: _periodStartedToday ? Colors.black : Colors.grey[700],
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Period Started",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Switch(
                          value: _periodStartedToday,
                          onChanged: (v) {
                            setSheetState(() {
                              _periodStartedToday = v;
                            });
                          },
                          activeColor: Colors.black,
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          // Quick save as "period started"
                          setSheetState(() {
                            _periodStartedToday = true;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Period Started",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving
                            ? null
                            : () async {
                                await _saveLogFromSheet();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
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
          const SnackBar(content: Text("Select your mood first 🙂")),
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
        const SnackBar(content: Text("Saved successfully ✅")),
      );

      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save log ❌")),
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "S-Cycle",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? const Center(child: Text("Not logged in"))
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _loading
                      ? const SizedBox(
                          height: 450,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: const Color(0xFFEDEDED)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "$_daysUntilPeriod",
                                    style: const TextStyle(
                                      fontSize: 44,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "days until period",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _motivation,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black45,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _saving ? null : _markPeriodStarted,
                                    icon: const Icon(Icons.water_drop_outlined, color: Colors.black),
                                    label: const Text(
                                      "Period Started",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _openLogBottomSheet,
                                    icon: const Icon(Icons.add, color: Colors.black),
                                    label: const Text(
                                      "Log Symptoms",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Predictions Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFEDEDED)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Predictions",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _PredictionRow(
                                    label: "Next Period",
                                    value: "In $_daysUntilPeriod days",
                                  ),
                                  const SizedBox(height: 10),
                                  const _PredictionRow(
                                    label: "Fertility Window",
                                    value: "Feb 1 - Feb 7",
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Nutrition Tip
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFEDEDED)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Row(
                                    children: [
                                      Icon(Icons.favorite_border, size: 18, color: Colors.black),
                                      SizedBox(width: 8),
                                      Text(
                                        "Nutrition Tip",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Avoid excessive salt to reduce bloating",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            const Text(
                              "History",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),

                            if (_history.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFEDEDED)),
                                ),
                                child: const Text(
                                  "No logs yet. Start logging today 💛",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black54,
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _history.length,
                                itemBuilder: (context, index) {
                                  final item = _history[index];

                                  final date = _formatDate(item["date"] ?? item["createdAt"] ?? "");
                                  final mood = (item["mood"] ?? "").toString();
                                  final symptoms = (item["symptoms"] ?? []) as List<dynamic>;
                                  final started = (item["periodStarted"] ?? false) == true;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: const Color(0xFFEDEDED)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 10,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                date,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            if (started)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.black,
                                                  borderRadius: BorderRadius.circular(999),
                                                ),
                                                child: const Text(
                                                  "Period Started",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Mood: $mood",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: symptoms.map((s) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(999),
                                                border: Border.all(color: const Color(0xFFEDEDED)),
                                              ),
                                              child: Text(
                                                s.toString(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                            const SizedBox(height: 30),
                          ],
                        ),
                ),
              ),
            ),
    );
  }
}

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
              color: Colors.black54,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
