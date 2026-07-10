import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:urban_goodz_driver/models/driver_job_model.dart';
import 'package:urban_goodz_driver/models/earnings_model.dart';
import 'package:urban_goodz_driver/models/opportunity_model.dart';
import 'package:urban_goodz_driver/models/vehicle_model.dart';
import 'package:urban_goodz_driver/models/certification_model.dart';
import 'package:urban_goodz_driver/models/payout_model.dart';

class MapPoint {
  final double lat;
  final double lng;
  final String address;

  MapPoint({required this.lat, required this.lng, required this.address});
}

class MockDashboardRepository {
  Future<double> fetchTodayEarnings() async => 187.50;
  Future<double> fetchWeeklyEarnings() async => 1245.75;
  Future<double> fetchMonthlyEarnings() async => 4872.30;
  Future<int> fetchCompletedJobs() async => 42;
  Future<int> fetchActiveJobs() async => 5;
  Future<double> fetchAcceptanceRate() async => 94.0;
  Future<double> fetchRating() async => 4.87;
  Future<List<DriverJobModel>> fetchActiveJobsList() => MockJobRepository().fetchActiveJobs();
  Future<List<double>> fetchWeeklyEarningsChart() async =>
      [134.50, 198.00, 156.75, 210.25, 178.50, 245.00, 122.75];
  Future<String> fetchDriverStatus() async => 'online';
  Future<bool> toggleStatus(String currentStatus) async =>
      currentStatus == 'online' ? false : true;
  Future<bool> acceptJob(String jobId) async => true;
  Future<bool> completeJob(String jobId) async => true;
}

class MockJobRepository {
  Future<List<DriverJobModel>> fetchActiveJobs() async {
    try {
      final getConnect = GetConnect();
      final response = await getConnect.get('https://admin.urbangoodzdelivery.com/api/v1/order-anywhere/driver/available');
      if (response.status.isOk && response.body != null && response.body['data'] != null) {
        final rawData = response.body['data'];
        final List<dynamic> list = (rawData is Map && rawData['data'] != null) ? rawData['data'] : (rawData is List ? rawData : []);
        
        return list.map((json) {
          final id = json['id']?.toString() ?? '';
          final requestNumber = json['request_number']?.toString() ?? 'OA-$id';
          final quoteAmount = double.tryParse(json['quote_amount']?.toString() ?? '0.0') ?? 0.0;
          final finalAmount = double.tryParse(json['final_amount']?.toString() ?? '0.0') ?? 0.0;
          final budgetEstimate = double.tryParse(json['budget_estimate']?.toString() ?? '0.0') ?? 0.0;
          final earnings = finalAmount > 0 ? finalAmount : (quoteAmount > 0 ? quoteAmount : budgetEstimate);
          
          return DriverJobModel(
            id: id,
            type: 'order_anywhere',
            title: 'Order Anywhere - ${json['store_vendor_name'] ?? 'Custom Run'} ($requestNumber)',
            description: json['request_details'] ?? 'Custom Order Anywhere request details.',
            pickupAddress: json['store_vendor_address_or_website'] ?? 'Pickup Store',
            dropoffAddress: json['delivery_address'] ?? 'Customer Dropoff',
            status: json['status'] ?? 'assigned',
            earnings: earnings,
            distance: 5.0,
            estimatedDuration: '20 min',
            customerName: json['customer_name'] ?? 'Marcus Aurelius',
            customerPhone: json['customer_phone'] ?? '+18325559876',
            scheduledDate: DateTime.now().toIso8601String().split('T')[0],
            scheduledTime: 'ASAP',
            vehicleType: 'sedan',
            isUrgent: true,
            tags: ['order-anywhere', 'live-backend'],
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching active jobs from backend: $e');
    }
    return [];
  }

  Future<List<DriverJobModel>> fetchAvailableLoads() async => [
        DriverJobModel(
          id: 'LB-2001',
          type: 'load_board',
          title: 'Pallet of Organics - Katy',
          description: 'Full pallet of organic Urban Goodz products for a health food store in Katy.',
          pickupAddress: 'Urban Goodz Distribution - 5500 N Sam Houston Pkwy, Houston, TX 77041',
          dropoffAddress: '24020 Cinco Village Center Blvd, Katy, TX 77494',
          status: 'available',
          earnings: 145.00,
          distance: 32.0,
          estimatedDuration: '50 min',
          customerName: 'Katy Health Foods',
          customerPhone: '+1 (281) 555-0765',
          scheduledDate: '2026-06-10',
          scheduledTime: '8:00 AM',
          vehicleType: 'truck',
          isUrgent: false,
          tags: ['pallet', 'organic', 'bulk'],
        ),
        DriverJobModel(
          id: 'LB-2002',
          type: 'load_board',
          title: 'Beverage Shipment - Montrose',
          description: 'Mixed pallet of Urban Goodz craft beverages and cold-pressed juices for a Montrose cafe.',
          pickupAddress: 'Urban Goodz Warehouse - 7200 Harrisburg Blvd, Houston, TX 77011',
          dropoffAddress: '1400 Westheimer Rd, Houston, TX 77006',
          status: 'available',
          earnings: 110.00,
          distance: 8.5,
          estimatedDuration: '20 min',
          customerName: 'Montrose Cafe Co-op',
          customerPhone: '+1 (713) 555-0322',
          scheduledDate: '2026-06-10',
          scheduledTime: '7:30 AM',
          vehicleType: 'van',
          isUrgent: false,
          tags: ['beverages', 'pallet', 'montrose', 'fragile'],
        ),
        DriverJobModel(
          id: 'LB-2003',
          type: 'load_board',
          title: 'Bulk Dry Goods - Pasadena',
          description: 'Three pallets of dry goods and pantry staples for a community food cooperative.',
          pickupAddress: 'Urban Goodz Logistics Center - 8900 East Fwy, Houston, TX 77029',
          dropoffAddress: '4800 Vista Rd, Pasadena, TX 77505',
          status: 'available',
          earnings: 195.00,
          distance: 18.2,
          estimatedDuration: '35 min',
          customerName: 'Pasadena Co-op Market',
          customerPhone: '+1 (713) 555-0987',
          scheduledDate: '2026-06-11',
          scheduledTime: '6:30 AM',
          vehicleType: 'truck',
          isUrgent: false,
          tags: ['dry-goods', 'bulk', 'pallet'],
        ),
        DriverJobModel(
          id: 'LB-2004',
          type: 'load_board',
          title: 'Cold Storage Run - Medical Center',
          description: 'Temperature-controlled delivery of perishable Urban Goodz items to Medical Center restaurants.',
          pickupAddress: 'Urban Goodz Cold Storage - 1500 Canal St, Houston, TX 77003',
          dropoffAddress: '2450 Holcombe Blvd, Houston, TX 77021',
          status: 'available',
          earnings: 88.00,
          distance: 4.5,
          estimatedDuration: '15 min',
          customerName: 'Med Center Bistro Group',
          customerPhone: '+1 (832) 555-0211',
          scheduledDate: '2026-06-10',
          scheduledTime: '5:00 AM',
          vehicleType: 'van',
          isUrgent: false,
          tags: ['cold-storage', 'perishable', 'medical-center'],
        ),
      ];
}

class MockEarningsRepository {
  Future<List<EarningsModel>> fetchDailyEarnings() async => [
        EarningsModel(date: '2026-06-08', amount: 187.50, source: 'Downtown Grocery Delivery', jobId: 'DJ-1001', status: 'completed', tips: 5.00, bonuses: 0.0, mileage: 8.2),
        EarningsModel(date: '2026-06-08', amount: 35.00, source: "Medical Supply - Texas Children's", jobId: 'DJ-1002', status: 'completed', tips: 0.0, bonuses: 10.00, mileage: 5.4),
        EarningsModel(date: '2026-06-08', amount: 52.75, source: 'Warehouse to Retail Restock', jobId: 'DJ-1003', status: 'in_progress', tips: 0.0, bonuses: 0.0, mileage: 15.8),
        EarningsModel(date: '2026-06-07', amount: 245.00, source: 'Weekend Farmers Market Delivery', jobId: 'DJ-0997', status: 'completed', tips: 15.00, bonuses: 20.00, mileage: 42.0),
        EarningsModel(date: '2026-06-07', amount: 32.25, source: 'Rice Village Restaurant Supply', jobId: 'DJ-0998', status: 'completed', tips: 4.50, bonuses: 0.0, mileage: 6.1),
        EarningsModel(date: '2026-06-06', amount: 178.50, source: 'Memorial Area Grocery Run', jobId: 'DJ-0995', status: 'completed', tips: 12.00, bonuses: 0.0, mileage: 14.3),
        EarningsModel(date: '2026-06-06', amount: 210.25, source: 'Galleria Mall Vendor Restock', jobId: 'DJ-0996', status: 'completed', tips: 8.75, bonuses: 15.00, mileage: 22.0),
        EarningsModel(date: '2026-06-05', amount: 156.75, source: 'Uptown Office Catering', jobId: 'DJ-0993', status: 'completed', tips: 18.00, bonuses: 0.0, mileage: 9.8),
        EarningsModel(date: '2026-06-05', amount: 198.00, source: 'Heights Neighborhood Delivery', jobId: 'DJ-0994', status: 'completed', tips: 10.50, bonuses: 5.00, mileage: 11.5),
        EarningsModel(date: '2026-06-04', amount: 134.50, source: 'Sugar Land Express', jobId: 'DJ-0991', status: 'completed', tips: 6.00, bonuses: 0.0, mileage: 25.6),
      ];

  Future<double> fetchTotalEarnings() async => 1245.75;
  Future<double> fetchTotalTips() async => 79.75;
  Future<double> fetchTotalBonuses() async => 50.00;
  Future<double> fetchTotalMileage() async => 160.7;
  Future<double> fetchProjectedWeeklyEarnings() async => 1850.00;
}

class MockOpportunityRepository {
  Future<List<OpportunityModel>> fetchOpportunities() async => [
        OpportunityModel(
          id: 'OP-001',
          title: 'Holiday Weekend Surge Bonus',
          description: 'Complete 15 deliveries between June 12-14 and earn an extra \$150 bonus. Houston metro area only.',
          type: 'bonus',
          reward: 150.00,
          status: 'available',
          validFrom: '2026-06-12',
          validUntil: '2026-06-14',
          terms: 'Must complete 15 deliveries within the promotional period. Bonus applied within 48 hours.',
          isActive: true,
        ),
        OpportunityModel(
          id: 'OP-002',
          title: 'Medical Center Surge Zone',
          description: 'Elevated demand in Texas Medical Center area. Earn 1.5x base pay on all deliveries within the zone.',
          type: 'surge',
          reward: 0.0,
          status: 'active',
          validFrom: '2026-06-08',
          validUntil: '2026-06-15',
          terms: 'Surge pricing applies automatically to all jobs originating or ending in the Medical Center zone.',
          isActive: true,
        ),
        OpportunityModel(
          id: 'OP-003',
          title: 'Refer a Driver - Earn \$200',
          description: 'Refer a qualified driver to join the Urban Goodz fleet. You get \$200 once they complete 20 deliveries.',
          type: 'referral',
          reward: 200.00,
          status: 'available',
          validFrom: '2026-01-01',
          validUntil: '2026-12-31',
          terms: 'Referred driver must pass background check and complete 20 deliveries within 60 days.',
          isActive: true,
        ),
        OpportunityModel(
          id: 'OP-004',
          title: 'Safe Driving Certification',
          description: 'Complete the Urban Goodz Safe Driving Course and earn a \$75 completion bonus.',
          type: 'training',
          reward: 75.00,
          status: 'available',
          validFrom: '2026-06-01',
          validUntil: '2026-07-31',
          terms: 'Course takes approximately 45 minutes. Must pass the final assessment with 80% or higher.',
          isActive: true,
        ),
        OpportunityModel(
          id: 'OP-005',
          title: '10 Delivery Streak Bonus',
          description: 'Complete 10 deliveries in a single day and earn a \$50 same-day bonus.',
          type: 'bonus',
          reward: 50.00,
          status: 'available',
          validFrom: '2026-06-01',
          validUntil: '2026-06-30',
          terms: 'Streak resets at midnight. All 10 deliveries must be accepted and completed on the same calendar day.',
          isActive: true,
        ),
        OpportunityModel(
          id: 'OP-006',
          title: 'Katy/Cypress Expansion Surge',
          description: 'New customer demand surge in Katy and Cypress areas. 1.75x earnings for all deliveries in these zones.',
          type: 'surge',
          reward: 0.0,
          status: 'active',
          validFrom: '2026-06-01',
          validUntil: '2026-07-01',
          terms: 'Automatic surge pricing for jobs in Katy and Cypress ZIP codes 77494, 77449, 77433.',
          isActive: true,
        ),
        OpportunityModel(
          id: 'OP-007',
          title: 'Early Bird Bonus',
          description: 'Complete deliveries between 5:00 AM and 8:00 AM and earn an additional \$3 per delivery.',
          type: 'bonus',
          reward: 3.00,
          status: 'claimed',
          validFrom: '2026-06-01',
          validUntil: '2026-06-30',
          terms: 'Per-delivery bonus stacked on top of regular earnings. Only applies to jobs accepted during the window.',
          isActive: true,
        ),
        OpportunityModel(
          id: 'OP-008',
          title: 'Customer Feedback Champion',
          description: 'Maintain a 4.9+ rating for the month and earn a \$100 quality service bonus.',
          type: 'bonus',
          reward: 100.00,
          status: 'completed',
          validFrom: '2026-05-01',
          validUntil: '2026-05-31',
          terms: 'Based on customer ratings from completed deliveries. Minimum 30 deliveries required to qualify.',
          isActive: false,
        ),
      ];

  Future<bool> claimOpportunity(String id) async => true;
}

class MockVehicleRepository {
  Future<List<VehicleModel>> fetchVehicles() async => [
        VehicleModel(
          id: 'VH-001',
          type: 'sedan',
          make: 'Toyota',
          model: 'Camry Hybrid',
          year: 2022,
          color: 'Pearl White',
          licensePlate: 'UGZ-4521',
          insuranceProvider: 'Progressive Commercial',
          insuranceExpiry: '2026-12-31',
          registrationExpiry: '2027-03-15',
          isAvailable: true,
          isInsured: true,
          isRegistered: true,
          mileage: 45230.0,
          lastMaintenance: '2026-05-15',
          nextMaintenance: '2026-08-15',
          certifications: ['Commercial Vehicle Inspection', 'Emissions Test'],
        ),
        VehicleModel(
          id: 'VH-002',
          type: 'van',
          make: 'Ford',
          model: 'Transit Connect',
          year: 2023,
          color: 'Midnight Blue',
          licensePlate: 'UGZ-7834',
          insuranceProvider: 'Progressive Commercial',
          insuranceExpiry: '2026-11-30',
          registrationExpiry: '2027-06-01',
          isAvailable: true,
          isInsured: true,
          isRegistered: true,
          mileage: 28910.0,
          lastMaintenance: '2026-04-20',
          nextMaintenance: '2026-07-20',
          certifications: ['Commercial Vehicle Inspection', 'Emissions Test', 'Cargo Restraint Certification'],
        ),
        VehicleModel(
          id: 'VH-003',
          type: 'truck',
          make: 'Ram',
          model: 'Promaster 2500',
          year: 2021,
          color: 'Graphite Gray',
          licensePlate: 'UGZ-9167',
          insuranceProvider: 'Progressive Commercial',
          insuranceExpiry: '2026-10-15',
          registrationExpiry: '2027-01-20',
          isAvailable: true,
          isInsured: true,
          isRegistered: true,
          mileage: 67240.0,
          lastMaintenance: '2026-03-10',
          nextMaintenance: '2026-06-10',
          certifications: ['CDL Class C', 'Commercial Vehicle Inspection', 'Emissions Test', 'Hazmat Endorsement'],
        ),
      ];

  Future<VehicleModel?> fetchVehicleById(String id) async {
    final vehicles = await fetchVehicles();
    try {
      return vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }
}

class MockCertificationRepository {
  Future<List<CertificationModel>> fetchCertifications() async => [
        CertificationModel(
          id: 'CERT-001',
          name: 'Texas Commercial Driver License',
          issuingAuthority: 'Texas DPS',
          issueDate: '2024-01-15',
          expiryDate: '2028-01-15',
          status: 'valid',
          documentUrl: 'documents/cdl_2024.pdf',
          isRequired: true,
        ),
        CertificationModel(
          id: 'CERT-002',
          name: 'Food Handler Certification',
          issuingAuthority: 'City of Houston - Health Dept',
          issueDate: '2025-03-01',
          expiryDate: '2027-03-01',
          status: 'valid',
          documentUrl: 'documents/food_handler.pdf',
          isRequired: true,
        ),
        CertificationModel(
          id: 'CERT-003',
          name: 'Defensive Driving Course',
          issuingAuthority: 'National Safety Council',
          issueDate: '2023-06-20',
          expiryDate: '2026-06-20',
          status: 'expired',
          documentUrl: 'documents/defensive_driving.pdf',
          isRequired: false,
        ),
        CertificationModel(
          id: 'CERT-004',
          name: 'Hazmat Endorsement',
          issuingAuthority: 'TSA / Texas DPS',
          issueDate: '2025-09-10',
          expiryDate: '2027-09-10',
          status: 'pending',
          documentUrl: '',
          isRequired: false,
        ),
        CertificationModel(
          id: 'CERT-005',
          name: "Medical Examiner's Certificate",
          issuingAuthority: 'FMCSA / Dr. Patel, MD',
          issueDate: '2025-11-01',
          expiryDate: '2026-11-01',
          status: 'valid',
          documentUrl: 'documents/medical_cert.pdf',
          isRequired: true,
        ),
        CertificationModel(
          id: 'CERT-006',
          name: 'Alcohol Server Training - TABC',
          issuingAuthority: 'Texas Alcoholic Beverage Commission',
          issueDate: '2024-07-15',
          expiryDate: '2026-07-15',
          status: 'expired',
          documentUrl: 'documents/tabc_cert.pdf',
          isRequired: false,
        ),
        CertificationModel(
          id: 'CERT-007',
          name: 'Fleet Safety Orientation',
          issuingAuthority: 'Urban Goodz Safety Division',
          issueDate: '2026-01-05',
          expiryDate: '2027-01-05',
          status: 'valid',
          documentUrl: 'documents/fleet_safety.pdf',
          isRequired: true,
        ),
        CertificationModel(
          id: 'CERT-008',
          name: 'Electric Vehicle Operation',
          issuingAuthority: 'Urban Goodz Training',
          issueDate: '2026-04-01',
          expiryDate: '2027-04-01',
          status: 'pending',
          documentUrl: 'documents/ev_training.pdf',
          isRequired: false,
        ),
      ];

  Future<bool> uploadDocument(String certId) async => true;
  Future<bool> renewCertification(String certId) async => true;
}

class MockPayoutRepository {
  Future<List<PayoutModel>> fetchPayouts() async => [
        PayoutModel(
          id: 'PO-001',
          amount: 1245.75,
          status: 'completed',
          requestedDate: '2026-06-05',
          completedDate: '2026-06-06',
          paymentMethod: 'Direct Deposit - Bank of America',
          transactionId: 'TXN-8932-AB',
          notes: 'Weekly payout for May 30 - June 5',
        ),
        PayoutModel(
          id: 'PO-002',
          amount: 987.50,
          status: 'completed',
          requestedDate: '2026-05-29',
          completedDate: '2026-05-30',
          paymentMethod: 'Direct Deposit - Bank of America',
          transactionId: 'TXN-8741-CD',
          notes: 'Weekly payout for May 23 - May 29',
        ),
        PayoutModel(
          id: 'PO-003',
          amount: 1450.25,
          status: 'pending',
          requestedDate: '2026-06-08',
          completedDate: '',
          paymentMethod: 'Direct Deposit - Bank of America',
          transactionId: '',
          notes: 'Weekly payout for June 6 - June 12',
        ),
        PayoutModel(
          id: 'PO-004',
          amount: 1102.00,
          status: 'completed',
          requestedDate: '2026-05-22',
          completedDate: '2026-05-23',
          paymentMethod: 'Direct Deposit - Bank of America',
          transactionId: 'TXN-8547-EF',
          notes: 'Weekly payout for May 16 - May 22',
        ),
        PayoutModel(
          id: 'PO-005',
          amount: 675.30,
          status: 'failed',
          requestedDate: '2026-05-15',
          completedDate: '',
          paymentMethod: 'Direct Deposit - Bank of America',
          transactionId: '',
          notes: 'Insufficient funds - retry scheduled',
        ),
        PayoutModel(
          id: 'PO-006',
          amount: 890.00,
          status: 'completed',
          requestedDate: '2026-05-08',
          completedDate: '2026-05-09',
          paymentMethod: 'Direct Deposit - Bank of America',
          transactionId: 'TXN-8219-GH',
          notes: 'Weekly payout for May 2 - May 8',
        ),
      ];

  Future<bool> requestPayout(double amount) async => true;
}
