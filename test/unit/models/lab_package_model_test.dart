import 'package:flutter_test/flutter_test.dart';
import 'package:sushrut_aushadhi/models/lab_package_model.dart';

void main() {
  group('LabPackageModel.fromFirestore', () {
    test('parses camelCase package fields', () {
      final package = LabPackageModel.fromFirestore({
        'name': 'Full Body Checkup',
        'shortDescription': 'Routine wellness package',
        'category': 'popular',
        'sampleType': 'Blood',
        'iconName': 'biotech',
        'price': 999,
        'originalPrice': 1499,
        'tatHours': 24,
        'fastingHours': 10,
        'sortOrder': 1,
        'testCount': 2,
        'fastingRequired': true,
        'active': true,
        'popular': true,
        'testIds': ['cbc', 'lft'],
        'testNames': ['CBC', 'LFT'],
        'preparationSteps': ['Fast for 10 hours'],
        'parameters': ['Hemoglobin'],
      }, 'pkg-1');

      expect(package.id, 'pkg-1');
      expect(package.shortDescription, 'Routine wellness package');
      expect(package.sampleType, 'Blood');
      expect(package.originalPrice, 1499);
      expect(package.testIds, ['cbc', 'lft']);
      expect(package.testNames, ['CBC', 'LFT']);
      expect(package.preparationSteps, ['Fast for 10 hours']);
      expect(package.parameters, ['Hemoglobin']);
    });

    test('parses legacy snake_case package fields', () {
      final package = LabPackageModel.fromFirestore({
        'name': 'Diabetes Package',
        'short_description': 'Legacy package shape',
        'sample_type': 'Blood',
        'icon_name': 'science',
        'price': 799,
        'original_price': 999,
        'tat_hours': 18,
        'fasting_hours': 8,
        'sort_order': 2,
        'test_count': 2,
        'fasting_required': true,
        'active': true,
        'popular': false,
        'test_ids': ['hba1c', 'glucose'],
        'test_names': ['HbA1c', 'Blood Sugar (Fasting)'],
        'preparation_steps': ['Stay hydrated'],
      }, 'pkg-legacy');

      expect(package.id, 'pkg-legacy');
      expect(package.shortDescription, 'Legacy package shape');
      expect(package.sampleType, 'Blood');
      expect(package.iconName, 'science');
      expect(package.originalPrice, 999);
      expect(package.tatHours, 18);
      expect(package.fastingHours, 8);
      expect(package.sortOrder, 2);
      expect(package.testCount, 2);
      expect(package.fastingRequired, isTrue);
      expect(package.testIds, ['hba1c', 'glucose']);
      expect(package.testNames, ['HbA1c', 'Blood Sugar (Fasting)']);
      expect(package.preparationSteps, ['Stay hydrated']);
    });
  });
}
