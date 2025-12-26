import 'package:flutter/material.dart';
import '../../models/meeting.dart';
import '../login_page.dart';
import '../MeetingDetailPage.dart';
import 'meeting_controller.dart';
import 'meeting_list.dart';
import '../../widgets/meeting_bottom_sheet.dart';

class HomePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String email;
  final String role;
  final String? token;

  const HomePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.email,
    required this.role,
    this.token,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MeetingController _controller = MeetingController();

  int _selectedIndex = 0;

  bool get isAdmin => widget.role.toLowerCase().contains("admin");

  @override
  void initState() {
    super.initState();
    _controller.loadMy(widget.userId).then((_) => setState(() {}));
    if (isAdmin) {
      _controller.loadAll(widget.userId).then((_) => setState(() {}));
    }
  }

  void _openCreateMeeting() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF020617),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MeetingBottomSheet(
        creatorId: widget.userId,
        creatorName: widget.userName,
        creatorEmail: widget.email,
        onSaved: () async {
          await _controller.loadMy(widget.userId);
          if (isAdmin) await _controller.loadAll(widget.userId);
          setState(() {});
        },
      ),
    );
  }

  void _onLogoutPressed() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false, // clear entire stack
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      MeetingList(
        meetings: _controller.myMeetings,
        isLoading: _controller.loadingMy,
        emptyText: "No meetings yet.",
        errorText: _controller.errorMy,
        onRetry: () async {
          await _controller.loadMy(widget.userId);
          setState(() {});
        },
        onTap: (Meeting m) async {
  debugPrint('👉 Tapped meeting: ${m.heading} | rowId=${m.rowId}');
  try {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeetingDetailPage(
          meeting: m,
          currentUserName: widget.userName,
        ),
      ),
    );

    debugPrint('⬅️ Returned from MeetingDetailPage. result=$result');

    if (result is String && result.isNotEmpty) {
      setState(() {
        _controller.myMeetings.removeWhere((x) => x.rowId == result);
      });
    }
  } catch (e, st) {
    debugPrint('❌ Navigation error: $e');
    debugPrint(st.toString());
  }
},
      ),
      if (isAdmin)
        MeetingList(
          meetings: _controller.allMeetings,
          isLoading: _controller.loadingAll,
          emptyText: "No meetings found.",
          errorText: _controller.errorAll,
          onRetry: () async {
            await _controller.loadAll(widget.userId);
            setState(() {});
          },
          onTap: (Meeting m) async {
  debugPrint('👉 Tapped meeting: ${m.heading} | rowId=${m.rowId}');
  try {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeetingDetailPage(
          meeting: m,
          currentUserName: widget.userName,
        ),
      ),
    );

    debugPrint('⬅️ Returned from MeetingDetailPage. result=$result');

    if (result is String && result.isNotEmpty) {
      setState(() {
        _controller.myMeetings.removeWhere((x) => x.rowId == result);
      });
    }
  } catch (e, st) {
    debugPrint('❌ Navigation error: $e');
    debugPrint(st.toString());
  }
},
        ),
    ];

    final bottomItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.event),
        label: "My Meetings",
      ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: "All Meetings",
        ),
    ];

    final totalMy = _controller.myMeetings.length;
    final totalAll = _controller.allMeetings.length;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Client Meetings",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              "${widget.userName} • ${widget.role}",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[400],
                  ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _onLogoutPressed,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.logout_rounded,
                        size: 18, color: Colors.red),
                    const SizedBox(width: 6),
                    Text(
                      "Logout",
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.red[300],
                                fontWeight: FontWeight.w500,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF020617),
              Color(0xFF020617),
              Color(0xFF0B1120),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatChip(
                      label: "My meetings",
                      value: totalMy.toString(),
                      icon: Icons.event_available,
                    ),
                    const SizedBox(width: 8),
                    if (isAdmin)
                      _StatChip(
                        label: "All meetings",
                        value: totalAll.toString(),
                        icon: Icons.analytics_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    color: const Color(0xFF020617).withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.6),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: pages[_selectedIndex],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: isAdmin
          ? Container(
              decoration: const BoxDecoration(
                color: Color(0xFF020617),
                border: Border(
                  top: BorderSide(color: Colors.white10, width: 0.5),
                ),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                currentIndex: _selectedIndex,
                items: bottomItems,
                selectedItemColor: const Color(0xFF38BDF8),
                unselectedItemColor: Colors.grey[500],
                type: BottomNavigationBarType.fixed,
                onTap: (i) => setState(() => _selectedIndex = i),
              ),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateMeeting,
        icon: const Icon(Icons.add),
        label: const Text('New meeting'),
        backgroundColor: const Color(0xFF38BDF8),
        foregroundColor: Colors.black,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1120),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

