import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../features/settings/screens/close_friends_screen.dart';
import '../../features/settings/services/settings_api.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sos_provider.dart';
import '../../services/sos_service.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool sendToCloseFriends = true;
  bool sendToNearby = false;
  bool isSending = false;

  int closeFriendsCount = 0;
  final TextEditingController descriptionController = TextEditingController();
  final settingsApi = SettingsApi();

  @override
  void initState() {
    super.initState();
    _loadCloseFriends();
  }

  Future<void> _loadCloseFriends() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    settingsApi.setToken(auth.token!);
    try {
      final list = await settingsApi.getCloseFriends();
      if (mounted) {
        setState(() => closeFriendsCount = list.length);
      }
    } catch (_) {}
  }

  // ---------------- LOCATION ----------------

  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _error("Location services are disabled");
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _error("Location permission denied");
      return false;
    }

    return true;
  }

  // ---------------- SEND SOS ----------------

  Future<void> _sendSOS() async {
    final sosProvider = context.read<SosProvider>();

    if (sosProvider.isActive) {
      _error("SOS already active");
      return;
    }

    if (!sendToCloseFriends && !sendToNearby) {
      _error("Select at least one alert option");
      return;
    }

    if (sendToCloseFriends && closeFriendsCount == 0) {
      _error("No close friends added");
      return;
    }

    setState(() => isSending = true);

    try {
      Position? position;

      if (sendToNearby) {
        if (!await _ensureLocationPermission()) return;
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }

      final payload = {
        "sendToCloseFriends": sendToCloseFriends,
        "sendToNearby": sendToNearby,
        "message": descriptionController.text.trim(),
        "location": position == null
            ? null
            : {
                "lat": position.latitude,
                "lng": position.longitude,
              },
        "radiusKm": sendToNearby ? 2 : null,
      };

      final response = await SosService.sendSOS(context, payload);

      sosProvider.activate(response["sosId"]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Emergency alert sent"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      _error("Failed to send SOS");
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  // ---------------- CANCEL SOS ----------------

  Future<void> _cancelSOS() async {
    final sosProvider = context.read<SosProvider>();
    if (sosProvider.sosId == null) return;

    try {
      await SosService.cancelSOS(context, sosProvider.sosId!);
      sosProvider.deactivate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("SOS cancelled")),
        );
      }
    } catch (_) {
      _error("Failed to cancel SOS");
    }
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final sosActive = context.watch<SosProvider>().isActive;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Emergency SOS"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Emergency SOS",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Your safety is our priority",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 24),
              const Text(
                "Send alert to:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  _AlertCard(
                    title: "Close Friends",
                    subtitle: "$closeFriendsCount people",
                    selected: sendToCloseFriends,
                    onTap: sosActive
                        ? null
                        : () => setState(() =>
                            sendToCloseFriends = !sendToCloseFriends),
                  ),
                  const SizedBox(width: 12),
                  _AlertCard(
                    title: "Nearby People",
                    subtitle: "Within 2km radius",
                    selected: sendToNearby,
                    onTap: sosActive
                        ? null
                        : () => setState(() => sendToNearby = !sendToNearby),
                  ),
                ],
              ),

              if (sendToCloseFriends && closeFriendsCount == 0)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CloseFriendsScreen(),
                    ),
                  ).then((_) => _loadCloseFriends()),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      "No close friends added. Tap to add in settings.",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              const Text("Describe your situation (optional)"),
              const SizedBox(height: 8),

              TextField(
                controller: descriptionController,
                maxLines: 3,
                enabled: !sosActive,
                decoration: InputDecoration(
                  hintText: "Tell us what's happening...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const Spacer(),

              if (sendToNearby)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Location access needed for emergency alerts",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      isSending || sosActive ? null : _sendSOS,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          sosActive
                              ? "SOS ACTIVE"
                              : "Send Emergency Alert",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              if (sosActive)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton(
                    onPressed: _cancelSOS,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text("Cancel SOS"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const _AlertCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.black : Colors.grey.shade300,
              width: 1.4,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
