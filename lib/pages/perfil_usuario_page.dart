import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion_luz/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilUsuarioPage extends StatefulWidget {
  const PerfilUsuarioPage({Key? key}) : super(key: key);

  @override
  _PerfilUsuarioPageState createState() => _PerfilUsuarioPageState();
}

class _PerfilUsuarioPageState extends State<PerfilUsuarioPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _telefonoController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _apellidoController = TextEditingController();
    _telefonoController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _nombreController.text = doc['nombre'] ?? '';
          _apellidoController.text = doc['apellido'] ?? '';
          _telefonoController.text = doc['telefono'] ?? '';
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userRef = FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid);

          // Verificar si el documento existe
          final doc = await userRef.get();

          if (!doc.exists) {
            // Crear el documento si no existe
            await userRef.set({
              'nombre': _nombreController.text.trim(),
              'apellido': _apellidoController.text.trim(),
              'telefono': _telefonoController.text.trim(),
              'email': user.email, // Añadir email del usuario
              'creado': FieldValue.serverTimestamp(),
            });
          } else {
            // Actualizar el documento existente
            await userRef.update({
              'nombre': _nombreController.text.trim(),
              'apellido': _apellidoController.text.trim(),
              'telefono': _telefonoController.text.trim(),
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado correctamente')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // En el método que guarda los datos en PerfilUsuarioPage
  Future<void> _guardarDatos() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Crear documento en Firestore por primera vez con todos los datos
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set(
        {
          'nombre': _nombreController.text,
          'apellido': _apellidoController.text,
          'telefono': _telefonoController.text,
          'email': user.email,
          'creado': FieldValue.serverTimestamp(),
          'verificado': user.emailVerified,
          'perfilCompleto':
              true, // Siempre true porque se crea al completar datos
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil creado y actualizado correctamente'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar datos: $e')));
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Colors.pink.shade100,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.pink.shade800),
      ),
      body: Container(
        color: Colors.pink.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nombreController,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              labelStyle: TextStyle(
                                color: Colors.pink.shade600,
                              ),
                              prefixIcon: Icon(
                                Icons.person,
                                color: Colors.pink.shade600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.pink.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.pink.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.pink.shade400,
                                ),
                              ),
                            ),
                            style: TextStyle(color: Colors.grey.shade800),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Por favor ingresa tu nombre';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _apellidoController,
                            decoration: InputDecoration(
                              labelText: 'Apellido',
                              labelStyle: TextStyle(
                                color: Colors.pink.shade600,
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Colors.pink.shade600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.pink.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.pink.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.pink.shade400,
                                ),
                              ),
                            ),
                            style: TextStyle(color: Colors.grey.shade800),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _telefonoController,
                            decoration: InputDecoration(
                              labelText: 'Teléfono',
                              labelStyle: TextStyle(
                                color: Colors.pink.shade600,
                              ),
                              prefixIcon: Icon(
                                Icons.phone,
                                color: Colors.pink.shade600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.pink.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.pink.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.pink.shade400,
                                ),
                              ),
                            ),
                            style: TextStyle(color: Colors.grey.shade800),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? CircularProgressIndicator(color: Colors.pink.shade600)
                      : ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.pink.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Guardar Cambios',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
