import 'package:flutter/material.dart';

/// Dashboard ve takvim ekranlarında duruşma/görüşme/süre/iş/ödeme gibi
/// farklı türdeki kayıtları tek tip görünümle listelemek için kullanılan
/// genel amaçlı satır widget'ı.
class EventTile extends StatelessWidget {
  const EventTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.14),
        foregroundColor: color,
        child: Icon(icon, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }
}
