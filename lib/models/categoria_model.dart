import 'package:cloud_firestore/cloud_firestore.dart';

class Categoria {
  final String id;
  final String nombre;
  final DateTime fechaCreacion;
  final DateTime? ultimaActualizacion;

  Categoria({
    required this.id,
    required this.nombre,
    required this.fechaCreacion,
    this.ultimaActualizacion,
  });

  factory Categoria.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Categoria(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
      ultimaActualizacion: data['ultimaActualizacion'] != null
          ? (data['ultimaActualizacion'] as Timestamp).toDate()
          : null,
    );
  }
}
