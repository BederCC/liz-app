import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PublicacionesPage extends StatelessWidget {
  const PublicacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Publicaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.pushNamed(context, '/categorias');
            },
            tooltip: 'Ver categorías',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.article, size: 50, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'Bienvenido a tus publicaciones',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/categorias');
              },
              child: const Text('Ver Categorías'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crear nueva publicación')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
