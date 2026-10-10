import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../models/homestay.dart';
import '../../../../models/destination.dart';
import '../../../../widgets/cards/homestay_card.dart';
import '../../../../widgets/cards/destination_card.dart';
import '../../common/homestays/homestay_details_screen.dart';
import '../destinations/destination_details_screen.dart';

class SavedItemsScreen extends StatelessWidget {
  const SavedItemsScreen({super.key});

  Future<List<Homestay>> _fetchSavedHomestays() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!userDoc.exists) return [];

    final favorites = List<String>.from(userDoc.data()?['favorites'] ?? []);
    if (favorites.isEmpty) return [];

    // Fetch homestays in batches of 10 due to Firestore 'whereIn' limits
    List<Homestay> homestays = [];
    for (int i = 0; i < favorites.length; i += 10) {
      final batch = favorites.sublist(
        i,
        i + 10 > favorites.length ? favorites.length : i + 10,
      );
      final snapshot = await FirebaseFirestore.instance
          .collection('homestays')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      homestays.addAll(
        snapshot.docs.map((doc) => Homestay.fromMap(doc.data(), doc.id)),
      );
    }

    return homestays;
  }

  Future<List<Destination>> _fetchSavedDestinations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!userDoc.exists) return [];

    final favorites = List<String>.from(
      userDoc.data()?['favoriteDestinations'] ?? [],
    );
    if (favorites.isEmpty) return [];

    // Fetch destinations in batches of 10
    List<Destination> destinations = [];
    for (int i = 0; i < favorites.length; i += 10) {
      final batch = favorites.sublist(
        i,
        i + 10 > favorites.length ? favorites.length : i + 10,
      );
      final snapshot = await FirebaseFirestore.instance
          .collection('destinations')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      destinations.addAll(
        snapshot.docs.map((doc) => Destination.fromMap(doc.data(), doc.id)),
      );
    }

    return destinations;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Saved Favorites',
            style: AppTextStyles.screenHeading.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.primaryDark),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Homestays'),
              Tab(text: 'Destinations'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildHomestaysTab(), _buildDestinationsTab()],
        ),
      ),
    );
  }

  Widget _buildHomestaysTab() {
    return FutureBuilder<List<Homestay>>(
      future: _fetchSavedHomestays(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryDark),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load saved homestays.',
              style: AppTextStyles.bodyMedium,
            ),
          );
        }

        final homestays = snapshot.data ?? [];

        if (homestays.isEmpty) {
          return _buildEmptyState('No saved homestays yet.');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: homestays.length,
          itemBuilder: (context, index) {
            final hs = homestays[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: HomestayCard(
                homestay: hs,
                onViewDetailsTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomestayDetailsScreen(homestayId: hs.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDestinationsTab() {
    return FutureBuilder<List<Destination>>(
      future: _fetchSavedDestinations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryDark),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load saved destinations.',
              style: AppTextStyles.bodyMedium,
            ),
          );
        }

        final destinations = snapshot.data ?? [];

        if (destinations.isEmpty) {
          return _buildEmptyState('No saved destinations yet.');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: destinations.length,
          itemBuilder: (context, index) {
            final dest = destinations[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: SizedBox(
                height: 220,
                child: DestinationCard(
                  title: dest.name,
                  subtitle: dest.locationName,
                  category: '',
                  imageUrl: dest.images.isNotEmpty
                      ? dest.images.first.url
                      : (dest.imageUrl ?? ''),
                  margin: EdgeInsets.zero,
                  width: double.infinity,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DestinationDetailsScreen(destination: dest),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTextStyles.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Explore and tap the heart icon to save them here.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
