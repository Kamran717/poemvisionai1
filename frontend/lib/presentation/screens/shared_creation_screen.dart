import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/presentation/common/app_header.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/services/service_locator.dart';

class SharedCreationScreen extends StatefulWidget {
  final String shareCode;

  const SharedCreationScreen({
    super.key,
    required this.shareCode,
  });

  @override
  State<SharedCreationScreen> createState() => _SharedCreationScreenState();
}

class _SharedCreationScreenState extends State<SharedCreationScreen> {
  final ApiClient _apiClient = serviceLocator.get<ApiClient>();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _creationData;

  @override
  void initState() {
    super.initState();
    _loadSharedCreation();
  }

  Future<void> _loadSharedCreation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      AppLogger.d('Loading shared creation with code: ${widget.shareCode}');
      
      // TODO: Implement shared creation loading
      // This is a placeholder until we implement the actual API call
      // In a real implementation, we would call:
      // final response = await _apiClient.getSharedCreation(widget.shareCode);
      
      // For now, we'll simulate a successful response after a delay
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _isLoading = false;
        _creationData = {
          'poem': 'This is a sample poem displayed for a shared creation.',
          'creatorUsername': 'PoemVision User',
        };
      });
    } catch (e) {
      AppLogger.e('Error loading shared creation: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load this creation. It may have been removed or is no longer available.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Creation'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadSharedCreation,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Shared by ${_creationData?['creatorUsername'] ?? 'Unknown'}',
            subtitle: 'A beautiful AI-generated poem based on an image',
          ),
          const SizedBox(height: 24),
          
          // Placeholder for image
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.image,
                size: 64,
                color: Colors.grey,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Poem display
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Poem',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _creationData?['poem'] ?? 'No poem available',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                onPressed: () {
                  // TODO: Implement sharing functionality
                  AppLogger.d('Share button pressed');
                },
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download'),
                onPressed: () {
                  // TODO: Implement download functionality
                  AppLogger.d('Download button pressed');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
