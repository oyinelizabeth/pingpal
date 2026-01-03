import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../theme/app_theme.dart';
import '../services/live_location_service.dart';
import '../services/notification_service.dart';
import '../services/pingtrail_service.dart';
import '../services/location_api_service.dart';
import '../utils/marker_helper.dart';
import 'pingtrail_complete.dart';

class ActivePingtrailMapPage extends StatefulWidget {
  final String pingtrailId;

  const ActivePingtrailMapPage({
    super.key,
    required this.pingtrailId,
  });

  @override
  State<ActivePingtrailMapPage> createState() =>
      _ActivePingtrailMapPageState();
}

class _ActivePingtrailMapPageState extends State<ActivePingtrailMapPage> {
  late final String currentUserId;
  final PingtrailService _pingtrailService = PingtrailService();

  GoogleMapController? _mapController;

  bool _hasArrived = false;
  bool _isArriving = false;
  bool _hasFittedCamera = false;

  String _currentUserName = 'A user';

  final Set<Polyline> _polylines = {};

  Timer? _writerTimer;
  Timer? _readerTimer;
  Map<String, Marker> _friendMarkers = {};
  Marker? _selfMarker;
  Marker? _destinationMarker;
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  
  // Cache for participant data (name, photo, bio)
  final Map<String, Map<String, dynamic>> _participantData = {};
  Position? _lastSelfPosition;

  StreamSubscription? _trailSubscription;

  // ─────────────────────────────
  // Lifecycle
  // ─────────────────────────────
  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.pingtrailId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return;
    }

    currentUserId = user.uid;

    _loadCurrentUserName();
    _checkIfAlreadyArrived();
    // Loops will be started from build() once destination is fetched
    _listenToTrailChanges();
  }

  bool _loopsStarted = false;

  void _listenToTrailChanges() {
    _trailSubscription = FirebaseFirestore.instance
        .collection('pingtrails')
        .doc(widget.pingtrailId)
        .snapshots()
        .listen((trailSnap) async {
      if (trailSnap.exists && mounted) {
        final List<dynamic> participants = trailSnap.data()?['participants'] ?? [];
        for (var p in participants) {
          final String uid = p['userId'];
          final String status = p['status'] ?? '';
          
          if (uid == currentUserId || status != 'accepted') continue;
          if (_participantData.containsKey(uid)) continue;

          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          
          if (userDoc.exists && mounted) {
            setState(() {
              _participantData[uid] = userDoc.data()!;
            });
          }
        }
      }
    });
  }

  void _startLoops(LatLng destination) {
    // 1. Writer Loop (Every 5 Seconds)
    _writerTimer = Timer.periodic(const Duration(seconds: 5), (_) => _writerLoop());

    // 2. Reader Loop (Every 2 Seconds)
    _readerTimer = Timer.periodic(const Duration(seconds: 2), (_) => _readerLoop(destination));
  }

  Future<void> _writerLoop() async {
    try {
      // Get GPS position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastSelfPosition = position;

      // Get Network Status
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      String networkType = '3g'; // Default
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        networkType = 'wifi';
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        // Simple logic for PoC: assume mobile is 4g/3g.
        // In real app we could use another package for more detail.
        networkType = '4g';
      }

      // Action: Call POST /update
      await LocationApiService.sendLocation(
        userId: currentUserId,
        lat: position.latitude,
        lng: position.longitude,
        networkType: networkType,
      );

      // Arrival Detection
      if (!_hasArrived) {
        final trailSnap = await FirebaseFirestore.instance
            .collection('pingtrails')
            .doc(widget.pingtrailId)
            .get();

        if (trailSnap.exists) {
          final data = trailSnap.data()!;
          final dest = data['destination'];
          double destLat, destLng;
          if (dest is GeoPoint) {
            destLat = dest.latitude;
            destLng = dest.longitude;
          } else {
            destLat = (dest['lat'] as num).toDouble();
            destLng = (dest['lng'] as num).toDouble();
          }

          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            destLat,
            destLng,
          );

          if (distance < 50) {
            final List<dynamic> participantsData = data['participants'] ?? [];
            final List<String> memberIds = participantsData
                .where((p) => p['status'] == 'accepted')
                .map((p) => p['userId'].toString())
                .toList();
            _onArrivedPressed(memberIds);
          }
        }
      }
    } catch (e) {
      debugPrint('Writer loop error: $e');
    }
  }

  Future<void> _readerLoop(LatLng destination) async {
    try {
      final List<dynamic> locations = await LocationApiService.getTrailLocations(widget.pingtrailId);

      for (var loc in locations) {
        final String uid = loc['userId'];
        if (uid == currentUserId) continue;

        final double lat = (loc['location']['lat'] as num).toDouble();
        final double lng = (loc['location']['lng'] as num).toDouble();

        final userData = _participantData[uid];
        final String name = userData?['fullName'] ?? 'Friend';
        final String? photoUrl = userData?['photoUrl'];
        
        String distanceText = '';
        double? distanceMeters;
        if (_lastSelfPosition != null) {
          distanceMeters = Geolocator.distanceBetween(
            _lastSelfPosition!.latitude,
            _lastSelfPosition!.longitude,
            lat,
            lng,
          );
          if (distanceMeters < 1000) {
            distanceText = '${distanceMeters.toStringAsFixed(0)}m away';
          } else {
            distanceText = '${(distanceMeters / 1000).toStringAsFixed(1)}km away';
          }
        }

        BitmapDescriptor icon;
        if (_markerIconCache.containsKey(uid)) {
          icon = _markerIconCache[uid]!;
        } else {
          icon = await MarkerHelper.getMarkerWithImage(
            photoUrl, 
            borderColor: Colors.purpleAccent,
          );
          _markerIconCache[uid] = icon;
        }

        final marker = Marker(
          markerId: MarkerId(uid),
          position: LatLng(lat, lng),
          icon: icon,
          infoWindow: InfoWindow(
            title: name,
            snippet: distanceText.isNotEmpty ? distanceText : null,
          ),
          onTap: () {
            if (distanceMeters != null) {
              _showUserDetailSheet(uid, distanceMeters);
            }
          },
        );

        _friendMarkers[uid] = marker;
      }

      // Add self marker (Blue)
      await _addSelfMarker();
      
      if (mounted) {
        setState(() {}); // Trigger build to update markers from components
        _fitBounds(destination);
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Reader loop error: $e');
        // If the error is 'Failed to load trail locations', it's likely the trailId doesn't exist in Redis yet
        // or the session hasn't started sending data. We'll just wait for the next tick.
      }
    }
  }

  void _showUserDetailSheet(String uid, double distance) {
    final userData = _participantData[uid];
    if (userData == null) return;

    final String name = userData['fullName'] ?? 'Pingpal';
    final String email = userData['email'] ?? '';
    final String bio = userData['bio'] ?? 'No bio available';
    final String photoUrl = userData['photoUrl'] ?? '';
    
    String distanceStr = distance < 1000 
        ? '${distance.toStringAsFixed(0)} meters' 
        : '${(distance / 1000).toStringAsFixed(1)} km';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                  child: photoUrl.isEmpty 
                      ? const Icon(Icons.person, color: AppTheme.primaryBlue, size: 35) 
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGray.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_walk, color: AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  const Text(
                    'Current Distance:',
                    style: TextStyle(color: AppTheme.textGray),
                  ),
                  const Spacer(),
                  Text(
                    distanceStr,
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      color: AppTheme.textGray,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bio,
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _fitBounds(LatLng destination) {
    if (_mapController == null) return;

    double? minLat, maxLat, minLng, maxLng;

    // Include destination in bounds
    minLat = destination.latitude;
    maxLat = destination.latitude;
    minLng = destination.longitude;
    maxLng = destination.longitude;

    final allMarkers = {
      if (_selfMarker != null) _selfMarker!,
      if (_destinationMarker != null) _destinationMarker!,
      ..._friendMarkers.values,
    };

    for (final marker in allMarkers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      if (lat < minLat!) minLat = lat;
      if (lat > maxLat!) maxLat = lat;
      if (lng < minLng!) minLng = lng;
      if (lng > maxLng!) maxLng = lng;
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 70), // 70px padding
      );
    }
  }

  Future<void> _addSelfMarker() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final user = FirebaseAuth.instance.currentUser;
      final photoUrl = user?.photoURL;
      
      BitmapDescriptor icon;
      if (_markerIconCache.containsKey(currentUserId)) {
        icon = _markerIconCache[currentUserId]!;
      } else {
        icon = await MarkerHelper.getMarkerWithImage(
          photoUrl, 
          borderColor: AppTheme.primaryBlue,
        );
        _markerIconCache[currentUserId] = icon;
      }

      if (mounted) {
        _selfMarker = Marker(
          markerId: MarkerId(currentUserId),
          position: LatLng(pos.latitude, pos.longitude),
          icon: icon,
          infoWindow: const InfoWindow(title: 'Me'),
        );
      }
    } catch (e) {
      debugPrint('Error adding self marker: $e');
    }
  }

  @override
  void dispose() {
    _writerTimer?.cancel();
    _readerTimer?.cancel();
    _trailSubscription?.cancel();
    _mapController?.dispose();
    LiveLocationService.stop();
    super.dispose();
  }

  // ─────────────────────────────
  // Helpers
  // ─────────────────────────────
  Future<void> _loadCurrentUserName() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (snap.exists && mounted) {
      _currentUserName =
          (snap.data()?['fullName'] ?? 'A user').toString();
    }
  }

  Future<void> _checkIfAlreadyArrived() async {
    final snap = await FirebaseFirestore.instance
        .collection('pingtrails')
        .doc(widget.pingtrailId)
        .get();

    final arrivedMembers =
    (snap.data()?['participants'] as List<dynamic>? ?? [])
        .where((p) => p['status'] == 'arrived')
        .map((p) => p['userId'].toString())
        .toList();

    if (arrivedMembers.contains(currentUserId)) {
      _hasArrived = true;
    }
  }

  // ─────────────────────────────
  // Camera helpers
  // ─────────────────────────────
  Future<void> _moveToUserLocation() async {
    if (_mapController == null) return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(pos.latitude, pos.longitude),
        14,
      ),
    );
  }

  Future<void> _fitCamera(Set<LatLng> points) async {
    if (_mapController == null || points.length < 2) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  // ─────────────────────────────
  // Arrival
  // ─────────────────────────────
  Future<void> _onArrivedPressed(List<String> members) async {
    setState(() => _isArriving = true);

    try {
      await _pingtrailService.userArrived(
        pingtrailId: widget.pingtrailId,
        userName: _currentUserName,
        members: members,
      );

      setState(() => _hasArrived = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arrival confirmed 🎉')),
      );

      // Show summary for current user
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PingtrailCompletePage(trailId: widget.pingtrailId),
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to confirm arrival')),
      );
    } finally {
      if (mounted) setState(() => _isArriving = false);
    }
  }

  // ─────────────────────────────
  // Cancel (host)
  // ─────────────────────────────
  Future<void> _cancelPingtrail(
      String hostId,
      String trailName,
      List<String> members,
      ) async {
    if (currentUserId != hostId) return;

    try {
      await FirebaseFirestore.instance
          .collection('pingtrails')
          .doc(widget.pingtrailId)
          .update({
        'status': 'cancelled',
        'endedAt': FieldValue.serverTimestamp(),
      });

      for (final uid in members) {
        if (uid == hostId) continue;

        await NotificationService.send(
          receiverId: uid,
          senderId: hostId,
          title: 'Pingtrail cancelled',
          body: '$trailName was cancelled by the host',
          type: 'pingtrail_cancelled',
          pingtrailId: widget.pingtrailId,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PingtrailCompletePage(trailId: widget.pingtrailId),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error cancelling pingtrail: $e');
    }
  }

  // ─────────────────────────────
  // UI
  // ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        title: const Text('Live Pingtrail'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pingtrails')
            .doc(widget.pingtrailId)
            .snapshots(),
        builder: (context, trailSnap) {
          if (!trailSnap.hasData || !trailSnap.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final trailData = trailSnap.data!.data() as Map<String, dynamic>;
          final dest = trailData['destination'];
          if (dest == null) {
            return const Center(
              child: Text(
                'Destination not set',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          LatLng destination;
          if (dest is GeoPoint) {
            destination = LatLng(dest.latitude, dest.longitude);
          } else if (dest is Map) {
            destination = LatLng(
              (dest['lat'] as num).toDouble(),
              (dest['lng'] as num).toDouble(),
            );
          } else {
            return const Center(
              child: Text(
                'Invalid destination format',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final List<String> members =
          (trailData['members'] as List<dynamic>? ?? [])
              .whereType<String>()
              .toList();

          final String hostId = (trailData['hostId'] ?? '').toString();
          final String trailName =
          (trailData['destinationName'] ?? 'Pingtrail').toString();

          // Update destination marker
          _destinationMarker = Marker(
            markerId: const MarkerId('destination'),
            position: destination,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: trailName, snippet: 'Destination'),
          );

          // Start loops once destination is known
          if (!_loopsStarted) {
            _loopsStarted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startLoops(destination);
            });
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: destination,
                  zoom: 13,
                ),
                markers: {
                  if (_selfMarker != null) _selfMarker!,
                  if (_destinationMarker != null) _destinationMarker!,
                  ..._friendMarkers.values,
                },
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (c) => _mapController = c,
              ),

              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: ElevatedButton.icon(
                  onPressed: _hasArrived || _isArriving
                      ? null
                      : () => _onArrivedPressed(members),
                  icon: const Icon(Icons.flag),
                  label: Text(
                    _hasArrived
                        ? 'Arrival confirmed'
                        : "I've arrived",
                  ),
                ),
              ),

              if (currentUserId == hostId)
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.red,
                    ),
                    onPressed: () => _cancelPingtrail(
                      hostId,
                      trailName,
                      members,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
