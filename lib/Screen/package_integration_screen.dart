import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_integration_test_task/file_modification.dart';
import 'package:package_integration_test_task/run_commands.dart';
import 'package:url_launcher/url_launcher.dart';

class PackageIntegrationScreen extends StatefulWidget {
  const PackageIntegrationScreen({super.key});

  @override
  PackageIntegrationScreenState createState() =>
      PackageIntegrationScreenState();
}

class PackageIntegrationScreenState extends State<PackageIntegrationScreen> {
  String selectedPackage = 'google_maps_flutter';
  String? selectedPath;
  String apiKey = "";
  String? resultMessage;
  bool isLoading = false;
  double progress = 0;
  bool runTheApp = false, appIsRunning = false;

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
    if (selectedPath == null || apiKey.isEmpty) {
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
      await configurePlatformFiles(selectedPath!, apiKey);
      debugPrint("Progress1: $progress");
      setState(() {
        progress = 0.2;
      });

      // Step 2: Add the Google Maps Demo with Explanation
      await addDemoFeatureToApp(selectedPath!);
      debugPrint("Progress2: $progress");
      setState(() {
        progress = 0.3;
      });

      // Step 3: Add the google_maps_flutter package
      await runFlutterCommand(
          ['pub', 'add', 'google_maps_flutter'], selectedPath!);
      debugPrint("Progress3: $progress");
      setState(() {
        progress = 0.5;
      });

      if (runTheApp) {
        await runFlutterApp(selectedPath!);
      }

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

  /// Function to run the Flutter app on an available device/emulator
  Future<void> runFlutterApp(String projectPath) async {
    debugPrint('Flutter App running');
    String flutterPath = Platform.isWindows ? 'flutter.bat' : 'flutter';

    // Check for available devices
    List<String> devices = await getAvailableDevices(projectPath);

    debugPrint('Available devices: $devices');
    setState(() {
      progress = 0.6;
    });

    // If no devices are found, try to launch an emulator
    if (devices.isEmpty) {
      await launchEmulator(projectPath);
      // Retry fetching devices after launching the emulator
      List<String> retryDevices = await getAvailableDevices(projectPath);
      if (retryDevices.isEmpty) {
        await Future.delayed(
            const Duration(seconds: 6)); // Wait 6 seconds before checking again
      }
      retryDevices = await getAvailableDevices(projectPath);

      if (retryDevices.isEmpty) {
        throw Exception('No devices/emulators available to run the app.');
      } else {
        devices.addAll(retryDevices);
      }
    }

    setState(() {
      progress = 0.8;
    });

    // Use the first available device if multiple devices are connected
    final deviceId = devices.isNotEmpty ? devices.first : null;

    // Run the Flutter app on the specified device
    final process = await Process.start(
      flutterPath,
      deviceId != null ? ['run', '-d', deviceId] : ['run'],
      workingDirectory: projectPath,
      runInShell: true,
    );

    // Listen for stdout and stderr
    process.stdout.transform(utf8.decoder).listen((data) {
      debugPrint(data);
      if (data.contains('Flutter run key commands.') ||
          data.contains('🔥  To hot restart')) {
        debugPrint('Flutter app is running successfully.');
        setState(() {
          appIsRunning = true;
          progress = 1.0;
          resultMessage = 'Package added and configured successfully!';
        });
      }
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      debugPrint('Error: $data');
    });

    // Handle process completion
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Flutter app failed to run with exit code: $exitCode');
    } else {
      setState(() {
        appIsRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
          title: const Text('Flutter Package Integration'),
          centerTitle: true,
          backgroundColor: Colors.grey.shade100),
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
                              ? null
                              : Colors.white,
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
                              ? null
                              : Colors.white,
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
              const SizedBox(height: 60),
              // Path selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            child: TextField(
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
                            child: const Row(
                              children: [
                                Icon(Icons.link),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  'Get API Key',
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // const SizedBox(height: 10),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: runTheApp,
                    onChanged: (value) {
                      setState(() {
                        runTheApp = value!;
                      });
                    },
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  const Text(
                    'Run app on a device or emulator',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Add package button
              ElevatedButton(
                onPressed: selectedPackage == 'google_maps_flutter' &&
                        apiKey.isNotEmpty &&
                        !isLoading &&
                        !appIsRunning
                    ? addPackage
                    : null,
                child: const Text('Add Package'),
              ),
              const SizedBox(height: 20),

              isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Text(
                            progress >= 0.2
                                ? 'Added Platform Specific Configurations Successfully!'
                                : 'Adding Platform Specific Configurations for $selectedPackage dependency...',
                            style: TextStyle(
                                fontSize: 16,
                                color: progress >= 0.2
                                    ? Colors.green
                                    : Colors.black),
                          ),
                          const SizedBox(
                            width: 70,
                          ),
                          progress >= 0.2
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
                    )
                  : const SizedBox(
                      height: 0,
                    ),

              isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Text(
                            progress >= 0.3
                                ? 'Added Demo Feature to the Main.dart file Successfully!'
                                : 'Adding Demo Feature to the Main.dart file ...',
                            style: TextStyle(
                                fontSize: 16,
                                color: progress >= 0.3
                                    ? Colors.green
                                    : Colors.black),
                          ),
                          const SizedBox(
                            width: 70,
                          ),
                          progress >= 0.3
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
                    )
                  : const SizedBox(
                      height: 0,
                    ),
              isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Text(
                            progress >= 0.5
                                ? '$selectedPackage added Successfully!'
                                : 'Running flutter pub add for $selectedPackage dependency...',
                            style: TextStyle(
                                fontSize: 16,
                                color: progress >= 0.5
                                    ? Colors.green
                                    : Colors.black),
                          ),
                          const SizedBox(
                            width: 70,
                          ),
                          progress >= 0.5
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
                    )
                  : const SizedBox(
                      height: 0,
                    ),

              isLoading && runTheApp
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Text(
                            progress >= 0.8
                                ? 'App build has started!'
                                : 'Getting ready to build app...',
                            style: TextStyle(
                                fontSize: 16,
                                color: progress >= 0.8
                                    ? Colors.green
                                    : Colors.black),
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
                    )
                  : const SizedBox(
                      height: 0,
                    ),
              isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                progress == 1
                                    ? '$selectedPackage added to your project Successfully!'
                                    : 'Waiting until app build finishes...',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: progress == 1
                                        ? Colors.green
                                        : Colors.black),
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
                          const Row(
                            children: [
                              Text("Exit running app to Add a Package Again"),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(
                      height: 0,
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
              if (resultMessage != null && !isLoading)
                Text(
                  resultMessage!,
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
