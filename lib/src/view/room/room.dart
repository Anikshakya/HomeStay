import 'dart:io';
import 'package:booking_desktop/src/app_config/constants.dart';
import 'package:booking_desktop/src/app_config/styles.dart';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:booking_desktop/src/view/room/add_room.dart';
import 'package:booking_desktop/src/view/room/room_details.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RoomsTab extends StatelessWidget {
  const RoomsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return RoomsListPage();
  }
}

class RoomsListPage extends StatelessWidget {
  final HotelController hc = HotelController.to;
  RoomsListPage({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rooms List'),
          bottom: TabBar(
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.white,
            tabs: [Tab(text: 'Active'), Tab(text: 'Inactive')],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => Get.to(() => AddRoomPage()),
        ),
        body: TabBarView(
          children: [
            _responsiveRoomsView(filterActive: true),
            _responsiveRoomsView(filterActive: false),
          ],
        ),
      ),
    );
  }

  Widget _responsiveRoomsView({required bool filterActive}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double spacing = 16;

        if (constraints.maxWidth >= kDesktopBreakpoint) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= kTabletBreakpoint) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return Obx(() {
          final list =
              hc.rooms
                  .where(
                    (r) =>
                        filterActive
                            ? r['active'].toString() == '1'
                            : r['active'].toString() != '1',
                  )
                  .toList();

          if (list.isEmpty) {
            return Center(
              child: Text(
                filterActive ? 'No active rooms' : 'No inactive rooms',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              mainAxisExtent: 120,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final r = list[i];
              final images =
                  (r['images'] as String? ?? '')
                      .split(';')
                      .where((e) => e.isNotEmpty)
                      .toList();

              return Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Get.to(() => RoomDetailPage(room: r)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              images.isNotEmpty
                                  ? Image.file(
                                    File(images.first),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.meeting_room,
                                      size: 32,
                                      color: Colors.grey,
                                    ),
                                  ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Room ${r['number']} — ${r['type']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₨ ${r['price']} • Beds: ${r['beds']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Switch(
                              value: r['active'].toString() == '1',
                              onChanged: (v) async {
                                await hc.updateRoom(
                                  int.tryParse(r['id'].toString()) ?? -1,
                                  {...r, 'active': v ? 1 : 0},
                                );
                              },
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  Get.to(() => AddRoomPage(editRoom: r));
                                }
                                if (v == 'delete') {
                                  await hc.deleteRoom(
                                    int.tryParse(r['id'].toString()) ?? -1,
                                  );
                                }
                                if (v == 'detail') {
                                  Get.to(() => RoomDetailPage(room: r));
                                }
                              },
                              itemBuilder:
                                  (_) => const [
                                    PopupMenuItem(
                                      value: 'detail',
                                      child: Text('View details'),
                                    ),
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        });
      },
    );
  }
}
