import 'package:flutter_test/flutter_test.dart';
import 'package:urban_goodz_driver/models/job_lifecycle.dart';

/// Unit tests for the lifecycle gate itself, with no controller, no
/// service and no network in the way.
///
/// The two properties that matter here are refusals, not permissions: a
/// driver must not be able to act on a job that is not theirs, and must not
/// be able to re-run a step that already happened. Both were possible in the
/// build this recovery is undoing.
void main() {
  const mine = {7, 8};

  group('ownership', () {
    test('refuses every transition on a job the driver does not own', () {
      for (final t in JobTransition.values) {
        final check = JobLifecycle.check(
          t,
          jobId: 99,
          status: JobStatus.assigned,
          ownedJobIds: mine,
        );
        expect(check.refused, isTrue, reason: '$t on an unowned job');
        expect(check.refusal, TransitionRefusal.notOwned, reason: '$t');
        expect(check.message, 'This job is not assigned to you.');
      }
    });

    test('ownership is checked before status, so an unowned job in a '
        'legal status is still refused', () {
      final check = JobLifecycle.check(
        JobTransition.accept,
        jobId: 99,
        status: JobStatus.assigned,
        ownedJobIds: mine,
      );
      expect(check.refusal, TransitionRefusal.notOwned);
    });

    test('an empty owned set refuses everything', () {
      final check = JobLifecycle.check(
        JobTransition.start,
        jobId: 7,
        status: JobStatus.assigned,
        ownedJobIds: const {},
      );
      expect(check.refusal, TransitionRefusal.notOwned);
    });
  });

  group('the happy path, one step at a time', () {
    void allowed(JobTransition t, String from) {
      test('$t is allowed from $from', () {
        final check = JobLifecycle.check(
          t,
          jobId: 7,
          status: from,
          ownedJobIds: mine,
        );
        expect(check.allowed, isTrue, reason: check.message);
      });
    }

    allowed(JobTransition.accept, JobStatus.assigned);
    allowed(JobTransition.start, JobStatus.assigned);
    allowed(JobTransition.start, JobStatus.accepted);
    allowed(JobTransition.pickup, JobStatus.enRoute);
    allowed(JobTransition.pickup, JobStatus.arrived);
    allowed(JobTransition.deliver, JobStatus.pickedUp);
    allowed(JobTransition.deliver, JobStatus.inTransit);
    allowed(JobTransition.deliver, JobStatus.delayed);
    allowed(JobTransition.reportException, JobStatus.enRoute);
    allowed(JobTransition.reportException, JobStatus.pickedUp);
  });

  group('refusing a step that already happened', () {
    test('cannot deliver a job that is already delivered', () {
      final check = JobLifecycle.check(
        JobTransition.deliver,
        jobId: 7,
        status: JobStatus.delivered,
        ownedJobIds: mine,
      );
      expect(check.refused, isTrue);
      expect(check.refusal, TransitionRefusal.wrongStatus);
      expect(check.message, 'This job is already delivered.');
    });

    test('cannot pick up a job that is already picked up', () {
      final check = JobLifecycle.check(
        JobTransition.pickup,
        jobId: 7,
        status: JobStatus.pickedUp,
        ownedJobIds: mine,
      );
      expect(check.refused, isTrue);
      expect(check.refusal, TransitionRefusal.wrongStatus);
    });

    test('cannot accept a job that is already accepted', () {
      final check = JobLifecycle.check(
        JobTransition.accept,
        jobId: 7,
        status: JobStatus.accepted,
        ownedJobIds: mine,
      );
      expect(check.refusal, TransitionRefusal.wrongStatus);
    });

    test('no forward transition survives a terminal status', () {
      for (final terminal in JobStatus.terminal) {
        for (final t in JobTransition.values) {
          final check = JobLifecycle.check(
            t,
            jobId: 7,
            status: terminal,
            ownedJobIds: mine,
          );
          expect(
            check.refused,
            isTrue,
            reason: '$t should be refused from $terminal',
          );
        }
      }
    });
  });

  group('running steps out of order', () {
    test('cannot deliver before pickup', () {
      final check = JobLifecycle.check(
        JobTransition.deliver,
        jobId: 7,
        status: JobStatus.enRoute,
        ownedJobIds: mine,
      );
      expect(check.refused, isTrue);
      expect(check.refusal, TransitionRefusal.wrongStatus);
      expect(check.message, 'Cannot deliver a job that is driver en route.');
    });

    test('cannot pick up before starting', () {
      final check = JobLifecycle.check(
        JobTransition.pickup,
        jobId: 7,
        status: JobStatus.assigned,
        ownedJobIds: mine,
      );
      expect(check.refusal, TransitionRefusal.wrongStatus);
    });

    test('cannot report an exception on a cancelled job', () {
      final check = JobLifecycle.check(
        JobTransition.reportException,
        jobId: 7,
        status: JobStatus.cancelled,
        ownedJobIds: mine,
      );
      expect(check.refusal, TransitionRefusal.wrongStatus);
    });
  });

  group('arrival check-in has no endpoint (CONTRACT-8)', () {
    test('is reported as unsupported rather than allowed', () {
      expect(JobLifecycle.hasEndpoint(JobTransition.arrived), isFalse);
    });

    test('is refused even from the status it would be legal from', () {
      final check = JobLifecycle.check(
        JobTransition.arrived,
        jobId: 7,
        status: JobStatus.enRoute,
        ownedJobIds: mine,
      );
      expect(check.refused, isTrue);
      expect(check.refusal, TransitionRefusal.noBackendEndpoint);
      expect(check.message, 'Arrival check-in is not available yet.');
    });

    test('every other transition does have an endpoint', () {
      for (final t in JobTransition.values) {
        if (t == JobTransition.arrived) continue;
        expect(JobLifecycle.hasEndpoint(t), isTrue, reason: '$t');
      }
    });
  });

  group('confirmation — a 2xx is not proof the job moved', () {
    test('a status that shows the move confirms it', () {
      expect(JobLifecycle.confirms(JobTransition.start, JobStatus.enRoute),
          isTrue);
      expect(JobLifecycle.confirms(JobTransition.pickup, JobStatus.pickedUp),
          isTrue);
      expect(JobLifecycle.confirms(JobTransition.deliver, JobStatus.delivered),
          isTrue);
      expect(JobLifecycle.confirms(JobTransition.accept, JobStatus.accepted),
          isTrue);
    });

    test('an unchanged status does not confirm the move', () {
      expect(JobLifecycle.confirms(JobTransition.start, JobStatus.assigned),
          isFalse);
      expect(JobLifecycle.confirms(JobTransition.pickup, JobStatus.enRoute),
          isFalse);
      expect(JobLifecycle.confirms(JobTransition.deliver, JobStatus.pickedUp),
          isFalse);
    });

    test('an empty or unknown status does not confirm the move', () {
      expect(JobLifecycle.confirms(JobTransition.deliver, ''), isFalse);
      expect(
        JobLifecycle.confirms(JobTransition.deliver, 'something_else'),
        isFalse,
      );
    });
  });
}
