// নামাজ শিক্ষা বিভাগের ভিডিও ও PDF-এর তালিকা।
//
// নতুন ভিডিও যোগ করতে kVideos-এ একটি LearningVideo বসান:
//   - নির্দিষ্ট ভিডিও/চ্যানেল/প্লেলিস্ট হলে link: 'https://m.youtube.com/...' দিন।
//   - link না দিলে query দিয়ে ইউটিউবে খোঁজা হবে (ফলাফল ইউটিউবই ঠিক করে)।
// নতুন PDF যোগ করতে kPdfs-এ একটি LearningPdf বসান (সরাসরি .pdf ফাইলের https লিংক)।
//
// গুরুত্বপূর্ণ: শিক্ষামূলক ভিডিও/PDF প্রকাশের আগে বিশ্বস্ত আলেম বা প্রতিষ্ঠানের
// কনটেন্ট কিনা যাচাই করে নিন।

const String kYoutubeHome = 'https://m.youtube.com';

class LearningVideo {
  /// যে অংশের নিচে দেখাবে (একই নামের ভিডিও একসঙ্গে থাকে)।
  final String group;
  final String title;
  final String subtitle;

  /// সরাসরি ভিডিও/চ্যানেল/প্লেলিস্টের লিংক। খালি থাকলে [query] দিয়ে খোঁজা হয়।
  final String link;
  final String query;

  const LearningVideo({
    this.group = '',
    required this.title,
    required this.subtitle,
    this.link = '',
    this.query = '',
  });

  String get url {
    if (link.isNotEmpty) return link;
    return 'https://m.youtube.com/results?search_query=${Uri.encodeQueryComponent(query)}';
  }
}

class LearningPdf {
  final String title;
  final String subtitle;

  /// সরাসরি PDF ফাইলের লিংক, অথবা বইয়ের ওয়েবপাতার লিংক ([isPage] = true হলে)।
  final String url;

  /// true হলে [url] একটি ওয়েবপাতা (যেমন Internet Archive-এর বইয়ের পাতা), সরাসরি খোলা হয়।
  /// false হলে [url] সরাসরি .pdf ফাইল, Google-এর ভিউয়ারে দেখানো হয়।
  final bool isPage;

  const LearningPdf({
    required this.title,
    required this.subtitle,
    required this.url,
    this.isPage = false,
  });

  /// অ্যাপের ভেতরে যে ঠিকানাটি খোলা হবে।
  String get openUrl {
    if (isPage) return url;
    return 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(url)}';
  }
}

const List<LearningVideo> kVideos = [
  // ---- শায়খ আহমাদুল্লাহ ----
  LearningVideo(
    group: 'শায়খ আহমাদুল্লাহর নামাজ শিক্ষা',
    title: 'নামাজ পড়ার সঠিক নিয়ম (প্র্যাকটিক্যাল)',
    subtitle: 'শায়খ আহমাদুল্লাহ • Quranic Life',
    link: 'https://m.youtube.com/watch?v=FJe03w1cbkI',
  ),
  LearningVideo(
    group: 'শায়খ আহমাদুল্লাহর নামাজ শিক্ষা',
    title: 'নামাজ পড়ার সঠিক নিয়ম ও দোয়া',
    subtitle: 'শায়খ আহমাদুল্লাহ • Daily Muslim TV BD',
    link: 'https://m.youtube.com/watch?v=n-oOlkZE7Yw',
  ),
  LearningVideo(
    group: 'শায়খ আহমাদুল্লাহর নামাজ শিক্ষা',
    title: 'মহিলা ও পুরুষের নামাজের পার্থক্য',
    subtitle: 'শায়খ আহমাদুল্লাহ • Abrar Islamic Centre',
    link: 'https://m.youtube.com/watch?v=U3lNpWeI1N8',
  ),

  // ---- নামাজ নিয়ে ওয়াজ ----
  LearningVideo(
    group: 'নামাজ নিয়ে ওয়াজ',
    title: 'নামাজ ও সুদ বিষয়ক লেকচার',
    subtitle: 'আবু ত্বহা মুহাম্মাদ আদনান • Taw Haa TV',
    link: 'https://m.youtube.com/watch?v=G5S42G3zOa8',
  ),
  LearningVideo(
    group: 'নামাজ নিয়ে ওয়াজ',
    title: 'নামাজের গুরুত্ব নিয়ে ওয়াজ',
    subtitle: 'আবু ত্বহা মুহাম্মাদ আদনান • Taw Haa TV',
    link: 'https://m.youtube.com/watch?v=NipPwgdB6h0',
  ),

  // ---- আরও নামাজ শিক্ষা ----
  LearningVideo(
    group: 'আরও নামাজ শিক্ষা',
    title: 'নামাজ শিখুন সঠিক পদ্ধতিতে',
    subtitle: 'মুফতী আল-আমিন সাইফি • কুরআনের ছোঁয়া',
    link: 'https://m.youtube.com/watch?v=6vWFISIDjp8',
  ),
  LearningVideo(
    group: 'আরও নামাজ শিক্ষা',
    title: 'হানাফি মাযহাবের নামাজের নিয়ম',
    subtitle: 'মুফতী আরিফ বিন হাবিব • Al-Barakah Online',
    link: 'https://m.youtube.com/watch?v=HBqJq6C39a0',
  ),
  LearningVideo(
    group: 'আরও নামাজ শিক্ষা',
    title: 'মহিলাদের নামাজের নিয়ম (চিত্রসহ, হানাফী মাযহাব)',
    subtitle: 'Taleem for Sisters',
    link: 'https://m.youtube.com/watch?v=dgQeGTKs2Bc',
  ),
];

const List<LearningPdf> kPdfs = [
  LearningPdf(
    title: 'সহীহ নামায ও দোয়া শিক্ষা (১ম খণ্ড)',
    subtitle: 'আল্লামা মুহাম্মাদ আবদুল্লাহ ইবনে ফযল • Internet Archive',
    url: 'https://archive.org/details/20201031_20201031_1848',
    isPage: true,
  ),
  LearningPdf(
    title: 'নামাজ সংক্রান্ত বিভিন্ন বই ও দোয়ার সংগ্রহ',
    subtitle: 'Internet Archive',
    url: 'https://archive.org/details/SalatSonkrantoBooks',
    isPage: true,
  ),
  LearningPdf(
    title: 'এসো নামায শিখি',
    subtitle: 'মুফতী আবদুল মান্নান • boimate.com',
    url: 'https://boimate.com/esho-namaj-shikhi-pdf',
    isPage: true,
  ),
  LearningPdf(
    title: 'সহীহ হাদীসের আলোকে: হানাফীদের নামায',
    subtitle: 'মুফতি তারেকুজ্জামান • boimate.com',
    url: 'https://boimate.com/sohih-hadiser-aloke-hanafider-namaz-pdf',
    isPage: true,
  ),
];
