import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/meeting.dart';

// UI widgets
import '../widgets/meeting_header_card.dart';
import '../widgets/meeting_clients_card.dart';
import '../widgets/meeting_minutes_card.dart'; // ✅ still using same card file
import '../widgets/meeting_location_card.dart';
import '../widgets/meeting_email_dialog.dart';

// Meeting service
import '../services/meeting_service.dart';

// Glide delete API
import '../services/glide_meeting_api.dart';

class MeetingDetailPage extends StatefulWidget {
  final Meeting meeting;
  final String currentUserName;

  const MeetingDetailPage({
    super.key,
    required this.meeting,
    required this.currentUserName,
  });

  @override
  State<MeetingDetailPage> createState() => _MeetingDetailPageState();
}

class _MeetingDetailPageState extends State<MeetingDetailPage> {
  // Local copy that will be replaced with the “full detail” from n8n
  late Meeting _meeting;

  late TextEditingController _point1Controller;
  late TextEditingController _point2Controller;
  late TextEditingController _point3Controller;

  bool _loadingDetail = false;
  String? _detailError;

  /// 🔗 n8n webhook for updating the 3 points
  static const String _updatePointsWebhookUrl =
      'https://fitsit.app.n8n.cloud/webhook/eb15cda9-cdb7-4b8f-96ba-9ee30db55a5d';

  // delete state
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    // Start with the “light” meeting from the list
    _meeting = widget.meeting;

    // Pre-fill controllers from whatever we already have
    _point1Controller = TextEditingController(text: _meeting.agreedActions ?? '');
    _point2Controller = TextEditingController(text: _meeting.responsibilities ?? '');
    _point3Controller = TextEditingController(text: _meeting.nextSteps ?? '');

    // Then fetch the full details from n8n based on rowId
    if (_meeting.rowId != null && _meeting.rowId!.isNotEmpty) {
      _loadDetailByRowId(_meeting.rowId!);
    } else {
      debugPrint('⚠️ No rowId on meeting; cannot load full details.');
    }
  }

  @override
  void dispose() {
    _point1Controller.dispose();
    _point2Controller.dispose();
    _point3Controller.dispose();
    super.dispose();
  }

  // ───────────── DETAIL LOADING ─────────────

  Future<void> _loadDetailByRowId(String rowId) async {
    setState(() {
      _loadingDetail = true;
      _detailError = null;
    });

    try {
      final detailed = await MeetingService.loadMeetingByRowId(rowId);

      if (!mounted) return;

      setState(() {
        _meeting = detailed;
        _loadingDetail = false;

        _point1Controller.text = detailed.agreedActions ?? '';
        _point2Controller.text = detailed.responsibilities ?? '';
        _point3Controller.text = detailed.nextSteps ?? '';
      });

      debugPrint('✅ Loaded detail for rowId=$rowId');
    } catch (e, st) {
      debugPrint('❌ loadMeetingByRowId error: $e');
      debugPrint(st.toString());

      if (!mounted) return;
      setState(() {
        _loadingDetail = false;
        _detailError = e.toString();
      });
    }
  }

  Future<void> _refreshDetail() async {
    final rowId = _meeting.rowId;
    if (rowId == null || rowId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot refresh: missing rowId.')),
      );
      return;
    }
    await _loadDetailByRowId(rowId);
  }

  // ───────────── EMAIL DIALOG ─────────────

  Future<void> _openEmailDialog() async {
    await showMeetingEmailDialog(
      context: context,
      meeting: _meeting,
      currentUserName: widget.currentUserName,
      point1: _point1Controller.text.trim(),
      point2: _point2Controller.text.trim(),
      point3: _point3Controller.text.trim(),
    );
  }

  // ───────────── UPDATE POINTS ─────────────

  Future<void> _updatePoints() async {
    final rowId = _meeting.rowId;
    final rowNumber = _meeting.rowNumber;

    if (rowId == null || rowId.isEmpty || rowNumber == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing row information to update points.')),
      );
      return;
    }

    final payload = {
      'rowId': rowId,
      'rowNumber': rowNumber,
      'point1': _point1Controller.text.trim(),
      'point2': _point2Controller.text.trim(),
      'point3': _point3Controller.text.trim(),
    };

    try {
      final resp = await http.post(
        Uri.parse(_updatePointsWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        setState(() {
          _meeting = _meeting.createCopyWith(
            agreedActions: _point1Controller.text.trim(),
            responsibilities: _point2Controller.text.trim(),
            nextSteps: _point3Controller.text.trim(),
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Points updated successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update points: ${resp.statusCode} ${resp.reasonPhrase}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating points: $e')),
      );
    }
  }

  // ───────────── DELETE MEETING ─────────────

  Future<void> _confirmAndDelete() async {
    final rowId = _meeting.rowId;

    if (rowId == null || rowId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: missing Row ID from Glide.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete meeting?'),
          content: Text(
            'Are you sure you want to delete:\n\n'
            '"${_meeting.heading}"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      setState(() => _isDeleting = true);

      await GlideMeetingApi.deleteMeetingByRowId(rowId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting deleted.')),
      );

      Navigator.of(context).pop(rowId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // ───────────── BUILD ─────────────

  @override
  Widget build(BuildContext context) {
    final m = _meeting;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        title: Text(
          m.heading.isNotEmpty ? m.heading : 'Meeting Details',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Delete meeting',
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            onPressed: _isDeleting ? null : _confirmAndDelete,
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshDetail,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MeetingHeaderCard(meeting: m),
                  const SizedBox(height: 16),

                  MeetingClientsCard(meeting: m),
                  const SizedBox(height: 16),

                  // ✅ same card, but now it's key points only
                  MeetingMinutesCard(
                    meeting: m,
                    onSendEmail: _openEmailDialog,
                    point1Controller: _point1Controller,
                    point2Controller: _point2Controller,
                    point3Controller: _point3Controller,
                    onUpdatePoints: _updatePoints,
                  ),
                  const SizedBox(height: 16),

                  MeetingLocationCard(meeting: m),

                  if (_detailError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Error loading details: $_detailError',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (_loadingDetail)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.black26,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF38BDF8)),
              ),
            ),
        ],
      ),
    );
  }
}
