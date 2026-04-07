import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushrut_aushadhi/core/widgets/admin_lab_order_card.dart';
import 'package:sushrut_aushadhi/models/lab_order_model.dart';

void main() {
  group('AdminLabOrderCard', () {
    LabOrderModel makeOrder({LabOrderStatus status = LabOrderStatus.pending}) {
      return LabOrderModel(
        orderId: 'order-1',
        userId: 'user-1',
        userPhone: '9999999999',
        userName: 'Test User',
        tests: [
          LabTestItem(testId: 'test-1', testName: 'CBC', price: 350),
        ],
        totalAmount: 350,
        status: status,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    }

    testWidgets('tapping a pending status chip calls callback',
        (WidgetTester tester) async {
      LabOrderStatus? tappedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminLabOrderCard(
              order: makeOrder(),
              onStatusTap: (status) => tappedStatus = status,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sample Collected'));
      await tester.pump();

      expect(tappedStatus, LabOrderStatus.sampleCollected);
    });

    testWidgets('processing orders do not show direct completed action',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminLabOrderCard(
              order: makeOrder(status: LabOrderStatus.processing),
            ),
          ),
        ),
      );

      expect(find.text('Completed'), findsNothing);
      expect(find.text('Move to:'), findsNothing);
      expect(find.text('Upload PDF'), findsOneWidget);
    });

    testWidgets('processing upload action calls callback',
        (WidgetTester tester) async {
      var uploadTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminLabOrderCard(
              order: makeOrder(status: LabOrderStatus.processing),
              onUploadPdfTap: () => uploadTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Upload PDF'));
      await tester.pump();

      expect(uploadTapped, isTrue);
    });
  });
}
