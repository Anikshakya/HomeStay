// dashboard_tab.dart
// Production-ready, responsive Material 3 Dashboard widget for Flutter (GetX-friendly)

import 'dart:io';

import 'package:booking_desktop/src/view/search/search_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:booking_desktop/src/app_config/styles.dart';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:booking_desktop/src/view/booking/booking_details.dart';
import 'package:booking_desktop/src/view/booking/booking_tab.dart';
import 'package:booking_desktop/src/view/calendar/calendar_tab.dart';
import 'package:booking_desktop/src/view/others/user_list_page.dart';
import 'package:booking_desktop/src/view/room/add_room.dart';
import 'package:booking_desktop/src/view/room/room.dart';
import 'package:booking_desktop/src/view/service/add_service_page.dart';
import 'package:booking_desktop/src/view/service/service.dart';

class DashboardTab extends StatelessWidget {
  DashboardTab({super.key});

  final HotelController hc = HotelController.to;

  static const double kDesktopBreakpoint = 1200;
  static const double kTabletBreakpoint = 800;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hotel Manager'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => Get.to(() => GlobalSearchPage()),
          ),
        ],
      ),
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => hc.loadAll(),
          edgeOffset: 16,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= kDesktopBreakpoint) {
                return _buildDesktop(context, cs);
              } else if (constraints.maxWidth >= kTabletBreakpoint) {
                return _buildTablet(context, cs);
              } else {
                return _buildMobile(context, cs);
              }
            },
          ),
        ),
      ),
    );
  }

  // ---------------------- Layout Variants ----------------------

  Widget _buildDesktop(BuildContext context, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left column: navigation / quick actions
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _brand(context),
                const SizedBox(height: 20),
                _quickActionsGrid(context, crossAxisCount: 1),
              ],
            ),
          ),
        ),

        // Main content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Overview'),
                  const SizedBox(height: 8),
                  Obx(() => _overviewGrid(context, columns: 3)),
                  const SizedBox(height: 24),
                  _sectionBookings(),
                ],
              ),
            ),
          ),
        ),

        // Right column: calendar
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Calendar'),
                Expanded(child: CalendarTab()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTablet(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 12),
          _brand(context),
          const SizedBox(height: 16),
          _sectionTitle('Overview'),
          const SizedBox(height: 8),
          Obx(() => _overviewGrid(context, columns: 2)),
          const SizedBox(height: 24),
          _sectionTitle('Bookings'),
          const SizedBox(height: 8),
          _sectionBookings(),
          const SizedBox(height: 24),
          _sectionTitle('Quick Actions'),
          _quickActionsGrid(context, crossAxisCount: 2),
          const SizedBox(height: 24),
          _sectionTitle('Calendar'),
          SizedBox(height: 380, child: CalendarTab()),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 12),
          _brand(context),
          const SizedBox(height: 16),
          _sectionTitle('Overview'),
          const SizedBox(height: 8),
          Obx(() => _overviewGrid(context, columns: 2)),
          const SizedBox(height: 24),
          _sectionTitle('Bookings'),
          const SizedBox(height: 8),
          _sectionBookings(),
          const SizedBox(height: 24),
          _sectionTitle('Quick Actions'),
          _quickActionsGrid(context, crossAxisCount: 2),
          const SizedBox(height: 24),
          _sectionTitle('Calendar'),
          SizedBox(height: 320, child: CalendarTab()),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---------------------- Reusable UI ----------------------

  Widget _brand(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'BD',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Booking Dashboard',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => hc.loadAll(),
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      t,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _overviewGrid(BuildContext context, {int columns = 3}) {
    final items = [
      _StatCardData(
        title: 'Users',
        value: hc.activeUsersCount().toString(),
        icon: Icons.people,
        color: AppColors.primaryLight,
        onTap: () => Get.to(() => UsersListPage()),
      ),
      _StatCardData(
        title: 'Rooms',
        value: hc.activeRoomsCount().toString(),
        icon: Icons.meeting_room,
        color: AppColors.secondaryLight,
        onTap: () => Get.to(() => RoomsListPage()),
      ),
      _StatCardData(
        title: 'Services',
        value: hc.activeServicesCount().toString(),
        icon: Icons.room_service,
        color: AppColors.tertiaryLight,
        onTap: () => Get.to(() => ServicesListPage()),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 92,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _statCard(
          item.title,
          item.value,
          item.icon,
          item.color,
          item.onTap,
        );
      },
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    VoidCallback onTap,
  ) {
    final isMobile = Get.width < 600;
    return Semantics(
      button: true,
      label: '$title: $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 18 : 26,
                backgroundColor: bgColor,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionsGrid(BuildContext context, {int crossAxisCount = 2}) {
    final actions = [
      _QuickAction(
        icon: Icons.meeting_room,
        label: 'Add Room',
        onTap: () => Get.to(() => AddRoomPage()),
      ),
      _QuickAction(
        icon: Icons.room_service,
        label: 'Add Service',
        onTap: () => Get.to(() => AddServicePage()),
      ),
      _QuickAction(
        icon: Icons.book_online,
        label: 'Create Booking',
        onTap: () => Get.to(() => BookingList()),
      ),
      _QuickAction(
        icon: Icons.calendar_today,
        label: 'Open Calendar',
        onTap: () => Get.to(() => CalendarTab()),
      ),
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 92,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
          ),
          onPressed: actions[i].onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(actions[i].icon, size: 28),
              const SizedBox(height: 6),
              Text(actions[i].label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionBookings() => Obx(() {
    if (hc.bookings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No bookings yet',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final activeBookings =
        hc.bookings
            .where(
              (b) => b['status'] == 'booked' || b['status'] == 'checked_in',
            )
            .toList();
    final completedBookings =
        hc.bookings.where((b) => b['status'] == 'checked_out').toList();
    final cancelledBookings =
        hc.bookings.where((b) => b['status'] == 'cancelled').toList();

    return DefaultTabController(
      length: 3,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _sectionTitle('Guest Logs'),
            ),
            TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
            SizedBox(
              height: 280,
              child: TabBarView(
                children: [
                  _bookingList(activeBookings),
                  _bookingList(completedBookings),
                  _bookingList(cancelledBookings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });

  Widget _bookingList(List bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          'No bookings here',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: bookings.length.clamp(0, 12),
      separatorBuilder:
          (_, __) =>
              const Divider(height: 1, color: Color(0xFFE5E5EA), thickness: 1),
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

        // Hover effect for desktop
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: StatefulBuilder(
            builder: (context, setState) {
              bool isHover = false;
              return GestureDetector(
                onTap:
                    () => Get.to(
                      () => BookingDetailPage(
                        bookingId: int.tryParse(b['id'].toString()) ?? -1,
                      ),
                    ),
                child: MouseRegion(
                  onEnter: (_) => setState(() => isHover = true),
                  onExit: (_) => setState(() => isHover = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isHover
                              ? Colors.grey.withOpacity(0.05)
                              : Colors.white,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.shadow.withValues(
                            alpha: 0.1,
                          ),
                          backgroundImage:
                              imagePath != null && imagePath.isNotEmpty
                                  ? Image.file(File(imagePath)).image
                                  : null,
                          child:
                              imagePath == null || imagePath.isEmpty
                                  ? Text(
                                    u?['name'] != null && u!['name'].isNotEmpty
                                        ? u['name'][0]
                                        : '?',
                                    style: const TextStyle(color: Colors.black),
                                  )
                                  : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${u?['name'] ?? 'Unknown'} - Room ${r?['number'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_fmt(b['checkIn'])} → ${_fmt(b['checkOut'])}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            b['status'].toString().toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }


  String _fmt(String? s) {
    if (s == null) return '-';
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    return DateFormat('yyyy-MM-dd').format(dt);
  }
}

// ---------------------- Helpers ----------------------

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _QuickAction({required this.icon, required this.label, required this.onTap});
}

class _StatCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
