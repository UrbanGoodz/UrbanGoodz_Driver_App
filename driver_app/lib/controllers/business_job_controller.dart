import 'package:flutter/material.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/utils/driver_notice.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/models/business_job_model.dart';
import 'package:urban_goodz_driver/models/job_lifecycle.dart';

/// Manages assigned business courier jobs: list, detail, and the
/// accept/start/pickup/delivery state machine plus proof + exception.
class BusinessJobController extends GetxController {
  final DriverApiService _api = Get.find<DriverApiService>();

  var jobs = <BusinessJobModel>[].obs;
  var selectedJob = Rxn<BusinessJobModel>();
  var isLoading = false.obs;
  var isDetailLoading = false.obs;
  var actionLoading = false.obs;
  var errorMessage = ''.obs;

  /// How the last attempted transition ended. Distinguishes a real state
  /// change from a request the server accepted without moving the job.
  var lastOutcome = TransitionOutcome.none.obs;

  /// Job ids this driver actually holds. Only ever populated from the
  /// driver-scoped, token-authorized endpoints (`business-jobs` and
  /// `business-jobs/{id}`); a successful response from either is the
  /// backend asserting ownership. Nothing else may add to this set, so a
  /// job id arriving from a deep link or a public feed cannot be acted on.
  final Set<int> _ownedJobIds = <int>{};

  Set<int> get ownedJobIds => Set.unmodifiable(_ownedJobIds);

  /// Visible for tests: the single gate every action passes through.
  TransitionCheck check(JobTransition t, BusinessJobModel job) =>
      JobLifecycle.check(
        t,
        jobId: job.jobId,
        status: job.status,
        ownedJobIds: _ownedJobIds,
      );

  bool canAccept(BusinessJobModel j) => check(JobTransition.accept, j).allowed;
  bool canStart(BusinessJobModel j) => check(JobTransition.start, j).allowed;
  bool canPickup(BusinessJobModel j) => check(JobTransition.pickup, j).allowed;
  bool canDeliver(BusinessJobModel j) => check(JobTransition.deliver, j).allowed;
  bool canReportException(BusinessJobModel j) =>
      check(JobTransition.reportException, j).allowed;

  /// Arrival check-in has no deployed endpoint. Probed 2026-07-25 under
  /// four spellings (`arrived`, `arrive`, `arrival`, `check-in`); all
  /// answer `Allow: GET,HEAD`, i.e. only the catch-all fallback matched.
  /// Surfaced so the UI can show the step as unavailable rather than omit
  /// it silently or pretend it succeeded. See CONTRACT-8.
  bool get arrivalCheckInSupported => JobLifecycle.hasEndpoint(
    JobTransition.arrived,
  );

  Future<void> fetchJobs() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final fetched = await _api.getBusinessJobs();
      jobs.value = fetched;
      _ownedJobIds
        ..clear()
        ..addAll(fetched.map((j) => j.jobId));
    } catch (e) {
      errorMessage.value = _msg(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDetail(int jobId) async {
    isDetailLoading.value = true;
    errorMessage.value = '';
    try {
      final job = await _api.getBusinessJobDetail(jobId);
      selectedJob.value = job;
      // The detail route is driver-scoped: a 2xx here is the backend
      // confirming this job belongs to the caller.
      if (job.jobId != 0) _ownedJobIds.add(job.jobId);
    } catch (e) {
      errorMessage.value = _msg(e);
    } finally {
      isDetailLoading.value = false;
    }
  }

  /// Runs one lifecycle transition.
  ///
  /// Refuses before touching the network if the driver does not own the job
  /// or the status does not permit the move, and — critically — only reports
  /// success when the job the server echoes back actually shows the new
  /// state. A 2xx with an unchanged status is reported as unconfirmed, not
  /// as "done". This is the specific failure this recovery exists to remove.
  Future<void> _run(
    JobTransition transition,
    int jobId,
    Future<BusinessJobModel> Function() call,
    String successMsg,
  ) async {
    final job = _jobById(jobId);
    if (job == null) {
      lastOutcome.value = TransitionOutcome.refused;
      _fail('This job is not assigned to you.');
      return;
    }
    final gate = check(transition, job);
    if (gate.refused) {
      lastOutcome.value = TransitionOutcome.refused;
      _fail(gate.message);
      return;
    }

    actionLoading.value = true;
    try {
      final updated = await call();
      _replace(updated);
      selectedJob.value = updated;

      if (!JobLifecycle.confirms(transition, updated.status)) {
        lastOutcome.value = TransitionOutcome.unconfirmed;
        // The call was accepted but the job did not move. Say exactly that
        // rather than claiming the step completed.
        showNotice(
          'Not confirmed',
          'The server accepted the request but the job is still '
              '"${updated.status}". Pull to refresh before retrying.',
          background: Colors.orange,
          text: Colors.white,
        );
        return;
      }

      lastOutcome.value = TransitionOutcome.success;
      showNotice(
        'Success',
        successMsg,
        background: AppTheme.primary,
        text: Colors.white,
      );
    } catch (e) {
      lastOutcome.value = TransitionOutcome.failed;
      showNotice(
        'Action failed',
        _msg(e),
        background: Colors.redAccent,
        text: Colors.white,
      );
    } finally {
      actionLoading.value = false;
    }
  }

  Future<void> accept(int jobId) => _run(
    JobTransition.accept,
    jobId,
    () => _api.acceptBusinessJob(jobId),
    'Job accepted',
  );

  Future<void> start(int jobId) => _run(
    JobTransition.start,
    jobId,
    () => _api.startBusinessJob(jobId),
    'You are en route',
  );

  Future<void> pickup(int jobId) => _run(
    JobTransition.pickup,
    jobId,
    () => _api.pickupBusinessJob(jobId),
    'Pickup complete',
  );

  Future<void> deliver(int jobId) => _run(
    JobTransition.deliver,
    jobId,
    () => _api.deliverBusinessJob(jobId),
    'Delivery complete',
  );

  BusinessJobModel? _jobById(int jobId) {
    final selected = selectedJob.value;
    if (selected != null && selected.jobId == jobId) return selected;
    for (final j in jobs) {
      if (j.jobId == jobId) return j;
    }
    return null;
  }

  void _fail(String message) => showNotice(
    'Action not allowed',
    message,
    background: Colors.redAccent,
    text: Colors.white,
  );

  Future<void> submitPickupProof(
    int jobId, {
    required String proofUrl,
    String? notes,
  }) async {
    if (!_ownedJobIds.contains(jobId)) {
      lastOutcome.value = TransitionOutcome.refused;
      _fail('This job is not assigned to you.');
      return;
    }
    actionLoading.value = true;
    try {
      final url = await _api.submitPickupProof(
        jobId,
        proofUrl: proofUrl,
        notes: notes,
      );
      if (selectedJob.value != null) {
        final j = selectedJob.value!;
        selectedJob.value = BusinessJobModel(
          jobId: j.jobId,
          jobNumber: j.jobNumber,
          businessClientId: j.businessClientId,
          businessClientName: j.businessClientName,
          jobType: j.jobType,
          status: j.status,
          description: j.description,
          referenceNumber: j.referenceNumber,
          poNumber: j.poNumber,
          pickup: j.pickup,
          dropoff: j.dropoff,
          requirements: j.requirements,
          pricing: j.pricing,
          driverNotes: j.driverNotes,
          exception: j.exception,
          proof: JobProof(
            proofOfPickup: url,
            proofOfDelivery: j.proof.proofOfDelivery,
            pickupProofSubmitted: true,
            deliveryProofSubmitted: j.proof.deliveryProofSubmitted,
          ),
          hasException: j.hasException,
        );
      }
      showNotice(
        'Success',
        'Pickup proof submitted',
        background: AppTheme.primary,
        text: Colors.white,
      );
    } catch (e) {
      showNotice(
        'Failed',
        _msg(e),
        background: Colors.redAccent,
        text: Colors.white,
      );
    } finally {
      actionLoading.value = false;
    }
  }

  Future<void> submitDeliveryProof(
    int jobId, {
    required String proofUrl,
    String? notes,
  }) async {
    if (!_ownedJobIds.contains(jobId)) {
      lastOutcome.value = TransitionOutcome.refused;
      _fail('This job is not assigned to you.');
      return;
    }
    actionLoading.value = true;
    try {
      final url = await _api.submitDeliveryProof(
        jobId,
        proofUrl: proofUrl,
        notes: notes,
      );
      if (selectedJob.value != null) {
        final j = selectedJob.value!;
        selectedJob.value = BusinessJobModel(
          jobId: j.jobId,
          jobNumber: j.jobNumber,
          businessClientId: j.businessClientId,
          businessClientName: j.businessClientName,
          jobType: j.jobType,
          status: j.status,
          description: j.description,
          referenceNumber: j.referenceNumber,
          poNumber: j.poNumber,
          pickup: j.pickup,
          dropoff: j.dropoff,
          requirements: j.requirements,
          pricing: j.pricing,
          driverNotes: j.driverNotes,
          exception: j.exception,
          proof: JobProof(
            proofOfPickup: j.proof.proofOfPickup,
            proofOfDelivery: url,
            pickupProofSubmitted: j.proof.pickupProofSubmitted,
            deliveryProofSubmitted: true,
          ),
          hasException: j.hasException,
        );
      }
      showNotice(
        'Success',
        'Delivery proof submitted',
        background: AppTheme.primary,
        text: Colors.white,
      );
    } catch (e) {
      showNotice(
        'Failed',
        _msg(e),
        background: Colors.redAccent,
        text: Colors.white,
      );
    } finally {
      actionLoading.value = false;
    }
  }

  Future<void> reportException(
    int jobId, {
    required String reason,
    String? notes,
  }) async {
    final job = _jobById(jobId);
    if (job == null) {
      lastOutcome.value = TransitionOutcome.refused;
      _fail('This job is not assigned to you.');
      return;
    }
    final gate = check(JobTransition.reportException, job);
    if (gate.refused) {
      lastOutcome.value = TransitionOutcome.refused;
      _fail(gate.message);
      return;
    }
    actionLoading.value = true;
    try {
      final updated = await _api.reportException(
        jobId,
        reason: reason,
        notes: notes,
      );
      _replace(updated);
      selectedJob.value = updated;
      showNotice(
        'Reported',
        'Exception submitted',
        background: Colors.orange,
        text: Colors.white,
      );
    } catch (e) {
      showNotice(
        'Failed',
        _msg(e),
        background: Colors.redAccent,
        text: Colors.white,
      );
    } finally {
      actionLoading.value = false;
    }
  }

  void _replace(BusinessJobModel updated) {
    final idx = jobs.indexWhere((j) => j.jobId == updated.jobId);
    if (idx != -1) {
      jobs[idx] = updated;
      jobs.refresh();
    } else {
      jobs.add(updated);
    }
  }

  String _msg(Object e) => e is ApiException ? e.message : e.toString();
}
