/// The driver-side delivery lifecycle, expressed exactly once.
///
/// The UI, the controllers and the tests all read their rules from here so
/// they cannot drift apart. Two things this file exists to prevent:
///
/// 1. Acting on a job the driver does not own. Server-side authorization is
///    the real boundary, but the app must not *offer* an action it has no
///    standing to take, and must not relay a success it cannot attribute.
/// 2. Re-running a transition that already happened. The previous build let a
///    driver tap "Complete Delivery" on an already-delivered job and showed
///    "Delivery complete" again — a success message with no state change
///    behind it.
///
/// ## How the routes behind these transitions were verified
///
/// Every transition here maps to a backend route probed against
/// `https://admin.urbangoodzdelivery.com` on 2026-07-25, read-only.
///
/// A plain `GET` cannot answer the question for these routes: the backend
/// has a catch-all fallback, so a `GET` to a POST-only route and a `GET` to
/// a route that does not exist at all both return the same `302` redirect
/// to the admin site root. The discriminator is an `OPTIONS` request, which
/// Laravel answers with an `Allow` header enumerating the verbs actually
/// registered for that URI:
///
/// * `Allow: GET,HEAD,POST` — a POST route is deployed here.
/// * `Allow: GET,HEAD` — only the fallback matched; no POST route exists.
///
/// `OPTIONS` mutates nothing and needs no token.
///
/// Deployed (`…,POST`): `business-jobs/{id}/{accept,start,pickup,delivery,
/// proof-pickup,proof-delivery,exception}`, `active-jobs/{id}/{start,
/// complete,cancel,status}`, `load-board/{id}/{bid,accept}`.
///
/// Absent (`GET,HEAD` only): every spelling of arrival check-in tried
/// (`business-jobs/{id}/arrived|arrive|arrival|check-in`),
/// `active-jobs/{id}/accept`, `active-jobs/{id}/pickup`, and
/// `job-discovery/{id}/accept`.
///
/// So [JobTransition.arrived] is deliberately modelled as unsupported — see
/// [TransitionRefusal.noBackendEndpoint] and CONTRACT-8 in
/// BACKEND_CONTRACTS.md. It is the one step of the delivery flow the app
/// cannot record, and it says so rather than pretending otherwise.
library;

enum JobTransition { accept, start, arrived, pickup, deliver, reportException }

/// How the last attempted transition actually ended.
///
/// This is deliberately four-valued. The build being replaced had two
/// states — it showed a success snackbar or an error one — which is why a
/// request the server accepted without moving the job read to the driver as
/// a completed step. [unconfirmed] is the state that had no name.
enum TransitionOutcome {
  none,

  /// The server echoed a job whose status proves the transition landed.
  success,

  /// The call returned 2xx but the job did not move. Not a success.
  unconfirmed,

  /// Refused locally, before the network: not owned, wrong status, or no
  /// deployed endpoint.
  refused,

  /// The call threw.
  failed,
}

/// Why a transition was refused. `none` means it was allowed.
enum TransitionRefusal {
  none,

  /// The job is not in the driver's own job list.
  notOwned,

  /// The job's current status does not permit this transition.
  wrongStatus,

  /// The transition is real in the product but has no deployed endpoint.
  /// The app must disable it rather than fake it.
  noBackendEndpoint,
}

class TransitionCheck {
  final bool allowed;
  final TransitionRefusal refusal;
  final String message;

  const TransitionCheck._(this.allowed, this.refusal, this.message);

  static const TransitionCheck allow = TransitionCheck._(
    true,
    TransitionRefusal.none,
    '',
  );

  const TransitionCheck.refuse(this.refusal, this.message) : allowed = false;

  bool get refused => !allowed;
}

/// Canonical driver job statuses, in the order they occur.
class JobStatus {
  static const assigned = 'assigned';
  static const accepted = 'accepted';
  static const enRoute = 'driver_en_route';
  static const arrived = 'arrived';
  static const pickedUp = 'picked_up';
  static const inTransit = 'in_transit';
  static const delayed = 'delayed';
  static const delivered = 'delivered';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
  static const failed = 'failed';

  /// Statuses after which no forward transition is possible.
  static const terminal = <String>{delivered, completed, cancelled, failed};

  static bool isTerminal(String s) => terminal.contains(s);
}

class JobLifecycle {
  /// Statuses from which each transition may legally be started.
  ///
  /// These are deliberately non-overlapping with the transition's own result:
  /// `pickup` is not permitted from `picked_up`, and `deliver` is not
  /// permitted from `delivered`. Re-tapping a completed step is a refusal,
  /// not a second success.
  static const Map<JobTransition, Set<String>> _from = {
    JobTransition.accept: {JobStatus.assigned},
    JobTransition.start: {JobStatus.assigned, JobStatus.accepted},
    JobTransition.arrived: {JobStatus.enRoute},
    JobTransition.pickup: {JobStatus.enRoute, JobStatus.arrived},
    JobTransition.deliver: {
      JobStatus.pickedUp,
      JobStatus.inTransit,
      JobStatus.delayed,
    },
    JobTransition.reportException: {
      JobStatus.assigned,
      JobStatus.accepted,
      JobStatus.enRoute,
      JobStatus.arrived,
      JobStatus.pickedUp,
      JobStatus.inTransit,
      JobStatus.delayed,
    },
  };

  /// Statuses that prove a transition actually landed. Used to verify the
  /// server's echoed job rather than assuming a 2xx means the state moved.
  static const Map<JobTransition, Set<String>> _proves = {
    JobTransition.accept: {JobStatus.accepted, JobStatus.enRoute},
    JobTransition.start: {JobStatus.enRoute},
    JobTransition.arrived: {JobStatus.arrived},
    JobTransition.pickup: {
      JobStatus.pickedUp,
      JobStatus.inTransit,
      JobStatus.delivered,
    },
    JobTransition.deliver: {JobStatus.delivered, JobStatus.completed},
  };

  /// Transitions with no deployed backend route. Probed 2026-07-25.
  static const Set<JobTransition> unsupported = {JobTransition.arrived};

  static bool hasEndpoint(JobTransition t) => !unsupported.contains(t);

  /// The single authorization + state gate. [ownedJobIds] is the set of job
  /// ids the driver actually holds, as returned by their own assigned-jobs
  /// endpoint — never a list the UI assembled from a public feed.
  static TransitionCheck check(
    JobTransition transition, {
    required int jobId,
    required String status,
    required Set<int> ownedJobIds,
  }) {
    if (!ownedJobIds.contains(jobId)) {
      return const TransitionCheck.refuse(
        TransitionRefusal.notOwned,
        'This job is not assigned to you.',
      );
    }
    if (unsupported.contains(transition)) {
      return const TransitionCheck.refuse(
        TransitionRefusal.noBackendEndpoint,
        'Arrival check-in is not available yet.',
      );
    }
    final allowedFrom = _from[transition] ?? const <String>{};
    if (!allowedFrom.contains(status)) {
      return TransitionCheck.refuse(
        TransitionRefusal.wrongStatus,
        _wrongStatusMessage(transition, status),
      );
    }
    return TransitionCheck.allow;
  }

  /// True when [newStatus] returned by the server demonstrates that
  /// [transition] took effect. A 2xx alone is not proof.
  static bool confirms(JobTransition transition, String newStatus) =>
      (_proves[transition] ?? const <String>{}).contains(newStatus);

  static String _wrongStatusMessage(JobTransition t, String status) {
    if (JobStatus.isTerminal(status)) {
      return 'This job is already ${_readable(status)}.';
    }
    return 'Cannot ${_verb(t)} a job that is ${_readable(status)}.';
  }

  static String _verb(JobTransition t) => switch (t) {
    JobTransition.accept => 'accept',
    JobTransition.start => 'start',
    JobTransition.arrived => 'check in at',
    JobTransition.pickup => 'pick up',
    JobTransition.deliver => 'deliver',
    JobTransition.reportException => 'report an exception on',
  };

  static String _readable(String status) => status.replaceAll('_', ' ');
}
