import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion_luz/services/publicacion_service.dart';

class TodasPublicacionesPage extends StatefulWidget {
  const TodasPublicacionesPage({super.key});

  @override
  State<TodasPublicacionesPage> createState() => _TodasPublicacionesPageState();
}

class _TodasPublicacionesPageState extends State<TodasPublicacionesPage> {
  final Map<String, bool> _comentariosExpandidos = {};
  final Map<String, TextEditingController> _comentarioControllers = {};

  @override
  void dispose() {
    // Limpiar todos los controllers
    _comentarioControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final publicacionService = Provider.of<PublicacionService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todas las Publicaciones'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('publicaciones')
            .orderBy('fechaPublicacion', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay publicaciones disponibles'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final fecha = (data['fechaPublicacion'] as Timestamp).toDate();
              final publicacionId = doc.id;
              _comentariosExpandidos.putIfAbsent(publicacionId, () => false);
              _comentarioControllers.putIfAbsent(
                publicacionId,
                () => TextEditingController(),
              );

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(data['usuarioId'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final userData =
                      userSnapshot.data?.data() as Map<String, dynamic>?;
                  final nombreUsuario = data['esAnonimo'] == true
                      ? 'Anónimo'
                      : userData?['nombre'] ?? 'Usuario';

                  return FutureBuilder<Map<String, dynamic>>(
                    future: _getLikeData(publicacionService, publicacionId),
                    builder: (context, likeSnapshot) {
                      final likesCount = likeSnapshot.data?['count'] ?? 0;
                      final hasLiked = likeSnapshot.data?['hasLiked'] ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Encabezado con usuario y fecha
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.grey[200],
                                      child: data['esAnonimo'] == true
                                          ? const Icon(Icons.person, size: 20)
                                          : Text(
                                              nombreUsuario
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nombreUsuario,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            DateFormat(
                                              'dd MMM yyyy · HH:mm',
                                            ).format(fecha),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Contenido de la publicación
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['titulo'] ?? 'Sin título',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      data['contenido'] ?? '',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),

                              // Contador de reacciones y comentarios
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.thumb_up,
                                        size: 14,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      likesCount.toString(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const Spacer(),
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('comentarios')
                                          .where(
                                            'publicacionId',
                                            isEqualTo: publicacionId,
                                          )
                                          .snapshots(),
                                      builder: (context, commentSnapshot) {
                                        final commentCount =
                                            commentSnapshot.data?.docs.length ??
                                            0;
                                        return Text(
                                          '$commentCount comentarios',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // Divider
                              const Divider(height: 1, thickness: 1),

                              // Botones de acción
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildLikeButton(
                                      publicacionService,
                                      publicacionId,
                                      hasLiked,
                                    ),
                                    _buildCommentButton(publicacionId),
                                    _buildActionButton(
                                      icon: Icons.share_outlined,
                                      label: 'Compartir',
                                      color: Colors.grey,
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              ),

                              // Sección de comentarios (expandible)
                              if (_comentariosExpandidos[publicacionId] == true)
                                _buildComentariosSection(
                                  publicacionService,
                                  publicacionId,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCommentButton(String publicacionId) {
    return TextButton.icon(
      icon: Icon(
        _comentariosExpandidos[publicacionId] == true
            ? Icons.mode_comment
            : Icons.mode_comment_outlined,
        color: _comentariosExpandidos[publicacionId] == true
            ? Colors.blue
            : Colors.grey,
      ),
      label: Text(
        'Comentar',
        style: TextStyle(
          color: _comentariosExpandidos[publicacionId] == true
              ? Colors.blue
              : Colors.grey,
        ),
      ),
      onPressed: () {
        setState(() {
          _comentariosExpandidos[publicacionId] =
              !_comentariosExpandidos[publicacionId]!;
        });
      },
    );
  }

  Widget _buildComentariosSection(
    PublicacionService service,
    String publicacionId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Lista de comentarios
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('comentarios')
                .where('publicacionId', isEqualTo: publicacionId)
                .orderBy('fecha', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No hay comentarios aún'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final fecha = (data['fecha'] as Timestamp).toDate();

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(data['usuarioId'])
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const ListTile(
                          leading: CircleAvatar(),
                          title: Text('Cargando...'),
                        );
                      }

                      final userData =
                          userSnapshot.data?.data() as Map<String, dynamic>?;
                      final nombreUsuario = userData?['nombre'] ?? 'Usuario';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[200],
                          child: Text(
                            nombreUsuario.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombreUsuario,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              data['contenido'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          DateFormat('dd MMM HH:mm').format(fecha),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),

          // Formulario para nuevo comentario
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _comentarioControllers[publicacionId],
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () async {
                    final contenido = _comentarioControllers[publicacionId]!
                        .text
                        .trim();
                    if (contenido.isNotEmpty) {
                      await service.agregarComentario(
                        publicacionId: publicacionId,
                        contenido: contenido,
                      );
                      _comentarioControllers[publicacionId]!.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getLikeData(
    PublicacionService service,
    String publicacionId,
  ) async {
    final count = await service.getLikesCount(publicacionId);
    final hasLiked = await service.hasUserLiked(publicacionId);
    return {'count': count, 'hasLiked': hasLiked};
  }

  Widget _buildLikeButton(
    PublicacionService service,
    String publicacionId,
    bool hasLiked,
  ) {
    return TextButton.icon(
      icon: Icon(
        hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
        color: hasLiked ? Colors.blue : Colors.grey,
      ),
      label: Text(
        'Me gusta',
        style: TextStyle(color: hasLiked ? Colors.blue : Colors.grey),
      ),
      onPressed: () async {
        await service.toggleLike(publicacionId);
        setState(() {});
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      onPressed: onPressed,
    );
  }
}
