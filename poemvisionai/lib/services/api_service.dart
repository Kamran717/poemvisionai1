import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/creation.dart';
import '../models/membership.dart';
import '../config/api_config.dart';
import 'session_service.dart';
import 'dart:math';

class ApiService {
  final String? _token;
  final bool _useMockData; // Flag to use mock data when API is unavailable
  late SessionService _sessionService;

  ApiService({String? token, bool useMockData = false}) 
      : _token = token,
        _useMockData = useMockData;

  Future<void> _initSession() async {
    _sessionService = await SessionService.getInstance();
  }

  Future<Map<String, String>> get _headers async {
    await _initSession();
    
    Map<String, String> headers;
    if (_token != null) {
      headers = ApiConfig.getAuthHeaders(_token!);
    } else {
      headers = ApiConfig.defaultHeaders;
    }
    
    // Add session information
    return _sessionService.addSessionHeaders(headers);
  }

  Future<void> _handleResponse(http.Response response) async {
    await _initSession();
    
    // Extract and store session cookie if present
    final sessionCookie = _sessionService.extractSessionCookie(response.headers);
    if (sessionCookie != null) {
      await _sessionService.setSessionCookie(sessionCookie);
    }
  }

  // Authentication methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (_useMockData) {
      // Return mock login response
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      return {
        'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': 1,
        'email': email,
        'username': email.split('@').first,
      };
    }

    // Initialize session service first
    await _initSession();

    // Flask expects form data, not JSON
    final response = await http.post(
      Uri.parse(ApiConfig.loginEndpoint),
      headers: ApiConfig.formHeaders,
      body: {
        'email': email,
        'password': password,
      },
    );

    await _handleResponse(response);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        // Flask uses session-based auth, return mock token for compatibility
        return {
          'token': 'session_token_${DateTime.now().millisecondsSinceEpoch}',
          'user_id': 1, // Flask doesn't return user_id in login response
          'email': email,
          'username': email.split('@').first,
          'success': true,
        };
      } else {
        throw Exception(responseData['error'] ?? 'Login failed');
      }
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to login: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    if (_useMockData) {
      // Return mock register response
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      return {
        'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': 1,
        'email': email,
        'username': username,
      };
    }

    // Flask expects form data, not JSON
    final response = await http.post(
      Uri.parse(ApiConfig.registerEndpoint),
      headers: ApiConfig.formHeaders,
      body: {
        'username': username,
        'email': email,
        'password': password,
        'confirm_password': password, // Flask expects this field
      },
    );

    await _handleResponse(response);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        // Flask registration is successful, return mock token for compatibility
        return {
          'token': 'session_token_${DateTime.now().millisecondsSinceEpoch}',
          'user_id': 1,
          'email': email,
          'username': username,
          'success': true,
          'message': responseData['message'],
        };
      } else {
        throw Exception(responseData['error'] ?? 'Registration failed');
      }
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to register: ${response.body}');
    }
  }

  Future<void> requestPasswordReset(String email) async {
    if (_useMockData) {
      // Simulate password reset request
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    // Flask expects form data for password reset
    final response = await http.post(
      Uri.parse(ApiConfig.forgotPasswordEndpoint),
      headers: ApiConfig.formHeaders,
      body: {
        'email': email,
      },
    );

    await _handleResponse(response);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] != true) {
        throw Exception(responseData['error'] ?? 'Failed to request password reset');
      }
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to request password reset: ${response.body}');
    }
  }

  Future<void> resetPassword(String token, String password) async {
    if (_useMockData) {
      // Simulate password reset
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    // Flask expects form data for password reset
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/reset-password/$token'),
      headers: ApiConfig.formHeaders,
      body: {
        'token': token,
        'password': password,
        'confirm_password': password,
      },
    );

    await _handleResponse(response);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] != true) {
        throw Exception(responseData['error'] ?? 'Failed to reset password');
      }
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to reset password: ${response.body}');
    }
  }

  // User methods
  Future<User> getUserProfile() async {
    if (_useMockData) {
      // Return mock user profile
      await Future.delayed(const Duration(seconds: 1));
      return User(
        id: 1,
        email: 'user@example.com',
        username: 'demouser',
        isPremium: false,
      );
    }

    final headers = await _headers;
    
    // Add Accept header to request JSON response
    final jsonHeaders = Map<String, String>.from(headers);
    jsonHeaders['Accept'] = 'application/json';
    jsonHeaders['X-Requested-With'] = 'XMLHttpRequest';
    
    print('Sending request to profile endpoint: ${ApiConfig.userProfileEndpoint}');
    print('Request headers: $jsonHeaders');
    
    final response = await http.get(
      Uri.parse(ApiConfig.userProfileEndpoint),
      headers: jsonHeaders,
    );

    await _handleResponse(response);

    print('Profile response status: ${response.statusCode}');
    print('Profile response body preview: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

    if (response.statusCode == 200) {
      // Check if response is HTML (Flask returns HTML profile page)
      if (response.body.trim().startsWith('<!DOCTYPE html') || 
          response.body.trim().startsWith('<html')) {
        throw Exception('Backend returned HTML instead of JSON. Please ensure you are logged in and the API is configured correctly.');
      }
      
      try {
        final responseData = jsonDecode(response.body);
        
        // Backend returns user data nested in a 'user' field
        if (responseData is Map<String, dynamic> && responseData.containsKey('user')) {
          final userData = responseData['user'] as Map<String, dynamic>;
          return User.fromJson(userData);
        } else {
          // Fallback: assume responseData is the user object directly
          return User.fromJson(responseData);
        }
      } catch (e) {
        print('Error parsing user profile response: $e');
        print('Response body: ${response.body}');
        throw Exception('Failed to parse user profile response: $e');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    } else if (response.statusCode == 403) {
      throw Exception('Access denied. Please check your permissions.');
    } else {
      throw Exception('Failed to get user profile: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    if (_useMockData) {
      // Return mock user stats
      await Future.delayed(const Duration(seconds: 1));
      return {
        'total_creations': 5,
        'time_saved': {
          'total_minutes': 120,
          'hours': 2,
          'minutes': 0,
          'formatted': '2 hours and 0 minutes'
        },
        'poem_counts': {
          'short': 2,
          'medium': 2,
          'long': 1,
          'total': 5
        }
      };
    }

    final headers = await _headers;
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/user/stats'),
      headers: headers,
    );

    await _handleResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user stats: ${response.body}');
    }
  }

  // Creation methods
  Future<Creation> uploadImage(String base64Image, Map<String, dynamic> preferences) async {
    if (_useMockData) {
      // Return mock creation
      await Future.delayed(const Duration(seconds: 2)); // Longer delay to simulate image processing
      return Creation(
        id: Random().nextInt(1000),
        imageData: base64Image,
        createdAt: DateTime.now(),
      );
    }

    print('Uploading image to server...');
    print('Image data length: ${base64Image.length} characters');
    
    final headers = await _headers;
    final response = await http.post(
      Uri.parse(ApiConfig.analyzeImageEndpoint),
      headers: headers,
      body: jsonEncode({
        'image': base64Image,  // Flask expects this exact field name
        'preferences': preferences,
      }),
    );

    // Handle session management
    await _handleResponse(response);

    print('Server response status: ${response.statusCode}');
    print('Server response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      
      // Flask returns: {"success": true, "analysisId": "abc123", "results": {...}}
      // We need to create a temporary Creation object with the analysis ID
      if (responseData['success'] == true && responseData['analysisId'] != null) {
        final analysisId = responseData['analysisId'] as String;
        print('Received analysisId from server: $analysisId');
        
        // Store the temporary creation data in session for later retrieval
        await _sessionService.storeTempCreation(analysisId, {
          'imageData': base64Image,
          'analysisResults': responseData['results'],
          'preferences': preferences,
        });
        
        // Create a temporary Creation object with the available data
        return Creation(
          id: analysisId.hashCode, // Use hash of analysisId as temporary ID
          imageData: base64Image,
          analysisResults: responseData['results'],
          shareCode: analysisId, // Store analysisId here temporarily
          createdAt: DateTime.now(),
        );
      } else {
        throw Exception('Invalid response format: ${response.body}');
      }
    } else {
      throw Exception('Failed to analyze image: ${response.body}');
    }
  }

  Future<Creation> generatePoem(String analysisId, Map<String, dynamic> poemPreferences) async {
    if (_useMockData) {
      // Return mock poem
      await Future.delayed(const Duration(seconds: 2)); // Longer delay to simulate poem generation
      return Creation(
        id: analysisId.hashCode,
        imageData: 'mock_image_data',
        poemText: _generateMockPoem(poemPreferences['poem_type'] ?? 'sonnet'),
        poemType: poemPreferences['poem_type'] ?? 'sonnet',
        createdAt: DateTime.now(),
      );
    }

    final requestBody = {
      'analysisId': analysisId,
      'poemType': poemPreferences['poem_type'] ?? 'sonnet',
      'poemLength': poemPreferences['poem_length'] ?? 'short',
      'emphasis': poemPreferences['emphasis'] ?? [],
      'customPrompt': poemPreferences['custom_prompt'] ?? {},
      'isRegeneration': poemPreferences['is_regeneration'] ?? false,
    };

    print('Sending poem generation request with body: ${jsonEncode(requestBody)}');
    print('Using analysisId: $analysisId');

    final headers = await _headers;
    final response = await http.post(
      Uri.parse(ApiConfig.generatePoemEndpoint),
      headers: headers,
      body: jsonEncode(requestBody),
    );

    // Handle session management
    await _handleResponse(response);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true && responseData['poem'] != null) {
        // Try to get stored image data from session
        final tempCreation = _sessionService.getTempCreation(analysisId);
        final imageData = tempCreation?['imageData'] ?? 'temp_image_data';
        
        // Return creation with the poem and actual image data
        return Creation(
          id: analysisId.hashCode,
          imageData: imageData,
          poemText: responseData['poem'],
          poemType: poemPreferences['poem_type'],
          poemLength: poemPreferences['poem_length'],
          createdAt: DateTime.now(),
        );
      } else {
        throw Exception('Invalid poem generation response: ${response.body}');
      }
    } else {
      throw Exception('Failed to generate poem: ${response.body}');
    }
  }

  Future<Creation> createFinalImage(String analysisId, String frameStyle) async {
    if (_useMockData) {
      // Return mock final creation with framed image
      await Future.delayed(const Duration(seconds: 3)); // Longer delay to simulate image processing
      return Creation(
        id: analysisId.hashCode,
        imageData: 'mock_image_data',
        poemText: _generateMockPoem('sonnet'),
        poemType: 'sonnet',
        frameStyle: frameStyle,
        finalImageData: 'mock_final_image_data_with_frame',
        shareCode: 'MOCK${Random().nextInt(10000)}',
        createdAt: DateTime.now(),
      );
    }

    final requestBody = {
      'analysisId': analysisId,
      'frameStyle': frameStyle,
    };

    print('Creating final image with frame: $frameStyle');
    print('Using analysisId: $analysisId');

    final headers = await _headers;
    final response = await http.post(
      Uri.parse(ApiConfig.createFinalImageEndpoint),
      headers: headers,
      body: jsonEncode(requestBody),
    );

    // Handle session management
    await _handleResponse(response);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true && responseData['finalImage'] != null) {
        // Try to get stored creation data from session
        final tempCreation = _sessionService.getTempCreation(analysisId);
        final imageData = tempCreation?['imageData'] ?? 'temp_image_data';
        final poemText = tempCreation?['poemText'] ?? 'Generated poem text';
        
        // Return complete creation with final framed image
        return Creation(
          id: responseData['creationId'] ?? analysisId.hashCode,
          imageData: imageData,
          poemText: poemText,
          frameStyle: frameStyle,
          finalImageData: responseData['finalImage'],
          shareCode: responseData['shareCode'],
          createdAt: DateTime.now(),
        );
      } else {
        throw Exception('Invalid final image response: ${response.body}');
      }
    } else {
      throw Exception('Failed to create final image: ${response.body}');
    }
  }

  Future<List<Creation>> getUserCreations() async {
    try {
      // Initialize session service first
      await _initSession();
      
      // Ensure we have proper JSON headers to get JSON response from Flask
      final baseHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',  // This is crucial for Flask to return JSON
        'X-Requested-With': 'XMLHttpRequest',  // Additional hint that this is an API request
      };
      
      // Use session-based authentication (cookies) instead of Bearer tokens
      final headers = await _sessionService.addSessionHeaders(baseHeaders);
      
      print('Sending request to: ${ApiConfig.userPoemsEndpoint}');
      print('Request headers: $headers');
      
      final response = await http.get(
        Uri.parse(ApiConfig.userPoemsEndpoint),
        headers: headers,
      );

      await _handleResponse(response);

      print('Server response status: ${response.statusCode}');
      print('Server response body preview: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

      if (response.statusCode == 200) {
        // Check if response is HTML (Flask returns HTML profile page)
        if (response.body.trim().startsWith('<!DOCTYPE html') || 
            response.body.trim().startsWith('<html')) {
          // Flask returns HTML for the profile page, but we need JSON data
          // Return empty list for now to avoid crashes
          print('Gallery endpoint returns HTML instead of JSON, returning empty list');
          return [];
        }
        
        // If it's JSON, parse it
        final dynamic responseData = jsonDecode(response.body);
        
        // Handle different response formats
        List<dynamic> creationsData;
        if (responseData is List) {
          // Direct array response
          creationsData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          // Object response - check for common field names
          if (responseData.containsKey('creations')) {
            creationsData = responseData['creations'] as List<dynamic>;
          } else if (responseData.containsKey('data')) {
            creationsData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('poems')) {
            creationsData = responseData['poems'] as List<dynamic>;
          } else if (responseData.containsKey('success') && responseData['success'] == false) {
            // Handle error response
            throw Exception(responseData['error'] ?? 'Failed to retrieve creations');
          } else {
            // If it's a single creation object, wrap it in a list
            creationsData = [responseData];
          }
        } else {
          throw Exception('Unexpected response format: ${responseData.runtimeType}');
        }
        
        // Filter out any null entries and safely convert to Creation objects
        final validCreations = <Creation>[];
        for (final json in creationsData) {
          if (json != null && json is Map<String, dynamic>) {
            try {
              validCreations.add(Creation.fromJson(json));
            } catch (e) {
              print('Error parsing creation: $e, skipping entry');
              continue;
            }
          }
        }
        
        return validCreations;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Please check your permissions.');
      } else if (response.statusCode == 404) {
        throw Exception('User creations endpoint not found. Please check API configuration.');
      } else {
        throw Exception('Failed to get user creations: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getUserCreations: $e');
      // Re-throw the exception to show the actual error
      rethrow;
    }
  }

  Future<Creation> getCreationById(int creationId) async {
    if (_useMockData) {
      // Return mock creation
      await Future.delayed(const Duration(seconds: 1));
      return Creation(
        id: creationId,
        imageData: 'mock_image_data',
        poemText: _generateMockPoem('sonnet'),
        poemType: 'sonnet',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        viewCount: Random().nextInt(50),
        downloadCount: Random().nextInt(10),
      );
    }

    final headers = await _headers;
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/creations/$creationId'),
      headers: headers,
    );

    await _handleResponse(response);

    if (response.statusCode == 200) {
      return Creation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get creation: ${response.body}');
    }
  }

  Future<Creation> getCreationByShareCode(String shareCode) async {
    if (_useMockData) {
      // Return mock shared creation
      await Future.delayed(const Duration(seconds: 1));
      return Creation(
        id: Random().nextInt(1000),
        imageData: 'mock_image_data',
        poemText: _generateMockPoem('sonnet'),
        poemType: 'sonnet',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        shareCode: shareCode,
        viewCount: Random().nextInt(100),
        downloadCount: Random().nextInt(20),
      );
    }

    final headers = await _headers;
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/shared/$shareCode'),
      headers: headers,
    );

    await _handleResponse(response);

    if (response.statusCode == 200) {
      return Creation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get shared creation: ${response.body}');
    }
  }

  // Membership methods
  Future<List<Membership>> getMembershipPlans() async {
    if (_useMockData) {
      // Return mock membership plans
      await Future.delayed(const Duration(seconds: 1));
      return [
        Membership(
          id: 1,
          name: 'Free',
          price: 0.0,
          description: 'Basic features for casual users',
          maxPoemTypes: 2,
          maxFrameTypes: 3,
          maxSavedPoems: 5,
          hasGallery: false,
          createdAt: DateTime.now(),
        ),
        Membership(
          id: 2,
          name: 'Premium',
          price: 9.99,
          description: 'Advanced features for poetry enthusiasts',
          maxPoemTypes: 10,
          maxFrameTypes: 15,
          maxSavedPoems: 100,
          hasGallery: true,
          createdAt: DateTime.now(),
        ),
      ];
    }

    final headers = await _headers;
    final response = await http.get(
      Uri.parse(ApiConfig.membershipPlansEndpoint),
      headers: headers,
    );

    await _handleResponse(response);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Membership.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get membership plans: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createSubscription(int membershipId, String paymentMethodId) async {
    if (_useMockData) {
      // Return mock subscription response
      await Future.delayed(const Duration(seconds: 1));
      return {
        'subscription_id': 'mock_sub_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'active',
        'start_date': DateTime.now().toIso8601String(),
        'end_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'membership_id': membershipId,
      };
    }

    final headers = await _headers;
    final response = await http.post(
      Uri.parse(ApiConfig.upgradeEndpoint),
      headers: headers,
      body: jsonEncode({
        'membership_id': membershipId,
        'payment_method_id': paymentMethodId,
      }),
    );

    await _handleResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create subscription: ${response.body}');
    }
  }

  Future<void> cancelSubscription() async {
    if (_useMockData) {
      // Simulate subscription cancellation
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    final headers = await _headers;
    final response = await http.post(
      Uri.parse(ApiConfig.cancelSubscriptionEndpoint),
      headers: headers,
    );

    await _handleResponse(response);

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel subscription: ${response.body}');
    }
  }

  // Helper method to generate mock poems for demo purposes
  String _generateMockPoem(String poemType) {
    switch (poemType.toLowerCase()) {
      case 'sonnet':
        return '''
The gentle breeze of summer's sweet embrace,
Caresses fields of gold with tender might.
As butterflies in dance of airy grace,
Illuminate the day with pure delight.

Through ancient woods where shadows softly play,
The songbirds weave their melodies divine.
While streams of silver wind their winding way,
Through valleys deep where wildflowers shine.

When sunset paints the sky in amber hue,
And stars begin their nightly serenade,
The world transforms to scenes forever new,
As daylight hours gracefully do fade.

In nature's realm, such beauty does abound,
Where peace and wonder everywhere are found.
''';
      case 'haiku':
        return '''
Morning dewdrops shine
On petals kissed by sunlight
Nature awakens
''';
      case 'free verse':
        return '''
In the spaces between thoughts
I find you there, waiting,
Like the pause between heartbeats,
Essential yet overlooked.

How many times have I passed by
Without noticing the whispers of your presence?
The world spins madly on
While we stand still in moments of recognition.

Your eyes - windows to memories
We haven't yet created,
Promises of tomorrow
Wrapped in the gentle uncertainty of now.
''';
      case 'limerick':
        return '''
There once was a poet inspired,
Whose words were greatly admired.
    With pen in hand,
    Made verses so grand,
That listeners never grew tired.
''';
      case 'ode':
        return '''
O wondrous light that fills the morning sky,
That wakes the world from slumber deep and still,
Your golden rays that stretch from mountains high,
To valleys low with warming gentle will.

How faithfully you rise each brand new day,
Dispelling darkness with your brilliant glow.
Across the land your light makes shadows play,
As through the heavens your path you slowly go.
''';
      default:
        return '''
Words paint pictures in the mind,
Creating worlds of every kind.
Through language, we express and share,
The thoughts and feelings that we bear.
''';
    }
  }
}
