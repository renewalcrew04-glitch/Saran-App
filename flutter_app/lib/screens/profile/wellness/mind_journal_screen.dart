import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saran_app/providers/auth_provider.dart';
import 'package:saran_app/services/mind_journal_service.dart';

// ── Brand tokens ───────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF060B14);
const _kSurface = Color(0xFF0D1120);
const _kCard    = Color(0xFF111827);
const _kBorder  = Color(0xFF1E2535);
const _kPrimary = Color(0xFFFF8132);
const _kPrimaryLt = Color(0xFFFF9D5C);
const _kText    = Color(0xFFF1F5F9);
const _kMuted   = Color(0xFF64748B);
const _kSubtext = Color(0xFF94A3B8);

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
  bool _showForm = false;

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
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid == null) {
        setState(() { _journals = []; _loadingList = false; });
        return;
      }
      final list = await MindJournalService.getMyJournals(uid);
      if (!mounted) return;
      setState(() {
        _journals = list.reversed.toList();
        _loadingList = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingList = false);
    }
  }

  Future<void> _saveJournal() async {
    final a = _presentCtrl.text.trim();
    final b = _comparisonCtrl.text.trim();
    final c = _selfCareCtrl.text.trim();
    if (a.isEmpty && b.isEmpty && c.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something before saving 💛')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid == null) throw Exception('Not logged in');
      await MindJournalService.saveJournal(
        userId: uid,
        presentFeel: a,
        stopComparison: b,
        selfCare: c,
      );
      _presentCtrl.clear();
      _comparisonCtrl.clear();
      _selfCareCtrl.clear();
      await _loadMyJournals();
      if (!mounted) return;
      setState(() => _showForm = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved ✨')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save journal')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteJournal(Map<String, dynamic> j) async {
    final id = j['_id']?.toString();
    if (id == null || id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kSurface,
        title: const Text('Delete entry?',
            style: TextStyle(color: _kText, fontWeight: FontWeight.w700)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: _kSubtext)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: _kSubtext)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await MindJournalService.deleteJournal(id);
      await _loadMyJournals();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _editJournal(Map<String, dynamic> j) async {
    final id = j['_id']?.toString();
    if (id == null || id.isEmpty) return;
    final pCtrl = TextEditingController(text: j['presentFeel']?.toString() ?? '');
    final cCtrl = TextEditingController(text: j['stopComparison']?.toString() ?? '');
    final sCtrl = TextEditingController(text: j['selfCare']?.toString() ?? '');
    bool saving = false;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _kSurface,
          title: const Text('Edit journal',
              style: TextStyle(color: _kText, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField('How present do you feel?', 'Take your time...', pCtrl),
                const SizedBox(height: 12),
                _dialogField('What comparison can you stop making?', 'Let go...', cCtrl),
                const SizedBox(height: 12),
                _dialogField('What did you do for yourself today?', 'Celebrate...', sCtrl),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: _kSubtext)),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      setS(() => saving = true);
                      try {
                        await MindJournalService.updateJournal(
                          journalId: id,
                          presentFeel: pCtrl.text.trim(),
                          stopComparison: cCtrl.text.trim(),
                          selfCare: sCtrl.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx, true);
                      } catch (e) {
                        setS(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: _kPrimary, strokeWidth: 2))
                  : const Text('Save',
                      style: TextStyle(
                          color: _kPrimary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    pCtrl.dispose();
    cCtrl.dispose();
    sCtrl.dispose();

    if (updated == true && mounted) {
      await _loadMyJournals();
    }
  }

  Widget _dialogField(String label, String hint, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _kSubtext, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: 2,
          style: const TextStyle(color: _kText, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _kMuted),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary),
            ),
            filled: true,
            fillColor: const Color(0xFF060B14),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return 'Journal Entry';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: _kSubtext, size: 20),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'S-Mind Journal',
                          style: TextStyle(
                            color: _kText,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'A safe space to reflect',
                          style: TextStyle(color: _kSubtext, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // New entry toggle
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showForm = !_showForm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: _showForm
                            ? null
                            : const LinearGradient(
                                colors: [_kPrimaryLt, _kPrimary]),
                        color: _showForm ? _kCard : null,
                        borderRadius: BorderRadius.circular(20),
                        border: _showForm
                            ? Border.all(color: _kBorder)
                            : null,
                      ),
                      child: Text(
                        _showForm ? 'Cancel' : '+ New entry',
                        style: TextStyle(
                          color: _showForm ? _kSubtext : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // ── Write form ──────────────────────────────────────────
                  if (_showForm) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✍️ Today\'s Reflection',
                            style: TextStyle(
                              color: _kText,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: 'How present do you feel right now?',
                            hint: 'Take your time...',
                            controller: _presentCtrl,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            label: 'What comparison can you stop making?',
                            hint: 'It\'s safe to let go...',
                            controller: _comparisonCtrl,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            label: 'What did you do just for yourself today?',
                            hint: 'Celebrate yourself...',
                            controller: _selfCareCtrl,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: _saving ? null : _saveJournal,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_kPrimaryLt, _kPrimary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: _saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      )
                                    : const Text(
                                        'Save Journal',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Past entries ─────────────────────────────────────────
                  Row(
                    children: [
                      const Text(
                        'Your Journals',
                        style: TextStyle(
                          color: _kText,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_journals.length}',
                          style: const TextStyle(
                            color: _kPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_loadingList)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(
                            color: _kPrimary, strokeWidth: 2.5),
                      ),
                    )
                  else if (_journals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          const Text('📓',
                              style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          const Text(
                            'No journals yet',
                            style: TextStyle(
                                color: _kText,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap "+ New entry" to start your first reflection.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: _kMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          if (!_showForm)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showForm = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 11),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_kPrimaryLt, _kPrimary],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Write your first entry',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    ..._journals.map(_buildJournalCard),
                ],
              ),
            ),
          ],
        ),
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
            color: _kSubtext,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: _kText, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _kMuted),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimary),
            ),
            filled: true,
            fillColor: _kBg,
          ),
        ),
      ],
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> j) {
    final hasPresent = (j['presentFeel'] ?? '').toString().isNotEmpty;
    final hasComparison = (j['stopComparison'] ?? '').toString().isNotEmpty;
    final hasSelfCare = (j['selfCare'] ?? '').toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📓', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatDate(j['createdAt']),
                  style: const TextStyle(
                    color: _kSubtext,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz,
                    size: 20, color: _kMuted),
                color: _kSurface,
                onSelected: (v) {
                  if (v == 'edit') _editJournal(j);
                  if (v == 'delete') _deleteJournal(j);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: const [
                      Icon(Icons.edit_outlined,
                          size: 18, color: _kSubtext),
                      SizedBox(width: 8),
                      Text('Edit',
                          style: TextStyle(color: _kText)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: const [
                      Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasPresent) _entryRow('🧠', j['presentFeel'].toString()),
          if (hasComparison) _entryRow('🔄', j['stopComparison'].toString()),
          if (hasSelfCare) _entryRow('💛', j['selfCare'].toString()),
        ],
      ),
    );
  }

  Widget _entryRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _kText,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
