import 'dart:io';

import 'package:booking_desktop/src/app_config/styles.dart';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:booking_desktop/src/view/others/edit_user_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AddBookingPage extends StatefulWidget {
  const AddBookingPage({super.key});

  @override
  State<AddBookingPage> createState() => _AddBookingPageState();
}

class _AddBookingPageState extends State<AddBookingPage> {
  final hc = HotelController.to;
  int step = 0;
  Map<String, dynamic>? selectedUser;
  Map<String, dynamic>? selectedRoom;
  DateTime checkIn = DateTime.now();
  DateTime checkOut = DateTime.now().add(Duration(days: 1));
  Map<int, int> chosenServices = {};
  double total = 0.0;
  final userSearchC = TextEditingController();
  @override
  void dispose() {
    userSearchC.dispose();
    super.dispose();
  }

  void recalcTotal() {
    double roomPrice =
        selectedRoom != null ? (double.tryParse(selectedRoom!['price']) ?? 0.0) : 0.0;
    double servicesPrice = 0.0;
    chosenServices.forEach((sid, cnt) {
      final s = hc.services.firstWhereOrNull((x) => x['id'] == sid);
      if (s != null) servicesPrice += ((s['price'] ?? 0.0) as double) * cnt;
    });
    total = roomPrice + servicesPrice;
    setState(() {});
  }

  Future<void> pickDate(BuildContext ctx, bool isIn) async {
    final res = await showDatePicker(
      context: ctx,
      initialDate: isIn ? checkIn : checkOut,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
    );
    if (res != null) {
      setState(() {
        if (isIn) {
          checkIn = DateTime(res.year, res.month, res.day);
        } else {
          checkOut = DateTime(res.year, res.month, res.day);
        }
        recalcTotal();
      });
    }
  }

  Future<void> createBooking() async {
    if (selectedUser == null) {
      Get.snackbar(
        'Error',
        'Select or create a user',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (selectedRoom == null) {
      Get.snackbar(
        'Error',
        'Select a room',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (checkOut.isBefore(checkIn) || checkOut.isAtSameMomentAs(checkIn)) {
      Get.snackbar(
        'Error',
        'Invalid dates',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final servicesString = hc.servicesMapToString(chosenServices);
    final booking = {
      'userId': selectedUser!['id'],
      'roomId': selectedRoom!['id'],
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'services': servicesString,
      'total': total,
      'status': 'booked',
      'createdAt': DateTime.now().toIso8601String(),
    };
    await hc.addBooking(booking);
    Get.snackbar(
      'Saved',
      'Booking created',
      snackPosition: SnackPosition.BOTTOM,
    );
    // reset
    selectedRoom = null;
    selectedUser = null;
    chosenServices.clear();
    total = 0;
    setState(() {
      step = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book a Room')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Stepper(
              currentStep: step,
              onStepContinue: () {
                if (step == 0) {
                  if (selectedUser == null) {
                    Get.snackbar('Error', 'Choose or add user');
                    return;
                  }
                } else if (step == 1) {
                  if (selectedRoom == null) {
                    Get.snackbar('Error', 'Choose a room');
                    return;
                  }
                } else if (step == 2) {
                  // ok
                }
                if (step < 3) {
                  setState(() => step++);
                } else {
                  createBooking();
                }
              },
              onStepCancel: () {
                if (step > 0) setState(() => step--);
              },
              steps: [
                Step(
                  title: Text('User'),
                  content: _userStep(),
                  isActive: step >= 0,
                ),
                Step(
                  title: Text('Room'),
                  content: _roomStep(),
                  isActive: step >= 1,
                ),
                Step(
                  title: Text('Services & Dates'),
                  content: _servicesStep(),
                  isActive: step >= 2,
                ),
                Step(
                  title: Text('Confirm'),
                  content: _confirmStep(),
                  isActive: step >= 3,
                ),
              ],
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _userStep() {
    return Column(
      children: [
        TextFormField(
          controller: userSearchC,
          decoration: InputDecoration(
            labelText: 'Search guest by name or phone',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 8),
        Obx(() {
          final query = userSearchC.text.trim().toLowerCase();
          final list =
              query.isEmpty
                  ? hc.users
                  : hc.users
                      .where(
                        (u) =>
                            (u['name'] ?? '').toString().toLowerCase().contains(
                              query,
                            ) ||
                            (u['phone'] ?? '').toString().contains(query),
                      )
                      .toList();
          if (list.isEmpty) {
            return Column(
              children: [
                Text('No guests'),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Get.to(() => UserEditPage()),
                  icon: Icon(Icons.add),
                  label: Text('Add guest'),
                ),
              ],
            );
          }
          return Column(
            children:
                list
                    .map(
                      (u) => Card(
                        child: ListTile(
                          leading:
                              u['idImagePath'] != null &&
                                      (u['idImagePath'] as String).isNotEmpty
                                  ? CircleAvatar(
                                    backgroundImage: FileImage(
                                      File(u['idImagePath']),
                                    ),
                                  )
                                  : CircleAvatar(child: Icon(Icons.person)),
                          title: Text(u['name'] ?? ''),
                          subtitle: Text(u['phone'] ?? ''),
                          trailing:
                              selectedUser != null &&
                                      selectedUser!['id'] == u['id']
                                  ? Icon(
                                    Icons.check,
                                    color: AppColors.checkedIn,
                                  )
                                  : null,
                          onTap: () {
                            setState(() => selectedUser = u);
                          },
                        ),
                      ),
                    )
                    .toList(),
          );
        }),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => Get.to(() => UserEditPage()),
          icon: Icon(Icons.add),
          label: Text('Create new guest'),
        ),
      ],
    );
  }

  Widget _roomStep() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Check-in: ${DateFormat('yyyy-MM-dd').format(checkIn)}',
              ),
            ),
            TextButton(
              onPressed: () => pickDate(context, true),
              child: Text('Pick'),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Check-out: ${DateFormat('yyyy-MM-dd').format(checkOut)}',
              ),
            ),
            TextButton(
              onPressed: () => pickDate(context, false),
              child: Text('Pick'),
            ),
          ],
        ),
        SizedBox(height: 8),
        Obx(() {
          final allActive = hc.rooms.where((r) => r['active'].toString() == 1.toString()).toList();
          if (allActive.isEmpty) return Text('No rooms');
          return Column(
            children:
                allActive.map((r) {
                  String roomStatus = 'Available';
                  for (final b in hc.bookings) {
                    if (b['roomId'] != r['id']) continue;
                    if (b['status'] == 'checked_out') continue;
                    final bIn = DateTime.parse(b['checkIn']);
                    final bOut = DateTime.parse(b['checkOut']);
                    final overlap =
                        !(checkOut.isBefore(bIn) || checkIn.isAfter(bOut));
                    if (overlap) {
                      roomStatus =
                          b['status'] == 'booked' ? 'Booked' : 'Checked In';
                      break;
                    }
                  }
                  final isAvailable = roomStatus == 'Available';
                  return Card(
                    color: isAvailable ? null : AppColors.inactiveBg,
                    child: ListTile(
                      title: Text('Room ${r['number']} — ${r['type']}'),
                      subtitle: Text(
                        '₨ ${r['price']} • Beds: ${r['beds']} • Status: $roomStatus',
                      ),
                      trailing:
                          selectedRoom != null && selectedRoom!['id'] == r['id']
                              ? Icon(Icons.check, color: AppColors.checkedIn)
                              : null,
                      onTap:
                          isAvailable
                              ? () {
                                setState(() {
                                  selectedRoom = r;
                                  recalcTotal();
                                });
                              }
                              : null,
                    ),
                  );
                }).toList(),
          );
        }),
      ],
    );
  }

  Widget _servicesStep() {
    return Column(
      children: [
        Obx(() {
          final active = hc.services.where((s) => s['active'].toString() == 1.toString()).toList();
          if (active.isEmpty) return Text('No active services');
          return Column(
            children:
                active.map((s) {
                  final sid = int.tryParse(s['id']) ?? -1;
                  final cnt = chosenServices[sid] ?? 0;
                  return Card(
                    child: ListTile(
                      title: Text('${s['name']}'),
                      subtitle: Text('₨ ${s['price']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (cnt > 0) {
                                chosenServices[sid] = cnt - 1;
                                if (chosenServices[sid] == 0) {
                                  chosenServices.remove(sid);
                                }
                                recalcTotal();
                                setState(() {});
                              }
                            },
                          ),
                          Text(cnt.toString()),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline),
                            onPressed: () {
                              chosenServices[sid] = cnt + 1;
                              recalcTotal();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          );
        }),
      ],
    );
  }

  Widget _confirmStep() {
    recalcTotal();
    return Column(
      children: [
        ListTile(
          title: Text('Guest'),
          subtitle: Text(selectedUser?['name'] ?? '-'),
        ),
        ListTile(
          title: Text('Room'),
          subtitle: Text(
            selectedRoom != null ? 'Room ${selectedRoom!['number']}' : '-',
          ),
        ),
        ListTile(
          title: Text('Dates'),
          subtitle: Text(
            '${DateFormat.yMd().format(checkIn)} → ${DateFormat.yMd().format(checkOut)}',
          ),
        ),
        ListTile(
          title: Text('Services'),
          subtitle: Text(
            chosenServices.entries
                .map((e) {
                  final s = hc.services.firstWhereOrNull(
                    (x) => x['id'] == e.key,
                  );
                  return '${s?['name'] ?? ''} x${e.value}';
                })
                .join(', '),
          ),
        ),
        ListTile(
          title: Text('Total'),
          subtitle: Text('₨ ${total.toStringAsFixed(0)}'),
        ),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: createBooking,
          icon: Icon(Icons.check),
          label: Text('Confirm Booking'),
        ),
      ],
    );
  }
}
