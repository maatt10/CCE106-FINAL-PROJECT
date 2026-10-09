import 'package:flutter/material.dart';

/// Maps a service name to its brand color.
/// Falls back to a deterministic hash-based color if unknown.
class BrandColors {
  static const Map<String, Color> _known = {
    'netflix': Color(0xFFE50914),
    'spotify': Color(0xFF1DB954),
    'youtube premium': Color(0xFFFF0033),
    'youtube': Color(0xFFFF0000),
    'disney+': Color(0xFF113CCF),
    'disney plus': Color(0xFF113CCF),
    'apple music': Color(0xFFFA243C),
    'icloud+': Color(0xFF007AFF),
    'icloud': Color(0xFF007AFF),
    'google one': Color(0xFF4285F4),
    'canva pro': Color(0xFF00C4CC),
    'canva': Color(0xFF00C4CC),
    'microsoft 365': Color(0xFFD83B01),
    'crunchyroll': Color(0xFFF47521),
    'grabunlimited': Color(0xFF00B14F),
    'pc game pass': Color(0xFF107C10),
    'xbox game pass': Color(0xFF107C10),
    'notion': Color(0xFF000000),
    'adobe creative cloud': Color(0xFFFF0000),
    'dropbox': Color(0xFF0061FF),
    'prime video': Color(0xFF00A8E1),
    'hbo max': Color(0xFF991EEB),
    'viu': Color(0xFFFFCC00),
    'coursera plus': Color(0xFF0056D2),
    'skillshare': Color(0xFF00FF84),
    'duolingo super': Color(0xFF58CC02),
  };

  static const List<Color> _fallbackPalette = [
    Color(0xFF6C4CE0),
    Color(0xFFEC4899),
    Color(0xFF0EA5E9),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
  ];

  /// Returns the brand color for [name]. Case-insensitive.
  static Color of(String name) {
    final key = name.trim().toLowerCase();
    if (_known.containsKey(key)) return _known[key]!;

    // Fuzzy match: check if the name contains a known key.
    for (final entry in _known.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }

    // Deterministic hash fallback so the same name always gets
    // the same color.
    int hash = 0;
    for (final c in name.codeUnits) {
      hash = c + ((hash << 5) - hash);
    }
    return _fallbackPalette[hash.abs() % _fallbackPalette.length];
  }
}