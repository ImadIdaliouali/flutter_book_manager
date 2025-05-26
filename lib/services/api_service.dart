import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/book.dart';

class ApiService {
  static const String baseUrl = 'https://openlibrary.org';
  static const Duration timeoutDuration = Duration(seconds: 10);

  // Search books using Open Library API
  static Future<List<Book>> searchBooks(String query) async {
    if (query.trim().isEmpty) {
      developer.log('Empty search query provided', name: 'ApiService');
      return [];
    }

    try {
      developer.log(
        'Searching for books with query: "$query"',
        name: 'ApiService',
      );

      // Encode the query to handle special characters
      final encodedQuery = Uri.encodeComponent(query.trim());
      final url = '$baseUrl/search.json?q=$encodedQuery&limit=20';

      developer.log('API URL: $url', name: 'ApiService');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'Flutter Book Manager App',
            },
          )
          .timeout(timeoutDuration);

      developer.log(
        'API Response status: ${response.statusCode}',
        name: 'ApiService',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['docs'] != null) {
          final List<dynamic> docs = data['docs'];
          developer.log(
            'Found ${docs.length} books in API response',
            name: 'ApiService',
          );

          List<Book> books =
              docs
                  .where(
                    (doc) => doc['title'] != null,
                  ) // Filter out books without titles
                  .map((doc) => Book.fromJson(doc))
                  .toList();

          developer.log(
            'Parsed ${books.length} valid books',
            name: 'ApiService',
          );
          return books;
        } else {
          developer.log('No docs found in API response', name: 'ApiService');
          return [];
        }
      } else {
        developer.log(
          'API request failed with status: ${response.statusCode}',
          name: 'ApiService',
        );
        throw ApiException('Failed to search books: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      developer.log('Error searching books: $e', name: 'ApiService');
      throw ApiException(
        'Network error: Unable to search books. Please check your internet connection.',
      );
    }
  }

  // Get book details by Open Library key
  static Future<BookDetails?> getBookDetails(String key) async {
    try {
      developer.log('Fetching book details for key: $key', name: 'ApiService');

      final url = '$baseUrl$key.json';
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'Flutter Book Manager App',
            },
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Extract basic information
        String title = data['title'] ?? 'Unknown Title';
        String description = '';
        String publishDate = '';
        List<String> subjects = [];
        int? pageCount;

        // Extract description
        if (data['description'] != null) {
          if (data['description'] is String) {
            description = data['description'];
          } else if (data['description'] is Map &&
              data['description']['value'] != null) {
            description = data['description']['value'];
          }
        }

        // Extract publish date
        if (data['publish_date'] != null) {
          publishDate = data['publish_date'];
        } else if (data['first_publish_date'] != null) {
          publishDate = data['first_publish_date'];
        }

        // Extract subjects
        if (data['subjects'] != null && data['subjects'] is List) {
          subjects =
              (data['subjects'] as List)
                  .map((s) => s.toString())
                  .take(5)
                  .toList();
        }

        // Extract page count
        if (data['number_of_pages'] != null) {
          pageCount = data['number_of_pages'];
        }

        // Try to get cover information
        String? coverUrl;
        if (data['covers'] != null && data['covers'].isNotEmpty) {
          final coverId = data['covers'][0];
          coverUrl =
              'https://covers.openlibrary.org/b/id/$coverId-L.jpg'; // Large cover for details page
        }

        return BookDetails(
          title: title,
          description: description,
          publishDate: publishDate,
          subjects: subjects,
          pageCount: pageCount,
          coverUrl: coverUrl,
          openLibraryKey: key,
        );
      } else {
        developer.log(
          'Failed to get book details: ${response.statusCode}',
          name: 'ApiService',
        );
        return null;
      }
    } catch (e) {
      developer.log('Error getting book details: $e', name: 'ApiService');
      return null;
    }
  }

  // Check if the API is reachable
  static Future<bool> checkApiHealth() async {
    try {
      developer.log('Checking API health', name: 'ApiService');

      final response = await http
          .get(
            Uri.parse('$baseUrl/search.json?q=test&limit=1'),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'Flutter Book Manager App',
            },
          )
          .timeout(const Duration(seconds: 5));

      bool isHealthy = response.statusCode == 200;
      developer.log(
        'API health check: ${isHealthy ? 'OK' : 'Failed'}',
        name: 'ApiService',
      );
      return isHealthy;
    } catch (e) {
      developer.log('API health check failed: $e', name: 'ApiService');
      return false;
    }
  }
}

// Custom exception for API errors
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
