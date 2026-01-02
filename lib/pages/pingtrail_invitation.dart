import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';

class PingtrailInvitationPage extends StatefulWidget {
  final String pingtrailId;
  final String invitationId;

  const PingtrailInvitationPage({
    super.key,
    required this.pingtrailId,
    required this.invitationId,
  });

  @override
  State<PingtrailInvitationPage> createState() =>
      _PingtrailInvitationPageState();
}

class _PingtrailInvitationPageState extends State<PingtrailInvitationPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final AnimationController _pulseController;
  final int _navIndex = 1;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String currentUserName = 'A user';

  /// 👇 MUST be stored on state (used by buttons)
  String? hostId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _loadCurrentUserName();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserName() async {
    final snap = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();

    if (snap.exists && mounted) {
      setState(() {
        currentUserName = snap.data()?['fullName'] ?? 'A user';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          Positioned.fill(
            child: CustomPaint(
              painter: DottedPathPainter(_pulseController),
            ),
          ),
          _buildGoalMarker(),
          _buildUserDot(),
          _buildContentCard(),
        ],
      ),
      bottomNavigationBar: NavBar(
        currentIndex: _navIndex,
        onTap: (index) {
          if (index != _navIndex) Navigator.pop(context);
        },
      ),
    );
  }

  /* ================= BACKGROUND ================= */

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.3, -0.5),
          radius: 1.2,
          colors: [
            Color(0xFF1A1D2E),
            Color(0xFF0A0E1A),
          ],
        ),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: MapGridPainter(),
      ),
    );
  }

  Widget _buildGoalMarker() {
    return const Positioned(
      top: 120,
      right: 40,
      child: Column(
        children: [
          Icon(
            FontAwesomeIcons.flagCheckered,
            color: AppTheme.primaryBlue,
            size: 32,
          ),
          SizedBox(height: 6),
          Text(
            'Goal',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDot() {
    return Positioned(
      bottom: 350,
      left: 60,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  /* ================= CONTENT ================= */

  Widget _buildContentCard() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withOpacity(0.98),
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('pingtrails')
                .doc(widget.pingtrailId)
                .snapshots(),
            builder: (context, trailSnap) {
              if (!trailSnap.hasData || !trailSnap.data!.exists) {
                return _message('Pingtrail not found.');
              }

              final trail =
              trailSnap.data!.data() as Map<String, dynamic>;

              /// 👇 store hostId on state ONCE
              hostId ??= trail['creatorId'];

              return StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('pingtrails')
                    .doc(widget.pingtrailId)
                    .collection('invitations')
                    .doc(widget.invitationId)
                    .snapshots(),
                builder: (context, inviteSnap) {
                  if (!inviteSnap.hasData ||
                      !inviteSnap.data!.exists) {
                    return _message(
                        'Invitation no longer available.');
                  }

                  final invite =
                  inviteSnap.data!.data() as Map<String, dynamic>;

                  return _buildInvitationContent(trail, invite);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _message(String text) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  /* ================= INVITE UI ================= */

  Widget _buildInvitationContent(
      Map<String, dynamic> trail,
      Map<String, dynamic> invite,
      ) {
    final Timestamp? ts = trail['startTime'];
    final int minutesToStart = ts == null
        ? 0
        : ts.toDate().difference(DateTime.now()).inMinutes.clamp(0, 999);

    final members = (trail['members'] as List?) ?? [];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: NetworkImage(
              invite['fromAvatar'] ??
                  'https://i.pravatar.cc/150?img=3',
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 16),
              children: [
                TextSpan(
                  text: '${invite['fromName']} ',
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(
                  text: 'invited you to a Pingtrail',
                  style: TextStyle(color: AppTheme.textGray),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            trail['name'] ?? 'Pingtrail',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            trail['destinationName'] ?? 'Unknown destination',
            style: const TextStyle(color: AppTheme.textWhite),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _declineInvite,
                  child: const Text(
                    'Decline',
                    style: TextStyle(color: AppTheme.textWhite),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _acceptInvite,
                  icon: const Icon(FontAwesomeIcons.check, size: 16),
                  label: const Text('Accept & Join'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* ================= ACTIONS ================= */

  Future<void> _declineInvite() async {
    if (hostId == null) return;

    await _firestore
        .collection('pingtrails')
        .doc(widget.pingtrailId)
        .collection('invitations')
        .doc(widget.invitationId)
        .update({'status': 'declined'});

    await NotificationService.send(
      receiverId: hostId!,
      senderId: currentUserId,
      title: 'Pingtrail declined',
      body:
      '$currentUserName declined your pingtrail invitation',
      type: 'pingtrail_declined',
      pingtrailId: widget.pingtrailId,
    );

    if (mounted) Navigator.pop(context);
  }

  Future<void> _acceptInvite() async {
    if (hostId == null) return;

    await _firestore
        .collection('pingtrails')
        .doc(widget.pingtrailId)
        .update({
      'members': FieldValue.arrayUnion([currentUserId]),
    });

    await _firestore
        .collection('pingtrails')
        .doc(widget.pingtrailId)
        .collection('invitations')
        .doc(widget.invitationId)
        .update({'status': 'accepted'});

    await NotificationService.send(
      receiverId: hostId!,
      senderId: currentUserId,
      title: 'Pingtrail accepted',
      body: '$currentUserName joined your pingtrail',
      type: 'pingtrail_accepted',
      pingtrailId: widget.pingtrailId,
    );

    if (mounted) Navigator.pop(context);
  }
}

/* ================= PAINTERS ================= */

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.borderColor.withOpacity(0.1)
      ..strokeWidth = 0.5;

    const gridSize = 40.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class DottedPathPainter extends CustomPainter {
  final Animation<double> animation;

  DottedPathPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue.withOpacity(0.5)
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(80, size.height - 350)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.3,
        size.width - 60,
        140,
      );

    final metric = path.computeMetrics().first;
    for (double i = 0; i < 1; i += 0.03) {
      final pos =
          metric.getTangentForOffset(metric.length * i)?.position;
      if (pos != null) {
        canvas.drawCircle(pos, 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
