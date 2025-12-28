import 'package:flutter/material.dart';
import '../models/meeting.dart';

class MeetingMinutesCard extends StatelessWidget {
  final Meeting meeting;

  final VoidCallback onSendEmail;

  /// Controllers for the 3 points (live in MeetingDetailPage)
  final TextEditingController point1Controller;
  final TextEditingController point2Controller;
  final TextEditingController point3Controller;

  /// Called when user taps "Update points"
  final Future<void> Function()? onUpdatePoints;

  const MeetingMinutesCard({
    super.key,
    required this.meeting,
    required this.onSendEmail,
    required this.point1Controller,
    required this.point2Controller,
    required this.point3Controller,
    this.onUpdatePoints,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Only Key points section
            Text(
              'Key Discussion Points',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: point1Controller,
              decoration: const InputDecoration(
                labelText: 'Agreed Actions',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: point2Controller,
              decoration: const InputDecoration(
                labelText: 'Responsibilities',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: point3Controller,
              decoration: const InputDecoration(
                labelText: 'Next Steps',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  onPressed: onUpdatePoints == null ? null : () => onUpdatePoints!(),
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Update points'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  onPressed: onSendEmail,
                  icon: const Icon(Icons.email, size: 18),
                  label: const Text('Email'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
