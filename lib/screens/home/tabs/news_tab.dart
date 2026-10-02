import 'package:flutter/material.dart';

import '../../../data/app_theme_store.dart';
import '../../../data/news_store.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/app_strings.dart';
import '../news_detail_screen.dart';
import '../../../widgets/app_ui.dart';

class NewsTab extends StatefulWidget {
  const NewsTab({super.key});

  @override
  State<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> {
  final PageController _bannerController = PageController();
  int _bannerPage = 0;

  @override
  void initState() {
    super.initState();
    NewsStore.instance.fetchNews();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListenableBuilder(
              listenable: NewsStore.instance,
              builder: (context, _) => _Header(count: NewsStore.instance.articles.length),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: NewsStore.instance,
                builder: (context, _) {
                  final store = NewsStore.instance;

                  if (store.loading && store.articles.isEmpty) {
                    return Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                      ),
                    );
                  }

                  if (store.error != null && store.articles.isEmpty) {
                    return _MessageState(
                      icon: Icons.cloud_off_rounded,
                      message: store.error!,
                      onRetry: store.fetchNews,
                    );
                  }

                  if (store.articles.isEmpty) {
                    return _MessageState(
                      icon: Icons.article_outlined,
                      message: 'Chưa có tin tức nào'.tr,
                      onRetry: store.fetchNews,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: store.fetchNews,
                    color: AppColors.accent,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isTablet = constraints.maxWidth >= 700;
                        final contentWidth =
                            isTablet ? (constraints.maxWidth < 900 ? constraints.maxWidth : 900) : constraints.maxWidth;
                        final cardWidth = isTablet ? (contentWidth - 32 - 16) / 2 : double.infinity;
                        final banner = store.featured;

                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: isTablet ? 900 : double.infinity),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (banner.isNotEmpty) ...[
                                    AspectRatio(
                                      aspectRatio: isTablet ? 2.4 : 390 / 216,
                                      child: _BannerCarousel(
                                        articles: banner,
                                        controller: _bannerController,
                                        onPageChanged: (i) => setState(() => _bannerPage = i),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _DotsIndicator(count: banner.length, index: _bannerPage),
                                    const SizedBox(height: 22),
                                  ],
                                  Text(
                                    'TIN MỚI NHẤT'.tr,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMuted,
                                        letterSpacing: 0.6),
                                  ),
                                  const SizedBox(height: 12),
                                  if (isTablet)
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 16,
                                      children: [
                                        for (final article in store.articles)
                                          SizedBox(width: cardWidth, child: _ArticleCard(article: article)),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
                                        for (final article in store.articles) ...[
                                          _ArticleCard(article: article),
                                          if (article != store.articles.last) const SizedBox(height: 16),
                                        ],
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int count;
  const _Header({required this.count});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(Navigator.of(context).canPop() ? 8 : 20, 14, 20, 20),
        child: Row(
          children: [
            if (Navigator.of(context).canPop())
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textPrimary,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tin tức'.tr,
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.2)),
                const SizedBox(height: 2),
                Text(
                  '$count ${'bài viết mới trong tuần này'.tr}',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }
}

// ── Featured banner carousel — image only, no text ─────────────────────────────

class _BannerCarousel extends StatelessWidget {
  final List<NewsArticle> articles;
  final PageController controller;
  final ValueChanged<int> onPageChanged;

  const _BannerCarousel({required this.articles, required this.controller, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 22, offset: const Offset(0, 8)),
          ],
        ),
        child: PageView.builder(
          controller: controller,
          itemCount: articles.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => _openArticle(context, articles[i]),
            child: NewsImage(url: articles[i].coverImageUrl, iconSize: 60),
          ),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int index;

  const _DotsIndicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 16 : 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : AppColors.border,
            borderRadius: BorderRadius.circular(2.5),
          ),
        );
      }),
    );
  }
}

// ── Article feed ────────────────────────────────────────────────────────────

class _ArticleCard extends StatelessWidget {
  final NewsArticle article;
  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openArticle(context, article),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(article.dateLabel,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(height: 160, child: NewsImage(url: article.coverImageUrl, iconSize: 44)),
              ),
              const SizedBox(height: 12),
              Text(
                article.title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.35),
              ),
              const SizedBox(height: 7),
              Text(
                article.excerpt,
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _openArticle(BuildContext context, NewsArticle article) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => NewsDetailScreen(article: article)));
}

/// A news photo loaded from the server, falling back to a soft branded
/// placeholder while it loads or if the URL is missing/broken.
class NewsImage extends StatelessWidget {
  final String url;
  final double iconSize;

  const NewsImage({super.key, required this.url, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) => progress == null ? child : _placeholder(),
      errorBuilder: (context, error, stack) {
        debugPrint('[NEWS_IMAGE] failed to load "$url": $error');
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    final isDark = AppThemeStore.instance.isDark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? const [Color(0xFF3A1F1F), Color(0xFF241212)] : const [Color(0xFFFFE3E3), Color(0xFFFFC4C4)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: iconSize,
          color: isDark ? AppColors.accent.withOpacity(0.32) : AppColors.accentSecondary.withOpacity(0.4),
        ),
      ),
    );
  }
}

// ── Error / empty state ─────────────────────────────────────────────────────

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Future<void> Function() onRetry;

  const _MessageState({required this.icon, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              child: Text('Tải lại'.tr, style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
