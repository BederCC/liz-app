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

  Future<void> actualizarPublicacion({
    required String publicacionId,
    required String categoriaId,
    required String titulo,
    required String contenido,
    required bool esAnonimo,
  }) async {
    await _firestore.collection('publicaciones').doc(publicacionId).update({
      'categoriaId': categoriaId,
      'titulo': titulo,
      'contenido': contenido,
      'esAnonimo': esAnonimo,
      'fechaPublicacion': FieldValue.serverTimestamp(),
    });
  }

  Future<void> eliminarPublicacion(String publicacionId) async {
    await _firestore.collection('publicaciones').doc(publicacionId).delete();
  }

  Future<void> toggleLike(String publicacionId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final likeRef = _firestore
        .collection('reacciones')
        .doc('${publicacionId}_${user.uid}');

    final doc = await likeRef.get();

    if (doc.exists) {
      await likeRef.delete();
      // Ya no actualizamos el contador en la publicación
    } else {
      await likeRef.set({
        'publicacionId': publicacionId,
        'usuarioId': user.uid,
        'fecha': FieldValue.serverTimestamp(),
        'tipo': 'like',
      });
      // Ya no actualizamos el contador en la publicación
    }
  }

  Future<int> getLikesCount(String publicacionId) async {
    final snapshot = await _firestore
        .collection('reacciones')
        .where('publicacionId', isEqualTo: publicacionId)
        .where('tipo', isEqualTo: 'like')
        .get();
    return snapshot.docs.length;
  }

  Future<bool> hasUserLiked(String publicacionId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('reacciones')
        .doc('${publicacionId}_${user.uid}')
        .get();
    return doc.exists;
  }

  Future<List<Map<String, dynamic>>> obtenerComentarios(
    String publicacionId,
  ) async {
    final snapshot = await _firestore
        .collection('comentarios')
        .where('publicacionId', isEqualTo: publicacionId)
        .orderBy('fecha', descending: false)
        .get();

    return await Future.wait(
      snapshot.docs.map((doc) async {
        final data = doc.data();
        final userDoc = await _firestore
            .collection('usuarios')
            .doc(data['usuarioId'])
            .get();
        return {
          'id': doc.id,
          'usuarioId': data['usuarioId'],
          'usuarioNombre': userDoc.data()?['nombre'] ?? 'Usuario',
          'contenido': data['contenido'],
          'fecha': data['fecha'],
        };
      }),
    );
  }

  Future<void> agregarComentario({
    required String publicacionId,
    required String contenido,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    await _firestore.collection('comentarios').add({
      'publicacionId': publicacionId,
      'usuarioId': user.uid,
      'contenido': contenido,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  Stream<bool> hasUserLikedStream(String publicacionId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('reacciones')
        .doc('${publicacionId}_${user.uid}')
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<int> getLikesCountStream(String publicacionId) {
    return _firestore
        .collection('reacciones')
        .where('publicacionId', isEqualTo: publicacionId)
        .where('tipo', isEqualTo: 'like')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
