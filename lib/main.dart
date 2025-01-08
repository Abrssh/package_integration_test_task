import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PackageIntegrationScreen(),
    );
  }
}

class PackageIntegrationScreen extends StatefulWidget {
  const PackageIntegrationScreen({super.key});

  @override
  _PackageIntegrationScreenState createState() =>
      _PackageIntegrationScreenState();
}

class _PackageIntegrationScreenState extends State<PackageIntegrationScreen> {
  String selectedPackage = 'google_maps_flutter';
  String? selectedPath;
  String? apiKey;
  String? resultMessage;
  bool isLoading = false;
  double progress = 0;

  final TextEditingController apiKeyController = TextEditingController();

  void selectProjectPath() async {
    String? path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      setState(() {
        selectedPath = path;
      });
      debugPrint('path: $path selectedPath: $selectedPath');
    }
  }

  void addPackage() async {
    if (selectedPath == null || apiKey == null || apiKey!.isEmpty) {
      setState(() {
        resultMessage = 'Please select a project path and provide an API key.';
      });
      return;
    }

    // Start the progress and show loading indicator
    setState(() {
      isLoading = true;
      progress = 0.1;
    });

    try {
      // Step 1: Add platform-specific configurations for Android and iOS
      await configurePlatformFiles(selectedPath!, apiKey!);
      debugPrint("Progress1: $progress");
      setState(() {
        progress = 0.4;
      });

      // Step 2: Add the Google Maps Demo with Explanation
      await addDemoFeatureToApp(selectedPath!);
      debugPrint("Progress2: $progress");
      setState(() {
        progress = 0.6;
      });

      // Step 3: Add the google_maps_flutter package
      await runFlutterCommand(['pub', 'add', 'google_maps_flutter']);
      debugPrint("Progress3: $progress");
      setState(() {
        progress = 0.8;
      });

      // Step 4: Success!
      setState(() {
        progress = 1.0;
        resultMessage = 'Package added and configured successfully!';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        resultMessage = 'Error2: $e';
        isLoading = false;
      });
    }
  }

  Future<void> runFlutterCommand(List<String> arguments) async {
    // Execute the flutter command in the selected directory
    debugPrint("RunFlutterCommand Path: $selectedPath arguments: $arguments");

    // Get the full path to the Flutter executable
    String flutterPath = Platform.isWindows
        ? 'flutter.bat' // Use flutter.bat on Windows
        : 'flutter'; // Use flutter on macOS/Linux

    ProcessResult result = await Process.run(
      flutterPath,
      arguments,
      workingDirectory: selectedPath,
      runInShell:
          true, // This helps ensure the command runs in the system shell
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to run flutter command: ${result.stderr}');
    }
  }

  Future<void> configurePlatformFiles(String projectPath, String apiKey) async {
    // Android configuration (modify AndroidManifest.xml)
    // iOS configuration (modify Info.plist or AppDelegate.swift)
    // This logic will insert the necessary API key configurations

    // Android: Add to AndroidManifest.xml
    final androidManifestPath =
        '$projectPath/android/app/src/main/AndroidManifest.xml';
    final manifestFile = File(androidManifestPath);
    if (await manifestFile.exists()) {
      String content = await manifestFile.readAsString();

      // Check if API key meta-data already exists
      if (content.contains('android:name="com.google.android.geo.API_KEY"')) {
        // Replace existing API key
        content = content.replaceAll(
          RegExp(
              r'<meta-data android:name="com.google.android.geo.API_KEY" android:value="[^"]*"/>'),
          '<meta-data android:name="com.google.android.geo.API_KEY" android:value="$apiKey"/>',
        );
      } else {
        // Add new API key if it doesn't exist
        content = content.replaceAll(
          '</application>',
          '<meta-data android:name="com.google.android.geo.API_KEY" android:value="$apiKey"/>\n</application>',
        );
      }
      await manifestFile.writeAsString(content);
    } else {
      throw Exception('AndroidManifest.xml not found.');
    }

    // iOS: Add to Info.plist
    final infoPlistPath = '$projectPath/ios/Runner/Info.plist';
    final plistFile = File(infoPlistPath);
    if (await plistFile.exists()) {
      String content = await plistFile.readAsString();

      // Check if GMSApiKey already exists
      if (content.contains('<key>GMSApiKey</key>')) {
        // Replace existing API key
        content = content.replaceAll(
          RegExp(r'<key>GMSApiKey</key>\s*<string>[^<]*</string>'),
          '<key>GMSApiKey</key>\n<string>$apiKey</string>',
        );
      } else {
        // Add new API key if it doesn't exist
        content = content.replaceAll(
          '</dict>',
          '<key>GMSApiKey</key>\n<string>$apiKey</string>\n</dict>',
        );
      }
      await plistFile.writeAsString(content);
    } else {
      throw Exception('Info.plist not found.');
    }
  }

  Future<void> addDemoFeatureToApp(String projectPath) async {
    // Path to the main.dart file
    String mainDartPath = '$projectPath/lib/main.dart';

    // Read the current content of the main.dart file
    File mainDartFile = File(mainDartPath);
    String content = await mainDartFile.readAsString();

    // Check if the GoogleMapDemoWithExplanation class is already present
    if (content.contains('class GoogleMapDemoWithExplanation')) {
      debugPrint('Google Maps Demo code is already present in $mainDartPath.');
      return;
    }

    // Add import at the top of the file
    String importLine =
        "import 'package:google_maps_flutter/google_maps_flutter.dart';\n";
    String updatedContent = content;
    if (!content.contains(
        "import 'package:google_maps_flutter/google_maps_flutter.dart'")) {
      updatedContent = importLine + content;
    }

    // Comment out the original main function
    updatedContent = updatedContent.replaceFirstMapped(
      RegExp(r'void main\(\)[\s\S]*?\{[\s\S]*?\}'), // Match the main function
      (match) =>
          '/* ${match.group(0)} */', // Properly comment out the entire main function
    );

    String googleMapDemoCode = '''

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
                          '1. Delete the added code for GoogleMapDemoWithExplanation in the main.dart file.\\n'
                          '2. Uncomment the original main() function that was commented out.\\n'
                          '3. Run the app again to see your original app.'),
                      actions: [
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

    // Add the new code at the bottom of the file
    updatedContent += '\n\n$googleMapDemoCode';

    // Write the updated content back to the main.dart file
    await mainDartFile.writeAsString(updatedContent);

    debugPrint('Google Maps Demo with Explanation added to $mainDartPath.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Package Integration'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Dropdown for selecting packages
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
                child: Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedPackage = 'google_maps_flutter';
                          });
                        },
                        child: Card(
                          elevation:
                              selectedPackage == 'google_maps_flutter' ? 8 : 4,
                          color: selectedPackage == 'google_maps_flutter'
                              ? Colors.blue.shade50
                              : null,
                          margin: const EdgeInsets.only(right: 16),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.15,
                            height: MediaQuery.of(context).size.width * 0.15,
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Image.network(
                                    'https://developers.google.com/static/maps/images/google-maps-platform-1200x675.png',
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Google Maps Flutter',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedPackage = 'flutter_animate';
                          });
                        },
                        child: Card(
                          elevation:
                              selectedPackage == 'flutter_animate' ? 8 : 4,
                          color: selectedPackage == 'flutter_animate'
                              ? Colors.blue.shade50
                              : null,
                          margin: const EdgeInsets.only(right: 16),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.15,
                            height: MediaQuery.of(context).size.width * 0.15,
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Image.network(
                                    'https://docs.flutter.dev/assets/images/docs/development/packages-and-plugins/FlutterFavoriteLogo.png',
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                  ),
                                ),
                                const Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Flutter Animate',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Path selector
              Row(
                children: [
                  const SizedBox(width: 10),
                  Text(
                    selectedPath == null
                        ? 'No path selected'
                        : selectedPath!.length > 60
                            ? '${selectedPath!.substring(0, 20)}...${selectedPath!.substring(selectedPath!.length - 30)}'
                            : selectedPath!,
                  ),
                  const SizedBox(
                    width: 30,
                  ),
                  ElevatedButton(
                    onPressed: selectProjectPath,
                    child: const Text('Select Project Path'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // API key input
              if (selectedPackage == 'google_maps_flutter')
                Column(
                  children: [
                    TextField(
                      controller: apiKeyController,
                      onChanged: (value) {
                        setState(() {
                          apiKeyController.text = value;
                          apiKey = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Google Maps API Key',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        // Open Google Maps API Key URL
                        final Uri url = Uri.parse(
                            'https://developers.google.com/maps/documentation/android-sdk/get-api-key');
                        if (!await launchUrl(url)) {
                          throw Exception('Could not launch $url');
                        }
                      },
                      child: const Text('Get API Key'),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              // Add package button
              ElevatedButton(
                onPressed:
                    selectedPackage == 'google_maps_flutter' && apiKey != null
                        ? addPackage
                        : null,
                child: const Text('Add Package'),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      progress >= 0.4
                          ? 'Added Platform Specific Configurations Successfully!'
                          : 'Adding Platform Specific Configurations for $selectedPackage dependency...',
                      style: TextStyle(
                          fontSize: 16,
                          color: progress >= 0.4 ? Colors.green : Colors.black),
                    ),
                    const SizedBox(
                      width: 70,
                    ),
                    progress >= 0.4
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 25)
                        : SizedBox(
                            width: 20,
                            height: 20,
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2)
                                : null,
                          ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      progress >= 0.6
                          ? 'Added Demo Feature to the Main.dart file Successfully!'
                          : 'Adding Demo Feature to the Main.dart file ...',
                      style: TextStyle(
                          fontSize: 16,
                          color: progress >= 0.6 ? Colors.green : Colors.black),
                    ),
                    const SizedBox(
                      width: 70,
                    ),
                    progress >= 0.6
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 25)
                        : SizedBox(
                            width: 20,
                            height: 20,
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2)
                                : null,
                          ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      progress >= 0.8
                          ? '$selectedPackage added Successfully!'
                          : 'Running flutter pub add for $selectedPackage dependency...',
                      style: TextStyle(
                          fontSize: 16,
                          color: progress >= 0.8 ? Colors.green : Colors.black),
                    ),
                    const SizedBox(
                      width: 70,
                    ),
                    progress >= 0.8
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 25)
                        : SizedBox(
                            width: 20,
                            height: 20,
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2)
                                : null,
                          ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      progress == 1
                          ? 'Package added to your project successfully!'
                          : 'Adding $selectedPackage to your Project...',
                      style: TextStyle(
                          fontSize: 16,
                          color: progress == 1 ? Colors.green : Colors.black),
                    ),
                    const SizedBox(
                      width: 70,
                    ),
                    progress == 1
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 25)
                        : SizedBox(
                            width: 20,
                            height: 20,
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2)
                                : null,
                          ),
                  ],
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              // Progress indicator
              if (isLoading)
                Column(
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 10),
                    Text('Progress: ${(progress * 100).toInt()}%'),
                  ],
                ),
              // Error message
              if (resultMessage != null)
                Text(
                  progress != 1 ? "" : resultMessage!,
                  style: TextStyle(
                      color: progress == 1 ? Colors.green : Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
