import 'package:booking_desktop/src/app_database/app_db.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:booking_desktop/src/controllers/hotel_controller.dart';

class ServiceLoggingDialog extends StatefulWidget {
  final int logId; // Guest log ID
  const ServiceLoggingDialog({super.key, required this.logId});

  @override
  State<ServiceLoggingDialog> createState() => _ServiceLoggingDialogState();
}

class _ServiceLoggingDialogState extends State<ServiceLoggingDialog> {
  final _controller = HotelController.to;
  final _db = DatabaseRepo();

  List<Map<String, dynamic>> _services = [];
  Map<int, int> _selectedQuantities = {}; // serviceId -> quantity
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _loading = true);

    await _db.init();
    final services = await _db.fetchServices();
    final consumed = await _db.fetchServiceConsumptionSummary(widget.logId);

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

  void _updateQuantity(int serviceId, int value) {
    setState(() {
      final current = _selectedQuantities[serviceId] ?? 0;
      final updated = current + value;
      if (updated <= 0) {
        _selectedQuantities.remove(serviceId);
      } else {
        _selectedQuantities[serviceId] = updated;
      }
    });
  }

  double _calculateTotalPrice() {
    double total = 0;
    for (final service in _services) {
      final serviceId = int.tryParse(service['id'] ?? '') ?? -1;
      final qty = _selectedQuantities[serviceId] ?? 0;
      if (qty > 0) {
        // parse as double
        final price = double.tryParse(service['price']?.toString() ?? '0') ?? 0;
        total += price * qty;
      }
    }
    return total;
  }


  int _calculateTotalQuantity() {
    return _selectedQuantities.values.fold(0, (a, b) => a + b);
  }

  Future<void> _saveConsumption() async {
    final items = <Map<String, dynamic>>[];

    final logExists = await _db.fetchGuestLogById(widget.logId);
    if (logExists.isEmpty) {
      Get.snackbar('Error', 'Guest log does not exist.');
      return;
    }

    for (final service in _services) {
      final id = int.tryParse(service['id'] ?? '') ?? -1;
      final qty = _selectedQuantities[id] ?? 0;
      if (qty > 0) {
        items.add({
          'logId': widget.logId,
          'serviceId': id,
          'quantity': qty,
          'pricePerUnit': service['price'],
        });
      }
    }

    await _db.deleteGuestServiceConsumptionByLog(widget.logId);
    if (items.isNotEmpty) await _db.bulkInsertGuestServiceConsumption(items);

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Guest Services'),
      content:
          _loading
              ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
              : SizedBox(
                width: 400,
                height: 400,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          final serviceId =
                              int.tryParse(service['id'] ?? '') ?? -1;
                          final quantity = _selectedQuantities[serviceId] ?? 0;
                          final isActive = service['active'] == '1';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(service['name']),
                              subtitle: Text(
                                'Price: ${service['price']}' +
                                    (isActive ? '' : ' (Inactive)'),
                              ),
                              trailing: SizedBox(
                                width: 140,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed:
                                          isActive
                                              ? () =>
                                                  _updateQuantity(serviceId, -1)
                                              : null,
                                    ),
                                    Text(quantity.toString()),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed:
                                          isActive
                                              ? () =>
                                                  _updateQuantity(serviceId, 1)
                                              : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Quantity: ${_calculateTotalQuantity()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Total Price: ${_calculateTotalPrice()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _saveConsumption, child: const Text('Save')),
      ],
    );
  }
}
