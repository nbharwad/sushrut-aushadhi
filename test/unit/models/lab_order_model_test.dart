import 'package:flutter_test/flutter_test.dart';
import 'package:sushrut_aushadhi/models/lab_order_model.dart';

void main() {
  group('LabOrderStatus', () {
    test('fromString parses valid statuses including sampleCollected', () {
      expect(LabOrderStatus.fromString('pending'), LabOrderStatus.pending);
      expect(
        LabOrderStatus.fromString('sampleCollected'),
        LabOrderStatus.sampleCollected,
      );
      expect(LabOrderStatus.fromString('processing'), LabOrderStatus.processing);
      expect(LabOrderStatus.fromString('completed'), LabOrderStatus.completed);
      expect(LabOrderStatus.fromString('cancelled'), LabOrderStatus.cancelled);
    });

    test('fromString accepts normalized legacy variants', () {
      expect(
        LabOrderStatus.fromString('samplecollected'),
        LabOrderStatus.sampleCollected,
      );
      expect(
        LabOrderStatus.fromString('sample_collected'),
        LabOrderStatus.sampleCollected,
      );
    });

    test('fromString falls back to pending for unknown values', () {
      expect(LabOrderStatus.fromString('invalid_status'), LabOrderStatus.pending);
    });
  });
}
