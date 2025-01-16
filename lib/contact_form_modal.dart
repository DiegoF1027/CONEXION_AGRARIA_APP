import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Importa Firebase Realtime Database

class ContactFormModal extends StatefulWidget {
  final String propertyId;

  const ContactFormModal({Key? key, required this.propertyId}) : super(key: key);

  @override
  _ContactFormModalState createState() => _ContactFormModalState();
}

class _ContactFormModalState extends State<ContactFormModal> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _phone = '';
  // ignore: unused_field
  String _message = '';
  bool _isCheckingAuth = true; // Bandera para verificar autenticación
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('Api/Users'); // Referencia a la base de datos

  @override
  void initState() {
    super.initState();
    _checkUserAuth(); // Verifica si el usuario está autenticado
  }

  // Función para verificar si el usuario ha iniciado sesión
  Future<void> _checkUserAuth() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginDialog(); // Si no está autenticado, mostrar diálogo
    } else {
      // Obtener los datos del usuario desde Realtime Database
      DatabaseReference userRef = _database.child(user.uid);
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        final userData = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _email = user.email ?? '';
          _name = userData['nombre'] ?? '';
          _phone = userData['telefono'] ?? '';
          _isCheckingAuth = false; // Termina la verificación de autenticación
        });
      } else {
        setState(() {
          _email = user.email ?? '';
          _isCheckingAuth = false; // Termina la verificación de autenticación
        });
      }
    }
  }

  // Mostrar el diálogo para pedir inicio de sesión
  Future<void> _showLoginDialog() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false, // Evita que se cierre al tocar fuera del diálogo
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Inicia sesión o regístrate'),
            content: const Text(
              'Por favor, inicia sesión o regístrate para continuar.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo
                  Navigator.of(context).pop(); // Cierra el modal
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo
                  Navigator.of(context).pushReplacementNamed('/login'); // Redirige a login
                },
                child: const Text('Iniciar sesión'),
              ),
            ],
          );
        },
      );
    });
  }

  // Función para enviar el formulario
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      // Aquí iría la lógica para enviar el formulario (ejemplo de solicitud HTTP)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formulario enviado exitosamente')),
      );

      Navigator.of(context).pop(); // Cierra el modal después de enviar
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Center(child: CircularProgressIndicator());
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Contáctenos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    onSaved: (value) => _name = value ?? '',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su nombre';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    initialValue: _email,
                    decoration: const InputDecoration(labelText: 'Correo electrónico'),
                    onSaved: (value) => _email = value ?? '',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su correo electrónico';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    initialValue: _phone, // Carga el teléfono obtenido
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    keyboardType: TextInputType.phone,
                    onSaved: (value) => _phone = value ?? '',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su número de teléfono';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Mensaje'),
                    maxLines: 5,
                    onSaved: (value) => _message = value ?? '',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su mensaje';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Enviar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
