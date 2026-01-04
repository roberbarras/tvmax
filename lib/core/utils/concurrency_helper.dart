import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb

class ConcurrencyHelper {
  /// Returns the optimal number of concurrent operations based on device CPU threads.
  /// 
  /// Policy:
  /// - < 4 threads: 1 call (Sequential)
  /// - 4-5 threads: 2 calls
  /// - 6-11 threads: 3 calls
  /// - >= 12 threads: 4 calls
  static int getDynamicBatchSize() {
    // Web doesn't expose strict thread counts nicely in Dart IO usually, but kIsWeb check helps safety.
    // On web, we might default to 2 or 3. But for now this logic is driven by "Old Windows" machine constraints.
    if (kIsWeb) return 3; 

    final processors = Platform.numberOfProcessors;
    
    if (processors < 4) {
      return 1;
    } else if (processors >= 4 && processors <= 5) {
      return 2;
    } else if (processors >= 6 && processors < 12) {
      return 3;
    } else {
      return 4;
    }
  }
}
