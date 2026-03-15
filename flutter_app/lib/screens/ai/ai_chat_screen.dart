import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/voice_profiles.dart';
import '../../services/ai_service.dart';
import '../../widgets/ai_wave_ring.dart';

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

  bool listening = false;
  bool loading = false;
  bool conversationMode = false;
  bool femaleVoice = true;
  bool typingMode = false;

  List<Map<String, String>> messages = [];

  String subtitleText = "";
  String selectedLanguage = "en_US";
  String selectedVoice = "saran_luna";

  Map<String, String> languages = {
    "English": "en_US",
    "Hindi": "hi_IN",
    "Tamil": "ta_IN",
    "Telugu": "te_IN",
    "Kannada": "kn_IN",
    "Malayalam": "ml_IN"
  };

  /* ---------------- INIT ---------------- */

  @override
  void initState() {
    super.initState();

    _inputFocus.addListener(() {
      if (_inputFocus.hasFocus) {
        setState(() {
          typingMode = true;
          conversationMode = false; // ensure voice mode stops
        });
      }
    });

    setupVoice().then((_) {
      setVoice();
    });
  }

  @override
  void dispose() {
    _inputFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  /* ---------------- VOICE SETUP ---------------- */

  Future setupVoice() async {
    await tts.awaitSpeakCompletion(true);
    await tts.setLanguage("en-US");
    await tts.setSpeechRate(0.48);
    await tts.setPitch(1.0);
    await tts.setVolume(1.0);
  }

  Future setVoice() async {
    if (!Platform.isAndroid) return;
    try {
      await tts.setVoice({
        "name": selectedVoice,
        "locale": selectedLanguage.replaceAll("_", "-"),
      });
    } catch (_) {
      // Custom voice names (saran_luna etc.) may not exist on device; use default voice
    }
  }

  /* ---------------- CLEAN TEXT ---------------- */

  String cleanText(String text) {
    text = text.replaceAll(RegExp(r'[*#@_]'), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text;
  }

  /* ---------------- CONVERSATION ---------------- */

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

  /* ---------------- SEND MESSAGE ---------------- */

  Future sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    await speech.stop();

    setState(() {
      messages.add({"role": "user", "text": text});
      loading = true;
    });

    final languageName = languages.entries
        .where((e) => e.value == selectedLanguage)
        .map((e) => e.key)
        .firstOrNull ?? 'English';
    final response = await AIService.sendMessage(context, text, language: languageName);

    // ERROR FIX: Prevent calling setState if widget was disposed during await
    if (!mounted) return;

    String reply = response ?? "AI error";

    setState(() {
      messages.add({"role": "ai", "text": reply});
      loading = false;
    });

    if (reply.isNotEmpty) {
      await speakStreaming(reply);
    }

    if (conversationMode) {
      startListening();
    }
  }

  /* ---------------- SPEAK STREAMING ---------------- */

  Future speakStreaming(String text) async {
    List<String> sentences = text.split(RegExp(r'[.!?]'));
    for (String s in sentences) {
      if (s.trim().isEmpty) continue;
      if (mounted) {
        setState(() {
          subtitleText = cleanText(s);
        });
      }
      try {
        await tts.speak(cleanText(s));
      } catch (_) {
        // TTS failed (e.g. unsupported voice); skip this sentence
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice playback failed. You can still read the reply.')),
          );
        }
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (mounted) {
      setState(() {
        subtitleText = "";
      });
    }
  }

  /* ---------------- LISTENING ---------------- */

  String get _speechLocale {
    return selectedLanguage.replaceAll('_', '-');
  }

  Future startListening() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is needed for voice conversation')),
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

    setState(() {
      listening = true;
    });

    speech.listen(
      localeId: _speechLocale,
      partialResults: true,
      listenMode: ListenMode.dictation,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      onResult: (result) {
        final text = result.recognizedWords;
        if (mounted) {
          setState(() {
            _controller.text = text;
          });
        }
        if (result.finalResult && text.trim().isNotEmpty) {
          sendMessage(text);
        }
      },
    );
  }

  /* ---------------- AVATAR ---------------- */

  Widget avatar() {
    String avatarImg = femaleVoice
        ? "assets/companions/female.png"
        : "assets/companions/male.png";

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AIWaveRing(
              active: listening || loading || subtitleText.isNotEmpty,
              size: 250,
            ),
            CircleAvatar(
              radius: 110,
              backgroundImage: AssetImage(avatarImg),
              backgroundColor: Colors.transparent,
            )
          ],
        ),
        const SizedBox(height: 25),
        if (subtitleText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              subtitleText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          )
      ],
    );
  }

  /* ---------------- VOICE CHIP WIDGET ---------------- */
  
  Widget voiceChip(dynamic v, Function setModalState) {
    return GestureDetector(
      onTap: () {
        setModalState(() {
          selectedVoice = v.id;
        });

        setState(() {});
        setVoice();
      },
      child: Container(
        width: 90,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selectedVoice == v.id
              ? const LinearGradient(
                  colors: [
                    Color(0xFF8E5CFF),
                    Color(0xFF6E3CFF),
                  ],
                )
              : null,
          color: selectedVoice == v.id ? null : Colors.white,
          border: selectedVoice == v.id
              ? null
              : Border.all(
                  width: 2,
                  color: const Color(0xFF3F6DFF),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Text(
          v.id.replaceAll("saran_", ""),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: selectedVoice == v.id ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  /* ---------------- SETTINGS ---------------- */

  void openSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "AI Settings",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(
                      thickness: 1,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 20),

                    // LANGUAGE DROPDOWN
                    GestureDetector(
                      onTap: () async {
                        final selected = await showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: languages.entries.map((e) {
                                  return ListTile(
                                    title: Text(
                                      e.key,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    trailing: selectedLanguage == e.value
                                        ? const Icon(Icons.check, color: Colors.blue)
                                        : null,
                                    onTap: () {
                                      Navigator.pop(context, e.value);
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        );

                        if (selected != null) {
                          // 1. Update the Bottom Sheet UI immediately
                          setModalState(() {
                            selectedLanguage = selected;
                            });
                            // 2. Update the main screen in the background
                            setState(() {}); 
                            setVoice();
                            }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              languages.keys.firstWhere(
                                (k) => languages[k] == selectedLanguage,
                              ),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.keyboard_arrow_down),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // GENDER BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              femaleVoice = true;
                            });
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 26, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF5E8BFF),
                                  Color(0xFF3F6DFF),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Text(
                              "Female Voices",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              femaleVoice = false;
                            });
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 26, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF5E8BFF),
                                  Color(0xFF3F6DFF),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Text(
                              "Male Voices",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // VOICE LIST
                    Column(
                      children: [
                        /// ROW 1 (3 voices)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: (femaleVoice
                                  ? VoiceProfiles.female
                                  : VoiceProfiles.male)
                              .take(3)
                              .map((v) => voiceChip(v, setModalState))
                              .toList(),
                        ),

                        const SizedBox(height: 12),

                        /// ROW 2 (2 voices)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: (femaleVoice
                                  ? VoiceProfiles.female
                                  : VoiceProfiles.male)
                              .skip(3)
                              .take(2)
                              .map((v) => voiceChip(v, setModalState))
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /* ---------------- CHAT UI ---------------- */

  Widget chatList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isUser = msg["role"] == "user";

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              msg["text"] ?? "",
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SARAN AI"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: openSettings,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: typingMode ? chatList() : Center(child: avatar()),
          ),
          const Divider(height: 1),

          /* ---------------- INPUT BAR ---------------- */
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // START / END CONVO BUTTON (DEFAULT SCREEN)
                if (!typingMode) ...[
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.mic, size: 18),
                      label: Text(
                        conversationMode ? "End Convo" : "Start Convo",
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            conversationMode ? Colors.red : Colors.blue,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: conversationMode
                          ? stopConversation
                          : startConversation,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                // WAVE BUTTON (ONLY IN CHAT MODE)
                if (typingMode) ...[
                  GestureDetector(
                    onTap: () {
                      startConversation();
                      setState(() {
                        typingMode = false;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF4A8CFF),
                            Color(0xFF2A6FFF),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.graphic_eq,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // TEXT INPUT
                Expanded(
                  flex: typingMode ? 5 : 1,
                  child: TextField(
                    focusNode: _inputFocus,
                    controller: _controller,
                    onTap: () {
                      setState(() {
                        typingMode = true;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: "Ask SARAN AI...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // SEND BUTTON
                IconButton(
                  icon: const Icon(Icons.rocket_launch),
                  onPressed: () {
                    sendMessage(_controller.text);
                    _controller.clear();
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}