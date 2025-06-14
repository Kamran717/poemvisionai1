import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import '../models/user.dart';
import '../models/creation.dart';
import '../models/membership.dart';
import '../config/api_config.dart';
import 'dart:math';

class ApiService {
  final String? _token;
  final bool _useMockData; // Flag to use mock data when API is unavailable
  late final Dio _dio;
  static final CookieJar _cookieJar = CookieJar();

  ApiService({String? token, bool useMockData = false}) 
      : _token = token,
        _useMockData = useMockData {
    _dio = Dio();
    _dio.interceptors.add(CookieManager(_cookieJar));
    
    // Set default headers
    _dio.options.headers.addAll(_headers);
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
    _dio.options.sendTimeout = ApiConfig.sendTimeout;
  }

  Map<String, String> get _headers {
    if (_token != null) {
      return ApiConfig.getAuthHeaders(_token!);
    }
    return ApiConfig.defaultHeaders;
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

    try {
      final response = await _dio.post(
        ApiConfig.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to login: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to login: $e');
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

    try {
      final response = await _dio.post(
        ApiConfig.registerEndpoint,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to register: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  Future<void> requestPasswordReset(String email) async {
    if (_useMockData) {
      // Simulate password reset request
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    try {
      final response = await _dio.post(
        '${ApiConfig.apiBaseUrl}/auth/reset-password-request',
        data: {
          'email': email,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to request password reset: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to request password reset: $e');
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

    try {
      final response = await _dio.get(ApiConfig.userProfileEndpoint);

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      } else {
        throw Exception('Failed to get user profile: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
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

    try {
      final response = await _dio.get('${ApiConfig.apiBaseUrl}/user/stats');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get user stats: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to get user stats: $e');
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

    try {
      final response = await _dio.post(
        ApiConfig.analyzeImageEndpoint,
        data: {
          'image': base64Image,
          'preferences': preferences,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // Flask returns: {"success": true, "analysisId": "abc123", "results": {...}}
        // We need to create a temporary Creation object with the analysis ID
        if (responseData['success'] == true && responseData['analysisId'] != null) {
          print('Received analysisId from server: ${responseData['analysisId']}');
          
          // Create a temporary Creation object with the available data
          // Store the analysisId in shareCode for later use in poem generation
          return Creation(
            id: responseData['analysisId'].hashCode, // Use hash of analysisId as temporary ID
            imageData: base64Image,
            analysisResults: responseData['results'],
            shareCode: responseData['analysisId'], // Store analysisId here temporarily
            createdAt: DateTime.now(),
          );
        } else {
          throw Exception('Invalid response format: ${response.data}');
        }
      } else {
        throw Exception('Failed to analyze image: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
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
      'poemType': poemPreferences['poem_type'],
      'poemLength': poemPreferences['poem_length'],
      'emphasis': poemPreferences['emphasis'],
      'customPrompt': poemPreferences['custom_prompt'],
      'isRegeneration': poemPreferences['is_regeneration'] ?? false,
    };

    print('Sending poem generation request with body: ${jsonEncode(requestBody)}');
    print('Using analysisId: $analysisId');

    try {
      final response = await _dio.post(
        ApiConfig.generatePoemEndpoint,
        data: requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['poem'] != null) {
          // Return creation with the poem
          return Creation(
            id: analysisId.hashCode,
            imageData: 'temp_image_data', // This will be updated with actual data
            poemText: responseData['poem'],
            poemType: poemPreferences['poem_type'],
            poemLength: poemPreferences['poem_length'],
            createdAt: DateTime.now(),
          );
        } else {
          throw Exception('Invalid poem generation response: ${response.data}');
        }
      } else {
        throw Exception('Failed to generate poem: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to generate poem: $e');
    }
  }

  Future<List<Creation>> getUserCreations() async {
    if (_useMockData) {
      // Return mock user creations
      await Future.delayed(const Duration(seconds: 1));
      
      final mockCreations = List.generate(
        5,
        (index) => Creation(
          id: index + 1,
          imageData: 'mock_image_data',
          poemText: _generateMockPoem(['sonnet', 'haiku', 'free verse'][index % 3]),
          poemType: ['sonnet', 'haiku', 'free verse'][index % 3],
          createdAt: DateTime.now().subtract(Duration(days: index)),
          viewCount: Random().nextInt(50),
          downloadCount: Random().nextInt(10),
        ),
      );
      
      return mockCreations;
    }

    try {
      final response = await _dio.get(ApiConfig.userPoemsEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Creation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get user creations: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to get user creations: $e');
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

    try {
      final response = await _dio.get('${ApiConfig.apiBaseUrl}/creations/$creationId');

      if (response.statusCode == 200) {
        return Creation.fromJson(response.data);
      } else {
        throw Exception('Failed to get creation: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to get creation: $e');
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

    try {
      final response = await _dio.get('${ApiConfig.apiBaseUrl}/shared/$shareCode');

      if (response.statusCode == 200) {
        return Creation.fromJson(response.data);
      } else {
        throw Exception('Failed to get shared creation: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to get shared creation: $e');
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

    try {
      final response = await _dio.get(ApiConfig.membershipStatusEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Membership.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get membership plans: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to get membership plans: $e');
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

    try {
      final response = await _dio.post(
        ApiConfig.upgradeEndpoint,
        data: {
          'membership_id': membershipId,
          'payment_method_id': paymentMethodId,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to create subscription: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to create subscription: $e');
    }
  }

  Future<void> cancelSubscription() async {
    if (_useMockData) {
      // Simulate subscription cancellation
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    try {
      final response = await _dio.post('${ApiConfig.apiBaseUrl}/memberships/cancel');

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel subscription: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to cancel subscription: $e');
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
