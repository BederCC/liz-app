import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TodasPublicacionesPage extends StatelessWidget {
  const TodasPublicacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                const Text(
                                  '125',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  '24 comentarios',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Divider
                          const Divider(height: 1, thickness: 1),

                          // Botones de acción
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  icon: Icons.thumb_up_outlined,
                                  label: 'Me gusta',
                                  color: Colors.grey,
                                ),
                                _buildActionButton(
                                  icon: Icons.mode_comment_outlined,
                                  label: 'Comentar',
                                  color: Colors.grey,
                                ),
                                _buildActionButton(
                                  icon: Icons.share_outlined,
                                  label: 'Compartir',
                                  color: Colors.grey,
                                ),
                              ],
                            ),
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
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return TextButton.icon(
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      onPressed: () {}, // Sin funcionalidad
    );
  }
}
