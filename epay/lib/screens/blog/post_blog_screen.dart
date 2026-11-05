import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';

class PostBlogScreen extends StatefulWidget {
  const PostBlogScreen({super.key});

  @override
  State<PostBlogScreen> createState() => _PostBlogScreenState();
}

class _PostBlogScreenState extends State<PostBlogScreen> {
  final _content = TextEditingController();
  final _photos = <String>[];
  bool _busy = false;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final ctrl = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the image URL of your withdrawal screenshot.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'https://...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (url != null && url.isNotEmpty) setState(() => _photos.add(url));
  }

  Future<void> _publish() async {
    if (_content.text.trim().length < 5) {
      showToast(context, 'Write at least a few words', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final msg = await Api.i.postBlog(_content.text.trim(), _photos);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showToast(context, msg);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Post Blog',
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Content'),
            AppCard(
              padding: const EdgeInsets.all(6),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.primary, width: 2.5),
                  ),
                ),
                child: TextField(
                  controller: _content,
                  maxLines: 7,
                  maxLength: 500,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                  decoration: const InputDecoration(
                    hintText: 'What do you want to share?',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),
            ),
            const SectionTitle('Photos'),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < _photos.length; i++)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        RemoteImage(
                          _photos[i],
                          width: 92,
                          height: 92,
                          radius: BorderRadius.circular(12),
                        ),
                        Positioned(
                          right: -6,
                          top: -6,
                          child: GestureDetector(
                            onTap: () => setState(() => _photos.removeAt(i)),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: AppColors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 15, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_photos.length < 6)
                    GestureDetector(
                      onTap: _addPhoto,
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: AppColors.ice,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GradientButton(
                label: 'Publish',
                loading: _busy,
                onPressed: _publish,
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                'Posts are reviewed before the reward is credited. '
                'Genuine withdrawal screenshots only.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.muted, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
