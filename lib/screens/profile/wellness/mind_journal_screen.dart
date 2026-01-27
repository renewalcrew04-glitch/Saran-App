import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saran_app/providers/auth_provider.dart';
import 'package:saran_app/services/mind_journal_service.dart';

class MindJournalScreen extends StatefulWidget {
  const MindJournalScreen({super.key});

  @override
  State<MindJournalScreen> createState() => _MindJournalScreenState();
}

class _MindJournalScreenState extends State<MindJournalScreen> {
  final _presentCtrl = TextEditingController();
  final _comparisonCtrl = TextEditingController();
  final _selfCareCtrl = TextEditingController();

  bool _saving = false;
  bool _loadingList = true;

  List<Map<String, dynamic>> _journals = [];

  @override
  void initState() {
    super.initState();
    _loadMyJournals();
  }

  @override
  void dispose() {
    _presentCtrl.dispose();
    _comparisonCtrl.dispose();
    _selfCareCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMyJournals() async {
    setState(() => _loadingList = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final uid = auth.user?.uid;

      if (uid == null) {
        setState(() {
          _journals = [];
          _loadingList = false;
        });
        return;
      }

      final list = await MindJournalService.getMyJournals(uid);

      if (!mounted) return;
      setState(() {
        _journals = list.reversed.toList(); // latest first
        _loadingList = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingList = false);
    }
  }

  Future<void> _saveJournal() async {
    final presentFeel = _presentCtrl.text.trim();
    final stopComparison = _comparisonCtrl.text.trim();
    final selfCare = _selfCareCtrl.text.trim();

    if (presentFeel.isEmpty && stopComparison.isEmpty && selfCare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Write something before saving 💛")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final uid = auth.user?.uid;

      if (uid == null) {
        throw Exception("User not logged in");
      }

      await MindJournalService.saveJournal(
        userId: uid,
        presentFeel: presentFeel,
        stopComparison: stopComparison,
        selfCare: selfCare,
      );

      _presentCtrl.clear();
      _comparisonCtrl.clear();
      _selfCareCtrl.clear();

      await _loadMyJournals();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved ✨")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save journal")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.black, width: 1.2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "S-Mind Journal",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(
                label: "How present do you feel right now?",
                hint: "Take your time...",
                controller: _presentCtrl,
              ),
              const SizedBox(height: 16),

              _buildField(
                label: "What comparison can you stop making?",
                hint: "It's safe to let go...",
                controller: _comparisonCtrl,
              ),
              const SizedBox(height: 16),

              _buildField(
                label: "What did you do just for yourself today?",
                hint: "Celebrate yourself...",
                controller: _selfCareCtrl,
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveJournal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Save Journal",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                "Your Journals",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),

              if (_loadingList)
                const Center(child: CircularProgressIndicator())
              else if (_journals.isEmpty)
                const Text(
                  "No journals yet. Your first entry will appear here ✨",
                  style: TextStyle(color: Colors.black54),
                )
              else
                Column(
                  children: _journals.map((j) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
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
                          Text(
                            (j["createdAt"] ?? "").toString().isNotEmpty
                                ? "🗓 ${(j["createdAt"]).toString()}"
                                : "🗓 Journal Entry",
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if ((j["presentFeel"] ?? "").toString().isNotEmpty)
                            Text("• ${j["presentFeel"]}"),
                          if ((j["stopComparison"] ?? "").toString().isNotEmpty)
                            Text("• ${j["stopComparison"]}"),
                          if ((j["selfCare"] ?? "").toString().isNotEmpty)
                            Text("• ${j["selfCare"]}"),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
