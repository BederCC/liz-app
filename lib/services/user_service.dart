import 'package:aplicacion_luz/model/usuario_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Usuario> getUsuarioActual() async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("Usuario no autenticado");

    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'apodo': '',
        'edad': 0,
        'carrera': '',
        'descripcion': '',
      });
      return Usuario(
        uid: user.uid,
        email: user.email ?? '',
        apodo: '',
        edad: 0,
        carrera: '',
        descripcion: '',
      );
    }
    return Usuario.fromMap(doc.data() as Map<String, dynamic>, user.uid);
  }

  Future<void> actualizarUsuario(Usuario usuario) async {
    await _firestore
        .collection('users')
        .doc(usuario.uid)
        .update(usuario.toMap());
  }
}
