import '../../models/lab_order_model.dart';
import '../../models/lab_package_model.dart';

Map<String, bool> resolvePackageTestSelection(
  LabPackageModel package,
  List<LabTestModel> tests,
) {
  final selected = <String, bool>{};

  for (final testId in package.testIds) {
    if (tests.any((test) => test.id == testId)) {
      selected[testId] = true;
    }
  }

  if (selected.isNotEmpty) {
    return selected;
  }

  final testsByNormalizedName = <String, LabTestModel>{};
  for (final test in tests) {
    final normalized = _normalizeTestKey(test.name);
    if (normalized.isNotEmpty) {
      testsByNormalizedName.putIfAbsent(normalized, () => test);
    }
  }

  for (final testName in package.testNames) {
    final normalized = _normalizeTestKey(testName);
    final matchedTest = testsByNormalizedName[normalized];
    if (matchedTest != null) {
      selected[matchedTest.id] = true;
    }
  }

  return selected;
}

List<LabTestItem> buildSelectedTestItems(
  Map<String, bool> selectedTests,
  List<LabTestModel> tests,
) {
  if (tests.isEmpty) {
    return [];
  }

  return tests
      .where((test) => selectedTests[test.id] == true)
      .map((test) => LabTestItem(
            testId: test.id,
            testName: test.name,
            price: test.price,
          ))
      .toList();
}

String _normalizeTestKey(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
