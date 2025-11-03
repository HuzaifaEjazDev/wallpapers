class Wallpaper {
  final int id;
  final String pageUrl;
  final String imageUrl;
  final int views;
  final int downloads;
  final int likes;

  Wallpaper({
    required this.id,
    required this.pageUrl,
    required this.imageUrl,
    required this.views,
    required this.downloads,
    required this.likes,
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      id: json['id'] as int,
      pageUrl: json['pageURL'] as String,
      imageUrl: json['largeImageURL'] as String,
      views: json['views'] as int,
      downloads: json['downloads'] as int,
      likes: json['likes'] as int,
    );
  }
}