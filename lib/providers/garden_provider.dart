import 'package:flutter/foundation.dart';

class GardenPlant {
  final int id;
  final DateTime plantedAt;
  DateTime wateredAt;

  GardenPlant({
    required this.id,
    required this.plantedAt,
    required this.wateredAt,
  });
}

enum PlantStage { seed, seedling, tree }

class GardenProvider extends ChangeNotifier {
  final List<GardenPlant> plants = [];

  String? lastSeededDay;
  String? lastWateredDay;

  void plantSeed() {
    final today = _todayKey();
    if (lastSeededDay == today) return;

    plants.add(
      GardenPlant(
        id: DateTime.now().millisecondsSinceEpoch,
        plantedAt: DateTime.now(),
        wateredAt: DateTime.now(),
      ),
    );

    lastSeededDay = today;
    notifyListeners();
  }

  void water() {
    final today = _todayKey();
    if (lastWateredDay == today) return;

    for (final p in plants) {
      p.wateredAt = DateTime.now();
    }

    lastWateredDay = today;
    notifyListeners();
  }

  PlantStage getStage(GardenPlant plant) {
    final days = DateTime.now().difference(plant.plantedAt).inDays;

    if (days == 0) return PlantStage.seed;
    if (days == 1) return PlantStage.seedling;
    return PlantStage.tree;
  }

  String _todayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }
}
