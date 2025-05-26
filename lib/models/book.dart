class Book {
  final String? id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? openLibraryKey;

  Book({
    this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.openLibraryKey,
  });

  // Factory constructor for creating Book from JSON (API response)
  factory Book.fromJson(Map<String, dynamic> json) {
    // Extract author names from the API response
    String author = 'Unknown Author';
    if (json['author_name'] != null && json['author_name'].isNotEmpty) {
      author = (json['author_name'] as List).join(', ');
    }

    // Extract cover URL if available
    String? coverUrl;
    if (json['cover_i'] != null) {
      coverUrl = 'https://covers.openlibrary.org/b/id/${json['cover_i']}-M.jpg';
    }

    return Book(
      title: json['title'] ?? 'Unknown Title',
      author: author,
      coverUrl: coverUrl,
      openLibraryKey: json['key'],
    );
  }

  // Factory constructor for creating Book from database
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id']?.toString(),
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      coverUrl: map['coverUrl'],
      openLibraryKey: map['openLibraryKey'],
    );
  }

  // Convert Book to Map for database storage
  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'openLibraryKey': openLibraryKey,
    };
    // Only include id if it's not null (for updates)
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  // Convert Book to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'openLibraryKey': openLibraryKey,
    };
  }

  @override
  String toString() {
    return 'Book{id: $id, title: $title, author: $author, coverUrl: $coverUrl, openLibraryKey: $openLibraryKey}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book &&
        other.title == title &&
        other.author == author &&
        other.openLibraryKey == openLibraryKey;
  }

  @override
  int get hashCode {
    return title.hashCode ^ author.hashCode ^ (openLibraryKey?.hashCode ?? 0);
  }

  // Create a copy of the book with updated fields
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverUrl,
    String? openLibraryKey,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      openLibraryKey: openLibraryKey ?? this.openLibraryKey,
    );
  }
}

// Extended book details class for the details page
class BookDetails {
  final String title;
  final String description;
  final String publishDate;
  final List<String> subjects;
  final int? pageCount;
  final String? coverUrl;
  final String? openLibraryKey;

  BookDetails({
    required this.title,
    required this.description,
    required this.publishDate,
    required this.subjects,
    this.pageCount,
    this.coverUrl,
    this.openLibraryKey,
  });

  // Convert to Book object for favorites operations
  Book toBook(String author) {
    return Book(
      title: title,
      author: author,
      coverUrl: coverUrl,
      openLibraryKey: openLibraryKey,
    );
  }
}
