import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_card.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CategoryList extends StatelessWidget {
  final List<CategoryData> categories;

  const CategoryList({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDims.s4,
        0,
        AppDims.s4,
        0,
      ),
      child: Column(
        children: List.generate(categories.length, (index) {
          final category = categories[index];
          final isLast = index == categories.length - 1;

          return Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : AppDims.s3,
            ),
            child: RepaintBoundary(
              child: CategoryCard(category: category)
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
            ),
          );
        }),
      ),
    );
  }
}