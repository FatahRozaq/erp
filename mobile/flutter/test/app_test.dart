import "package:erp_mobile/app/app.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("shows skeleton shell", (tester) async {
    await tester.pumpWidget(const ErpApp());
    expect(find.text("Enterprise ERP skeleton"), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
