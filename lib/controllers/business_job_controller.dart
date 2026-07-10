import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/models/business_job_model.dart';

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

  // Statuses that permit each action (per Session 2 contract state machine).
  bool canAccept(String s) => s == 'assigned';
  bool canStart(String s) => s == 'assigned' || s == 'driver_en_route';
  bool canPickup(String s) => s == 'driver_en_route' || s == 'picked_up';
  bool canDeliver(String s) =>
      s == 'picked_up' || s == 'in_transit' || s == 'delayed' || s == 'delivered';
  bool canReportException(String s) =>
      ['assigned', 'driver_en_route', 'picked_up', 'in_transit', 'delayed']
          .contains(s);

  Future<void> fetchJobs() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      jobs.value = await _api.getBusinessJobs();
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
      selectedJob.value = await _api.getBusinessJobDetail(jobId);
    } catch (e) {
      errorMessage.value = _msg(e);
    } finally {
      isDetailLoading.value = false;
    }
  }

  Future<void> _run(
      Future<BusinessJobModel> Function() call, String successMsg) async {
    actionLoading.value = true;
    try {
      final updated = await call();
      _replace(updated);
      selectedJob.value = updated;
      Get.snackbar('Success', successMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Action failed', _msg(e),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    } finally {
      actionLoading.value = false;
    }
  }

  void accept(int jobId) =>
      _run(() => _api.acceptBusinessJob(jobId), 'Job accepted');
  void start(int jobId) => _run(() => _api.startBusinessJob(jobId), 'Job started');
  void pickup(int jobId) =>
      _run(() => _api.pickupBusinessJob(jobId), 'Pickup complete');
  void deliver(int jobId) =>
      _run(() => _api.deliverBusinessJob(jobId), 'Delivery complete');

  Future<void> submitPickupProof(int jobId,
      {required String proofUrl, String? notes}) async {
    actionLoading.value = true;
    try {
      final url =
          await _api.submitPickupProof(jobId, proofUrl: proofUrl, notes: notes);
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
      Get.snackbar('Success', 'Pickup proof submitted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Failed', _msg(e),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    } finally {
      actionLoading.value = false;
    }
  }

  Future<void> submitDeliveryProof(int jobId,
      {required String proofUrl, String? notes}) async {
    actionLoading.value = true;
    try {
      final url = await _api.submitDeliveryProof(jobId,
          proofUrl: proofUrl, notes: notes);
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
      Get.snackbar('Success', 'Delivery proof submitted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Failed', _msg(e),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    } finally {
      actionLoading.value = false;
    }
  }

  Future<void> reportException(int jobId,
      {required String reason, String? notes}) async {
    actionLoading.value = true;
    try {
      final updated = await _api.reportException(jobId,
          reason: reason, notes: notes);
      _replace(updated);
      selectedJob.value = updated;
      Get.snackbar('Reported', 'Exception submitted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Failed', _msg(e),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
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
