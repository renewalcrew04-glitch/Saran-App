import 'package:flutter/material.dart';
import '../services/camera_settings_service.dart';

class CameraSettingsScreen extends StatefulWidget {
  const CameraSettingsScreen({super.key});

  @override
  State<CameraSettingsScreen> createState() => _CameraSettingsScreenState();
}

class _CameraSettingsScreenState extends State<CameraSettingsScreen> {
  bool _defaultFrontCamera = false;
  bool _toolbarOnLeft = true;
  bool _allowCameraRoll = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final front = await CameraSettingsService.getDefaultFrontCamera();
    final left = await CameraSettingsService.getToolbarOnLeft();
    final roll = await CameraSettingsService.getAllowCameraRoll();
    if (mounted) {
      setState(() {
        _defaultFrontCamera = front;
        _toolbarOnLeft = left;
        _allowCameraRoll = roll;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Camera settings',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: scheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done',
                style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: scheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: 'Story'),
                  _SettingTile(
                    icon: Icons.add_circle_outline,
                    iconBg: scheme.primary.withValues(alpha: 0.15),
                    iconColor: scheme.primary,
                    title: 'Story',
                    onTap: () {},
                  ),
                  _SectionHeader(title: 'Controls'),
                  _SwitchTile(
                    title: 'Default to front camera',
                    value: _defaultFrontCamera,
                    onChanged: (v) async {
                      setState(() => _defaultFrontCamera = v);
                      await CameraSettingsService.setDefaultFrontCamera(v);
                    },
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Camera tools'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Choose which side of the screen you want your camera toolbar to be on.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  _RadioTile(
                    title: 'Left-hand side',
                    selected: _toolbarOnLeft,
                    onTap: () async {
                      setState(() => _toolbarOnLeft = true);
                      await CameraSettingsService.setToolbarOnLeft(true);
                    },
                  ),
                  _RadioTile(
                    title: 'Right-hand side',
                    selected: !_toolbarOnLeft,
                    onTap: () async {
                      setState(() => _toolbarOnLeft = false);
                      await CameraSettingsService.setToolbarOnLeft(false);
                    },
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Camera roll'),
                  _SwitchTile(
                    title: 'Allow access',
                    value: _allowCameraRoll,
                    onChanged: (v) async {
                      setState(() => _allowCameraRoll = v);
                      await CameraSettingsService.setAllowCameraRoll(v);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Allow SARAN to suggest stories and prepare content from photos and videos on your device using data such as image quality and location. Learn more',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: scheme.primary,
          ),
        ],
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _RadioTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? scheme.primary
                        : scheme.outline,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
