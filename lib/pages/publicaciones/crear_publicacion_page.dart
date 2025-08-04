import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion_luz/services/categoria_service.dart';
import 'package:aplicacion_luz/services/publicacion_service.dart';
import 'package:aplicacion_luz/models/categoria_model.dart';
import 'package:aplicacion_luz/models/publicacion_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CrearPublicacionPage extends StatefulWidget {
  final Publicacion? publicacionExistente;

  const CrearPublicacionPage({Key? key, this.publicacionExistente})
    : super(key: key);

  @override
  State<CrearPublicacionPage> createState() => _CrearPublicacionPageState();
}

class _CrearPublicacionPageState extends State<CrearPublicacionPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  final _imagenController =
      TextEditingController(); // Nuevo controlador para la URL de la imagen
  String? _categoriaSeleccionada;
  bool _esAnonimo = false;
  bool _isLoading = false;
  late CategoriaService _categoriaService;
  List<Categoria> _categorias = [];
  int _selectedIndex = 1; // Índice para "Mis Publicaciones"

  @override
  void initState() {
    super.initState();
    if (widget.publicacionExistente != null) {
      _tituloController.text = widget.publicacionExistente!.titulo;
      _contenidoController.text = widget.publicacionExistente!.contenido;
      _imagenController.text =
          widget.publicacionExistente!.imagenUrl ??
          ''; // Cargar URL de la imagen
      _categoriaSeleccionada = widget.publicacionExistente!.categoriaId;
      _esAnonimo = widget.publicacionExistente!.esAnonimo;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _categoriaService = Provider.of<CategoriaService>(context, listen: false);
    _cargarCategorias();
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

  Future<void> _cargarCategorias() async {
    final categorias = await _categoriaService.obtenerCategorias();
    setState(() {
      _categorias = categorias;
    });
  }

  Future<void> _guardarPublicacion() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final service = Provider.of<PublicacionService>(context, listen: false);

      try {
        if (widget.publicacionExistente == null) {
          await service.crearPublicacion(
            categoriaId: _categoriaSeleccionada!,
            titulo: _tituloController.text,
            contenido: _contenidoController.text,
            imagenUrl: _imagenController.text, // Pasar el enlace de la imagen
            esAnonimo: _esAnonimo,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Publicación creada con éxito'),
              backgroundColor: Colors.black,
            ),
          );
        } else {
          await service.actualizarPublicacion(
            publicacionId: widget.publicacionExistente!.id,
            categoriaId: _categoriaSeleccionada!,
            titulo: _tituloController.text,
            contenido: _contenidoController.text,
            imagenUrl: _imagenController.text, // Pasar el enlace de la imagen
            esAnonimo: _esAnonimo,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Publicación actualizada con éxito'),
              backgroundColor: Colors.black,
            ),
          );
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    _imagenController.dispose(); // Liberar el controlador de imagen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.publicacionExistente == null
              ? 'Crear Publicación'
              : 'Editar Publicación',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  labelStyle: const TextStyle(color: Colors.black),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contenidoController,
                decoration: InputDecoration(
                  labelText: 'Contenido',
                  labelStyle: const TextStyle(color: Colors.black),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese el contenido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imagenController,
                decoration: InputDecoration(
                  labelText: 'URL de la imagen (Opcional)',
                  labelStyle: const TextStyle(color: Colors.black),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  labelStyle: const TextStyle(color: Colors.black),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                items: _categorias.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria.id,
                    child: Text(
                      categoria.nombre,
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _categoriaSeleccionada = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, seleccione una categoría';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text(
                  'Publicar anónimamente',
                  style: TextStyle(color: Colors.black),
                ),
                value: _esAnonimo,
                onChanged: (bool value) {
                  setState(() {
                    _esAnonimo = value;
                  });
                },
                activeColor: Colors.black,
                activeTrackColor: Colors.grey.shade300,
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.shade300,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : ElevatedButton(
                      onPressed: _guardarPublicacion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        widget.publicacionExistente == null
                            ? 'Crear Publicación'
                            : 'Actualizar Publicación',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ],
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
}
