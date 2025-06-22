import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class PermissionDebugScreen extends StatefulWidget {
  const PermissionDebugScreen({super.key});

  @override
  State<PermissionDebugScreen> createState() => _PermissionDebugScreenState();
}

class _PermissionDebugScreenState extends State<PermissionDebugScreen> {
  final List<String> _logs = [];
  final ImagePicker _imagePicker = ImagePicker();

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    debugPrint(message);
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  Future<void> _checkAllPermissions() async {
    _addLog('=== CHECKING ALL PERMISSIONS ===');
    
    if (kIsWeb) {
      _addLog('Platform: Web - permissions not applicable');
      return;
    }
    
    _addLog('Platform: ${Platform.operatingSystem}');
    
    if (Platform.isAndroid) {
      await _checkAndroidPermissions();
    } else if (Platform.isIOS) {
      await _checkiOSPermissions();
    }
  }

  Future<void> _checkAndroidPermissions() async {
    _addLog('--- Android Permission Check ---');
    
    List<Permission> permissionsToCheck = [
      Permission.camera,
      Permission.storage,
      Permission.photos,
      Permission.mediaLibrary,
    ];
    
    for (Permission permission in permissionsToCheck) {
      try {
        final status = await permission.status;
        _addLog('${permission.toString()}: $status');
      } catch (e) {
        _addLog('${permission.toString()}: ERROR - $e');
      }
    }
  }

  Future<void> _checkiOSPermissions() async {
    _addLog('--- iOS Permission Check ---');
    
    List<Permission> permissionsToCheck = [
      Permission.camera,
      Permission.photos,
    ];
    
    for (Permission permission in permissionsToCheck) {
      try {
        final status = await permission.status;
        _addLog('${permission.toString()}: $status');
      } catch (e) {
        _addLog('${permission.toString()}: ERROR - $e');
      }
    }
  }

  Future<void> _requestPhotosPermission() async {
    _addLog('=== REQUESTING PHOTOS PERMISSION ===');
    try {
      final status = await Permission.photos.request();
      _addLog('Photos permission request result: $status');
    } catch (e) {
      _addLog('Photos permission request error: $e');
    }
  }

  Future<void> _requestStoragePermission() async {
    _addLog('=== REQUESTING STORAGE PERMISSION ===');
    try {
      final status = await Permission.storage.request();
      _addLog('Storage permission request result: $status');
    } catch (e) {
      _addLog('Storage permission request error: $e');
    }
  }

  Future<void> _testDirectImagePicker() async {
    _addLog('=== TESTING DIRECT IMAGE PICKER ===');
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _addLog('Direct image picker SUCCESS: ${pickedFile.path}');
        
        // Check if file exists
        final file = File(pickedFile.path);
        final exists = await file.exists();
        _addLog('File exists: $exists');
        
        if (exists) {
          final size = await file.length();
          _addLog('File size: $size bytes');
        }
      } else {
        _addLog('Direct image picker: User cancelled or no image selected');
      }
    } catch (e) {
      _addLog('Direct image picker ERROR: $e');
    }
  }

  Future<void> _openAppSettings() async {
    _addLog('=== OPENING APP SETTINGS ===');
    try {
      final opened = await openAppSettings();
      _addLog('App settings opened: $opened');
    } catch (e) {
      _addLog('Error opening app settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Debug'),
        backgroundColor: const Color(0xFF1B2A37),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1B2A37),
      body: SafeArea(
        child: Column(
          children: [
            // Control buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _checkAllPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7DA1BF),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Check Permissions'),
                  ),
                  ElevatedButton(
                    onPressed: _requestPhotosPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEDD050),
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('Request Photos'),
                  ),
                  ElevatedButton(
                    onPressed: _requestStoragePermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEDD050),
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('Request Storage'),
                  ),
                  ElevatedButton(
                    onPressed: _testDirectImagePicker,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8C7B9),
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('Test Image Picker'),
                  ),
                  ElevatedButton(
                    onPressed: _openAppSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            ),
            
            // Logs display
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF7DA1BF)),
                ),
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'No logs yet. Tap "Check Permissions" to start.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _logs[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
