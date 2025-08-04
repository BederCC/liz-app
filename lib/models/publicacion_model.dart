import 'package:cloud_firestore/cloud_firestore.dart';

class Publicacion {
  final String id;
  final String usuarioId;
  final String categoriaId;
  final String titulo;
  final String contenido;
  final String imagenUrl;
  final bool esAnonimo;
  final DateTime fechaPublicacion;

  Publicacion({
    required this.id,
    required this.usuarioId,
    required this.categoriaId,
    required this.titulo,
    required this.contenido,
    required this.imagenUrl,
    required this.esAnonimo,
    required this.fechaPublicacion,
  });

  factory Publicacion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Publicacion(
      id: doc.id,
      usuarioId: data['usuarioId'],
      categoriaId: data['categoriaId'],
      titulo: data['titulo'],
      contenido: data['contenido'],
      imagenUrl: data['imagenUrl'] ?? '',
      esAnonimo: data['esAnonimo'] ?? false,
      fechaPublicacion: (data['fechaPublicacion'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'usuarioId': usuarioId,
      'categoriaId': categoriaId,
      'titulo': titulo,
      'contenido': contenido,
      'imagenUrl': imagenUrl.isNotEmpty ? imagenUrl : null,
      'esAnonimo': esAnonimo,
      'fechaPublicacion': Timestamp.fromDate(fechaPublicacion),
    };
  }
}
