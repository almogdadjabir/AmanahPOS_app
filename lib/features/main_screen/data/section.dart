import 'package:flutter/material.dart';

class Section {
  final String title;
  final List<SectionItem> items;
  const Section(this.title, this.items);
}

class SectionItem {
  final String id;
  final String name;
  final String desc;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback? onTap;
  const SectionItem(
      this.id, this.name, this.desc, this.icon, this.color, {
        this.active = false, this.onTap,
      });
}