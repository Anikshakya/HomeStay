import 'dart:io';

import 'package:booking_desktop/src/app_config/styles.dart';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AddServicePage extends StatefulWidget {
  final Map<String, dynamic>? editService;
  const AddServicePage({super.key, this.editService});
  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final _form = GlobalKey<FormState>();
  final nameC = TextEditingController();
  final priceC = TextEditingController();
  final descC = TextEditingController();
  final categoryC = TextEditingController();
  final scheduleC = TextEditingController();
  bool active = true;
  List<String> images = [];
  @override
  void initState() {
    super.initState();
    if (widget.editService != null) {
      final s = widget.editService!;
      nameC.text = s['name'] ?? '';
      priceC.text = (s['price'] ?? '').toString();
      active = s['active'].toString() == 1.toString();
      descC.text = s['description'] ?? '';
      categoryC.text = s['category'] ?? '';
      scheduleC.text = s['schedule'] ?? '';
      images =
          (s['images'] as String? ?? '')
              .split(';')
              .where((e) => e.isNotEmpty)
              .toList();
    }
  }

  @override
  void dispose() {
    nameC.dispose();
    priceC.dispose();
    descC.dispose();
    categoryC.dispose();
    scheduleC.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    setState(() {
      images.addAll(picked.map((e) => e.path));
    });
    }

  void removeImage(int idx) {
    setState(() {
      images.removeAt(idx);
    });
  }

  Future<void> save() async {
    if (!_form.currentState!.validate()) return;
    final map = {
      'name': nameC.text.trim(),
      'price': double.tryParse(priceC.text.trim()) ?? 0,
      'active': active ? 1 : 0,
      'description': descC.text.trim(),
      'category': categoryC.text.trim(),
      'schedule': scheduleC.text.trim(),
      'images': images.join(';'),
    };
    if (widget.editService != null) {
      await Get.find<HotelController>().updateService(
        int.tryParse(widget.editService!['id']) ?? -1,
        map,
      );
      Get.back();
    } else {
      await Get.find<HotelController>().addService(map);
      nameC.clear();
      priceC.clear();
      active = true;
      descC.clear();
      categoryC.clear();
      scheduleC.clear();
      images.clear();
      setState(() {});
      Get.snackbar(
        'Saved',
        'Service added',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editService != null ? 'Edit Service' : 'Add Service',
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: nameC,
                decoration: InputDecoration(
                  labelText: 'Service Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: priceC,
                decoration: InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: categoryC,
                decoration: InputDecoration(
                  labelText: 'Category (e.g Food, Laundry)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: descC,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: scheduleC,
                decoration: InputDecoration(
                  labelText: 'Schedule / Availability notes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text('Active'),
                        Switch(
                          value: active,
                          onChanged: (v) => setState(() => active = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: pickImages,
                icon: Icon(Icons.image),
                label: Text('Pick images'),
              ),
              if (images.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder:
                        (_, i) => Stack(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(images[i]),
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => removeImage(i),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: AppColors.primaryForeground,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    separatorBuilder: (_, __) => SizedBox(width: 8),
                  ),
                ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: save,
                icon: Icon(Icons.save),
                label: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
