import 'dart:io';

import 'package:booking_desktop/src/app_config/styles.dart';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:booking_desktop/src/view/service/add_service_page.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServiceDetailPage extends StatelessWidget {
  final Map<String, dynamic> service;
  ServiceDetailPage({super.key, required this.service});
  final HotelController hc = HotelController.to;
  @override
  Widget build(BuildContext context) {
    final images =
        (service['images'] as String? ?? '')
            .split(';')
            .where((e) => e.isNotEmpty)
            .toList();
    return Scaffold(
      appBar: AppBar(title: Text(service['name'])),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Icons.room_service,
                  size: 80,
                  color: AppColors.checkedOut,
                ),
              ),
            SizedBox(height: 12),
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
                          service['name'],
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text(
                            service['active'] == 1 ? 'Active' : 'Inactive',
                          ),
                          backgroundColor:
                              service['active'] == 1
                                  ? AppColors.activeBg
                                  : AppColors.inactiveBg,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Category: ${service['category'] ?? ''}'),
                    SizedBox(height: 8),
                    Text('Price: ₨ ${service['price']}'),
                    SizedBox(height: 12),
                    Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(service['description'] ?? 'No description'),
                    SizedBox(height: 12),
                    Text(
                      'Schedule / Notes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(service['schedule'] ?? 'No schedule'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.edit),
                label: Text('Edit Service'),
                onPressed:
                    () => Get.to(
                      () => AddServicePage(editService: service),
                    )?.then((_) => Get.back()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
