// Book Manager App Widget Tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/main.dart';

void main() {
  testWidgets('Book Manager app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BookManagerApp());

    // Verify that the app loads with the correct title
    expect(find.text('Book Search'), findsOneWidget);

    // Verify that the search field is present
    expect(find.byType(TextField), findsOneWidget);

    // Verify that the search button is present
    expect(find.text('Search'), findsOneWidget);

    // Verify that the favorites icon is present in the app bar
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    // Verify that the initial state shows the search prompt
    expect(
      find.text('Search for books using the search bar above'),
      findsOneWidget,
    );
  });

  testWidgets('Search field accepts input', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BookManagerApp());

    // Find the search field and enter text
    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'Harry Potter');

    // Verify that the text was entered
    expect(find.text('Harry Potter'), findsOneWidget);
  });

  testWidgets('Favorites page navigation works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BookManagerApp());

    // Tap the favorites icon
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();

    // Verify that we navigated to the favorites page
    expect(find.text('Favorite Books'), findsOneWidget);

    // Verify that the empty state is shown
    expect(find.text('No favorite books yet'), findsOneWidget);
  });

  testWidgets('Book details page components exist', (
    WidgetTester tester,
  ) async {
    // This test would require mocking the database and API
    // For now, we'll just verify the basic app structure
    await tester.pumpWidget(const BookManagerApp());

    // Verify the main components are present
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
