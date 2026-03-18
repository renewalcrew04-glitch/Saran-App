import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/voice_profiles.dart';
import '../../services/ai_service.dart';
import '../../widgets/ai_avatar.dart';
import '../../widgets/ai_streaming_subtitle.dart';

extension _Cap on String {
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

// ── Theme tokens ───────────────────────────────────────────────────────────────
const _kPurple      = Color(0xFF7C3AED);
const _kPurple2     = Color(0xFF4F46E5);
const _kPurpleDark  = Color(0xFF3D1A6B);
const _kPurpleLight = Color(0xFFEDE8FF);

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final SpeechToText speech = SpeechToText();
  final FlutterTts tts = FlutterTts();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  bool listening = false;
  bool loading = false;
  bool conversationMode = false;
  bool femaleVoice = true;
  bool typingMode = false;

  List<Map<String, String>> messages = [];

  String subtitleText = "";
  String selectedLanguage = "en_US";
  String selectedVoice = "saran_luna";

  List<Map<String, String>> _deviceVoicesFemale = [];
  List<Map<String, String>> _deviceVoicesMale = [];

  static const Map<String, String> _languages = {
    "English": "en_US",
    "Hindi": "hi_IN",
    "Tamil": "ta_IN",
    "Telugu": "te_IN",
    "Kannada": "kn_IN",
    "Malayalam": "ml_IN",
  };

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _inputFocus.addListener(() {
      if (_inputFocus.hasFocus) {
        setState(() {
          typingMode = true;
          conversationMode = false;
        });
      }
    });

    setupVoice().then((_) async {
      await _loadDeviceVoices();
      setVoice();
    });
  }

  @override
  void dispose() {
    _inputFocus.dispose();
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Voice setup ───────────────────────────────────────────────────────────

  Future setupVoice() async {
    await tts.awaitSpeakCompletion(true);
    await tts.setLanguage("en-US");
    await tts.setSpeechRate(0.48);
    await tts.setPitch(1.0);
    await tts.setVolume(1.0);
  }

  Future<void> _loadDeviceVoices() async {
    try {
      final list = await tts.getVoices;
      if (list == null || list.isEmpty) return;
      final female = <Map<String, String>>[];
      final male = <Map<String, String>>[];
      final unknown = <Map<String, String>>[];
      for (final v in list) {
        if (v is! Map) continue;
        final name = v['name']?.toString();
        final locale = v['locale']?.toString();
        if (name == null || name.isEmpty || locale == null || locale.isEmpty) {
          continue;
        }
        final map = {'name': name, 'locale': locale};
        final gender =
            v['gender']?.toString().toLowerCase() ?? v['genderId']?.toString() ?? '';
        if (gender.contains('female') || gender == '1') {
          female.add(map);
        } else if (gender.contains('male') || gender == '0') {
          male.add(map);
        } else {
          unknown.add(map);
        }
      }
      if (female.isEmpty && male.isEmpty && unknown.isNotEmpty) {
        final half = (unknown.length / 2).ceil();
        female.addAll(unknown.take(half));
        male.addAll(unknown.skip(half));
      } else if (unknown.isNotEmpty) {
        final half = (unknown.length / 2).ceil();
        female.addAll(unknown.take(half));
        male.addAll(unknown.skip(half));
      }
      if (mounted) {
        setState(() {
          _deviceVoicesFemale = female;
          _deviceVoicesMale = male;
        });
      }
    } catch (_) {}
  }

  Map<String, String>? _getVoiceMapForSelectedProfile() {
    final locale = selectedLanguage.replaceAll("_", "-");
    final langPrefix = locale.split('-').first;
    final filterLocale = (List<Map<String, String>> list) => list
        .where((v) {
          final loc = v['locale'] ?? '';
          return loc.startsWith(langPrefix) || loc == locale;
        })
        .toList();

    final pool =
        femaleVoice ? filterLocale(_deviceVoicesFemale) : filterLocale(_deviceVoicesMale);
    if (pool.isEmpty) return null;

    final profiles = femaleVoice ? VoiceProfiles.female : VoiceProfiles.male;
    final index = profiles.indexWhere((p) => p.id == selectedVoice);
    if (index < 0) return null;
    return pool[index % pool.length];
  }

  Future setVoice() async {
    try {
      final voiceMap = _getVoiceMapForSelectedProfile();
      if (voiceMap != null) {
        await tts.setVoice(voiceMap);
      } else {
        await tts.setLanguage(selectedLanguage.replaceAll("_", "-"));
      }
    } catch (_) {
      await tts.setLanguage(selectedLanguage.replaceAll("_", "-"));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String cleanText(String text) {
    text = text.replaceAll(RegExp(r'[*#@_]'), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Conversation ──────────────────────────────────────────────────────────

  Future startConversation() async {
    setState(() {
      conversationMode = true;
      typingMode = false;
    });
    startListening();
  }

  Future stopConversation() async {
    await speech.stop();
    setState(() {
      listening = false;
      conversationMode = false;
    });
  }

  // ── Send message ──────────────────────────────────────────────────────────

  Future sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    await speech.stop();

    setState(() {
      messages.add({"role": "user", "text": text});
      loading = true;
    });
    _scrollToBottom();

    final languageName = _languages.entries
            .where((e) => e.value == selectedLanguage)
            .map((e) => e.key)
            .firstOrNull ??
        'English';

    final response =
        await AIService.sendMessage(context, text, language: languageName);

    if (!mounted) return;

    final reply = response ?? "AI error";

    setState(() {
      messages.add({"role": "ai", "text": reply});
      loading = false;
    });
    _scrollToBottom();

    if (reply.isNotEmpty) {
      await speakStreaming(reply);
    }

    if (conversationMode) {
      startListening();
    }
  }

  // ── Speak streaming ───────────────────────────────────────────────────────

  Future speakStreaming(String text) async {
    final sentences = text.split(RegExp(r'[.!?]'));
    for (final s in sentences) {
      if (s.trim().isEmpty) continue;
      if (mounted) setState(() => subtitleText = cleanText(s));
      try {
        await tts.speak(cleanText(s));
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice playback failed. Reading the reply instead.')),
          );
        }
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (mounted) setState(() => subtitleText = "");
  }

  // ── Listening ─────────────────────────────────────────────────────────────

  String get _speechLocale => selectedLanguage.replaceAll('_', '-');

  Future startListening() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission needed for voice conversation')),
        );
      }
      return;
    }

    final available = await speech.initialize(
      onError: (error) {
        if (mounted) {
          setState(() => listening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice error: ${error.errorMsg}')),
          );
        }
      },
    );
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available on this device')),
      );
      return;
    }

    setState(() => listening = true);

    speech.listen(
      localeId: _speechLocale,
      partialResults: true,
      listenMode: ListenMode.dictation,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      onResult: (result) {
        final text = result.recognizedWords;
        if (mounted) setState(() => _controller.text = text);
        if (result.finalResult && text.trim().isNotEmpty) {
          sendMessage(text);
        }
      },
    );
  }

  // ── Settings modal ────────────────────────────────────────────────────────

  void openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF120030).withOpacity(0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'AI Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.1), height: 28),

                // Language picker
                GestureDetector(
                  onTap: () async {
                    final selected = await showModalBottomSheet<String>(
                      context: context,
                      backgroundColor: const Color(0xFF0D0022),
                      builder: (ctx) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _languages.entries
                              .map((e) => ListTile(
                                    title: Text(
                                      e.key,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    trailing: selectedLanguage == e.value
                                        ? const Icon(Icons.check, color: Color(0xFF9B4DFF))
                                        : null,
                                    onTap: () => Navigator.pop(ctx, e.value),
                                  ))
                              .toList(),
                        ),
                      ),
                    );
                    if (selected != null) {
                      setModalState(() => selectedLanguage = selected);
                      setState(() {});
                      setVoice();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withOpacity(0.06),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language, color: Colors.white54, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _languages.keys
                              .firstWhere((k) => _languages[k] == selectedLanguage),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _genderButton('Female', true, setModalState),
                    const SizedBox(width: 14),
                    _genderButton('Male', false, setModalState),
                  ],
                ),

                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: (femaleVoice ? VoiceProfiles.female : VoiceProfiles.male)
                      .take(3)
                      .map((v) => _voiceChip(v, setModalState))
                      .toList(),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: (femaleVoice ? VoiceProfiles.female : VoiceProfiles.male)
                      .skip(3)
                      .take(2)
                      .map((v) => _voiceChip(v, setModalState))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderButton(String label, bool isFemale, Function setModalState) {
    final selected = femaleVoice == isFemale;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          femaleVoice = isFemale;
          selectedVoice =
              (isFemale ? VoiceProfiles.female : VoiceProfiles.male).first.id;
        });
        setState(() {});
        setVoice();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected
              ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)])
              : null,
          color: selected ? null : Colors.white.withOpacity(0.07),
          border: selected ? null : Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Text(
          '$label Voices',
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _voiceChip(dynamic v, Function setModalState) {
    final isSelected = selectedVoice == v.id;
    return GestureDetector(
      onTap: () {
        setModalState(() => selectedVoice = v.id);
        setState(() {});
        setVoice();
      },
      child: Container(
        width: 90,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFF8E5CFF), Color(0xFF6E3CFF)])
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.07),
          border: isSelected ? null : Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Text(
          v.id.replaceAll("saran_", ""),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF0D0022), Color(0xFF180042), Color(0xFF0A0018)]
                : const [Color(0xFFFFFFFF), Color(0xFFF2ECFF), Color(0xFFE8DFFF)],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: typingMode
                    ? _buildChatView(isDark)
                    : _buildCompanionView(isDark),
              ),
              _buildInputBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _circleBtn(Icons.arrow_back_ios_new, 16, () => Navigator.pop(context), isDark),
          const Spacer(),
          // ── Logo only — no text ───────────────────────────────────────────
          ClipOval(
            child: Image.asset(
              'assets/ai_logo.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFCDA8FF), Color(0xFF8B5CF6)],
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
            ),
          ),
          const Spacer(),
          _circleBtn(Icons.tune, 18, openSettings, isDark),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, double size, VoidCallback onTap, bool isDark) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.05),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.14)
                  : _kPurple.withOpacity(0.2),
            ),
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.white70 : _kPurpleDark,
            size: size,
          ),
        ),
      );

  // ── Companion view ────────────────────────────────────────────────────────

  Widget _buildCompanionView(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        AICompanionAvatar(
          isListening: listening,
          isLoading: loading,
          isSpeaking: subtitleText.isNotEmpty,
          isFemale: femaleVoice,
        ),
        const SizedBox(height: 14),
        Text(
          selectedVoice.replaceAll('saran_', '').capitalized,
          style: TextStyle(
            color: isDark ? Colors.white38 : _kPurpleDark.withOpacity(0.45),
            fontSize: 13,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatusBadge(isDark),
        const SizedBox(height: 16),
        if (subtitleText.isNotEmpty) _buildSubtitle(isDark),
        const Spacer(),
      ],
    );
  }

  Widget _buildStatusBadge(bool isDark) {
    String label;
    Color color;

    if (listening) {
      label = 'Listening...';
      color = const Color(0xFF4FFFB0);
    } else if (loading) {
      label = 'Thinking...';
      color = const Color(0xFFFFB347);
    } else if (subtitleText.isNotEmpty) {
      label = 'Speaking...';
      color = const Color(0xFF87CEEB);
    } else if (conversationMode) {
      label = 'Ready';
      color = const Color(0xFF9B4DFF);
    } else {
      label = 'Tap to talk';
      color = isDark ? Colors.white24 : _kPurple.withOpacity(0.35);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(label),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 13, letterSpacing: 1),
        ),
      ),
    );
  }

  // ── Running caption (word-by-word streaming) ──────────────────────────────

  Widget _buildSubtitle(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : _kPurple.withOpacity(0.06),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : _kPurple.withOpacity(0.18),
        ),
      ),
      child: AIStreamingSubtitle(
        key: ValueKey(subtitleText),
        text: subtitleText,
        isDark: isDark,
      ),
    );
  }

  // ── Chat view ─────────────────────────────────────────────────────────────

  Widget _buildChatView(bool isDark) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : _kPurple.withOpacity(0.2),
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              'Start chatting with SARAN AI',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.25)
                    : _kPurpleDark.withOpacity(0.35),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: messages.length + (loading ? 1 : 0),
      itemBuilder: (context, i) {
        // Loading dots bubble
        if (loading && i == messages.length) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : _kPurple.withOpacity(0.07),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : _kPurple.withOpacity(0.15),
                ),
              ),
              child: const _ThinkingDots(),
            ),
          );
        }

        final msg = messages[i];
        final isUser = msg['role'] == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74,
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              gradient: isUser
                  ? const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    )
                  : null,
              color: isUser
                  ? null
                  : isDark
                      ? Colors.white.withOpacity(0.08)
                      : _kPurple.withOpacity(0.06),
              border: isUser
                  ? null
                  : Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : _kPurple.withOpacity(0.15),
                    ),
              boxShadow: isUser
                  ? [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.28),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Text(
              msg['text'] ?? '',
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : isDark
                        ? Colors.white.withOpacity(0.88)
                        : _kPurpleDark,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white.withOpacity(0.7),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : _kPurple.withOpacity(0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          if (typingMode) ...[
            GestureDetector(
              onTap: () {
                startConversation();
                setState(() => typingMode = false);
              },
              child: _gradientCircle(
                icon: Icons.graphic_eq,
                colors: const [_kPurple, _kPurple2],
              ),
            ),
            const SizedBox(width: 8),
          ],

          Expanded(
            flex: typingMode ? 5 : 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.13)
                      : _kPurple.withOpacity(0.22),
                ),
              ),
              child: TextField(
                focusNode: _inputFocus,
                controller: _controller,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onTap: () => setState(() => typingMode = true),
                onSubmitted: (text) {
                  sendMessage(text);
                  _controller.clear();
                },
                decoration: InputDecoration(
                  hintText: 'Ask SARAN AI...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.32)
                        : Colors.black.withOpacity(0.32),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          if (!typingMode) ...[
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: conversationMode ? stopConversation : startConversation,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: conversationMode
                          ? const [Color(0xFFFF4A6E), Color(0xFFFF1F4D)]
                          : const [_kPurple, _kPurple2],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (conversationMode
                                ? Colors.redAccent
                                : _kPurple)
                            .withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        conversationMode ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        conversationMode ? 'End' : 'Talk',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          GestureDetector(
            onTap: () {
              sendMessage(_controller.text);
              _controller.clear();
            },
            child: _gradientCircle(
              icon: Icons.send_rounded,
              colors: const [_kPurple, _kPurple2],
              glow: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientCircle({
    required IconData icon,
    required List<Color> colors,
    bool glow = false,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: colors.first.withOpacity(0.38),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

// ── Thinking dots ─────────────────────────────────────────────────────────────

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_ctrl.value + i / 3) % 1.0;
            final yOffset = phase < 0.5 ? -phase * 10 : -(1.0 - phase) * 10;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.translate(
                offset: Offset(0, yOffset),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF9B4DFF),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
