import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:booking_desktop/src/app_database/app_db.dart';

class CalculateBillDialog extends StatefulWidget {
  final int logId; // Guest log ID

  const CalculateBillDialog({super.key, required this.logId});

  @override
  State<CalculateBillDialog> createState() => _CalculateBillDialogState();
}

class _CalculateBillDialogState extends State<CalculateBillDialog> {
  final _db = DatabaseRepo();

  Map<String, dynamic>? _roomDetails; // Room info with check-in/out
  List<Map<String, dynamic>> _services = [];
  Map<int, int> _selectedQuantities = {};
  bool _loading = true;

  final _discountC = TextEditingController(text: '0');
  final _additionalChargeC = TextEditingController(text: '0');
  final _additionalReasonC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBillData();
  }

  Future<void> _loadBillData() async {
    setState(() => _loading = true);
    await _db.init();

    // 1. Fetch booking items for this guest log
    final bookingItems = await _db.fetchBookingItemsByLog(widget.logId);
    if (bookingItems.isEmpty) {
      Get.snackbar('Error', 'Booking not found for this guest');
      setState(() => _loading = false);
      return;
    }

    // For simplicity, we take the first room (assuming 1 room per log)
    final firstItem = bookingItems.first;

    final roomId = firstItem['roomId'] ?? firstItem['room_id'];
    if (roomId != null) {
      final rooms = await _db.fetchRooms();
      final room = rooms.firstWhere((r) => r['id'] == roomId, orElse: () => {});
      if (room.isNotEmpty) {
        _roomDetails = {
          'roomId': room['id'],
          'roomNumber': room['number'],
          'price': room['price'],
          'type': room['type'],
          'arrivalDate':
              firstItem['arrivalDate'] ?? firstItem['checkInTime'] ?? '',
          'checkOutDate':
              firstItem['checkOutDate'] ?? firstItem['checkOutTime'] ?? '',
        };
      }
    }

    // 2. Fetch consumed services
    final consumed = await _db.fetchServiceConsumptionSummary(widget.logId);
    final services = await _db.fetchServices();

    final Map<int, int> selected = {};
    for (final item in consumed) {
      final serviceId = int.tryParse(item['serviceId']?.toString() ?? '') ?? -1;
      if (serviceId == -1) continue;

      int totalQty = 0;
      final qtyStr = item['totalQuantity']?.toString() ?? '0';
      totalQty =
          qtyStr.contains('.')
              ? (double.tryParse(qtyStr)?.toInt() ?? 0)
              : (int.tryParse(qtyStr) ?? 0);
      if (totalQty > 0) selected[serviceId] = totalQty;
    }

    setState(() {
      _services = services;
      _selectedQuantities = selected;
      _loading = false;
    });
  }

  double _calculateServiceTotal() {
    double total = 0;
    for (final service in _services) {
      final serviceId = int.tryParse(service['id']?.toString() ?? '') ?? -1;
      final qty = _selectedQuantities[serviceId] ?? 0;
      if (qty > 0) {
        final price = double.tryParse(service['price']?.toString() ?? '0') ?? 0;
        total += price * qty;
      }
    }
    return total;
  }

  double _calculateTotal() {
    final roomPrice =
        double.tryParse(_roomDetails?['price']?.toString() ?? '0') ?? 0;
    final serviceTotal = _calculateServiceTotal();
    final discount = double.tryParse(_discountC.text) ?? 0;
    final additional = double.tryParse(_additionalChargeC.text) ?? 0;
    return roomPrice + serviceTotal - discount + additional;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calculate Bill'),
      content:
          _loading
              ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
              : SizedBox(
                width: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Services Consumed
                    const Text(
                      'Room Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Room Info
                    if (_roomDetails != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Room:'),
                          Text('${_roomDetails!['roomNumber']}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Check-in:'),
                          Text('${_roomDetails!['arrivalDate']}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Check-out:'),
                          Text('${_roomDetails!['checkOutDate']}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Room Price:'),
                          Text('${_roomDetails!['price']}'),
                        ],
                      ),
                      const Divider(),
                    ],

                    // Services Consumed
                    const Text(
                      'Services Used',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          final serviceId =
                              int.tryParse(service['id']?.toString() ?? '') ??
                              -1;
                          final qty = _selectedQuantities[serviceId] ?? 0;
                          if (qty <= 0) return const SizedBox.shrink();

                          final price =
                              double.tryParse(
                                service['price']?.toString() ?? '0',
                              ) ??
                              0;
                          return ListTile(
                            title: Text(service['name']),
                            subtitle: Text('Price: $price x $qty'),
                            trailing: Text((price * qty).toStringAsFixed(2)),
                          );
                        },
                      ),
                    ),
                    const Divider(),

                    // Discount & Additional Charges
                    TextField(
                      controller: _discountC,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Discount (-)',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    TextField(
                      controller: _additionalChargeC,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Additional Charge (+)',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    TextField(
                      controller: _additionalReasonC,
                      decoration: const InputDecoration(
                        labelText: 'Reason for Additional Charge',
                      ),
                    ),

                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _calculateTotal().toStringAsFixed(2),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_roomDetails == null) {
              Get.snackbar('Error', 'No room details found');
              return;
            }

            final discount = double.tryParse(_discountC.text) ?? 0;
            final additional = double.tryParse(_additionalChargeC.text) ?? 0;
            final reason = _additionalReasonC.text;

            // Save guest bill
            await _db.saveGuestBill(
              widget.logId,
              discount: discount,
              additionalCharge: additional,
              reason: reason,
            );

            // Update guest log & booking item status
            await _db.updateGuestLogStatus(
              widget.logId,
              status: 'Checked Out',
              checkOutDate: DateTime.now().toIso8601String(),
            );

            Get.back(result: true);
          },
          child: const Text('Confirm Check Out'),
        ),
      ],
    );
  }
}
