import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplicacion_luz/models/publicacion_model.dart';

class PublicacionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Publicacion>> obtenerPublicacionesDelUsuario() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final snapshot = await _firestore
        .collection('publicaciones')
        .where('usuarioId', isEqualTo: user.uid)
        .orderBy('fechaPublicacion', descending: true)
        .get();

    return snapshot.docs.map(Publicacion.fromFirestore).toList();
  }

  Future<String> crearPublicacion({
    required String categoriaId,
    required String titulo,
    required String contenido,
    required bool esAnonimo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final docRef = await _firestore.collection('publicaciones').add({
      'usuarioId': user.uid,
      'categoriaId': categoriaId,
      'titulo': titulo,
      'contenido': contenido,
      'esAnonimo': esAnonimo,
      'fechaPublicacion': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<void> eliminarPublicacion(String publicacionId) async {
    await _firestore.collection('publicaciones').doc(publicacionId).delete();
  }
}
