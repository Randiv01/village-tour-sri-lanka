import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HostLanguageService {
  static final HostLanguageService _instance = HostLanguageService._internal();
  factory HostLanguageService() => _instance;

  final ValueNotifier<bool> isSinhalaNotifier = ValueNotifier<bool>(false);

  HostLanguageService._internal() {
    _loadPreference();
  }

  bool get isSinhala => isSinhalaNotifier.value;

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isSinhalaNotifier.value = prefs.getBool('host_language_sinhala') ?? false;
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    isSinhalaNotifier.value = !isSinhalaNotifier.value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('host_language_sinhala', isSinhalaNotifier.value);
    } catch (_) {}
  }

  Future<void> setLanguage({required bool sinhala}) async {
    if (isSinhalaNotifier.value == sinhala) return;
    isSinhalaNotifier.value = sinhala;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('host_language_sinhala', sinhala);
    } catch (_) {}
  }
}

class HostTranslation {
  static bool get isSi => HostLanguageService().isSinhala;

  // Header & Greetings
  static String get ayubowan => isSi ? 'ආයුබෝවන්,' : 'Ayubowan,';
  static String get goodMorning => isSi ? 'සුබ උදෑසනක්,' : 'Good morning,';
  static String get goodAfternoon => isSi ? 'සුබ දහවලක්,' : 'Good afternoon,';
  static String get goodEvening => isSi ? 'සුබ සන්ධ්‍යාවක්,' : 'Good evening,';
  static String get goodNight => isSi ? 'සුබ රාත්‍රියක්,' : 'Good night,';
  static String get homestayHost => isSi ? 'හෝම්ස්ටේ සත්කාරක' : 'Homestay Host';
  static String get superhost => isSi ? 'සුපිරි සත්කාරක' : 'Superhost';
  static String get myProfile => isSi ? 'මගේ ගිණුම' : 'My Profile';
  static String get signOut => isSi ? 'ගිණුමෙන් ඉවත් වන්න' : 'Sign Out';

  // Analytics Stat Cards
  static String get thisMonthRevenue => isSi ? 'මෙම මස ආදායම' : "This Month's Revenue";
  static String get vsLastMonth => isSi ? 'පසුගිය මසට සාපේක්ෂව' : 'vs last month';
  static String get upcomingGuests => isSi ? 'පැමිණෙන අමුත්තන්' : 'Upcoming Guests';
  static String get next7Days => isSi ? 'ඉදිරි දින 7 තුළ' : 'Next 7 days';
  static String get occupancyRate => isSi ? 'කාමර පිරී ඇති අනුපාතය' : 'Occupancy Rate';

  // Add Homestay CTA
  static String get addNewHomestay => isSi ? 'නව හෝම්ස්ටේ එකක් එක් කරන්න' : 'Add New Homestay';
  static String get listYourVillageStay => isSi ? 'සංචාරකයින් සඳහා ඔබේ නවාතැන ලියාපදිංචි කරන්න' : 'List your village stay for travelers';

  // My Homestays Section
  static String get myHomestays => isSi ? 'මගේ හෝම්ස්ටේ' : 'My Homestays';
  static String get listed => isSi ? 'ලැයිස්තුගත' : 'Listed';
  static String get manageAll => isSi ? 'සියල්ල කළමනාකරණය ' : 'Manage All ';
  static String get viewAll => isSi ? 'සියල්ල බලන්න ' : 'View All ';
  static String get noHomestaysYet => isSi ? 'තවමත් හෝම්ස්ටේ එකතු කර නැත.' : 'No homestays listed yet.';
  static String get rooms => isSi ? 'කාමර' : 'Rooms';
  static String get upTo => isSi ? 'උපරිම' : 'Up to';
  static String get guests => isSi ? 'අමුත්තන්' : 'Guests';
  static String get perNight => isSi ? '/දිනකට' : '/night';
  static String get booked => isSi ? 'වෙන් කර ඇත' : 'Booked';

  // Upcoming Bookings Section
  static String get upcomingBookings => isSi ? 'ඉදිරි වෙන්කිරීම්' : 'Upcoming Bookings';
  static String get noUpcomingBookings => isSi ? 'දැනට ඉදිරි වෙන්කිරීම් කිසිවක් නැත.' : 'No upcoming bookings at the moment.';

  // Bottom Navigation
  static String get navHome => isSi ? 'මුල් පිටුව' : 'Home';
  static String get navHomestays => isSi ? 'නවාතැන්' : 'Homestays';
  static String get navBookings => isSi ? 'වෙන්කිරීම්' : 'Bookings';
  static String get navProfile => isSi ? 'ගිණුම' : 'Profile';

  // Manage Homestays Screen
  static String get manageHomestaysTitle => isSi ? 'හෝම්ස්ටේ කළමනාකරණය' : 'Manage Homestays';
  static String get searchHomestays => isSi ? 'හෝම්ස්ටේ සොයන්න...' : 'Search homestays...';
  static String get filterAll => isSi ? 'සියල්ල' : 'All';
  static String get filterActive => isSi ? 'සක්‍රිය' : 'Active';
  static String get filterInactive => isSi ? 'අක්‍රිය' : 'Inactive';
  static String get statusActive => isSi ? 'සක්‍රියයි' : 'Active';
  static String get statusInactive => isSi ? 'අක්‍රියයි' : 'Inactive';
  static String get manageAction => isSi ? 'සකසන්න' : 'Manage';

  // Host Bookings Screen
  static String get hostBookingsTitle => isSi ? 'වෙන්කිරීම්' : 'Host Bookings';
  static String get tabPending => isSi ? 'පොරොත්තු' : 'Pending';
  static String get tabAccepted => isSi ? 'පිළිගත්' : 'Accepted';
  static String get tabConfirmed => isSi ? 'තහවුරු කළ' : 'Confirmed';
  static String get tabAll => isSi ? 'සියල්ල' : 'All';
  static String get acceptBtn => isSi ? 'පිළිගන්න' : 'Accept';
  static String get rejectBtn => isSi ? 'ප්‍රතික්ෂේප කරන්න' : 'Reject';

  // Host Profile Screen
  static String get hostProfileTitle => isSi ? 'සත්කාරක ගිණුම' : 'Host Profile';
  static String get earningsAndPayouts => isSi ? 'ඉපැයීම් සහ ගෙවීම්' : 'Earnings & Payouts';
  static String get availableBalance => isSi ? 'දැනට ඇති ශේෂය' : 'Available Balance';
  static String get cashDeliveryNote => isSi ? 'මුදල් අතින්ම ලබාදීම සක්‍රියයි. ඔබේ ඉපැයීම් ඔබේ ස්ථානයටම ලබාදෙනු ඇත.' : 'Cash Hand-Delivery Enabled. Your earnings will be delivered to your location.';
  static String get accountAndPrefs => isSi ? 'ගිණුම් තොරතුරු' : 'Account & Preferences';
  static String get personalInfo => isSi ? 'පුද්ගලික තොරතුරු' : 'Personal Information';
  static String get signOutConfirmTitle => isSi ? 'ගිණුමෙන් ඉවත් වන්නද?' : 'Sign out?';
  static String get signOutConfirmMsg => isSi ? 'ඔබට මෙම ගිණුමෙන් ඉවත් වීමට අවශ්‍ය බව ස්ථිරද?' : 'Are you sure you want to sign out of your account?';
  static String get cancel => isSi ? 'අවලංගු කරන්න' : 'Cancel';
}
