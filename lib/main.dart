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
  String? errorMessage;
  bool isLoading = false;
  double progress = 0;

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
        errorMessage = 'Please select a project path and provide an API key.';
      });
      return;
    }

    // Start the progress and show loading indicator
    setState(() {
      isLoading = true;
      progress = 0.1;
    });

    try {
      // Step 1: Add the google_maps_flutter package
      await runFlutterCommand(['pub', 'add', 'google_maps_flutter']);
      debugPrint("Progress1: $progress");
      setState(() {
        progress = 0.4;
      });

      // Step 2: Add platform-specific configurations for Android and iOS
      await configurePlatformFiles(selectedPath!, apiKey!);
      debugPrint("Progress2: $progress");
      setState(() {
        progress = 0.6;
      });

      await modifyMainDartFile(selectedPath!).then((value) => {});
      debugPrint("Progress3: $progress");
      setState(() {
        progress = 0.8;
      });

      // Step 3: Success!
      setState(() {
        progress = 1.0;
        errorMessage = 'Package added and configured successfully!';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error2: $e';
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

  Future<void> modifyMainDartFile(String projectPath) async {
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

    String updatedContent = content.replaceFirstMapped(
      RegExp(r'void main\(\)[\s\S]*?\{[\s\S]*?\}'), // Match the main function
      (match) =>
          '/* ${match.group(0)} */', // Properly comment out the entire main function
    );

    String googleMapDemoCode = '''
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapDemoWithExplanation extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      // A random location (e.g., New York City)
      LatLng randomLocation = LatLng(40.7128, -74.0060);
      return Scaffold(
        appBar: AppBar(
          title: Text('Google Maps Demo'),
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
                    markerId: MarkerId('randomLocation'),
                    position: randomLocation,
                    infoWindow: InfoWindow(title: 'Random Location'),
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
                      title: Text('Explanation'),
                      content: Text(
                          'To restore your original app:\\n\\n'
                          '1. Delete the added code for GoogleMapDemoWithExplanation in the main.dart file.\\n'
                          '2. Uncomment the original main() function that was commented out.\\n'
                          '3. Run the app again to see your original app.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Explanation'),
            ),
          ],
        ),
      );
    }
}

// Replace runApp with GoogleMapDemoWithExplanation
void main() {
    /* Original main is commented out */
    runApp(MaterialApp(
      home: GoogleMapDemoWithExplanation(),
    ));
}
    ''';

    // Add the new main function and Google Maps demo page to the main.dart file
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown for selecting packages
            DropdownButton<String>(
              value: selectedPackage,
              onChanged: (value) {
                setState(() {
                  selectedPackage = value!;
                });
              },
              items: const [
                DropdownMenuItem(
                  value: 'google_maps_flutter',
                  child: Text('google_maps_flutter'),
                ),
                DropdownMenuItem(
                  value: 'other_package',
                  enabled: false,
                  child: Text('other_package (disabled)'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Path selector
            Row(
              children: [
                ElevatedButton(
                  onPressed: selectProjectPath,
                  child: const Text('Select Project Path'),
                ),
                const SizedBox(width: 10),
                Text(selectedPath ?? 'No path selected'),
              ],
            ),
            const SizedBox(height: 20),
            // API key input
            if (selectedPackage == 'google_maps_flutter')
              Column(
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
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
              onPressed: addPackage,
              child: const Text('Add Package'),
            ),
            const SizedBox(height: 20),
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
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
