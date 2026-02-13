import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_qu.dart';
import 'app_localizations_sw.dart';
import 'app_localizations_yo.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('pt'),
    Locale('qu'),
    Locale('sw'),
    Locale('yo'),
    Locale('zh'),
  ];

  /// No description provided for @matches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matches;

  /// No description provided for @leagues.
  ///
  /// In en, this message translates to:
  /// **'Leagues'**
  String get leagues;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @teams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teams;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock the World of Premium'**
  String get premiumTitle;

  /// No description provided for @premiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Elevate your football experience,\nBecome a VIP Member Today.'**
  String get premiumSubtitle;

  /// No description provided for @enjoyingApp.
  ///
  /// In en, this message translates to:
  /// **'Enjoying the App?'**
  String get enjoyingApp;

  /// No description provided for @rateUsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap a star to rate us on the Store!'**
  String get rateUsPrompt;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @testScheduledNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Scheduled Notification (10s)'**
  String get testScheduledNotification;

  /// No description provided for @notificationScheduled.
  ///
  /// In en, this message translates to:
  /// **'Notification scheduled for 10 seconds...'**
  String get notificationScheduled;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @topLeagues.
  ///
  /// In en, this message translates to:
  /// **'Top Leagues'**
  String get topLeagues;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @allLeagues.
  ///
  /// In en, this message translates to:
  /// **'All Leagues'**
  String get allLeagues;

  /// No description provided for @searchLeagues.
  ///
  /// In en, this message translates to:
  /// **'Search leagues...'**
  String get searchLeagues;

  /// No description provided for @noFavoriteLeagues.
  ///
  /// In en, this message translates to:
  /// **'No favorited leagues yet'**
  String get noFavoriteLeagues;

  /// No description provided for @starLeaguePrompt.
  ///
  /// In en, this message translates to:
  /// **'Star a league to see it here'**
  String get starLeaguePrompt;

  /// No description provided for @loadingMoreLeagues.
  ///
  /// In en, this message translates to:
  /// **'Loading more leagues'**
  String get loadingMoreLeagues;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found for this date'**
  String get noMatchesFound;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @away.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get away;

  /// No description provided for @notificationsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Notifications removed'**
  String get notificationsRemoved;

  /// No description provided for @noLiveMatches.
  ///
  /// In en, this message translates to:
  /// **'No live matches at the moment'**
  String get noLiveMatches;

  /// No description provided for @liveMatches.
  ///
  /// In en, this message translates to:
  /// **'Live Matches'**
  String get liveMatches;

  /// No description provided for @refreshingLiveMatches.
  ///
  /// In en, this message translates to:
  /// **'Refreshing live matches...'**
  String get refreshingLiveMatches;

  /// No description provided for @allTeams.
  ///
  /// In en, this message translates to:
  /// **'All Teams'**
  String get allTeams;

  /// No description provided for @loadingMoreTeams.
  ///
  /// In en, this message translates to:
  /// **'Loading more teams'**
  String get loadingMoreTeams;

  /// No description provided for @noFavoriteTeams.
  ///
  /// In en, this message translates to:
  /// **'No favorited teams yet'**
  String get noFavoriteTeams;

  /// No description provided for @starTeamPrompt.
  ///
  /// In en, this message translates to:
  /// **'Star a team to see it here'**
  String get starTeamPrompt;

  /// No description provided for @searchTeams.
  ///
  /// In en, this message translates to:
  /// **'Search teams...'**
  String get searchTeams;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @notify.
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get notify;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @fixtures.
  ///
  /// In en, this message translates to:
  /// **'Fixtures'**
  String get fixtures;

  /// No description provided for @squad.
  ///
  /// In en, this message translates to:
  /// **'Squad'**
  String get squad;

  /// No description provided for @selectCompetition.
  ///
  /// In en, this message translates to:
  /// **'Select Competition'**
  String get selectCompetition;

  /// No description provided for @statsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Stats not found for this season'**
  String get statsNotFound;

  /// No description provided for @competition.
  ///
  /// In en, this message translates to:
  /// **'Competition'**
  String get competition;

  /// No description provided for @stat.
  ///
  /// In en, this message translates to:
  /// **'Stat'**
  String get stat;

  /// No description provided for @noFixturesFound.
  ///
  /// In en, this message translates to:
  /// **'No fixtures found for selected period'**
  String get noFixturesFound;

  /// No description provided for @liveLabel.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveLabel;

  /// No description provided for @ft.
  ///
  /// In en, this message translates to:
  /// **'FT'**
  String get ft;

  /// No description provided for @jersey.
  ///
  /// In en, this message translates to:
  /// **'Jersey'**
  String get jersey;

  /// No description provided for @squadListUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Squad list upcoming'**
  String get squadListUpcoming;

  /// No description provided for @infoTab.
  ///
  /// In en, this message translates to:
  /// **'INFO'**
  String get infoTab;

  /// No description provided for @h2hTab.
  ///
  /// In en, this message translates to:
  /// **'H2H'**
  String get h2hTab;

  /// No description provided for @statsTab.
  ///
  /// In en, this message translates to:
  /// **'STATS'**
  String get statsTab;

  /// No description provided for @tableTab.
  ///
  /// In en, this message translates to:
  /// **'TABLE'**
  String get tableTab;

  /// No description provided for @commentsTab.
  ///
  /// In en, this message translates to:
  /// **'COMMENTS'**
  String get commentsTab;

  /// No description provided for @matchInformation.
  ///
  /// In en, this message translates to:
  /// **'Match Information'**
  String get matchInformation;

  /// No description provided for @kickOff.
  ///
  /// In en, this message translates to:
  /// **'Kick off'**
  String get kickOff;

  /// No description provided for @halfTimeResult.
  ///
  /// In en, this message translates to:
  /// **'Half Time Result'**
  String get halfTimeResult;

  /// No description provided for @venue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get venue;

  /// No description provided for @predictions.
  ///
  /// In en, this message translates to:
  /// **'Predictions'**
  String get predictions;

  /// No description provided for @noPredictionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No prediction available for this match'**
  String get noPredictionsAvailable;

  /// No description provided for @winProbability.
  ///
  /// In en, this message translates to:
  /// **'Win Probability'**
  String get winProbability;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @matchTimeline.
  ///
  /// In en, this message translates to:
  /// **'Match Timeline'**
  String get matchTimeline;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @ownGoal.
  ///
  /// In en, this message translates to:
  /// **'Own Goal'**
  String get ownGoal;

  /// No description provided for @penaltyGoal.
  ///
  /// In en, this message translates to:
  /// **'Penalty Goal'**
  String get penaltyGoal;

  /// No description provided for @yellowCard.
  ///
  /// In en, this message translates to:
  /// **'Yellowcard'**
  String get yellowCard;

  /// No description provided for @redCard.
  ///
  /// In en, this message translates to:
  /// **'Redcard'**
  String get redCard;

  /// No description provided for @substitution.
  ///
  /// In en, this message translates to:
  /// **'Substitution'**
  String get substitution;

  /// No description provided for @ht.
  ///
  /// In en, this message translates to:
  /// **'HT'**
  String get ht;

  /// No description provided for @pressureIndex.
  ///
  /// In en, this message translates to:
  /// **'Pressure Index'**
  String get pressureIndex;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @noTeamsFound.
  ///
  /// In en, this message translates to:
  /// **'No teams found'**
  String get noTeamsFound;

  /// No description provided for @searchFavoriteTeamsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search for your favorite teams'**
  String get searchFavoriteTeamsPrompt;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @problemFacingPrompt.
  ///
  /// In en, this message translates to:
  /// **'What type of problem are you facing?'**
  String get problemFacingPrompt;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @shareThoughtsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts'**
  String get shareThoughtsPrompt;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @selectProblemTypePrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select a problem type'**
  String get selectProblemTypePrompt;

  /// No description provided for @feedbackSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Feedback submitted successfully!'**
  String get feedbackSubmitted;

  /// No description provided for @goPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremium;

  /// No description provided for @getAccessTo.
  ///
  /// In en, this message translates to:
  /// **'Get Access to'**
  String get getAccessTo;

  /// No description provided for @exploreBenefits.
  ///
  /// In en, this message translates to:
  /// **'Explore Benefits'**
  String get exploreBenefits;

  /// No description provided for @coveringLeagues.
  ///
  /// In en, this message translates to:
  /// **'Covering 2100+ leagues'**
  String get coveringLeagues;

  /// No description provided for @adsFreeVersion.
  ///
  /// In en, this message translates to:
  /// **'Ads Free Version'**
  String get adsFreeVersion;

  /// No description provided for @customMatchNotifications.
  ///
  /// In en, this message translates to:
  /// **'Custom Match Notifications'**
  String get customMatchNotifications;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @priceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Rs 1,400/week'**
  String get priceWeekly;

  /// No description provided for @priceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Rs 4,200/month'**
  String get priceMonthly;

  /// No description provided for @purchasePremium.
  ///
  /// In en, this message translates to:
  /// **'Purchase Premium'**
  String get purchasePremium;

  /// No description provided for @cancelAnyTime.
  ///
  /// In en, this message translates to:
  /// **'Cancel any time'**
  String get cancelAnyTime;

  /// No description provided for @unknownPlayer.
  ///
  /// In en, this message translates to:
  /// **'Unknown Player'**
  String get unknownPlayer;

  /// No description provided for @na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get years;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @club.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get club;

  /// No description provided for @shirt.
  ///
  /// In en, this message translates to:
  /// **'Shirt'**
  String get shirt;

  /// No description provided for @preferFoot.
  ///
  /// In en, this message translates to:
  /// **'Prefer Foot'**
  String get preferFoot;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @nationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationality;

  /// No description provided for @matchHighlights.
  ///
  /// In en, this message translates to:
  /// **'Match Highlights'**
  String get matchHighlights;

  /// No description provided for @highlightsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Highlights Coming Soon'**
  String get highlightsComingSoon;

  /// No description provided for @shorts.
  ///
  /// In en, this message translates to:
  /// **'Shorts'**
  String get shorts;

  /// No description provided for @shortsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Shorts Coming Soon'**
  String get shortsComingSoon;

  /// No description provided for @comingSoonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exclusive content is on the way!'**
  String get comingSoonSubtitle;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @scheduledShort.
  ///
  /// In en, this message translates to:
  /// **'Sch'**
  String get scheduledShort;

  /// No description provided for @notStartedShort.
  ///
  /// In en, this message translates to:
  /// **'NS'**
  String get notStartedShort;

  /// No description provided for @played.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get played;

  /// No description provided for @win.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get win;

  /// No description provided for @loss.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get loss;

  /// No description provided for @gd.
  ///
  /// In en, this message translates to:
  /// **'GD'**
  String get gd;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Pts'**
  String get points;

  /// No description provided for @pts.
  ///
  /// In en, this message translates to:
  /// **'Pts'**
  String get pts;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @unlockPremium.
  ///
  /// In en, this message translates to:
  /// **'Unlock Premium Access'**
  String get unlockPremium;

  /// No description provided for @adFreeExperience.
  ///
  /// In en, this message translates to:
  /// **'Ad-Free Experience'**
  String get adFreeExperience;

  /// No description provided for @unlimitedAlerts.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Match Alerts'**
  String get unlimitedAlerts;

  /// No description provided for @detailedStats.
  ///
  /// In en, this message translates to:
  /// **'Advanced Prediction Stats'**
  String get detailedStats;

  /// No description provided for @hdContent.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Full HD Content'**
  String get hdContent;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'MOST POPULAR'**
  String get mostPopular;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'SUBSCRIBE NOW'**
  String get subscribeNow;

  /// No description provided for @restorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get restorePurchase;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @describeProblem.
  ///
  /// In en, this message translates to:
  /// **'Describe your problem'**
  String get describeProblem;

  /// No description provided for @describeProblemHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us more about the issue...'**
  String get describeProblemHint;

  /// No description provided for @pleaseSelectProblemType.
  ///
  /// In en, this message translates to:
  /// **'Please select a problem type'**
  String get pleaseSelectProblemType;

  /// No description provided for @pleaseDescribeProblem.
  ///
  /// In en, this message translates to:
  /// **'Please describe the problem'**
  String get pleaseDescribeProblem;

  /// No description provided for @feedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent successfully!'**
  String get feedbackSent;

  /// No description provided for @problemTypes.
  ///
  /// In en, this message translates to:
  /// **'Problem types'**
  String get problemTypes;

  /// No description provided for @appCrash.
  ///
  /// In en, this message translates to:
  /// **'App Crash'**
  String get appCrash;

  /// No description provided for @slowPerformance.
  ///
  /// In en, this message translates to:
  /// **'Slow Performance'**
  String get slowPerformance;

  /// No description provided for @incorrectData.
  ///
  /// In en, this message translates to:
  /// **'Incorrect Data'**
  String get incorrectData;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'am',
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'pt',
    'qu',
    'sw',
    'yo',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'qu':
      return AppLocalizationsQu();
    case 'sw':
      return AppLocalizationsSw();
    case 'yo':
      return AppLocalizationsYo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
