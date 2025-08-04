import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion_luz/models/publicacion_model.dart';
import 'package:aplicacion_luz/services/publicacion_service.dart';
import 'package:aplicacion_luz/pages/publicaciones/crear_publicacion_page.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PublicacionesPage extends StatefulWidget {
  const PublicacionesPage({super.key});

  @override
  State<PublicacionesPage> createState() => _PublicacionesPageState();
}

class _PublicacionesPageState extends State<PublicacionesPage> {
  late final PublicacionService _publicacionService;
  int _selectedIndex = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _publicacionService = Provider.of<PublicacionService>(
      context,
      listen: false,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.popAndPushNamed(context, '/perfil');
        break;
      case 1:
        Navigator.popAndPushNamed(context, '/publicaciones');
        break;
      case 2:
        Navigator.popAndPushNamed(context, '/todas-publicaciones');
        break;
      case 3:
        FirebaseAuth.instance.signOut();
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Publicaciones',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () => _navegarACrearPublicacion(context),
            tooltip: 'Crear nueva publicación',
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: RefreshIndicator(
          color: Colors.black,
          onRefresh: _refreshPublicaciones,
          child: FutureBuilder<List<Publicacion>>(
            future: _publicacionService.obtenerPublicacionesDelUsuario(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }

              final publicaciones = snapshot.data ?? [];

              if (publicaciones.isEmpty) {
                return const Center(
                  child: Text(
                    'No tienes publicaciones aún',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: publicaciones.length,
                itemBuilder: (context, index) {
                  final publicacion = publicaciones[index];
                  return _PublicacionCard(
                    publicacion: publicacion,
                    onEdit: () => _editarPublicacion(context, publicacion),
                    onDelete: () =>
                        _eliminarPublicacion(context, publicacion.id),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarACrearPublicacion(context),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
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
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.category),
          //   label: 'Categorías',
          // ),
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

  Future<void> _refreshPublicaciones() async {
    setState(() {});
  }

  void _navegarACrearPublicacion(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearPublicacionPage()),
    ).then((_) => setState(() {}));
  }

  void _editarPublicacion(BuildContext context, Publicacion publicacion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CrearPublicacionPage(publicacionExistente: publicacion),
      ),
    ).then((_) => setState(() {}));
  }

  Future<void> _eliminarPublicacion(
    BuildContext context,
    String publicacionId,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Eliminar publicación',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta publicación?',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _publicacionService.eliminarPublicacion(publicacionId);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publicación eliminada'),
            backgroundColor: Colors.black,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _PublicacionCard extends StatelessWidget {
  final Publicacion publicacion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PublicacionCard({
    required this.publicacion,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    publicacion.titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.black),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.black),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              publicacion.contenido,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  backgroundColor: publicacion.esAnonimo
                      ? Colors.grey.shade200
                      : Colors.grey.shade200,
                  label: Text(
                    publicacion.esAnonimo ? 'Anónimo' : 'Público',
                    style: const TextStyle(color: Colors.black),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(publicacion.fechaPublicacion),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
