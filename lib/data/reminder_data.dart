/// রিমাইন্ডারের তালিকা: দৈনিক যিকির ও কুরআন, নফল নামাজ, এবং সাপ্তাহিক (জুমআ, নফল রোযা)।
/// সব সেটিং ও নোটিফিকেশন ব্যবহারকারীর নিজের ফোনেই থাকে এবং সময় ব্যবহারকারী নিজে ঠিক করেন।
class DailyReminder {
  final String key;
  final int id;
  final String title;
  final String body;

  /// দিনের শুরু থেকে মিনিট (যেমন সকাল ৬:৩০ = ৩৯০)।
  final int defaultMinutes;

  /// null হলে প্রতিদিন; নইলে সপ্তাহের নির্দিষ্ট দিন (DateTime.monday = ১ ... DateTime.sunday = ৭)।
  final int? weekday;

  /// সেটিংসে কোন বিভাগে দেখাবে: ০ = যিকির ও তিলাওয়াত, ১ = নফল নামাজ, ২ = জুমআ ও নফল রোযা।
  final int group;

  const DailyReminder({
    required this.key,
    required this.id,
    required this.title,
    required this.body,
    required this.defaultMinutes,
    required this.group,
    this.weekday,
  });
}

const List<String> kWeekdayNamesBn = [
  '',
  'সোমবার',
  'মঙ্গলবার',
  'বুধবার',
  'বৃহস্পতিবার',
  'শুক্রবার',
  'শনিবার',
  'রবিবার',
];

const List<String> kReminderGroupTitles = [
  'যিকির ও তিলাওয়াত',
  'নফল নামাজ',
  'জুমআ ও নফল রোযা',
];

const List<DailyReminder> kDailyReminders = [
  DailyReminder(
    key: 'adhkar_morning',
    id: 4001,
    title: 'সকালের যিকির',
    body: 'সকালের যিকির ও দোয়ার সময় হয়েছে। আল্লাহর স্মরণ দিয়ে দিন শুরু করুন।',
    defaultMinutes: 6 * 60 + 30,
    group: 0,
  ),
  DailyReminder(
    key: 'adhkar_evening',
    id: 4002,
    title: 'সন্ধ্যার যিকির',
    body: 'সন্ধ্যার যিকির ও দোয়ার সময় হয়েছে। আল্লাহর স্মরণে দিন শেষ করুন।',
    defaultMinutes: 17 * 60 + 30,
    group: 0,
  ),
  DailyReminder(
    key: 'quran',
    id: 4003,
    title: 'কুরআন তিলাওয়াত',
    body: 'আজকের কুরআন তিলাওয়াতের সময় হয়েছে। অল্প হলেও নিয়মিত পড়ুন।',
    defaultMinutes: 21 * 60,
    group: 0,
  ),
  DailyReminder(
    key: 'tahajjud',
    id: 4004,
    title: 'তাহাজ্জুদ',
    body: 'আপনার সেট করা তাহাজ্জুদের সময় হয়েছে।',
    defaultMinutes: 3 * 60 + 30,
    group: 1,
  ),
  DailyReminder(
    key: 'ishraq',
    id: 4005,
    title: 'ইশরাক',
    body: 'আপনার সেট করা ইশরাকের নফল নামাজের সময় হয়েছে।',
    defaultMinutes: 6 * 60 + 45,
    group: 1,
  ),
  DailyReminder(
    key: 'chasht',
    id: 4006,
    title: 'চাশত (দুহা)',
    body: 'আপনার সেট করা চাশতের নফল নামাজের সময় হয়েছে।',
    defaultMinutes: 9 * 60,
    group: 1,
  ),
  DailyReminder(
    key: 'awwabin',
    id: 4007,
    title: 'আউওয়াবীন',
    body: 'আপনার সেট করা আউওয়াবীনের নফল নামাজের সময় হয়েছে।',
    defaultMinutes: 19 * 60,
    group: 1,
  ),
  DailyReminder(
    key: 'jumuah',
    id: 4008,
    title: 'জুমআর দিন',
    body: 'আজ জুমআ। গোসল, সূরা কাহফ তিলাওয়াত ও দরুদ পাঠের কথা মনে করুন।',
    defaultMinutes: 8 * 60,
    weekday: DateTime.friday,
    group: 2,
  ),
  DailyReminder(
    key: 'roza_mon',
    id: 4009,
    title: 'আগামীকাল সোমবার',
    body: 'আগামীকাল সোমবার। নফল রোযা রাখার নিয়ত করতে পারেন।',
    defaultMinutes: 20 * 60,
    weekday: DateTime.sunday,
    group: 2,
  ),
  DailyReminder(
    key: 'roza_thu',
    id: 4010,
    title: 'আগামীকাল বৃহস্পতিবার',
    body: 'আগামীকাল বৃহস্পতিবার। নফল রোযা রাখার নিয়ত করতে পারেন।',
    defaultMinutes: 20 * 60,
    weekday: DateTime.wednesday,
    group: 2,
  ),
];
