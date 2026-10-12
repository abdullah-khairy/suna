import 'package:flutter/material.dart';
import 'constractor/usercon.dart';

class UserProfileCard extends StatelessWidget {
  final Usercon user;
  final VoidCallback? onCallPressed;
  final VoidCallback? onLocationPressed;

  const UserProfileCard({
    super.key,
    required this.user,
    this.onCallPressed,
    this.onLocationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الهيدر: الصورة الشخصية، الاسم والوظيفة
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Text(
                      user.name != null && user.name!.isNotEmpty
                          ? user.name![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name ?? 'اسم غير محدد',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.jop != null && user.jop!.isNotEmpty
                                ? user.jop!
                                : 'مستخدم',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade100,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Divider(color: Colors.white24, height: 1),
              ),

              // التفاصيل: رقم الهاتف
              _buildInfoRow(
                icon: Icons.phone,
                title: 'رقم الهاتف',
                value: user.phone ?? 'غير متوفر',
                trailing: onCallPressed != null
                    ? IconButton(
                        icon: const Icon(Icons.call, color: Colors.greenAccent, size: 20),
                        onPressed: onCallPressed,
                        tooltip: 'اتصال',
                      )
                    : null,
              ),
              const SizedBox(height: 10),

              // التفاصيل: نبذة
              if (user.discription != null && user.discription!.isNotEmpty) ...[
                _buildInfoRow(
                  icon: Icons.description_outlined,
                  title: 'نبذة شخصية',
                  value: user.discription!,
                ),
                const SizedBox(height: 10),
              ],

              // التفاصيل: الموقع الإحداثي
              if (user.location != null)
                _buildInfoRow(
                  icon: Icons.location_on,
                  title: 'الموقع الجغرافي',
                  value:
                      'Lat: ${user.location!.latitude.toStringAsFixed(3)}, Long: ${user.location!.longitude.toStringAsFixed(3)}',
                  trailing: onLocationPressed != null
                      ? IconButton(
                          icon: const Icon(Icons.directions, color: Colors.amberAccent, size: 20),
                          onPressed: onLocationPressed,
                          tooltip: 'عرض المسار',
                        )
                      : null,
                ),

              const SizedBox(height: 12),

              // عرض الـ ID الخاص بالمستند أسفل الكارت
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'ID: ${user.id ?? 'غير مسجل'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}