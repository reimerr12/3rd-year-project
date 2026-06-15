import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/lang_provider.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  int _currentTabIndex = 2;

  void _onTabTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
            context, AppRouter.home, (route) => false);
        break;
      case 1:
        Navigator.pushNamed(context, AppRouter.market);
        break;
      case 2:
        break;
      case 3:
        Navigator.pushNamed(context, AppRouter.profile);
        break;
    }
    setState(() => _currentTabIndex = index);
  }

  static const _services = [
    _ServiceItem(
      icon: Icons.smart_toy_outlined,
      labelBn: 'AI সহকারী',
      labelEn: 'AI Assistant',
      descBn: 'কৃষি প্রশ্নের উত্তর পান',
      descEn: 'Get answers to farming questions',
      route: AppRouter.aiChat,
      color: Color(0xFF6C63FF),
      bgColor: Color(0xFFF0EEFF),
    ),
    _ServiceItem(
      icon: Icons.wb_cloudy_outlined,
      labelBn: 'আবহাওয়া',
      labelEn: 'Weather',
      descBn: '৫ দিনের পূর্বাভাস',
      descEn: '5-day forecast',
      route: AppRouter.weather,
      color: Color(0xFF2196F3),
      bgColor: Color(0xFFE3F2FD),
    ),
    _ServiceItem(
      icon: Icons.agriculture_outlined,
      labelBn: 'যন্ত্রপাতি ভাড়া',
      labelEn: 'Equipment Rental',
      descBn: 'ট্র্যাক্টর, পাম্প, ট্রাক',
      descEn: 'Tractors, pumps, trucks',
      route: AppRouter.rentals,
      color: Color(0xFFFF9800),
      bgColor: Color(0xFFFFF3E0),
    ),
    _ServiceItem(
      icon: Icons.calendar_month_outlined,
      labelBn: 'ফসল ক্যালেন্ডার',
      labelEn: 'Crop Calendar',
      descBn: 'বপন ও ফসল তোলার সময়',
      descEn: 'Sowing and harvest schedule',
      route: AppRouter.calendar,
      color: Color(0xFF4CAF50),
      bgColor: Color(0xFFE8F5E9),
    ),
    _ServiceItem(
      icon: Icons.menu_book_outlined,
      labelBn: 'চাষ নির্দেশিকা',
      labelEn: 'Crop Guidelines',
      descBn: 'রোগ, পরিচর্যা ও প্রতিকার',
      descEn: 'Diseases, care & remedies',
      route: AppRouter.guidelines,
      color: Color(0xFF009688),
      bgColor: Color(0xFFE0F2F1),
    ),
    _ServiceItem(
      icon: Icons.medical_services_outlined,
      labelBn: 'কৃষি ডাক্তার',
      labelEn: 'Agri Doctors',
      descBn: 'বিশেষজ্ঞের পরামর্শ নিন',
      descEn: 'Consult a specialist',
      route: AppRouter.doctors,
      color: Color(0xFFE91E63),
      bgColor: Color(0xFFFCE4EC),
    ),
    _ServiceItem(
      icon: Icons.landscape_outlined,
      labelBn: 'মাটির গুণমান',
      labelEn: 'Soil Quality',
      descBn: 'উপযুক্ত ফসল জানুন',
      descEn: 'Find suitable crops',
      route: AppRouter.soil,
      color: Color(0xFF8BC34A),
      bgColor: Color(0xFFF1F8E9),
    ),
    _ServiceItem(
      icon: Icons.store_outlined,
      labelBn: 'বাজার',
      labelEn: 'Marketplace',
      descBn: 'পণ্য কিনুন ও বিক্রি করুন',
      descEn: 'Buy and sell products',
      route: AppRouter.market,
      color: Color(0xFFFF5722),
      bgColor: Color(0xFFFBE9E7),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(langProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          bn ? 'সেবাসমূহ' : 'Services',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.05,
        ),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          return _ServiceCard(item: _services[index], bn: bn);
        },
      ),
      bottomNavigationBar: _buildBottomNav(bn),
    );
  }

  Widget _buildBottomNav(bool bn) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: const Color(0xFF9E9E9E),
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          backgroundColor: Colors.white,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                label: bn ? 'হোম' : 'Home'),
            BottomNavigationBarItem(
                icon: const Icon(Icons.store_outlined),
                label: bn ? 'বাজার' : 'Market'),
            BottomNavigationBarItem(
                icon: const Icon(Icons.miscellaneous_services_outlined),
                label: bn ? 'সেবা' : 'Services'),
            BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                label: bn ? 'প্রোফাইল' : 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final _ServiceItem item;
  final bool bn;
  const _ServiceCard({required this.item, required this.bn});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, item.route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: item.bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bn ? item.labelBn : item.labelEn,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 3),
                Text(
                  bn ? item.descBn : item.descEn,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500, height: 1.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem {
  final IconData icon;
  final String labelBn;
  final String labelEn;
  final String descBn;
  final String descEn;
  final String route;
  final Color color;
  final Color bgColor;

  const _ServiceItem({
    required this.icon,
    required this.labelBn,
    required this.labelEn,
    required this.descBn,
    required this.descEn,
    required this.route,
    required this.color,
    required this.bgColor,
  });
}
