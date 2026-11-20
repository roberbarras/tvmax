import 'dart:convert';
import 'dart:typed_data';

/// Decodes the stream URLs RTVE hides in the image returned by
/// `https://www.rtve.es/ztnr/movil/thumbnail/{manager}/videos/{id}.png?q=v2`.
///
/// The response body is a base64 PNG; each `tEXt` chunk holds an alphabet and an
/// obfuscated URL. This is the same scheme RTVE's own web player (pf_video.js)
/// uses, ported from yt-dlp's `RTVEBaseIE._decrypt_url` (yt_dlp/extractor/rtve.py).
class RtveUrlDecoder {
  /// Decodes the base64 body of the thumbnail endpoint.
  static List<String> decodeBase64Png(String body) => decodePng(base64.decode(body.trim()));

  static List<String> decodePng(Uint8List png) {
    final urls = <String>[];
    final view = ByteData.sublistView(png);
    var offset = 8; // PNG signature
    while (offset + 8 <= png.length) {
      final length = view.getUint32(offset);
      final type = latin1.decode(png.sublist(offset + 4, offset + 8));
      offset += 8;
      if (type == 'IEND' || offset + length > png.length) break;
      if (type == 'tEXt') {
        final text = latin1.decode(png.sublist(offset, offset + length).where((b) => b != 0).toList());
        final url = _decodeText(text);
        if (url != null) urls.add(url);
      }
      offset += length + 4; // chunk data + CRC
    }
    return urls;
  }

  /// `<alphabet>#<quality>%%<url>`; the quality part is optional.
  static String? _decodeText(String text) {
    final hash = text.indexOf('#');
    if (hash < 0) return null;
    final alphabet = _alphabet(text.substring(0, hash));
    var urlData = text.substring(hash + 1);
    final quality = urlData.lastIndexOf('%%');
    if (quality >= 0) urlData = urlData.substring(quality + 2);
    return _url(alphabet, urlData);
  }

  /// Keeps one character, skips 1, keeps one, skips 2, 3, 0, 1, 2...
  static List<String> _alphabet(String data) {
    final alphabet = <String>[];
    var skip = 0;
    var toSkip = 0;
    for (final char in data.split('')) {
      if (toSkip == 0) {
        alphabet.add(char);
        skip = (skip + 1) % 4;
        toSkip = skip;
      } else {
        toSkip--;
      }
    }
    return alphabet;
  }

  /// Each URL character is an alphabet index written as two digits (tens, units)
  /// with a growing number of filler characters between them.
  static String? _url(List<String> alphabet, String data) {
    final url = StringBuffer();
    var readingUnits = false;
    var toSkip = 3;
    var count = 1;
    var index = 0;
    for (final char in data.split('')) {
      if (!readingUnits) {
        final tens = int.tryParse(char);
        if (tens == null) return null;
        index = tens * 10;
        readingUnits = true;
      } else if (toSkip == 0) {
        final units = int.tryParse(char);
        if (units == null) return null;
        index += units;
        if (index >= alphabet.length) return null;
        url.write(alphabet[index]);
        toSkip = (count + 3) % 4;
        readingUnits = false;
        count++;
      } else {
        toSkip--;
      }
    }
    return url.isEmpty ? null : url.toString();
  }
}
