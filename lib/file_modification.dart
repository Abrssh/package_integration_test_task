import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_integration_test_task/demo_feature.dart';

Future<void> configurePlatformFiles(String projectPath, String apiKey) async {
  // Android configuration (modify AndroidManifest.xml)
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

  // iOS Configuration
  final appDelegatePath = '$projectPath/ios/Runner/AppDelegate.swift';
  try {
    final file = File(appDelegatePath);

    if (!await file.exists()) {
      throw Exception('AppDelegate.swift file not found.');
    }

    String content = await file.readAsString();

    if (!content.contains('import GoogleMaps')) {
      content = content.replaceFirst(
          'import Flutter', 'import Flutter\nimport GoogleMaps');
    }

    if (content.contains('GMSServices.provideAPIKey')) {
      content = content.replaceAll(
        RegExp(r'GMSServices\.provideAPIKey\("[^"]*"\)'),
        'GMSServices.provideAPIKey("$apiKey")',
      );
    } else {
      final pattern =
          RegExp(r'GeneratedPluginRegistrant\.register\(with: self\)');
      content = content.replaceFirst(
        pattern,
        'GMSServices.provideAPIKey("$apiKey")\n    GeneratedPluginRegistrant.register(with: self)',
      );
    }
    await file.writeAsString(content);
  } catch (e) {
    throw Exception('Failed to update AppDelegate.swift: $e');
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

  // Add the new code at the bottom of the file
  updatedContent += '\n\n$googleMapDemoCode';

  // Write the updated content back to the main.dart file
  await mainDartFile.writeAsString(updatedContent);

  debugPrint('Google Maps Demo with Explanation added to $mainDartPath.');
}
