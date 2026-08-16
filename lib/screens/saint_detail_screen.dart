import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SaintDetailScreen extends StatelessWidget {
  const SaintDetailScreen({super.key, required this.saintName});

  final String saintName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saint of the Day')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              color: AppColors.navy,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: AppColors.gold,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      saintName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
