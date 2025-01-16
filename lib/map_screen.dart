import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:convert'; // Para decodificar JSON
import 'package:http/http.dart' as http; // Para realizar solicitudes HTTP
import 'package:permission_handler/permission_handler.dart' as perm_handler;
import 'package:flutter/services.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(0, 0);
  final Location _location = Location();
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  final List<Map<String, dynamic>> _properties = [];
  int currentPage = 1;
  LatLngBounds? _mapBounds;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _fetchProperties(LatLngBounds bounds) async {
    try {
      final response = await http.get(
        Uri.parse('https://us-central1-conexion-agraria.cloudfunctions.net/getCombinedData?page=$currentPage&limit=6'),
        headers: {
          'x-secret-key': 'supersecreta123',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> propertiesData = json.decode(response.body);

        if (propertiesData.isEmpty) {
          _showSnackBar('No se encontraron predios en esta área.');
          return;
        }

        setState(() {
          _properties.clear();
          for (var property in propertiesData) {
            _properties.add({
              "id": property['id'],
              "name": property['nombre'],
              "lat": property['latitud'],
              "lng": property['longitud'],
              "description": property['descripcion'],
              "price": property['precio_arriendo'],
              "measure": property['medida'],
              "address": property['direccion'],
              "images": property['imagenes'] ?? [],
            });
          }
        });

        _addPropertyMarkers(bounds);
      } else {
        _showSnackBar('Error al obtener los predios: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error al obtener los predios: $e');
    }
  }

  void _addPropertyMarkers(LatLngBounds bounds) {
    _markers.clear();
    for (var property in _properties) {
      LatLng propertyLocation = LatLng(property['lat'], property['lng']);
      if (bounds.contains(propertyLocation)) {
        _markers.add(
          Marker(
            markerId: MarkerId(property['id']),
            position: propertyLocation,
            infoWindow: InfoWindow(
              title: property['name'],
              onTap: () {
                print('Marcador de ${property['name']} seleccionado');
                List<String> propertyImages = property['images'] ?? [];
                _onMarkerTapped(
                  property['name'],
                  property['description'],
                  property['price'],
                  property['measure'],
                  property['address'],
                  propertyImages,
                );
              },
            ),
          ),
        );
      }
    }
    setState(() {});
  }

  Future<void> _getUserLocation() async {
    perm_handler.PermissionStatus permission = await perm_handler.Permission.locationWhenInUse.status;

    if (!permission.isGranted) {
      permission = await perm_handler.Permission.locationWhenInUse.request();
      if (!permission.isGranted) {
        _showSnackBar('El permiso de ubicación ha sido denegado.');
        return;
      }
    }

    LocationData locationData;
    try {
      locationData = await _location.getLocation();
      LatLng userLocation = LatLng(locationData.latitude!, locationData.longitude!);

      setState(() {
        _initialPosition = userLocation;
        _isLoading = false;
      });

      _markers.add(
        Marker(
          markerId: const MarkerId('userLocation'),
          position: _initialPosition,
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
        ),
      );

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_initialPosition, 10),
      );

      _fetchProperties(_mapBounds!);
    } catch (e) {
      if (e is PlatformException) {
        _showSnackBar('Error obteniendo la ubicación: ${e.code}, ${e.message}');
      } else {
        _showSnackBar('Error obteniendo la ubicación: $e');
      }
    }
  }

void _onMarkerTapped(String name, String description, String price, String measure, String address, List<String> images) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.6,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('Descripción: $description'),
                const SizedBox(height: 10),
                Text('Precio: $price'),
                const SizedBox(height: 10),
                Text('Medida: $measure'),
                const SizedBox(height: 10),
                Text('Dirección: $address'),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: images.isNotEmpty
                      ? PageView.builder(
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              images[index],
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : const Center(child: Text('No hay imágenes disponibles')),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PropertyDetailsScreen(
                          name: name,
                          price: price,
                          measure: measure,
                          images: images,
                        ),
                      ),
                    );
                  },
                  child: const Text('Ver más detalles'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('lib/assets/logo.png', height: 30),
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 8,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              onCameraIdle: () async {
                LatLngBounds bounds = await _mapController!.getVisibleRegion();
                _mapBounds = bounds;
                _fetchProperties(bounds);
              },
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
    );
  }
}

class PropertyDetailsScreen extends StatelessWidget {
  final String name;
  final String price;
  final String measure;
  final List<String> images;

  const PropertyDetailsScreen({
    Key? key,
    required this.name,
    required this.price,
    required this.measure,
    required this.images,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: $name'),
            const SizedBox(height: 10),
            Text('Precio: $price'),
            const SizedBox(height: 10),
            Text('Medida: $measure'),
            const SizedBox(height: 20),
            Expanded(
              child: images.isNotEmpty
                  ? ListView.builder(
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Image.network(images[index]);
                      },
                    )
                  : const Text('No hay imágenes disponibles'),
            ),
          ],
        ),
      ),
    );
  }
}
