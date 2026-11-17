import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cirunay_navigation_app/demo_auth.dart';
import 'package:cirunay_navigation_app/main.dart';
import 'package:cirunay_navigation_app/post_card.dart';
import 'package:cirunay_navigation_app/social_media.dart';

void main() {
  setUp(() {
    DemoAuth.registeredUsername = null;
    DemoAuth.registeredPassword = null;
    DemoAuth.currentUsername = null;
  });

  testWidgets('Full social media and auth workflow', (
    WidgetTester tester,
  ) async {
    Future<void> openCreatePostSheet() async {
      await tester.tap(find.byTooltip('Create Post'));
      await tester.pumpAndSettle();
      expect(find.text('Create Post'), findsOneWidget);
    }

    Future<void> fillPostSheet(String caption, String imageUrl) async {
      await tester.enterText(
        find.widgetWithText(TextField, 'Caption'),
        caption,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Image URL'),
        imageUrl,
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
      await tester.pump();
    }

    await tester.pumpWidget(const StudentApp());

    // 1. Log in using the default admin account.
    expect(find.text('Welcome Back!'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'admin',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'admin123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    expect(DemoAuth.currentUsername, 'admin');
    expect(find.text('Welcome, Student!'), findsOneWidget);

    // 2. Open Social Media.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Social Media'),
      ),
    );
    await tester.pumpAndSettle();
    final socialListView = find.descendant(
      of: find.byType(SocialMediaPage),
      matching: find.byType(ListView),
    );
    expect(find.text('JohnDoe'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('JaneSmith'),
      socialListView,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(find.text('JaneSmith'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('JohnDoe'),
      socialListView,
      const Offset(0, 200),
    );
    await tester.pumpAndSettle();

    // 3. Submit a post with empty fields.
    await openCreatePostSheet();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pump();
    expect(
      find.text('Complete both fields before submitting!'),
      findsOneWidget,
    );
    expect(find.text('Create Post'), findsOneWidget);

    // Clear previous snackbar before next validation test.
    ScaffoldMessenger.of(
      tester.element(find.text('Create Post')),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    // 4. Submit a post with an invalid URL.
    await fillPostSheet('Invalid URL Post', 'not-a-valid-url');
    expect(
      find.text('Enter a valid HTTP or HTTPS image URL.'),
      findsOneWidget,
    );
    expect(find.text('Create Post'), findsOneWidget);

    ScaffoldMessenger.of(
      tester.element(find.text('Create Post')),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    // 5. Submit a valid post.
    await fillPostSheet(
      'Admin first valid post',
      'https://picsum.photos/id/10/600/400',
    );
    await tester.pumpAndSettle();
    expect(find.text('Create Post'), findsNothing);
    expect(find.text('Admin first valid post'), findsOneWidget);

    final firstPostCard = find.ancestor(
      of: find.text('Admin first valid post'),
      matching: find.byType(PostCard),
    );
    expect(
      find.descendant(of: firstPostCard, matching: find.text('admin')),
      findsOneWidget,
    );

    // 6. Tap Like twice.
    await tester.ensureVisible(
      find.descendant(of: firstPostCard, matching: find.text('Like')),
    );
    await tester.tap(
      find.descendant(of: firstPostCard, matching: find.text('Like')),
    );
    await tester.pump();
    expect(
      find.descendant(of: firstPostCard, matching: find.text('Liked')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: firstPostCard, matching: find.text('Liked')),
    );
    await tester.pump();
    expect(
      find.descendant(of: firstPostCard, matching: find.text('Like')),
      findsOneWidget,
    );

    // 7. Add a nonempty comment.
    final firstCommentField = find.descendant(
      of: firstPostCard,
      matching: find.byType(TextField),
    );
    final firstSendButton = find.descendant(
      of: firstPostCard,
      matching: find.byIcon(Icons.send),
    );
    await tester.ensureVisible(firstCommentField);
    await tester.pumpAndSettle();
    await tester.enterText(firstCommentField, 'Hello world comment');
    await tester.pumpAndSettle();
    await tester.ensureVisible(firstSendButton);
    await tester.pumpAndSettle();
    await tester.tap(firstSendButton);
    await tester.pump();
    expect(
      find.descendant(
        of: firstPostCard,
        matching: find.text('Hello world comment'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: firstPostCard, matching: find.text('1 Comments')),
      findsOneWidget,
    );

    // 8. Submit a blank comment.
    await tester.enterText(firstCommentField, '   ');
    await tester.tap(firstSendButton);
    await tester.pump();
    expect(
      find.descendant(of: firstPostCard, matching: find.text('1 Comments')),
      findsOneWidget,
    );

    // 9. Like a sample post, then create another post.
    await tester.dragUntilVisible(
      find.text('JohnDoe'),
      socialListView,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    final johnPostCard = find.ancestor(
      of: find.text('JohnDoe'),
      matching: find.byType(PostCard),
    );
    await tester.ensureVisible(
      find.descendant(of: johnPostCard, matching: find.text('Like')),
    );
    await tester.tap(
      find.descendant(of: johnPostCard, matching: find.text('Like')),
    );
    await tester.pump();
    expect(
      find.descendant(of: johnPostCard, matching: find.text('Liked')),
      findsOneWidget,
    );

    await openCreatePostSheet();
    await fillPostSheet(
      'Admin second valid post',
      'https://picsum.photos/id/11/600/400',
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Admin second valid post'),
      socialListView,
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();
    expect(find.text('Admin second valid post'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('JohnDoe'),
      socialListView,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('JohnDoe'),
          matching: find.byType(PostCard),
        ),
        matching: find.text('Liked'),
      ),
      findsOneWidget,
    );

    // 10. Switch to Home and return.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Home'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Student!'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Social Media'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Admin second valid post'),
      socialListView,
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();
    expect(find.text('Admin second valid post'), findsOneWidget);

    // 11. Log out (button in top right), register, and log in with a new account.
    final logoutButtons = find.byTooltip('Logout');
    expect(logoutButtons, findsWidgets);
    // Verify the active Social Media Logout button is positioned in the top-right corner.
    final socialMediaAppBar = find.descendant(
      of: find.ancestor(
        of: find.text('Social Media').first,
        matching: find.byType(AppBar),
      ),
      matching: find.byTooltip('Logout'),
    );
    final logoutCenter = tester.getCenter(socialMediaAppBar);
    expect(logoutCenter.dx, greaterThan(700));
    expect(logoutCenter.dy, lessThan(60));

    await tester.tap(socialMediaAppBar);
    await tester.pumpAndSettle();
    expect(DemoAuth.currentUsername, isNull);
    expect(find.text('Welcome Back!'), findsOneWidget);

    // Register a new account.
    await tester.tap(find.text("Don't have an account? Register"));
    await tester.pumpAndSettle();
    expect(find.text('Create an Account'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'newstudent',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Password'),
      'secret123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(
      find.text('Registration successful! You can now log in.'),
      findsOneWidget,
    );

    // Log in with the newly registered account.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'newstudent',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    expect(DemoAuth.currentUsername, 'newstudent');
    expect(find.text('Welcome, Student!'), findsOneWidget);

    // Verify Social Media uses the new account's username for posts.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Social Media'),
      ),
    );
    await tester.pumpAndSettle();

    await openCreatePostSheet();
    await fillPostSheet(
      'New student post',
      'https://picsum.photos/id/12/600/400',
    );
    await tester.pumpAndSettle();

    final newStudentPostCard = find.ancestor(
      of: find.text('New student post'),
      matching: find.byType(PostCard),
    );
    expect(
      find.descendant(
        of: newStudentPostCard,
        matching: find.text('newstudent'),
      ),
      findsOneWidget,
    );
  });
}
