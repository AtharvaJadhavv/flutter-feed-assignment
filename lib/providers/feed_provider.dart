import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/post.dart';

const userId = 'user_123';

final likedPostsProvider = StateProvider<Set<String>>((ref) => <String>{});

class PostsNotifier extends AsyncNotifier<List<Post>> {
  final Map<String, int> _lastToggleEpochMs = <String, int>{};
  final Map<String, int> _toggleTokenByPost = <String, int>{};
  int _nextToggleToken = 0;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<Post>> build() {
    return fetchPosts(0);
  }

  Future<List<Post>> fetchPosts(int page) async {
    final dynamic response = await _client
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .range(page * 10, page * 10 + 9);

    final List<dynamic> rows = response as List<dynamic>;
    return rows
        .map((dynamic row) => Post.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> loadMore() async {
    final List<Post> currentPosts = state.valueOrNull ?? <Post>[];
    final int nextPage = currentPosts.length ~/ 10;

    state = const AsyncLoading<List<Post>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final List<Post> nextPosts = await fetchPosts(nextPage);
      return <Post>[...currentPosts, ...nextPosts];
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<Post>>();
    state = await AsyncValue.guard(() => fetchPosts(0));
  }

  Future<void> toggleLike(String postId) async {
    final List<Post>? currentPosts = state.valueOrNull;
    if (currentPosts == null) {
      return;
    }

    final int postIndex = currentPosts.indexWhere((Post post) => post.id == postId);
    if (postIndex == -1) {
      return;
    }

    final Set<String> currentLiked = ref.read(likedPostsProvider);
    final bool wasLiked = currentLiked.contains(postId);
    final bool willBeLiked = !wasLiked;

    final int beforeLikeCount = currentPosts[postIndex].likeCount;
    final int updatedLikeCount = beforeLikeCount + (willBeLiked ? 1 : -1);

    final Set<String> nextLiked = <String>{...currentLiked};
    if (willBeLiked) {
      nextLiked.add(postId);
    } else {
      nextLiked.remove(postId);
    }
    ref.read(likedPostsProvider.notifier).state = nextLiked;

    final List<Post> optimisticPosts = <Post>[...currentPosts];
    optimisticPosts[postIndex] =
        optimisticPosts[postIndex].copyWith(likeCount: updatedLikeCount < 0 ? 0 : updatedLikeCount);
    state = AsyncData<List<Post>>(optimisticPosts);

    final int now = DateTime.now().millisecondsSinceEpoch;
    final int previousEpoch = _lastToggleEpochMs[postId] ?? 0;
    _lastToggleEpochMs[postId] = now;

    // Debounce network calls and invalidate previous pending call tokens.
    final int token = ++_nextToggleToken;
    _toggleTokenByPost[postId] = token;

    final int delayMs = (now - previousEpoch) < 500 ? 500 : 0;
    if (delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }

    if (_toggleTokenByPost[postId] != token) {
      return;
    }

    try {
      await _client.rpc('toggle_like', params: <String, dynamic>{
        'p_post_id': postId,
        'p_user_id': userId,
      });
    } catch (error, stackTrace) {
      if (_toggleTokenByPost[postId] == token) {
        final List<Post>? latestPosts = state.valueOrNull;
        if (latestPosts != null) {
          final int latestIndex = latestPosts.indexWhere((Post post) => post.id == postId);
          if (latestIndex != -1) {
            final List<Post> revertedPosts = <Post>[...latestPosts];
            revertedPosts[latestIndex] = revertedPosts[latestIndex].copyWith(
              likeCount: beforeLikeCount,
            );
            state = AsyncData<List<Post>>(revertedPosts);
          }
        }

        final Set<String> revertedLiked = <String>{...ref.read(likedPostsProvider)};
        if (wasLiked) {
          revertedLiked.add(postId);
        } else {
          revertedLiked.remove(postId);
        }
        ref.read(likedPostsProvider.notifier).state = revertedLiked;

        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }
}

final postsNotifierProvider =
    AsyncNotifierProvider<PostsNotifier, List<Post>>(PostsNotifier.new);

@Deprecated('Use postsNotifierProvider instead.')
final postsProvider = postsNotifierProvider;
