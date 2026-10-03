import 'package:flutter/material.dart';

import '../../../../models/destination.dart';
import '../../../../repositories/destination_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../utils/cloudinary_utils.dart';
import '../../../../widgets/cards/destination_card.dart';
import 'destination_details_screen.dart';

class ExploreDestinationsScreen extends StatefulWidget {
  const ExploreDestinationsScreen({super.key});

  @override
  State<ExploreDestinationsScreen> createState() =>
      _ExploreDestinationsScreenState();
}

class _ExploreDestinationsScreenState extends State<ExploreDestinationsScreen> {
  final DestinationRepository _repository = DestinationRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Explore Destinations'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        titleTextStyle: AppTextStyles.sectionHeading.copyWith(
          color: AppColors.primaryDark,
        ),
      ),
      body: StreamBuilder<List<Destination>>(
        stream: _repository.getActiveDestinationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Unable to load destinations.'),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final destinations = snapshot.data ?? [];

          if (destinations.isEmpty) {
            return const Center(
              child: Text(
                'No destinations available yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.85,
            ),
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final dest = destinations[index];
              String imageUrl = '';
              if (dest.images.isNotEmpty) {
                imageUrl = dest.images.first.url;
              } else if (dest.imageUrl != null) {
                imageUrl = dest.imageUrl!;
              }

              imageUrl = CloudinaryUtils.getOptimizedUrl(
                imageUrl,
                width: 400,
                height: 400,
              );

              return DestinationCard(
                title: dest.name,
                subtitle: dest.locationName,
                category: 'DESTINATION',
                imageUrl: imageUrl,
                width: double.infinity, // GridView will constrain
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DestinationDetailsScreen(destination: dest),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
