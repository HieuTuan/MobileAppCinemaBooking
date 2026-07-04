package com.cineluxe.service;

import com.cineluxe.entity.Booking;
import com.cineluxe.entity.RefundRequest;
import com.cineluxe.entity.UserProfile;
import com.cineluxe.entity.WithdrawalRequest;
import jakarta.mail.MessagingException;
import java.text.NumberFormat;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
public class RefundEmailService {

    private static final Logger log = LoggerFactory.getLogger(RefundEmailService.class);
    private static final ZoneId VIETNAM_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final DateTimeFormatter DATE_TIME_FORMATTER =
            DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm", Locale.forLanguageTag("vi-VN"))
                    .withZone(VIETNAM_ZONE);
    private final Optional<JavaMailSender> mailSender;
    private final String mailFrom;
    private final String smtpHost;

    public RefundEmailService(
            Optional<JavaMailSender> mailSender,
            @Value("${spring.mail.username:${SPRING_MAIL_USERNAME:}}") String mailFrom,
            @Value("${spring.mail.host:${SPRING_MAIL_HOST:}}") String smtpHost) {
        this.mailSender = mailSender;
        this.mailFrom = mailFrom;
        this.smtpHost = smtpHost;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void logMailConfiguration() {
        log.info(
                "Mail configuration: host={}, from={}, senderBeanAvailable={}",
                smtpHost == null || smtpHost.isBlank() ? "<empty>" : smtpHost,
                mailFrom == null || mailFrom.isBlank() ? "<empty>" : mailFrom,
                mailSender.isPresent());
    }

    @Async
    public void sendRefundApproved(UserProfile user, Booking booking, RefundRequest refund) {
        if (!canSend(user)) return;

        var subject = "CineLuxe - Hoàn tiền thành công";
        var html = layout(
                "Hoàn tiền thành công",
                "Yêu cầu hoàn tiền của bạn đã được duyệt. Số tiền hoàn đã được cộng vào ví CineLuxe.",
                "approved",
                """
                <tr><td>Mã đặt vé</td><td>%s</td></tr>
                <tr><td>Phim</td><td>%s</td></tr>
                <tr><td>Ghế</td><td>%s</td></tr>
                <tr><td>Suất chiếu</td><td>%s</td></tr>
                <tr><td>Số tiền hoàn</td><td class="amount">%s</td></tr>
                <tr><td>Trạng thái</td><td><span class="badge approved">Đã hoàn tiền</span></td></tr>
                """.formatted(
                        escape(booking.getId()),
                        escape(booking.getMovieTitle()),
                        escape(String.join(", ", booking.getSeatCodes())),
                        escape(DATE_TIME_FORMATTER.format(booking.getShowtimeDateTime())),
                        escape(formatMoney(refund.getRefundAmount()))),
                """
                <p class="note success">
                  Bạn có thể kiểm tra số dư mới trong mục Ví của tôi. Cảm ơn bạn đã sử dụng CineLuxe.
                </p>
                """);

        send(user.getEmail(), subject, html);
    }

    @Async
    public void sendRefundRejected(
            UserProfile user,
            Booking booking,
            RefundRequest refund,
            String reason) {
        if (!canSend(user)) return;

        var safeReason = reason == null || reason.isBlank()
                ? "Yêu cầu chưa đáp ứng điều kiện hoàn tiền. Vui lòng kiểm tra lại thông tin và gửi yêu cầu mới."
                : reason.trim();

        var subject = "CineLuxe - Yêu cầu hoàn tiền chưa được duyệt";
        var html = layout(
                "Yêu cầu hoàn tiền chưa được duyệt",
                "Yêu cầu hoàn tiền của bạn chưa được chấp nhận. Vui lòng thao tác lại theo đúng lý do bên dưới nếu bạn vẫn muốn gửi yêu cầu.",
                "rejected",
                """
                <tr><td>Mã đặt vé</td><td>%s</td></tr>
                <tr><td>Phim</td><td>%s</td></tr>
                <tr><td>Ghế</td><td>%s</td></tr>
                <tr><td>Suất chiếu</td><td>%s</td></tr>
                <tr><td>Số tiền yêu cầu hoàn</td><td class="amount">%s</td></tr>
                <tr><td>Trạng thái</td><td><span class="badge rejected">Chưa hoàn tiền</span></td></tr>
                """.formatted(
                        escape(booking.getId()),
                        escape(booking.getMovieTitle()),
                        escape(String.join(", ", booking.getSeatCodes())),
                        escape(DATE_TIME_FORMATTER.format(booking.getShowtimeDateTime())),
                        escape(formatMoney(refund.getRefundAmount()))),
                """
                <div class="reason">
                  <div class="reason-title">Lý do từ chối</div>
                  <div>%s</div>
                </div>
                <p class="note warning">
                  Vui lòng thao tác lại yêu cầu hoàn tiền và bổ sung/điều chỉnh thông tin theo đúng lý do trên.
                </p>
                """.formatted(escape(safeReason)));

        send(user.getEmail(), subject, html);
    }

    @Async
    public void sendWithdrawalCompleted(UserProfile user, WithdrawalRequest withdrawal) {
        if (!canSend(user)) return;

        var subject = "CineLuxe - Rút tiền thành công";
        var html = layout(
                "Rút tiền thành công",
                "Yêu cầu rút tiền của bạn đã được staff xác nhận chuyển khoản thành công.",
                "approved",
                """
                <tr><td>Mã yêu cầu</td><td>%s</td></tr>
                <tr><td>Ngân hàng</td><td>%s</td></tr>
                <tr><td>Số tài khoản</td><td>%s</td></tr>
                <tr><td>Chủ tài khoản</td><td>%s</td></tr>
                <tr><td>Số tiền đã chuyển</td><td class="amount">%s</td></tr>
                <tr><td>Trạng thái</td><td><span class="badge approved">Đã chuyển khoản</span></td></tr>
                """.formatted(
                        escape(withdrawal.getId()),
                        escape(withdrawal.getBankName()),
                        escape(withdrawal.getAccountNumber()),
                        escape(withdrawal.getAccountHolder()),
                        escape(formatMoney(withdrawal.getAmount()))),
                """
                <p class="note success">
                  Vui lòng kiểm tra tài khoản ngân hàng nhận tiền. Nếu chưa nhận được tiền sau thời gian xử lý của ngân hàng,
                  hãy liên hệ CineLuxe để được hỗ trợ.
                </p>
                """);

        send(user.getEmail(), subject, html);
    }

    @Async
    public void sendWithdrawalRejected(UserProfile user, WithdrawalRequest withdrawal, String note) {
        if (!canSend(user)) return;

        var safeNote = note == null || note.isBlank()
                ? "Thong tin rut tien chua hop le. Vui long kiem tra lai ngan hang, so tai khoan va ten chu tai khoan roi gui yeu cau moi."
                : note.trim();
        var subject = "CineLuxe - Yeu cau rut tien chua duoc duyet";
        var html = layout(
                "Yeu cau rut tien chua duoc duyet",
                "Yeu cau rut tien cua ban chua duoc chap nhan. So tien da duoc hoan lai vao vi CineLuxe. Vui long thao tac lai theo ly do ben duoi.",
                "rejected",
                """
                <tr><td>Ma yeu cau</td><td>%s</td></tr>
                <tr><td>Ngan hang</td><td>%s</td></tr>
                <tr><td>So tai khoan</td><td>%s</td></tr>
                <tr><td>Chu tai khoan</td><td>%s</td></tr>
                <tr><td>So tien da hoan vao vi</td><td class="amount">%s</td></tr>
                <tr><td>Trang thai</td><td><span class="badge rejected">Da tu choi</span></td></tr>
                """.formatted(
                        escape(withdrawal.getId()),
                        escape(withdrawal.getBankName()),
                        escape(withdrawal.getAccountNumber()),
                        escape(withdrawal.getAccountHolder()),
                        escape(formatMoney(withdrawal.getAmount()))),
                """
                <div class="reason">
                  <div class="reason-title">Ly do tu choi</div>
                  <div>%s</div>
                </div>
                <p class="note warning">
                  Vui long gui lai yeu cau rut tien voi thong tin chinh xac theo ly do tren.
                </p>
                """.formatted(escape(safeNote)));

        send(user.getEmail(), subject, html);
    }

    private boolean canSend(UserProfile user) {
        if (user == null || user.getEmail() == null || user.getEmail().isBlank()) {
            log.warn("Skip refund email because customer email is missing");
            return false;
        }
        if (mailSender.isEmpty() || smtpHost == null || smtpHost.isBlank()) {
            log.warn("SMTP is not configured. Skip refund email for {}", user.getEmail());
            return false;
        }
        return true;
    }

    private void send(String to, String subject, String html) {
        try {
            log.info("Sending email '{}' to {}", subject, to);
            var message = mailSender.get().createMimeMessage();
            var helper = new MimeMessageHelper(message, "UTF-8");
            helper.setFrom(mailFrom == null || mailFrom.isBlank()
                    ? "no-reply@cineluxe.local"
                    : mailFrom);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(stripHtml(html), html);
            mailSender.get().send(message);
            log.info("Email '{}' sent to {}", subject, to);
        } catch (MailException | MessagingException e) {
            log.warn(
                    "Could not send email '{}' to {}: {} - {}",
                    subject,
                    to,
                    e.getClass().getSimpleName(),
                    e.getMessage());
        }
    }

    private String layout(
            String title,
            String lead,
            String tone,
            String rows,
            String footerContent) {
        return """
                <!doctype html>
                <html lang="vi">
                <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <style>
                    body {
                      margin: 0;
                      padding: 0;
                      background: #f4f5f8;
                      color: #141822;
                      font-family: Arial, Helvetica, sans-serif;
                    }
                    .wrap {
                      max-width: 640px;
                      margin: 0 auto;
                      padding: 28px 16px;
                    }
                    .card {
                      overflow: hidden;
                      background: #ffffff;
                      border: 1px solid #e7eaf1;
                      border-radius: 18px;
                      box-shadow: 0 16px 40px rgba(20, 24, 34, .08);
                    }
                    .hero {
                      padding: 30px 28px;
                      color: #ffffff;
                      background: %s;
                    }
                    .brand {
                      margin-bottom: 18px;
                      font-size: 13px;
                      font-weight: 800;
                      letter-spacing: .08em;
                      text-transform: uppercase;
                    }
                    h1 {
                      margin: 0 0 10px;
                      font-size: 26px;
                      line-height: 1.2;
                    }
                    .lead {
                      margin: 0;
                      font-size: 15px;
                      line-height: 1.6;
                      opacity: .95;
                    }
                    .content {
                      padding: 26px 28px 30px;
                    }
                    table {
                      width: 100%%;
                      border-collapse: collapse;
                      margin: 0 0 22px;
                      background: #fbfbf8;
                      border: 1px solid #e7eaf1;
                      border-radius: 12px;
                      overflow: hidden;
                    }
                    td {
                      padding: 13px 14px;
                      border-bottom: 1px solid #e7eaf1;
                      font-size: 14px;
                      vertical-align: top;
                    }
                    tr:last-child td {
                      border-bottom: 0;
                    }
                    td:first-child {
                      width: 38%%;
                      color: #71788a;
                      font-weight: 700;
                    }
                    td:last-child {
                      color: #141822;
                      font-weight: 800;
                    }
                    .amount {
                      color: #1b9e66 !important;
                      font-size: 16px;
                    }
                    .badge {
                      display: inline-block;
                      padding: 6px 10px;
                      border-radius: 999px;
                      font-size: 12px;
                      font-weight: 900;
                    }
                    .badge.approved {
                      color: #0f7b4b;
                      background: #e8f7ef;
                    }
                    .badge.rejected {
                      color: #b42318;
                      background: #fff0ed;
                    }
                    .reason {
                      margin: 0 0 18px;
                      padding: 14px 16px;
                      border-left: 4px solid #d04747;
                      border-radius: 12px;
                      background: #fff7f6;
                      color: #6b1717;
                      font-size: 14px;
                      line-height: 1.55;
                    }
                    .reason-title {
                      margin-bottom: 6px;
                      color: #b42318;
                      font-weight: 900;
                    }
                    .note {
                      margin: 0;
                      padding: 14px 16px;
                      border-radius: 12px;
                      font-size: 14px;
                      line-height: 1.55;
                    }
                    .note.success {
                      color: #0f7b4b;
                      background: #e8f7ef;
                    }
                    .note.warning {
                      color: #7a4a00;
                      background: #fff6df;
                    }
                    .footer {
                      padding: 18px 28px 26px;
                      color: #71788a;
                      font-size: 12px;
                      line-height: 1.5;
                      background: #fbfbf8;
                    }
                  </style>
                </head>
                <body>
                  <div class="wrap">
                    <div class="card">
                      <div class="hero">
                        <div class="brand">CineLuxe</div>
                        <h1>%s</h1>
                        <p class="lead">%s</p>
                      </div>
                      <div class="content">
                        <table>%s</table>
                        %s
                      </div>
                      <div class="footer">
                        Email này được gửi tự động từ hệ thống CineLuxe. Vui lòng không trả lời trực tiếp email này.
                      </div>
                    </div>
                  </div>
                </body>
                </html>
                """.formatted(
                "approved".equals(tone)
                        ? "linear-gradient(135deg, #141822 0%, #1b9e66 100%)"
                        : "linear-gradient(135deg, #141822 0%, #d04747 100%)",
                escape(title),
                escape(lead),
                rows,
                footerContent);
    }

    private String stripHtml(String html) {
        return html.replaceAll("<[^>]*>", " ")
                .replaceAll("\\s+", " ")
                .trim();
    }

    private String formatMoney(long amount) {
        return NumberFormat.getCurrencyInstance(Locale.forLanguageTag("vi-VN"))
                .format(amount);
    }

    private String escape(String value) {
        if (value == null) return "";
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
}
