import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  bool _isAuthenticated = false;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String username, String password) async {
    try {
      final db = DatabaseService.instance;
      final results = await db.rawQuery(
        'SELECT * FROM users WHERE username = ? AND is_active = 1',
        [username],
      );

      if (results.isEmpty) return false;

      final user = results.first;
      final storedHash = user['password_hash'] as String;

      final isValidPassword = BCrypt.checkpw(password, storedHash);
      if (!isValidPassword) return false;

      _currentUser = user;
      _isAuthenticated = true;

      await db.update('users', {
        'last_login': DateTime.now().toIso8601String(),
      }, user['id'] as int);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<bool> checkPermission(String module, String action) async {
    if (_currentUser == null) return false;

    final role = _currentUser!['role'] as String;
    if (role == 'super_admin') return true;

    final db = DatabaseService.instance;
    final results = await db.rawQuery(
      'SELECT * FROM permissions WHERE role = ? AND module = ?',
      [role, module],
    );

    if (results.isEmpty) return false;

    final permission = results.first;
    switch (action) {
      case 'view': return permission['can_view'] == 1;
      case 'create': return permission['can_create'] == 1;
      case 'edit': return permission['can_edit'] == 1;
      case 'delete': return permission['can_delete'] == 1;
      case 'export': return permission['can_export'] == 1;
      default: return false;
    }
  }
}
