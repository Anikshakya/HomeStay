import 'dart:io';
import 'package:booking_desktop/src/app_config/styles.dart';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BookingDetailPage extends StatefulWidget {
  final int bookingId;
  const BookingDetailPage({super.key, required this.bookingId});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  final hc = HotelController.to;

  Map<String, dynamic>? booking;
  Map<int, int> servicesSelected = {};
  Map<String, dynamic>? user;
  Map<String, dynamic>? room;

  double recalculatedTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await hc.loadBookings();

    booking = hc.bookings.firstWhereOrNull(
      (b) => b['id'].toString() == widget.bookingId.toString(),
    );

    if (booking == null) {
      Get.back();
      return;
    }

    servicesSelected = hc
        .parseServicesString(booking!['services'] ?? "")
        .map((k, v) => MapEntry(k, v));

    user = hc.users.firstWhereOrNull((u) => u['id'] == booking!['userId']);
    room = hc.rooms.firstWhereOrNull((r) => r['id'] == booking!['roomId']);

    _recalc();
    setState(() {});
  }

  double _parsePrice(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  void _recalc() {
    double roomPrice = room != null ? _parsePrice(room!['price']) : 0.0;

    double serviceTotal = 0.0;
    servicesSelected.forEach((sid, cnt) {
      final s = hc.services.firstWhereOrNull(
        (x) => x['id'].toString() == sid.toString(),
      );
      if (s != null) {
        serviceTotal += _parsePrice(s['price']) * cnt;
      }
    });

    recalculatedTotal = roomPrice + serviceTotal;
  }

  Future<void> _toggleService(int sid, int delta) async {
    final current = servicesSelected[sid] ?? 0;
    final updated = (current + delta).clamp(0, 999);

    if (updated == 0) {
      servicesSelected.remove(sid);
    } else {
      servicesSelected[sid] = updated;
    }

    _recalc();
    setState(() {});
  }

  Future<void> _saveChanges() async {
    final servicesStr = hc.servicesMapToString(servicesSelected);

    await hc.updateBooking(int.tryParse(booking!['id'].toString()) ?? -1, {
      ...booking!,
      'services': servicesStr,
      'total': recalculatedTotal,
    });

    await hc.loadAll();
    Get.snackbar(
      'Saved',
      'Booking updated',
      snackPosition: SnackPosition.BOTTOM,
    );
    _load();
  }

  Future<void> _changeStatus(String status) async {
    await hc.updateBooking(int.tryParse(booking!['id']) ?? -1, {...booking!, 'status': status});

    await hc.loadBookings();
    _load();
  }

  Future<void> _addServiceToBookingDialog() async {
    final selected = await showDialog<int?>(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: Text('Add service'),
          children: [
            SizedBox(
              width: double.maxFinite,
              child: Obx(() {
                final list =
                    hc.services
                        .where((s) => s['active'].toString() == "1")
                        .toList();

                if (list.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No services'),
                  );
                }

                return Column(
                  children:
                      list.map((s) {
                        return SimpleDialogOption(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${s['name']}'),
                              Text('₨ ${s['price']}'),
                            ],
                          ),
                          onPressed:
                              () => Navigator.of(
                                context,
                              ).pop(int.tryParse(s['id']) ?? -1),
                        );
                      }).toList(),
                );
              }),
            ),
          ],
        );
      },
    );

    if (selected != null) {
      servicesSelected[selected] = (servicesSelected[selected] ?? 0) + 1;
      _recalc();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (booking == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Booking Details • #${booking!['id']}')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            _checkInOut(),
            SizedBox(height: 16),
            _userSection(),
            SizedBox(height: 16),
            _roomSection(),
            SizedBox(height: 16),
            _serviceSection(),
            SizedBox(height: 16),
            _billingSection(),
            SizedBox(height: 16),
            _statusSection(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // USER SECTION
  // ---------------------------------------------------------------
  Widget _userSection() {
    return _sectionCard(
      title: "Guest Information",
      child: Row(
        children: [
          _userImage(),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow("Name", user?['name']),
                _infoRow("Phone", user?['phone']),
                _infoRow("Email", user?['email']),
                _infoRow(
                  "ID Image",
                  user?['idImagePath']?.isNotEmpty == true
                      ? "Uploaded"
                      : "Not Provided",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _userImage() {
    final path = user?['idImagePath']?.toString() ?? '';
    if (path.isNotEmpty && File(path).existsSync()) {
      return CircleAvatar(radius: 40, backgroundImage: FileImage(File(path)));
    }
    return CircleAvatar(radius: 40, child: Icon(Icons.person, size: 32));
  }

  // ---------------------------------------------------------------
  // ROOM SECTION
  // ---------------------------------------------------------------
  Widget _roomSection() {
    return _sectionCard(
      title: "Room Details",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow("Room Number", room?['number']),
          _infoRow("Room Type", room?['type']),
          _infoRow("Beds", room?['beds']),
          _infoRow("AC", room?['ac'] == "1" ? "Yes" : "No"),
          _infoRow("Price", "₨ ${room?['price']}"),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // USER SECTION
  // ---------------------------------------------------------------
  Widget _checkInOut() {
    final checkIn = _fmt(booking!['checkIn']);
    final checkOut = _fmt(booking!['checkOut']);

    return _sectionCard(
      title: "Date Information",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow("Check In: ", checkIn),
          _infoRow("Check Out: ", checkOut),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // SERVICE SECTION
  // ---------------------------------------------------------------
  Widget _serviceSection() {
    double serviceTotal = 0.0;
    servicesSelected.forEach((sid, cnt) {
      final s = hc.services.firstWhereOrNull(
        (x) => x['id'].toString() == sid.toString(),
      );
      if (s != null) {
        serviceTotal += _parsePrice(s['price']) * cnt;
      }
    });

    return _sectionCard(
      title: "Services",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _addServiceToBookingDialog,
            icon: Icon(Icons.add),
            label: Text("Add Service"),
          ),
          SizedBox(height: 12),
          if (servicesSelected.isEmpty)
            Text("No services added.")
          else
            ...servicesSelected.entries.map((entry) {
              final sid = entry.key;
              final cnt = entry.value;

              final service = hc.services.firstWhereOrNull(
                (s) => s['id'].toString() == sid.toString(),
              );

              if (service == null) return SizedBox();

              final price = _parsePrice(service['price']);
              final total = price * cnt;

              return ListTile(
                title: Text(service['name']),
                subtitle: Text("₨ $price × $cnt = ₨ $total"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () => _toggleService(sid, -1),
                    ),
                    Text(cnt.toString()),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => _toggleService(sid, 1),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        servicesSelected.remove(sid);
                        _recalc();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              );
            }),

          SizedBox(height: 10,),
          // Services Total
          _infoRow("Services Total: ", "₨ $serviceTotal"),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // BILLING SECTION
  // ---------------------------------------------------------------
  Widget _billingSection() {
    final checkIn = _fmt(booking!['checkIn']);
    final checkOut = _fmt(booking!['checkOut']);

    double roomPrice = _parsePrice(room?['price']);

    double serviceTotal = 0.0;
    servicesSelected.forEach((sid, cnt) {
      final s = hc.services.firstWhereOrNull(
        (x) => x['id'].toString() == sid.toString(),
      );
      if (s != null) {
        serviceTotal += _parsePrice(s['price']) * cnt;
      }
    });

    final total = roomPrice + serviceTotal;

    return _sectionCard(
      title: "Billing Summary",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _billingRow("Check-in Date", checkIn),
          _billingRow("Check-out Date", checkOut),
          Divider(),
          _billingRow("Room Price", "₨ $roomPrice"),
          _billingRow("Services Total", "₨ $serviceTotal"),
          Divider(thickness: 1.2),
          _billingRow("Grand Total", "₨ $total", bold: true, highlight: true),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // STATUS SECTION
  // ---------------------------------------------------------------
  Widget _statusSection() {
    return _sectionCard(
      title: "Booking Actions",
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () => _changeStatus("checked_in"),
            child: Text("Mark Checked In"),
          ),
          ElevatedButton(
            onPressed: () => _changeStatus("checked_out"),
            child: Text("Mark Checked Out"),
          ),
          ElevatedButton.icon(
            onPressed: _saveChanges,
            icon: Icon(Icons.save),
            label: Text("Save Changes"),
          ),
          ElevatedButton(
            onPressed: () async {
              await hc.deleteBooking(booking!['id']);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.delete),
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------
  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value?.toString() ?? "-")),
        ],
      ),
    );
  }

  Widget _billingRow(
    String label,
    String value, {
    bool bold = false,
    bool highlight = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: highlight ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic s) {
    if (s == null) return "-";

    final dt = DateTime.tryParse(s.toString());
    if (dt == null) return s.toString();

    return DateFormat('yyyy-MM-dd').format(dt);
  }
}
