import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';
import 'favorites_page.dart';
import 'book_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  List<Book> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  Set<String> _favoriteKeys = {}; // Track favorite books by title+author

  @override
  void initState() {
    super.initState();
    _loadFavoriteKeys();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load favorite book keys to track which books are favorited
  Future<void> _loadFavoriteKeys() async {
    try {
      final favorites = await _dbService.getItems();
      setState(() {
        _favoriteKeys =
            favorites.map((book) => '${book.title}|${book.author}').toSet();
      });
    } catch (e) {
      developer.log('Error loading favorite keys: $e', name: 'HomePage');
    }
  }

  // Search for books using the API
  Future<void> _searchBooks() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await ApiService.searchBooks(query);

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      });
      developer.log('Search error: $e', name: 'HomePage');
    }
  }

  // Toggle favorite status of a book
  Future<void> _toggleFavorite(Book book) async {
    final key = '${book.title}|${book.author}';
    final isFavorite = _favoriteKeys.contains(key);

    try {
      if (isFavorite) {
        // Remove from favorites
        await _dbService.deleteItemByTitleAuthor(book.title, book.author);
        setState(() {
          _favoriteKeys.remove(key);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${book.title}" from favorites'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Add to favorites
        await _dbService.insertItem(book);
        setState(() {
          _favoriteKeys.add(key);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${book.title}" to favorites'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error toggling favorite: $e', name: 'HomePage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Search'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesPage()),
              ).then(
                (_) => _loadFavoriteKeys(),
              ); // Refresh favorites when returning
            },
            tooltip: 'View Favorites',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search for books...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _searchBooks(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchBooks,
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Search'),
                ),
              ],
            ),
          ),

          // Results Section
          Expanded(child: _buildResultsSection()),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching for books...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _searchBooks, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search for books using the search bar above',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        final key = '${book.title}|${book.author}';
        final isFavorite = _favoriteKeys.contains(key);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading:
                book.coverUrl != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        book.coverUrl!,
                        width: 50,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 70,
                            color: Colors.grey[300],
                            child: const Icon(Icons.book, color: Colors.grey),
                          );
                        },
                      ),
                    )
                    : Container(
                      width: 50,
                      height: 70,
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, color: Colors.grey),
                    ),
            title: Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey,
              ),
              onPressed: () => _toggleFavorite(book),
            ),
            onTap: () {
              // Navigate to book details page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailsPage(book: book),
                ),
              ).then(
                (_) => _loadFavoriteKeys(),
              ); // Refresh favorites when returning
            },
          ),
        );
      },
    );
  }
}
