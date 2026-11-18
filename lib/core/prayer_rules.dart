/// নিষিদ্ধ সময় ও ওয়াক্ত হিসাবের নিয়ম এক জায়গায়।
/// সংখ্যা বদলাতে চাইলে শুধু এই ফাইল বদলালেই হবে।
///
/// গুরুত্বপূর্ণ: নিষিদ্ধ সময়ের মিনিট আলেমদের মধ্যে কিছুটা আলাদা।
/// প্রকাশের আগে এই সংখ্যাগুলো কোনো আলেম দিয়ে যাচাই করিয়ে নিন।
/// ওয়াক্ত গণনার পদ্ধতি (ফজর ও এশার সূর্যের কোণ)।
class CalcMethod {
  final String key;
  final String name;
  final double fajr;
  final double isha;
  const CalcMethod(this.key, this.name, this.fajr, this.isha);
}

class PrayerRules {
  PrayerRules._();

  /// সূর্যোদয় থেকে যত মিনিট নামাজ নিষিদ্ধ।
  static const int sunriseMinutes = 10;

  /// ঠিক দুপুরে সূর্য মাথার ওপর আসার (যোহর শুরুর) আগের যত মিনিট নামাজ নিষিদ্ধ।
  static const int zawalMinutes = 10;

  /// সূর্যাস্তের আগের যত মিনিট নামাজ নিষিদ্ধ।
  static const int sunsetMinutes = 10;

  /// ফজরের সময় ঠিক করার সূর্যের কোণ (ডিগ্রি)।
  static double fajrAngle = 18.0;

  /// এশার সময় ঠিক করার সূর্যের কোণ (ডিগ্রি)।
  static double ishaAngle = 18.0;

  /// সেটিংসে বাছাইযোগ্য পদ্ধতি। প্রথমটি ডিফল্ট।
  static const List<CalcMethod> methods = [
    CalcMethod('karachi', 'করাচি বিশ্ববিদ্যালয় (ফজর ১৮°, এশা ১৮°)', 18.0, 18.0),
    CalcMethod('mwl', 'মুসলিম ওয়ার্ল্ড লীগ (ফজর ১৮°, এশা ১৭°)', 18.0, 17.0),
    CalcMethod('egypt', 'মিসরীয় জরিপ কর্তৃপক্ষ (ফজর ১৯.৫°, এশা ১৭.৫°)', 19.5, 17.5),
    CalcMethod('isna', 'উত্তর আমেরিকা, ISNA (ফজর ১৫°, এশা ১৫°)', 15.0, 15.0),
  ];

  static void applyMethod(String key) {
    for (final m in methods) {
      if (m.key == key) {
        fajrAngle = m.fajr;
        ishaAngle = m.isha;
        return;
      }
    }
  }

  /// আসরের ছায়ার গুণক: ২ = হানাফি, ১ = শাফেয়ী/মালেকী/হাম্বলী।
  /// সেটিংস থেকে বদলায় (অ্যাপ চালুর সময় সংরক্ষিত মান বসে)।
  static double asrFactor = 2.0;

  /// যোহরের আজান সূর্য মাথার ওপর আসার কত মিনিট পরে বাজবে।
  static const int zuhrDelayMinutes = 2;
}
