import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:pylons_wallet/components/loading.dart';
import 'package:pylons_wallet/model/transaction.dart';
import 'package:pylons_wallet/modules/Pylonstech.pylons.pylons/module/client/pylons/recipe.pb.dart';
import 'package:pylons_wallet/pylons_app.dart';
import 'package:pylons_wallet/stores/wallet_store.dart';
import 'package:pylons_wallet/utils/constants.dart';
import 'package:pylons_wallet/utils/enums.dart';
import 'package:pylons_wallet/utils/extension.dart';
import 'package:pylons_wallet/utils/route_util.dart';
import 'package:pylons_wallet/utils/svg_util.dart';

var _headingTextStyle =
    TextStyle(color: kWhite, fontWeight: FontWeight.w600, fontSize: 11.sp);
var _subtitleTextStyle =
    TextStyle(color: kWhite, fontWeight: FontWeight.w600, fontSize: 9.sp); //7

Map<int, String> monthStrMap = {
  1: 'jan'.tr(),
  2: 'feb'.tr(),
  3: 'mar'.tr(),
  4: 'apr'.tr(),
  5: 'may'.tr(),
  6: 'jun'.tr(),
  7: 'jul'.tr(),
  8: 'aug'.tr(),
  9: 'sept'.tr(),
  10: 'oct'.tr(),
  11: 'nov'.tr(),
  12: 'dec'.tr()
};
Map<String, String> denomAbbr = {
  kPylonCoinName: kPYLN_ABBREVATION,
  kUSD: kStripeUSD_ABR
};

class LatestTransactions extends StatelessWidget {
  final List<TransactionHistory> denomSpecificTxList;

  final String defaultCurrency;

  const LatestTransactions(
      {Key? key,
      required this.denomSpecificTxList,
      required this.defaultCurrency})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          denomSpecificTxList.map((tx) => buildRow(txHistory: tx)).toList(),
    );
  }

  bool getPrefix(TransactionHistory amount) {
    if (defaultCurrency.convertFromU(amount) == kZeroDouble) {
      return true;
    }
    return false;
  }

  bool getPrefixForUSD(TransactionHistory amount) {
    if (defaultCurrency.convertToUSD(amount) == kZeroInt) {
      return true;
    }
    return false;
  }

  Column getAmountColumn({required TransactionHistory txHistory}) {
    if (txHistory.transactionTypeEnum == TransactionType.NFTSELL ||
        txHistory.transactionTypeEnum == TransactionType.RECEIVE) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            "${getPrefix(txHistory) ? "" : "+"}${defaultCurrency.convertFromU(txHistory)} ${denomAbbr[defaultCurrency]}",
            style: _headingTextStyle,
          ),
          if (defaultCurrency != kUSD)
            Text(
              "${getPrefixForUSD(txHistory) ? "" : "+"}${defaultCurrency.convertToUSD(txHistory)} $kStripeUSD_ABR",
              style: _subtitleTextStyle,
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "${getPrefix(txHistory) ? "" : "-"}${defaultCurrency.convertFromU(txHistory)} ${denomAbbr[defaultCurrency]}",
          style: _headingTextStyle.copyWith(color: kDarkRed),
        ),
        if (defaultCurrency != kUSD)
          Text(
            "${getPrefixForUSD(txHistory) ? "" : "-"}${defaultCurrency.convertToUSD(txHistory)} $kStripeUSD_ABR",
            style: _subtitleTextStyle.copyWith(color: kDarkRed),
          ),
      ],
    );
  }

  ListTile buildTransactionListTile({required TransactionHistory txHistory}) {
    switch (txHistory.transactionTypeEnum) {
      case TransactionType.NFTBUY:
        return ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          minVerticalPadding: 0,
          leading: SizedBox(
              width: 25.w,
              height: 25.h,
              child: SvgPicture.asset(SVGUtil.WALLET_NFT_PURCHASE)),
          title: Text(
            "nft_purchase".tr(),
            softWrap: false,
            style: _headingTextStyle,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                txHistory.recipeId.trimString(stringTrimConstantMax),
                style: _headingTextStyle,
              ),
              SizedBox(
                height: 10.h,
              ),
            ],
          ),
        );
      case TransactionType.NFTSELL:
        return ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          leading: SizedBox(
              width: 25.w,
              height: 25.h,
              child: SvgPicture.asset(SVGUtil.WALLET_NFT_SELL)),
          title: Text(
            "nft_sold".tr(),
            softWrap: false,
            style: _headingTextStyle,
          ),
          subtitle: Column(
            children: [
              Text(
                txHistory.recipeId.trimString(stringTrimConstantMax),
                style: _headingTextStyle,
              ),
              SizedBox(
                height: 10.h,
              ),
            ],
          ),
        );
      case TransactionType.RECEIVE:
        return ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          leading: SizedBox(
              width: 25.w,
              height: 25.h,
              child: SvgPicture.asset(SVGUtil.WALLET_CURRENCY_RECEIVE)),
          title: Text(
            "pylons_purchase".tr(),
            softWrap: false,
            style: _headingTextStyle,
          ),
          subtitle: SizedBox(height: 8.h),
        );
      case TransactionType.SEND:
        return ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          leading: SizedBox(
              width: 25.w,
              height: 25.h,
              child: SvgPicture.asset(SVGUtil.WALLET_CURRENCY_SENT)),
          title: Text(
            "pylons_sent".tr(),
            softWrap: false,
            style: _headingTextStyle,
          ),
          subtitle: SizedBox(height: 8.h),
        );
      default:
        return const ListTile();
    }
  }

  Future<void> onTxTapped({required TransactionHistory txHistory}) async {
    final walletsStore = GetIt.I.get<WalletsStore>();

    String seller = "";
    String buyer = "";

    if (txHistory.transactionTypeEnum == TransactionType.NFTSELL ||
        txHistory.transactionTypeEnum == TransactionType.NFTBUY) {
      final showLoader = Loading()..showLoading();

      if (txHistory.transactionTypeEnum == TransactionType.NFTSELL) {
        seller = await walletsStore.getAccountNameByAddress(
            walletsStore.getWallets().value.first.publicAddress);
        buyer = await walletsStore.getAccountNameByAddress(txHistory.address);
      }

      if (txHistory.transactionTypeEnum == TransactionType.NFTBUY) {
        seller = await walletsStore.getAccountNameByAddress(txHistory.address);
        buyer = await walletsStore.getAccountNameByAddress(
            walletsStore.getWallets().value.first.publicAddress);
      }

      final recipeResult = await walletsStore.getRecipe(
          txHistory.cookbookId, txHistory.recipeId);
      final creator =
          await walletsStore.getAccountNameByAddress(txHistory.address);
      showLoader.dismiss();
      if (recipeResult.isLeft()) {
        "nft_does_not_exists".tr().show();
        return;
      }
      final recipe = recipeResult.toOption().toNullable()!;

      final AssetType nftType = recipe.entries.itemOutputs.first.strings
          .firstWhere((strKeyValue) => strKeyValue.key == kNftFormat,
              orElse: () => StringParam())
          .value
          .toAssetTypeEnum();
      final String nftUrl = recipe.entries.itemOutputs.first.strings
          .firstWhere((strKeyValue) => strKeyValue.key == kNFTURL,
              orElse: () => StringParam())
          .value;
      final String thumbnailUrl = recipe.entries.itemOutputs.first.strings
          .firstWhere((strKeyValue) => strKeyValue.key == kThumbnailUrl,
              orElse: () => StringParam())
          .value;

      Navigator.of(navigatorKey.currentState!.overlay!.context)
          .pushNamed(RouteUtil.ROUTE_TRANSACTION_DETAIL,
              arguments: TxDetailArguments(
                recipe: recipe,
                creator: creator,
                seller: seller,
                buyer: buyer,
                txID: txHistory.txID,
                transactionTime: DateFormat("MMM dd yyyy HH:mm").format(
                    DateTime.fromMillisecondsSinceEpoch(
                        txHistory.createdAt * kDateConverterConstant)),
                currency: (denomAbbr[defaultCurrency])!,
                price:
                    "${defaultCurrency.convertFromU(txHistory)} ${denomAbbr[defaultCurrency]}",
                transactionEnum: txHistory.transactionTypeEnum,
                nftType: nftType,
                nftThumbnailUrl: thumbnailUrl,
                nftUrl: nftUrl,
              ));
    }
  }

  InkWell buildRow({required TransactionHistory txHistory}) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(
        txHistory.createdAt * kDateConverterConstant,
        isUtc: true);
    return InkWell(
      onTap: () => onTxTapped(txHistory: txHistory),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(monthStrMap[date.month]!, style: _subtitleTextStyle),
              Text(date.day.toString(), style: _headingTextStyle),
            ],
          ),
          Expanded(child: buildTransactionListTile(txHistory: txHistory)),
          getAmountColumn(txHistory: txHistory),
          SizedBox(
            width: 10.w,
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 10.r,
            color: kUnselectedIcon,
          ),
        ],
      ),
    );
  }
}

class TxDetailArguments {
  final Recipe recipe;
  final String nftUrl;
  final String nftThumbnailUrl;
  final String creator;
  final String seller;
  final String buyer;
  final String txID;
  final String transactionTime;
  final String currency;
  final String price;
  final TransactionType transactionEnum;
  final AssetType nftType;

  TxDetailArguments({
    required this.recipe,
    required this.creator,
    required this.seller,
    required this.buyer,
    required this.txID,
    required this.transactionTime,
    required this.currency,
    required this.price,
    required this.transactionEnum,
    required this.nftType,
    required this.nftUrl,
    required this.nftThumbnailUrl,
  });
}
