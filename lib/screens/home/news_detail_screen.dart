import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/news_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_strings.dart';
import 'tabs/news_tab.dart' show NewsImage;
import '../../widgets/app_ui.dart';

/// Full article view. Opens instantly with the list data (title, cover,
/// excerpt) and swaps in the Markdown `body` once `GET /news/:id` returns.
class NewsDetailScreen extends StatefulWidget {
  final NewsArticle article;
  const NewsDetailScreen({super.key, required this.article});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late NewsArticle _article = widget.article;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    NewsStore.instance.recordView(widget.article.id);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final full = await NewsStore.instance.fetchArticle(widget.article.id);
      if (!mounted) return;
      setState(() => _article = full);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Không tải được bài viết'.tr);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openLink(String? href) async {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final a = _article;
    final body = a.body ?? '';

    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('Tin tức'.tr,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (a.coverImageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: AspectRatio(aspectRatio: 16 / 9, child: NewsImage(url: a.coverImageUrl, iconSize: 56)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    a.title,
                    style:
                        TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [a.dateLabel, a.source, if (a.viewCount != null) '${a.viewCount} ${'lượt xem'.tr}'].join(' · '),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  if (body.isNotEmpty)
                    MarkdownBody(
                      data: body,
                      selectable: true,
                      onTapLink: (text, href, title) => _openLink(href),
                      imageBuilder: (uri, title, alt) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.network(
                            resolveNewsImageUrl(uri.toString()),
                            fit: BoxFit.fitWidth,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.65),
                        h1: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        h2: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        h3: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        listBullet: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                        a: TextStyle(color: AppColors.accent, decoration: TextDecoration.underline),
                        blockquote: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
                        ),
                        code: TextStyle(fontSize: 13, color: AppColors.textPrimary, backgroundColor: AppColors.card),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        horizontalRuleDecoration: BoxDecoration(
                          border: Border(top: BorderSide(color: AppColors.divider)),
                        ),
                      ),
                    )
                  else if (a.excerpt.isNotEmpty && !_loading)
                    Text(a.excerpt, style: TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.65)),
                  if (_loading && body.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        ),
                      ),
                    ),
                  if (_error != null && body.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          Text(_error!, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          TextButton(
                            onPressed: _load,
                            child: Text('Tải lại'.tr,
                                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
