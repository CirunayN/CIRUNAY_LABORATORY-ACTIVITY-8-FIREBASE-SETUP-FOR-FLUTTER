import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cirunay_navigation_app/calculator_screen.dart';
import 'package:cirunay_navigation_app/demo_auth.dart';
import 'package:cirunay_navigation_app/main.dart';
import 'package:cirunay_navigation_app/main_screen.dart';
import 'package:cirunay_navigation_app/profile_page.dart';
import 'package:cirunay_navigation_app/social_media/post_card.dart';

void main() {
  setUp(() {
    DemoAuth.registeredUsername = null;
    DemoAuth.registeredPassword = null;
    DemoAuth.currentUsername = null;
  });

  testWidgets('Complete integrated student application flow (Steps 1-14)', (
    WidgetTester tester,
  ) async {
    Future<void> tapNavDestination(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> createPost(String caption, String imageUrl) async {
      await tester.tap(find.byTooltip('Create Post'));
      await tester.pumpAndSettle();
      expect(find.text('Create Post'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Caption'),
        caption,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Image URL'),
        imageUrl,
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
      await tester.pumpAndSettle();
      expect(find.text('Create Post'), findsNothing);
    }

    Future<void> tapCalculatorButton(String symbol) async {
      final button = find.descendant(
        of: find.byType(CalculatorScreen),
        matching: find.text(symbol),
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
    }

    await tester.pumpWidget(const StudentApp());

    // 1. Open the application: Login appears first.
    expect(find.text('Welcome Back!'), findsOneWidget);

    // 2. Submit empty login fields: Validation messages appear.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    expect(find.text('Enter your username.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);

    // 3. Enter incorrect credentials: Login is rejected.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'wronguser',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrongpass',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    expect(find.text('Invalid username or password.'), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);

    // 4 & 5. Enter admin / admin123: Dashboard opens and displays Welcome, admin!
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
    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Welcome, admin!'), findsOneWidget);

    // 6. Open Calculator: verify Step 7 checkpoint (20 and 5) and 10 + 5 = 15.0.
    await tapNavDestination('Calculator');
    expect(find.text('My Stateful Calculator'), findsOneWidget);

    final firstField = find.widgetWithText(TextField, 'First Number');
    final secondField = find.widgetWithText(TextField, 'Second Number');

    // Empty validation.
    await tapCalculatorButton('+');
    expect(find.text('Invalid input'), findsOneWidget);

    // Step 7 checkpoint: 20 and 5 across all four operations.
    await tester.enterText(firstField, '20');
    await tester.enterText(secondField, '5');

    await tapCalculatorButton('+');
    expect(find.text('25.0'), findsOneWidget);

    await tapCalculatorButton('−');
    expect(find.text('15.0'), findsOneWidget);

    await tapCalculatorButton('×');
    expect(find.text('100.0'), findsOneWidget);

    await tapCalculatorButton('÷');
    expect(find.text('4.0'), findsOneWidget);

    // Division by zero handling.
    await tester.enterText(secondField, '0');
    await tapCalculatorButton('÷');
    expect(find.text('Cannot divide by zero'), findsOneWidget);

    // Clear button resets inputs and result.
    await tapCalculatorButton('Clear');
    expect(find.text('0'), findsOneWidget);

    // Test 6: calculate 10 + 5 -> 15.0.
    await tester.enterText(firstField, '10');
    await tester.enterText(secondField, '5');
    await tapCalculatorButton('+');
    expect(find.text('15.0'), findsOneWidget);

    // 7. Switch tabs and return to Calculator: inputs and result remain.
    await tapNavDestination('Dashboard');
    expect(find.text('Welcome, admin!'), findsOneWidget);
    await tapNavDestination('Calculator');

    expect(
      tester.widget<TextField>(firstField).controller?.text,
      '10',
    );
    expect(
      tester.widget<TextField>(secondField).controller?.text,
      '5',
    );
    expect(find.text('15.0'), findsOneWidget);

    // 8. Create a social post: post displays logged-in username.
    await tapNavDestination('Social');
    expect(find.text('JohnDoe'), findsOneWidget);

    await createPost(
      'Admin integrated post',
      'https://picsum.photos/id/10/600/400',
    );

    final adminPostCard = find.ancestor(
      of: find.text('Admin integrated post'),
      matching: find.byType(PostCard),
    );
    expect(adminPostCard, findsOneWidget);
    expect(
      find.descendant(of: adminPostCard, matching: find.text('admin')),
      findsOneWidget,
    );

    // 9. Like a post and add a comment: both interactions update correctly.
    final likeButton = find.descendant(
      of: adminPostCard,
      matching: find.text('Like'),
    );
    await tester.ensureVisible(likeButton);
    await tester.pumpAndSettle();
    await tester.tap(likeButton);
    await tester.pump();
    expect(
      find.descendant(of: adminPostCard, matching: find.text('Liked')),
      findsOneWidget,
    );

    final commentField = find.descendant(
      of: adminPostCard,
      matching: find.byType(TextField),
    );
    final sendButton = find.descendant(
      of: adminPostCard,
      matching: find.byIcon(Icons.send),
    );
    await tester.ensureVisible(commentField);
    await tester.enterText(commentField, 'Nice integrated feed!');
    await tester.ensureVisible(sendButton);
    await tester.pumpAndSettle();
    await tester.tap(sendButton);
    await tester.pump();

    expect(
      find.descendant(
        of: adminPostCard,
        matching: find.text('Nice integrated feed!'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: adminPostCard, matching: find.text('1 Comments')),
      findsOneWidget,
    );

    // 10. Switch tabs and return to Social: posts, likes, and comments remain.
    await tapNavDestination('Dashboard');
    expect(find.text('Welcome, admin!'), findsOneWidget);
    await tapNavDestination('Social');

    final preservedPostCard = find.ancestor(
      of: find.text('Admin integrated post'),
      matching: find.byType(PostCard),
    );
    expect(preservedPostCard, findsOneWidget);
    expect(
      find.descendant(of: preservedPostCard, matching: find.text('Liked')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: preservedPostCard,
        matching: find.text('Nice integrated feed!'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: preservedPostCard, matching: find.text('1 Comments')),
      findsOneWidget,
    );

    // 11. Open Profile: student information and username appear.
    await tapNavDestination('Profile');
    expect(find.text('Student Profile'), findsOneWidget);
    expect(find.text('Niño Angelo C. Cirunay'), findsOneWidget);
    expect(find.text('Logged in as: admin'), findsOneWidget);
    expect(find.text('556466'), findsOneWidget);
    expect(find.text('BSIT — CCE106(3447)'), findsOneWidget);
    expect(find.text('n.cirunay.556466@umindanao.edu.ph'), findsOneWidget);

    // 12. Tap Logout: Login appears; Back does not reopen MainScreen.
    final profileListView = find.descendant(
      of: find.byType(ProfilePage),
      matching: find.byType(ListView),
    );
    final logoutButton = find.text('Logout');
    await tester.dragUntilVisible(
      logoutButton,
      profileListView,
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    expect(DemoAuth.currentUsername, isNull);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);
    expect(
      Navigator.of(tester.element(find.text('Welcome Back!'))).canPop(),
      isFalse,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MainScreen), findsNothing);

    // 13. Register a valid account and log in: Dashboard displays registered username.
    await tester.tap(find.text("Don't have an account? Register"));
    await tester.pumpAndSettle();
    expect(find.text('Create an Account'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'student1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'pass1234',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Password'),
      'pass1234',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back!'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'student1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'pass1234',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(DemoAuth.currentUsername, 'student1');
    expect(find.text('Welcome, student1!'), findsOneWidget);

    await tapNavDestination('Profile');
    expect(find.text('Logged in as: student1'), findsOneWidget);

    // 14. Create a post using the registered account: post displays registered username.
    await tapNavDestination('Social');
    await createPost(
      'Student1 integrated post',
      'https://picsum.photos/id/15/600/400',
    );

    final studentPostCard = find.ancestor(
      of: find.text('Student1 integrated post'),
      matching: find.byType(PostCard),
    );
    expect(studentPostCard, findsOneWidget);
    expect(
      find.descendant(of: studentPostCard, matching: find.text('student1')),
      findsOneWidget,
    );
  });
}
