import 'dart:io';

import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:booking_desktop/src/view/booking/booking_details.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';


class UserDetailPage extends StatelessWidget {
  final Map<String, dynamic> user;
  UserDetailPage({super.key, required this.user});
  final hc = HotelController.to;
  @override
  Widget build(BuildContext context) {
    final userBookings =
        hc.bookings.where((b) => b['userId'] == user['id']).toList();
    return Scaffold(
      appBar: AppBar(title: Text(user['name'] ?? 'Guest')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (user['idImagePath'] != null &&
                    (user['idImagePath'] as String).isNotEmpty)
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: FileImage(File(user['idImagePath'])),
                  )
                else
                  CircleAvatar(radius: 36, child: Icon(Icons.person)),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(user['phone'] ?? ''),
                    SizedBox(height: 6),
                    Text(user['email'] ?? ''),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Bookings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: userBookings.isEmpty
                ? Center(child: Text('No bookings'))
                : ListView.separated(
                  itemBuilder: (_, i) {
                    final b = userBookings[i];
                    final r = hc.rooms.firstWhereOrNull(
                      (x) => x['id'] == b['roomId'],
                    );
                    return Card(
                      child: ListTile(
                        title: Text('Room ${r?['number'] ?? ''}'),
                        subtitle: Text(
                          '${_fmt(b['checkIn'])} → ${_fmt(b['checkOut'])} • ${b['status']}',
                        ),
                        trailing: Text(
                          '₨ ${(b['total'] ?? 0)}',
                        ),
                        onTap:
                            () => Get.to(
                              () => BookingDetailPage(
                                bookingId: int.tryParse(b['id']) ?? -1,
                              ),
                            ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => SizedBox(height: 8),
                  itemCount: userBookings.length,
                ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(String? s) {
    if (s == null) return '-';
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    return DateFormat('yyyy-MM-dd').format(dt);
  }
}
