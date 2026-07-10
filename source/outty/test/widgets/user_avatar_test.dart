import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outty/widgets/user_avatar.dart';

void main() {
  Widget buildSubject({
    String? photoUrl,
    double size = 72,
    Color? backgroundColor,
    Color? borderColor,
    double borderWidth = 0,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: UserAvatar(
            size: size,
            photoUrl: photoUrl,
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            borderWidth: borderWidth,
            fallback: const Icon(Icons.person, key: Key('fallback_icon')),
          ),
        ),
      ),
    );
  }

  testWidgets('UserAvatar shows fallback when photoUrl is null', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(photoUrl: null));

    expect(find.byKey(const Key('fallback_icon')), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('UserAvatar shows fallback when photoUrl is blank', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(photoUrl: '   '));

    expect(find.byKey(const Key('fallback_icon')), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('UserAvatar renders network image for non-empty photoUrl', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(photoUrl: 'https://example.com/profile.png'),
    );

    final image = tester.widget<Image>(find.byType(Image));

    expect(find.byType(Image), findsOneWidget);
    expect(image.image, isA<NetworkImage>());
  });

  testWidgets('UserAvatar clips avatar content to an oval shape', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(photoUrl: 'https://example.com/profile.png'),
    );

    expect(find.byType(ClipOval), findsOneWidget);
  });

  testWidgets('UserAvatar applies size and border styling', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        photoUrl: null,
        size: 88,
        backgroundColor: Colors.amber,
        borderColor: Colors.blue,
        borderWidth: 3,
      ),
    );

    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration! as BoxDecoration;

    expect(tester.getSize(find.byType(UserAvatar)), const Size(88, 88));
    expect(decoration.color, Colors.amber);
    expect(decoration.border, isA<Border>());
    expect((decoration.border! as Border).top.color, Colors.blue);
    expect((decoration.border! as Border).top.width, 3);
  });
}
