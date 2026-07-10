import 'package:get/get.dart';
import 'package:urban_goodz_driver/models/certification_model.dart';
import 'package:urban_goodz_driver/repositories/mock_driver_data.dart';

class CertificationsController extends GetxController {
  final MockCertificationRepository _repository = MockCertificationRepository();

  var certifications = <CertificationModel>[].obs;
  var validCount = 0.obs;
  var expiredCount = 0.obs;
  var pendingCount = 0.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchCertifications();
    super.onInit();
  }

  void fetchCertifications() {
    isLoading.value = true;
    _repository.fetchCertifications().then((certs) {
      certifications.value = certs;
      validCount.value = certs.where((c) => c.status == 'valid').length;
      expiredCount.value = certs.where((c) => c.status == 'expired').length;
      pendingCount.value = certs.where((c) => c.status == 'pending').length;
      isLoading.value = false;
    });
  }

  void uploadDocument(String certId) {
    _repository.uploadDocument(certId).then((success) {
      if (success) {
        final idx = certifications.indexWhere((c) => c.id == certId);
        if (idx != -1) {
          final updated = CertificationModel(
            id: certifications[idx].id,
            name: certifications[idx].name,
            issuingAuthority: certifications[idx].issuingAuthority,
            issueDate: certifications[idx].issueDate,
            expiryDate: certifications[idx].expiryDate,
            status: certifications[idx].status,
            documentUrl: 'documents/uploaded_${certId.toLowerCase()}.pdf',
            isRequired: certifications[idx].isRequired,
          );
          certifications[idx] = updated;
        }
        Get.snackbar('Uploaded', 'Document uploaded successfully.',
            snackPosition: SnackPosition.BOTTOM);
      }
    });
  }

  void renewCertification(String id) {
    _repository.renewCertification(id).then((success) {
      if (success) {
        final idx = certifications.indexWhere((c) => c.id == id);
        if (idx != -1) {
          final updated = CertificationModel(
            id: certifications[idx].id,
            name: certifications[idx].name,
            issuingAuthority: certifications[idx].issuingAuthority,
            issueDate: certifications[idx].issueDate,
            expiryDate: certifications[idx].expiryDate,
            status: 'pending',
            documentUrl: certifications[idx].documentUrl,
            isRequired: certifications[idx].isRequired,
          );
          certifications[idx] = updated;
          fetchCertifications();
        }
        Get.snackbar('Renewal Requested',
            'Your renewal application has been submitted for review.',
            snackPosition: SnackPosition.BOTTOM);
      }
    });
  }
}
