import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/meeting.dart';
import '../services/email_template.dart';

/// Convenience helper so the page can just call:
/// await showMeetingEmailDialog(...);
Future<void> showMeetingEmailDialog({
  required BuildContext context,
  required Meeting meeting,
  required String currentUserName,
  required String point1,
  required String point2,
  required String point3,
}) async {
  await showDialog(
    context: context,
    builder: (_) => MeetingEmailDialog(
      meeting: meeting,
      currentUserName: currentUserName,
      point1: point1,
      point2: point2,
      point3: point3,
    ),
  );
}

class MeetingEmailDialog extends StatefulWidget {
  final Meeting meeting;
  final String currentUserName;

  /// These come from the text fields on the Meeting detail page
  final String point1;
  final String point2;
  final String point3;

  const MeetingEmailDialog({
    super.key,
    required this.meeting,
    required this.currentUserName,
    required this.point1,
    required this.point2,
    required this.point3,
  });

  @override
  State<MeetingEmailDialog> createState() => _MeetingEmailDialogState();
}

class _MeetingEmailDialogState extends State<MeetingEmailDialog> {
  /// 🔗 n8n webhook for SENDING EMAILS (not points)
  static const String _emailWebhookUrl =
      'https://fitsit.app.n8n.cloud/webhook/c4ef887e-3a3d-4234-9ee0-eb754d16c1b6';

  late TextEditingController _subjectController;
  late TextEditingController _bodyController;

  bool _isSending = false;

  List<String> _collectRecipients(Meeting m) {
    return [
      m.client1Email,
      if (m.client2Email != null && m.client2Email!.isNotEmpty)
        m.client2Email!,
      if (m.client3Email != null && m.client3Email!.isNotEmpty)
        m.client3Email!,
    ];
  }

  @override
  void initState() {
    super.initState();

    final m = widget.meeting;

    _subjectController = TextEditingController(
      text: 'Meeting summary: ${m.heading}',
    );

    // 👉 Build email body using the template AND the latest points
    _bodyController = TextEditingController(
      text: buildMeetingSummaryEmail(
        meeting: m,
        currentUserName: widget.currentUserName,
        point1: widget.point1, // values from the text boxes
        point2: widget.point2,
        point3: widget.point3,
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail(List<String> recipients) async {
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    if (recipients.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No client emails to send to.')),
      );
      return;
    }

    if (subject.isEmpty || body.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject and body cannot be empty.')),
      );
      return;
    }

    // 🛑 Confirmation dialog
final confirm = await showDialog<bool>(
  context: context,
  builder: (ctx) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirm send'),
      content: Text(
        'Are you sure you want to send this email to:\n\n'
        '${recipients.join(', ')}?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'No',
            style: TextStyle(fontSize: 13),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: const Text(
            'Yes, send',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  },
);


    if (confirm != true) return;

    final payload = {
      'rowId': widget.meeting.rowId,
      'rowNumber': widget.meeting.rowNumber,
      'heading': widget.meeting.heading,
      'creatorEmail': widget.meeting.creatorEmail,
      'to': recipients,
      'subject': subject,
      'body': body,
    };

    if (kDebugMode) {
      print('📧 Sending email via n8n: $payload');
    }

    try {
      setState(() => _isSending = true);

      final uri = Uri.parse(_emailWebhookUrl);
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email request sent successfully.')),
        );
        Navigator.of(context).pop(); // close dialog
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email request failed: ${resp.statusCode} ${resp.reasonPhrase}',
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Email error: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meeting;
    final recipients = _collectRecipients(m);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Email meeting minutes'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To:',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            if (recipients.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: recipients
                    .map(
                      (email) => Chip(
                        label: Text(
                          email,
                          style: textTheme.labelSmall,
                        ),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      ),
                    )
                    .toList(),
              )
            else
              Text(
                'No client emails found',
                style: textTheme.bodySmall
                    ?.copyWith(color: Colors.redAccent.shade100),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Body',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can edit the subject and body before sending.',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
      actions: [
  TextButton(
    onPressed: _isSending ? null : () => Navigator.of(context).pop(),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: const Text(
      'Cancel',
      style: TextStyle(fontSize: 13),
    ),
  ),
  ElevatedButton.icon(
    onPressed: _isSending ? null : () => _sendEmail(recipients),
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    ),
    icon: _isSending
        ? const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(
            Icons.send,
            size: 16,
          ),
    label: Text(
      _isSending ? 'Sending...' : 'Send',
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
  ),
]
,
    );
  }
}
