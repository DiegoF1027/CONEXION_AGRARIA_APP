import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login.dart'; // Importa tu pantalla de login

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  String _phone = '';
  String _documentNumber = '';
  bool _isLoading = true;

  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('Api/Users');

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    // Obtener datos del usuario desde Firebase Realtime Database
    DatabaseReference userRef = _database.child(user.uid);
    final snapshot = await userRef.get();

    if (snapshot.exists) {
      final userData = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _name = userData['nombre'] ?? 'No disponible';
        _email = user.email ?? 'No disponible';
        _phone = userData['telefono'] ?? 'No disponible';
        _documentNumber = userData['numero_documento'] ?? 'No disponible';
        _isLoading = false;
      });
    } else {
      setState(() {
        _name = user.displayName ?? 'No disponible';
        _email = user.email ?? 'No disponible';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile(String key, String value) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DatabaseReference userRef = _database.child(user.uid);

      if (key == 'email') {
        await user.updateEmail(value); // Cambiar el correo en FirebaseAuth
      }

      await userRef.update({key: value}); // Actualizar en Realtime Database
      setState(() {
        if (key == 'telefono') {
          _phone = value;
        } else if (key == 'email') {
          _email = value;
        }
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Editar perfil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // buildProfileAvatar(), // Eliminado
                  SizedBox(height: 30),
                  buildProfileItem(
                      context, 'Nombre de usuario', _name, Icons.person,
                      editable: false),
                  buildProfileItem(context, 'Correo electrónico', _email,
                      Icons.email),
                  buildProfileItem(context, 'Número de documento',
                      _documentNumber, Icons.badge, editable: false),
                  buildProfileItem(
                      context, 'Teléfono', _phone, Icons.phone),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _signOut,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildProfileItem(BuildContext context, String title, String value,
      IconData icon, {bool editable = true}) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      subtitle: Text(value),
      trailing: editable
          ? IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                String formattedTitle = formatTitle(title);
                showEditBottomSheet(context, formattedTitle, value);
              },
            )
          : null,
    );
  }

  String formatTitle(String title) {
    switch (title) {
      case 'Nombre de usuario':
        return 'nombre';
      case 'Correo electrónico':
        return 'email';
      case 'Número de documento':
        return 'numero_documento';
      case 'Teléfono':
        return 'telefono';
      default:
        return title.toLowerCase();
    }
  }

  void showEditBottomSheet(
      BuildContext context, String key, String currentValue) {
    TextEditingController controller =
        TextEditingController(text: currentValue);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Modificar el ${key == 'email' ? 'correo electrónico' : key}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.green), // Borde verde para el input
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.green), // Borde verde cuando no está enfocado
                  ),
                ),
              ),
              SizedBox(height: 24), // Espacio aumentado entre el input y los botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    child: Text(
                      'CANCELAR',
                      style: TextStyle(color: Color.fromARGB(255, 99, 101, 95)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text(
                      'GUARDAR',
                      style: TextStyle(
                          color: Colors.green), // Letras en verde
                    ),
                    onPressed: () {
                      _saveProfile(key, controller.text); // Guardar cambios
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

void main() => runApp(MaterialApp(
      home: ProfileScreen(),
    ));
