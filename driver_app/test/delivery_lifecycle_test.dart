import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/active_jobs_controller.dart';
import 'package:urban_goodz_driver/controllers/business_job_controller.dart';
import 'package:urban_goodz_driver/controllers/load_board_controller.dart';
import 'package:urban_goodz_driver/models/job_lifecycle.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';

import 'support/fakes.dart';

/// End-to-end tests for the driver delivery lifecycle:
/// load board -> accept -> en route -> (arrived) -> picked up -> delivered.
///
/// These run the real controllers over the real [DriverApiService] and only
/// fake the socket, so they assert the exact endpoint path each transition
/// hits — not just that some method was called. A test that passed while the
/// app posted to the wrong route would be worthless here, and the
/// wrong-route bug this recovery fixed is exactly that.
const _base = '/api/v1/urban-goodz/driver';

Map<String, dynamic> businessJob(int id, String status) => {
      'job_id': id,
      'job_number': 'UG-$id',
      'status': status,
      'job_type': 'business_courier',
    };

Map<String, dynamic> boardLoad(String id, {double earnings = 42.5}) => {
      'id': id,
      'type': 'marketplace',
      'title': 'Pallet run $id',
      'description': 'desc',
      'pickup_address': '1 A St',
      'dropoff_address': '2 B St',
      'status': 'available',
      'earnings': earnings,
      'distance': 12.0,
      'estimated_duration': '45m',
      'customer_name': 'Acme',
      'customer_phone': '555',
      'scheduled_date': '2026-07-26',
      'scheduled_time': '09:00',
      'vehicle_type': 'van',
    };

Map<String, dynamic> activeJob(String id, String status) =>
    boardLoad(id)..['status'] = status;

Response ok(Object body) => Response(statusCode: 200, body: body);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiClient client;

  setUp(() {
    Get.testMode = true;
    client = FakeApiClient();
    Get.put<DriverApiService>(DriverApiService(client: client));
  });

  tearDown(Get.reset);

  /// Paths this test's fake actually received a POST for.
  List<String> posted() =>
      client.calls.where((c) => c.method == 'POST').map((c) => c.path).toList();

  // ---------------------------------------------------------------- board

  group('discovery / load board', () {
    late LoadBoardController board;

    setUp(() {
      board = LoadBoardController();
      client.stub(
        '$_base/load-board?page=1',
        ok({
          'loads': [boardLoad('22'), boardLoad('23')],
        }),
      );
    });

    test('accept posts to load-board/{id}/accept and takes the load off the '
        'board once the server returns the job', () async {
      await board.fetchLoads();
      expect(board.availableLoads.length, 2);

      client.stub(
        '$_base/load-board/22/accept',
        ok({
          'job': {'id': 501, 'status': JobStatus.accepted},
        }),
      );

      await board.acceptLoad('22');

      expect(posted(), contains('$_base/load-board/22/accept'));
      expect(board.lastOutcome.value, TransitionOutcome.success);
      expect(board.availableLoads.map((l) => l.id), ['23']);
    });

    test('accept does NOT report success when the server returns no job',
        () async {
      await board.fetchLoads();
      client.stub('$_base/load-board/22/accept', ok({'message': 'queued'}));

      await board.acceptLoad('22');

      expect(board.lastOutcome.value, TransitionOutcome.unconfirmed);
      // The load stays on the board: the app cannot claim the driver has it.
      expect(board.availableLoads.map((l) => l.id), containsAll(['22', '23']));
    });

    test('refuses to accept a load the board never served', () async {
      await board.fetchLoads();

      await board.acceptLoad('999');

      expect(board.lastOutcome.value, TransitionOutcome.refused);
      expect(posted(), isEmpty);
    });

    test('a bid sends the driver amount, not zero', () async {
      await board.fetchLoads();
      client.stub('$_base/load-board/22/bid', ok({'message': 'ok'}));

      await board.bidOnLoad('22', 137.25, notes: 'can do it today');

      final bid = client.calls.firstWhere(
        (c) => c.path == '$_base/load-board/22/bid',
      );
      expect(bid.body['bid_amount'], 137.25);
      expect(bid.body['notes'], 'can do it today');
      expect(board.lastOutcome.value, TransitionOutcome.success);
    });

    test('refuses a zero or negative bid instead of submitting it', () async {
      await board.fetchLoads();

      await board.bidOnLoad('22', 0);
      expect(board.lastOutcome.value, TransitionOutcome.refused);

      await board.bidOnLoad('22', -5);
      expect(board.lastOutcome.value, TransitionOutcome.refused);

      expect(posted(), isEmpty);
    });

    test('refuses to bid on a load the board never served', () async {
      await board.fetchLoads();
      await board.bidOnLoad('999', 50);
      expect(board.lastOutcome.value, TransitionOutcome.refused);
      expect(posted(), isEmpty);
    });
  });

  // ------------------------------------------------- business courier path

  group('business courier lifecycle', () {
    late BusinessJobController c;

    Future<void> loadJob(String status) async {
      client.stub(
        '$_base/business-jobs',
        ok({
          'jobs': [businessJob(7, status)],
        }),
      );
      await c.fetchJobs();
    }

    setUp(() => c = BusinessJobController());

    test('accept posts to business-jobs/{id}/accept and confirms from the '
        'returned status', () async {
      await loadJob(JobStatus.assigned);
      client.stub(
        '$_base/business-jobs/7/accept',
        ok({'job': businessJob(7, JobStatus.accepted)}),
      );

      await c.accept(7);

      expect(posted(), ['$_base/business-jobs/7/accept']);
      expect(c.lastOutcome.value, TransitionOutcome.success);
      expect(c.selectedJob.value!.status, JobStatus.accepted);
    });

    test('start posts to business-jobs/{id}/start', () async {
      await loadJob(JobStatus.accepted);
      client.stub(
        '$_base/business-jobs/7/start',
        ok({'job': businessJob(7, JobStatus.enRoute)}),
      );

      await c.start(7);

      expect(posted(), ['$_base/business-jobs/7/start']);
      expect(c.lastOutcome.value, TransitionOutcome.success);
    });

    test('pickup posts to business-jobs/{id}/pickup', () async {
      await loadJob(JobStatus.enRoute);
      client.stub(
        '$_base/business-jobs/7/pickup',
        ok({'job': businessJob(7, JobStatus.pickedUp)}),
      );

      await c.pickup(7);

      expect(posted(), ['$_base/business-jobs/7/pickup']);
      expect(c.lastOutcome.value, TransitionOutcome.success);
    });

    test('deliver posts to business-jobs/{id}/delivery', () async {
      await loadJob(JobStatus.pickedUp);
      client.stub(
        '$_base/business-jobs/7/delivery',
        ok({'job': businessJob(7, JobStatus.delivered)}),
      );

      await c.deliver(7);

      expect(posted(), ['$_base/business-jobs/7/delivery']);
      expect(c.lastOutcome.value, TransitionOutcome.success);
    });

    test('the whole flow runs end to end in order', () async {
      await loadJob(JobStatus.assigned);
      client
        ..stub('$_base/business-jobs/7/accept',
            ok({'job': businessJob(7, JobStatus.accepted)}))
        ..stub('$_base/business-jobs/7/start',
            ok({'job': businessJob(7, JobStatus.enRoute)}))
        ..stub('$_base/business-jobs/7/pickup',
            ok({'job': businessJob(7, JobStatus.pickedUp)}))
        ..stub('$_base/business-jobs/7/delivery',
            ok({'job': businessJob(7, JobStatus.delivered)}));

      await c.accept(7);
      await c.start(7);
      await c.pickup(7);
      await c.deliver(7);

      expect(posted(), [
        '$_base/business-jobs/7/accept',
        '$_base/business-jobs/7/start',
        '$_base/business-jobs/7/pickup',
        '$_base/business-jobs/7/delivery',
      ]);
      expect(c.selectedJob.value!.status, JobStatus.delivered);
      expect(c.lastOutcome.value, TransitionOutcome.success);
    });

    group('refusals', () {
      test('refuses to act on a job that is not the driver\'s', () async {
        await loadJob(JobStatus.assigned);

        await c.accept(4242);

        expect(c.lastOutcome.value, TransitionOutcome.refused);
        expect(posted(), isEmpty);
      });

      test('a job id known only from a detail fetch IS owned, because that '
          'route is driver-scoped', () async {
        client.stub(
          '$_base/business-jobs/9',
          ok({'job': businessJob(9, JobStatus.assigned)}),
        );
        await c.fetchDetail(9);
        expect(c.ownedJobIds, contains(9));
      });

      test('refuses to deliver a job that was never picked up', () async {
        await loadJob(JobStatus.enRoute);

        await c.deliver(7);

        expect(c.lastOutcome.value, TransitionOutcome.refused);
        expect(posted(), isEmpty);
      });

      test('refuses to re-deliver an already delivered job — the exact bug '
          'that showed "Delivery complete" twice', () async {
        await loadJob(JobStatus.delivered);

        await c.deliver(7);

        expect(c.lastOutcome.value, TransitionOutcome.refused);
        expect(posted(), isEmpty);
      });

      test('refuses to accept a job that is already accepted', () async {
        await loadJob(JobStatus.accepted);
        await c.accept(7);
        expect(c.lastOutcome.value, TransitionOutcome.refused);
        expect(posted(), isEmpty);
      });

      test('refuses every action on a cancelled job', () async {
        await loadJob(JobStatus.cancelled);

        await c.accept(7);
        await c.start(7);
        await c.pickup(7);
        await c.deliver(7);

        expect(c.lastOutcome.value, TransitionOutcome.refused);
        expect(posted(), isEmpty);
      });

      test('refuses to report an exception on a job that is not the '
          'driver\'s', () async {
        await loadJob(JobStatus.enRoute);
        await c.reportException(4242, reason: 'damaged');
        expect(c.lastOutcome.value, TransitionOutcome.refused);
        expect(posted(), isEmpty);
      });

      test('refuses to submit proof for a job that is not the driver\'s',
          () async {
        await loadJob(JobStatus.enRoute);
        await c.submitPickupProof(4242, proofUrl: 'https://x/y.jpg');
        await c.submitDeliveryProof(4242, proofUrl: 'https://x/y.jpg');
        expect(c.lastOutcome.value, TransitionOutcome.refused);
        expect(posted(), isEmpty);
      });
    });

    group('a 2xx is not a success', () {
      test('reports unconfirmed when the server returns the job unchanged',
          () async {
        await loadJob(JobStatus.pickedUp);
        client.stub(
          '$_base/business-jobs/7/delivery',
          ok({'job': businessJob(7, JobStatus.pickedUp)}),
        );

        await c.deliver(7);

        expect(c.lastOutcome.value, TransitionOutcome.unconfirmed);
      });

      test('reports unconfirmed when the server returns no job at all',
          () async {
        await loadJob(JobStatus.pickedUp);
        client.stub('$_base/business-jobs/7/delivery', ok({'message': 'ok'}));

        await c.deliver(7);

        expect(c.lastOutcome.value, TransitionOutcome.unconfirmed);
      });

      test('reports failed when the call throws', () async {
        await loadJob(JobStatus.pickedUp);
        client.throwOnNextCall = Exception('socket closed');

        await c.deliver(7);

        expect(c.lastOutcome.value, TransitionOutcome.failed);
      });
    });

    test('arrival check-in is reported as unsupported, not offered', () {
      expect(c.arrivalCheckInSupported, isFalse);
    });
  });

  // ----------------------------------------------------- marketplace path

  group('marketplace (active-jobs) lifecycle', () {
    late ActiveJobsController c;

    Future<void> loadJob(String status) async {
      client.stub(
        '$_base/active-jobs',
        ok({
          'jobs': [activeJob('11', status)],
        }),
        times: 4,
      );
      await c.fetchActiveJobs();
    }

    setUp(() => c = ActiveJobsController());

    test('start posts to active-jobs/{id}/start', () async {
      await loadJob(JobStatus.accepted);
      client.stub(
        '$_base/active-jobs/11/start',
        ok({
          'job': {'status': JobStatus.enRoute},
        }),
      );

      await c.startJob('11');

      expect(posted(), ['$_base/active-jobs/11/start']);
      expect(c.lastOutcome.value, TransitionOutcome.success);
    });

    test('pickup goes through active-jobs/{id}/status, because no pickup '
        'route exists (CONTRACT-10)', () async {
      await loadJob(JobStatus.enRoute);
      client.stub(
        '$_base/active-jobs/11/status',
        ok({
          'job': {'status': JobStatus.pickedUp},
        }),
      );

      await c.markPickedUp('11');

      final call = client.calls.firstWhere(
        (x) => x.path == '$_base/active-jobs/11/status',
      );
      expect(call.body['driver_task_status'], JobStatus.pickedUp);
      expect(c.lastOutcome.value, TransitionOutcome.success);
    });

    test('pickup is reported unconfirmed if the backend rejects the status '
        'vocabulary by leaving the job where it was', () async {
      await loadJob(JobStatus.enRoute);
      client.stub(
        '$_base/active-jobs/11/status',
        ok({
          'job': {'status': JobStatus.enRoute},
        }),
      );

      await c.markPickedUp('11');

      expect(c.lastOutcome.value, TransitionOutcome.unconfirmed);
    });

    test('complete posts to active-jobs/{id}/complete', () async {
      await loadJob(JobStatus.pickedUp);
      client.stub(
        '$_base/active-jobs/11/complete',
        ok({
          'job': {'status': JobStatus.delivered},
        }),
      );

      await c.completeJob('11');

      expect(posted(), ['$_base/active-jobs/11/complete']);
      expect(c.lastOutcome.value, TransitionOutcome.success);
    });

    test('refuses to act on a job the driver does not hold', () async {
      await loadJob(JobStatus.pickedUp);

      await c.startJob('9999');
      expect(c.lastOutcome.value, TransitionOutcome.refused);

      await c.completeJob('9999');
      expect(c.lastOutcome.value, TransitionOutcome.refused);

      expect(posted(), isEmpty);
    });

    test('refuses to complete a job that was never picked up', () async {
      await loadJob(JobStatus.enRoute);

      await c.completeJob('11');

      expect(c.lastOutcome.value, TransitionOutcome.refused);
      expect(posted(), isEmpty);
    });

    test('refuses to complete an already delivered job', () async {
      await loadJob(JobStatus.delivered);

      await c.completeJob('11');

      expect(c.lastOutcome.value, TransitionOutcome.refused);
      expect(posted(), isEmpty);
    });

    test('refuses to cancel a terminal job', () async {
      await loadJob(JobStatus.completed);

      await c.cancelJob('11');

      expect(c.lastOutcome.value, TransitionOutcome.refused);
      expect(posted(), isEmpty);
    });

    test('the marketplace job list never posts to an accept route — accept '
        'belongs to the load board and its id space (CONTRACT-9)', () async {
      // Each transition refetches, so the list is queued to advance in step
      // with the job: the flow only runs if every gate really passes.
      for (final s in [
        JobStatus.assigned,
        JobStatus.enRoute,
        JobStatus.pickedUp,
        JobStatus.delivered,
      ]) {
        client.stub('$_base/active-jobs', ok({'jobs': [activeJob('11', s)]}));
      }
      await c.fetchActiveJobs();

      client
        ..stub('$_base/active-jobs/11/start',
            ok({'job': {'status': JobStatus.enRoute}}))
        ..stub('$_base/active-jobs/11/status',
            ok({'job': {'status': JobStatus.pickedUp}}))
        ..stub('$_base/active-jobs/11/complete',
            ok({'job': {'status': JobStatus.delivered}}));

      await c.startJob('11');
      await c.markPickedUp('11');
      await c.completeJob('11');

      expect(c.lastOutcome.value, TransitionOutcome.success);

      // The bug being locked out: this controller used to call the
      // load-board accept route with an active-job id.
      expect(posted().where((p) => p.contains('accept')), isEmpty);
      expect(posted().where((p) => p.contains('load-board')), isEmpty);
      expect(posted(), [
        '$_base/active-jobs/11/start',
        '$_base/active-jobs/11/status',
        '$_base/active-jobs/11/complete',
      ]);
    });
  });
}
