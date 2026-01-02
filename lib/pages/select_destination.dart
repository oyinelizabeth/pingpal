import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

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

  Future<void> _startPingtrail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final arrivalDateTime = _getArrivalDateTime();

    if (_destinationController.text.trim().isEmpty) {
      _showError('Please enter a destination name');
      return;
    }

    if (_selectedLatLng == null) {
      _showError('Please select a destination on the map');
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

    await FirebaseFirestore.instance.collection('pingtrails').add({
      'hostId': user.uid,
      'name': widget.trailName,
      'destinationName': _destinationController.text.trim(),
      'destination': GeoPoint(
        _selectedLatLng!.latitude,
        _selectedLatLng!.longitude,
      ),
      'arrivalTime': Timestamp.fromDate(arrivalDateTime.toUtc()),
      'members': [user.uid, ...widget.selectedFriends],
      'acceptedMembers': [user.uid],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': null,
      'endedAt': null,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pingtrail created! Waiting for pingpals...'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          /// MAP
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(51.5074, -0.1278),
              zoom: 12,
            ),
            myLocationEnabled: true,
            markers: _markers,
            onTap: (latLng) {
              setState(() {
                _selectedLatLng = latLng;
                _markers
                  ..clear()
                  ..add(
                    Marker(
                      markerId: const MarkerId('destination'),
                      position: latLng,
                    ),
                  );
              });
            },
            onMapCreated: (controller) => _mapController = controller,
          ),

          /// BACK BUTTON
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

          /// BOTTOM SHEET
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Destination',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _destinationController,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: InputDecoration(
                      hintText: 'e.g. Westfield Stratford',
                      hintStyle: TextStyle(
                        color: AppTheme.textGray.withOpacity(0.6),
                      ),
                      filled: true,
                      fillColor: AppTheme.inputBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

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
                    leading: const Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                    title: Text(
                      _selectedDate == null
                          ? 'Select date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: const TextStyle(color: AppTheme.textWhite),
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );

                      if (pickedDate != null) {
                        setState(() => _selectedDate = pickedDate);
                      }
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.access_time, color: AppTheme.primaryBlue),
                    title: Text(
                      _selectedTime == null
                          ? 'Select time'
                          : _selectedTime!.format(context),
                      style: const TextStyle(color: AppTheme.textWhite),
                    ),
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (pickedTime != null) {
                        setState(() => _selectedTime = pickedTime);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

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

          /// RECENTER
          Positioned(
            bottom: 260,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: AppTheme.cardBackground,
              child: const Icon(
                FontAwesomeIcons.locationArrow,
                color: AppTheme.primaryBlue,
              ),
              onPressed: () {
                if (_selectedLatLng != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(_selectedLatLng!, 14),
                  );
                }
              },
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
