import 'dart:typed_data';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LogDetailPage extends StatelessWidget {
  final int logId;
  final VoidCallback onLogUpdated;

  const LogDetailPage({
    super.key,
    required this.logId,
    required this.onLogUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final controller = HotelController.to;

    final log = controller.guestLogs.firstWhere(
      (e) => e['id'] == logId,
      orElse: () => {},
    );

    final bookings =
        controller.bookingItems.where((b) => b['logId'] == logId).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Guest Details'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            onLogUpdated();
            Navigator.pop(context);
          },
        ),
      ),
      body:
          log.isEmpty
              ? const Center(child: Text('Guest not found'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _profileSection(log),
                    const SizedBox(height: 24),
                    _infoSection(log),
                    const SizedBox(height: 24),
                    _bookingSection(bookings, controller),
                    const SizedBox(height: 24),
                    _actionsSection(context, log),
                  ],
                ),
              ),
    );
  }

  // =================== SECTIONS ===================

  Widget _profileSection(Map<String, dynamic> log) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _profileImage(log['citizenImageBlob']),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log['name'] ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(log['contactNumber'] ?? 'No Contact'),
                  const SizedBox(height: 4),
                  Text(log['address'] ?? 'No Address'),
                ],
              ),
            ),
            _statusChip(_getGuestStatus(log)),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(Map<String, dynamic> log) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 40,
          runSpacing: 16,
          children: [
            _infoTile('Citizenship No', log['citizenNumber']),
            _infoTile('Nationality', log['nationality']),
            _infoTile('Gender', log['gender']),
            _infoTile('Guests', log['totalGuests']?.toString()),
            _infoTile('Created At', _formatDate(log['createdAt'])),
          ],
        ),
      ),
    );
  }

  Widget _bookingSection(
    List<Map<String, dynamic>> bookings,
    HotelController controller,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Room Bookings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...bookings.map((b) {
              final room = controller.rooms.firstWhere(
                (r) => r['id'] == b['roomId'],
                orElse: () => {'number': 'Unknown'},
              );

              return ListTile(
                leading: const Icon(Icons.hotel),
                title: Text('Room ${room['number']}'),
                subtitle: Text(
                  '${_formatDate(b['arrivalDate'])} → ${_formatDate(b['checkOutDate'])}',
                ),
                trailing: Text(
                  'Rs ${b['price'] ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _actionsSection(BuildContext context, Map<String, dynamic> log) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Guest'),
                onPressed: () {
                  // TODO: Open edit dialog/page
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Checkout'),
                onPressed: () {
                  // TODO: Checkout logic
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== HELPERS ===================

  Widget _infoTile(String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _profileImage(Uint8List? bytes) {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: bytes != null ? MemoryImage(bytes) : null,
      child: bytes == null ? const Icon(Icons.person, size: 40) : null,
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'Checked-in':
        bg = Colors.green.shade100;
        fg = Colors.green.shade700;
        break;
      case 'Upcoming':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade700;
        break;
      default:
        bg = Colors.red.shade100;
        fg = Colors.red.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  static String _getGuestStatus(Map<String, dynamic> log) {
    final now = DateTime.now();
    final arrival = DateTime.tryParse(log['arrivalDate'] ?? '');
    final checkout = DateTime.tryParse(log['checkOutDate'] ?? '');

    if (arrival != null && arrival.isAfter(now)) return 'Upcoming';
    if (checkout != null && checkout.isBefore(now)) return 'Checked-out';
    return 'Checked-in';
  }

  static String _formatDate(dynamic v) {
    if (v == null) return '-';
    try {
      final d = DateTime.parse(v.toString());
      return DateFormat('dd MMM yyyy').format(d);
    } catch (_) {
      return '-';
    }
  }
}
