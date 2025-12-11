import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:booking_desktop/src/view/booking/booking_details.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  final hc = HotelController.to;
  DateTime focused = DateTime.now();
  DateTime selected = DateTime.now();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Booking Calendar')),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.now().subtract(Duration(days: 365)),
                lastDay: DateTime.now().add(Duration(days: 365 * 2)),
                focusedDay: focused,
                selectedDayPredicate: (d) => isSameDay(d, selected),
                onDaySelected: (d, f) {
                  setState(() {
                    selected = d;
                    focused = f;
                  });
                },
                eventLoader: (day) => hc.bookingsForDate(day),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bookings on ${DateFormat.yMMMd().format(selected)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: Obx(() {
                  final list = hc.bookingsForDate(selected);
                  if (list.isEmpty) return Center(child: Text('No bookings'));
                  return ListView.separated(
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final b = list[i];
                      final u = hc.users.firstWhereOrNull(
                        (x) => x['id'] == b['userId'],
                      );
                      final r = hc.rooms.firstWhereOrNull(
                        (x) => x['id'] == b['roomId'],
                      );
                      return Card(
                        child: ListTile(
                          title: Text(
                            '${u?['name'] ?? 'Unknown'} — Room ${r?['number'] ?? ''}',
                          ),
                          subtitle: Text(
                            '${_fmt(b['checkIn'])} → ${_fmt(b['checkOut'])}',
                          ),
                          trailing: Text(b['status'] ?? ''),
                          onTap:
                              () => Get.to(
                                () => BookingDetailPage(bookingId: int.tryParse(b['id']) ?? -1),
                              ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => SizedBox(height: 8),
                  );
                }),
              ),
            ],
          ),
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
