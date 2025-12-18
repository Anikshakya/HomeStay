// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:booking_desktop/src/view/guest_management/check_out_management.dart';
import 'package:booking_desktop/src/view/guest_management/edit_guest.dart';
import 'package:booking_desktop/src/view/guest_management/guest_card.dart';
import 'package:booking_desktop/src/view/guest_management/service_logging_dialoge.dart';
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
          'Room $roomId is not available: ${available.reason ?? 'Booked'}',
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
                            color: Colors.black.withValues(alpha:0.08),
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
    // Room inactive
    if (room['active'].toString() != '1') {
      return RoomAvailability(selectable: false, reason: 'Inactive');
    }

    // No dates selected yet → allow selection
    if (checkInDate == null || checkOutDate == null) {
      return RoomAvailability(selectable: true);
    }

    for (final b in _controller.bookingItems) {
      if (b['roomId'].toString() != room['id'].toString()) continue;

      final status = getBookingStatus(b);

      // ✅ Checked-out bookings NEVER block rooms
      if (status == GuestStatus.checkedOut) continue;

      final existingCheckIn = parseDate(b['arrivalDate']);
      final existingCheckOut = parseDate(b['checkOutDate']);

      if (existingCheckIn == null || existingCheckOut == null) continue;

      final overlap =
          existingCheckIn.isBefore(checkOutDate) &&
          existingCheckOut.isAfter(checkInDate);

      if (overlap) {
        return RoomAvailability(
          selectable: false,
          reason: status == GuestStatus.booked ? 'Booked' : 'Occupied',
          bookingStatus: status.name,
        );
      }
    }

    return RoomAvailability(selectable: true);
  }

 

GuestStatus getBookingStatus(Map<String, dynamic> booking) {
  final now = DateTime.now();
  final arrival = parseDate(booking['arrivalDate']);
  final checkout = parseDate(booking['checkOutDate']);

  if (arrival == null || checkout == null) {
    return GuestStatus.checkedIn;
  }

  if (now.isBefore(arrival)) {
    return GuestStatus.booked;
  }

  if (now.isAfter(checkout)) {
    return GuestStatus.checkedOut;
  }

  return GuestStatus.checkedIn;
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
enum GuestFilter { active, past }

enum GuestStatus { booked, checkedIn, checkedOut }

class CurrentGuestsCard extends StatefulWidget {
  const CurrentGuestsCard({super.key});

  @override
  State<CurrentGuestsCard> createState() => _CurrentGuestsCardState();
}

class _CurrentGuestsCardState extends State<CurrentGuestsCard> {
  final controller = HotelController.to;

  String search = '';
  GuestFilter _filter = GuestFilter.active;

  @override
  void initState() {
    super.initState();
    controller.loadBookingItemsForGuests();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Guests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            _searchAndFilterBar(),

            const SizedBox(height: 16),

            Obx(() {
              final items = _optimizedGuestItems();

              final filtered = items.where((e) {
                final q = search.toLowerCase();

                final matchesSearch =
                    e['name'].toString().toLowerCase().contains(q) ||
                    e['roomNumber'].toString().toLowerCase().contains(q) ||
                    e['contactNumber'].toString().toLowerCase().contains(q);

                if (!matchesSearch) return false;

                final status = getGuestStatus(e);

                if (_filter == GuestFilter.active) {
                  return status == GuestStatus.booked ||
                      status == GuestStatus.checkedIn;
                } else {
                  return status == GuestStatus.checkedOut;
                }
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No guests found'));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final item = filtered[i];
                  final status = getGuestStatus(item);

                  return GuestLogCard(
                    item: item,
                    statusLabel: getStatusLabel(status),
                    statusColor: getStatusColor(status),
                    onTap: () async {
                      final didUpdate = await showDialog(
                        context: context,
                        builder: (_) => EditGuestDialog(
                          logId: int.tryParse(item['logId']) ?? -1,
                        ),
                      );

                      if (didUpdate == true) {
                        await controller.refreshGuestData();
                      }
                    },
                    onFoodTap: () {
                      _showFoodLoggingDialog(
                        int.tryParse(item['logId']) ?? -1,
                      );
                    },
                    popupMenu: _buildPopupMenu(
                      int.tryParse(item['logId']) ?? -1,
                      item,
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // 🔍 Search + Filter Bar
  Widget _searchAndFilterBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => search = v),
            decoration: InputDecoration(
              hintText: 'Search by name, phone, room',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        _filterButton(
          label: 'Active',
          selected: _filter == GuestFilter.active,
          onTap: () => setState(() => _filter = GuestFilter.active),
        ),

        const SizedBox(width: 8),

        _filterButton(
          label: 'Past',
          selected: _filter == GuestFilter.past,
          onTap: () => setState(() => _filter = GuestFilter.past),
        ),
      ],
    );
  }

  Widget _filterButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ⚡ Optimized flattening (O(n))
  List<Map<String, dynamic>> _optimizedGuestItems() {
    final roomMap = {
      for (var r in controller.rooms) r['id'].toString(): r['number'],
    };

    final guestMap = {
      for (var g in controller.guestLogs) g['id'].toString(): g,
    };

    final List<Map<String, dynamic>> result = [];

    for (final b in controller.bookingItems) {
      final guest = guestMap[b['logId'].toString()];
      if (guest == null) continue;

      result.add({
        ...guest,
        ...b,
        'roomNumber': roomMap[b['roomId'].toString()] ?? 'Unknown',
      });
    }

    return result;
  }

  // ✅ Correct guest status logic
  static GuestStatus getGuestStatus(Map<String, dynamic> item) {
    final now = DateTime.now();
    final arrival = parseDate(item['arrivalDate']);
    final checkout = parseDate(item['checkOutDate']);

    if (arrival == null || checkout == null) {
      return GuestStatus.checkedIn;
    }

    if (now.isBefore(arrival)) {
      return GuestStatus.booked;
    }

    if (now.isAfter(checkout)) {
      return GuestStatus.checkedOut;
    }

    return GuestStatus.checkedIn;
  }

  static String getStatusLabel(GuestStatus status) {
    switch (status) {
      case GuestStatus.booked:
        return 'Booked';
      case GuestStatus.checkedIn:
        return 'Checked-in';
      case GuestStatus.checkedOut:
        return 'Checked-out';
    }
  }

  static Color getStatusColor(GuestStatus status) {
    switch (status) {
      case GuestStatus.booked:
        return Colors.orange;
      case GuestStatus.checkedIn:
        return Colors.green;
      case GuestStatus.checkedOut:
        return Colors.red;
    }
  }

  static DateTime? parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  void _showFoodLoggingDialog(int logId) {
    showDialog(
      context: context,
      builder: (_) => ServiceLoggingDialog(logId: logId),
    );
  }

  Widget _buildPopupMenu(int id, Map<String, dynamic> log) {
    final controller = HotelController.to;
    final status = getGuestStatus(log);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'calculate_bill':
            final didUpdate = await showDialog(
              context: context,
              builder: (_) => CalculateBillDialog(logId: id),
            );
            if (didUpdate == true) {
              await controller.refreshGuestData();
            }
            break;

          case 'delete':
            await controller.deleteGuestLog(id);
            await controller.refreshGuestData();
            break;
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'calculate_bill',
          child: Text('Calculate Bill'),
        ),
        if (status != GuestStatus.checkedOut)
          const PopupMenuItem(
            value: 'checkout',
            child: Text('Update Check Out'),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Text(
            'Delete',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}



class AddServiceDialog extends StatefulWidget {
  final int logId;

  const AddServiceDialog({super.key, required this.logId});

  @override
  State<AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<AddServiceDialog> {
  final controller = HotelController.to;

  Map<int, int> selected = {}; // serviceId -> qty

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Services'),
      content: SizedBox(
        width: 420,
        child: Obx(() {
          return ListView.separated(
            shrinkWrap: true,
            itemCount: controller.services.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) {
              final s = controller.services[i];
              final id = s['id'];
              final qty = selected[id] ?? 0;

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('Rs ${s['price']}'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed:
                        qty > 0
                            ? () => setState(() => selected[id] = qty - 1)
                            : null,
                  ),
                  Text(qty.toString()),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() => selected[id] = qty + 1);
                    },
                  ),
                ],
              );
            },
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Add')),
      ],
    );
  }

  Future<void> _save() async {
    final entries = selected.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) return;

    // for (final e in entries) {
    //   await controller.repo.insertGuestServiceUsage({
    //     'logId': widget.logId,
    //     'serviceId': e.key,
    //     'qty': e.value,
    //   });
    // }

    await controller.refreshGuestData();
    Navigator.pop(context);
  }
}

