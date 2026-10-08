import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../models/homestay.dart';
import '../../../../widgets/cards/homestay_card.dart';
import '../../common/homestays/homestay_details_screen.dart';

class SavedHomestaysScreen extends StatelessWidget {
  const SavedHomestaysScreen({super.key});

  Future<List<Homestay>> _fetchSavedHomestays() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return [];

    final favorites = List<String>.from(userDoc.data()?['favorites'] ?? []);
    if (favorites.isEmpty) return [];

    // Fetch homestays in batches of 10 due to Firestore 'whereIn' limits
    List<Homestay> homestays = [];
    for (int i = 0; i < favorites.length; i += 10) {
      final batch = favorites.sublist(i, i + 10 > favorites.length ? favorites.length : i + 10);
      final snapshot = await FirebaseFirestore.instance
          .collection('homestays')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      
      homestays.addAll(snapshot.docs.map((doc) => Homestay.fromMap(doc.data(), doc.id)));
    }
    
    return homestays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Saved Homestays',
          style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
      ),
      body: FutureBuilder<List<Homestay>>(
        future: _fetchSavedHomestays(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryDark));
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load saved homestays.', style: AppTextStyles.bodyMedium));
          }
          
          final homestays = snapshot.data ?? [];
          
          if (homestays.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: AppSpacing.md),
                  Text('No saved homestays yet.', style: AppTextStyles.bodyLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Explore and tap the heart icon to save them here.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
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
      ),
    );
  }
}
