import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SoundboardScreen extends StatefulWidget {
  const SoundboardScreen({super.key});

  @override
  State<SoundboardScreen> createState() => _SoundboardScreenState();
}

class _SoundboardScreenState extends State<SoundboardScreen> {
  String? active;

  final List<_SoundItem> sounds = const [
    _SoundItem(id: "rain", label: "Rain", icon: FontAwesomeIcons.cloudRain),
    _SoundItem(id: "wind", label: "Wind", icon: FontAwesomeIcons.wind),
    _SoundItem(id: "chimes", label: "Chimes", icon: FontAwesomeIcons.bell),
    _SoundItem(id: "ocean", label: "Ocean", icon: FontAwesomeIcons.water),
    _SoundItem(id: "hum", label: "Hum", icon: FontAwesomeIcons.music),
  ];

  void toggle(String id) {
    setState(() {
      if (active == id) {
        active = null;
      } else {
        active = id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playingLabel = active == null
        ? null
        : sounds.firstWhere((s) => s.id == active!).label;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("S-Zen Soundboard"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tap to play (dummy for now)",
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: GridView.builder(
                itemCount: sounds.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final s = sounds[index];
                  final isActive = active == s.id;

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => toggle(s.id),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isActive ? Colors.black : const Color(0xFFDDDDDD),
                        ),
                        color: isActive ? Colors.black : Colors.white,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            s.icon,
                            size: 22,
                            color: isActive ? Colors.white : Colors.black,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (playingLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: Text(
                    "Playing $playingLabel",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SoundItem {
  final String id;
  final String label;
  final IconData icon;

  const _SoundItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}
