import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/marketplace/market_screen.dart';
import '../screens/marketplace/product_detail.dart';
import '../screens/marketplace/cart_screen.dart';
import '../screens/marketplace/orders_screen.dart';
import '../screens/marketplace/sell_product_screen.dart';
import '../screens/ai_assistant/chat_screen.dart';
import '../screens/rentals/rentals_screen.dart';
import '../screens/rentals/booking_screen.dart';
import '../screens/weather/weather_screen.dart';
import '../screens/map/nearby_screen.dart';
import '../screens/guidelines/guidelines_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/soil/soil_screen.dart';
import '../screens/doctors/doctors_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String market = '/market';
  static const String productDetail = '/product-detail';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String sellProduct = '/sell-product';
  static const String aiChat = '/ai-chat';
  static const String rentals = '/rentals';
  static const String booking = '/booking';
  static const String weather = '/weather';
  static const String nearby = '/nearby';
  static const String guidelines = '/guidelines';
  static const String calendar = '/calendar';
  static const String soil = '/soil';
  static const String doctors = '/doctors';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        otp: (_) => const OtpScreen(),
        home: (_) => const HomeScreen(),
        dashboard: (_) => const DashboardScreen(),
        market: (_) => const MarketScreen(),
        productDetail: (_) => const ProductDetailScreen(),
        cart: (_) => const CartScreen(),
        orders: (_) => const OrdersScreen(),
        sellProduct: (_) => const SellProductScreen(),
        aiChat: (_) => const ChatScreen(),
        rentals: (_) => const RentalsScreen(),
        booking: (_) => const BookingScreen(),
        weather: (_) => const WeatherScreen(),
        nearby: (_) => const NearbyScreen(),
        guidelines: (_) => const GuidelinesScreen(),
        calendar: (_) => const CalendarScreen(),
        soil: (_) => const SoilScreen(),
        doctors: (_) => const DoctorsScreen(),
        settings: (_) => const SettingsScreen(),
      };
}
