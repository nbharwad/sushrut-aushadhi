import 'package:flutter_test/flutter_test.dart';
import 'package:sushrut_aushadhi/features/lab/booking_selection_resolver.dart';
import 'package:sushrut_aushadhi/models/lab_order_model.dart';
import 'package:sushrut_aushadhi/models/lab_package_model.dart';

void main() {
  final tests = [
    LabTestModel(
      id: 'cbc',
      name: 'Complete Blood Count (CBC)',
      category: 'Haematology',
      price: 350,
      tatHours: 24,
      sampleType: 'Blood',
    ),
    LabTestModel(
      id: 'lft',
      name: 'Liver Function Test',
      category: 'Biochemistry',
      price: 700,
      tatHours: 24,
      sampleType: 'Blood',
    ),
  ];

  LabPackageModel makePackage({
    List<String> testIds = const [],
    List<String> testNames = const [],
  }) {
    return LabPackageModel(
      id: 'pkg-1',
      name: 'Package',
      shortDescription: 'desc',
      category: 'popular',
      sampleType: 'Blood',
      iconName: 'biotech',
      price: 900,
      originalPrice: 1200,
      tatHours: 24,
      fastingHours: 0,
      sortOrder: 1,
      testCount: testIds.length + testNames.length,
      fastingRequired: false,
      active: true,
      popular: false,
      testIds: testIds,
      testNames: testNames,
      preparationSteps: const [],
      parameters: const [],
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  group('resolvePackageTestSelection', () {
    test('selects tests from package test ids', () {
      final selection = resolvePackageTestSelection(
        makePackage(testIds: const ['cbc', 'lft']),
        tests,
      );

      expect(selection, {'cbc': true, 'lft': true});
    });

    test('falls back to test names when ids are missing', () {
      final selection = resolvePackageTestSelection(
        makePackage(
          testNames: const ['Complete Blood Count (CBC)', 'Liver Function Test'],
        ),
        tests,
      );

      expect(selection, {'cbc': true, 'lft': true});
    });

    test('returns empty selection when package tests cannot be resolved', () {
      final selection = resolvePackageTestSelection(
        makePackage(testNames: const ['Unknown Test']),
        tests,
      );

      expect(selection, isEmpty);
    });
  });

  test('buildSelectedTestItems returns selected lab test items', () {
    final items = buildSelectedTestItems({'cbc': true}, tests);

    expect(items, hasLength(1));
    expect(items.single.testId, 'cbc');
    expect(items.single.testName, 'Complete Blood Count (CBC)');
    expect(items.single.price, 350);
  });
}
