import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'property_card.dart';
import 'contact_form_modal.dart';
import 'map_screen.dart';
import 'profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> properties = [];
  bool isLoading = true;
  bool isError = false;
  bool isLoadingMore = false; // Indica si estamos cargando más propiedades
  int currentPage = 0; // Página actual para paginación
  int _selectedIndex = 0; // Se debe definir el índice de selección
  final ScrollController _scrollController =
      ScrollController(); // Controlador para detectar final del scroll

  @override
  void initState() {
    super.initState();
    fetchData(); // Cargar propiedades inicialmente
    _scrollController.addListener(() {
      // Detectar si el usuario llegó al final del scroll
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !isLoadingMore) {
        loadMoreData(); // Cargar más propiedades si estamos al final
      }
    });
  }

  // Método para cargar las propiedades iniciales
  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://us-central1-conexion-agraria.cloudfunctions.net/getCombinedData?page=$currentPage&limit=6'),
        headers: {
          'x-secret-key': 'supersecreta123', // Agrega tu clave secreta aquí
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          properties =
              json.decode(response.body); // Agregar las propiedades cargadas
          isLoading = false;
        });
      } else {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
      print('Error fetching data: $e');
    }
  }

  // Método para cargar más propiedades cuando se llega al final del scroll
  Future<void> loadMoreData() async {
    setState(() {
      isLoadingMore = true;
      currentPage++; // Aumentar la página para cargar la siguiente
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://us-central1-conexion-agraria.cloudfunctions.net/getCombinedData?page=$currentPage&limit=6'),
        headers: {
          'x-secret-key': 'supersecreta123',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          properties.addAll(
              json.decode(response.body)); // Agregar las nuevas propiedades
          isLoadingMore = false;
        });
      } else {
        setState(() {
          isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
      print('Error loading more data: $e');
    }
  }

  // Método para manejar la navegación del BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return const ContactFormModal(propertyId: '');
        },
      ).then((_) {
        setState(() {
          _selectedIndex = 0; // Volver a seleccionar "Explorar"
        });
      });
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MapScreen()),
      ).then((_) {
        setState(() {
          _selectedIndex = 0; // Volver a "Explorar" después de cerrar el Mapa
        });
      });
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      ).then((_) {
        setState(() {
          _selectedIndex = 0; // Volver a "Explorar" después de cerrar el Perfil
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('lib/assets/logo.png', height: 30),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : isError
                ? const Center(child: Text('Error al cargar los datos.'))
                : ListView.builder(
                    controller:
                        _scrollController, // Asignar el ScrollController
                    itemCount: properties.length +
                        (isLoadingMore
                            ? 1
                            : 0), // Agregar 1 si estamos cargando más
                    itemBuilder: (context, index) {
                      if (index == properties.length) {
                        return const Center(
                            child:
                                CircularProgressIndicator()); // Indicador de carga para más propiedades
                      }
                      return PropertyCard(
                          property:
                              properties[index]); // Mostrar cada propiedad
                    },
                  ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        iconSize: 24,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.travel_explore),
            label: 'Explorar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'Mapa',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            label: 'Contáctanos',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'lib/assets/icono_campecino2.webp', // Ruta correcta de la imagen
              width: 28,
              height: 28,
            ),
            label: 'Perfil',
          ),
        ],
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
