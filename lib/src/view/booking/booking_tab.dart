import 'dart:io';
import 'package:booking_desktop/src/app_config/styles.dart';
import 'package:booking_desktop/src/view/booking/add_bookings.dart';
import 'package:booking_desktop/src/view/booking/booking_details.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';

class BookingList extends StatefulWidget {
  const BookingList({super.key});

  @override
  State<BookingList> createState() => _BookingListState();
}

class _BookingListState extends State<BookingList> {
  final HotelController hc = HotelController.to;
  final TextEditingController searchController = TextEditingController();
  RxString searchText = ''.obs;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      searchText.value = searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List _filterBookings(String status) {
    final filtered =
        hc.bookings.where((b) => b['status'] == status).where((b) {
          final user = hc.users.firstWhereOrNull((u) => u['id'] == b['userId']);
          if (user == null) return false;
          final name = (user['name'] ?? '').toString().toLowerCase();
          final phone = (user['phone'] ?? '').toString().toLowerCase();
          final query = searchText.value;
          return name.contains(query) || phone.contains(query);
        }).toList();
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Get.to(() => AddBookingPage()),
      ),
      body: Obx(() {
        // Rebuilds automatically when searchText changes
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Current Guest'),
                  Tab(text: 'Past Guest'),
                  Tab(text: 'Cancelled'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _bookingList(
                      _filterBookings('booked') + _filterBookings('checked_in'),
                    ),
                    _bookingList(_filterBookings('checked_out')),
                    _bookingList(_filterBookings('cancelled')),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _bookingList(List bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          'No bookings found',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final b = bookings[i];
        final u = hc.users.firstWhereOrNull((x) => x['id'] == b['userId']);
        final r = hc.rooms.firstWhereOrNull((x) => x['id'] == b['roomId']);

        final statusColor =
            b['status'] == 'booked'
                ? AppColors.booked
                : b['status'] == 'checked_in'
                ? AppColors.checkedIn
                : b['status'] == 'checked_out'
                ? AppColors.checkedOut
                : AppColors.error;

        final imagePath = u?['image'] as String?;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: AppColors.surface,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.shadow.withValues(alpha: 0.1),
                  backgroundImage:
                      imagePath != null && imagePath.isNotEmpty
                          ? File(imagePath).existsSync()
                              ? Image.file(File(imagePath)).image
                              : null
                          : null,
                  child:
                      imagePath == null || imagePath.isEmpty
                          ? Text(
                            u?['name'] != null && u!['name'].isNotEmpty
                                ? u['name'][0]
                                : '?',
                          )
                          : null,
                ),
              ],
            ),
            title: Text(
              '${u?['name'] ?? 'Unknown'} - Room ${r?['number'] ?? 'N/A'}',
            ),
            subtitle: Text(
              '${_fmt(b['checkIn'])} → ${_fmt(b['checkOut'])}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                b['status'].toString().toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap:
                () => Get.to(
                  () => BookingDetailPage(
                    bookingId: int.tryParse(b['id'].toString()) ?? -1,
                  ),
                ),
          ),
        );
      },
    );
  }

  String _fmt(String? s) {
    if (s == null) return '-';
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
