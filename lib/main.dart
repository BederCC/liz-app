import 'dart:async';

import 'package:aplicacion_luz/pages/categorias_page.dart';
import 'package:aplicacion_luz/pages/perfil_usuario_page.dart';
import 'package:aplicacion_luz/pages/publicaciones/todas_publicaciones_page.dart';
import 'package:aplicacion_luz/pages/publicaciones_page.dart';
import 'package:aplicacion_luz/services/categoria_service.dart';
import 'package:aplicacion_luz/services/publicacion_service.dart';
import 'package:aplicacion_luz/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase inicializado correctamente");

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    try {
      await FirebaseFirestore.instance
          .collection('test')
          .doc('connection_test')
          .set({'timestamp': FieldValue.serverTimestamp()});
      print("Conexión a Firestore verificada correctamente");
    } catch (e) {
      print("Error al verificar conexión a Firestore: $e");
    }
  } catch (e) {
    print("Error crítico inicializando Firebase: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<UserService>(create: (_) => UserService()),
        Provider<CategoriaService>(create: (_) => CategoriaService()),
        Provider<PublicacionService>(create: (_) => PublicacionService()),
      ],
      child: MaterialApp(
        title: 'UniConnect',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: Colors.indigo.shade50,
          appBarTheme: const AppBarTheme(
            color: Colors.indigo,
            elevation: 4,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            labelStyle: TextStyle(color: Colors.indigo.shade800),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.indigo.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.indigo, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/perfil': (context) =>
              ProfilePage(user: FirebaseAuth.instance.currentUser!),
          '/publicaciones': (context) => const PublicacionesPage(),
          '/categorias': (context) => const CategoriasPage(),
          '/todas-publicaciones': (context) => const TodasPublicacionesPage(),
          '/perfil_usuario': (context) => const PerfilUsuarioPage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniConnect',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const AuthWrapper(),
      routes: {'/perfil': (context) => const PerfilUsuarioPage()},
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<void> _checkEmailVerification(User user) async {
    try {
      if (!user.emailVerified) {
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;
        if (updatedUser != null && updatedUser.emailVerified) {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(updatedUser.uid)
              .update({'verificado': true});
        }
      }
    } catch (e) {
      if (!e.toString().contains('PigeonUserInfo')) {
        print("Error verificando email: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.active) {
          final user = authSnapshot.data;
          if (user != null) {
            if (!user.emailVerified) {
              return EmailVerificationPage(user: user);
            }
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasData) {
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  final perfilCompleto = userData?['perfilCompleto'] ?? false;

                  _checkEmailVerification(user);
                  return ProfilePage(user: user);
                }
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            );
          }
          return const LoginPage();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showRegisterForm = false;

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      if (!email.endsWith('@khipu.edu.pe')) {
        setState(() {
          _errorMessage = 'Solo se permiten cuentas @khipu.edu.pe';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message ?? "Error al iniciar sesión";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    if (!email.endsWith('@khipu.edu.pe')) {
      setState(() {
        _errorMessage = 'Solo se permiten cuentas @khipu.edu.pe';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _passwordController.text.trim(),
          )
          .timeout(const Duration(seconds: 30));

      final user = userCredential.user;
      if (user == null) throw Exception("Usuario no creado");

      await user.sendEmailVerification();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro exitoso. Verifica tu email.'),
          duration: Duration(seconds: 5),
        ),
      );

      setState(() {
        _isLoading = false;
        _showRegisterForm = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? "Error al registrar");
    } catch (e) {
      setState(() => _errorMessage = "Error inesperado: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu correo electrónico');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo de recuperación enviado')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? "Error al enviar correo");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'UniConnect',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade800,
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu correo';
                        }
                        if (!value.endsWith('@khipu.edu.pe')) {
                          return 'Solo se permiten cuentas @khipu.edu.pe';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu contraseña';
                        }
                        if (_showRegisterForm && value.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    if (_showRegisterForm) ...[
                      const SizedBox(height: 20),
                      TextFormField(
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar Contraseña',
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 30),
              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.indigo),
                    )
                  : ElevatedButton(
                      onPressed: _showRegisterForm ? _register : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        _showRegisterForm ? 'Registrarse' : 'Iniciar Sesión',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showRegisterForm = !_showRegisterForm;
                    _errorMessage = null;
                  });
                },
                child: Text(
                  _showRegisterForm
                      ? '¿Ya tienes cuenta? Inicia sesión'
                      : 'Crear cuenta',
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: _resetPassword,
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(color: Colors.indigo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isVerificationEmailSending = false;
  bool _perfilCompleto = false;
  bool _loading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
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

  Future<void> _checkProfileStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.user.uid)
          .get();

      setState(() {
        _perfilCompleto = doc.exists;
        _loading = false;
      });

      if (!_perfilCompleto && mounted) {
        _showProfileCompletionDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
      print('Error verificando estado del perfil: $e');
    }
  }

  void _showProfileCompletionDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('¡Completa tu perfil!'),
          content: const Text(
            'Para acceder a todas las funciones de la aplicación, necesitamos que completes tu información personal.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToProfileUpdate();
              },
              child: const Text('Ir a completar perfil'),
            ),
          ],
        ),
      );
    });
  }

  void _navigateToProfileUpdate() {
    Navigator.pushNamed(context, '/perfil_usuario').then((_) {
      _checkProfileStatus();
    });
  }

  Future<void> _sendVerificationEmail() async {
    if (_isVerificationEmailSending) return;

    setState(() => _isVerificationEmailSending = true);

    try {
      await widget.user.sendEmailVerification();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo de verificación enviado'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar correo: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerificationEmailSending = false);
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Fecha desconocida';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.indigo.shade50,
        body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Mi Perfil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.indigo.shade800),
                  onPressed: _navigateToProfileUpdate,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.indigo.shade100,
                child: Icon(Icons.person, size: 60, color: Colors.indigo),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.user.email ?? 'No email',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Usuario desde: ${_formatDate(widget.user.metadata.creationTime)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 30),
            _buildVerificationStatus(),
            const SizedBox(height: 20),
            if (!_perfilCompleto) _buildProfileIncompleteWarning(),
            const SizedBox(height: 30),
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

  Widget _buildVerificationStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.user.emailVerified
            ? Colors.green.shade50
            : Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.user.emailVerified
              ? Colors.green.shade200
              : Colors.indigo.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.user.emailVerified ? Icons.verified : Icons.warning,
            color: widget.user.emailVerified
                ? Colors.green.shade700
                : Colors.indigo.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.user.emailVerified
                  ? 'Correo verificado'
                  : 'Correo no verificado',
              style: TextStyle(
                color: widget.user.emailVerified
                    ? Colors.green.shade700
                    : Colors.indigo.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!widget.user.emailVerified) ...[
            _isVerificationEmailSending
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.indigo,
                    ),
                  )
                : TextButton(
                    onPressed: _sendVerificationEmail,
                    child: Text(
                      'Enviar verificación',
                      style: TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileIncompleteWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.orange.shade700, size: 40),
          const SizedBox(height: 10),
          Text(
            'Perfil incompleto',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Debes completar tu información personal para acceder a todas las funciones.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _navigateToProfileUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text('Completar perfil ahora'),
          ),
        ],
      ),
    );
  }
}

class EmailVerificationPage extends StatefulWidget {
  final User user;
  const EmailVerificationPage({Key? key, required this.user}) : super(key: key);

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isVerificationEmailSending = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await widget.user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;
      if (updatedUser != null && updatedUser.emailVerified) {
        timer.cancel();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    if (_isVerificationEmailSending) return;

    setState(() => _isVerificationEmailSending = true);

    try {
      await widget.user.sendEmailVerification();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo de verificación enviado'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar correo: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerificationEmailSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email, color: Colors.indigo, size: 80),
              const SizedBox(height: 20),
              Text(
                'Verifica tu correo electrónico',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Se ha enviado un enlace de verificación a ${widget.user.email}. Por favor, revisa tu bandeja de entrada y haz clic en el enlace para continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 30),
              _isVerificationEmailSending
                  ? CircularProgressIndicator(color: Colors.indigo)
                  : ElevatedButton(
                      onPressed: _sendVerificationEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Reenviar correo de verificación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const AuthWrapper(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text(
                  'Volver a la pantalla de inicio',
                  style: TextStyle(color: Colors.indigo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
