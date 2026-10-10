// ignore_for_file: avoid_print
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static const String _username = 'sliitprojects2025@gmail.com';
  static const String _appPassword = 'tvcc qrzf upzl vwkk';
  static const String _companyName = 'Village Tour Sri Lanka';
  static const String _logoUrl = 'https://res.cloudinary.com/dxsho3nak/image/upload/v1791643405/app_logo_50.png'; 

  static SmtpServer get _smtpServer => gmail(_username, _appPassword);

  static String _getHtmlTemplate(String title, String content) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
      </head>
      <body style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #f4f7f6; margin: 0; padding: 20px;">
        <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.05);">
          <!-- Header -->
          <div style="background-color: #1F4D3A; padding: 30px 20px; text-align: center;">
            <img src="$_logoUrl" alt="Logo" style="width: 60px; height: 60px; margin-bottom: 10px; filter: brightness(0) invert(1);">
            <h1 style="color: #ffffff; margin: 0; font-size: 24px; font-weight: 600; letter-spacing: 1px;">$_companyName</h1>
          </div>
          
          <!-- Body -->
          <div style="padding: 40px 30px; color: #333333; line-height: 1.6;">
            <h2 style="color: #1F4D3A; margin-top: 0; font-size: 20px;">$title</h2>
            $content
          </div>
          
          <!-- Footer -->
          <div style="background-color: #f9f9f9; padding: 20px; text-align: center; border-top: 1px solid #eeeeee;">
            <p style="margin: 0; color: #888888; font-size: 13px;">Need help? Contact our support team.</p>
            <p style="margin: 5px 0 0; color: #aaaaaa; font-size: 12px;">© ${DateTime.now().year} $_companyName. All rights reserved.</p>
            <p style="margin: 5px 0 0; color: #cccccc; font-size: 11px;">This is an automated email, please do not reply directly.</p>
          </div>
        </div>
      </body>
      </html>
    ''';
  }

  static Future<bool> _sendMail(String toEmail, String subject, String htmlContent) async {
    final message = Message()
      ..from = Address(_username, _companyName)
      ..recipients.add(toEmail)
      ..subject = subject
      ..html = htmlContent;

    try {
      await send(message, _smtpServer);
      print('Email sent successfully to $toEmail');
      return true;
    } catch (e) {
      print('Error sending email to $toEmail: $e');
      return false;
    }
  }

  // ==========================================
  // 1. TRAVELER NOTIFICATIONS
  // ==========================================
  
  static Future<void> notifyTravelerBookingRequested({
    required String toEmail,
    required String customerName,
    required String bookingId,
    required String type, // 'Homestay' or 'Tour'
  }) async {
    String content = '''
      <p>Dear <b>$customerName</b>,</p>
      <p>We have successfully received your $type booking request (ID: <b>$bookingId</b>).</p>
      <p>Your request has been forwarded to the host/guide for approval. You will receive another notification once they review your request.</p>
      <br/>
      <p>Thank you for choosing $_companyName!</p>
    ''';
    await _sendMail(toEmail, 'Booking Request Received - $bookingId', _getHtmlTemplate('Request Received', content));
  }

  static Future<void> notifyTravelerStatusUpdate({
    required String toEmail,
    required String customerName,
    required String bookingId,
    required String status,
  }) async {
    String color = status.toLowerCase() == 'accepted' ? '#2e7d32' : (status.toLowerCase() == 'rejected' ? '#d32f2f' : '#1976d2');
    String content = '''
      <p>Dear <b>$customerName</b>,</p>
      <p>The status of your booking (ID: <b>$bookingId</b>) has been updated.</p>
      <div style="background-color: #f5f5f5; border-left: 4px solid $color; padding: 15px; margin: 20px 0;">
        <p style="margin: 0; font-size: 16px;">New Status: <strong style="color: $color; text-transform: uppercase;">$status</strong></p>
      </div>
      <p>If your booking was accepted, please proceed to the app to complete your payment.</p>
    ''';
    await _sendMail(toEmail, 'Booking Status: ${status.toUpperCase()} - $bookingId', _getHtmlTemplate('Booking Update', content));
  }

  static Future<void> notifyTravelerPaymentConfirmed({
    required String toEmail,
    required String customerName,
    required String bookingId,
    required String amount,
  }) async {
    String content = '''
      <p>Dear <b>$customerName</b>,</p>
      <p>We have successfully received your payment of <b>$amount</b> for booking <b>$bookingId</b>.</p>
      <p>Your booking is now <strong style="color: #2e7d32;">FULLY CONFIRMED</strong>! 🎒✈️</p>
      <p>You can view your itinerary and host/guide details directly in the app.</p>
      <br/>
      <p>Have a wonderful trip!</p>
    ''';
    await _sendMail(toEmail, 'Payment Confirmed! - $bookingId', _getHtmlTemplate('Payment Successful', content));
  }

  // ==========================================
  // 2. HOST / GUIDE NOTIFICATIONS
  // ==========================================

  static Future<void> notifyHostNewBookingRequest({
    required String hostEmail,
    required String hostName,
    required String bookingId,
    required String travelerName,
    required String dates,
  }) async {
    String content = '''
      <p>Hello <b>$hostName</b>,</p>
      <p>Great news! You have a new booking request from <b>$travelerName</b>.</p>
      <div style="background-color: #f5f5f5; border-left: 4px solid #1F4D3A; padding: 15px; margin: 20px 0;">
        <p style="margin: 0;">Booking ID: <b>$bookingId</b></p>
        <p style="margin: 5px 0 0;">Dates: <b>$dates</b></p>
      </div>
      <p>Please open the app to review and <b>Accept</b> or <b>Reject</b> this request as soon as possible.</p>
    ''';
    await _sendMail(hostEmail, 'Action Required: New Booking Request!', _getHtmlTemplate('New Booking Request', content));
  }

  static Future<void> notifyHostBookingCancelled({
    required String hostEmail,
    required String hostName,
    required String bookingId,
    required String travelerName,
  }) async {
    String content = '''
      <p>Hello <b>$hostName</b>,</p>
      <p>We wanted to inform you that <b>$travelerName</b> has <strong style="color: #d32f2f;">CANCELLED</strong> their booking request.</p>
      <div style="background-color: #f5f5f5; border-left: 4px solid #d32f2f; padding: 15px; margin: 20px 0;">
        <p style="margin: 0;">Booking ID: <b>$bookingId</b></p>
        <p style="margin: 5px 0 0;">Status: <b>CANCELLED</b></p>
      </div>
      <p>No further action is required from you.</p>
    ''';
    await _sendMail(hostEmail, 'Booking Cancelled - $bookingId', _getHtmlTemplate('Booking Cancelled', content));
  }

  static Future<void> notifyHostPaymentReceived({
    required String hostEmail,
    required String hostName,
    required String bookingId,
    required String amount,
  }) async {
    String content = '''
      <p>Hello <b>$hostName</b>,</p>
      <p>The traveler has successfully completed the payment of <b>$amount</b> for booking <b>$bookingId</b>.</p>
      <p>This booking is now officially <strong style="color: #2e7d32;">CONFIRMED</strong>.</p>
      <p>Please prepare for your upcoming guests!</p>
    ''';
    await _sendMail(hostEmail, 'Booking Confirmed (Paid) - $bookingId', _getHtmlTemplate('Payment Received', content));
  }
}
