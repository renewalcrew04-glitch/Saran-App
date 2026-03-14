import 'package:audioplayers/audioplayers.dart';

class SpeechPlayerService {

  static final AudioPlayer _player = AudioPlayer();

  static bool isSpeaking = false;

  static Future play(String url) async {
    isSpeaking = true;
    await _player.play(UrlSource(url));
  }

  static Future stop() async {
    isSpeaking = false;
    await _player.stop();
  }

}