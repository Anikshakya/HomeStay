import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:booking_desktop/src/view/booking/booking_tab.dart';
import 'package:booking_desktop/src/view/dashboard/dashboard.dart';
import 'package:booking_desktop/src/view/guest_management/guest_management.dart';
import 'package:booking_desktop/src/view/room/room.dart';
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

  int idx = 2; // Default page

  final List<Widget> pages = [
    DashboardTab(),
    BookingList(),
    RoomsTab(),
    ServicesTab(),
    GuestManagementPage(),
    const Center(child: Text("Billing")),
    const Center(child: Text("Reports")),
  ];

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF4CAF50);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1100;

        return Scaffold(
          body: SafeArea(
            child: Obx(() {
              if (hc.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (isDesktop) {
                return Row(
                  children: [
                    // ======================== SIDEBAR ========================
                    Container(
                      width: 260,
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.08),
                            blurRadius: 20,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Row(
                              children: const [
                                Icon(Icons.star, color: primaryColor, size: 30),
                                SizedBox(width: 10),
                                Text(
                                  "Homestay",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Divider(
                              thickness: 1,
                              height: 1,
                              indent: 15,
                              endIndent: 15,
                            ),
                          ),
                          // Menu
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              children: [
                                _menuTile(
                                  index: 0,
                                  label: "Dashboard",
                                  icon: Icons.dashboard_outlined,
                                  selectedIcon: Icons.dashboard,
                                  color: primaryColor,
                                ),
                                _menuTile(
                                  index: 1,
                                  label: "Bookings",
                                  icon: Icons.book_online_outlined,
                                  selectedIcon: Icons.book_online,
                                  color: primaryColor,
                                ),
                                _menuTile(
                                  index: 2,
                                  label: "Room Master",
                                  icon: Icons.king_bed_outlined,
                                  selectedIcon: Icons.king_bed,
                                  color: primaryColor,
                                ),
                                _menuTile(
                                  index: 3,
                                  label: "Food",
                                  icon: Icons.fastfood_outlined,
                                  selectedIcon: Icons.fastfood,
                                  color: primaryColor,
                                ),
                                _menuTile(
                                  index: 4,
                                  label: "Guest Management",
                                  icon: Icons.monetization_on_outlined,
                                  selectedIcon: Icons.monetization_on,
                                  color: primaryColor,
                                ),
                                _menuTile(
                                  index: 5,
                                  label: "Billing",
                                  icon: Icons.monetization_on_outlined,
                                  selectedIcon: Icons.monetization_on,
                                  color: primaryColor,
                                ),
                                _menuTile(
                                  index: 6,
                                  label: "Reports",
                                  icon: Icons.bar_chart_outlined,
                                  selectedIcon: Icons.bar_chart,
                                  color: primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ======================== CONTENT ========================
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha:0.08),
                              blurRadius: 20,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: pages[idx],
                        ),
                      ),
                    ),
                  ],
                );
              }

              // ======================== MOBILE / TABLET ========================
              return pages[idx];
            }),
          ),
          // ======================== BOTTOM NAV ========================
          bottomNavigationBar:
              isDesktop
                  ? null
                  : NavigationBar(
                    selectedIndex: idx,
                    onDestinationSelected: (i) => setState(() => idx = i),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.dashboard),
                        label: "Dashboard",
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.book_online),
                        label: "Bookings",
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.fastfood),
                        label: "Services",
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.king_bed),
                        label: "Rooms",
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.monetization_on),
                        label: "Guest Management",
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.monetization_on),
                        label: "Billing",
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.bar_chart),
                        label: "Reports",
                      ),
                    ],
                  ),
        );
      },
    );
  }

  // ======================== CUSTOM MENU TILE ========================
  Widget _menuTile({
    required int index,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
    required Color color,
  }) {
    final bool isSelected = idx == index;

    return InkWell(
      onTap: () => setState(() => idx = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha:0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 22,
              color: isSelected ? color : Colors.black87,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
