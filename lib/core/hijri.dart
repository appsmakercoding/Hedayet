/// হিজরি তারিখ ও ইসলামি দিবস (ট্যাবুলার/হিসাবভিত্তিক)।
/// চাঁদ দেখার ওপর নির্ভর করায় আসল তারিখ বাংলাদেশে ১–২ দিন আলাদা হতে পারে;
/// সেটিংসে তারিখ আগে-পরে করার সুযোগ আছে।
class HijriDate {
  final int year;
  final int month;
  final int day;
  const HijriDate(this.year, this.month, this.day);
}

class IslamicEvent {
  final int month;
  final int day;
  final String name;
  final String note;
  const IslamicEvent(this.month, this.day, this.name, [this.note = '']);
}

class Hijri {
  Hijri._();

  static const List<String> monthNames = [
    'মুহাররম',
    'সফর',
    'রবিউল আউয়াল',
    'রবিউস সানি',
    'জমাদিউল আউয়াল',
    'জমাদিউস সানি',
    'রজব',
    'শা\'বান',
    'রমযান',
    'শাওয়াল',
    'যিলকদ',
    'যিলহজ্জ',
  ];

  /// শুধু সর্বসম্মত ও প্রচলিত দিনগুলো। চাঁদ দেখার সঙ্গে মিলিয়ে নিন।
  static const List<IslamicEvent> events = [
    IslamicEvent(1, 1, 'হিজরি নববর্ষ'),
    IslamicEvent(1, 10, 'আশুরা (১০ মুহাররম)'),
    IslamicEvent(9, 1, 'রমযানের শুরু'),
    IslamicEvent(9, 27, 'লাইলাতুল কদর (প্রচলিত ২৭শের রাত)', 'শেষ দশকের বেজোড় রাতগুলোতেও খোঁজা হয়'),
    IslamicEvent(10, 1, 'ঈদুল ফিতর'),
    IslamicEvent(12, 9, 'আরাফার দিন'),
    IslamicEvent(12, 10, 'ঈদুল আযহা'),
  ];

  static int _jdFromGregorian(int y, int m, int d) {
    final a = (m - 14) ~/ 12;
    return (1461 * (y + 4800 + a)) ~/ 4 +
        (367 * (m - 2 - 12 * a)) ~/ 12 -
        (3 * ((y + 4900 + a) ~/ 100)) ~/ 4 +
        d -
        32075;
  }

  /// [adjust] দিন যোগ করে হিজরি তারিখ বের করে।
  static HijriDate fromGregorian(DateTime date, {int adjust = 0}) {
    final d = DateTime(date.year, date.month, date.day + adjust);
    final jd = _jdFromGregorian(d.year, d.month, d.day);
    var l = jd - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) + (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) - (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
    final month = (24 * l) ~/ 709;
    final day = l - (709 * month) ~/ 24;
    final year = 30 * n + j - 30;
    return HijriDate(year, month, day);
  }

  /// হিজরি তারিখ থেকে ইংরেজি তারিখ। [adjust] ধরলে দেখানো তারিখের সঙ্গে মেলে।
  static DateTime toGregorian(int hy, int hm, int hd, {int adjust = 0}) {
    final jd = (11 * hy + 3) ~/ 30 + 354 * hy + 30 * hm - (hm - 1) ~/ 2 + hd + 1948440 - 385;
    var l = jd + 68569;
    final n = (4 * l) ~/ 146097;
    l = l - (146097 * n + 3) ~/ 4;
    final i = (4000 * (l + 1)) ~/ 1461001;
    l = l - (1461 * i) ~/ 4 + 31;
    final j = (80 * l) ~/ 2447;
    final day = l - (2447 * j) ~/ 80;
    l = j ~/ 11;
    final month = j + 2 - 12 * l;
    final year = 100 * (n - 49) + i + l;
    return DateTime(year, month, day - adjust);
  }

  /// [from] তারিখ বা তার পরের ইসলামি দিবসগুলো, সময়ক্রমে।
  static List<MapEntry<DateTime, IslamicEvent>> upcoming(DateTime from, {int adjust = 0, int count = 8}) {
    final today = DateTime(from.year, from.month, from.day);
    final hy = fromGregorian(today, adjust: adjust).year;
    final list = <MapEntry<DateTime, IslamicEvent>>[];
    for (var y = hy; y <= hy + 1; y++) {
      for (final e in events) {
        final g = toGregorian(y, e.month, e.day, adjust: adjust);
        if (!g.isBefore(today)) list.add(MapEntry(g, e));
      }
    }
    list.sort((a, b) => a.key.compareTo(b.key));
    return list.length > count ? list.sublist(0, count) : list;
  }

  static String monthName(int m) => monthNames[(m - 1).clamp(0, 11)];
}

const List<String> kGregorianMonthsBn = [
  'জানুয়ারি',
  'ফেব্রুয়ারি',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্টেম্বর',
  'অক্টোবর',
  'নভেম্বর',
  'ডিসেম্বর',
];

/// DateTime.weekday (সোম = ১ ... রবি = ৭) অনুযায়ী বার।
const List<String> kWeekdaysBn = [
  'সোমবার',
  'মঙ্গলবার',
  'বুধবার',
  'বৃহস্পতিবার',
  'শুক্রবার',
  'শনিবার',
  'রবিবার',
];
