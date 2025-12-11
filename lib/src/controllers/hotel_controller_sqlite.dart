// import 'dart:async';
// import 'dart:io';
// import 'package:csv/csv.dart';
// import 'package:get/get.dart';
// import 'package:syuseiclub/src/database/db.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;

// class HotelController extends GetxController {
//   static HotelController get to => Get.find();
//   var rooms = <Map<String, dynamic>>[].obs;
//   var services = <Map<String, dynamic>>[].obs;
//   var users = <Map<String, dynamic>>[].obs;
//   var bookings = <Map<String, dynamic>>[].obs;
//   var loading = false.obs;
//   @override
//   void onInit() {
//     super.onInit();
//     loadAll();
//   }

//   Future<void> loadAll() async {
//     loading.value = true;
//     await Future.wait([
//       loadRooms(),
//       loadServices(),
//       loadUsers(),
//       loadBookings(),
//     ]);
//     loading.value = false;
//   }

//   // Rooms
//   Future<void> loadRooms() async {
//     final res = await DB.query('SELECT * FROM rooms ORDER BY id DESC');
//     rooms.assignAll(res);
//   }

//   Future<int> addRoom(Map<String, dynamic> r) async {
//     int id = await DB.insert('rooms', r);
//     await loadRooms();
//     return id;
//   }

//   Future<void> updateRoom(int id, Map<String, dynamic> r) async {
//     await DB.update('rooms', r, where: 'id = ?', whereArgs: [id]);
//     await loadRooms();
//   }

//   Future<void> deleteRoom(int id) async {
//     await DB.delete('rooms', where: 'id = ?', whereArgs: [id]);
//     await loadRooms();
//   }

//   // Services
//   Future<void> loadServices() async {
//     final res = await DB.query('SELECT * FROM services ORDER BY id DESC');
//     services.assignAll(res);
//   }

//   Future<int> addService(Map<String, dynamic> s) async {
//     int id = await DB.insert('services', s);
//     await loadServices();
//     return id;
//   }

//   Future<void> updateService(int id, Map<String, dynamic> s) async {
//     await DB.update('services', s, where: 'id = ?', whereArgs: [id]);
//     await loadServices();
//   }

//   Future<void> deleteService(int id) async {
//     await DB.delete('services', where: 'id = ?', whereArgs: [id]);
//     await loadServices();
//   }

//   // Users
//   Future<void> loadUsers() async {
//     final res = await DB.query('SELECT * FROM users ORDER BY id DESC');
//     users.assignAll(res);
//   }

//   Future<int> addUser(Map<String, dynamic> u) async {
//     int id = await DB.insert('users', u);
//     await loadUsers();
//     return id;
//   }

//   Future<void> updateUser(int id, Map<String, dynamic> u) async {
//     await DB.update('users', u, where: 'id = ?', whereArgs: [id]);
//     await loadUsers();
//   }

//   Future<void> deleteUser(int id) async {
//     await DB.delete('users', where: 'id = ?', whereArgs: [id]);
//     await loadUsers();
//   }

//   // Bookings
//   Future<void> loadBookings() async {
//     final res = await DB.query('SELECT * FROM bookings ORDER BY id DESC');
//     bookings.assignAll(res);
//   }

//   Future<int> addBooking(Map<String, dynamic> b) async {
//     int id = await DB.insert('bookings', b);
//     await loadBookings();
//     return id;
//   }

//   Future<void> updateBooking(int id, Map<String, dynamic> b) async {
//     await DB.update('bookings', b, where: 'id = ?', whereArgs: [id]);
//     await loadBookings();
//   }

//   Future<void> deleteBooking(int id) async {
//     await DB.delete('bookings', where: 'id = ?', whereArgs: [id]);
//     await loadBookings();
//   }

//   // Helpers
//   List<Map<String, dynamic>> availableRoomsForRange(
//     DateTime inDate,
//     DateTime outDate,
//   ) {
//     final take = <int>{};
//     for (final b in bookings) {
//       if (b['status'] == 'checked_out') continue;
//       final bIn = DateTime.parse(b['checkIn']);
//       final bOut = DateTime.parse(b['checkOut']);
//       final overlap = !(outDate.isBefore(bIn) || inDate.isAfter(bOut));
//       if (overlap) take.add(b['roomId'] as int);
//     }
//     return rooms
//         .where((r) => !take.contains(r['id'] as int) && (r['active'] == 1))
//         .toList();
//   }

//   int activeUsersCount() => users.length;
//   int activeRoomsCount() => rooms.where((r) => r['active'] == 1).length;
//   int activeServicesCount() => services.where((s) => s['active'] == 1).length;
//   // CSV
//   Future<String> exportBookingsCsv() async {
//     List<List<dynamic>> rows = [
//       [
//         'BookingId',
//         'User',
//         'Phone',
//         'Room',
//         'CheckIn',
//         'CheckOut',
//         'Services',
//         'Total',
//         'Status',
//         'CreatedAt',
//       ],
//     ];
//     for (final b in bookings) {
//       final u = users.firstWhereOrNull((x) => x['id'] == b['userId']);
//       final r = rooms.firstWhereOrNull((x) => x['id'] == b['roomId']);
//       rows.add([
//         b['id'],
//         u != null ? u['name'] ?? '' : '',
//         u != null ? u['phone'] ?? '' : '',
//         r != null ? r['number'] ?? '' : '',
//         b['checkIn'] ?? '',
//         b['checkOut'] ?? '',
//         b['services'] ?? '',
//         b['total'] ?? '',
//         b['status'] ?? '',
//         b['createdAt'] ?? '',
//       ]);
//     }
//     final csv = const ListToCsvConverter().convert(rows);
//     final dir = await getApplicationDocumentsDirectory();
//     final file = File(
//       p.join(
//         dir.path,
//         'bookings_export_${DateTime.now().millisecondsSinceEpoch}.csv',
//       ),
//     );
//     await file.writeAsString(csv);
//     return file.path;
//   }

//   // Services string <=> map
//   Map<int, int> parseServicesString(String? s) {
//     final Map<int, int> result = {};
//     if (s == null || s.isEmpty) return result;
//     final parts = s.split(';');
//     for (final pstr in parts) {
//       if (pstr.trim().isEmpty) continue;
//       final kv = pstr.split(':');
//       if (kv.length >= 1) {
//         final id = int.tryParse(kv[0]) ?? -1;
//         final cnt = kv.length >= 2 ? int.tryParse(kv[1]) ?? 1 : 1;
//         if (id > 0) result[id] = cnt;
//       }
//     }
//     return result;
//   }

//   String servicesMapToString(Map<int, int> m) {
//     final parts = m.entries.map((e) => '${e.key}:${e.value}').toList();
//     return parts.join(';');
//   }

//   List<Map<String, dynamic>> bookingsForDate(DateTime date) {
//     final start = DateTime(date.year, date.month, date.day);
//     final end = start.add(Duration(days: 1)).subtract(Duration(seconds: 1));
//     return bookings.where((b) {
//       final inDt = DateTime.parse(b['checkIn']);
//       final outDt = DateTime.parse(b['checkOut']);
//       return !(outDt.isBefore(start) || inDt.isAfter(end));
//     }).toList();
//   }
// }
