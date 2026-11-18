// নামাজের তথ্য। রাকাত সংখ্যা ও সূরার তালিকা হানাফি ফিকহের প্রচলিত নিয়ম
// অনুযায়ী সাজানো। প্রকাশের আগে কোনো আলেম দিয়ে যাচাই করিয়ে নিন।

const List<String> _digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

String bn(int n) => n.toString().split('').map((c) => _digits[int.parse(c)]).join();

/// মিনিট (০–১৪৩৯) থেকে বাংলা সময়, যেমন "ভোর ৫:০০"।
String formatTimeBn(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  final h12 = (h % 12 == 0) ? 12 : h % 12;
  final String period;
  if (h < 4) {
    period = 'রাত';
  } else if (h < 6) {
    period = 'ভোর';
  } else if (h < 12) {
    period = 'সকাল';
  } else if (h < 15) {
    period = 'দুপুর';
  } else if (h < 17) {
    period = 'বিকাল';
  } else if (h < 19) {
    period = 'সন্ধ্যা';
  } else {
    period = 'রাত';
  }
  return '$period ${bn(h12)}:${m < 10 ? '০' : ''}${bn(m)}';
}

class SurahSuggestion {
  final int number;
  final String name;
  const SurahSuggestion(this.number, this.name);

  String get label => '$name (সূরা নং ${bn(number)})';
}

const _infitar = SurahSuggestion(82, 'আল-ইনফিতার');
const _inshiqaq = SurahSuggestion(84, 'আল-ইনশিকাক');
const _buruj = SurahSuggestion(85, 'আল-বুরুজ');
const _ala = SurahSuggestion(87, 'আল-আ\'লা');
const _shams = SurahSuggestion(91, 'আশ-শামস');
const _layl = SurahSuggestion(92, 'আল-লাইল');
const _duha = SurahSuggestion(93, 'আদ-দুহা');
const _qariah = SurahSuggestion(101, 'আল-কারিয়া');
const _takathur = SurahSuggestion(102, 'আত-তাকাসুর');
const _humazah = SurahSuggestion(104, 'আল-হুমাযাহ');
const _fil = SurahSuggestion(105, 'আল-ফীল');
const _quraysh = SurahSuggestion(106, 'কুরাইশ');
const _maun = SurahSuggestion(107, 'আল-মাঊন');
const _kawthar = SurahSuggestion(108, 'আল-কাউসার');
const _kafirun = SurahSuggestion(109, 'আল-কাফিরুন');
const _ikhlas = SurahSuggestion(112, 'আল-ইখলাস');

class PrayerInfo {
  final String key;
  final int id;
  final String name;
  final int defaultMinutes;
  final List<String> rakats;

  /// সুন্নতের ১ম ও ২য় রাকাতের সূরা (কুরআনের ক্রম অনুযায়ী)।
  final List<SurahSuggestion> sunnahPair;

  /// ফরজের ১ম ও ২য় রাকাতের সূরা (কুরআনের ক্রম অনুযায়ী)।
  final List<SurahSuggestion> fardPair;

  /// বিতরের তিন রাকাতের সূরা (শুধু এশায়)।
  final List<SurahSuggestion> witr;

  const PrayerInfo({
    required this.key,
    required this.id,
    required this.name,
    required this.defaultMinutes,
    required this.rakats,
    required this.sunnahPair,
    required this.fardPair,
    this.witr = const [],
  });

  String get notificationTitle => '$name নামাজের সময় হয়েছে';

  String get notificationBody =>
      '${rakats.join(', ')}\nফরজে প্রস্তাবিত সূরা: ${fardPair[0].name}, ${fardPair[1].name}';
}

const List<PrayerInfo> kPrayers = [
  PrayerInfo(
    key: 'fajr',
    id: 1,
    name: 'ফজর',
    defaultMinutes: 5 * 60,
    rakats: ['২ রাকাত সুন্নত', '২ রাকাত ফরজ'],
    sunnahPair: [_kafirun, _ikhlas],
    fardPair: [_inshiqaq, _buruj],
  ),
  PrayerInfo(
    key: 'zuhr',
    id: 2,
    name: 'যোহর',
    defaultMinutes: 12 * 60 + 15,
    rakats: ['৪ রাকাত সুন্নত', '৪ রাকাত ফরজ', '২ রাকাত সুন্নত', '২ রাকাত নফল'],
    sunnahPair: [_fil, _quraysh],
    fardPair: [_infitar, _inshiqaq],
  ),
  PrayerInfo(
    key: 'asr',
    id: 3,
    name: 'আসর',
    defaultMinutes: 16 * 60,
    rakats: ['৪ রাকাত সুন্নত (গাইরে মুয়াক্কাদা)', '৪ রাকাত ফরজ'],
    sunnahPair: [_maun, _kawthar],
    fardPair: [_shams, _layl],
  ),
  PrayerInfo(
    key: 'maghrib',
    id: 4,
    name: 'মাগরিব',
    defaultMinutes: 18 * 60,
    rakats: ['৩ রাকাত ফরজ', '২ রাকাত সুন্নত', '২ রাকাত নফল'],
    sunnahPair: [_humazah, _fil],
    fardPair: [_qariah, _takathur],
  ),
  PrayerInfo(
    key: 'isha',
    id: 5,
    name: 'এশা',
    defaultMinutes: 19 * 60 + 30,
    rakats: [
      '৪ রাকাত সুন্নত (গাইরে মুয়াক্কাদা)',
      '৪ রাকাত ফরজ',
      '২ রাকাত সুন্নত',
      '২ রাকাত নফল',
      '৩ রাকাত বিতর',
    ],
    sunnahPair: [_kawthar, _kafirun],
    fardPair: [_shams, _duha],
    witr: [_ala, _kafirun, _ikhlas],
  ),
];

PrayerInfo? prayerByKey(String key) {
  for (final p in kPrayers) {
    if (p.key == key) return p;
  }
  return null;
}
