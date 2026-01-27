import 'package:flutter/material.dart';

class RepostBottomSheet {
  static void show({
    required BuildContext context,
    required VoidCallback onRepost,
    required VoidCallback onQuote,
    required bool alreadyReposted,
    required VoidCallback onUndo,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!alreadyReposted)
                _Action(
                  icon: Icons.repeat,
                  label: 'Repost',
                  onTap: () {
                    Navigator.pop(context);
                    onRepost();
                  },
                ),
              _Action(
                icon: Icons.mode_edit_outline,
                label: 'Quote',
                onTap: () {
                  Navigator.pop(context);
                  onQuote();
                },
              ),
              if (alreadyReposted)
                _Action(
                  icon: Icons.undo,
                  label: 'Undo repost',
                  onTap: () {
                    Navigator.pop(context);
                    onUndo();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}
