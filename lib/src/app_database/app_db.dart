import 'package:mysql1/mysql1.dart';

class DatabaseRepo {
  late MySqlConnection _conn;

  // ================================================================
  // INIT
  // ================================================================
  Future<void> init() async {
    final settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      password: '1234',
      db: 'hotel_db',
    );

    _conn = await MySqlConnection.connect(settings);
    await _createTables();
  }

  // ================================================================
  // CREATE TABLES
  // ================================================================
  Future<void> _createTables() async {
    // ROOMS
    await _conn.query('''
      CREATE TABLE IF NOT EXISTS rooms (
        id INT AUTO_INCREMENT PRIMARY KEY,
        number VARCHAR(50),
        type VARCHAR(100),
        price DOUBLE,
        active TINYINT DEFAULT 1,
        images TEXT,
        description TEXT
      )
    ''');

    // SERVICES
    await _conn.query('''
      CREATE TABLE IF NOT EXISTS services (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(150),
        price DOUBLE,
        active TINYINT DEFAULT 1,
        category VARCHAR(50),
        description VARCHAR(200),
        images TEXT
      )
    ''');

    // USERS
    await _conn.query('''
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(150),
        phone VARCHAR(50),
        email VARCHAR(150),
        idImagePath TEXT
      )
    ''');

    // BOOKINGS
    await _conn.query('''
      CREATE TABLE IF NOT EXISTS bookings (
        id INT AUTO_INCREMENT PRIMARY KEY,
        userId INT,
        roomId INT,
        checkIn VARCHAR(50),
        checkOut VARCHAR(50),
        services TEXT,
        total DOUBLE,
        status VARCHAR(50),
        createdAt VARCHAR(100),
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (roomId) REFERENCES rooms(id) ON DELETE CASCADE
      )
    ''');

    // GUEST LOG
    await _conn.query('''
      CREATE TABLE IF NOT EXISTS guestlog (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(150),
        address VARCHAR(255),
        citizenNumber VARCHAR(100),
        occupation VARCHAR(100),
        numberOfGuests INT,
        relationWithPartner VARCHAR(100),
        reasonOfStay VARCHAR(150),
        contactNumber VARCHAR(50),
        citizenImageBlob LONGBLOB,
        citizenImageDriveLink TEXT,
        overallDiscountRs DOUBLE DEFAULT 0,
        extraChargesRs DOUBLE DEFAULT 0,
        chargeReason VARCHAR(200),
        status VARCHAR(50) DEFAULT 'checked-in',   -- ADD STATUS HERE
        createdAt VARCHAR(100)
      )
    ''');


    // BOOKING ITEMS
    await _conn.query('''
      CREATE TABLE IF NOT EXISTS booking_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        logId INT NOT NULL,
        roomId INT,
        roomNumber VARCHAR(50),
        arrivalDate VARCHAR(50),
        checkInTime VARCHAR(50),
        checkOutDate VARCHAR(50),
        checkOutTime VARCHAR(50),
        status VARCHAR(50) DEFAULT 'booked',
        discount DOUBLE DEFAULT 0,
        FOREIGN KEY (logId) REFERENCES guestlog(id) ON DELETE CASCADE,
        FOREIGN KEY (roomId) REFERENCES rooms(id) ON DELETE SET NULL
      )
    ''');

    // ================================================================
    // NEW TABLE: GUEST SERVICE CONSUMPTION
    // ================================================================
    await _conn.query('''
      CREATE TABLE IF NOT EXISTS guest_service_consumption (
        id INT AUTO_INCREMENT PRIMARY KEY,
        logId INT NOT NULL,
        serviceId INT NOT NULL,
        quantity INT DEFAULT 0,
        pricePerUnit DOUBLE DEFAULT 0,
        FOREIGN KEY (logId) REFERENCES guestlog(id) ON DELETE CASCADE,
        FOREIGN KEY (serviceId) REFERENCES services(id) ON DELETE CASCADE
      )
    ''');

    // ================================================================
    // GUEST BILLS
    // ================================================================
    await _conn.query('''
      CREATE TABLE IF NOT EXISTS guest_bills (
        id INT AUTO_INCREMENT PRIMARY KEY,
        logId INT NOT NULL,
        discount DOUBLE DEFAULT 0,
        additionalCharge DOUBLE DEFAULT 0,
        reason VARCHAR(255),
        createdAt VARCHAR(100) DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (logId) REFERENCES guestlog(id) ON DELETE CASCADE
      )
    ''');

    
  }

  // ================================================================
  // HELPERS
  // ================================================================
  String? _toString(dynamic value) {
    if (value == null) return null;
    if (value is List<int>) return String.fromCharCodes(value);
    return value.toString();
  }

  Map<String, dynamic> _rowToMap(ResultRow row) {
    return row.fields.map((k, v) => MapEntry(k, _toString(v)));
  }

  // ================================================================
  // ROOM CRUD
  // ================================================================
  Future<List<Map<String, dynamic>>> fetchRooms() async {
    final res = await _conn.query('SELECT * FROM rooms ORDER BY id DESC');
    return res.map(_rowToMap).toList();
  }

  Future<int> insertRoom(Map<String, dynamic> r) async {
    final res = await _conn.query(
      'INSERT INTO rooms (number, type, price, active, images, description) VALUES (?, ?, ?, ?, ?, ?)',
      [
        r['number'],
        r['type'],
        r['price'],
        r['active'],
        r['images'],
        r['description'],
      ],
    );
    return res.insertId ?? 0;
  }

  Future<void> updateRoom(int id, Map<String, dynamic> r) async {
    await _conn.query(
      'UPDATE rooms SET number=?, type=?, price=?, active=?, images=?, description=? WHERE id=?',
      [
        r['number'],
        r['type'],
        r['price'],
        r['active'],
        r['images'],
        r['description'],
        id,
      ],
    );
  }

  Future<void> deleteRoom(int id) async {
    await _conn.query('DELETE FROM rooms WHERE id=?', [id]);
  }

  // ================================================================
  // SERVICE CRUD
  // ================================================================
  Future<List<Map<String, dynamic>>> fetchServices() async {
    final res = await _conn.query('SELECT * FROM services ORDER BY id DESC');
    return res.map(_rowToMap).toList();
  }

  Future<int> insertService(Map<String, dynamic> s) async {
    final res = await _conn.query(
      'INSERT INTO services (name, price, active, category, description, images) VALUES (?, ?, ?, ?, ?, ?)',
      [
        s['name'],
        s['price'],
        s['active'],
        s['category'],
        s['description'],
        s['images'],
      ],
    );
    return res.insertId ?? 0;
  }

  Future<void> updateService(int id, Map<String, dynamic> s) async {
    await _conn.query(
      'UPDATE services SET name=?, price=?, active=?, category=?, description=?, images=? WHERE id=?',
      [
        s['name'],
        s['price'],
        s['active'],
        s['category'],
        s['description'],
        s['images'],
        id,
      ],
    );
  }

  Future<void> deleteService(int id) async {
    await _conn.query('DELETE FROM services WHERE id=?', [id]);
  }

  // ================================================================
  // USER CRUD
  // ================================================================
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final res = await _conn.query('SELECT * FROM users ORDER BY id DESC');
    return res.map(_rowToMap).toList();
  }

  Future<int> insertUser(Map<String, dynamic> u) async {
    final res = await _conn.query(
      'INSERT INTO users (name, phone, email, idImagePath) VALUES (?, ?, ?, ?)',
      [u['name'], u['phone'], u['email'], u['idImagePath']],
    );
    return res.insertId ?? 0;
  }

  Future<void> updateUser(int id, Map<String, dynamic> u) async {
    await _conn.query(
      'UPDATE users SET name=?, phone=?, email=?, idImagePath=? WHERE id=?',
      [u['name'], u['phone'], u['email'], u['idImagePath'], id],
    );
  }

  Future<void> deleteUser(int id) async {
    await _conn.query('DELETE FROM users WHERE id=?', [id]);
  }

  // ================================================================
  // GUEST LOG CRUD
  // ================================================================
  Future<List<Map<String, dynamic>>> fetchGuestLogs() async {
    final res = await _conn.query('SELECT * FROM guestlog ORDER BY id DESC');
    return res.map(_rowToMap).toList();
  }

  Future<int> insertGuestLog(
    Map<String, dynamic> g,
    List<Map<String, dynamic>> items,
  ) async {
    final res = await _conn.query(
      '''
      INSERT INTO guestlog (
        name, address, citizenNumber, occupation,
        numberOfGuests, relationWithPartner, reasonOfStay,
        contactNumber, citizenImageBlob, citizenImageDriveLink,
        overallDiscountRs, extraChargesRs, chargeReason, createdAt
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        g['name'],
        g['address'],
        g['citizenNumber'],
        g['occupation'],
        g['numberOfGuests'],
        g['relationWithPartner'],
        g['reasonOfStay'],
        g['contactNumber'],
        g['citizenImageBlob'],
        g['citizenImageDriveLink'],
        g['overallDiscountRs'] ?? 0,
        g['extraChargesRs'] ?? 0,
        g['chargeReason'],
        g['createdAt'],
      ],
    );

    final logId = res.insertId ?? 0;

    for (final item in items) {
      await insertBookingItem({...item, 'logId': logId});
    }

    return logId;
  }

  Future<void> updateGuestLog(
    int id,
    Map<String, dynamic> g,
    List<Map<String, dynamic>> items,
  ) async {
    await _conn.query(
      '''
      UPDATE guestlog SET
        name=?, address=?, citizenNumber=?, occupation=?,
        numberOfGuests=?, relationWithPartner=?, reasonOfStay=?,
        contactNumber=?, citizenImageBlob=?, citizenImageDriveLink=?,
        overallDiscountRs=?, extraChargesRs=?, chargeReason=?
      WHERE id=?
      ''',
      [
        g['name'],
        g['address'],
        g['citizenNumber'],
        g['occupation'],
        g['numberOfGuests'],
        g['relationWithPartner'],
        g['reasonOfStay'],
        g['contactNumber'],
        g['citizenImageBlob'],
        g['citizenImageDriveLink'],
        g['overallDiscountRs'] ?? 0,
        g['extraChargesRs'] ?? 0,
        g['chargeReason'],
        id,
      ],
    );

    await deleteBookingItemsByLog(id);

    for (final item in items) {
      await insertBookingItem({...item, 'logId': id});
    }
  }

  Future<void> deleteGuestLog(int id) async {
    await _conn.query('DELETE FROM guestlog WHERE id=?', [id]);
  }

  // ================================================================
  // BOOKING ITEMS
  // ================================================================
  Future<int> insertBookingItem(Map<String, dynamic> i) async {
    DateTime? parseToUtc(dynamic v) {
      if (v == null) return null;

      if (v is DateTime) {
        return v.isUtc ? v : v.toUtc();
      }

      if (v is String) {
        final d = DateTime.parse(v);
        return d.isUtc ? d : d.toUtc();
      }

      throw ArgumentError('Invalid date type: ${v.runtimeType}');
    }

    final arrivalDateUtc = parseToUtc(i['checkInDate']);
    final checkOutDateUtc = parseToUtc(i['checkOutDate']);

    final res = await _conn.query(
      '''
    INSERT INTO booking_items (
      logId, roomId, roomNumber,
      arrivalDate, checkInTime,
      checkOutDate, checkOutTime,
      discount, status
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        i['logId'],
        i['roomId'],
        i['roomNumber'],
        arrivalDateUtc,
        i['checkInTime'],
        checkOutDateUtc,
        i['checkOutTime'],
        i['discount'] ?? 0,
        i['status'] ?? 'booked',
      ],
    );

    return res.insertId ?? 0;
  }

  Future<void> deleteBookingItemsByLog(int logId) async {
    await _conn.query('DELETE FROM booking_items WHERE logId=?', [logId]);
  }

  Future<List<Map<String, dynamic>>> fetchBookingItemsByLog(int logId) async {
    final res = await _conn.query(
      'SELECT * FROM booking_items WHERE logId = ? ORDER BY id ASC',
      [logId],
    );
    return res.map(_rowToMap).toList();
  }


  Future<List<Map<String, dynamic>>> fetchAllBookingItems() async {
    final res = await _conn.query(
      'SELECT * FROM booking_items ORDER BY id ASC',
    );
    return res.map(_rowToMap).toList();
  }

  Future<int> updateBookingItem(int id, Map<String, dynamic> i) async {
    final arrivalDateUtc =
        i['checkInDate'];
    final checkOutDateUtc =
        i['checkOutDate'];

    final res = await _conn.query(
      '''
    UPDATE booking_items
    SET roomNumber=?,
        arrivalDate=?, checkInTime=?,
        checkOutDate=?, checkOutTime=?,
        discount=?, status=?
    WHERE id=?
    ''',
      [
        i['roomNumber'],
        arrivalDateUtc,
        i['checkInTime'],
        checkOutDateUtc,
        i['checkOutTime'],
        i['discount'] ?? 0,
        i['status'] ?? 'booked',
        id,
      ],
    );
    return res.affectedRows ?? 0;
  }


  // ================================================================
  // BOOKINGS CRUD
  // ================================================================
  Future<List<Map<String, dynamic>>> fetchBookings() async {
    final res = await _conn.query('SELECT * FROM bookings ORDER BY id DESC');
    return res.map(_rowToMap).toList();
  }

  Future<int> insertBooking(Map<String, dynamic> b) async {
    final res = await _conn.query(
      'INSERT INTO bookings (userId, roomId, checkIn, checkOut, services, total, status, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        b['userId'],
        b['roomId'],
        b['checkIn'],
        b['checkOut'],
        b['services'],
        b['total'],
        b['status'],
        b['createdAt'],
      ],
    );
    return res.insertId ?? 0;
  }

  Future<void> updateBooking(int id, Map<String, dynamic> b) async {
    await _conn.query(
      'UPDATE bookings SET userId=?, roomId=?, checkIn=?, checkOut=?, services=?, total=?, status=?, createdAt=? WHERE id=?',
      [
        b['userId'],
        b['roomId'],
        b['checkIn'],
        b['checkOut'],
        b['services'],
        b['total'],
        b['status'],
        b['createdAt'],
        id,
      ],
    );
  }

  Future<void> deleteBooking(int id) async {
    await _conn.query('DELETE FROM bookings WHERE id=?', [id]);
  }

  // ================================================================
  // NEW: GUEST SERVICE CONSUMPTION CRUD
  // ================================================================
  Future<List<Map<String, dynamic>>> fetchServiceConsumptionSummary(
    int logId,
  ) async {
    final res = await _conn.query(
      'SELECT serviceId, SUM(quantity) as totalQuantity FROM guest_service_consumption WHERE logId=? GROUP BY serviceId',
      [logId],
    );
    return res.map(_rowToMap).toList();
  }

  Future<void> deleteGuestServiceConsumptionByLog(int logId) async {
    await _conn.query('DELETE FROM guest_service_consumption WHERE logId=?', [
      logId,
    ]);
  }

  Future<void> bulkInsertGuestServiceConsumption(
    List<Map<String, dynamic>> items,
  ) async {
    for (final i in items) {
      final logExists = await _conn.query(
        'SELECT id FROM guestlog WHERE id=?',
        [i['logId']],
      );
      if (logExists.isEmpty) {
        throw Exception('Guest log ID ${i['logId']} does not exist.');
      }

      await _conn.query(
        'INSERT INTO guest_service_consumption (logId, serviceId, quantity, pricePerUnit) VALUES (?, ?, ?, ?)',
        [i['logId'], i['serviceId'], i['quantity'], i['pricePerUnit']],
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchGuestLogById(int logId) async {
    final res = await _conn.query('SELECT * FROM guestlog WHERE id=?', [logId]);
    return res.map(_rowToMap).toList();
  }

  // Update guest log to Checked Out
  Future<void> updateGuestLogStatus(
    int logId, {
    required String status,
    required String checkOutDate, // should be a valid ISO string
  }) async {
    // 1. Update the guest log status
    await _conn.query('UPDATE guestlog SET status = ? WHERE id = ?', [
      status,
      logId,
    ]);

    // 2. Update all associated booking items
    await _conn.query(
      'UPDATE booking_items SET status = ?, checkOutDate = ? WHERE logId = ?',
      [status, checkOutDate.isNotEmpty ? checkOutDate : null, logId],
    );
  }


  // Optional: Save bill info
  Future<void> saveGuestBill(
    int logId, {
    double discount = 0,
    double additionalCharge = 0,
    String reason = '',
  }) async {
    // implement logic to save to a 'guest_bills' table if you have one
    // Example:
    await _conn.query(
      'INSERT INTO guest_bills (logId, discount, additionalCharge, reason) VALUES (?, ?, ?, ?)',
      [logId, discount, additionalCharge, reason],
    );
  }

  // ================================================================
  // DELETE GUEST LOG AND ALL ASSOCIATED DATA
  // ================================================================
  /// DELETE GUEST LOG AND ALL ASSOCIATED DATA
  Future<void> deleteGuestLogWithAssociations(int logId) async {
    // 1. Delete guest service consumption
    await _conn.query('DELETE FROM guest_service_consumption WHERE logId = ?', [
      logId,
    ]);

    // 2. Delete booking items
    await _conn.query('DELETE FROM booking_items WHERE logId = ?', [logId]);

    // 3. Delete guest bills
    await _conn.query('DELETE FROM guest_bills WHERE logId = ?', [logId]);

    // 4. Delete the guest log itself
    await _conn.query('DELETE FROM guestlog WHERE id = ?', [logId]);
  }




}
