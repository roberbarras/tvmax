class AppConstants {
  static const String apiBaseUrl = 'https://api.atresplayer.com';
  
  // Headers to mimic browser behavior
  // Headers to mimic browser behavior
  static const Map<String, String> _baseApiHeaders = {
    'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'accept-language': 'es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3',
    'accept-encoding': 'gzip, deflate, br',
    'upgrade-insecure-requests': '1',
    'sec-fetch-dest': 'document',
    'sec-fetch-mode': 'navigate',
    'sec-fetch-site': 'none',
    'sec-fetch-user': '?1',
    'connection': 'keep-alive',
    'referer': 'https://www.atresplayer.com/',
    'user-agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:106.0) Gecko/20100101 Firefox/106.0',
  };

  static Map<String, String> getHeaders(String? cookie) {
    if (cookie != null && cookie.isNotEmpty) {
      print('[AppConstants] Adding Cookie to headers (len=${cookie.length})');
    } else {
      print('[AppConstants] No cookie provided for headers');
    }
    final headers = Map<String, String>.from(_baseApiHeaders);
    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }
    return headers;
  }

  // Channel and Category IDs (from user script)
  static const String mainChannelId = '5a6b32667ed1a834493ec03b';
  static const String categoryId = '5a6a1ba0986b281d18a512b9';

  // News IDs
  static const String newsMainChannelId = '5a6b32667ed1a834493ec03b';
  static const String newsCategoryId = '5a6a215e986b281d18a512bc';

  // Series IDs
  static const String seriesMainChannelId = '5a6b32667ed1a834493ec03b';
  static const String seriesCategoryId = '5a6a1b22986b281d18a512b8';

  // Documentaries IDs
  static const String documentariesMainChannelId = '5a6b32667ed1a834493ec03b';
  static const String documentariesCategoryId = '5b067bf3986b28b0a27c2f42';
}
