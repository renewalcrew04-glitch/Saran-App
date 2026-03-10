import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/ai_service.dart';
import '../../widgets/ai_wave_ring.dart';
import '../../widgets/ai_streaming_subtitle.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {

  final TextEditingController _controller = TextEditingController();
  final SpeechToText speech = SpeechToText();
  final FlutterTts tts = FlutterTts();

  bool listening = false;
  bool loading = false;
  bool conversationMode = false;
  bool femaleVoice = true;

  bool speechMode = true;

  List<Map<String, String>> messages = [];

  List<Map<String, String>> voices = [];
  Map<String, String>? selectedVoice;

  String selectedLanguage = "en_US";

  String subtitleText = "";

  Map<String,String> languages = {
    "English":"en_US",
    "Hindi":"hi_IN",
    "Tamil":"ta_IN",
    "Telugu":"te_IN",
    "Kannada":"kn_IN",
    "Malayalam":"ml_IN",
    "Marathi":"mr_IN",
    "Punjabi":"pa_IN",
    "Odia":"or_IN",
    "Urdu":"ur_PK"
  };

  String currentEmotion = "neutral";

  @override
  void initState() {
    super.initState();
    setupVoice();
    loadVoices();
  }

  // ---------- VOICE SETUP ----------

  Future setupVoice() async {

    await tts.awaitSpeakCompletion(true);
    await tts.setLanguage("en-US");
    await tts.setSpeechRate(0.4);
    await tts.setPitch(1.0);

    await setVoice();
  }

  Future loadVoices() async {
    final result = await tts.getVoices;

    if (result is List && result.isNotEmpty) {
      final first = result.first;
      if (first is Map) {
        final mapped = first.map((key, value) =>
            MapEntry(key.toString(), value.toString()));
        voices = [mapped];
        selectedVoice = mapped;
        await tts.setVoice(mapped);
      }
    }
  }

  Future setVoice() async {

    if (femaleVoice) {
      await tts.setVoice({
        "name": "en-us-x-sfg#female_1-local",
        "locale": "en-US"
      });
    } else {
      await tts.setVoice({
        "name": "en-us-x-sfg#male_1-local",
        "locale": "en-US"
      });
    }

  }

  // ---------- CLEAN TEXT ----------

  String cleanText(String text) {

    text = text.replaceAll(RegExp(r'[*#@_]'), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text;

  }

  // ---------- CONVERSATION CONTROL ----------

  Future startConversation() async {

    setState(() {
      conversationMode = true;
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

  // ---------- EMOTION VOICE TONE ----------

  Future applyEmotionTone(String emotion) async {

    currentEmotion = emotion;

    if (emotion == "sad") {
      await tts.setSpeechRate(0.5);
      await tts.setPitch(0.9);
    }

    else if (emotion == "excited") {
      await tts.setSpeechRate(0.7);
      await tts.setPitch(1.2);
    }

    else {
      await tts.setSpeechRate(0.6);
      await tts.setPitch(1.0);
    }

  }

  // ---------- AI MESSAGE ----------

  Future sendMessage(String text) async {

    if (text.trim().isEmpty) return;

    await speech.stop();

    setState(() {

      messages.add({
        "role": "user",
        "text": text
      });

      loading = true;

    });

    final response = await AIService.sendMessage(context, text);

    String reply = response ?? "AI error";

    if(reply.contains("sorry") || reply.contains("sad")){
       await applyEmotionTone("sad");
    }
    else if(reply.contains("great") || reply.contains("excited")){
       await applyEmotionTone("excited");
    }
    else{
       await applyEmotionTone("neutral");
    }

    setState(() {

      messages.add({
        "role": "ai",
        "text": reply
      });

      loading = false;

    });

    await speakStreaming(reply);

    if (conversationMode) {
      startListening();
    }

  }

  // ---------- STREAMING SPEECH ----------

Future speakStreaming(String text) async {

  List<String> sentences = text.split(".");

  for (String s in sentences) {

    if (s.trim().isEmpty) continue;

    setState(() {
      subtitleText = cleanText(s);
    });

    await tts.speak(cleanText(s));
    await tts.awaitSpeakCompletion(true);

  }

  setState(() {
    subtitleText = "";
  });

}

  // ---------- LISTENING ----------

  Future startListening() async {

    var status = await Permission.microphone.request();

    if (!status.isGranted) {
      return;
    }

    bool available = await speech.initialize(
      onStatus: (status) {
        print("Speech status: $status");
      },
      onError: (error) {

        print("Speech error: $error");

        if (conversationMode) {
          startListening();
        }

      },
    );

    if (!available) return;

    setState(() {
      listening = true;
    });

    speech.listen(
      localeId: selectedLanguage,
      partialResults: false,
      listenMode: ListenMode.dictation,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      cancelOnError: false,
      onResult: (result) {

        String text = result.recognizedWords;

        setState(() {
          _controller.text = text;
        });

        if (result.finalResult) {
          sendMessage(text);
        }

      },
    );

  }

  // ---------- AVATAR ----------

  Widget companionAvatar(){

  String avatar = femaleVoice
      ? "assets/companions/female.png"
      : "assets/companions/male.png";

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [

      Stack(
        alignment: Alignment.center,
        children: [

          AIWaveRing(
            active: listening || loading,
            size: 250,
          ),

          CircleAvatar(
            radius: 110,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage(avatar),
          ),

        ],
      ),

      const SizedBox(height: 30),

      if(subtitleText.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AIStreamingSubtitle(
            text: subtitleText,
          ),
        )

    ],
  );
}

  // ---------- MESSAGE UI ----------

  Widget messageBubble(Map<String,String> msg) {

    final isUser = msg["role"] == "user";

    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.blue
              : Colors.grey.shade300,
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

  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("SARAN AI"),
      ),

      body: Column(
        children: [

          // LANGUAGE

          Padding(
            padding: const EdgeInsets.all(8),
            child: DropdownButton<String>(
              value: selectedLanguage,
              items: languages.entries.map((e) {
                return DropdownMenuItem(
                  value: e.value,
                  child: Text(e.key),
                );
              }).toList(),
              onChanged: (value){
                setState(() {
                  selectedLanguage = value!;
                });
              },
            ),
          ),

          // VOICE SWITCH

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Switch(
                value: femaleVoice,
                onChanged: (value) {

                  setState(() {
                    femaleVoice = value;
                  });

                  setVoice();

                },
              ),

              Text(femaleVoice ? "Female Voice" : "Male Voice"),

            ],
          ),

          // CHAT / AVATAR

          Expanded(
            child: speechMode
                ? Center(child: companionAvatar())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context,index){
                      return messageBubble(messages[index]);
                    },
                  ),
          ),

          if (listening)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.graphic_eq, color: Colors.red, size: 30),
                  SizedBox(width: 10),
                  Text(
                    "SARAN AI is listening",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          if (loading)
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text("SARAN AI is thinking..."),
            ),

          const Divider(height:1),

          // INPUT

          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [

                conversationMode
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.stop),
                        label: const Text("End Conversation"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: stopConversation,
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.mic),
                        label: const Text("Start Conversation"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: startConversation,
                      ),

                const SizedBox(width: 8),

                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ask SARAN AI...",
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: (){
                    sendMessage(_controller.text);
                    _controller.clear();
                  },
                )

              ],
            ),
          )
        ],
      ),
    );
  }
}