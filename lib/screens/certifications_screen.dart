import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/certifications_controller.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class CertificationsScreen extends StatefulWidget {
  const CertificationsScreen({super.key});

  @override
  State<CertificationsScreen> createState() => _CertificationsScreenState();
}

class _CertificationsScreenState extends State<CertificationsScreen> {
  final CertificationsController controller =
      Get.put(CertificationsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchCertifications(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatBadge(
                    label: 'Valid',
                    count: controller.validCount.value,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 10),
                  _StatBadge(
                    label: 'Expired',
                    count: controller.expiredCount.value,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 10),
                  _StatBadge(
                    label: 'Pending',
                    count: controller.pendingCount.value,
                    color: AppTheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('All Certifications',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...controller.certifications.map((cert) {
                Color statusColor;
                switch (cert.status) {
                  case 'valid':
                    statusColor = Colors.green;
                    break;
                  case 'expired':
                    statusColor = Colors.red;
                    break;
                  case 'pending':
                    statusColor = AppTheme.primary;
                    break;
                  default:
                    statusColor = AppTheme.dark;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withAlpha(60),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.dark.withAlpha(10),
                          blurRadius: 6)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              cert.status == 'valid'
                                  ? Icons.verified
                                  : cert.status == 'expired'
                                      ? Icons.error_outline
                                      : Icons.hourglass_empty,
                              color: statusColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cert.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                Text(cert.issuingAuthority,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.dark
                                            .withAlpha(150))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              cert.status[0].toUpperCase() +
                                  cert.status.substring(1),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14,
                              color: AppTheme.dark.withAlpha(120)),
                          const SizedBox(width: 4),
                          Text('Issued: ${cert.issueDate}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      AppTheme.dark.withAlpha(120))),
                          const SizedBox(width: 16),
                          Icon(Icons.event,
                              size: 14,
                              color: cert.status == 'expired'
                                  ? Colors.red
                                  : AppTheme.dark.withAlpha(120)),
                          const SizedBox(width: 4),
                          Text('Expires: ${cert.expiryDate}',
                              style: TextStyle(
                                fontSize: 12,
                                color: cert.status == 'expired'
                                    ? Colors.red
                                    : AppTheme.dark.withAlpha(120),
                              )),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (cert.isRequired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.dark.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('REQUIRED',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.dark)),
                            ),
                          const Spacer(),
                          if (cert.status == 'valid' && cert.documentUrl.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.file_present,
                                  size: 16),
                              label: const Text('View',
                                  style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue),
                            ),
                          if (cert.status == 'expired')
                            ElevatedButton(
                              onPressed: () =>
                                  controller.renewCertification(cert.id),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                backgroundColor: AppTheme.primary,
                              ),
                              child: const Text('Renew',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          if (cert.status == 'pending')
                            ElevatedButton(
                              onPressed: () =>
                                  controller.uploadDocument(cert.id),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text('Upload',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      if (cert.status == 'pending')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 0.3,
                              minHeight: 4,
                              backgroundColor: AppTheme.beige,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      AppTheme.primary),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: AppTheme.dark.withAlpha(15), blurRadius: 8)
          ],
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                )),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 13, color: AppTheme.dark.withAlpha(150))),
          ],
        ),
      ),
    );
  }
}
