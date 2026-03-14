import 'speech_player_service.dart';

class VoiceInterruptController {

  static void onUserSpeak() {

    if (SpeechPlayerService.isSpeaking) {
      SpeechPlayerService.stop();
    }

  }

}