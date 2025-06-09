import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:mittsure/field/attendance.dart';
import 'package:mittsure/field/punchin.dart';
import 'package:mittsure/field/routes.dart';

class FieldOperationsPage extends StatefulWidget {
  const FieldOperationsPage({super.key});

  @override
  State<FieldOperationsPage> createState() => _FieldOperationsPageState();
}

class _FieldOperationsPageState extends State<FieldOperationsPage> {
  bool _isPunchedIn = false;
  DateTime? _startTime;
  Duration _workingDuration = Duration.zero;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePunch() {
    setState(() {
      if (_isPunchedIn) {
        _timer?.cancel();
        _workingDuration = Duration.zero;
        _startTime = null;
      } else {
        _startTime = DateTime.now();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            _workingDuration = DateTime.now().difference(_startTime!);
          });
        });
      }
      _isPunchedIn = !_isPunchedIn;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:"
        "${twoDigits(duration.inMinutes % 60)}:"
        "${twoDigits(duration.inSeconds % 60)}";
  }

  @override
  Widget build(BuildContext context) {
    final formattedStartTime = _startTime != null
        ? DateFormat('hh:mm a').format(_startTime!)
        : '--:--';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Operations'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            // Handle Home
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () {
              // Handle logout
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Working Hours Today',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('Start Time: $formattedStartTime'),
                  const SizedBox(height: 5),
                  Text('Working Duration: ${_formatDuration(_workingDuration)}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _togglePunch,
                    icon: Icon(_isPunchedIn ? Icons.logout : Icons.login),
                    label: Text(_isPunchedIn ? 'Punch Out' : 'Punch In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPunchedIn ? Colors.red : Colors.green,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildMenuItem(Icons.alt_route, 'Route',CreatedRoutesPage()),
          const SizedBox(height: 12),
          _buildMenuItem(Icons.place, 'Visits', PunchScreen()),
          const SizedBox(height: 12),
          _buildMenuItem(Icons.attach_money, 'Expenses', () {}),
          const SizedBox(height: 12),
          _buildMenuItem(Icons.access_time, 'Attendance', MeterPunchScreen()),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, screen) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen), // Route to HomePage
          );
        },
      ),
    );
  }
}
