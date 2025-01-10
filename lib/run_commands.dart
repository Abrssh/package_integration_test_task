import 'dart:io';

import 'package:flutter/material.dart';

Future<void> runFlutterCommand(
    List<String> arguments, String selectedPath) async {
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
    runInShell: true, // This helps ensure the command runs in the system shell
  );

  if (result.exitCode != 0) {
    throw Exception('Failed to run flutter command: ${result.stderr}');
  }
}

/// Function to check available devices/emulators
Future<List<String>> getAvailableDevices(String projectPath) async {
  String flutterPath = Platform.isWindows
      ? 'flutter.bat' // Use flutter.bat on Windows
      : 'flutter'; // Use flutter on macOS/Linux

  final result = await Process.run(flutterPath, ['devices'],
      workingDirectory: projectPath, runInShell: true);

  if (result.exitCode == 0) {
    debugPrint('Available devices:');
    debugPrint(result.stdout);
    final devicesOutput = result.stdout as String;
    final deviceList = <String>[];
    final lines = devicesOutput.split('\n');
    for (String line in lines) {
      if (line.trim().isNotEmpty) {
        final parts = line.split('•').map((s) => s.trim()).toList();
        if (parts.isNotEmpty) {
          final deviceInfo = parts[0].split(' ');
          if (deviceInfo.isNotEmpty) {
            final deviceId = deviceInfo[0].trim();
            // Filter for mobile devices (Android or iOS)
            if (deviceId.isNotEmpty &&
                !deviceId.contains('List') &&
                (line.toLowerCase().contains('android') ||
                    line.toLowerCase().contains('ios'))) {
              deviceList.add(deviceId);
            }
          }
        }
      }
    }
    return deviceList;
  } else {
    throw Exception('Error while listing devices: ${result.stderr}');
  }
}

/// Function to list available emulators
Future<List<String>> getAvailableEmulators(String selectedPath) async {
  String flutterPath = Platform.isWindows
      ? 'flutter.bat' // Use flutter.bat on Windows
      : 'flutter'; // Use flutter on macOS/Linux

  final result = await Process.run(flutterPath, ['emulators'],
      workingDirectory: selectedPath, runInShell: true);

  if (result.exitCode == 0) {
    debugPrint('Available emulators:');
    debugPrint(result.stdout.toString());

    final emulatorsOutput = result.stdout as String;
    final List<String> emulatorList = [];

    final lines = emulatorsOutput.split('\n');
    for (String line in lines) {
      if (line.trim().isNotEmpty) {
        final parts = line
            .split('â€¢')
            .map((s) => s.trim())
            .toList(); // Separating using 'â€¢'
        if (parts.length >= 2) {
          // Check if there are at least ID and Display Name
          final emulatorId = parts[0]; // Extract ID

          if (emulatorId.isNotEmpty) {
            emulatorList.add(emulatorId); // Add only ID to the list
          }
        }
      }
    }
    debugPrint('Emulator list: $emulatorList');
    return emulatorList;
  } else {
    throw Exception('Error while listing emulators: ${result.stderr}');
  }
}

/// Function to launch an available emulator
Future<void> launchEmulator(String projectPath) async {
  String flutterPath = Platform.isWindows ? 'flutter.bat' : 'flutter';
  debugPrint('No emulator running, attempting to launch one...');

  // List available emulators
  final emulatorList = await getAvailableEmulators(projectPath);
  debugPrint('Available emulators: $emulatorList');

  if (emulatorList.isNotEmpty) {
    final emulatorId =
        emulatorList.first; // Select the first available emulator
    debugPrint('Selected emulator: $emulatorId');

    // Wait until the emulator is fully launched
    bool isEmulatorRunning = false;

    final launchResult = await Process.run(
        flutterPath, ['emulators', '--launch', emulatorId],
        workingDirectory: projectPath, runInShell: true);

    if (launchResult.exitCode != 0) {
      throw Exception('Error launching emulator: ${launchResult.stderr}');
    }

    int checkCount = 0;
    while (!isEmulatorRunning) {
      if (checkCount == 4) {
        throw Exception('Failed to launch emulator.');
      }
      // Check for available devices
      List<String> devices = await getAvailableDevices(projectPath);
      // If empty try again upto 4 times
      if (devices.isEmpty) {
        await Future.delayed(
            const Duration(seconds: 5)); // Wait 5 seconds before checking again
        checkCount++;
      } else {
        isEmulatorRunning = true;
        debugPrint('Emulator $emulatorId is now running.');
      }
    }
  } else {
    throw Exception('No emulators available to launch.');
  }
}
