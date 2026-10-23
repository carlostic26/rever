import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/admob_constants.dart';
import '../../../../core/theme/app_colors.dart';

class BlogArticleScreen extends StatefulWidget {
  final String title;
  final String url;

  const BlogArticleScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<BlogArticleScreen> createState() => _BlogArticleScreenState();
}

class _BlogArticleScreenState extends State<BlogArticleScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;

  // Banner Ad adaptativo de AdMob
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool _isLoadingBanner = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              '[BlogArticleScreen] Error al cargar la página: ${error.description}',
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !_isLoadingBanner) {
      _loadAdaptiveBannerAd();
    }
  }

  Future<void> _loadAdaptiveBannerAd() async {
    _isLoadingBanner = true;
    final int width = MediaQuery.of(context).size.width.truncate();

    AnchoredAdaptiveBannerAdSize? adaptiveSize;
    try {
      adaptiveSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    } catch (e) {
      debugPrint('[BlogArticleScreen] Error calculando tamaño banner: $e');
    }

    if (!mounted) return;

    _bannerAd = BannerAd(
      adUnitId: AdMobConstants.bannerAdUnitId,
      size: adaptiveSize ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[BlogArticleScreen] Error cargando BannerAd: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isBannerLoaded = false;
            });
          }
        },
      ),
    );
    await _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final Color appBarBg =
        isDark ? AppColors.darkBackgroundAlt : AppColors.lightBackgroundAlt;
    final Color textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: textSecondary,
              size: 22,
            ),
            tooltip: 'Recargar página',
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _loadingProgress > 0 ? _loadingProgress / 100.0 : null,
                backgroundColor: Colors.transparent,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                minHeight: 3,
              ),
            ),
        ],
      ),
      bottomNavigationBar: (_isBannerLoaded && _bannerAd != null)
          ? SafeArea(
              top: false,
              child: Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                decoration: BoxDecoration(color: bgColor),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : null,
    );
  }
}

