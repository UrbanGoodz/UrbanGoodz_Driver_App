import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/add_favourite_view.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';

import '../../../util/images.dart';

class VisitAgainCard extends StatelessWidget {
  final Store store;
  final bool fromFood;
  const VisitAgainCard({super.key, required this.store, required this.fromFood});

  @override
  Widget build(BuildContext context) {
    bool isPharmacy = Get.find<SplashController>().module != null && Get.find<SplashController>().module!.moduleType.toString() == AppConstants.pharmacy;
    bool isFood = Get.find<SplashController>().module != null && Get.find<SplashController>().module!.moduleType.toString() == AppConstants.food;
    bool isAvailable = store.open == 1 && store.active!;

    return TextHover(
      builder: (hovered) {
        return Stack(children: [
          Container(
            margin: const EdgeInsets.only(top: Dimensions.paddingSizeLarge, bottom: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              color: Theme.of(context).cardColor,
              // The amber border is intentional here (it echoes the logo
              // avatar's own accent ring below), kept as-is -- only the
              // shadow recipe is brought in line with CustomCard's.
              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), width: 1),
              boxShadow: [BoxShadow(color: Get.isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: CustomInkWell(
              onTap: () {
                Get.toNamed(
                  RouteHelper.getStoreRoute(id: store.id, page: 'store', slug: store.slug??''),
                  arguments: StoreScreen(store: store, fromModule: false),
                );
              },
              radius: Dimensions.radiusDefault,
              padding: const EdgeInsets.only(top: 40, bottom: Dimensions.paddingSizeSmall),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                // Flexible(child: Text(store.name ?? '', style: robotoBold, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(store.name ?? '', style: robotoMedium),
                  SizedBox(width: 8),
                  store.verifiedSeller == 1 ? Image.asset(Images.verifiedBadge, width: 16, height: 16) : SizedBox.shrink()
                ]),

                store.ratingCount! > 0 ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.star, size: 15, color: AppConstants.seasoningOrange),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                  Text(store.avgRating!.toStringAsFixed(1), style: robotoRegular),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                  Text("(${store.ratingCount})", style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                ]) : SizedBox.shrink(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.storefront_outlined, size: 20, color: Theme.of(context).disabledColor),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                    Flexible(
                      child: Text(
                        store.address ?? '',
                        overflow: TextOverflow.ellipsis, maxLines: 1,
                        style: robotoRegular.copyWith(color: Theme.of(context).disabledColor),
                      ),
                    ),
                  ]),
                ),

                store.items != null ? Container(
                  alignment: Alignment.center,
                  height: 25, width: 200,
                  child: ListView.builder(
                    itemCount: store.items!.length,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular((isPharmacy || isFood) ? 100 : Dimensions.radiusSmall),
                              child: CustomImage(
                                image: '${store.items![index].imageFullUrl}',
                                  fit: BoxFit.cover, height: 25, width: 25,
                              ),
                            ),

                            index == store.items!.length -1 ? Positioned(
                              top: 0, left: 0,right: 0, bottom: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular((isPharmacy || isFood) ? 100 : Dimensions.radiusSmall),
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                                child: Center(child: Text(
                                  (store.itemCount! > 20) ? '20+' : '${store.itemCount}', style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraSmall),
                                )),
                              ),
                            ) : const SizedBox(),
                          ],
                        ),
                      );
                    },
                  ),
                ) : const SizedBox(),
              ]),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 54, width: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(fromFood ? 100 : Dimensions.radiusDefault),
                color: Theme.of(context).cardColor,
                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(fromFood ? 100 : Dimensions.radiusDefault),
                child: Stack(
                  children: [
                    CustomImage(
                      isHovered: hovered,
                      image: '${store.logoFullUrl}',
                      fit: BoxFit.cover, height: 54, width: 54,
                    ),

                    isAvailable ? const SizedBox() : NotAvailableWidget(isStore: true, store: store, fontSize: 8, isAllSideRound: true),

                  ],
                ),
              ),
            ),
          ),

          AddFavouriteView(
            top: 30,
            left: Get.find<LocalizationController>().isLtr ? null : 10,
            right: Get.find<LocalizationController>().isLtr ? 10 : null,
            item: null, storeId: store.id,
          ),

        ]);
      }
    );
  }
}
