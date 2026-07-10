import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/load_board_controller.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class LoadBoardScreen extends StatefulWidget {
  const LoadBoardScreen({super.key});

  @override
  State<LoadBoardScreen> createState() => _LoadBoardScreenState();
}

class _LoadBoardScreenState extends State<LoadBoardScreen> {
  final LoadBoardController controller = Get.put(LoadBoardController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Load Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchLoads(),
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
              padding: const EdgeInsets.all(12),
              color: AppTheme.dark,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search loads...',
                      prefixIcon:
                          const Icon(Icons.search, color: AppTheme.dark),
                      filled: true,
                      fillColor: AppTheme.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _SortButton(
                        label: 'Pay',
                        isSelected: controller.sortBy.value == 'pay',
                        onTap: () => controller.sortLoads('pay'),
                      ),
                      const SizedBox(width: 8),
                      _SortButton(
                        label: 'Distance',
                        isSelected: controller.sortBy.value == 'distance',
                        onTap: () => controller.sortLoads('distance'),
                      ),
                      const SizedBox(width: 8),
                      _SortButton(
                        label: 'Date',
                        isSelected: controller.sortBy.value == 'date',
                        onTap: () => controller.sortLoads('date'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: controller.filteredLoads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping,
                              size: 64,
                              color: AppTheme.dark.withAlpha(60)),
                          const SizedBox(height: 16),
                          const Text('No loads available',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: controller.filteredLoads.length,
                      itemBuilder: (context, index) {
                        final load = controller.filteredLoads[index];
                        return _LoadCard(
                          load: load,
                          onBid: () => controller.bidOnLoad(load.id),
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

class _SortButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.beige,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? AppTheme.white : AppTheme.dark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            )),
      ),
    );
  }
}

class _LoadCard extends StatelessWidget {
  final dynamic load;
  final VoidCallback onBid;

  const _LoadCard({required this.load, required this.onBid});

  @override
  Widget build(BuildContext context) {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(load.type.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary)),
              ),
              const Spacer(),
              Text('\$${load.earnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dark)),
            ],
          ),
          const SizedBox(height: 10),
          Text(load.title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on,
                  size: 16, color: AppTheme.primary.withAlpha(180)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(load.pickupAddress,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.dark.withAlpha(150)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.flag,
                  size: 16, color: AppTheme.accent.withAlpha(180)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(load.dropoffAddress,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.dark.withAlpha(150)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.straighten,
                  size: 16, color: AppTheme.dark.withAlpha(120)),
              const SizedBox(width: 4),
              Text('${load.distance.toStringAsFixed(1)} mi',
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.dark.withAlpha(150))),
              const SizedBox(width: 16),
              Icon(Icons.directions_car,
                  size: 16, color: AppTheme.dark.withAlpha(120)),
              const SizedBox(width: 4),
              Text(load.vehicleType[0].toUpperCase() +
                      load.vehicleType.substring(1),
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.dark.withAlpha(150))),
              const SizedBox(width: 16),
              Icon(Icons.access_time,
                  size: 16, color: AppTheme.dark.withAlpha(120)),
              const SizedBox(width: 4),
              Text(load.scheduledTime,
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.dark.withAlpha(150))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBid,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.white,
              ),
              child: const Text('Place Bid'),
            ),
          ),
        ],
      ),
    );
  }
}
