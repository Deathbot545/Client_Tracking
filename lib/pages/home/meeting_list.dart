import 'package:flutter/material.dart';
import '../../../models/meeting.dart';

class MeetingList extends StatelessWidget {
  final List<Meeting> meetings;
  final bool isLoading;
  final String emptyText;
  final String? errorText;
  final Future<void> Function() onRetry;
  final void Function(Meeting) onTap;

  const MeetingList({
    super.key,
    required this.meetings,
    required this.isLoading,
    required this.emptyText,
    required this.errorText,
    required this.onRetry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Loading state (first load)
    if (isLoading && meetings.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (errorText != null && meetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 32),
            const SizedBox(height: 8),
            Text(
              errorText!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (meetings.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF38BDF8),
      onRefresh: onRetry,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        itemCount: meetings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final m = meetings[i];

          final creatorDisplay =
              (m.creatorName.isNotEmpty ? m.creatorName : m.creatorEmail);

          // Simple createdAt label
          final createdLabel = m.createdAt != null
              ? 'Created: ${m.createdAt!.toLocal().toString().substring(0, 16)}'
              : '';

          final hasRecording = (m.recordingId != null &&
              m.recordingId!.trim().isNotEmpty);

          final hasStatus = (m.status != null && m.status!.trim().isNotEmpty);

          return InkWell(
            onTap: () => onTap(m),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF020617).withOpacity(0.95),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon/avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_note,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Main text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + status pill
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                m.heading.isNotEmpty
                                    ? m.heading
                                    : '(No title)',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            if (hasStatus) ...[
                              const SizedBox(width: 8),
                              _StatusChip(text: m.status!.trim()),
                            ],
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Client line
                        Text(
                          'Client: ${m.client1Name.isNotEmpty ? m.client1Name : m.client1Email}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[300],
                                  ),
                        ),

                        const SizedBox(height: 2),

                        if (createdLabel.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            createdLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                          ),
                        ],

                        const SizedBox(height: 6),

                        // Extra chips: recording / minutes
                        Row(
                          children: [
                            if (hasRecording)
                              _SmallTag(
                                icon: Icons.mic,
                                label: 'Recording',
                              ),
                            if (m.finalMinutes != null &&
                                m.finalMinutes!.trim().isNotEmpty) ...[
                              if (hasRecording) const SizedBox(width: 6),
                              _SmallTag(
                                icon: Icons.description_outlined,
                                label: 'AI minutes',
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;

  const _StatusChip({required this.text});

  @override
  Widget build(BuildContext context) {
    // You can map specific statuses to different colors if you want later
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey[200],
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallTag({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF38BDF8)),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[200],
                ),
          ),
        ],
      ),
    );
  }
}
