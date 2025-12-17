import 'package:booking_desktop/src/app_database/app_db.dart';
import 'package:get/get.dart';

class HotelController extends GetxController {
  static HotelController get to => Get.find();

  final repo = DatabaseRepo();

  // =================== STATE ===================
  var rooms = <Map<String, dynamic>>[].obs;
  var services = <Map<String, dynamic>>[].obs;
  var users = <Map<String, dynamic>>[].obs;
  var bookings = <Map<String, dynamic>>[].obs;

  // Guest log (Homestay)
  var guestLogs = <Map<String, dynamic>>[].obs;
  var bookingItems = <Map<String, dynamic>>[].obs;

  var loading = false.obs;

  // =================== LIFECYCLE ===================
  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await repo.init(); // initialize connection
    await loadAll();
  }

  Future<void> loadAll() async {
    loading.value = true;
    await Future.wait([
      loadRooms(),
      loadServices(),
      loadUsers(),
      loadBookings(),
      loadGuestLogs(),
      loadBookingItemsForGuests(),
    ]);
    loading.value = false;
  }

  // ================================================================
  // ROOMS
  // ================================================================
  Future<void> loadRooms() async {
    rooms.assignAll(await repo.fetchRooms());
  }

  Future<int> addRoom(Map<String, dynamic> r) async {
    final id = await repo.insertRoom(r);
    await loadRooms();
    return id;
  }

  Future<void> updateRoom(int id, Map<String, dynamic> r) async {
    await repo.updateRoom(id, r);
    await loadRooms();
  }

  Future<void> deleteRoom(int id) async {
    await repo.deleteRoom(id);
    await loadRooms();
  }

  // ================================================================
  // SERVICES
  // ================================================================
  Future<void> loadServices() async {
    services.assignAll(await repo.fetchServices());
  }

  Future<int> addService(Map<String, dynamic> s) async {
    final id = await repo.insertService(s);
    await loadServices();
    return id;
  }

  Future<void> updateService(int id, Map<String, dynamic> s) async {
    await repo.updateService(id, s);
    await loadServices();
  }

  Future<void> deleteService(int id) async {
    await repo.deleteService(id);
    await loadServices();
  }

  // ================================================================
  // USERS
  // ================================================================
  Future<void> loadUsers() async {
    users.assignAll(await repo.fetchUsers());
  }

  Future<int> addUser(Map<String, dynamic> u) async {
    final id = await repo.insertUser(u);
    await loadUsers();
    return id;
  }

  Future<void> updateUser(int id, Map<String, dynamic> u) async {
    await repo.updateUser(id, u);
    await loadUsers();
  }

  Future<void> deleteUser(int id) async {
    await repo.deleteUser(id);
    await loadUsers();
  }

  // ================================================================
  // BOOKINGS (LEGACY)
  // ================================================================
  Future<void> loadBookings() async {
    bookings.assignAll(await repo.fetchBookings());
  }

  Future<int> addBooking(Map<String, dynamic> b) async {
    final id = await repo.insertBooking(b);
    await loadBookings();
    return id;
  }

  Future<void> updateBooking(int id, Map<String, dynamic> b) async {
    await repo.updateBooking(id, b);
    await loadBookings();
  }

  Future<void> deleteBooking(int id) async {
    await repo.deleteBooking(id);
    await loadBookings();
  }

  // ================================================================
  // GUEST LOG (HOMESTAY)
  // ================================================================
  Future<void> loadGuestLogs() async {
    guestLogs.assignAll(await repo.fetchGuestLogs());
  }

  // ================================================================
  // GUEST LOG + BOOKING ITEMS
  // ================================================================
  Future<int> addGuestLog(
    Map<String, dynamic> guest,
    List<Map<String, dynamic>> items,
  ) async {
    final logId = await repo.insertGuestLog(
      guest,
      items,
    ); // already inserts items
    await refreshGuestData();
    return logId;
  }


  Future<void> updateGuestLog(
    int logId,
    Map<String, dynamic> guest,
    List<Map<String, dynamic>> items,
  ) async {
    // Update guest info
    await repo.updateGuestLog(logId, guest, items);

    // Update or insert booking items
    for (final item in items) {
      if (item.containsKey('roomId') && item['roomId'] != null) {
        // Update existing booking item
        await repo.updateBookingItem(logId, item);
      }
    }

    await refreshGuestData();
  }

  /// Load all booking items and parse DateTime fields
  Future<void> loadBookingItemsForGuests() async {
    final items = await repo.fetchAllBookingItems();
    bookingItems.assignAll(
      items.map((b) {
        return {
          ...b,
          'checkInDate':
              b['checkInDate'] != null
                  ? DateTime.parse(b['checkInDate']).toLocal()
                  : null,
          'checkOutDate':
              b['checkOutDate'] != null
                  ? DateTime.parse(b['checkOutDate']).toLocal()
                  : null,
        };
      }).toList(),
    );
  }

  /// Update a specific booking item
  Future<void> updateBookingItem(int itemId, Map<String, dynamic> data) async {
    await repo.updateBookingItem(itemId, {
      ...data,
      'checkInDate': data['checkInDate']?.toUtc().toIso8601String(),
      'checkOutDate': data['checkOutDate']?.toUtc().toIso8601String(),
    });
    await loadBookingItemsForGuests();
  }

  deleteGuestLog(int id) async{
    await repo.deleteGuestLogWithAssociations(id);
  }

  // ================================================================
  // 🔥 SAFE ADDITION (USED BY LOG DETAIL PAGE)
  // ================================================================
  Future<void> refreshGuestData() async {
    await loadGuestLogs();
    await loadBookingItemsForGuests();
  }

  // ================================================================
  // HELPERS (UNCHANGED)
  // ================================================================
  List<Map<String, dynamic>> availableRoomsForRange(
    DateTime inDate,
    DateTime outDate,
  ) {
    final taken = <int>{};

    for (final b in bookings) {
      if (b['status'] == 'checked_out') continue;
      final bIn = DateTime.parse(b['checkIn']!);
      final bOut = DateTime.parse(b['checkOut']!);

      final overlap = !(outDate.isBefore(bIn) || inDate.isAfter(bOut));
      if (overlap) taken.add(int.parse(b['roomId']!));
    }

    return rooms
        .where(
          (r) => !taken.contains(int.parse(r['id']!)) && r['active'] == '1',
        )
        .toList();
  }

  int activeUsersCount() => users.length;
  int activeRoomsCount() => rooms.where((r) => r['active'] == '1').length;
  int activeServicesCount() => services.where((s) => s['active'] == '1').length;

  Map<int, int> parseServicesString(String? s) {
    final Map<int, int> result = {};
    if (s == null || s.isEmpty) return result;

    for (final part in s.split(';')) {
      final kv = part.split(':');
      final id = int.tryParse(kv[0]) ?? -1;
      final qty = kv.length > 1 ? int.tryParse(kv[1]) ?? 1 : 1;
      if (id > 0) result[id] = qty;
    }
    return result;
  }

  String servicesMapToString(Map<int, int> m) =>
      m.entries.map((e) => '${e.key}:${e.value}').join(';');

  List<Map<String, dynamic>> bookingsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return bookings.where((b) {
      final inDt = DateTime.parse(b['checkIn']!);
      final outDt = DateTime.parse(b['checkOut']!);
      return !(outDt.isBefore(start) || inDt.isAfter(end));
    }).toList();
  }
}
