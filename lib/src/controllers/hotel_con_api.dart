import 'dart:convert';
import 'package:get/get.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

class HotelControllerAPI extends GetxController {
  static HotelControllerAPI get to => Get.find();
  var rooms = <Map<String, dynamic>>[].obs;
  var services = <Map<String, dynamic>>[].obs;
  var users = <Map<String, dynamic>>[].obs;
  var bookings = <Map<String, dynamic>>[].obs;
  var loading = false.obs;

  final String baseUrl =
      'http://localhost/hotel_app/'; // Adjust if needed (e.g., http://localhost:80/hotel_api/)

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    loading.value = true;
    await Future.wait([
      loadRooms(),
      loadServices(),
      loadUsers(),
      loadBookings(),
    ]);
    loading.value = false;
  }

  // Rooms
  Future<void> loadRooms() async {
    final response = await http.get(Uri.parse('${baseUrl}room.php'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      rooms.assignAll(data.map((e) => Map<String, dynamic>.from(e)).toList());
    } else {
      Get.snackbar('Error', 'Failed to load rooms');
    }
  }

  Future<int> addRoom(Map<String, dynamic> r) async {
    final response = await http.post(
      Uri.parse('${baseUrl}room.php'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(r),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await loadRooms();
      return data['id'];
    } else {
      Get.snackbar('Error', 'Failed to add room');
      return -1;
    }
  }

  Future<void> updateRoom(int id, Map<String, dynamic> r) async {
    final updateData = {...r, 'id': id};
    final response = await http.put(
      Uri.parse('${baseUrl}room.php'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(updateData),
    );
    if (response.statusCode == 200) {
      await loadRooms();
    } else {
      Get.snackbar('Error', 'Failed to update room');
    }
  }

  Future<void> deleteRoom(int id) async {
    final response = await http.delete(
      Uri.parse('${baseUrl}room.php'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({'id': id}),
    );
    if (response.statusCode == 200) {
      await loadRooms();
    } else {
      Get.snackbar('Error', 'Failed to delete room');
    }
  }

  // Services
  Future<void> loadServices() async {
    final response = await http.get(Uri.parse('${baseUrl}services.php'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      services.assignAll(
        data.map((e) => Map<String, dynamic>.from(e)).toList(),
      );
    } else {
      Get.snackbar('Error', 'Failed to load services');
    }
  }

  Future<int> addService(Map<String, dynamic> s) async {
    final response = await http.post(
      Uri.parse('${baseUrl}services.php'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(s),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await loadServices();
      return data['id'];
    } else {
      Get.snackbar('Error', 'Failed to add service');
      return -1;
    }
  }

  Future<void> updateService(int id, Map<String, dynamic> s) async {
    final updateData = {...s, 'id': id};
    final response = await http.put(
      Uri.parse('${baseUrl}services.php'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(updateData),
    );
    if (response.statusCode == 200) {
      await loadServices();
    } else {
      Get.snackbar('Error', 'Failed to update service');
    }
  }

  Future<void> deleteService(int id) async {
    final response = await http.delete(
      Uri.parse('${baseUrl}services.php'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({'id': id}),
    );
    if (response.statusCode == 200) {
      await loadServices();
    } else {
      Get.snackbar('Error', 'Failed to delete service');
    }
  }

  // Users
  Future<void> loadUsers() async {
    final response = await http.get(Uri.parse('${baseUrl}users.php'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      users.assignAll(data.map((e) => Map<String, dynamic>.from(e)).toList());
    } else {
      Get.snackbar('Error', 'Failed to load users');
    }
  }

  Future<int> addUser(Map<String, dynamic> u) async {
    final response = await http.post(
      Uri.parse('${baseUrl}users.php'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(u),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await loadUsers();
      return data['id'];
    } else {
      Get.snackbar('Error', 'Failed to add user');
      return -1;
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> u) async {
    final updateData = {...u, 'id': id};
    final response = await http.put(
      Uri.parse('${baseUrl}users.php'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(updateData),
    );
    if (response.statusCode == 200) {
      await loadUsers();
    } else {
      Get.snackbar('Error', 'Failed to update user');
    }
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('${baseUrl}users.php'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({'id': id}),
    );
    if (response.statusCode == 200) {
      await loadUsers();
    } else {
      Get.snackbar('Error', 'Failed to delete user');
    }
  }

  // Bookings
  Future<void> loadBookings() async {
    final response = await http.get(Uri.parse('${baseUrl}bookings.php'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      bookings.assignAll(
        data.map((e) => Map<String, dynamic>.from(e)).toList(),
      );
    } else {
      Get.snackbar('Error', 'Failed to load bookings');
    }
  }

  Future<int> addBooking(Map<String, dynamic> b) async {
    final response = await http.post(
      Uri.parse('${baseUrl}bookings.php'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(b),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await loadBookings();
      return data['id'];
    } else {
      Get.snackbar('Error', 'Failed to add booking');
      return -1;
    }
  }

  Future<void> updateBooking(int id, Map<String, dynamic> b) async {
    final updateData = {...b, 'id': id};
    final response = await http.put(
      Uri.parse('${baseUrl}bookings.php'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(updateData),
    );
    if (response.statusCode == 200) {
      await loadBookings();
    } else {
      Get.snackbar('Error', 'Failed to update booking');
    }
  }

  Future<void> deleteBooking(int id) async {
    final response = await http.delete(
      Uri.parse('${baseUrl}bookings.php'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({'id': id}),
    );
    if (response.statusCode == 200) {
      await loadBookings();
    } else {
      Get.snackbar('Error', 'Failed to delete booking');
    }
  }

  // Helpers (remain the same, as they use in-memory lists)
  List<Map<String, dynamic>> availableRoomsForRange(
    DateTime inDate,
    DateTime outDate,
  ) {
    final take = <int>{};
    for (final b in bookings) {
      if (b['status'] == 'checked_out') continue;
      final bIn = DateTime.parse(b['checkIn']);
      final bOut = DateTime.parse(b['checkOut']);
      final overlap = !(outDate.isBefore(bIn) || inDate.isAfter(bOut));
      if (overlap) take.add(b['roomId'] as int);
    }
    return rooms
        .where(
          (r) =>
              !take.contains(r['id'] as int) &&
              (r['active'].toString() == 1.toString()),
        )
        .toList();
  }

  int activeUsersCount() => users.length;
  int activeRoomsCount() =>
      rooms.where((r) => r['active'].toString() == 1.toString()).length;
  int activeServicesCount() =>
      services.where((s) => s['active'].toString() == 1.toString()).length;

  // CSV (implement fully if needed; uses in-memory data)
  Future<String> exportBookingsCsv() async {
    List<List<dynamic>> rows = [
      [
        'BookingId',
        'User',
        'Phone',
        'Room',
        'CheckIn',
        'CheckOut',
        'Services',
        'Total',
        'Status',
        'CreatedAt',
      ],
    ];
    for (var b in bookings) {
      var user = users.firstWhereOrNull((u) => u['id'] == b['userId']);
      var room = rooms.firstWhereOrNull((r) => r['id'] == b['roomId']);
      var servicesStr = b['services'] ?? '';
      rows.add([
        b['id'],
        user?['name'] ?? '',
        user?['phone'] ?? '',
        room?['number'] ?? '',
        b['checkIn'],
        b['checkOut'],
        servicesStr,
        b['total'],
        b['status'],
        b['createdAt'],
      ]);
    }
    // Build CSV string
    String csv = rows.map((row) => row.map((e) => '"$e"').join(',')).join('\n');
    return csv;
  }

  // Services string <=> map
  Map<int, int> parseServicesString(String? s) {
    final Map<int, int> result = {};
    if (s == null || s.isEmpty) return result;
    final parts = s.split(';');
    for (final pstr in parts) {
      if (pstr.trim().isEmpty) continue;
      final kv = pstr.split(':');
      if (kv.isNotEmpty) {
        final id = int.tryParse(kv[0]) ?? -1;
        final cnt = kv.length >= 2 ? int.tryParse(kv[1]) ?? 1 : 1;
        if (id > 0) result[id] = cnt;
      }
    }
    return result;
  }

  String servicesMapToString(Map<int, int> m) {
    final parts = m.entries.map((e) => '${e.key}:${e.value}').toList();
    return parts.join(';');
  }

  List<Map<String, dynamic>> bookingsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(Duration(days: 1)).subtract(Duration(seconds: 1));
    return bookings.where((b) {
      final inDt = DateTime.parse(b['checkIn']);
      final outDt = DateTime.parse(b['checkOut']);
      return !(outDt.isBefore(start) || inDt.isAfter(end));
    }).toList();
  }
}
