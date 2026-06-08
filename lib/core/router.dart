import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/marketplace/market_screen.dart';
import '../screens/marketplace/product_detail.dart';
import '../screens/marketplace/cart_screen.dart';
import '../screens/marketplace/orders_screen.dart';
import '../screens/marketplace/sell_product_screen.dart';
import '../screens/marketplace/payment_screen.dart';
import '../screens/marketplace/order_confirmation_screen.dart';
import '../screens/ai_assistant/chat_screen.dart';
import '../screens/rentals/rentals_screen.dart';
import '../screens/rentals/booking_screen.dart';
import '../screens/weather/weather_screen.dart';
import '../screens/guidelines/guidelines_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/soil/soil_screen.dart';
import '../screens/doctors/doctors_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/servicegrid/services_screen.dart';

class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String home = '/home';
  static const String market = '/market';
  static const String productDetail = '/product-detail';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String sellProduct = '/sell-product';
  static const String payment = '/payment';
  static const String orderConfirmation = '/order-confirmation';
  static const String aiChat = '/ai-chat';
  static const String rentals = '/rentals';
  static const String booking = '/booking';
  static const String weather = '/weather';
  static const String nearby = '/nearby';
  static const String guidelines = '/guidelines';
  static const String calendar = '/calendar';
  static const String soil = '/soil';
  static const String doctors = '/doctors';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String services = '/services';

  static Map<String, WidgetBuilder> get routes => {
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        otp: (_) => const OtpScreen(),
        home: (_) => const HomeScreen(),
        market: (_) => const MarketScreen(),
        productDetail: (_) => const ProductDetailScreen(),
        cart: (_) => const CartScreen(),
        orders: (_) => const OrdersScreen(),
        sellProduct: (_) => const SellProductScreen(),
        payment: (_) => const PaymentScreen(),
        orderConfirmation: (_) => const OrderConfirmationScreen(),
        aiChat: (_) => const ChatScreen(),
        rentals: (_) => const RentalsScreen(),
        booking: (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as EquipmentModel;
          return BookingScreen(equipment: args);
        },
        weather: (_) => const WeatherScreen(),
        guidelines: (_) => const GuidelinesScreen(),
        calendar: (_) => const CalendarScreen(),
        soil: (_) => const SoilScreen(),
        doctors: (_) => const DoctorsScreen(),
        profile: (_) => const ProfileScreen(),
        notifications: (_) => const NotificationsScreen(),
        services: (_) => const ServicesScreen(),
      };
}
