# Flutter High-Performance Feed Application with various functions

A highly optimized infinite-scrolling social feed built with Flutter and Supabase, submitted as part of the Full Stack Engineering Assignment.

## GitHub
https://github.com/AtharvaJadhavv/flutter-feed-assignment

## Tech Stack
- Flutter (Dart)
- Riverpod 2.5 (State Management)
- Supabase (Database, Storage, RPC)
- cached_network_image
- connectivity_plus

## Setup Instructions

1. Clone the repo:
   git clone https://github.com/AtharvaJadhavv/flutter-feed-assignment.git
   cd flutter-feed-assignment

2. Install dependencies:
   flutter pub get

3. Run the app:
   flutter run

Supabase is already configured and connected.

## Architecture & Approach

### State Management (Riverpod)
- PostsNotifier extends AsyncNotifier<List<Post>> and manages the entire feed state
- likedPostsProvider is a StateProvider<Set<String>> tracking liked post IDs locally
- All UI updates are driven by watching providers - no setState anywhere in the feed

### Infinite Scroll
- ScrollController detects when user is within 200px of the bottom
- Triggers loadMore() which fetches the next page (10 items) and appends to state
- Pull-to-refresh calls refresh() which resets to page 0

### GPU Protection (RepaintBoundary)
- Every PostCard is wrapped in RepaintBoundary
- This isolates the heavy BoxShadow (blurRadius: 24) rasterization to its own layer
- GPU does not recalculate shadow math during fast scrolling - verified in Flutter DevTools

### RAM Protection (memCacheWidth)
- CachedNetworkImage uses memCacheWidth: 400 on native platforms
- This ensures decoded image footprint in RAM matches the UI display size
- Prevents OOM crashes during fast scrolling through large image feeds

### 3-Tier Image Pipeline
- Thumbnail (300px): shown in feed for fast loading and low RAM usage
- Mobile (1080px): loaded in detail screen via FutureBuilder with AnimatedOpacity fade-in
- Raw (original): only fetched on explicit "Download High-Res" button tap

### Hero Animation
- GestureDetector on PostCard navigates to DetailScreen with Hero tag: 'post-{id}'
- DetailScreen immediately shows cached thumbnail while mobile quality fades in over 600ms
- Smooth transition with no blank frames

### Optimistic UI + Debouncing
- Like button immediately updates UI (heart turns red, count increments) via local state mutation
- Supabase RPC toggle_like fires asynchronously in background
- 500ms debounce per post prevents race conditions from rapid tapping
- On network failure: UI reverts to previous state + SnackBar shown to user

## Corner Cases Handled

### Spam Clicker
- 500ms debounce per post ID cancels previous pending call on rapid taps
- UI updates instantly every tap but only one network call fires per debounce window
- Database stays in sync - no double-like or desynced state

### Offline Revert
- If toggle_like RPC fails (no network): optimistic state is reverted
- SnackBar shows: "Could not update like. Check your connection."
- Feed shows error state with Retry button when initial load fails

### Rapid Scroll Jank Prevention
- RepaintBoundary isolates shadow rasterization per card
- memCacheWidth prevents large image decoding on scroll
- ListView.builder only builds visible items

## AI Usage (Honest)
- Used Claude + Cursor to scaffold Riverpod providers, screen structure, and widget layout
- Manually fixed: precacheImage called in initState (moved to didChangeDependencies)
- Manually fixed: dart:io HttpClient replaced with NetworkImage for web compatibility  
- Manually configured: Supabase RLS policies to allow public read/write
- Manually debugged: RLS blocking all reads (posts count was 0) and fixed via SQL
- Manually seeded: database with direct Unsplash URLs after Python script produced corrupted webp files from screenshots

## What I Would Add With More Time
- Real device testing on Android/iOS for CachedNetworkImage and memCacheWidth verification
- Framer-style scroll animations on card entry
- Supabase Realtime subscription for live like count updates
- User authentication instead of hardcoded user_123
- Save high-res image to device gallery on download
- Unit tests for PostsNotifier and toggleLike debounce logic
