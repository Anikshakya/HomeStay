import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

enum GuestStatus { booked, checkedIn, checkedOut }

class GuestLogCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onFoodTap;
  final Widget popupMenu;

  // ✅ NEW
  final String statusLabel;
  final Color statusColor;

  const GuestLogCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onFoodTap,
    required this.popupMenu,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
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
        onTap: onTap,
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
                _buildStatusChip(statusLabel, statusColor),
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

  // ---------------- UI HELPERS ----------------

  static Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }

  static String _buildDateRange(Map<String, dynamic> item) {
    try {
      final a = DateTime.parse(item['arrivalDate']);
      final c =
          item['checkOutDate'] != null && item['checkOutDate'] != ''
              ? DateTime.parse(item['checkOutDate'])
              : a.add(const Duration(days: 1));

      return '${DateFormat('MMM d').format(a)} - ${DateFormat('MMM d').format(c)}';
    } catch (_) {
      return 'Invalid date';
    }
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
    } catch (_) {
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
