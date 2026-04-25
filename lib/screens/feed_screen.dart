import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final ScrollPosition position = _scrollController.position;
    final bool isNearBottom = (position.maxScrollExtent - position.pixels) <= 200;
    if (!isNearBottom) {
      return;
    }

    final AsyncValue<List<Post>> state = ref.read(postsNotifierProvider);
    final bool isLoadingMore = state.isLoading && state.hasValue;
    if (!isLoadingMore) {
      ref.read(postsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Post>> postsAsync = ref.watch(postsNotifierProvider);
    return postsAsync.when(
      data: (List<Post> posts) {
        // ignore: avoid_print
        print('Posts count: ${posts.length}');
        if (posts.isNotEmpty) {
          // ignore: avoid_print
          print('First post: ${posts.first.mediaThumbUrl}');
        }
        final bool isLoadingMore = postsAsync.isLoading && postsAsync.hasValue;
        return Scaffold(
          backgroundColor: Colors.grey.shade200,
          body: RefreshIndicator(
            onRefresh: () => ref.read(postsNotifierProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: posts.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == posts.length) {
                  if (isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return const SizedBox(height: 12);
                }

                return RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: PostCard(post: posts[index]),
                  ),
                );
              },
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace st) => Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 12),
              Text('Error: $e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(postsNotifierProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
