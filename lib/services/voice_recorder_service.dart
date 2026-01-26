import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

class VoiceRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<String> startRecording() async {
    final ok = await hasPermission();
    if (!ok) {
      throw Exception("Microphone permission denied");
    }

    final tempDir = Directory.systemTemp;
    final filePath = p.join(
      tempDir.path,
      'saran_voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    return filePath;
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
