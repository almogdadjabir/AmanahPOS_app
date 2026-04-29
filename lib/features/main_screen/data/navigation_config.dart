import 'package:amana_pos/features/business/presentation/business_screen.dart';
import 'package:amana_pos/features/category/presentation/category_screen.dart';
import 'package:amana_pos/features/dashboard/presentation/dashboard_screen.dart';
import 'package:amana_pos/features/main_screen/data/navigation_model.dart';
import 'package:amana_pos/features/users/presentation/users_screen.dart';

class NavigationConfig {
  static final List<NavigationModel> screens = [
    NavigationModel(
      child: const DashboardScreen(),
    ),
    NavigationModel(
      child: const BusinessScreen(),
    ),
    NavigationModel(
      child: const UsersScreen(),
    ),
    NavigationModel(
      child: const CategoriesScreen(),
    ),

  ];
}
