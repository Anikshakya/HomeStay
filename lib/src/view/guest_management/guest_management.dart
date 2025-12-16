import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';

// -------------------------
// Theme Colors
// -------------------------
const Color _kPrimaryColor = Color(0xFF00E676);
const Color _kBackgroundColor = Color(0xFFF5F5F5);
const Color _kCardColor = Colors.white;
const Color _kTextColor = Color(0xFF333333);

// =========================
// Responsive Layout Wrapper
// =========================
class ResponsiveGuestLayout extends StatelessWidget {
  final Widget leftPanel;
  final Widget rightPanel;

  const ResponsiveGuestLayout({
    super.key,
    required this.leftPanel,
    required this.rightPanel,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const breakpoint = 900;

    if (screenWidth > breakpoint) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: leftPanel),
          const SizedBox(width: 32),
          Expanded(flex: 5, child: rightPanel),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [leftPanel, const SizedBox(height: 32), rightPanel],
      );
    }
  }
}

// =========================
// Guest Management Page
// =========================
class GuestManagementPage extends StatelessWidget {
  const GuestManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Guest Management',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _kTextColor,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage guest check-ins and view current stays.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const ResponsiveGuestLayout(
              leftPanel: NewGuestCheckInCard(),
              rightPanel: CurrentGuestsCard(),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// Left Panel: New Guest Check-in
// =========================
class NewGuestCheckInCard extends StatefulWidget {
  const NewGuestCheckInCard({super.key});

  @override
  State<NewGuestCheckInCard> createState() => _NewGuestCheckInCardState();
}

class _NewGuestCheckInCardState extends State<NewGuestCheckInCard> {
  final _controller = HotelController.to;

  // Guest info controllers
  final _nameC = TextEditingController();
  final _addressC = TextEditingController();
  final _citizenNoC = TextEditingController();
  final _occupationC = TextEditingController();
  final _contactC = TextEditingController();
  final _relationC = TextEditingController();
  final _reasonC = TextEditingController();
  final _discountC = TextEditingController();
  final _extraChargeC = TextEditingController();
  final _chargeReasonC = TextEditingController();

  final _guestCount = TextEditingController(text: "1");
  File? _citizenImage;

  // --------------------------
  // Room + Check-in/Check-out selection
  // --------------------------
  final RxList<RxMap<String, dynamic>> _roomSelections =
      <RxMap<String, dynamic>>[].obs;

  @override
  void initState() {
    super.initState();
    _roomSelections.add(_createEmptyRoomSelection());
  }

  RxMap<String, dynamic> _createEmptyRoomSelection() {
    return RxMap<String, dynamic>({
      'roomId': '',
      'checkInDate': null,
      'checkInTime': null,
      'checkOutDate': null,
      'checkOutTime': null,
      'discount': 0,
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) setState(() => _citizenImage = File(picked.path));
  }

  void _addRoom() {
    _roomSelections.add(_createEmptyRoomSelection());
  }

  void _removeRoom(int index) {
    if (_roomSelections.length > 1) {
      _roomSelections.removeAt(index);
    } else {
      _roomSelections[0] = _createEmptyRoomSelection();
    }
  }

  Future<void> _selectDate(int index, bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      if (isCheckIn) {
        _roomSelections[index]['checkInDate'] = picked;
      } else {
        _roomSelections[index]['checkOutDate'] = picked;
      }
    }
  }

  Future<void> _selectTime(int index, bool isCheckIn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (isCheckIn) {
        _roomSelections[index]['checkInTime'] = picked.format(context);
      } else {
        _roomSelections[index]['checkOutTime'] = picked.format(context);
      }
    }
  }

  Future<void> _submit() async {
    final items =
        _roomSelections.where((r) => r['roomId'] != null && r['roomId'] != '').toList();
    if (items.isEmpty) {
      Get.snackbar('Error', 'Please select at least one room');
      return;
    }

    // Check availability
    for (var selection in items) {
      final roomId = selection['roomId'];
      final checkInDate = selection['checkInDate'];
      final checkInTime = selection['checkInTime'];
      final checkOutDate = selection['checkOutDate'];
      final checkOutTime = selection['checkOutTime'];

      if (roomId == null ||
          checkInDate == null ||
          checkInTime == null ||
          checkOutDate == null ||
          checkOutTime == null) {
        Get.snackbar(
          'Error',
          'Please select check-in and check-out date/time for all rooms',
        );
        return;
      }

      final available = getRoomAvailability(
        room: _controller.rooms.firstWhere((r) => r['id'].toString() == roomId.toString()),
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
      );

      if (!available.selectable) {
        Get.snackbar(
          'Error',
          'Room ${roomId} is not available: ${available.reason ?? 'Booked'}',
        );
        return;
      }
    }

    final imageBytes =
        _citizenImage != null ? await _citizenImage!.readAsBytes() : null;

    final guestData = {
      'name': _nameC.text,
      'address': _addressC.text,
      'citizenNumber': _citizenNoC.text,
      'occupation': _occupationC.text,
      'numberOfGuests': int.tryParse(_guestCount.text) ?? 1,
      'relationWithPartner': _relationC.text,
      'reasonOfStay': _reasonC.text,
      'contactNumber': _contactC.text,
      'citizenImageBlob': imageBytes,
      'overallDiscountRs': double.tryParse(_discountC.text) ?? 0,
      'extraChargesRs': double.tryParse(_extraChargeC.text) ?? 0,
      'chargeReason': _chargeReasonC.text,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _controller.addGuestLog(guestData, items);

    Get.snackbar('Success', 'Guest checked in');
    _clearForm();
  }

  void _clearForm() {
    _nameC.clear();
    _addressC.clear();
    _citizenNoC.clear();
    _occupationC.clear();
    _contactC.clear();
    _relationC.clear();
    _reasonC.clear();
    _discountC.clear();
    _extraChargeC.clear();
    _chargeReasonC.clear();
    _citizenImage = null;
    _roomSelections.clear();
    _roomSelections.add(_createEmptyRoomSelection());
  }

  DateTime? parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _kCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Guest Check-in',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            _tf('Full Name', _nameC),
            Row(
              children: [
                Expanded(child: _tf('Contact Number', _contactC)),
                SizedBox(width: 10,),
                Expanded(child: _tf('Address', _addressC)),
              ],
            ),
            _tf('Citizen Number', _citizenNoC),
            const SizedBox(height: 12),
            const Text('ID Proof'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _citizenImage == null
                      ? const Text('Click to upload ID')
                      : Image.file(_citizenImage!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Rooms & Check-in/Check-out'),
            const SizedBox(height: 8),
            Obx(() {
              final rooms = _controller.rooms;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...List.generate(_roomSelections.length, (index) {
                    final selection = _roomSelections[index];
                    final discountController = TextEditingController(
                      text: selection['discount']?.toString() ?? '0',
                    );
                    discountController.addListener(() {
                      selection['discount'] =
                          int.tryParse(discountController.text) ?? 0;
                    });

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Room ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.blue,
                                  ),
                                ),
                                if (_roomSelections.length > 1)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeRoom(index),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(index, true),
                                    child: Obx(
                                      () => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          selection['checkInDate'] != null
                                              ? "${selection['checkInDate'].day}-${selection['checkInDate'].month}-${selection['checkInDate'].year}"
                                              : 'Check-in Date',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(index, true),
                                    child: Obx(
                                      () => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          selection['checkInTime'] ??
                                              'Check-in Time',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(index, false),
                                    child: Obx(
                                      () => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          selection['checkOutDate'] != null
                                              ? "${selection['checkOutDate'].day}-${selection['checkOutDate'].month}-${selection['checkOutDate'].year}"
                                              : 'Check-out Date',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(index, false),
                                    child: Obx(
                                      () => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          selection['checkOutTime'] ??
                                              'Check-out Time',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value:
                                  selection['roomId'] == ''
                                      ? null
                                      : selection['roomId'],
                              hint: const Text(
                                'Select Room',
                              ), // Placeholder text
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items:
                                  rooms.map((r) {
                                    final availability = getRoomAvailability(
                                      room: r,
                                      checkInDate: selection['checkInDate'],
                                      checkOutDate: selection['checkOutDate'],
                                    );

                                    return DropdownMenuItem<String>(
                                      value: r['id'],
                                      enabled: availability.selectable,
                                      child: Row(
                                        children: [
                                          Text(
                                            r['number'] ?? 'Unknown',
                                            style: TextStyle(
                                              color:
                                                  availability.selectable
                                                      ? Colors.black
                                                      : Colors.grey,
                                            ),
                                          ),
                                          if (!availability.selectable) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              availability.reason == 'Inactive'
                                                  ? '(Inactive)'
                                                  : availability
                                                          .bookingStatus !=
                                                      null
                                                  ? '(${availability.bookingStatus})'
                                                  : '(Unavailable)',
                                              style: TextStyle(
                                                color:
                                                    availability.reason ==
                                                            'Inactive'
                                                        ? Colors.orange
                                                        : Colors.red,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  selection['roomId'] = v;
                                }
                              },
                            ),

                            const SizedBox(height: 12),
                            TextField(
                              controller: discountController,
                              decoration: InputDecoration(
                                labelText: 'Discount (%)',
                                prefixIcon: const Icon(Icons.local_offer),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: _addRoom,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Room'),
                  ),
                ],
              );
            }),
            const SizedBox(height: 10),
            _tf('Occupation', _occupationC),
            _tf('Relation With Partner', _relationC),
            _tf('No. of Guest', _guestCount),
            _tf('Reason Of Stay', _reasonC),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Check-in Guest',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tf(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Room availability check
  RoomAvailability getRoomAvailability({
    required Map<String, dynamic> room,
    required DateTime? checkInDate,
    required DateTime? checkOutDate,
  }) {
    if (room['active'].toString() != 1.toString()) {
      return RoomAvailability(selectable: false, reason: 'Inactive');
    }

    if (checkInDate == null || checkOutDate == null) {
      return RoomAvailability(selectable: true);
    }

    for (final b in _controller.bookingItems) {
      if (b['roomId'].toString() != room['id'].toString()) continue;

      final existingCheckIn = parseDate(b['arrivalDate']);
      final existingCheckOut = parseDate(b['checkOutDate']);

      if (existingCheckIn == null || existingCheckOut == null) continue;

      final overlap =
          existingCheckIn.isBefore(checkOutDate) && existingCheckOut.isAfter(checkInDate);

      if (overlap) {
        return RoomAvailability(
          selectable: false,
          reason: 'Booked',
          bookingStatus: b['status'],
        );
      }
    }

    return RoomAvailability(selectable: true);
  }
}

class RoomAvailability {
  final bool selectable;
  final String? reason;
  final String? bookingStatus;

  RoomAvailability({required this.selectable, this.reason, this.bookingStatus});
}


// =========================
// Right Panel: Current Guests
// =========================

class CurrentGuestsCard extends StatefulWidget {
  const CurrentGuestsCard({super.key});

  @override
  State<CurrentGuestsCard> createState() => _CurrentGuestsCardState();
}

class _CurrentGuestsCardState extends State<CurrentGuestsCard> {
  final _controller = HotelController.to;

  final ScrollController _verticalScroll = ScrollController();
  final ScrollController _horizontalScroll = ScrollController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller.loadBookingItemsForGuests();
  }

  @override
  void dispose() {
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  // final List<String> statusFilters = [
  //   'All',
  //   'Current',
  //   'Past',
  // ];

  // Widget _buildFilterButton(BuildContext context, String filter) {
  //   final isSelected = _selectedFilter == filter;

  //   return Padding(
  //     padding: const EdgeInsets.only(right: 8.0),
  //     child: OutlinedButton(
  //       onPressed: () {
  //         setState(() {
  //           _selectedFilter = filter;
  //         });
  //       },
  //       style: OutlinedButton.styleFrom(
  //         foregroundColor: isSelected ? Colors.white : Colors.black87,
  //         backgroundColor: isSelected ? const Color(0xFF4CAF50) : Colors.white,
  //         side: BorderSide(
  //           color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
  //           width: 1.2,
  //         ),
  //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //       ),
  //       child: Text(
  //         filter,
  //         style: TextStyle(
  //           color: isSelected ? Colors.white : Colors.black87,
  //           fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _kCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Guests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildSearchBar(),
              ],
            ),
            const SizedBox(height: 10),
            Obx(() {
              if (_controller.guestLogs.isEmpty) {
                return const Center(child: Text('No current guests'));
              }
            
              // Filter guests based on search query
              final filteredGuests =
                  _controller.guestLogs.where((g) {
                    final guestName =
                        (g['name'] ?? '').toString().toLowerCase();
                    final guestPhone =
                        (g['contactNumber'] ?? '').toString().toLowerCase();
            
                    // Collect guest rooms
                    final guestRoomNumbers = _controller.bookingItems
                        .where(
                          (b) => b['logId'].toString() == g['id'].toString(),
                        )
                        .map((b) {
                          final room = _controller.rooms.firstWhere(
                            (r) =>
                                r['id'].toString() == b['roomId'].toString(),
                            orElse: () => {'number': 'Unknown'},
                          );
                          return room['number'].toString().toLowerCase();
                        })
                        .join(' ');
            
                    final query = _searchQuery.toLowerCase();
                    return guestName.contains(query) ||
                        guestPhone.contains(query) ||
                        guestRoomNumbers.contains(query);
                  }).toList();
            
              if (filteredGuests.isEmpty) {
                return const Center(child: Text('No matching guests'));
              }
            
              final rows = <DataRow>[];
            
              for (final g in filteredGuests) {
                final Map<String, Map<String, dynamic>> roomBookings = {};
            
                for (final b in _controller.bookingItems) {
                  if (b['logId'].toString() != g['id'].toString()) continue;
                  final roomId = b['roomId'].toString();
                  roomBookings.putIfAbsent(roomId, () => b);
                }
            
                for (final b in roomBookings.values) {
                  final room = _controller.rooms.firstWhere(
                    (r) => r['id'].toString() == b['roomId'].toString(),
                    orElse: () => {'number': 'Unknown'},
                  );
            
                  final checkIn =
                      b['arrivalDate'] != null
                          ? "${_formatDate(b['arrivalDate'])} ${b['checkInTime'] ?? ''}"
                          : '';
            
                  final checkOut =
                      b['checkOutDate'] != null
                          ? "${_formatDate(b['checkOutDate'])} ${b['checkOutTime'] ?? ''}"
                          : '';
            
                  rows.add(
                    DataRow(
                      cells: [
                        // Action buttons
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Edit Guest',
                                onPressed: () {
                                  // _controller.updateGuestLog(g);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete Guest',
                                onPressed: () {
                                  // _controller.dele(g['id']);
                                },
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(g['name'] ?? '')),
                        DataCell(Text(room['number'] ?? 'Unknown')),
                        DataCell(Text(checkIn)),
                        DataCell(Text(checkOut)),
                        const DataCell(Text('Active')),
                      ],
                    ),
                  );
                }
              }
            
              return Scrollbar(
                controller: _verticalScroll,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalScroll,
                  scrollDirection: Axis.vertical,
                  child: Scrollbar(
                    controller: _horizontalScroll,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _horizontalScroll,
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Actions')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Room')),
                          DataColumn(label: Text('Check-in')),
                          DataColumn(label: Text('Check-out')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: rows,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Expanded(
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by name, phone, or room...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic v) {
    if (v == null) return '';
    if (v is DateTime) return '${v.day}-${v.month}-${v.year}';
    if (v is String) {
      final d = DateTime.tryParse(v);
      if (d != null) return '${d.day}-${d.month}-${d.year}';
    }
    return '';
  }
}

