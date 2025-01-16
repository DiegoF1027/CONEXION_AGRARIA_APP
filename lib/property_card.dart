import 'package:flutter/material.dart';
import 'package:page_view_indicators/circle_page_indicator.dart';
import 'property_details.dart'; // Importa la nueva pantalla

class PropertyCard extends StatefulWidget {
  final dynamic property;

  const PropertyCard({super.key, required this.property});

  @override
  _PropertyCardState createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  final _currentPageNotifier = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    // Verifica que 'imagenes' no sea null y maneja la lista adecuadamente
    final List<String> imageUrls = widget.property['imagenes'] != null
        ? List<String>.from(widget.property['imagenes']
            .map((url) => url ?? 'lib/assets/default_image.png'))
        : [
            'lib/assets/default_image.png'
          ]; // Proporciona una lista con una imagen por defecto si es null

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetails(property: widget.property),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 0, // Elimina la sombra
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slider de imágenes utilizando PageView
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.2, // Mantiene el aspecto cuadrado
                  child: PageView.builder(
                    itemCount: imageUrls.length,
                    onPageChanged: (index) {
                      _currentPageNotifier.value =
                          index; // Actualiza el indicador de página
                    },
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(15.0),
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'lib/assets/default_image.png', // Imagen por defecto si falla la carga
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: CirclePageIndicator(
                    itemCount: imageUrls.length,
                    currentPageNotifier: _currentPageNotifier,
                  ),
                ),
              ],
            ),
            // Datos debajo de la imagen
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verifica que 'nombre' no sea null
                  Text(
                    widget.property['nombre'] ??
                        'Sin nombre', // Valor por defecto si es null
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 1), // Reduce el espacio aquí
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Verifica que 'departamento' y 'municipio' no sean null
                      Text(
                        '${(widget.property['departamento']?.join(', ') ?? 'Sin departamento')}, ${widget.property['municipio'] ?? 'Sin municipio'}',
                        style: const TextStyle(fontSize: 12), // Tamaño reducido
                      ),
                      // Verifica que 'precio_arriendo' no sea null
                      Text(
                        '${widget.property['precio_arriendo'] ?? 'Sin precio'}', // Muestra el precio de arriendo o un valor por defecto
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
