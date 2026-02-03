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

  Future<void> _deleteJournal(Map<String, dynamic> j) async {
    final id = j["_id"]?.toString();
    if (id == null || id.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete journal?"),
        content: const Text(
          "This entry will be removed. This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await MindJournalService.deleteJournal(id);
      if (!mounted) return;
      await _loadMyJournals();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text("Journal deleted")),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text("Failed to delete: ${e.toString().replaceFirst('Exception: ', '')}")),
      );
    }
  }

  Future<void> _editJournal(Map<String, dynamic> j) async {
    final id = j["_id"]?.toString();
    if (id == null || id.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final presentCtrl = TextEditingController(text: (j["presentFeel"] ?? "").toString());
    final comparisonCtrl = TextEditingController(text: (j["stopComparison"] ?? "").toString());
    final selfCareCtrl = TextEditingController(text: (j["selfCare"] ?? "").toString());
    bool saving = false;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit journal"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("How present do you feel right now?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: presentCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: "Take your time...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("What comparison can you stop making?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: comparisonCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: "It's safe to let go...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("What did you do just for yourself today?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: selfCareCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: "Celebrate yourself...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: saving
                    ? null
                    : () async {
                        setDialogState(() => saving = true);
                        try {
                          await MindJournalService.updateJournal(
                            journalId: id,
                            presentFeel: presentCtrl.text.trim(),
                            stopComparison: comparisonCtrl.text.trim(),
                            selfCare: selfCareCtrl.text.trim(),
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx, true);
                        } catch (e) {
                          setDialogState(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text("Failed to update: ${e.toString().replaceFirst('Exception: ', '')}")),
                            );
                          }
                        }
                      },
                child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Save"),
              ),
            ],
          );
        },
      ),
    );

    presentCtrl.dispose();
    comparisonCtrl.dispose();
    selfCareCtrl.dispose();

    if (updated == true && context.mounted) {
      await _loadMyJournals();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text("Journal updated ✨")),
      );
    }
  }

  Widget _buildJournalCard(Map<String, dynamic> j) {
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  (j["createdAt"] ?? "").toString().isNotEmpty
                      ? "🗓 ${(j["createdAt"]).toString()}"
                      : "🗓 Journal Entry",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 22, color: Colors.black54),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'edit') _editJournal(j);
                  if (value == 'delete') _deleteJournal(j);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 10),
                        Text("Edit"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 10),
                        Text("Delete", style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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
                  children: _journals.map((j) => _buildJournalCard(j)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
