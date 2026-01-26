import 'package:flutter/material.dart';
import '../../../../models/user_model.dart';

class SettingsUserTile extends StatelessWidget {
  final User user;
  final String buttonText;
  final Color buttonColor;
  final VoidCallback onPressed;

  const SettingsUserTile({
    super.key,
    required this.user,
    required this.buttonText,
    required this.buttonColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
            ? NetworkImage(user.avatar!)
            : null,
        child: (user.avatar == null || user.avatar!.isEmpty)
            ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : "S",
                style: const TextStyle(fontWeight: FontWeight.w800),
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
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onPressed,
          child: Text(buttonText),
        ),
      ),
    );
  }
}
