/// কুরআনের ইংরেজি হরফের উচ্চারণ (Tanzil) থেকে বাংলা হরফে আনুমানিক উচ্চারণ বানায়।
///
/// এটি নিয়ম ধরে স্বয়ংক্রিয় রূপান্তর, তাই কিছু শব্দে বানান একটু আলাদা হতে পারে।
/// কোনো শব্দের বানান ঠিক করতে চাইলে শুধু এই ফাইলের নিয়ম বা মানচিত্র বদলালেই হবে।
class BanglaTranslit {
  BanglaTranslit._();

  static const String _vowels = 'aeiou';
  static const String _shamsi = 'tTDdrzsSn';
  static const List<String> _skipAl = ['ala', 'alam'];

  // ই + য় ইত্যাদির জন্য: য় = য + নুক্তা, ওয় = ও + য়
  static const String _ya = '\u09AF\u09BC';
  static const String _wa = '\u0993\u09AF\u09BC';
  static const String _hasanta = '\u09CD';

  // T = ث (ছ), D = ذ/ظ (য), S = ش (শ), x = خ (খ), g = غ (গ)
  static const Map<String, String> _cons = {
    'b': 'ব',
    't': 'ত',
    'T': 'ছ',
    'j': 'জ',
    'h': 'হ',
    'x': 'খ',
    'd': 'দ',
    'D': 'য',
    'r': 'র',
    'z': 'য',
    's': 'স',
    'S': 'শ',
    'g': 'গ',
    'f': 'ফ',
    'q': 'ক্ব',
    'k': 'ক',
    'l': 'ল',
    'm': 'ম',
    'n': 'ন',
  };

  static const Map<String, String> _kar = {
    'a': 'া',
    'i': 'ি',
    'u': 'ু',
    'ee': 'ী',
    'oo': 'ূ',
  };

  static const Map<String, String> _ind = {
    'a': 'আ',
    'i': 'ই',
    'u': 'উ',
    'ee': 'ঈ',
    'oo': 'ঊ',
  };

  /// [latin] = Tanzil-এর ইংরেজি উচ্চারণ, [arabic] = ওই আয়াতের আরবি টেক্সট।
  /// আরবি টেক্সট দেখে ث/ذ/ظ আলাদা করা হয় এবং আয়াতের শেষে থামার নিয়ম (ওয়াকফ) ঠিক করা হয়।
  static String convert(String latin, String arabic) {
    var s = latin.trim().replaceAll('AA', '#').toLowerCase();
    if (s.isEmpty) return '';
    s = _markTh(s, arabic);
    s = s.replaceAll('sh', 'S').replaceAll('kh', 'x').replaceAll('gh', 'g');

    var words = <String>[];
    for (final w in s.split(RegExp(r'\s+'))) {
      if (w.isNotEmpty) words.add(_dropInnerAl(w));
    }
    if (words.isEmpty) return '';

    words = _liaison(words);
    words = words.map(_initialAl).toList();
    words[words.length - 1] = _waqf(words[words.length - 1], arabic);

    final out = <String>[];
    for (final w in words) {
      if (w.isNotEmpty) out.add(_toBn(w));
    }
    return out.join(' ');
  }

  // ---------- "th" কে ث নাকি ذ/ظ তা আরবি টেক্সট মিলিয়ে ঠিক করা ----------

  static String _markTh(String s, String arabic) {
    final starts = <int>[];
    final lens = <int>[];
    var i = 0;
    while (i < s.length) {
      if (s.startsWith('th', i)) {
        final ln = s.startsWith('th', i + 2) ? 4 : 2;
        starts.add(i);
        lens.add(ln);
        i += ln;
      } else {
        i++;
      }
    }
    if (starts.isEmpty) return s;

    final letters = <String>[];
    for (final r in arabic.runes) {
      if (r == 0x062B) {
        letters.add('T');
      } else if (r == 0x0630 || r == 0x0638) {
        letters.add('D');
      }
    }
    final useLetters = letters.length == starts.length;

    final sb = StringBuffer();
    var pos = 0;
    for (var g = 0; g < starts.length; g++) {
      sb.write(s.substring(pos, starts[g]));
      final m = useLetters ? letters[g] : 'D';
      sb.write(lens[g] == 4 ? '$m$m' : m);
      pos = starts[g] + lens[g];
    }
    sb.write(s.substring(pos));
    return sb.toString();
  }

  // ---------- আলিফ-লাম (ال) সংক্রান্ত নিয়ম ----------

  static bool _isShamsiDoubled(String rest) {
    return rest.length >= 2 && rest[0] == rest[1] && _shamsi.contains(rest[0]);
  }

  /// শব্দের ভেতরে উপসর্গের পরে আসা "al" (যেমন waalssalata, biAllahi) সরায়।
  static String _dropInnerAl(String w) {
    if (w.length < 5) return w;
    for (var p = 2; p < w.length - 2; p++) {
      if ('aiu'.contains(w[p - 1]) && w[p] == 'a' && w[p + 1] == 'l') {
        final rest = w.substring(p + 2);
        if (_isShamsiDoubled(rest)) {
          return w.substring(0, p) + rest;
        }
        return '${w.substring(0, p)}l$rest';
      }
    }
    return w;
  }

  /// আগের শব্দ স্বরবর্ণে শেষ হলে পরের শব্দের "al" আগের শব্দের সঙ্গে মিলিয়ে পড়া হয়।
  static List<String> _liaison(List<String> words) {
    final out = <String>[];
    for (final w in words) {
      if (out.isNotEmpty) {
        final prev = out[out.length - 1];
        if (_vowels.contains(prev[prev.length - 1])) {
          if (w.startsWith('all') && w.length > 3) {
            out[out.length - 1] = prev + w.substring(1);
            continue;
          }
          if (w.startsWith('al') && w.length >= 4 && !_skipAl.contains(w)) {
            final rest = w.substring(2);
            if (_isShamsiDoubled(rest)) {
              out[out.length - 1] = prev + rest[0];
              out.add(rest.substring(1));
            } else {
              out[out.length - 1] = '${prev}l';
              out.add(rest);
            }
            continue;
          }
        }
      }
      out.add(w);
    }
    return out;
  }

  /// আয়াতের শুরুতে "alrrahmani" হলো "ar-rahmani"।
  static String _initialAl(String w) {
    if (w.startsWith('al') && w.length >= 4 && !_skipAl.contains(w)) {
      final rest = w.substring(2);
      if (_isShamsiDoubled(rest)) {
        return 'a${rest[0]}-${rest.substring(1)}';
      }
    }
    return w;
  }

  // ---------- আয়াতের শেষে থামা (ওয়াকফ) ----------

  static bool _isMark(int r) {
    return (r >= 0x064B && r <= 0x065F) ||
        r == 0x0670 ||
        r == 0x0640 ||
        (r >= 0x06D6 && r <= 0x06ED) ||
        (r >= 0x08D3 && r <= 0x08FF);
  }

  static int _lastBase(String arabic) {
    final runes = arabic.runes.toList();
    for (var i = runes.length - 1; i >= 0; i--) {
      final r = runes[i];
      if (r == 0x20 || r == 0x0A || r == 0x0D || r == 0x09 || r == 0xA0 || _isMark(r)) {
        continue;
      }
      return r;
    }
    return 0;
  }

  static String _waqf(String w, String arabic) {
    if (w.length < 3) return w;
    final lb = _lastBase(arabic);
    final longA = lb == 0x0627 || lb == 0x0649;
    final isNun = lb == 0x0646;

    if (w.endsWith('un') || w.endsWith('in')) {
      if (w.length >= 4 && !isNun) return w.substring(0, w.length - 2);
      return w;
    }
    if (w.endsWith('an')) {
      if (w.length >= 4 && !isNun) {
        return longA ? w.substring(0, w.length - 1) : w.substring(0, w.length - 2);
      }
      return w;
    }
    final last = w[w.length - 1];
    if (last == 'i' || last == 'u') return w.substring(0, w.length - 1);
    if (last == 'o' && !w.endsWith('oo')) return w.substring(0, w.length - 1);
    if (last == 'a') return longA ? w : w.substring(0, w.length - 1);
    return w;
  }

  // ---------- ইংরেজি হরফ থেকে বাংলা হরফ ----------

  static List<_Tok> _tokenize(String w) {
    final toks = <_Tok>[];
    final n = w.length;
    var i = 0;
    while (i < n) {
      final c = w[i];
      if (c == '#') {
        toks.add(const _Tok('ain', '', false));
        i++;
      } else if (_cons.containsKey(c) || c == 'w' || c == 'y') {
        final dbl = i + 1 < n && w[i + 1] == c;
        toks.add(_Tok('c', c, dbl));
        i += dbl ? 2 : 1;
      } else if (c == 'e') {
        toks.add(const _Tok('v', 'ee', false));
        i += (i + 1 < n && w[i + 1] == 'e') ? 2 : 1;
      } else if (c == 'o') {
        if (i + 1 < n && w[i + 1] == 'o') {
          toks.add(const _Tok('v', 'oo', false));
          i += 2;
        } else {
          toks.add(const _Tok('v', 'u', false));
          i++;
        }
      } else if (c == 'a' || c == 'i' || c == 'u') {
        toks.add(_Tok('v', c, false));
        i++;
      } else {
        toks.add(_Tok('x', c, false));
        i++;
      }
    }
    return toks;
  }

  static String _toBn(String w) {
    final toks = _tokenize(w);
    final out = StringBuffer();
    var prevCons = false;
    var prevVowel = false;
    var i = 0;
    while (i < toks.length) {
      final t = toks[i];
      final next = i + 1 < toks.length ? toks[i + 1] : null;

      if (t.type == 'c' && (t.v == 'w' || t.v == 'y')) {
        final pre = next != null && next.type == 'v';
        if (pre) {
          if (t.v == 'y') {
            final y = t.dbl ? '$_ya$_hasanta\u09AF' : _ya;
            out.write(prevVowel ? y : 'ই$y');
          } else {
            out.write(_wa);
          }
          prevCons = true;
          prevVowel = false;
        } else {
          out.write(t.v == 'y' ? 'ই' : 'ও');
          prevCons = false;
          prevVowel = true;
        }
      } else if (t.type == 'c') {
        final b = _cons[t.v] ?? '';
        if (t.dbl) {
          out.write(t.v == 'q' ? 'ক্ক্ব' : '$b$_hasanta$b');
        } else {
          out.write(b);
        }
        prevCons = true;
        prevVowel = false;
      } else if (t.type == 'v') {
        final sign = prevCons ? (_kar[t.v] ?? '') : (_ind[t.v] ?? '');
        out.write(sign);
        prevCons = false;
        prevVowel = true;
      } else if (t.type == 'ain') {
        if (next != null && next.type == 'v') {
          out.write(_ind[next.v] ?? '');
          i++;
          prevCons = false;
          prevVowel = true;
        } else {
          out.write('\u2019');
          prevCons = false;
          prevVowel = false;
        }
      } else {
        out.write(t.v);
        prevCons = false;
        prevVowel = false;
      }
      i++;
    }
    return out.toString();
  }
}

class _Tok {
  /// 'c' = ব্যঞ্জন, 'v' = স্বর, 'ain' = ع, 'x' = অন্য চিহ্ন
  final String type;
  final String v;
  final bool dbl;
  const _Tok(this.type, this.v, this.dbl);
}
