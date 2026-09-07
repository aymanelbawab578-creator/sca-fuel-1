import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sca_fuel/providers/auth_provider.dart';
import 'package:sca_fuel/screens/store_screen.dart';

class TestAuthProvider extends AuthProvider {
  TestAuthProvider() : super();

  @override
  String? get token => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Store screen shows all tabs without needing to suppress overflow errors',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>(
          create: (_) => TestAuthProvider(),
          child: const StoreScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('المتابعة'), findsOneWidget);
    expect(find.text('الفواتير'), findsOneWidget);
    expect(find.text('تقرير التسوية'), findsOneWidget);
    expect(find.text('تغيير السعر'), findsOneWidget);
    expect(find.text('المأموريّات'), findsOneWidget);
    expect(find.text('جرد'), findsOneWidget);

    await tester.tap(find.text('المأموريّات'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
