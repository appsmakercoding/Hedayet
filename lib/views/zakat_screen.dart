import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/prayer_data.dart' show bn;

/// বাংলা বা ইংরেজি অঙ্ক থেকে সংখ্যা বের করে (কমা বাদ দেয়)।
double _num(String s) {
  const bnDigits = '০১২৩৪৫৬৭৮৯';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = bnDigits.indexOf(ch);
    if (i >= 0) {
      b.write(i);
    } else if (ch != ',' && ch != ' ') {
      b.write(ch);
    }
  }
  return double.tryParse(b.toString()) ?? 0;
}

/// টাকার অঙ্ক বাংলায়, ৩ অঙ্ক পরপর কমা দিয়ে।
String _fmt(double v) {
  final s = (v < 0 ? 0 : v).round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final left = s.length - i;
    b.write(bn(int.parse(s[i])));
    if (left > 1 && left % 3 == 1) b.write(',');
  }
  return '৳ ${b.toString()}';
}

/// যাকাত ও ফিতরার হিসাব। দাম ও পরিমাণ ব্যবহারকারী নিজে বসান।
class ZakatScreen extends StatelessWidget {
  const ZakatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('যাকাত ও ফিতরা', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'যাকাত'), Tab(text: 'ফিতরা')],
          ),
        ),
        body: const TabBarView(children: [_ZakatTab(), _FitraTab()]),
      ),
    );
  }
}

class _ZakatTab extends StatefulWidget {
  const _ZakatTab();

  @override
  State<_ZakatTab> createState() => _ZakatTabState();
}

class _ZakatTabState extends State<_ZakatTab> {
  static const double _silverNisabGrams = 612.36; // ৫২.৫ তোলা
  static const double _goldNisabGrams = 87.48; // ৭.৫ তোলা

  final _cash = TextEditingController();
  final _goldG = TextEditingController();
  final _goldP = TextEditingController();
  final _silverG = TextEditingController();
  final _silverP = TextEditingController();
  final _stock = TextEditingController();
  final _receivable = TextEditingController();
  final _debt = TextEditingController();
  bool _silverBase = true;

  @override
  void dispose() {
    for (final c in [_cash, _goldG, _goldP, _silverG, _silverP, _stock, _receivable, _debt]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(String label, TextEditingController c, {String? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _line(String a, String b, {bool bold = false}) {
    final style = TextStyle(fontSize: 14.5, fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(a, style: style)),
          Text(b, style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cash = _num(_cash.text);
    final goldValue = _num(_goldG.text) * _num(_goldP.text);
    final silverValue = _num(_silverG.text) * _num(_silverP.text);
    final stock = _num(_stock.text);
    final receivable = _num(_receivable.text);
    final debt = _num(_debt.text);

    final assets = cash + goldValue + silverValue + stock + receivable;
    final net = assets - debt;
    final nisabPrice = _silverBase ? _num(_silverP.text) : _num(_goldP.text);
    final nisab = (_silverBase ? _silverNisabGrams : _goldNisabGrams) * nisabPrice;
    final hasNisab = nisab > 0;
    final eligible = hasNisab && net >= nisab;
    final zakat = eligible ? net * 0.025 : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('নিসাব কিসের ভিত্তিতে ধরবেন', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('রুপা (৬১২.৩৬ গ্রাম)'),
              selected: _silverBase,
              onSelected: (_) => setState(() => _silverBase = true),
            ),
            ChoiceChip(
              label: const Text('সোনা (৮৭.৪৮ গ্রাম)'),
              selected: !_silverBase,
              onSelected: (_) => setState(() => _silverBase = false),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _field('নগদ টাকা ও ব্যাংকে জমা', _cash, suffix: '৳'),
        Row(
          children: [
            Expanded(child: _field('সোনা', _goldG, suffix: 'গ্রাম')),
            const SizedBox(width: 10),
            Expanded(child: _field('সোনার দাম (প্রতি গ্রাম)', _goldP, suffix: '৳')),
          ],
        ),
        Row(
          children: [
            Expanded(child: _field('রুপা', _silverG, suffix: 'গ্রাম')),
            const SizedBox(width: 10),
            Expanded(child: _field('রুপার দাম (প্রতি গ্রাম)', _silverP, suffix: '৳')),
          ],
        ),
        _field('ব্যবসার পণ্যের বর্তমান মূল্য', _stock, suffix: '৳'),
        _field('পাওনা (যা ফেরত পাওয়ার আশা আছে)', _receivable, suffix: '৳'),
        _field('দেনা ও ঋণ (বাদ যাবে)', _debt, suffix: '৳'),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line('মোট সম্পদ', _fmt(assets)),
                _line('দেনা বাদে নিট সম্পদ', _fmt(net)),
                _line('নিসাবের মূল্য', hasNisab ? _fmt(nisab) : 'দাম দিন'),
                const Divider(height: 18),
                if (!hasNisab)
                  const Text(
                    'নিসাব হিসাবের জন্য ওপরে নির্বাচিত ধাতুর (রুপা বা সোনা) প্রতি গ্রামের দাম দিন।',
                    style: TextStyle(color: AppColors.subtle, fontSize: 13),
                  )
                else if (!eligible)
                  const Text(
                    'নিট সম্পদ নিসাবের কম, তাই এই হিসাবে যাকাত ফরজ নয়।',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                else
                  _line('যাকাতের পরিমাণ (২.৫%)', _fmt(zakat), bold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'যাকাত ফরজ হতে নিসাব পরিমাণ সম্পদ প্রয়োজনের অতিরিক্ত অবস্থায় পূর্ণ এক চান্দ্র বছর থাকতে হয়। এটি সাধারণ হিসাবের সহায়তা মাত্র, নির্দিষ্ট ক্ষেত্রে বিশ্বস্ত আলেমের পরামর্শ নিন।',
          style: TextStyle(fontSize: 11.5, color: AppColors.subtle, height: 1.5),
        ),
      ],
    );
  }
}

class _FitraTab extends StatefulWidget {
  const _FitraTab();

  @override
  State<_FitraTab> createState() => _FitraTabState();
}

class _FitraTabState extends State<_FitraTab> {
  final _persons = TextEditingController(text: '1');
  final _rate = TextEditingController();

  @override
  void dispose() {
    _persons.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final persons = _num(_persons.text);
    final rate = _num(_rate.text);
    final total = persons * rate;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _persons,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'কত জনের পক্ষ থেকে',
            suffixText: 'জন',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _rate,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'জনপ্রতি ফিতরার পরিমাণ',
            suffixText: '৳',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(child: Text('মোট ফিতরা', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                Text(_fmt(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accent)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'ফিতরার পরিমাণ প্রতি বছর ইসলামিক ফাউন্ডেশনসহ বিভিন্ন প্রতিষ্ঠান খাদ্যদ্রব্যের মূল্য অনুযায়ী ঘোষণা করে। ঘোষিত পরিমাণ জেনে জনপ্রতি অঙ্কটি নিজে বসান।',
          style: TextStyle(fontSize: 11.5, color: AppColors.subtle, height: 1.5),
        ),
      ],
    );
  }
}
