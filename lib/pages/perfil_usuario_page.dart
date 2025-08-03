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
  int _selectedIndex = 0; // Índice para "Perfil"

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _apellidoController = TextEditingController();
    _telefonoController = TextEditingController();
    _loadUserData();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Ya estamos en esta página
        break;
      case 1:
        Navigator.popAndPushNamed(context, '/categorias');
        break;
      case 2:
        Navigator.popAndPushNamed(context, '/publicaciones');
        break;
      case 3:
        Navigator.popAndPushNamed(context, '/todas-publicaciones');
        break;
      case 4:
        FirebaseAuth.instance.signOut();
        // Redirigir al usuario a la página de inicio de sesión
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/', // Asumiendo que la ruta de login es la raíz
          (route) => false,
        );
        break;
    }
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
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .update({
                'nombre': _nombreController.text.trim(),
                'apellido': _apellidoController.text.trim(),
                'telefono': _telefonoController.text.trim(),
              });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado con éxito'),
              backgroundColor: Colors.black,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar el perfil: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
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
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    labelStyle: const TextStyle(color: Colors.black),
                    prefixIcon: const Icon(Icons.person, color: Colors.black),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese su nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apellidoController,
                  decoration: InputDecoration(
                    labelText: 'Apellido',
                    labelStyle: const TextStyle(color: Colors.black),
                    prefixIcon: const Icon(Icons.person, color: Colors.black),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese su apellido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonoController,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    labelStyle: const TextStyle(color: Colors.black),
                    prefixIcon: const Icon(Icons.phone, color: Colors.black),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      )
                    : ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.black,
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categorías',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.my_library_books),
            label: 'Mis Publicaciones',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Todas'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Salir'),
        ],
      ),
    );
  }
}
