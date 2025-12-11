import 'package:mysql1/mysql1.dart';

class DatabaseRepo {
  late MySqlConnection _conn;

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
  // AUTO CREATE TABLES IF NOT EXISTS
  // ================================================================
  Future<void> _createTables() async {
    // rooms table
    await _conn.query('''
      CREATE TABLE IF NOT EXISTS rooms (
        id INT AUTO_INCREMENT PRIMARY KEY,
        number VARCHAR(50),
        type VARCHAR(100),
        price DOUBLE,
        active TINYINT DEFAULT 1,
        images TEXT
      )
    ''');

    // services table
    await _conn.query('''
      CREATE TABLE IF NOT EXISTS services (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(150),
        price DOUBLE,
        active TINYINT DEFAULT 1
      )
    ''');

    // users table
    await _conn.query('''
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(150),
        phone VARCHAR(50),
        email VARCHAR(150)
      )
    ''');

    // bookings table
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
  }

  // ================================================================
  // HANDLE BLOB/TEXT
  // ================================================================
  String? _toString(dynamic value) {
    if (value == null) return null;
    if (value is List<int>) return String.fromCharCodes(value);
    return value.toString();
  }

  Map<String, dynamic> _rowToMap(ResultRow row) {
    return row.fields.map((key, value) => MapEntry(key, _toString(value)));
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
      'INSERT INTO rooms (number, type, price, active, images) VALUES (?, ?, ?, ?, ?)',
      [r['number'], r['type'], r['price'], r['active'], r['images']],
    );
    return res.insertId ?? 0;
  }

  Future<void> updateRoom(int id, Map<String, dynamic> r) async {
    await _conn.query(
      'UPDATE rooms SET number=?, type=?, price=?, active=?, images=? WHERE id=?',
      [r['number'], r['type'], r['price'], r['active'], r['images'], id],
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
      'INSERT INTO services (name, price, active) VALUES (?, ?, ?)',
      [s['name'], s['price'], s['active']],
    );
    return res.insertId ?? 0;
  }

  Future<void> updateService(int id, Map<String, dynamic> s) async {
    await _conn.query(
      'UPDATE services SET name=?, price=?, active=? WHERE id=?',
      [s['name'], s['price'], s['active'], id],
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
      'INSERT INTO users (name, phone, email) VALUES (?, ?, ?)',
      [u['name'], u['phone'], u['email']],
    );
    return res.insertId ?? 0;
  }

  Future<void> updateUser(int id, Map<String, dynamic> u) async {
    await _conn.query('UPDATE users SET name=?, phone=?, email=? WHERE id=?', [
      u['name'],
      u['phone'],
      u['email'],
      id,
    ]);
  }

  Future<void> deleteUser(int id) async {
    await _conn.query('DELETE FROM users WHERE id=?', [id]);
  }

  // ================================================================
  // BOOKING CRUD
  // ================================================================
  Future<List<Map<String, dynamic>>> fetchBookings() async {
    final res = await _conn.query('SELECT * FROM bookings ORDER BY id DESC');
    return res.map(_rowToMap).toList();
  }

  Future<int> insertBooking(Map<String, dynamic> b) async {
    final res = await _conn.query(
      'INSERT INTO bookings (userId, roomId, checkIn, checkOut, services, total, status, createdAt) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
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
}
