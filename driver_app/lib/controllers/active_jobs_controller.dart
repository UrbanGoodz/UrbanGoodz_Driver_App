import 'package:get/get.dart';
import 'package:urban_goodz_driver/models/driver_job_model.dart';
import 'package:urban_goodz_driver/models/job_lifecycle.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';

class ActiveJobsController extends GetxController {
  DriverApiService get _api => Get.find<DriverApiService>();

  var activeJobs = <DriverJobModel>[].obs;
  var filteredJobs = <DriverJobModel>[].obs;
  var selectedFilter = 'all'.obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    fetchActiveJobs();
    super.onInit();
  }

  void fetchActiveJobs() async {
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
  Set<int> get ownedJobIds => activeJobs
      .map((j) => int.tryParse(j.id))
      .whereType<int>()
      .toSet();

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

  Future<void> startJob(String id) =>
      _transition(id, JobTransition.start, (jobId) => _api.startActiveJob(jobId),
          'You are en route.');

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
  Future<void> markPickedUp(String id) => _transition(
        id,
        JobTransition.pickup,
        (jobId) => _api.updateActiveJobStatus(jobId, JobStatus.pickedUp),
        'Pickup recorded.',
      );

  Future<void> completeJob(String id) => _transition(
        id,
        JobTransition.deliver,
        (jobId) => _api.completeActiveJob(jobId),
        'Delivery complete.',
      );

  Future<void> cancelJob(String id) async {
    final job = _ownedJob(id);
    if (job == null) {
      _fail('This job is not assigned to you.');
      return;
    }
    if (JobStatus.isTerminal(job.status)) {
      _fail('This job is already ${job.status.replaceAll('_', ' ')}.');
      return;
    }
    try {
      await _api.cancelActiveJob(int.parse(job.id));
      fetchActiveJobs();
      Get.snackbar(
        'Job Cancelled',
        'The job has been removed from your list.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
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
    Future<Map<String, dynamic>> Function(int jobId) call,
    String successMsg,
  ) async {
    final job = _ownedJob(id);
    if (job == null) {
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
      _fail(gate.message);
      return;
    }
    try {
      final updated = await call(int.parse(job.id));
      fetchActiveJobs();
      final newStatus = updated['status']?.toString() ?? '';
      if (newStatus.isEmpty || !JobLifecycle.confirms(transition, newStatus)) {
        Get.snackbar(
          'Not confirmed',
          newStatus.isEmpty
              ? 'The server accepted the request but did not report a new '
                  'status. Refresh to check.'
              : 'The server accepted the request but the job is still '
                  '"$newStatus". Refresh before retrying.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      Get.snackbar(
        'Updated',
        successMsg,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _fail('Failed: $e');
    }
  }

  void _fail(String message) => Get.snackbar(
        'Action not allowed',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
}
