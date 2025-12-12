import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:booking_desktop/src/app_config/styles.dart';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:booking_desktop/src/view/booking/add_bookings.dart';
import 'package:booking_desktop/src/view/booking/booking_details.dart';

class BookingList extends StatefulWidget {
  const BookingList({super.key});

  @override
  State<BookingList> createState() => _BookingListState();
}

class _BookingListState extends State<BookingList>
    with SingleTickerProviderStateMixin {
  final HotelController hc = HotelController.to;
  final TextEditingController searchController = TextEditingController();
  late TabController _tabController;
  RxString searchText = ''.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    searchController.addListener(() {
      searchText.value = searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List _filterBookings(String tabStatus) {
    final List<String> statuses =
        tabStatus == 'Current Guests'
            ? ['booked', 'checked_in']
            : ['checked_out'];

    return hc.bookings.where((b) => statuses.contains(b['status'])).where((b) {
      final user = hc.users.firstWhereOrNull((u) => u['id'] == b['userId']);
      if (user == null) return false;
      final query = searchText.value;
      final room =
          hc.rooms
              .firstWhereOrNull((r) => r['id'] == b['roomId'])?['number']
              .toString()
              .toLowerCase();
      return user['name'].toString().toLowerCase().contains(query) ||
          user['phone'].toString().toLowerCase().contains(query) ||
          (room ?? '').contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bookings'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Get.to(() => AddBookingPage()),
      ),
      body: Obx(() {
        return Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _bookingGrid(_filterBookings('Current Guests'), width),
                  _bookingGrid(_filterBookings('Past Guests'), width),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 10),
          _buildTabBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search by guest name or room...',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary.withValues(alpha:0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15.0,
            horizontal: 10.0,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.shadow.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        tabs: const [Tab(text: 'Current Guests'), Tab(text: 'Past Guests')],
      ),
    );
  }

  Widget _bookingGrid(List bookings, double width) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          'No bookings found',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final isDesktop = width > 1000;
    final isTablet = width > 600 && width <= 1000;
    final crossAxisCount =
        isDesktop
            ? 3
            : isTablet
            ? 2
            : 1;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: 160,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: bookings.length,
      itemBuilder: (_, i) {
        final b = bookings[i];
        final u = hc.users.firstWhereOrNull((x) => x['id'] == b['userId']);
        final r = hc.rooms.firstWhereOrNull((x) => x['id'] == b['roomId']);
        return _bookingCard(b, u, r);
      },
    );
  }

  Widget _bookingCard(Map b, Map? u, Map? r) {
    final status = b['status'];
    String displayStatus;
    Color statusColor;

    if (status == 'checked_in') {
      displayStatus = 'Checked-in';
      statusColor = Colors.green;
    } else if (status == 'booked') {
      displayStatus = 'Booked';
      statusColor = Colors.orange;
    } else {
      displayStatus = status.toString();
      statusColor = AppColors.textSecondary.withValues(alpha:0.5);
    }

    final imagePath = u?['image'] as String?;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              () => Get.to(
                () => BookingDetailPage(
                  bookingId: int.tryParse(b['id'].toString()) ?? -1,
                ),
              ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.shadow.withValues(alpha:0.1),
                      backgroundImage:
                          imagePath != null && imagePath.isNotEmpty
                              ? File(imagePath).existsSync()
                                  ? Image.file(File(imagePath)).image
                                  : null
                              : null,
                      child:
                          (imagePath == null || imagePath.isEmpty)
                              ? Text(
                                u?['name'] != null && u!['name'].isNotEmpty
                                    ? u['name'][0]
                                    : '?',
                                style: TextStyle(color: AppColors.primary),
                              )
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u?['name'] ?? 'Unknown Guest',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r?['name'] ?? 'Room ${r?['number'] ?? 'N/A'}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${_fmt(b['checkIn'])} - ${_fmt(b['checkOut'])}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        displayStatus.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Divider(height: 1, color: Colors.grey[200]),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: Icons.call,
                      label: 'Call',
                      onPressed: () {
                        /* Call logic */
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.message,
                      label: 'Message',
                      onPressed: () {
                        /* Message logic */
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(
        label,
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: AppColors.primary.withValues(alpha:0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _fmt(String? s) {
    if (s == null) return '-';
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;

    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

extension StringExtension on String {
  String? get capitalizeFirst {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
