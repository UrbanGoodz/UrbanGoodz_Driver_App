import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/widgets/add_favourite_view.dart';
import 'package:sixam_mart/common/widgets/custom_card.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/new_tag.dart';
import 'package:sixam_mart/common/widgets/rating_bar.dart';
import 'package:sixam_mart/common/widgets/status_chip.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';

class StoreCard extends StatelessWidget {
  final Store store;
  final bool? isTopOffers;
  const StoreCard({super.key, required this.store, this.isTopOffers = false});

  @override
  Widget build(BuildContext context) {
    bool isPharmacy = Get.find<SplashController>().module != null && Get.find<SplashController>().module!.moduleType.toString() == AppConstants.pharmacy;
    double distance = Get.find<StoreController>().getRestaurantDistance(
      LatLng(double.parse(store.latitude!), double.parse(store.longitude!)),
    );
    double discount = store.discount?.discount ?? 0;
    String discountType = store.discount?.discountType ?? '';
    bool isRightSide = Get.find<SplashController>().configModel!.currencySymbolDirection == 'right';
    String currencySymbol = Get.find<SplashController>().configModel!.currencySymbol!;
    bool isAvailable = store.open == 1 && store.active!;

    return Stack(children: [

      Container(
        width: 300,
        // Previously had no shadow at all on desktop/web and a different,
        // one-off shadow recipe on mobile -- now the same CustomCard
        // treatment every other card surface uses, on every platform.
        decoration: CustomCard.decoration(context, radius: Dimensions.radiusDefault),
        child: CustomInkWell(
          onTap: () {
            if(Get.find<SplashController>().moduleList != null) {
              for(ModuleModel module in Get.find<SplashController>().moduleList!) {
                if(module.id == store.moduleId) {
                  Get.find<SplashController>().setModule(module);
                  break;
                }
              }
            }
            Get.toNamed(
              RouteHelper.getStoreRoute(id: store.id, page: 'store', slug: store.slug??''),
              arguments: StoreScreen(store: store, fromModule: false),
            );
          },
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          radius: Dimensions.radiusDefault,
          child: TextHover(
            builder: (hovered) {
              return Stack(children: [

                Column(children: [

                  Expanded(
                    flex: 5,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            child: CustomImage(
                              isHovered: hovered,
                              image: '${store.logoFullUrl}',
                              height: 50, width: 50, fit: BoxFit.cover,
                              isStoreLogo: true,
                              storeName: store.name,
                              storeModuleId: store.moduleId,
                            ),
                          ),

                          isAvailable ? const SizedBox() : NotAvailableWidget(isStore: true, store: store, fontSize: Dimensions.fontSizeExtraSmall, isAllSideRound: true),
                        ],
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                          Row(children: [
                            Text(store.name ?? '', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(width: 8),
                            store.verifiedSeller == 1 ? Image.asset(Images.verifiedBadge, width: 12, height: 12) : SizedBox.shrink()
                          ]),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                          !isPharmacy ? store.ratingCount! > 0 ? RatingBar(
                            rating: store.avgRating,
                            ratingCount: store.ratingCount,
                            size: 12,
                          ) : const SizedBox() : Row(children: [

                            Icon(Icons.storefront, size: 15, color: Theme.of(context).primaryColor),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                            Expanded(
                              child: Text(store.address ?? '',
                                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          ]),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                          !isPharmacy ? Row(children: [

                            Icon(Icons.storefront, size: 15, color: Theme.of(context).primaryColor),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                            Flexible(
                              child: Text(store.address ?? '',
                                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          ]) : Text('${store.itemCount}' ' ' 'items'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),

                        ]),
                      ),
                    ]),
                  ),
                  Expanded(
                    flex: 2,
                    child: isTopOffers! ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      StatusChip.subtle(context,
                        label: '${AppConstants.formattedDistance(distance)} ${'from_you'.tr}',
                        leading: Image.asset(Images.distanceLine, height: 15, width: 15, color: Theme.of(context).disabledColor),
                      ),
                      StatusChip.solid(context,
                        label: discount > 0 ? '${(isRightSide || discountType == 'percent') ? '' : currencySymbol}$discount${discountType == 'percent' ? '%'
                            : isRightSide ? currencySymbol : ''} ${'off'.tr}' : 'free_delivery'.tr,
                      ),
                    ]) : Row(children: [

                      StatusChip.subtle(context,
                        label: '${AppConstants.formattedDistance(distance)} ${'from_you'.tr}',
                        leading: Image.asset(Images.distanceLine, height: 15, width: 15, color: Theme.of(context).textTheme.bodyLarge!.color),
                      ),
                      const Spacer(),

                      // "Closed" is a muted/disabled state, not an alarm --
                      // it previously used colorScheme.error, which in this
                      // theme is aliased to the brand amber itself (the same
                      // color "open" used), so closed and open read almost
                      // identically. disabledColor is already in the
                      // palette; no new color introduced.
                      StatusChip.subtle(context,
                        label: Get.find<StoreController>().isOpenNow(store) ? 'open_now'.tr : 'closed_now'.tr,
                        textColor: Get.find<StoreController>().isOpenNow(store) ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
                        leading: Image.asset(Images.clockIcon, height: 15, width: 15, color: Get.find<StoreController>().isOpenNow(store) ? Theme.of(context).primaryColor : Theme.of(context).disabledColor),
                      ),
                    ]),
                  ),
                ]),

                AddFavouriteView(
                  top: 0,
                  left: Get.find<LocalizationController>().isLtr ? null : 0,
                  right: Get.find<LocalizationController>().isLtr ? 0 : null,
                  item: null, storeId: store.id,
                ),

              ]);
            }
          ),
        ),
      ),

      !isTopOffers! ? const NewTag() : const SizedBox(),
    ]);
  }
}
