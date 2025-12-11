import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:booking_desktop/src/view/booking/booking_details.dart';
import 'package:booking_desktop/src/view/others/user_deatils_page.dart';
import 'package:booking_desktop/src/view/room/room_details.dart';
import 'package:booking_desktop/src/view/service/service_details_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final hc = HotelController.to;
  final qC = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final q = qC.text.trim().toLowerCase();
    final users =
        q.isEmpty
            ? []
            : hc.users
                .where(
                  (u) =>
                      (u['name'] ?? '').toString().toLowerCase().contains(q) ||
                      (u['phone'] ?? '').toString().contains(q) ||
                      (u['email'] ?? '').toString().toLowerCase().contains(q),
                )
                .toList();
    final rooms =
        q.isEmpty
            ? []
            : hc.rooms
                .where(
                  (r) =>
                      (r['number'] ?? '').toString().toLowerCase().contains(
                        q,
                      ) ||
                      (r['type'] ?? '').toString().toLowerCase().contains(q),
                )
                .toList();
    final services =
        q.isEmpty
            ? []
            : hc.services
                .where(
                  (s) => (s['name'] ?? '').toString().toLowerCase().contains(q),
                )
                .toList();
    final bookings =
        q.isEmpty
            ? []
            : hc.bookings.where((b) {
              final u = hc.users.firstWhereOrNull(
                (x) => x['id'] == b['userId'],
              );
              final r = hc.rooms.firstWhereOrNull(
                (x) => x['id'] == b['roomId'],
              );
              return (u != null &&
                      (u['name'] ?? '').toString().toLowerCase().contains(q)) ||
                  (r != null &&
                      (r['number'] ?? '').toString().toLowerCase().contains(q));
            }).toList();
    return Scaffold(
      appBar: AppBar(title: Text('Search')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: qC,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search users, rooms, services, bookings',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 12),
            if (q.isEmpty)
              Expanded(child: Center(child: Text('Type to search...')))
            else
              Expanded(
                child: ListView(
                  children: [
                    if (users.isNotEmpty)
                      _section(
                        'Guests',
                        users
                            .map(
                              (u) => ListTile(
                                title: Text(u['name'] ?? ''),
                                subtitle: Text(u['phone'] ?? ''),
                                onTap:
                                    () => Get.to(() => UserDetailPage(user: u)),
                              ),
                            )
                            .toList(),
                      ),
                    if (rooms.isNotEmpty)
                      _section(
                        'Rooms',
                        rooms
                            .map(
                              (r) => ListTile(
                                title: Text('Room ${r['number']}'),
                                subtitle: Text(r['type'] ?? ''),
                                onTap:
                                    () => Get.to(() => RoomDetailPage(room: r)),
                              ),
                            )
                            .toList(),
                      ),
                    if (services.isNotEmpty)
                      _section(
                        'Services',
                        services
                            .map(
                              (s) => ListTile(
                                title: Text(s['name']),
                                subtitle: Text('₨ ${s['price']}'),
                                onTap:
                                    () => Get.to(
                                      () => ServiceDetailPage(service: s),
                                    ),
                              ),
                            )
                            .toList(),
                      ),
                    if (bookings.isNotEmpty)
                      _section(
                        'Bookings',
                        bookings.map((b) {
                          final u = hc.users.firstWhereOrNull(
                            (x) => x['id'] == b['userId'],
                          );
                          final r = hc.rooms.firstWhereOrNull(
                            (x) => x['id'] == b['roomId'],
                          );
                          return ListTile(
                            title: Text(
                              '${u?['name'] ?? ''} — Room ${r?['number'] ?? ''}',
                            ),
                            subtitle: Text(
                              '${_fmt(b['checkIn'])} → ${_fmt(b['checkOut'])}',
                            ),
                            onTap:
                                () => Get.to(
                                  () => BookingDetailPage(
                                    bookingId: int.tryParse(b['id']) ?? -1,
                                  ),
                                ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        ...items,
        SizedBox(height: 12),
      ],
    );
  }

  String _fmt(String? s) {
    if (s == null) return '-';
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    return DateFormat('yyyy-MM-dd').format(dt);
  }
}
