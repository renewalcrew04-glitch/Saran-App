import 'package:flutter/material.dart';
import '../../../../models/user_model.dart';

class SettingsUserTile extends StatelessWidget {
  final User user;
  final String buttonText;
  final Color buttonColor;
  final Color? buttonForegroundColor;
  final VoidCallback onPressed;

  const SettingsUserTile({
    super.key,
    required this.user,
    required this.buttonText,
    required this.buttonColor,
    this.buttonForegroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
            ? NetworkImage(user.avatar!)
            : null,
            child: (user.avatar == null || user.avatar!.isEmpty)
            ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : "S",
                style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface),
              )
            : null,
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text("@${user.username}"),
      trailing: SizedBox(
        height: 34,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: buttonForegroundColor ?? (buttonColor == scheme.primary ? scheme.onPrimary : scheme.onSurfaceVariant),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onPressed,
          child: Text(buttonText),
        ),
      ),
    );
  }
}
