class Usuario {
  final String uid;
  final String email;
  final String apodo;
  final int edad;
  final String carrera;
  final String descripcion;

  Usuario({
    required this.uid,
    required this.email,
    required this.apodo,
    required this.edad,
    required this.carrera,
    required this.descripcion,
  });

  factory Usuario.fromMap(Map<String, dynamic> data, String uid) {
    return Usuario(
      uid: uid,
      email: data['email'] ?? '',
      apodo: data['apodo'] ?? '',
      edad: data['edad'] ?? 0,
      carrera: data['carrera'] ?? '',
      descripcion: data['descripcion'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'apodo': apodo,
      'edad': edad,
      'carrera': carrera,
      'descripcion': descripcion,
    };
  }
}
