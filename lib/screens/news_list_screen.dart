import 'package:flutter/material.dart';
import 'package:sjut/models/news.dart';
import 'package:sjut/screens/news_detail_screen.dart';
import 'package:sjut/services/api_service.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  NewsScreenState createState() => NewsScreenState();
}

class NewsScreenState extends State<NewsScreen> {
  List<News>? _newsList; // Local list to manage news items
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _likedStates = {};
  String get baseUrl => 'http://192.168.137.1:8000'; // Updated IP address

  @override
  void initState() {
    super.initState();
    _fetchNews(); // Initial fetch
  }

 Future<void> _fetchNews() async {
  try {
    final newsList = await ApiService().fetchNews();
    logger.i('Fetched ${newsList.length} news items');
    setState(() {
      _newsList = newsList; // Update UI immediately
    });
    for (var news in newsList) {
      _likedStates[news.id] = news.reactions.any((r) => r.type == 'like' && r.userId == ApiService.currentUserId);
      if (news.video != null && news.video!.isNotEmpty) {
        _initializeVideo(news.video!, news.id); // No await, runs in background
      }
    }
  } catch (e) {
    logger.e('Error fetching news: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching news: $e')));
    }
  }
}

  @override
  void dispose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeVideo(String videoUrl, int index) async {
    if (!_videoControllers.containsKey(index)) {
      final controller = VideoPlayerController.networkUrl(Uri.parse('$baseUrl/storage/$videoUrl'));
      _videoControllers[index] = controller;
      await controller.initialize().then((_) {
        if (mounted) {
          setState(() {});
          controller.setLooping(true);
        }
      }).catchError((e) {
        logger.e('Video init error for news $index: $e');
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _shareToWhatsApp(String title) async {
    final url = Uri.parse('whatsapp://send?text=Check out this news: $title');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp not installed')));
    }
  }

  Future<void> _toggleLike(int newsId) async {
    if (ApiService.token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please log in to like posts'),
            action: SnackBarAction(
              label: 'Login',
              onPressed: () => Navigator.pushNamed(context, '/login'),
            ),
          ),
        );
      }
      return;
    }

    final isLiked = _likedStates[newsId] ?? false;

    // Optimistic UI update
    setState(() {
      _likedStates[newsId] = !isLiked;
      if (_newsList != null) {
        final newsIndex = _newsList!.indexWhere((n) => n.id == newsId);
        if (newsIndex != -1) {
          final news = _newsList![newsIndex];
          final newReactions = List<Reaction>.from(news.reactions);
          if (!isLiked) {
            newReactions.add(Reaction(type: 'like', userId: ApiService.currentUserId));
          } else {
            newReactions.removeWhere((r) => r.type == 'like' && r.userId == ApiService.currentUserId);
          }
          _newsList![newsIndex] = News(
            id: news.id,
            title: news.title,
            description: news.description,
            image: news.image,
            video: news.video,
            userId: news.userId,
            reactions: newReactions,
            comments: news.comments,
            createdAt: news.createdAt,
          );
        }
      }
    });

    // Sync with server in the background
    try {
      if (isLiked) {
        await ApiService().removeReaction(newsId, 'like');
        logger.i('Removed like from news $newsId');
      } else {
        await ApiService().react(newsId, 'like');
        logger.i('Added like to news $newsId');
      }
      // Fetch updated news item to sync with server
      final updatedNews = await ApiService().fetchNewsDetail(newsId);
      setState(() {
        if (_newsList != null) {
          final newsIndex = _newsList!.indexWhere((n) => n.id == newsId);
          if (newsIndex != -1) {
            _newsList![newsIndex] = updatedNews;
            _likedStates[newsId] = updatedNews.reactions.any((r) => r.type == 'like' && r.userId == ApiService.currentUserId);
          }
        }
      });
    } catch (e) {
      logger.e('Failed to toggle like on news $newsId: $e');
      // Revert on error
      setState(() {
        _likedStates[newsId] = isLiked;
        if (_newsList != null) {
          final newsIndex = _newsList!.indexWhere((n) => n.id == newsId);
          if (newsIndex != -1) {
            final news = _newsList![newsIndex];
            final newReactions = List<Reaction>.from(news.reactions);
            if (!isLiked) {
              newReactions.removeWhere((r) => r.type == 'like' && r.userId == ApiService.currentUserId);
            } else {
              newReactions.add(Reaction(type: 'like', userId: ApiService.currentUserId));
            }
            _newsList![newsIndex] = News(
              id: news.id,
              title: news.title,
              description: news.description,
              image: news.image,
              video: news.video,
              userId: news.userId,
              reactions: newReactions,
              comments: news.comments,
              createdAt: news.createdAt,
            );
          }
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update like: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Feed'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _newsList == null
          ? const Center(child: CircularProgressIndicator())
          : _newsList!.isEmpty
              ? const Center(child: Text('No news available'))
              : ListView.builder(
                  itemCount: _newsList!.length,
                  itemBuilder: (context, index) {
                    final news = _newsList![index];
                    final mediaItems = [
                      if (news.image != null && news.image!.isNotEmpty) news.image!,
                      if (news.video != null && news.video!.isNotEmpty) news.video!,
                    ];
                    final likeCount = news.reactions.where((r) => r.type == 'like').length;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mediaItems.isNotEmpty)
                            SizedBox(
                              height: 200,
                              child: Stack(
                                children: [
                                  PageView.builder(
                                    itemCount: mediaItems.length,
                                    itemBuilder: (context, mediaIndex) {
                                      final media = mediaItems[mediaIndex];
                                      if (media == news.video && _videoControllers[news.id] != null) {
                                        return Stack(
                                          alignment: Alignment.center,
                                          children: [
                                              _videoControllers[news.id]!.value.isInitialized
                                                ? VideoPlayer(_videoControllers[news.id]!)
                                                : Container(
                                                    height: 200,
                                                    color: Colors.grey[300],
                                                    child: const Center(child: CircularProgressIndicator()),
                                                  ),
                                            if (_videoControllers[news.id]!.value.isInitialized)
                                              IconButton(
                                                icon: Icon(
                                                  _videoControllers[news.id]!.value.isPlaying
                                                      ? Icons.pause
                                                      : Icons.play_arrow,
                                                  color: Colors.white,
                                                  size: 40,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _videoControllers[news.id]!.value.isPlaying
                                                        ? _videoControllers[news.id]!.pause()
                                                        : _videoControllers[news.id]!.play();
                                                  });
                                                },
                                              ),
                                          ],
                                        );
                                      } else {
                                        return Image.network(
                                          '$baseUrl/storage/$media',
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 200,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              height: 200,
                                              color: Colors.grey[300],
                                              child: const Center(child: CircularProgressIndicator()),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            logger.e('Image load error for $media: $error');
                                            return Container(
                                              height: 200,
                                              color: Colors.grey[300],
                                              child: const Center(child: Text('Media unavailable')),
                                            );
                                          },
                                        );
                                      }
                                    },
                                  ),
                                  if (mediaItems.length > 1)
                                    Positioned(
                                      right: 8,
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white.withAlpha(178),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          else
                            Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(child: Text('No media available')),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            _likedStates[news.id] == true ? Icons.favorite : Icons.favorite_border,
                                            color: _likedStates[news.id] == true ? Colors.red : Colors.grey[700],
                                          ),
                                          onPressed: () => _toggleLike(news.id),
                                        ),
                                        Text(
                                          '$likeCount',
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.share_outlined),
                                          color: Colors.grey[700],
                                          onPressed: () => _shareToWhatsApp(news.title ?? 'No Title'),
                                        ),
                                        const Text('Share', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.message_outlined),
                                          color: Colors.grey[700],
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => NewsDetailScreen(newsId: news.id)),
                                          ),
                                        ),
                                        Text(
                                          '${news.comments.length}',
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  DateFormat('MMM d, HH:mm').format(
                                    DateTime.parse(news.createdAt ?? DateTime.now().toIso8601String()),
                                  ),
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              news.title ?? 'No Title',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    news.description ?? 'No Description',
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => NewsDetailScreen(newsId: news.id)),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 4.0),
                                    child: Text(
                                      'Read More',
                                      style: TextStyle(color: Colors.blue, fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}