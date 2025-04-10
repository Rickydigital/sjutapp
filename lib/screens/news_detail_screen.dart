import 'package:flutter/material.dart';
import 'package:sjut/models/news.dart';
import 'package:sjut/services/api_service.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class NewsDetailScreen extends StatefulWidget {
  final int newsId;

  const NewsDetailScreen({required this.newsId, super.key});

  @override
  NewsDetailScreenState createState() => NewsDetailScreenState();
}

class NewsDetailScreenState extends State<NewsDetailScreen> {
  late Future<News> _newsFuture;
  final _commentController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isLiked = false;
  bool _isDisliked = false;
  bool _videoInitError = false; // New flag for video error
  String get baseUrl => 'http://192.168.137.1:8000';

  @override
  void initState() {
    super.initState();
    _newsFuture = _fetchNewsDetail();
  }

    Future<News> _fetchNewsDetail() async {
    try {
      final news = await ApiService().fetchNewsDetail(widget.newsId);
      logger.i('Fetched news detail for ID ${widget.newsId} - Image: ${news.image}, Video: ${news.video}');
      _isLiked = news.reactions.any((r) => r.type == 'like' && r.userId == ApiService.currentUserId);
      _isDisliked = news.reactions.any((r) => r.type == 'dislike' && r.userId == ApiService.currentUserId);
      if (news.video != null && news.video!.isNotEmpty) {
        _initializeVideo(news.video!); // Start video initialization without awaiting
      }
      return news;
    } catch (e) {
      logger.e('Error fetching news detail for ID ${widget.newsId}: $e');
      rethrow;
    }
  }

  Future<void> _initializeVideo(String? videoUrl) async {
    if (videoUrl != null && videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse('$baseUrl/storage/$videoUrl'));
      await _videoController!.initialize().then((_) {
        if (mounted) {
          setState(() {
            _videoInitError = false;
          });
          _videoController?.setLooping(true);
        }
      }).catchError((e) {
        logger.e('Video init error: $e');
        if (mounted) {
          setState(() {
            _videoInitError = true;
          });
        }
      });
    }
  }

  Future<void> _toggleReaction(String type) async {
    if (ApiService.token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please log in to react'),
            action: SnackBarAction(
              label: 'Login',
              onPressed: () => Navigator.pushNamed(context, '/login'),
            ),
          ),
        );
      }
      return;
    }

    final wasLiked = _isLiked;
    final wasDisliked = _isDisliked;

    setState(() {
      if (type == 'like') {
        _isLiked = !_isLiked;
        if (_isLiked && _isDisliked) _isDisliked = false;
      } else {
        _isDisliked = !_isDisliked;
        if (_isDisliked && _isLiked) _isLiked = false;
      }
    });

    try {
      if ((type == 'like' && wasLiked) || (type == 'dislike' && wasDisliked)) {
        await ApiService().removeReaction(widget.newsId, type);
        logger.i('Removed $type reaction from news ${widget.newsId}');
      } else {
        await ApiService().react(widget.newsId, type);
        logger.i('Added $type reaction to news ${widget.newsId}');
      }
      final updatedNews = await ApiService().fetchNewsDetail(widget.newsId);
      setState(() {
        _isLiked = updatedNews.reactions.any((r) => r.type == 'like' && r.userId == ApiService.currentUserId);
        _isDisliked = updatedNews.reactions.any((r) => r.type == 'dislike' && r.userId == ApiService.currentUserId);
        _newsFuture = Future.value(updatedNews);
      });
    } catch (e) {
      logger.e('Failed to toggle $type reaction on news ${widget.newsId}: $e');
      setState(() {
        _isLiked = wasLiked;
        _isDisliked = wasDisliked;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty || ApiService.token == null) {
      if (mounted && ApiService.token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please log in to comment'),
            action: SnackBarAction(
              label: 'Login',
              onPressed: () => Navigator.pushNamed(context, '/login'),
            ),
          ),
        );
      }
      return;
    }
    try {
      await ApiService().addComment(widget.newsId, _commentController.text);
      logger.i('Added comment to news ${widget.newsId}');
      setState(() {
        _newsFuture = _fetchNewsDetail();
        _commentController.clear();
      });
    } catch (e) {
      logger.e('Failed to add comment to news ${widget.newsId}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _shareToWhatsApp(News news) async {
    final url = Uri.parse(
      'whatsapp://send?text=Check out this news: ${news.title ?? 'No Title'}\n${news.description ?? ''}\n$baseUrl/news/${widget.newsId}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp not installed')));
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Details'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          FutureBuilder<News>(
            future: _newsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final news = snapshot.data!;
              final hasMultipleMedia = (news.image != null && news.image!.isNotEmpty) && (news.video != null && news.video!.isNotEmpty);
              return hasMultipleMedia
                  ? IconButton(
                      icon: const Icon(Icons.share, color: Colors.black),
                      onPressed: () => _shareToWhatsApp(news),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<News>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No news found'));
          }

          final news = snapshot.data!;
          final likeCount = news.reactions.where((r) => r.type == 'like').length;
          final dislikeCount = news.reactions.where((r) => r.type == 'dislike').length;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (news.image != null && news.image!.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            '$baseUrl/storage/${news.image}',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 250,
                            loadingBuilder: (context, child, loadingProgress) {
                              return loadingProgress == null ? child : const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 250,
                              color: Colors.grey[300],
                              child: const Center(child: Text('Image unavailable')),
                            ),
                          ),
                        ),
                      if (news.video != null && news.video!.isNotEmpty && _videoController != null)
                        ClipRRect(
                          borderRadius: news.image == null
                              ? const BorderRadius.vertical(top: Radius.circular(12))
                              : const BorderRadius.vertical(bottom: Radius.zero),
                          child: _videoInitError
                              ? Container(
                                  height: 250,
                                  color: Colors.grey[300],
                                  child: const Center(child: Text('Video unavailable')),
                                )
                              : _videoController!.value.isInitialized
                                  ? Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: _videoController!.value.aspectRatio,
                                          child: VideoPlayer(_videoController!),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                                            });
                                          },
                                        ),
                                      ],
                                    )
                                  : const Center(child: CircularProgressIndicator()),
                        ),
                      if (news.image == null && news.video == null)
                        Container(
                          height: 250,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: Text('No media available')),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news.title ?? 'No Title',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMM d, yyyy • HH:mm').format(
                          DateTime.parse(news.createdAt ?? DateTime.now().toIso8601String()),
                        ),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    news.description ?? 'No Description',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                              color: _isLiked ? Colors.red : Colors.grey[700],
                            ),
                            onPressed: () => _toggleReaction('like'),
                          ),
                          Text('$likeCount', style: TextStyle(color: Colors.grey[700])),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: Icon(
                              _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                              color: _isDisliked ? Colors.green : Colors.grey[700],
                            ),
                            onPressed: () => _toggleReaction('dislike'),
                          ),
                          Text('$dislikeCount', style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                        onPressed: () => FocusScope.of(context).requestFocus(FocusNode()),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: _addComment,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comments (${news.comments.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (news.comments.isEmpty) const Text('No comments yet', style: TextStyle(color: Colors.grey)),
                      ...news.comments.map(
                        (c) => Container(
                          margin: const EdgeInsets.only(bottom: 4.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: _getAvatarColor(c.user.reg_no),
                                child: Text(
                                  c.user.reg_no.isNotEmpty ? c.user.reg_no[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.user.reg_no,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c.comment,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getAvatarColor(String regNo) {
    final hash = regNo.hashCode;
    return Color.fromARGB(
      255,
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      hash & 0x0000FF,
    );
  }
}