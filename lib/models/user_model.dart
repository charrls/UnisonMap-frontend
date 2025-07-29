class UserModel {
  final String nombres;
  final String apellidos;
  final String correo;
  final String tipoUsuario;
  final String departamento;
  final String carrera;
  final String? expediente;
  final int? semestre;
  final String? fechaRegistro;

  UserModel({
    required this.nombres,
    required this.apellidos,
    required this.correo,
    required this.tipoUsuario,
    required this.departamento,
    required this.carrera,
    this.expediente,
    this.semestre,
    this.fechaRegistro,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      nombres: json['nombres'],
      apellidos: json['apellidos'],
      correo: json['correo'],
      tipoUsuario: json['tipo_usuario'],
      departamento: json['departamento'],
      carrera: json['carrera'],
      expediente: json['expediente'], 
      semestre: json['semestre'],     
      fechaRegistro: json['fecha_registro'], 
    );
  }

  String get nombreCompleto => '$nombres $apellidos';
}
