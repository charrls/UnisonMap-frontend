import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../data/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  String? _token;
  UserModel? _user;

  String? get token => _token;
  UserModel? get user => _user;
  bool get isAuthenticated => _token != null;


  Future<void> loginAsGuest() async {
  _token = null; 
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
  notifyListeners();
}

  Future<bool> login(String email, String password) async {
    final result = await _authService.login(email, password);
    if (result != null) {
      _token = result;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await fetchUser();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      await fetchUser();
      notifyListeners();
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    return await _authService.register(userData);
  }

Future<void> fetchUser() async {
  if (_token == null) {
    print('No hay token');
    return;
  }

  print('Token presente: $_token');

  final user = await _authService.getCurrentUser(_token!);
  if (user == null) {
    print('El backend no devolvió usuario (¿token inválido?)');
  } else {
    print('Usuario cargado: ${user.nombreCompleto}');
  }

  _user = user;
  notifyListeners();
}


  void logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }


}
