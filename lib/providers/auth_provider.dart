import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../data/services/auth_service.dart';
import '../utils/storage_helper.dart';


class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  String? _token;
  UserModel? _user;
  bool _isGuestMode = false;

  String? get token => _token;
  UserModel? get user => _user;
  bool get isAuthenticated => _token != null || _isGuestMode;
  bool get isGuestMode => _isGuestMode;

  Future<void> loginAsGuest() async {
    _token = null; 
    _isGuestMode = true;
    _user = UserModel(
      nombres: 'Invitado',
      apellidos: '',
      correo: 'invitado@unison.mx',
      tipoUsuario: 'invitado',
      departamento: '',
      carrera: '',
      expediente: null,
      semestre: null,
      fechaRegistro: null,
    );
    
    await StorageHelper.setGuestMode(true);
    await StorageHelper.saveUser(_user!);
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final result = await _authService.login(email, password);
      if (result != null) {
        _token = result;
        _isGuestMode = false;
        
        await StorageHelper.saveToken(_token!);
        await StorageHelper.setGuestMode(false);
        
        await fetchUser();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  Future<void> loadToken() async {
    try {
      _isGuestMode = await StorageHelper.isGuestMode();
      
      if (_isGuestMode) {
        _token = null;
        _user = await StorageHelper.getUser();
        notifyListeners();
        return;
      }
      
      _token = await StorageHelper.getToken();
      _user = await StorageHelper.getUser();
      
      if (_token != null) {
        notifyListeners();
      }
    } catch (e) {
      print('Error cargando datos: $e');
    }
  }

  Future<bool> validateToken() async {
    if (_token == null || _isGuestMode) return _isGuestMode;
    
    try {
      final isValid = await _authService.validateToken(_token!);
      if (!isValid) {
        print('Token inválido - limpiando sesión');
        await _clearSession();
      }
      return isValid;
    } catch (e) {
      print('Error validando token: $e');
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    return await _authService.register(userData);
  }

  Future<void> fetchUser() async {
    if (_token == null || _isGuestMode) {
      print('No hay token o está en modo invitado');
      return;
    }

    print('Token presente: $_token');

    try {
      final user = await _authService.getCurrentUser(_token!);
      if (user == null) {
        print('El backend no devolvió usuario (¿token inválido?)');
        await _clearSession();
      } else {
        print('Usuario cargado: ${user.nombreCompleto}');
        _user = user;
        await StorageHelper.saveUser(_user!);
      }
    } catch (e) {
      print('Error obteniendo usuario: $e');
    }

    notifyListeners();
  }

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _token = null;
    _user = null;
    _isGuestMode = false;
    await StorageHelper.clearAll();
  }

  Future<bool> checkConnection() async {
    return await _authService.isServerAvailable();
  }
}
