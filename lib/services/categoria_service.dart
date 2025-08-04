import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplicacion_luz/models/categoria_model.dart';

class CategoriaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Categoria>> obtenerCategorias() async {
    try {
      // Verificar si existen categorías
      final query = await _firestore.collection('categorias').limit(1).get();

      if (query.docs.isEmpty) {
        await _crearCategoriasIniciales();
      }

      final snapshot = await _firestore.collection('categorias').get();
      return snapshot.docs.map(Categoria.fromFirestore).toList();
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  Future<void> _crearCategoriasIniciales() async {
    const categoriasIniciales = [
      {'nombre': 'Administración de Empresas'},
      {'nombre': 'Administración de Negocios Internacionales'},
      {'nombre': 'Contabilidad'},
      {'nombre': 'Desarrollo de Sistemas de Información'},
      {'nombre': 'Gastronomía'},
      {'nombre': 'Guía Oficial de Turismo'},
    ];

    final batch = _firestore.batch();

    for (var categoria in categoriasIniciales) {
      final docRef = _firestore.collection('categorias').doc();
      batch.set(docRef, {
        'nombre': categoria['nombre'],
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> agregarCategoria(String nombre) async {
    try {
      await _firestore.collection('categorias').add({
        'nombre': nombre,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al agregar categoría: $e');
    }
  }

  Future<void> actualizarCategoria(String id, String nuevoNombre) async {
    try {
      await _firestore.collection('categorias').doc(id).update({
        'nombre': nuevoNombre,
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  Future<void> eliminarCategoria(String id) async {
    try {
      await _firestore.collection('categorias').doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar categoría: $e');
    }
  }
}
