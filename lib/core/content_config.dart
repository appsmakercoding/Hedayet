/// কুরআন ও হাদিসের ডেটা কোথা থেকে আসবে তার সব ঠিকানা এক জায়গায়।
/// উৎস বদলাতে চাইলে শুধু এই ফাইল বদলালেই হবে।
class ContentConfig {
  static const String quranBase = 'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions';
  static const String hadithBase = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';

  /// আরবি টেক্সট: প্রথমটি না মিললে পরেরটি চেষ্টা হবে।
  static const List<String> arabicQuranEditions = ['ara-quranacademy', 'ara-quransimple'];
  static const String banglaQuranEdition = 'ben-muhiuddinkhan';

  /// কুরআনের ইংরেজি হরফের উচ্চারণ (Tanzil)। প্রথমটি না মিললে পরেরটি চেষ্টা হবে।
  /// অ্যাপ এটিকে বাংলা হরফে রূপান্তর করে (lib/core/bangla_translit.dart)।
  static const List<String> translitUrls = [
    'https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist/quran_transliteration.json',
    'https://unpkg.com/quran-json@3.1.2/dist/quran_transliteration.json',
  ];

  static const String arabicHadithEdition = 'ara-bukhari';
  static const String banglaHadithEdition = 'ben-bukhari';

  /// পূর্ণ সূরার অডিও (মিশারি আল-আফাসি), অনলাইনে চলে।
  static String audioUrl(int surah) => 'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/$surah.mp3';

  static const String quranCredit =
      'আরবি টেক্সট ও বাংলা অনুবাদ (মুহিউদ্দীন খান): tanzil.net ও fawazahmed0/quran-api। '
      'বাংলা উচ্চারণ: tanzil.net-এর ইংরেজি উচ্চারণ থেকে স্বয়ংক্রিয়ভাবে রূপান্তরিত (আনুমানিক, সঠিক তিলাওয়াতের জন্য আরবি ও অডিও অনুসরণ করুন)। '
      'তিলাওয়াত: মিশারি আল-আফাসি, cdn.islamic.network।';
  static const String hadithCredit = 'হাদিস: fawazahmed0/hadith-api (সহীহ বুখারী)।';
}
