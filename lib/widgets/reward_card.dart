import 'package:flutter/material.dart';

class RewardCard extends StatelessWidget {
  final String rewardText;
  final VoidCallback onTap;

  const RewardCard({super.key, required this.rewardText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEDE7F6), Color(0xFFFCE4EC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_giftcard_rounded, size: 16, color: Color(0xFFE91E63)), 
                const SizedBox(width: 6),
                Text(
                  "WEEKLY COMMITMENT & REWARD", 
                  style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.purple.shade400, fontWeight: FontWeight.bold)
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rewardText, 
              style: const TextStyle(fontSize: 15, color: Color(0xFF2D3436), fontWeight: FontWeight.w600, height: 1.5)
            ),
          ],
        ),
      ),
    );
  }
}