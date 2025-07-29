import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion_luz/services/categoria_service.dart';
import 'package:aplicacion_luz/services/publicacion_service.dart';
import 'package:aplicacion_luz/models/categoria_model.dart';
import 'package:aplicacion_luz/models/publicacion_model.dart';

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
  String? _categoriaSeleccionada;
  bool _esAnonimo = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.publicacionExistente != null) {
      _tituloController.text = widget.publicacionExistente!.titulo;
      _contenidoController.text = widget.publicacionExistente!.contenido;
      _categoriaSeleccionada = widget.publicacionExistente!.categoriaId;
      _esAnonimo = widget.publicacionExistente!.esAnonimo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriaService = Provider.of<CategoriaService>(
      context,
      listen: false,
    );
    final publicacionService = Provider.of<PublicacionService>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.publicacionExistente == null
              ? 'Nueva Publicación'
              : 'Editar Publicación',
          style: TextStyle(color: Colors.pink.shade800),
        ),
        backgroundColor: Colors.pink.shade100,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.pink.shade800),
      ),
      body: Container(
        color: Colors.pink.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  FutureBuilder<List<Categoria>>(
                    future: categoriaService.obtenerCategorias(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.pink.shade600,
                          ),
                        );
                      }

                      final categorias = snapshot.data ?? [];

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonFormField<String>(
                            value: _categoriaSeleccionada,
                            hint: Text(
                              'Selecciona una categoría',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                            dropdownColor: Colors.white,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.pink.shade600,
                            ),
                            items: categorias.map((categoria) {
                              return DropdownMenuItem<String>(
                                value: categoria.id,
                                child: Text(
                                  categoria.nombre,
                                  style: TextStyle(color: Colors.grey.shade800),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _categoriaSeleccionada = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Debes seleccionar una categoría';
                              }
                              return null;
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _tituloController,
                      decoration: InputDecoration(
                        labelText: 'Título',
                        labelStyle: TextStyle(color: Colors.pink.shade600),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: TextStyle(color: Colors.grey.shade800),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa un título';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _contenidoController,
                      decoration: InputDecoration(
                        labelText: 'Contenido',
                        labelStyle: TextStyle(color: Colors.pink.shade600),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: TextStyle(color: Colors.grey.shade800),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el contenido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'Publicación anónima',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                      value: _esAnonimo,
                      activeColor: Colors.pink.shade600,
                      onChanged: (value) {
                        setState(() {
                          _esAnonimo = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _crearOActualizarPublicacion(
                            context,
                            publicacionService,
                          ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.pink.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : Text(
                            widget.publicacionExistente == null
                                ? 'Publicar'
                                : 'Actualizar',
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

  Future<void> _crearOActualizarPublicacion(
    BuildContext context,
    PublicacionService service,
  ) async {
    if (_formKey.currentState!.validate() && _categoriaSeleccionada != null) {
      setState(() => _isLoading = true);

      try {
        if (widget.publicacionExistente == null) {
          await service.crearPublicacion(
            categoriaId: _categoriaSeleccionada!,
            titulo: _tituloController.text,
            contenido: _contenidoController.text,
            esAnonimo: _esAnonimo,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Publicación creada con éxito'),
              backgroundColor: Colors.pink.shade600,
            ),
          );
        } else {
          await service.actualizarPublicacion(
            publicacionId: widget.publicacionExistente!.id,
            categoriaId: _categoriaSeleccionada!,
            titulo: _tituloController.text,
            contenido: _contenidoController.text,
            esAnonimo: _esAnonimo,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Publicación actualizada con éxito'),
              backgroundColor: Colors.pink.shade600,
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
    super.dispose();
  }
}
