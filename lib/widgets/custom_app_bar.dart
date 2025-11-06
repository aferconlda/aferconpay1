import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool? centerTitle; 

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.centerTitle, 
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary, 
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AppBar(
        title: DefaultTextStyle(
          style: theme.textTheme.titleLarge!.copyWith(
            color: theme.colorScheme.onPrimary, 
            fontSize: 20.sp, 
            fontWeight: FontWeight.bold
          ),
          child: title,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: centerTitle ?? false, 
        actions: actions,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        bottom: bottom,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(60.h + (bottom?.preferredSize.height ?? 0.0));
}
