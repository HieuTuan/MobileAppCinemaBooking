import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('vi'),
  ];

  /// App title
  ///
  /// In vi, this message translates to:
  /// **'CineLuxe Booking'**
  String get appTitle;

  /// Label for movies section
  ///
  /// In vi, this message translates to:
  /// **'Phim'**
  String get moviesLabel;

  /// Label for showtimes section
  ///
  /// In vi, this message translates to:
  /// **'Suất chiếu'**
  String get showtimesLabel;

  /// Movie status: now showing
  ///
  /// In vi, this message translates to:
  /// **'Đang chiếu'**
  String get nowShowing;

  /// Movie status: coming soon
  ///
  /// In vi, this message translates to:
  /// **'Sắp chiếu'**
  String get comingSoon;

  /// All filter option
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get allLabel;

  /// Book ticket button label
  ///
  /// In vi, this message translates to:
  /// **'Đặt vé'**
  String get bookingLabel;

  /// Buy ticket label
  ///
  /// In vi, this message translates to:
  /// **'Mua vé'**
  String get buyTicketLabel;

  /// No showtimes available
  ///
  /// In vi, this message translates to:
  /// **'Chưa có suất chiếu'**
  String get noShowtimesLabel;

  /// Seat label
  ///
  /// In vi, this message translates to:
  /// **'Ghế'**
  String get seatLabel;

  /// Standard seat type
  ///
  /// In vi, this message translates to:
  /// **'Ghế thường'**
  String get standardSeat;

  /// VIP seat type
  ///
  /// In vi, this message translates to:
  /// **'Ghế VIP'**
  String get vipSeat;

  /// Couple seat type
  ///
  /// In vi, this message translates to:
  /// **'Ghế đôi'**
  String get coupleSeat;

  /// Total price label
  ///
  /// In vi, this message translates to:
  /// **'Tổng cộng'**
  String get totalLabel;

  /// Confirm booking label
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận đặt vé'**
  String get confirmBookingLabel;

  /// Cancel button
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancelLabel;

  /// Save button
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get saveLabel;

  /// Edit button
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get editLabel;

  /// Delete button
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get deleteLabel;

  /// Add button
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get addLabel;

  /// Search placeholder text
  ///
  /// In vi, this message translates to:
  /// **'Tìm phim, thể loại, diễn viên...'**
  String get searchHint;

  /// Profile section label
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get profileLabel;

  /// Logout button
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get logoutLabel;

  /// Login button
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get loginLabel;

  /// Register button
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get registerLabel;

  /// Email field label
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Password field label
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get passwordLabel;

  /// Full name field label
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên'**
  String get fullNameLabel;

  /// Phone field label
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get phoneLabel;

  /// Birthdate field label
  ///
  /// In vi, this message translates to:
  /// **'Ngày sinh'**
  String get birthdateLabel;

  /// Payment label
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán'**
  String get paymentLabel;

  /// Payment success message
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thành công'**
  String get paymentSuccessLabel;

  /// Payment failed message
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thất bại'**
  String get paymentFailedLabel;

  /// My tickets label
  ///
  /// In vi, this message translates to:
  /// **'Vé của tôi'**
  String get ticketsLabel;

  /// Active booking status
  ///
  /// In vi, this message translates to:
  /// **'Sắp chiếu'**
  String get activeTicketLabel;

  /// Used booking status
  ///
  /// In vi, this message translates to:
  /// **'Đã xem'**
  String get usedTicketLabel;

  /// Cancelled booking status
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get cancelledTicketLabel;

  /// Refunded booking status
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tiền'**
  String get refundedTicketLabel;

  /// Admin label
  ///
  /// In vi, this message translates to:
  /// **'Quản trị'**
  String get adminLabel;

  /// Staff label
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên'**
  String get staffLabel;

  /// Customer label
  ///
  /// In vi, this message translates to:
  /// **'Khách hàng'**
  String get customerLabel;

  /// Room ready status
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng'**
  String get readyLabel;

  /// Room maintenance status
  ///
  /// In vi, this message translates to:
  /// **'Bảo trì'**
  String get maintenanceLabel;

  /// Review label
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá'**
  String get reviewLabel;

  /// Write review hint text
  ///
  /// In vi, this message translates to:
  /// **'Bạn nghĩ gì về bộ phim này?'**
  String get writeReviewHint;

  /// Send button
  ///
  /// In vi, this message translates to:
  /// **'Gửi'**
  String get sendLabel;

  /// Settings label
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsLabel;

  /// Language setting label
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get languageLabel;

  /// Vietnamese language option
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get vietnameseLabel;

  /// English language option
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get englishLabel;

  /// Offline cache banner message
  ///
  /// In vi, this message translates to:
  /// **'Đang hiển thị kết quả đã lưu'**
  String get offlineBannerText;

  /// No network connection message
  ///
  /// In vi, this message translates to:
  /// **'Không có kết nối mạng'**
  String get noNetworkLabel;

  /// Retry button
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retryLabel;

  /// Generic error message
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi'**
  String get errorOccurred;

  /// Scan QR code label
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR'**
  String get scanQrLabel;

  /// Ticket validation success
  ///
  /// In vi, this message translates to:
  /// **'Vé hợp lệ'**
  String get validationSuccessLabel;

  /// Ticket validation failed
  ///
  /// In vi, this message translates to:
  /// **'Vé không hợp lệ'**
  String get validationFailedLabel;

  /// Food combo label
  ///
  /// In vi, this message translates to:
  /// **'Combo đồ ăn'**
  String get comboLabel;

  /// Revenue label
  ///
  /// In vi, this message translates to:
  /// **'Doanh thu'**
  String get revenueLabel;

  /// Bookings count label
  ///
  /// In vi, this message translates to:
  /// **'Lượt đặt vé'**
  String get bookingsCountLabel;

  /// Upload image button label
  ///
  /// In vi, this message translates to:
  /// **'Tải ảnh lên'**
  String get uploadImageLabel;

  /// Privacy policy label
  ///
  /// In vi, this message translates to:
  /// **'Chính sách bảo mật'**
  String get privacyPolicyLabel;

  /// Accept button
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý'**
  String get acceptLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
