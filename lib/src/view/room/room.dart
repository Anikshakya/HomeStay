// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class RoomsTab extends StatelessWidget {
  const RoomsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoomsListPage();
  }
}

class RoomsListPage extends StatefulWidget {
  const RoomsListPage({super.key});

  @override
  State<RoomsListPage> createState() => _RoomsListPageState();
}

class _RoomsListPageState extends State<RoomsListPage> {
  final HotelController hc = HotelController.to;
  final TextEditingController _searchController = TextEditingController();

  final List<String> statusFilters = [
    'All',
    'Available',
    'Occupied',
    'In Active',
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

  // ---------------------------
  // REAL ROOM STATUS CALCULATION
  // ---------------------------
  String _getRoomStatus(Map<String, dynamic> room) {
    // Active 0 → In Active
    if (room['active'].toString() != '1') {
      return 'In Active';
    }

    // Active bookings for this room
    final roomId = room['id'].toString();
    final hasActiveBooking = hc.bookings.any(
      (b) =>
          b['roomId'].toString() == roomId &&
          (b['status'] == 'booked' || b['status'] == 'checked_in'),
    );

    if (hasActiveBooking) return 'Occupied';

    return 'Available';
  }

  // Filter rooms by search and status
  List<Map<String, dynamic>> _getFilteredRooms(
    List<Map<String, dynamic>> allRooms,
  ) {
    return allRooms.where((room) {
      final status = _getRoomStatus(room);

      final statusMatch = _selectedFilter == 'All' || status == _selectedFilter;

      final searchMatch =
          room['number'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          room['type'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      return statusMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        final allRooms = hc.rooms.toList();
        final filteredRooms = _getFilteredRooms(allRooms);

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
                      if (filteredRooms.isEmpty)
                        _buildEmptyState()
                      else
                        ...filteredRooms
                            .map((room) => _buildRoomTableRow(context, room))
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

  // HEADER
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Room Master Panel',
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
              builder:
                  (ctx) => AddRoomDialog(),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add New Room',
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

  // CONTROL BAR
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
                hintText: 'Search by room number...',
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
          ...statusFilters.map((filter) => _buildFilterButton(context, filter)),
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

  // ROOM ROW
  Widget _buildRoomTableRow(BuildContext context, Map<String, dynamic> room) {
    final status = _getRoomStatus(room);

    Color statusColor;
    Color statusBgColor;

    switch (status) {
      case 'Available':
        statusColor = Colors.green.shade800;
        statusBgColor = Colors.green.shade100;
        break;
      case 'Occupied':
        statusColor = Colors.red.shade800;
        statusBgColor = Colors.red.shade100;
        break;
      case 'In Active':
        statusColor = Colors.orange.shade800;
        statusBgColor = Colors.orange.shade100;
        break;
      default:
        statusColor = Colors.grey.shade800;
        statusBgColor = Colors.grey.shade100;
    }

    final isActive = room['active'].toString() == '1';

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
              room['number'].toString(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 2, child: Text(room['type'].toString())),
          Expanded(
            flex: 1,
            child: Text(
              '\$${room['price']}',
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
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Switch(
                  value: isActive,
                  onChanged: (v) async {
                    await hc.updateRoom(
                      int.tryParse(room['id'].toString()) ?? -1,
                      {...room, 'active': v ? 1 : 0},
                    );
                  },
                  activeColor: Colors.green,
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:(ctx) =>AddRoomDialog(editRoom: room), // pass the room
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.edit, size: 20, color: Colors.grey),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    await hc.deleteRoom(
                      int.tryParse(room['id'].toString()) ?? -1,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
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
            Icon(Icons.search_off, size: 40, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No rooms match the current search or filters.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// TABLE HEADER
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
        children: [
          SizedBox(width: 100, child: Text('ROOM NO.', style: headerStyle)),
          Expanded(flex: 2, child: Text('TYPE', style: headerStyle)),
          Expanded(flex: 1, child: Text('PRICE', style: headerStyle)),
          Expanded(flex: 2, child: Text('STATUS', style: headerStyle)),
          SizedBox(
            width: 150,
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

class AddRoomDialog extends StatefulWidget {
  final Map<String, dynamic>? editRoom;

  const AddRoomDialog({super.key, this.editRoom});

  @override
  State<AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<AddRoomDialog> {
  final _form = GlobalKey<FormState>();

  final numberC = TextEditingController();
  final typeC = TextEditingController(); // Free-text type
  final priceC = TextEditingController();
  final descriptionC = TextEditingController();

  bool active = true;
  List<String> images = [];

  @override
  void initState() {
    super.initState();

    if (widget.editRoom != null) {
      final r = widget.editRoom!;
      numberC.text = r['number']?.toString() ?? '';
      typeC.text = r['type']?.toString() ?? '';
      priceC.text = r['price']?.toString() ?? '';
      descriptionC.text = r['description'] ?? '';
      active = r['active'].toString() == '1';

      images =
          (r['images'] as String? ?? '')
              .split(';')
              .where((e) => e.isNotEmpty)
              .toList();
    }
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
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

  void removeImage(int index) {
    setState(() {
      images.removeAt(index);
    });
  }

  Future<void> save() async {
    if (!_form.currentState!.validate()) return;

    final map = {
      'number': numberC.text.trim(),
      'type': typeC.text.trim(),
      'price': double.tryParse(priceC.text.trim()) ?? 0,
      'description': descriptionC.text.trim(),
      'active': active ? 1 : 0,
      'images': images.join(';'),
    };

    final hc = Get.find<HotelController>();

    if (widget.editRoom != null) {
      await hc.updateRoom(
        int.tryParse(widget.editRoom!['id'].toString()) ?? -1,
        map,
      );
      Navigator.pop(context);
    } else {
      await hc.addRoom(map);
      Navigator.pop(context);

      Get.snackbar(
        'Success',
        'Room added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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
            // Title header
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
                widget.editRoom != null ? 'Edit Room' : 'Add Room',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Room Number
                      TextFormField(
                        controller: numberC,
                        decoration: _input('Room Number'),
                        validator:
                            (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Room Type (Free-text)
                      TextFormField(
                        controller: typeC,
                        decoration: _input('Room Type'),
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

                      // Description
                      TextFormField(
                        controller: descriptionC,
                        maxLines: 3,
                        decoration: _input('Description'),
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
                            'Active Room',
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

            // Footer Buttons
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



