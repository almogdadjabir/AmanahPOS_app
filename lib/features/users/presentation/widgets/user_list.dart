import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/widgets/cashier_card.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UserList extends StatelessWidget {
  final List<UserData> users;

  const UserList({
    super.key,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        0,
        AppDims.s4,
        0,
      ),
      child: Column(
        children: List.generate(users.length, (index) {
          final user = users[index];

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == users.length - 1 ? 0 : AppDims.s3,
            ),
            child: CashierCard(user: user)
                .animate()
                .fadeIn(
              delay: Duration(milliseconds: 24 + (index % 6) * 18),
              duration: 220.ms,
            )
                .slideY(
              begin: 0.025,
              end: 0,
              duration: 220.ms,
              curve: Curves.easeOutCubic,
            ),
          );
        }),
      ),
    );
  }
}