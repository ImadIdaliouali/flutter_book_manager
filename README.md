# Flutter Book Manager

A Flutter application for searching and managing favorite books using the Open Library API and SQLite local storage.

## Features

### 🔍 Book Search

- Search books by keyword using the Open Library API
- Display search results with title, author, and cover image
- Real-time search with loading indicators and error handling

### ❤️ Favorites Management

- Save favorite books locally using SQLite database
- View all saved favorites in a dedicated page
- Remove books from favorites with delete functionality
- Undo functionality for accidental deletions
- Heart icon toggle with immediate visual feedback
- Synchronized favorite status across all pages

### 📖 Book Details Page

- Comprehensive book information display
- Large book cover images
- Additional details from Open Library API (description, publication date, subjects, page count)
- Prominent favorite/unfavorite button
- Navigation from search results and favorites list
- Proper loading states and error handling

### 🏗️ Architecture

- Clean file structure with separate models, services, and pages
- Proper state management using FutureBuilder
- Error handling for network requests and database operations
- Database schema migration support

## File Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── book.dart            # Book data model & BookDetails class
├── services/
│   ├── api_service.dart     # Open Library API integration
│   └── db_service.dart      # SQLite database service
└── pages/
    ├── home_page.dart       # Search functionality
    ├── favorites_page.dart  # Favorites management
    └── book_details_page.dart # Book details display
```

## Dependencies

- `http: ^1.1.0` - HTTP requests for API calls
- `sqflite: ^2.3.0` - SQLite database for local storage
- `path: ^1.8.3` - Path manipulation for database

## Database Schema

### Favorites Table

```sql
CREATE TABLE favorites (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  coverUrl TEXT,
  openLibraryKey TEXT,
  UNIQUE(title, author)
)
```

## API Integration

Uses the Open Library Search API:

- Endpoint: `https://openlibrary.org/search.json?q={search_term}`
- No API key required
- Returns book data including title, author, and cover images

## Getting Started

1. **Install dependencies:**

   ```bash
   flutter pub get
   ```

2. **Run the app:**

   ```bash
   flutter run
   ```

3. **Run tests:**
   ```bash
   flutter test
   ```

## Usage

1. **Search for Books:**

   - Enter a search term in the search field
   - Tap the "Search" button or press Enter
   - Browse through the search results

2. **Add to Favorites:**

   - Tap the heart icon next to any book in search results
   - The heart will fill and turn red to indicate it's favorited
   - A confirmation message will appear

3. **View Favorites:**

   - Tap the heart icon in the app bar to view favorites
   - See all your saved books in a list format

4. **Remove from Favorites:**
   - In the favorites page, tap the delete icon next to any book
   - Use the "Undo" option if you accidentally remove a book
   - Or use "Clear All" from the menu to remove all favorites

## Technical Features

- **Offline Storage:** Books are stored locally using SQLite
- **Network Handling:** Proper error handling for API requests
- **State Management:** Uses FutureBuilder for async operations
- **Visual Feedback:** Immediate UI updates when adding/removing favorites
- **Database Migration:** Automatic schema upgrades and error recovery
- **Material Design:** Modern UI following Material Design 3 guidelines

## Testing

The app includes widget tests for:

- App initialization and UI components
- Search field functionality
- Navigation between pages
- Basic user interactions

Run tests with: `flutter test`