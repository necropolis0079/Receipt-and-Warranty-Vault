import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/receipt/domain/entities/image_data.dart';

void main() {
  group('ImageData', () {
    test('constructs with required fields', () {
      const data = ImageData(
        id: 'img1',
        localPath: '/path/to/image.jpg',
        sizeBytes: 1024,
        mimeType: 'image/jpeg',
      );
      expect(data.id, 'img1');
      expect(data.localPath, '/path/to/image.jpg');
      expect(data.thumbnailPath, isNull);
      expect(data.sizeBytes, 1024);
    });

    test('copyWith creates modified copy', () {
      const original = ImageData(
        id: 'img1',
        localPath: '/path/to/image.jpg',
        sizeBytes: 1024,
        mimeType: 'image/jpeg',
      );
      final copy = original.copyWith(
        thumbnailPath: '/path/to/thumb.jpg',
        width: 200,
        height: 300,
      );
      expect(copy.thumbnailPath, '/path/to/thumb.jpg');
      expect(copy.width, 200);
      expect(copy.id, 'img1');
    });

    test('equatable compares by value', () {
      const a = ImageData(
        id: 'img1',
        localPath: '/path.jpg',
        sizeBytes: 100,
        mimeType: 'image/jpeg',
      );
      const b = ImageData(
        id: 'img1',
        localPath: '/path.jpg',
        sizeBytes: 100,
        mimeType: 'image/jpeg',
      );
      expect(a, equals(b));
    });
  });
}
