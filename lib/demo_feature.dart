const String googleMapDemoCode = '''

class GoogleMapDemoWithExplanation extends StatelessWidget {
    const GoogleMapDemoWithExplanation({super.key});

    @override
    Widget build(BuildContext context) {
      // A random location (e.g., New York City)
      LatLng randomLocation = const LatLng(40.7128, -74.0060);
      return Scaffold(
        appBar: AppBar(
          title: const Text('Google Maps Demo'),
        ),
        body: Column(
          children: [
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: randomLocation,
                  zoom: 14.0,
                ),
                markers: {
                   Marker(
                    markerId: const MarkerId('randomLocation'),
                    position: randomLocation,
                    infoWindow: const InfoWindow(title: 'Random Location'),
                  ),
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Show the explanation in a dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Explanation'),
                      content: const Text(
                          'To restore your original app:\\n\\n'
                          '1. Delete the added code for GoogleMapDemoWithExplanation in the main.dart file. \\n\\n'
                          '2. Uncomment the original main() function that was commented out.\\n\\n'
                          '3. Run the app again to see your original app.'),                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Explanation'),
            ),
          ],
        ),
      );
    }
}
// Replace runApp with GoogleMapDemoWithExplanation
void main() {
    /* Original main is commented out */
    runApp(const MaterialApp(
      home: GoogleMapDemoWithExplanation(),
    ));
}
    ''';
