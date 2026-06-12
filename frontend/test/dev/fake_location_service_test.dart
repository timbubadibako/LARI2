import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lari_lari/dev/fake_location_service.dart';

void main() {
  test('FakeLocationService emits roughly one sample per second', () {
    fakeAsync((async) {
      final service = FakeLocationService(
        config: FakeLocationConfig.defaults().copyWith(
          durationSeconds: 60,
          simulateDropouts: false,
          loopForever: false,
        ),
      );

      final samples = <dynamic>[];
      final subscription = service.start().listen(samples.add);

      async.elapse(const Duration(seconds: 60));

      expect(samples.length, inInclusiveRange(58, 62));

      subscription.cancel();
      service.stop();
    });
  });
}
