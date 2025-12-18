import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:image_picker/image_picker.dart';

class EditGuestDialog extends StatefulWidget {
  final int logId;

  const EditGuestDialog({super.key, required this.logId});

  @override
  State<EditGuestDialog> createState() => _EditGuestDialogState();
}

class _EditGuestDialogState extends State<EditGuestDialog> {
  final controller = HotelController.to;

  final _nameC = TextEditingController();
  final _contactC = TextEditingController();
  final _addressC = TextEditingController();
  final _occupationC = TextEditingController();
  final _relationC = TextEditingController();
  final _reasonC = TextEditingController();
  final _discountC = TextEditingController();
  final _extraChargeC = TextEditingController();
  final _chargeReasonC = TextEditingController();
  final _guestCount = TextEditingController(text: "1");

  File? _citizenImage;
  bool _loading = true;

  final RxList<RxMap<String, dynamic>> _roomSelections =
      <RxMap<String, dynamic>>[].obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGuestData();
    });
  }

  TimeOfDay? parseTime(String? t) {
    if (t == null || t.isEmpty) return null;

    // Expect format like "2:16 PM"
    final regex = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    );
    final match = regex.firstMatch(t.trim());
    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    final String period = match.group(3)!.toUpperCase();

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }


  RxMap<String, dynamic> _createRoomSelectionFromBooking([
    Map<String, dynamic>? bookingItem,
  ]) {
    if (bookingItem != null) {
      return RxMap<String, dynamic>({
        'roomId': bookingItem['roomId']?.toString() ?? '',
        'checkInDate':
            bookingItem['arrivalDate'] != null
                ? DateTime.tryParse(bookingItem['arrivalDate'])
                : null,
        'checkInTime': parseTime(bookingItem['checkInTime']),
        'checkOutDate':
            bookingItem['checkOutDate'],
        'checkOutTime': parseTime(bookingItem['checkOutTime']),
        'discount': bookingItem['discount'] ?? 0,
      });
    }

    return RxMap<String, dynamic>({
      'roomId': '',
      'checkInDate': null,
      'checkInTime': null,
      'checkOutDate': null,
      'checkOutTime': null,
      'discount': 0,
    });
  }

  Future<void> _loadGuestData() async {
    final log = controller.guestLogs.firstWhere(
      (g) => g['id'].toString() == widget.logId.toString(),
      orElse: () => {},
    );

    if (log.isEmpty) {
      Get.snackbar('Error', 'Guest not found');
      Navigator.pop(context);
      return;
    }

    // Pre-fill guest info
    _nameC.text = log['name'] ?? '';
    _contactC.text = log['contactNumber'] ?? '';
    _addressC.text = log['address'] ?? '';
    _occupationC.text = log['occupation'] ?? '';
    _relationC.text = log['relationWithPartner'] ?? '';
    _reasonC.text = log['reasonOfStay'] ?? '';
    _discountC.text = (log['overallDiscountRs'] ?? 0).toString();
    _extraChargeC.text = (log['extraChargesRs'] ?? 0).toString();
    _chargeReasonC.text = log['chargeReason'] ?? '';
    _guestCount.text = (log['numberOfGuests'] ?? 1).toString();

    // Pre-fill room selections
    final bookingItems =
        controller.bookingItems
            .where((b) => b['logId'].toString() == widget.logId.toString())
            .toList();
    if (bookingItems.isNotEmpty) {
      _roomSelections.value =
          bookingItems.map((b) => _createRoomSelectionFromBooking(b)).toList();
    } else {
      _roomSelections.add(_createRoomSelectionFromBooking());
    }

    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) setState(() => _citizenImage = File(picked.path));
  }

  void _addRoom() {
    _roomSelections.add(_createRoomSelectionFromBooking());
  }

  void _removeRoom(int index) {
    if (_roomSelections.length > 1) {
      _roomSelections.removeAt(index);
    } else {
      _roomSelections[0] = _createRoomSelectionFromBooking();
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
    final currentTime =
        isCheckIn
            ? _roomSelections[index]['checkInTime'] as TimeOfDay?
            : _roomSelections[index]['checkOutTime'] as TimeOfDay?;

    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      if (isCheckIn) {
        _roomSelections[index]['checkInTime'] = picked;
      } else {
        _roomSelections[index]['checkOutTime'] = picked;
      }
    }
  }

  Future<void> _save() async {
    final items =
        _roomSelections
            .where((r) => r['roomId'] != null && r['roomId'] != '')
            .map((r) {
              // Convert TimeOfDay to string if necessary
              String? formatTime(dynamic t) {
                if (t == null) return null;
                if (t is TimeOfDay) {
                  final hourStr = t.hour.toString().padLeft(2, '0');
                  final minStr = t.minute.toString().padLeft(2, '0');
                  return '$hourStr:$minStr';
                }
                if (t is String) return t;
                return null;
              }

              return {
                'roomId': r['roomId'],
                'checkInDate': r['checkInDate']?.toIso8601String(),
                'checkInTime': formatTime(r['checkInTime']),
                'checkOutDate': r['checkOutDate']?.toIso8601String(),
                'checkOutTime': formatTime(r['checkOutTime']),
                'discount': r['discount'] ?? 0,
              };
            })
            .toList();

    if (items.isEmpty) {
      Get.snackbar('Error', 'Please select at least one room');
      return;
    }

    final updatedData = {
      'name': _nameC.text,
      'contactNumber': _contactC.text,
      'address': _addressC.text,
      'occupation': _occupationC.text,
      'relationWithPartner': _relationC.text,
      'reasonOfStay': _reasonC.text,
      'numberOfGuests': int.tryParse(_guestCount.text) ?? 1,
      'overallDiscountRs': double.tryParse(_discountC.text) ?? 0,
      'extraChargesRs': double.tryParse(_extraChargeC.text) ?? 0,
      'chargeReason': _chargeReasonC.text,
      'citizenImageBlob':
          _citizenImage != null ? await _citizenImage!.readAsBytes() : null,
    };

    await controller.updateGuestLog(widget.logId, updatedData, items);

    Get.snackbar('Success', 'Guest updated');
    // ignore: use_build_context_synchronously
    Navigator.pop(context, true);
  }


  DateTime? parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.40,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
            child: _loading
                ? SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Edit Guest',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _textField('Full Name', _nameC),
                      Row(
                        children: [
                          Expanded(
                            child: _textField('Contact Number', _contactC),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: _textField('Address', _addressC)),
                        ],
                      ),
                      _textField('Occupation', _occupationC),
                      _textField('Relation With Partner', _relationC),
                      _textField('Reason Of Stay', _reasonC),
                      _textField('No. of Guests', _guestCount),
                      _textField('Overall Discount (Rs)', _discountC),
                      _textField('Extra Charges (Rs)', _extraChargeC),
                      _textField('Charge Reason', _chargeReasonC),
                      const SizedBox(height: 16),
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
                            child:
                                _citizenImage == null
                                    ? const Text('Click to upload ID')
                                    : Image.file(
                                      _citizenImage!,
                                      fit: BoxFit.cover,
                                    ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Select Rooms & Check-in/Check-out'),
                      const SizedBox(height: 8),
                      Obx(() {
                        final rooms = controller.rooms;
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                              onTap:
                                                  () => _selectDate(index, true),
                                              child: Obx(
                                                () => Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 14,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.grey.shade300,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    selection['checkInDate'] !=
                                                            null
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
                                              onTap:
                                                  () => _selectTime(index, true),
                                              child: Obx(
                                                () => Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 14,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.grey.shade300,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    selection['checkInTime'] !=
                                                            null
                                                        ? (selection['checkInTime']
                                                                as TimeOfDay)
                                                            .format(context)
                                                        : 'Check-in Time',
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
                                              onTap:
                                                  () => _selectDate(index, false),
                                              child: Obx(
                                                () => Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 14,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.grey.shade300,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    selection['checkOutDate'] !=
                                                            null
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
                                              onTap:
                                                  () => _selectTime(index, false),
                                              child: Obx(
                                                () => Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 14,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.grey.shade300,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    selection['checkOutTime'] !=
                                                            null
                                                        ? (selection['checkOutTime']
                                                                as TimeOfDay)
                                                            .format(context)
                                                        : 'Check-out Time',
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
                                            selection['roomId'] != ''
                                                ? selection['roomId']
                                                : null,
                                        hint: const Text('Select Room'),
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        items:
                                            rooms.map((r) {
                                              final availability =
                                                  _getRoomAvailability(
                                                    room: r,
                                                    checkInDate:
                                                        selection['checkInDate'],
                                                    checkOutDate:
                                                        selection['checkOutDate'],
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
                                                            availability
                                                                    .selectable
                                                                ? Colors.black
                                                                : Colors.grey,
                                                      ),
                                                    ),
                                                    if (!availability
                                                        .selectable) ...[
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        availability.reason ==
                                                                'Inactive'
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
                                          if (v != null) selection['roomId'] = v;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: discountController,
                                        decoration: InputDecoration(
                                          labelText: 'Discount (%)',
                                          prefixIcon: const Icon(
                                            Icons.local_offer,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _save,
                          child: const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _textField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  RoomAvailability _getRoomAvailability({
    required Map<String, dynamic> room,
    required DateTime? checkInDate,
    required DateTime? checkOutDate,
  }) {
    if (room['active'].toString() != '1') {
      return RoomAvailability(selectable: false, reason: 'Inactive');
    }

    if (checkInDate == null || checkOutDate == null) {
      return RoomAvailability(selectable: true);
    }

    for (final b in controller.bookingItems) {
      if (b['roomId'].toString() != room['id'].toString()) continue;
      final existingCheckIn = parseDate(b['arrivalDate']);
      final existingCheckOut = parseDate(b['checkOutDate']);
      if (existingCheckIn == null || existingCheckOut == null) continue;

      final overlap =
          existingCheckIn.isBefore(checkOutDate) &&
          existingCheckOut.isAfter(checkInDate);
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
