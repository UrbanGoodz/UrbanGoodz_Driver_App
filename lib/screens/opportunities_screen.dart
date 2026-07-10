import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/opportunities_controller.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  final OpportunitiesController controller =
      Get.put(OpportunitiesController());

  final List<String> _categories = [
    'all',
    'bonus',
    'surge',
    'referral',
    'training'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opportunities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchOpportunities(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              color: AppTheme.dark,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((c) {
                    final isSelected = controller.selectedCategory.value == c;
                    String label;
                    switch (c) {
                      case 'all':
                        label = 'All';
                        break;
                      case 'bonus':
                        label = 'Bonus Missions';
                        break;
                      case 'surge':
                        label = 'Surge Zones';
                        break;
                      case 'referral':
                        label = 'Referrals';
                        break;
                      case 'training':
                        label = 'Training';
                        break;
                      default:
                        label = c;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.white
                                  : AppTheme.dark,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            )),
                        selected: isSelected,
                        onSelected: (_) => controller.filterByCategory(c),
                        backgroundColor: AppTheme.beige,
                        selectedColor: AppTheme.primary,
                        checkmarkColor: AppTheme.white,
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: controller.filteredOpportunities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.card_giftcard,
                              size: 64,
                              color: AppTheme.dark.withAlpha(60)),
                          const SizedBox(height: 16),
                          const Text('No opportunities available',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: controller.filteredOpportunities.length,
                      itemBuilder: (context, index) {
                        final opp = controller.filteredOpportunities[index];
                        return _OpportunityCard(
                          opportunity: opp,
                          onClaim: () =>
                              controller.claimOpportunity(opp.id),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final dynamic opportunity;
  final VoidCallback onClaim;

  const _OpportunityCard({
    required this.opportunity,
    required this.onClaim,
  });

  IconData _typeIcon(String type) {
    switch (type) {
      case 'bonus':
        return Icons.monetization_on;
      case 'surge':
        return Icons.trending_up;
      case 'referral':
        return Icons.people;
      case 'training':
        return Icons.school;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'bonus':
        return Colors.green;
      case 'surge':
        return Colors.orange;
      case 'referral':
        return Colors.blue;
      case 'training':
        return Colors.purple;
      default:
        return AppTheme.primary;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return AppTheme.primary;
      case 'active':
        return Colors.green;
      case 'claimed':
        return Colors.blue;
      case 'completed':
        return AppTheme.dark;
      default:
        return AppTheme.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClaimable =
        opportunity.status == 'available' || opportunity.status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: AppTheme.dark.withAlpha(15), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _typeColor(opportunity.type).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(opportunity.type),
                    color: _typeColor(opportunity.type), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opportunity.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(opportunity.type[0].toUpperCase() +
                            opportunity.type.substring(1),
                        style: TextStyle(
                            fontSize: 12,
                            color: _typeColor(opportunity.type),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (opportunity.reward > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                      '\$${opportunity.reward == 3.0 ? '3/delivery' : opportunity.reward.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          fontSize: 16)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(opportunity.description,
              style: TextStyle(
                  fontSize: 13, color: AppTheme.dark.withAlpha(180))),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 14, color: AppTheme.dark.withAlpha(120)),
              const SizedBox(width: 4),
              Text('Expires: ${opportunity.validUntil}',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.dark.withAlpha(120))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(opportunity.status).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(opportunity.status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(opportunity.status))),
              ),
              const Spacer(),
              if (isClaimable)
                ElevatedButton(
                  onPressed: onClaim,
                  child: const Text('Claim Now'),
                ),
              if (!isClaimable)
                Text(
                  opportunity.status == 'claimed' ? 'Claimed' : 'Completed',
                  style: TextStyle(
                      color: AppTheme.dark.withAlpha(120),
                      fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
