import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';

class BookDetailsPage extends StatefulWidget {
  final Book book;

  const BookDetailsPage({super.key, required this.book});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  final DatabaseService _dbService = DatabaseService();
  late Future<BookDetails?> _bookDetailsFuture;
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _loadBookDetails();
    _checkFavoriteStatus();
  }

  void _loadBookDetails() {
    if (widget.book.openLibraryKey != null) {
      _bookDetailsFuture = ApiService.getBookDetails(
        widget.book.openLibraryKey!,
      );
    } else {
      // Create a basic BookDetails from the existing book data
      _bookDetailsFuture = Future.value(
        BookDetails(
          title: widget.book.title,
          description: 'No additional details available.',
          publishDate: '',
          subjects: [],
          coverUrl: widget.book.coverUrl,
          openLibraryKey: widget.book.openLibraryKey,
        ),
      );
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final isFavorite = await _dbService.isBookInFavorites(
        widget.book.title,
        widget.book.author,
      );
      setState(() {
        _isFavorite = isFavorite;
        _isLoadingFavorite = false;
      });
    } catch (e) {
      developer.log(
        'Error checking favorite status: $e',
        name: 'BookDetailsPage',
      );
      setState(() {
        _isLoadingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      if (_isFavorite) {
        // Remove from favorites
        await _dbService.deleteItemByTitleAuthor(
          widget.book.title,
          widget.book.author,
        );
        setState(() {
          _isFavorite = false;
          _isLoadingFavorite = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${widget.book.title}" from favorites'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Add to favorites
        await _dbService.insertItem(widget.book);
        setState(() {
          _isFavorite = true;
          _isLoadingFavorite = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${widget.book.title}" to favorites'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingFavorite = false;
      });
      developer.log('Error toggling favorite: $e', name: 'BookDetailsPage');
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
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Favorite button in app bar
          _isLoadingFavorite
              ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
              : IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: _toggleFavorite,
                tooltip:
                    _isFavorite ? 'Remove from favorites' : 'Add to favorites',
              ),
        ],
      ),
      body: FutureBuilder<BookDetails?>(
        future: _bookDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading book details...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading book details: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadBookDetails();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final bookDetails = snapshot.data;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover and basic info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book cover
                    Container(
                      width: 120,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            bookDetails?.coverUrl != null
                                ? Image.network(
                                  bookDetails!.coverUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.book,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                )
                                : Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.book,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Book info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.book.title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'by ${widget.book.author}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),

                          // Favorite button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isLoadingFavorite ? null : _toggleFavorite,
                              icon:
                                  _isLoadingFavorite
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Icon(
                                        _isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: _isFavorite ? Colors.red : null,
                                      ),
                              label: Text(
                                _isFavorite
                                    ? 'Remove from Favorites'
                                    : 'Add to Favorites',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isFavorite ? Colors.red[50] : null,
                                foregroundColor:
                                    _isFavorite ? Colors.red : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Additional details
                if (bookDetails != null) ...[
                  // Publish date
                  if (bookDetails.publishDate.isNotEmpty) ...[
                    _buildDetailSection(
                      'Publication Date',
                      bookDetails.publishDate,
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Page count
                  if (bookDetails.pageCount != null) ...[
                    _buildDetailSection(
                      'Pages',
                      '${bookDetails.pageCount} pages',
                      Icons.menu_book,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Subjects
                  if (bookDetails.subjects.isNotEmpty) ...[
                    _buildDetailSection(
                      'Subjects',
                      bookDetails.subjects.join(', '),
                      Icons.category,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  if (bookDetails.description.isNotEmpty) ...[
                    _buildDetailSection(
                      'Description',
                      bookDetails.description,
                      Icons.description,
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(content, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
