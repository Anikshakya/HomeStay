import 'dart:io';

import 'package:booking_desktop/src/app_config/styles.dart';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:booking_desktop/src/view/room/add_room.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RoomDetailPage extends StatelessWidget {
  final Map<String, dynamic> room;
  RoomDetailPage({super.key, required this.room});
  final HotelController hc = HotelController.to;
  
  @override
  Widget build(BuildContext context) {
    final images =
        (room['images'] as String? ?? '')
            .split(';')
            .where((e) => e.isNotEmpty)
            .toList();
    final amenities =
        (room['amenities'] as String? ?? '')
            .split(';')
            .where((e) => e.isNotEmpty)
            .toList();
    return Scaffold(
      appBar: AppBar(title: Text('Room ${room['number']}')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE CAROUSEL
            if (images.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  height: 240,
                  autoPlay: true,
                  enlargeCenterPage: true,
                ),
                items:
                    images
                        .map(
                          (path) => Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            if (images.isEmpty)
              Container(
                height: 240,
                alignment: Alignment.center,
                child: Icon(
                  Icons.meeting_room,
                  size: 80,
                  color: AppColors.checkedOut,
                ),
              ),
            SizedBox(height: 12),
            // DETAILS
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Room ${room['number']}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text(
                            room['active'] == 1 ? 'Active' : 'Inactive',
                          ),
                          backgroundColor:
                              room['active'] == 1
                                  ? AppColors.activeBg
                                  : AppColors.inactiveBg,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      room['type'] ?? '',
                      style: TextStyle(fontSize: 16, color: AppColors.primary),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '₨ ${room['price']} per night • ${room['beds']} beds • AC ${room['ac'] == 1 ? 'Yes' : 'No'}',
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(room['description'] ?? 'No description'),
                    SizedBox(height: 12),
                    Text(
                      'Amenities',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    if (amenities.isEmpty)
                      Text('None')
                    else
                      Wrap(
                        spacing: 8,
                        children:
                            amenities
                                .map(
                                  (a) => Chip(
                                    backgroundColor: AppColors.chipBg,
                                    label: Text(a),
                                  ),
                                )
                                .toList(),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.edit),
                label: Text('Edit Room'),
                onPressed:
                    () => Get.to(
                      () => AddRoomPage(editRoom: room),
                    )?.then((_) => Get.back()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
