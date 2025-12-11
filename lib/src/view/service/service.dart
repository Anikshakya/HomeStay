import 'dart:io';
import 'package:booking_desktop/src/app_config/constants.dart';
import 'package:booking_desktop/src/app_config/styles.dart';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:booking_desktop/src/view/service/add_service_page.dart';
import 'package:booking_desktop/src/view/service/service_details_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ServicesListPage();
  }
}

class ServicesListPage extends StatelessWidget {
  final HotelController hc = HotelController.to;
  ServicesListPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Service List'),
          bottom: TabBar(
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.white,
            tabs: [Tab(text: 'Active'), Tab(text: 'Inactive')],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => Get.to(() => AddServicePage()),
        ),
        body: TabBarView(
          children: [
            _responsiveServiceView(filterActive: true),
            _responsiveServiceView(filterActive: false),
          ],
        ),
      ),
    );
  }

  Widget _responsiveServiceView({required bool filterActive}) {
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
              hc.services
                  .where(
                    (s) =>
                        filterActive
                            ? s['active'].toString() == '1'
                            : s['active'].toString() != '1',
                  )
                  .toList();

          if (list.isEmpty) {
            return Center(
              child: Text(
                filterActive ? 'No active services' : 'No inactive services',
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
              final s = list[i];
              final images =
                  (s['images'] as String? ?? '')
                      .split(';')
                      .where((e) => e.isNotEmpty)
                      .toList();

              return Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Get.to(() => ServiceDetailPage(service: s)),
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
                                      Icons.room_service,
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
                                s['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₨ ${s['price']} • ${s['category'] ?? ''}',
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
                              value: s['active'].toString() == '1',
                              onChanged: (v) async {
                                await hc.updateService(
                                  int.tryParse(s['id'].toString()) ?? -1,
                                  {...s, 'active': v ? 1 : 0},
                                );
                              },
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  Get.to(() => AddServicePage(editService: s));
                                }
                                if (v == 'delete') {
                                  await hc.deleteService(
                                    int.tryParse(s['id'].toString()) ?? -1,
                                  );
                                }
                                if (v == 'detail') {
                                  Get.to(() => ServiceDetailPage(service: s));
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
