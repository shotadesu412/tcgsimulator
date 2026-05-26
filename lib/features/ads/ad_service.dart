import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _bannerAdUnitId = 'ca-app-pub-2416149393168379/2643597949';

final adServiceProvider = Provider<AdService>((ref) => AdService());

class AdService {
  /// ATT許可リクエスト → MobileAds初期化
  Future<void> initialize() async {
    if (Platform.isIOS) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
    await MobileAds.instance.initialize();
  }

  BannerAd createBanner({required void Function(Ad, LoadAdError) onFailed}) {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(onAdFailedToLoad: onFailed),
    );
  }
}
