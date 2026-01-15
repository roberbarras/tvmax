import 'package:http/http.dart' as http;

class M3u8QualityParser {
  static Future<List<VideoQuality>> getQualities(String m3u8Url) async {
    try {
      final response = await http.get(Uri.parse(m3u8Url));
      if (response.statusCode == 200) {
        return _parseM3u8(response.body, m3u8Url);
      }
    } catch (e) {
      print('Error parsing M3U8: $e');
    }
    return [];
  }

  static List<VideoQuality> _parseM3u8(String content, String baseUrl) {
    final qualities = <VideoQuality>[];
    final lines = content.split('\n');
    
    int? bandwidth;
    int? width;
    int? height;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#EXT-X-STREAM-INF:')) {
        // Parse attributes
        final attributes = line.substring(18);
        final bandwidthMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(attributes);
        final resolutionMatch = RegExp(r'RESOLUTION=(\d+)x(\d+)').firstMatch(attributes);
        
        if (bandwidthMatch != null) bandwidth = int.parse(bandwidthMatch.group(1)!);
        if (resolutionMatch != null) {
          width = int.parse(resolutionMatch.group(1)!);
          height = int.parse(resolutionMatch.group(2)!);
        }
        
        // Next line should be the URL
        if (i + 1 < lines.length) {
          String url = lines[i+1].trim();
          if (!url.startsWith('http')) {
             // Handle relative URLs
             final base = baseUrl.substring(0, baseUrl.lastIndexOf('/') + 1);
             url = base + url;
          }
          
          if (width != null && height != null) {
             qualities.add(VideoQuality(
               width: width, 
               height: height, 
               bitrate: bandwidth ?? 0, 
               url: url
             ));
          }
        }
      }
    }
    
    // Sort by height descending
    qualities.sort((a, b) => b.height.compareTo(a.height));
    return qualities;
  }
}

class VideoQuality {
  final int width;
  final int height;
  final int bitrate;
  final String url;

  VideoQuality({required this.width, required this.height, required this.bitrate, required this.url});
  
  String get label => '${width}x${height}';
  String get description => '${(bitrate / 1000000).toStringAsFixed(1)} Mbps';
}
