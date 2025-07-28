import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PublicacionesPage extends StatelessWidget {
  const PublicacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Publicaciones')),
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
            const SizedBox(height: 10),
            Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            const Text(
              'Aquí podrás ver y gestionar todas tus publicaciones',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aquí añadirás la lógica para crear nuevas publicaciones después
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crear nueva publicación')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
