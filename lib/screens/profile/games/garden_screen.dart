import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  static const int maxPlants = 12;

  static const _keyPlants = "garden_plants";
  static const _keyLastSeeded = "garden_last_seeded";
  static const _keyLastWatered = "garden_last_watered";

  List<GardenPlant> plants = [];
  String? lastSeededDay;
  String? lastWateredDay;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadGarden();
  }

  Future<void> _loadGarden() async {
    final prefs = await SharedPreferences.getInstance();

    final rawPlants = prefs.getStringList(_keyPlants) ?? [];
    final loadedPlants = <GardenPlant>[];

    for (final raw in rawPlants) {
      final parts = raw.split("|");
      if (parts.length < 3) continue;

      final id = int.tryParse(parts[0]) ?? 0;
      final plantedAt = DateTime.tryParse(parts[1]);
      final wateredAt = DateTime.tryParse(parts[2]);

      if (plantedAt == null || wateredAt == null) continue;

      loadedPlants.add(
        GardenPlant(
          id: id,
          plantedAt: plantedAt,
          wateredAt: wateredAt,
        ),
      );
    }

    setState(() {
      plants = loadedPlants;
      lastSeededDay = prefs.getString(_keyLastSeeded);
      lastWateredDay = prefs.getString(_keyLastWatered);
      loading = false;
    });
  }

  Future<void> _saveGarden() async {
    final prefs = await SharedPreferences.getInstance();

    final rawPlants = plants
        .map((p) => "${p.id}|${p.plantedAt.toIso8601String()}|${p.wateredAt.toIso8601String()}")
        .toList();

    await prefs.setStringList(_keyPlants, rawPlants);

    if (lastSeededDay != null) {
      await prefs.setString(_keyLastSeeded, lastSeededDay!);
    }
    if (lastWateredDay != null) {
      await prefs.setString(_keyLastWatered, lastWateredDay!);
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  PlantStage _getStage(GardenPlant plant) {
    final days = DateTime.now().difference(plant.plantedAt).inDays;
    if (days == 0) return PlantStage.seed;
    if (days == 1) return PlantStage.seedling;
    return PlantStage.tree;
  }

  bool get _canSeedToday {
    return lastSeededDay != _todayKey();
  }

  bool get _canWaterToday {
    return lastWateredDay != _todayKey();
  }

  Future<void> _plantSeed() async {
    if (!_canSeedToday) {
      _toast("You already planted today 🌱");
      return;
    }

    if (plants.length >= maxPlants) {
      _toast("Garden is full (12 plants max)");
      return;
    }

    plants.add(
      GardenPlant(
        id: DateTime.now().millisecondsSinceEpoch,
        plantedAt: DateTime.now(),
        wateredAt: DateTime.now(),
      ),
    );

    lastSeededDay = _todayKey();

    setState(() {});
    await _saveGarden();
  }

  Future<void> _waterGarden() async {
    if (plants.isEmpty) return;

    if (!_canWaterToday) {
      _toast("You already watered today 💧");
      return;
    }

    for (final p in plants) {
      p.wateredAt = DateTime.now();
    }

    lastWateredDay = _todayKey();

    setState(() {});
    await _saveGarden();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("S-Garden"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Grow something small, every day.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _TopActions(
                    plantsCount: plants.length,
                    canSeed: _canSeedToday && plants.length < maxPlants,
                    canWater: _canWaterToday && plants.isNotEmpty,
                    onSeed: _plantSeed,
                    onWater: _waterGarden,
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: GridView.builder(
                      itemCount: maxPlants,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        if (index >= plants.length) {
                          // Empty slots
                          return _EmptySlot(
                            showAdd: index == plants.length && plants.length < maxPlants,
                            onAdd: _plantSeed,
                          );
                        }

                        final plant = plants[index];
                        final stage = _getStage(plant);

                        return _PlantTile(stage: stage);
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (plants.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _waterGarden,
                        child: const Text(
                          "Water Garden",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

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

class _PlantTile extends StatelessWidget {
  final PlantStage stage;

  const _PlantTile({required this.stage});

  @override
  Widget build(BuildContext context) {
    IconData icon;

    if (stage == PlantStage.seed) {
      icon = FontAwesomeIcons.circleDot;
    } else if (stage == PlantStage.seedling) {
      icon = FontAwesomeIcons.seedling;
    } else {
      icon = FontAwesomeIcons.tree;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: FaIcon(icon, size: 26, color: Colors.black),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final bool showAdd;
  final VoidCallback onAdd;

  const _EmptySlot({
    required this.showAdd,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (!showAdd) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEDED)),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onAdd,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black12,
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            "＋",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopActions extends StatelessWidget {
  final int plantsCount;
  final bool canSeed;
  final bool canWater;
  final VoidCallback onSeed;
  final VoidCallback onWater;

  const _TopActions({
    required this.plantsCount,
    required this.canSeed,
    required this.canWater,
    required this.onSeed,
    required this.onWater,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniActionButton(
            title: "Plant",
            subtitle: canSeed ? "Available today" : "Done today",
            icon: Icons.add_circle_outline,
            enabled: canSeed,
            onTap: onSeed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniActionButton(
            title: "Water",
            subtitle: canWater ? "Available today" : "Done today",
            icon: Icons.water_drop_outlined,
            enabled: canWater,
            onTap: onWater,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDEDED)),
          ),
          child: Column(
            children: [
              Text(
                "$plantsCount/12",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "Plants",
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _MiniActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDEDED)),
          color: enabled ? Colors.white : const Color(0xFFF7F7F7),
        ),
        child: Row(
          children: [
            Icon(icon, color: enabled ? Colors.black : Colors.black38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: enabled ? Colors.black : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: enabled ? Colors.black54 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
