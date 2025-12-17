import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

class GuestLogCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onFoodTap;
  final Widget popupMenu;

  const GuestLogCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onFoodTap,
    required this.popupMenu,
  });

  @override
  Widget build(BuildContext context) {
    final status = _getGuestStatus(item);
    final dateRange = _buildDateRange(item);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: (){
          onTap();
        },
        child: Column(
          children: [
            Row(
              children: [
                _buildProfileImage(_getImageBytes(item['citizenImageBlob'])),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'No name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        item['roomNumber'] ?? 'Room N/A',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        dateRange,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                _actionButton(
                  icon: Icons.phone,
                  label: 'Call',
                  onPressed: () {
                    launchUrlString('tel://${item['contactNumber']}');
                  },
                ),
                _actionButton(
                  icon: Icons.restaurant,
                  label: 'Food',
                  onPressed: onFoodTap,
                ),
                popupMenu,
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------

  static String _getGuestStatus(Map<String, dynamic> item) {
    return item['status'] ?? 'Checked-in';
  }


  static DateTime? parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }


  // DateTime? parseDate(dynamic v) {
  //   if (v == null) return null;
  //   if (v is DateTime) return v;
  //   if (v is String) return DateTime.tryParse(v);
  //   return null;
  // }


  static String _buildDateRange(Map<String, dynamic> item) {
    try {
      final a = DateTime.parse(item['arrivalDate']);
      final c =
          item['checkOutDate'] != null && item['checkOutDate'] != ''
              ? item['checkOutDate']
              : a.add(const Duration(days: 1));

      return '${DateFormat('MMM d').format(a)} - ${DateFormat('MMM d').format(c)}';
    } catch (_) {
      return 'Invalid date';
    }
  }

  static Widget _buildStatusChip(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: fg),
      ),
    );
  }

  static Widget _buildProfileImage(Uint8List? bytes) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child:
          bytes != null
              ? ClipOval(child: Image.memory(bytes, fit: BoxFit.cover))
              : const Icon(Icons.person, size: 30),
    );
  }

  Uint8List? _getImageBytes(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      print("Error decoding image: $e");
      return null;
    }
  }

  static Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
      ),
    );
  }
}
