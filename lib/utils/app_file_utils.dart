import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AppFileUtils {
  // Singleton instance
  static final AppFileUtils _instance = AppFileUtils._internal();
  factory AppFileUtils() => _instance;
  AppFileUtils._internal();

  // Flag to track file system issues
  bool _hasFileSystemIssues = false;
  bool get hasFileSystemIssues => _hasFileSystemIssues;

  // Directory for app temporary files
  Directory? _appTempDir;

  // Add missing Java-related fields
  String? _javaHomePath;
  bool _javaHomeVerified = false;

  // Initialize file utility
  Future<void> initialize() async {
    try {
      _appTempDir = await getTemporaryDirectory();
      _hasFileSystemIssues = false;
    } catch (e) {
      print('Error initializing app file utils: $e');
      _hasFileSystemIssues = true;

      // Try to create an alternative temp directory
      try {
        final appDir = await getApplicationDocumentsDirectory();
        _appTempDir = Directory(path.join(appDir.path, 'temp'));
        if (!await _appTempDir!.exists()) {
          await _appTempDir!.create(recursive: true);
        }
      } catch (e) {
        print('Failed to create alternative temp directory: $e');
      }
    }
  }

  // Safe initialization that doesn't throw exceptions
  Future<void> safeInitialize() async {
    try {
      await initialize();
    } catch (e) {
      print('Error safely initializing app file utils: $e');
      _hasFileSystemIssues = true;
    }
  }

  // Get a safe temporary file path
  Future<String?> getSafeTempFilePath(String filename) async {
    if (_appTempDir == null) {
      // Try to initialize again
      await initialize();

      // If still null, return null
      if (_appTempDir == null) return null;
    }

    return path.join(_appTempDir!.path, filename);
  }

  // Safe write to file operation with fallbacks
  Future<bool> safeWriteFile(String content, String filename) async {
    try {
      final filePath = await getSafeTempFilePath(filename);
      if (filePath == null) return false;

      final file = File(filePath);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      print('Error writing file $filename: $e');
      return false;
    }
  }

  // Safe read from file operation with fallbacks
  Future<String?> safeReadFile(String filename) async {
    try {
      final filePath = await getSafeTempFilePath(filename);
      if (filePath == null) return null;

      final file = File(filePath);
      if (!await file.exists()) return null;

      return await file.readAsString();
    } catch (e) {
      print('Error reading file $filename: $e');
      return null;
    }
  }

  // Detect and verify Java installation
  Future<bool> verifyJavaInstallation() async {
    if (_javaHomeVerified) return true;

    try {
      // Try potential Java home paths
      final potentialPaths = [
        'C:\\Program Files\\Java\\jdk-11',
        'C:\\Program Files\\Java\\jdk-17',
        'C:\\Program Files\\Java\\jdk1.8.0',
        'C:\\Program Files (x86)\\Java\\jdk-11',
        'C:\\Program Files (x86)\\Java\\jdk-17',
        Platform.environment['JAVA_HOME'],
      ];

      for (final javaPath in potentialPaths) {
        if (javaPath == null || javaPath.isEmpty) continue;

        final javaDir = Directory(javaPath);
        if (await javaDir.exists()) {
          // Check for java.exe
          final javaExe = File('$javaPath\\bin\\java.exe');
          if (await javaExe.exists()) {
            _javaHomePath = javaPath;
            _javaHomeVerified = true;

            // Update gradle.properties with correct Java path
            await _updateGradleProperties();
            return true;
          }
        }
      }

      // If we get here, no valid Java home was found
      return false;
    } catch (e) {
      print('Error verifying Java installation: $e');
      return false;
    }
  }

  // Update gradle.properties with correct Java home
  Future<void> _updateGradleProperties() async {
    if (_javaHomePath == null) return;

    try {
      final gradlePropsFile = File('android/gradle.properties');
      if (!await gradlePropsFile.exists()) return;

      String content = await gradlePropsFile.readAsString();

      // Remove existing org.gradle.java.home lines
      final lines = content.split('\n');
      final updatedLines = lines.where(
        (line) => !line.trim().startsWith('org.gradle.java.home='),
      );

      // Add the correct Java home path with properly escaped backslashes
      final escapedPath = _javaHomePath!.replaceAll('\\', '\\\\');
      final updatedContent = [
        ...updatedLines,
        '# Updated by AppFileUtils',
        'org.gradle.java.home=$escapedPath',
      ].join('\n');

      await gradlePropsFile.writeAsString(updatedContent);
      print('Updated gradle.properties with Java home: $_javaHomePath');
    } catch (e) {
      print('Error updating gradle.properties: $e');
    }
  }

  // Show dialog for file system issues
  void showFileSystemIssueDialog(BuildContext context) {
    if (_hasFileSystemIssues) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('File System Access Issues'),
              content: Text(
                'Your app is experiencing file system permission issues. '
                'Some features may not work correctly. Please try running the '
                'force_clean.bat script with administrator privileges, or '
                'reinstall the app in a location with full access permissions.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Understood'),
                ),
              ],
            ),
      );
    }
  }

  // Alternative way to show file system issues via SnackBar
  void showFileSystemIssueSnackBar(BuildContext context) {
    if (_hasFileSystemIssues && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File system permission issues detected'),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Details',
            onPressed: () => showFileSystemIssueDialog(context),
          ),
        ),
      );
    }
  }

  // Show dialog for Java installation issues
  void showJavaInstallationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Java Installation Issue'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The app could not find a valid Java installation, which is required for building the release version.',
                ),
                SizedBox(height: 16),
                Text(
                  'Please ensure you have Java JDK 11 or newer installed and set the JAVA_HOME environment variable.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }
}
