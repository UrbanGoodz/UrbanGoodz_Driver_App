import 'package:get/get.dart';
import 'package:urban_goodz_driver/utils/driver_notice.dart';
import 'package:urban_goodz_driver/models/driver_job_model.dart';
import 'package:urban_goodz_driver/models/job_lifecycle.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';

class ActiveJobsController extends GetxController {
  DriverApiService get _api => Get.find<DriverApiService>();

  var activeJobs = <DriverJobModel>[].obs;
  var filteredJobs = <DriverJobModel>[].obs;
  var selectedFilter = 'all'.obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  /// How the last attempted transition ended. Distinguishes a real state
  /// change from a request the server accepted without moving the job.
  var lastOutcome = TransitionOutcome.none.obs;

  @override
  void onInit() {
    fetchActiveJobs();
    super.onInit();
  }

  Future<void> fetchActiveJobs() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final jobsData = await _api.getActiveJobs();
      final jobs = jobsData.map((e) => DriverJobModel.fromJson(e)).toList();
      activeJobs.value = jobs;
      filterByType(selectedFilter.value);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void filterByType(String type) {
    selectedFilter.value = type;
    if (type == 'all') {
      filteredJobs.value = List.from(activeJobs);
    } else {
      filteredJobs.value = activeJobs.where((job) => job.type == type).toList();
    }
  }

  /// Job ids the driver actually holds, taken only from their own
  /// `active-jobs` response. Any id not in here is refused before the
  /// network is touched.
  Set<int> get ownedJobIds =>
      activeJobs.map((j) => int.tryParse(j.id)).whereType<int>().toSet();

  DriverJobModel? _ownedJob(String id) {
    final jobId = int.tryParse(id);
    if (jobId == null) return null;
    for (final j in activeJobs) {
      if (int.tryParse(j.id) == jobId) return j;
    }
    return null;
  }

  /// There is no `POST /active-jobs/{id}/accept` on the backend (probed
  /// 2026-07-25: 405). Accepting work happens on the load board, against a
  /// *load* id — a different id space. The previous implementation called
  /// `acceptLoad()` with an active-job id, which is both a wrong-endpoint
  /// bug and a route by which a driver could act on a load that was not
  /// theirs. Accept now lives only on LoadBoardController.
  ///
  /// Deliberately not reinstated here. See CONTRACT-9.

  Future<void> startJob(String id, {String? source}) => _transition(
    id,
    JobTransition.start,
    (jobId, src) => _api.startActiveJob(jobId, source: src),
    'You are en route.',
    source: source,
  );

  /// POST `/api/v1/urban-goodz/driver/active-jobs/{id}/status` — deployed
  /// (OPTIONS -> `Allow: GET,HEAD,POST`, 2026-07-25).
  ///
  /// The marketplace path has no dedicated pickup route: `active-jobs/{id}/
  /// pickup` answers `Allow: GET,HEAD` (fallback only), so it does not
  /// exist. Pickup is therefore recorded through the generic status route.
  /// The set of `driver_task_status` values the backend accepts is
  /// undocumented — see CONTRACT-10. If the backend rejects this value the
  /// call throws and the driver is told it failed; if it returns 2xx without
  /// moving the job, the driver is told it is unconfirmed. Neither path
  /// reports a pickup that did not happen.
  Future<void> markPickedUp(String id, {String? source}) => _transition(
    id,
    JobTransition.pickup,
    (jobId, source) =>
        _api.updateActiveJobStatus(jobId, JobStatus.pickedUp, source: source),
    'Pickup recorded.',
    source: source,
  );

  Future<void> completeJob(
    String id, {
    String? recipientName,
    String? source,
  }) => _transition(
    id,
    JobTransition.deliver,
    (jobId, source) => _api.completeActiveJob(
      jobId,
      recipientName: recipientName,
      source: source,
    ),
    'Delivery complete.',
    source: source,
  );

  Future<void> cancelJob(String id, {String? source}) async {
    final job = _ownedJob(id);
    if (job == null) {
      lastOutcome.value = TransitionOutcome.refused;
      _fail('This job is not assigned to you.');
      return;
    }
    if (JobStatus.isTerminal(job.status)) {
      lastOutcome.value = TransitionOutcome.refused;
      _fail('This job is already ${job.status.replaceAll('_', ' ')}.');
      return;
    }
    try {
      await _api.cancelActiveJob(
        int.parse(job.id),
        source: _pick(source, job.source),
      );
      await fetchActiveJobs();
      lastOutcome.value = TransitionOutcome.success;
      showNotice('Job Cancelled', 'The job has been removed from your list.');
    } catch (e) {
      lastOutcome.value = TransitionOutcome.failed;
      _fail('Failed to cancel job: $e');
    }
  }

  /// Shared gate: ownership, then status, then the call, then confirmation
  /// from the status the server echoes back. A 2xx that leaves the job in
  /// its old status is reported as unconfirmed rather than as success.
  ///
  /// Note on earnings: completion no longer claims "Earnings have been
  /// added." The completion response is not an earnings receipt, and the
  /// app has no way to prove a wallet credit from it. Earnings are shown
  /// from the earnings endpoint only.
  Future<void> _transition(
    String id,
    JobTransition transition,
    Future<Map<String, dynamic>> Function(int jobId, String? source) call,
    String successMsg, {
    String? source,
  }) async {
    final job = _ownedJob(id);
    if (job == null) {
      lastOutcome.value = TransitionOutcome.refused;
      _fail('This job is not assigned to you.');
      return;
    }
    final gate = JobLifecycle.check(
      transition,
      jobId: int.parse(job.id),
      status: job.status,
      ownedJobIds: ownedJobIds,
    );
    if (gate.refused) {
      lastOutcome.value = TransitionOutcome.refused;
      _fail(gate.message);
      return;
    }
    try {
      final updated = await call(int.parse(job.id), _pick(source, job.source));
      await fetchActiveJobs();
      final newStatus = updated['status']?.toString() ?? '';
      if (newStatus.isEmpty || !JobLifecycle.confirms(transition, newStatus)) {
        lastOutcome.value = TransitionOutcome.unconfirmed;
        showNotice(
          'Not confirmed',
          newStatus.isEmpty
              ? 'The server accepted the request but did not report a new '
                    'status. Refresh to check.'
              : 'The server accepted the request but the job is still '
                    '"$newStatus". Refresh before retrying.',
        );
        return;
      }
      lastOutcome.value = TransitionOutcome.success;
      showNotice('Updated', successMsg);
    } catch (e) {
      lastOutcome.value = TransitionOutcome.failed;
      if (e is ApiException && e.code == 'recipient_required') {
        _fail('Enter the name of the person who received the delivery.');
        return;
      }
      _fail('Failed: $e');
    }
  }

  /// An explicit caller-supplied source wins; otherwise the job's own.
  String? _pick(String? explicit, String? own) =>
      (explicit != null && explicit.trim().isNotEmpty) ? explicit : own;

  void _fail(String message) => showNotice('Action not allowed', message);
}
