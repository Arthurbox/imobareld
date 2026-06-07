import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdHelper {
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoaded = false;

  static String get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-4819995149639257/9253418531'; // ID Réel
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-4819995149639257/9253418531'; // ID Réel (utilisé le même pour l'instant)
    } else {
      return '';
    }
  }

  static String get interstitialAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-4819995149639257/3859825758'; // ID Réel
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-4819995149639257/3859825758'; // ID Réel (utilisé le même pour l'instant)
    } else {
      return '';
    }
  }

  static Future<void> loadInterstitialAd() async {
    if (kIsWeb) return;
    
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          debugPrint('AdMob Interstitial loaded.');
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob Interstitial failed to load: $error');
          _isInterstitialAdLoaded = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  static Future<void> showInterstitialAd() async {
    if (kIsWeb) return;

    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          loadInterstitialAd();
        },
      );
      await _interstitialAd!.show();
      _isInterstitialAdLoaded = false;
      _interstitialAd = null;
    } else {
      debugPrint('AdMob Interstitial not ready.');
      loadInterstitialAd();
    }
  }
}
