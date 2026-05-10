import 'package:flutter/material.dart';
import '../../../shared/app_colors.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl; // Opsional: jika ada gambar
  final IconData? icon; // Opsional: jika pakai ikon saja
  final VoidCallback onDetailPressed;

  const NotificationCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.icon,
    required this.onDetailPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgTeal,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          // BAGIAN KIRI: GAMBAR ATAU IKON
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.white.withOpacity(0.5),
              child:
                  imageUrl != null
                      ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Icon(Icons.image, color: Colors.grey),
                      )
                      : Icon(
                        icon ?? Icons.notifications,
                        size: 40,
                        color: Colors.black87,
                      ),
            ),
          ),
          const SizedBox(width: 20),

          // BAGIAN TENGAH: TEKS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textTealDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),

          // BAGIAN KANAN: TOMBOL DETAIL
          ElevatedButton(
            onPressed: onDetailPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Detail", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
