import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';

class SelectDestinationPage extends StatefulWidget {
  final String trailName;
  final List<String> selectedFriends;

  const SelectDestinationPage({
    super.key,
    required this.trailName,
    required this.selectedFriends,
  });

  @override
  State<SelectDestinationPage> createState() => _SelectDestinationPageState();
}

class _SelectDestinationPageState extends State<SelectDestinationPage> {
  final int _navIndex = 0;

  final TextEditingController _destinationController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;
  final Set<Marker> _markers = {};
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  @override
  void initState() {
    super.initState();

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    _localNotifications.initialize(initSettings);
  }
  // HELPERS
  DateTime? _getArrivalDateTime() {
    if (_selectedDate == null || _selectedTime == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  double? _distanceKm;
  String? _estimatedTime;
  bool _isCalculatingRoute = false;
  LatLng? _lastRoutedDestination;

  Future<void> _calculateDistanceAndETA(LatLng destination) async {
    if (_lastRoutedDestination == destination) return;
    _lastRoutedDestination = destination;

    setState(() {
      _isCalculatingRoute = true;
      _estimatedTime = null;
    });

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    /// Estimation
    final minutes = ((_distanceKm! / 40) * 60).round();

    setState(() {
      _estimatedTime = '$minutes mins (estimating...)';
    });

    /// Distance (KM)
    final meters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      destination.latitude,
      destination.longitude,
    );

    setState(() {
      _distanceKm = meters / 1000;
    });

    /// ETA (Directions API)
    final url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${position.latitude},${position.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=AIzaSyBQbcJzO-r0747NpMLKOt3ZUQN_1fZEt-g';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['routes'].isNotEmpty) {
        _estimatedTime =
        data['routes'][0]['legs'][0]['duration']['text'];
      }
    }

    setState(() => _isCalculatingRoute = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Create Pingtrail

  Future<void> _startPingtrail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final arrivalDateTime = _getArrivalDateTime();

    if (_destinationController.text.trim().isEmpty) {
      if (!mounted) return;
      _showError('Please select a destination');
      return;
    }

    if (_selectedLatLng == null) {
      _showError('Destination location not set');
      return;
    }

    if (arrivalDateTime == null) {
      _showError('Please select an arrival date and time');
      return;
    }

    if (arrivalDateTime.isBefore(DateTime.now())) {
      _showError('Arrival time must be in the future');
      return;
    }

    final Map<String, dynamic> pingtrailData = {
      'hostId': user.uid,
      'name': widget.trailName,
      'destinationName': _destinationController.text.trim(),
      'destination': GeoPoint(
        _selectedLatLng!.latitude,
        _selectedLatLng!.longitude,
      ),
      'arrivalTime': Timestamp.fromDate(arrivalDateTime.toUtc()),
      'participants': [user.uid, ...widget.selectedFriends].map((pId) => {
        'userId': pId,
        'status': pId == user.uid ? 'accepted' : 'pending',
      }).toList(),
      'members': [user.uid], // Start with just the host
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': FieldValue.serverTimestamp(),
      'endedAt': null,
    };

    final docRef = await FirebaseFirestore.instance.collection('ping_trails').add(pingtrailData);

    // Send invitations/notifications
    for (String friendId in widget.selectedFriends) {
      final inviteRef = await FirebaseFirestore.instance
          .collection('ping_trails')
          .doc(docRef.id)
          .collection('invitations')
          .add({
        'fromId': user.uid,
        'fromName': 'Your friend', // Should ideally fetch sender's name
        'toId': friendId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await NotificationService.send(
        receiverId: friendId,
        senderId: user.uid,
        type: 'pingtrail_invitation',
        title: 'New Pingtrail Invitation',
        body: 'You have been invited to join ${widget.trailName}',
        pingtrailId: docRef.id,
        invitationId: inviteRef.id,
      );
    }
    if (!mounted) return; // <<< check here

    // Show local notification
    await _localNotifications.show(
      docRef.hashCode,
      'Pingtrail Created!',
      'Invite sent to ${widget.selectedFriends.length} pingpals',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_notification_channel',
          'Default Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );

    if (!mounted) return; // <<< check here again
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pingtrail created! Waiting for pingpals...'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );

    Navigator.popUntil(context, (route) => route.isFirst);
  }
  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }
  // UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [

          /// Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(51.5074, -0.1278), // London
              zoom: 12,
            ),
            myLocationEnabled: true,
            markers: _markers,
            onMapCreated: (controller) => _mapController = controller,
          ),

          /// Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircleAvatar(
                backgroundColor: AppTheme.cardBackground,
                child: IconButton(
                  icon: const Icon(
                    FontAwesomeIcons.arrowLeft,
                    color: AppTheme.textWhite,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          /// Bottom sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// Destination
                    const Text(
                      'Destination',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 8),

                    GooglePlaceAutoCompleteTextField(
                      textEditingController: _destinationController,
                      googleAPIKey: "AIzaSyBQbcJzO-r0747NpMLKOt3ZUQN_1fZEt-g",
                      debounceTime: 400,
                      countries: const ["gb"],

                      isLatLngRequired: true,

                      inputDecoration: InputDecoration(
                        hintText: 'Search destination',
                        filled: true,
                        fillColor: AppTheme.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),

                      /// callback for when lat/lng arrive
                      getPlaceDetailWithLatLng: (Prediction p) {
                        if (p.lat == null || p.lng == null) {
                          debugPrint('Place details loaded but lat/lng missing');
                          return;
                        }

                        final double lat = double.parse(p.lat!);
                        final double lng = double.parse(p.lng!);

                        final LatLng mapLatLng = LatLng(lat, lng);

                        setState(() {
                          // Show info in text field
                          _destinationController.text = p.description ?? 'Selected place';

                          // Save destination
                          _selectedLatLng = mapLatLng;

                          // Show marker on map
                          _markers
                            ..clear()
                            ..add(
                              Marker(
                                markerId: const MarkerId('destination'),
                                position: mapLatLng,
                                infoWindow: InfoWindow(
                                  title: p.structuredFormatting?.mainText ?? 'Destination',
                                  snippet:
                                  p.structuredFormatting?.secondaryText ?? '',
                                ),
                              ),
                            );
                        });

                        // Move map
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(mapLatLng, 14),
                        );

                        _calculateDistanceAndETA(mapLatLng);

                        // Close keyboard
                        FocusScope.of(context).unfocus();
                      },

                      itemClick: (Prediction p) {
                      },
                    ),

                    const SizedBox(height: 4),

                    if (_isCalculatingRoute && _estimatedTime == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),


                    if (_distanceKm != null && _estimatedTime != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.place,
                                    color: AppTheme.primaryBlue, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  '${_distanceKm!.toStringAsFixed(1)} km away',
                                  style: const TextStyle(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.directions_car,
                                    color: AppTheme.primaryBlue, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  _estimatedTime!,
                                  style: const TextStyle(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    /// Arrival time
                    const Text(
                      'Arrival time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ListTile(
                      leading: const Icon(Icons.calendar_today,
                          color: AppTheme.primaryBlue),
                      title: Text(
                        _selectedDate == null
                            ? 'Select date'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style:
                        const TextStyle(color: AppTheme.textWhite),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.access_time,
                          color: AppTheme.primaryBlue),
                      title: Text(
                        _selectedTime == null
                            ? 'Select time'
                            : _selectedTime!.format(context),
                        style:
                        const TextStyle(color: AppTheme.textWhite),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() => _selectedTime = picked);
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Create button
                    ElevatedButton(
                      onPressed: _startPingtrail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Start Pingtrail',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavBar(
        currentIndex: _navIndex,
        onTap: (_) => Navigator.popUntil(context, (r) => r.isFirst),
      ),
    );
  }
}
