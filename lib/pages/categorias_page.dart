import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aplicacion_luz/models/categoria_model.dart';
import 'package:aplicacion_luz/services/categoria_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplicacion_luz/pages/perfil_usuario_page.dart';
import 'package:aplicacion_luz/pages/publicaciones_page.dart';
import 'package:aplicacion_luz/pages/publicaciones/todas_publicaciones_page.dart';

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  late final CategoriaService _categoriaService;
  List<Categoria> _categorias = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _categoriaService = Provider.of<CategoriaService>(context, listen: false);
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    setState(() => _isLoading = true);
    try {
      final categorias = await _categoriaService.obtenerCategorias();
      setState(() => _categorias = categorias);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar categorías: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Categoria> _filtrarCategorias() {
    if (_searchController.text.isEmpty) {
      return _categorias;
    }
    return _categorias
        .where(
          (categoria) => categoria.nombre.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ),
        )
        .toList();
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
    final categoriasFiltradas = _filtrarCategorias();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _cargarCategorias,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar categorías',
                  labelStyle: const TextStyle(color: Colors.black),
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : categoriasFiltradas.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontraron categorías',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      color: Colors.black,
                      onRefresh: _cargarCategorias,
                      child: ListView.builder(
                        itemCount: categoriasFiltradas.length,
                        itemBuilder: (context, index) {
                          final categoria = categoriasFiltradas[index];
                          return _buildCategoriaItem(categoria);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNuevaCategoria(context),
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

  Widget _buildCategoriaItem(Categoria categoria) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: ListTile(
        leading: const Icon(Icons.category, color: Colors.black),
        title: Text(
          categoria.nombre,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creada: ${DateFormat('dd/MM/yyyy').format(categoria.fechaCreacion)}',
              style: const TextStyle(color: Colors.black54),
            ),
            if (categoria.ultimaActualizacion != null)
              Text(
                'Editada: ${DateFormat('dd/MM/yyyy').format(categoria.ultimaActualizacion!)}',
                style: const TextStyle(color: Colors.black54),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () =>
                  _mostrarDialogoEditarCategoria(context, categoria),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black54),
              onPressed: () =>
                  _mostrarDialogoConfirmarEliminacion(context, categoria.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoNuevaCategoria(BuildContext context) async {
    final nombreController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Nueva Categoría',
            style: TextStyle(color: Colors.black),
          ),
          content: TextField(
            controller: nombreController,
            decoration: InputDecoration(
              labelText: 'Nombre de la categoría',
              labelStyle: const TextStyle(color: Colors.black),
              hintText: 'Ej: Deportes',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black),
              ),
            ),
            autofocus: true,
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    await _categoriaService.agregarCategoria(
                      nombreController.text.trim(),
                    );
                    await _cargarCategorias();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Categoría creada'),
                        backgroundColor: Colors.black,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red.shade400,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Crear', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarDialogoEditarCategoria(
    BuildContext context,
    Categoria categoria,
  ) async {
    final nombreController = TextEditingController(text: categoria.nombre);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Editar Categoría',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: nombreController,
            decoration: InputDecoration(
              labelText: 'Nuevo nombre',
              labelStyle: const TextStyle(color: Colors.black),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            autofocus: true,
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    await _categoriaService.actualizarCategoria(
                      categoria.id,
                      nombreController.text.trim(),
                    );
                    await _cargarCategorias();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Categoría actualizada'),
                        backgroundColor: Colors.black,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red.shade400,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarDialogoConfirmarEliminacion(
    BuildContext context,
    String categoriaId,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Confirmar Eliminación',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '¿Estás seguro de eliminar esta categoría? Esta acción no se puede deshacer.',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _categoriaService.eliminarCategoria(categoriaId);
                  await _cargarCategorias();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Categoría eliminada'),
                      backgroundColor: Colors.black,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                }
              },
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
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
