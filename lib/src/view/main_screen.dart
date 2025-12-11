import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:booking_desktop/src/view/booking/booking_tab.dart';
import 'package:booking_desktop/src/view/calendar/calendar_tab.dart';
import 'package:booking_desktop/src/view/dashboard/dashboard.dart';
import 'package:booking_desktop/src/view/room/room.dart';
import 'package:booking_desktop/src/view/search/search_page.dart';
import 'package:booking_desktop/src/view/service/service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final HotelController hc = Get.put(HotelController());
  int idx = 0;
  final pages = [
    DashboardTab(),
    RoomsTab(),
    ServicesTab(),
    BookingList(),
    CalendarTab(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (hc.loading.value) {
            return Center(child: CircularProgressIndicator());
          }
          return pages[idx];
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(Icons.meeting_room), label: 'Rooms'),
          NavigationDestination(
            icon: Icon(Icons.room_service),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_online),
            label: 'Booking',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }
}
