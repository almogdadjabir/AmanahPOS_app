import 'package:amana_pos/features/business/presentation/business_screen.dart';
import 'package:amana_pos/features/dashboard/presentation/dashboard_screen.dart';
import 'package:amana_pos/features/main_screen/data/navigation_model.dart';

class NavigationConfig {
  static final List<NavigationModel> screens = [
    NavigationModel(
      child: const DashboardScreen(),
    ),
    NavigationModel(
      child: const BusinessScreen(),
    ),
    NavigationModel(
      child: const BusinessScreen(),
    ),
    NavigationModel(
      child: const BusinessScreen(),
    ),

  ];
}
