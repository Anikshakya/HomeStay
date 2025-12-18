// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:booking_desktop/src/view/service/service_details_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicesListPage();
  }
}

class ServicesListPage extends StatefulWidget {
  const ServicesListPage({super.key});

  @override
  State<ServicesListPage> createState() => _ServicesListPageState();
}

class _ServicesListPageState extends State<ServicesListPage> {
  final HotelController hc = HotelController.to;
  final TextEditingController _searchController = TextEditingController();
  final List<String> categoryFilters = [
    'All',
    'Food',
    'Spa',
    'Laundry',
    'Transport',
  ];
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  String _getServiceCategory(Map<String, dynamic> service) {
    final existingCategory = service['category']?.toString() ?? '';
    if (existingCategory.isNotEmpty) return existingCategory;
    final serviceId = int.tryParse(service['id'].toString()) ?? 0;
    if (serviceId % 4 == 0) return 'Food';
    if (serviceId % 4 == 1) return 'Spa';
    if (serviceId % 4 == 2) return 'Laundry';
    return 'Transport';
  }

  List<Map<String, dynamic>> _getFilteredServices(
    List<Map<String, dynamic>> allServices,
  ) {
    return allServices.where((service) {
      final serviceCategory = _getServiceCategory(service);
      final categoryMatch =
          _selectedFilter == 'All' || serviceCategory == _selectedFilter;
      final searchMatch =
          service['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          service['price'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          serviceCategory.toLowerCase().contains(_searchQuery.toLowerCase());
      return categoryMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        final allServices = hc.services.toList();
        final filteredServices = _getFilteredServices(allServices);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            _buildControlBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      const _TableHeader(),
                      if (filteredServices.isEmpty)
                        _buildEmptyState()
                      else
                        ...filteredServices
                            .map(
                              (service) =>
                                  _buildServiceTableRow(context, service),
                            )
                            ,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Service Master Panel',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          ElevatedButton.icon(
            onPressed:
                () => showDialog(
                  context: context,
                  builder: (ctx) => const AddServiceDialog(),
                ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add New Service',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by service name or price...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 16.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ...categoryFilters.map(
            (filter) => _buildFilterButton(context, filter),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, String filter) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          backgroundColor: isSelected ? const Color(0xFF4CAF50) : Colors.white,
          side: BorderSide(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            width: 1.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTableRow(
    BuildContext context,
    Map<String, dynamic> service,
  ) {
    final category = _getServiceCategory(service);
    Color categoryBgColor;
    Color categoryTextColor;
    switch (category) {
      case 'Food':
        categoryBgColor = Colors.lightBlue.shade100;
        categoryTextColor = Colors.lightBlue.shade800;
        break;
      case 'Spa':
        categoryBgColor = Colors.purple.shade100;
        categoryTextColor = Colors.purple.shade800;
        break;
      case 'Laundry':
        categoryBgColor = Colors.deepOrange.shade100;
        categoryTextColor = Colors.deepOrange.shade800;
        break;
      default:
        categoryBgColor = Colors.grey.shade100;
        categoryTextColor = Colors.grey.shade800;
    }
    final isActive = service['active'].toString() == '1';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              service['id'].toString(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 3, child: Text(service['name'].toString())),
          Expanded(
            flex: 1,
            child: Text(
              '₨ ${service['price']}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: categoryBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: categoryTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap:
                      () => Get.to(() => ServiceDetailPage(service: service)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(Icons.visibility, size: 20, color: Colors.grey),
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (v) async {
                    await hc.updateService(
                      int.tryParse(service['id'].toString()) ?? -1,
                      {...service, 'active': v ? 1 : 0},
                    );
                  },
                  activeColor: Colors.green,
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap:
                      () => showDialog(
                        context: context,
                        builder:
                            (ctx) => AddServiceDialog(editService: service),
                      ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(Icons.edit, size: 20, color: Colors.grey),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    await hc.deleteService(
                      int.tryParse(service['id'].toString()) ?? -1,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(Icons.delete, size: 20, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(40.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.room_service_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No services match the current search or filters.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.grey,
      fontSize: 12,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: const [
          SizedBox(width: 100, child: Text('ID', style: headerStyle)),
          Expanded(flex: 3, child: Text('NAME', style: headerStyle)),
          Expanded(flex: 1, child: Text('PRICE', style: headerStyle)),
          Expanded(flex: 2, child: Text('CATEGORY', style: headerStyle)),
          SizedBox(
            width: 180,
            child: Text(
              'ACTIONS',
              style: headerStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class AddServiceDialog extends StatefulWidget {
  final Map<String, dynamic>? editService;

  const AddServiceDialog({super.key, this.editService});

  @override
  State<AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<AddServiceDialog> {
  final _form = GlobalKey<FormState>();

  final nameC = TextEditingController();
  final priceC = TextEditingController();
  final descC = TextEditingController();
  final scheduleC = TextEditingController();

  String? selectedCategory;
  bool active = true;
  List<String> images = [];

  final List<String> categories = ['Food', 'Spa', 'Laundry', 'Transport'];

  @override
  void initState() {
    super.initState();
    if (widget.editService != null) {
      final s = widget.editService!;
      nameC.text = s['name'] ?? '';
      priceC.text = s['price']?.toString() ?? '';
      descC.text = s['description'] ?? '';
      selectedCategory =
          (s['category']?.toString() ?? '').isNotEmpty
              ? s['category'].toString()
              : null;
      active = s['active'].toString() == '1';
      scheduleC.text = s['schedule'] ?? '';
      images =
          (s['images'] as String? ?? '')
              .split(';')
              .where((e) => e.isNotEmpty)
              .toList();
    }
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        images.addAll(picked.map((e) => e.path));
      });
    }
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
      'category': selectedCategory ?? '',
      'schedule': scheduleC.text.trim(),
      'images': images.join(';'),
    };

    final hc = Get.find<HotelController>();

    if (widget.editService != null) {
      await hc.updateService(
        int.tryParse(widget.editService!['id'].toString()) ?? -1,
        map,
      );
      Navigator.pop(context);
    } else {
      await hc.addService(map);
      Navigator.pop(context);
      Get.snackbar(
        'Success',
        'Service added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.50,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            // Title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Text(
                widget.editService != null ? 'Edit Service' : 'Add Service',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Name
                      TextFormField(
                        controller: nameC,
                        decoration: _input('Service Name'),
                        validator:
                            (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Price
                      TextFormField(
                        controller: priceC,
                        keyboardType: TextInputType.number,
                        decoration: _input('Price (NPR)'),
                        validator:
                            (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items:
                            categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          setState(() => selectedCategory = v);
                        },
                        decoration: _input('Category'),
                        validator:
                            (v) => v == null ? 'Select a category' : null,
                      ),
                      const SizedBox(height: 14),

                      // Description
                      TextFormField(
                        controller: descC,
                        maxLines: 3,
                        decoration: _input('Description'),
                      ),
                      const SizedBox(height: 14),

                      // Schedule
                      TextFormField(
                        controller: scheduleC,
                        decoration: _input('Service Schedule'),
                      ),
                      const SizedBox(height: 20),

                      // Active Switch
                      Row(
                        children: [
                          Switch(
                            value: active,
                            onChanged: (v) => setState(() => active = v),
                          ),
                          const Text(
                            'Active Service',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Images Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Images',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: pickImages,
                            child: const Text('Add Images'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Image preview grid
                      if (images.isNotEmpty)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(images.length, (i) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(images[i]),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: InkWell(
                                    onTap: () => removeImage(i),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
