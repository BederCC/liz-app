import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion_luz/services/publicacion_service.dart';
import 'package:aplicacion_luz/services/categoria_service.dart';
import 'package:aplicacion_luz/models/publicacion_model.dart';
import 'package:aplicacion_luz/models/categoria_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TodasPublicacionesPage extends StatefulWidget {
  const TodasPublicacionesPage({super.key});

  @override
  State<TodasPublicacionesPage> createState() => _TodasPublicacionesPageState();
}

class _TodasPublicacionesPageState extends State<TodasPublicacionesPage> {
  final Map<String, bool> _comentariosExpandidos = {};
  final Map<String, TextEditingController> _comentarioControllers = {};
  final Map<String, bool> _localLikes = {};
  final Map<String, int> _localLikesCount = {};
  int _selectedIndex = 2;

  String? _categoriaSeleccionada;
  List<Categoria> _categorias = [];
  late CategoriaService _categoriaService;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _comentarioControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final publicacionService = Provider.of<PublicacionService>(context);

    Stream<QuerySnapshot> getPublicacionesStream() {
      if (_categoriaSeleccionada == null) {
        return FirebaseFirestore.instance
            .collection('publicaciones')
            .orderBy('fechaPublicacion', descending: true)
            .snapshots();
      } else {
        return FirebaseFirestore.instance
            .collection('publicaciones')
            .where('categoriaId', isEqualTo: _categoriaSeleccionada)
            .orderBy('fechaPublicacion', descending: true)
            .snapshots();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Todas las Publicaciones',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.indigo.shade50,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Filtrar por Categoría',
                  labelStyle: TextStyle(color: Colors.indigo.shade800),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.indigo.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.indigo, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black87),
                icon: Icon(Icons.arrow_drop_down, color: Colors.indigo),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas las categorías'),
                  ),
                  ..._categorias.map((categoria) {
                    return DropdownMenuItem(
                      value: categoria.id,
                      child: Text(categoria.nombre),
                    );
                  }).toList(),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _categoriaSeleccionada = newValue;
                  });
                },
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) => false,
                child: StreamBuilder<QuerySnapshot>(
                  stream: getPublicacionesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: Colors.indigo),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No hay publicaciones para mostrar.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs.elementAt(index);
                        final publicacionId = doc.id;
                        _comentariosExpandidos.putIfAbsent(
                          publicacionId,
                          () => false,
                        );
                        _comentarioControllers.putIfAbsent(
                          publicacionId,
                          () => TextEditingController(),
                        );

                        return PublicacionItem(
                          key: ValueKey(publicacionId),
                          doc: doc,
                          publicacionId: publicacionId,
                          service: publicacionService,
                          isCommentsExpanded:
                              _comentariosExpandidos[publicacionId] ?? false,
                          onToggleLike: () =>
                              _handleLike(publicacionService, publicacionId),
                          onToggleComments: () =>
                              _handleComments(publicacionId),
                          comentarioController:
                              _comentarioControllers[publicacionId]!,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey.shade600,
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

  Future<void> _handleLike(
    PublicacionService service,
    String publicacionId,
  ) async {
    final currentLikeStatus =
        _localLikes[publicacionId] ?? await service.hasUserLiked(publicacionId);
    final currentLikesCount =
        _localLikesCount[publicacionId] ??
        await service.getLikesCount(publicacionId);

    setState(() {
      _localLikes[publicacionId] = !currentLikeStatus;
      _localLikesCount[publicacionId] = currentLikeStatus
          ? (currentLikesCount ?? 0) - 1
          : (currentLikesCount ?? 0) + 1;
    });

    try {
      await service.toggleLike(publicacionId);
    } catch (e) {
      setState(() {
        _localLikes[publicacionId] = currentLikeStatus;
        _localLikesCount[publicacionId] = currentLikesCount;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar like: $e')));
    }
  }

  void _handleComments(String publicacionId) {
    setState(() {
      _comentariosExpandidos[publicacionId] =
          !(_comentariosExpandidos[publicacionId] ?? false);
    });
  }
}

class PublicacionItem extends StatelessWidget {
  final DocumentSnapshot doc;
  final String publicacionId;
  final PublicacionService service;
  final bool isCommentsExpanded;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleComments;
  final TextEditingController comentarioController;

  const PublicacionItem({
    super.key,
    required this.doc,
    required this.publicacionId,
    required this.service,
    required this.isCommentsExpanded,
    required this.onToggleLike,
    required this.onToggleComments,
    required this.comentarioController,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final fecha = (data['fechaPublicacion'] as Timestamp).toDate();
    final imagenUrl = data['imagenUrl'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(data, fecha),
          _buildContent(data),
          if (imagenUrl != null && imagenUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imagenUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
            ),
          _buildStats(context),
          const Divider(height: 1, thickness: 1, color: Colors.indigo),
          _buildActions(context),
          if (isCommentsExpanded) _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data, DateTime fecha) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(data['usuarioId'])
          .get(),
      builder: (context, userSnapshot) {
        final nombreUsuario = data['esAnonimo'] == true
            ? 'Anónimo'
            : (userSnapshot.data?.data() as Map<String, dynamic>?)?['nombre'] ??
                  'Usuario';

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.indigo.shade100,
                child: data['esAnonimo'] == true
                    ? Icon(Icons.person_outline, size: 28, color: Colors.indigo)
                    : Text(
                        nombreUsuario.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.indigo.shade800,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreUsuario,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy · HH:mm').format(fecha),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['titulo'] ?? 'Sin título',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['contenido'] ?? '',
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          StreamBuilder<int>(
            stream: service.getLikesCountStream(publicacionId),
            builder: (context, snapshot) {
              final likesCount = snapshot.data ?? 0;
              return Row(
                children: [
                  Icon(Icons.thumb_up, size: 16, color: Colors.indigo),
                  const SizedBox(width: 6),
                  Text(
                    likesCount.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('comentarios')
                .where('publicacionId', isEqualTo: publicacionId)
                .snapshots(),
            builder: (context, snapshot) {
              final commentCount = snapshot.data?.docs.length ?? 0;
              return Text(
                '$commentCount comentarios',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('publicaciones')
                .doc(publicacionId)
                .snapshots(),
            builder: (context, snapshot) {
              final likesCount =
                  snapshot.data?.data()?['likesCount'] as int? ?? 0;
              return StreamBuilder<bool>(
                stream: service.hasUserLikedStream(publicacionId),
                builder: (context, likeSnapshot) {
                  final hasLiked = likeSnapshot.data ?? false;
                  return TextButton.icon(
                    icon: Icon(
                      hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      color: hasLiked ? Colors.indigo : Colors.grey,
                    ),
                    label: Text(
                      'Me gusta ${likesCount > 0 ? '($likesCount)' : ''}',
                      style: TextStyle(
                        color: hasLiked ? Colors.indigo : Colors.grey,
                        fontWeight: hasLiked
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onPressed: onToggleLike,
                  );
                },
              );
            },
          ),
          TextButton.icon(
            icon: Icon(
              isCommentsExpanded
                  ? Icons.mode_comment
                  : Icons.mode_comment_outlined,
              color: isCommentsExpanded ? Colors.indigo : Colors.grey,
            ),
            label: Text(
              'Comentar',
              style: TextStyle(
                color: isCommentsExpanded ? Colors.indigo : Colors.grey,
                fontWeight: isCommentsExpanded
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            onPressed: onToggleComments,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: service.obtenerComentarios(publicacionId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: Colors.indigo),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No hay comentarios aún',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final comentario = snapshot.data!.elementAt(index);
                  final fecha = (comentario['fecha'] as Timestamp).toDate();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.indigo.shade50,
                          child: Text(
                            comentario['usuarioNombre']
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comentario['usuarioNombre'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comentario['contenido'],
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  DateFormat('dd MMM HH:mm').format(fecha),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: comentarioController,
              decoration: InputDecoration(
                hintText: 'Escribe un comentario...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.indigo, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.indigo,
            radius: 24,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () async {
                final contenido = comentarioController.text.trim();
                if (contenido.isNotEmpty) {
                  await service.agregarComentario(
                    publicacionId: publicacionId,
                    contenido: contenido,
                  );
                  comentarioController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

extension on Object? {
  void operator [](String other) {}
}
