import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import '../providers/feed_provider.dart';
import '../screens/detail_screen.dart';

class PostCard extends StatelessWidget {
  const PostCard({required this.post, super.key});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<DetailScreen>(
              builder: (_) => DetailScreen(post: post),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                blurRadius: 24,
                spreadRadius: 2,
                color: Colors.black.withValues(alpha: 0.18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: <Widget>[
                Hero(
                  tag: 'post-${post.id}',
                  child: kIsWeb
                      ? Image.network(
                          post.mediaThumbUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 300,
                          errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
                              Container(
                            height: 300,
                            color: Colors.grey.shade800,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image, color: Colors.white),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: post.mediaThumbUrl,
                          memCacheWidth: 400,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 300,
                          placeholder: (BuildContext context, String url) => Container(
                            height: 300,
                            color: Colors.grey.shade800,
                          ),
                          errorWidget:
                              (BuildContext context, String url, Object error) => Container(
                            height: 300,
                            color: Colors.grey.shade800,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image, color: Colors.white),
                          ),
                        ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 120,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: <Color>[Colors.black87, Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Consumer(
                    builder: (BuildContext context, WidgetRef ref, Widget? child) {
                      final bool isLiked = ref.watch(likedPostsProvider).contains(post.id);
                      return Row(
                        children: <Widget>[
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              try {
                                await ref
                                    .read(postsNotifierProvider.notifier)
                                    .toggleLike(post.id);
                              } catch (_) {
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not update like. Check your connection.',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.white,
                            ),
                          ),
                          Text(
                            '${post.likeCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
