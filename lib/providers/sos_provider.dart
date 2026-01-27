import 'package:flutter/foundation.dart';

class SosProvider extends ChangeNotifier {
  bool _isActive = false;
  String? _sosId;

  bool get isActive => _isActive;
  String? get sosId => _sosId;

  void activate(String sosId) {
    _isActive = true;
    _sosId = sosId;
    notifyListeners();
  }

  void deactivate() {
    _isActive = false;
    _sosId = null;
    notifyListeners();
  }
}
