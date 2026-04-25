import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({required this.post, super.key});

  final Post post;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _showHighRes = false;
  late final Future<ImageProvider> _highResFuture;

  @override
  void initState() {
    super.initState();
    _highResFuture = _loadHighQualityImage()
      ..then((_) {
        if (mounted) {
          setState(() {
            _showHighRes = true;
          });
        }
      });
  }

  Future<void> _downloadHighRes() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fetching high-res image...')),
    );

    final HttpClient client = HttpClient();
    try {
      final Uri uri = Uri.parse(widget.post.mediaRawUrl);
      final HttpClientRequest request = await client.getUrl(uri);
      final HttpClientResponse response = await request.close();
      await response.drain<void>();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('High-res ready!')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch high-res image.')),
      );
    } finally {
      client.close(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(''),
        actions: <Widget>[
          TextButton(
            onPressed: _downloadHighRes,
            child: const Text('Download High-Res'),
          ),
        ],
      ),
      body: Hero(
        tag: 'post-${widget.post.id}',
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CachedNetworkImage(
              imageUrl: widget.post.mediaThumbUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            FutureBuilder<ImageProvider>(
              future: _highResFuture,
              builder: (BuildContext context, AsyncSnapshot<ImageProvider> snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                return AnimatedOpacity(
                  opacity: _showHighRes ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: Image(
                    image: snapshot.data!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<ImageProvider> _loadHighQualityImage() async {
    final CachedNetworkImageProvider provider =
        CachedNetworkImageProvider(widget.post.mediaMobileUrl);
    await precacheImage(provider, context);
    return provider;
  }
}
