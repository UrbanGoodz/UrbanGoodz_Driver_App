import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/earnings_controller.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final EarningsController controller = Get.put(EarningsController());

  final List<String> _periods = ['daily', 'weekly', 'monthly'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchEarnings(),
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
                children: _periods
                    .map((p) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(p[0].toUpperCase() + p.substring(1),
                                  style: TextStyle(
                                    color: controller.selectedPeriod.value == p
                                        ? AppTheme.white
                                        : AppTheme.dark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  )),
                              selected: controller.selectedPeriod.value == p,
                              onSelected: (_) => controller.changePeriod(p),
                              selectedColor: AppTheme.primary,
                              backgroundColor: AppTheme.beige,
                              side: BorderSide.none,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Earnings',
                      value:
                          '\$${controller.totalEarnings.value.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Tips',
                      value:
                          '\$${controller.totalTips.value.toStringAsFixed(2)}',
                      icon: Icons.thumb_up,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Bonuses',
                      value:
                          '\$${controller.totalBonuses.value.toStringAsFixed(2)}',
                      icon: Icons.card_giftcard,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Mileage',
                      value:
                          '${controller.totalMileage.value.toStringAsFixed(1)} mi',
                      icon: Icons.speed,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withAlpha(40),
                      AppTheme.accent.withAlpha(30)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Projected Weekly Earnings',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.dark,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(
                              '\$${controller.projectedWeeklyEarnings.value.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.dark)),
                        ],
                      ),
                    ),
                    Icon(Icons.trending_up,
                        size: 48, color: AppTheme.primary.withAlpha(180)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Earnings Breakdown',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                height: 140,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.dark.withAlpha(15), blurRadius: 8)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('7-Day Trend',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (i) {
                          final heights = [0.5, 0.7, 0.55, 0.8, 0.65, 0.9, 0.6];
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: Container(
                                height: 80 * heights[i],
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(180),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Recent Transactions',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...controller.dailyEarnings.take(8).map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.dark.withAlpha(10),
                            blurRadius: 4)
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt,
                              color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.source,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(e.date,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          AppTheme.dark.withAlpha(120))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${e.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            if (e.tips > 0)
                              Text('+\$${e.tips.toStringAsFixed(2)} tip',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade600)),
                          ],
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      }),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dark)),
          const SizedBox(height: 2),
          Text(title,
              style: TextStyle(
                  fontSize: 12, color: AppTheme.dark.withAlpha(150))),
        ],
      ),
    );
  }
}
