package com.cineluxe.service;

import com.cineluxe.dto.request.CreateWithdrawalRequest;
import com.cineluxe.dto.response.RefundRequestResponse;
import com.cineluxe.dto.response.WalletResponse;
import com.cineluxe.dto.response.WithdrawalRequestResponse;
import com.cineluxe.entity.Booking;
import com.cineluxe.entity.RefundRequest;
import com.cineluxe.entity.UserProfile;
import com.cineluxe.entity.WithdrawalRequest;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.BookingRepository;
import com.cineluxe.repository.RefundRequestRepository;
import com.cineluxe.repository.UserProfileRepository;
import com.cineluxe.repository.WithdrawalRequestRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class RefundAndWalletService {

    private static final Logger log = LoggerFactory.getLogger(RefundAndWalletService.class);

    private final BookingRepository bookingRepo;
    private final RefundRequestRepository refundRepo;
    private final WithdrawalRequestRepository withdrawalRepo;
    private final UserProfileRepository userProfileRepo;
    private final WalletService walletService;
    private final RefundEmailService refundEmailService;

    public RefundAndWalletService(
            BookingRepository bookingRepo,
            RefundRequestRepository refundRepo,
            WithdrawalRequestRepository withdrawalRepo,
            UserProfileRepository userProfileRepo,
            WalletService walletService,
            RefundEmailService refundEmailService) {
        this.bookingRepo = bookingRepo;
        this.refundRepo = refundRepo;
        this.withdrawalRepo = withdrawalRepo;
        this.userProfileRepo = userProfileRepo;
        this.walletService = walletService;
        this.refundEmailService = refundEmailService;
    }

    // ══════════════════════════════════════════════════════════════
    // CUSTOMER: Gửi yêu cầu hủy vé
    // ══════════════════════════════════════════════════════════════

    @Transactional
    public RefundRequestResponse requestCancel(String bookingId, String userId) {
        Booking booking = bookingRepo.findById(bookingId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking không tồn tại"));

        if (!booking.getUserId().equals(userId)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Không có quyền hủy vé này");
        }
        if (!"active".equals(booking.getStatus())) {
            throw new ApiException(HttpStatus.CONFLICT, "Chỉ có thể hủy vé đang active");
        }
        if (!booking.getShowtimeDateTime().isAfter(Instant.now())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Không thể hủy sau giờ chiếu");
        }
        if (refundRepo.existsByBookingIdAndStatus(bookingId, "PENDING")) {
            throw new ApiException(HttpStatus.CONFLICT, "Đã có yêu cầu hoàn tiền đang xử lý");
        }

        // Tính tiền hoàn dự kiến
        Instant now = Instant.now();
        long refundAmount = booking.getShowtimeDateTime().isAfter(now.plus(Duration.ofHours(2)))
                ? booking.getTotalAmount()
                : booking.getTotalAmount() / 2;

        // Đổi trạng thái booking → pendingRefund
        booking.setStatus("pendingRefund");
        bookingRepo.save(booking);

        // Tạo RefundRequest
        RefundRequest req = new RefundRequest(
                "RF-" + UUID.randomUUID(),
                bookingId, userId, refundAmount);
        refundRepo.save(req);

        return RefundRequestResponse.from(req, booking.getMovieTitle(),
                String.join(", ", booking.getSeatCodes()));
    }

    // ══════════════════════════════════════════════════════════════
    // STAFF: Xem danh sách yêu cầu hoàn tiền
    // ══════════════════════════════════════════════════════════════

    @Transactional(readOnly = true)
    public List<RefundRequestResponse> listPendingRefunds() {
        return refundRepo.findByStatusOrderByRequestedAtDesc("PENDING")
                .stream()
                .map(this::toRefundResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<RefundRequestResponse> listRefundHistoryForStaff() {
        return refundRepo.findAllByOrderByRequestedAtDesc()
                .stream()
                .sorted((left, right) -> latestRefundTime(right).compareTo(latestRefundTime(left)))
                .map(this::toRefundResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<RefundRequestResponse> listRefundHistoryForUser(String userId) {
        return refundRepo.findByUserIdOrderByRequestedAtDesc(userId)
                .stream()
                .sorted((left, right) -> latestRefundTime(right).compareTo(latestRefundTime(left)))
                .map(this::toRefundResponse)
                .collect(Collectors.toList());
    }

    private RefundRequestResponse toRefundResponse(RefundRequest r) {
        Booking b = bookingRepo.findById(r.getBookingId()).orElse(null);
        String movieTitle = b != null ? b.getMovieTitle() : "N/A";
        String seats = b != null ? String.join(", ", b.getSeatCodes()) : "";
        return RefundRequestResponse.from(r, movieTitle, seats);
    }

    private Instant latestRefundTime(RefundRequest request) {
        return request.getProcessedAt() != null
                ? request.getProcessedAt()
                : request.getRequestedAt();
    }

    // ══════════════════════════════════════════════════════════════
    // STAFF: Duyệt yêu cầu hoàn tiền
    // ══════════════════════════════════════════════════════════════

    @Transactional
    public RefundRequestResponse approveRefund(String refundRequestId, String staffId) {
        RefundRequest req = refundRepo.findById(refundRequestId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Yêu cầu hoàn tiền không tồn tại"));

        if (!"PENDING".equals(req.getStatus())) {
            throw new ApiException(HttpStatus.CONFLICT, "Yêu cầu đã được xử lý");
        }

        // Duyệt RefundRequest
        req.approve(staffId);
        refundRepo.save(req);

        // Cập nhật booking → cancelled
        Booking booking = bookingRepo.findById(req.getBookingId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking không tồn tại"));
        booking.setStatus("cancelled");
        booking.setRefundAmount(req.getRefundAmount());
        bookingRepo.save(booking);

        // Nạp tiền vào ví khách hàng
        walletService.credit(
                req.getUserId(),
                req.getRefundAmount(),
                "Hoàn tiền vé " + booking.getMovieTitle(),
                req.getBookingId()
        );

        userProfileRepo.findById(req.getUserId()).ifPresent(user ->
                afterCommit(() -> refundEmailService.sendRefundApproved(user, booking, req)));

        return RefundRequestResponse.from(req, booking.getMovieTitle(),
                String.join(", ", booking.getSeatCodes()));
    }

    // ══════════════════════════════════════════════════════════════
    // STAFF: Từ chối yêu cầu hoàn tiền
    // ══════════════════════════════════════════════════════════════

    @Transactional
    public RefundRequestResponse rejectRefund(String refundRequestId, String staffId, String reason) {
        RefundRequest req = refundRepo.findById(refundRequestId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Yêu cầu hoàn tiền không tồn tại"));

        if (!"PENDING".equals(req.getStatus())) {
            throw new ApiException(HttpStatus.CONFLICT, "Yêu cầu đã được xử lý");
        }

        req.reject(staffId, reason);
        refundRepo.save(req);

        // Khôi phục booking → active
        Booking booking = bookingRepo.findById(req.getBookingId()).orElse(null);
        if (booking != null) {
            booking.setStatus("active");
            bookingRepo.save(booking);
        }

        String movieTitle = booking != null ? booking.getMovieTitle() : "N/A";
        String seats = booking != null ? String.join(", ", booking.getSeatCodes()) : "";
        if (booking != null) {
            Booking emailBooking = booking;
            userProfileRepo.findById(req.getUserId()).ifPresent(user ->
                    afterCommit(() -> refundEmailService.sendRefundRejected(user, emailBooking, req, reason)));
        }
        return RefundRequestResponse.from(req, movieTitle, seats);
    }

    // ══════════════════════════════════════════════════════════════
    // CUSTOMER: Lấy thông tin ví
    // ══════════════════════════════════════════════════════════════

    private void afterCommit(Runnable action) {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            action.run();
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                action.run();
            }
        });
    }

    @Transactional(readOnly = true)
    public WalletResponse getWallet(String userId) {
        return walletService.getWalletInfo(userId);
    }

    // ══════════════════════════════════════════════════════════════
    // CUSTOMER: Gửi yêu cầu rút tiền
    // ══════════════════════════════════════════════════════════════

    @Transactional
    public WithdrawalRequestResponse requestWithdrawal(String userId, CreateWithdrawalRequest req) {
        if (req.amount() <= 0) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Số tiền rút phải lớn hơn 0");
        }

        WalletResponse wallet = walletService.getWalletInfo(userId);
        if (wallet.balance() < req.amount()) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Số dư ví không đủ (hiện có: " + wallet.balance() + " VND)");
        }

        // Trừ số dư ngay (lock tiền)
        walletService.debit(userId, req.amount(),
                "Yêu cầu rút tiền " + req.bankName() + " " + req.accountNumber(),
                null);

        WithdrawalRequest withdrawal = new WithdrawalRequest(
                "WD-" + UUID.randomUUID(),
                userId, req.amount(),
                req.bankName(), req.accountNumber(), req.accountHolder()
        );
        withdrawalRepo.save(withdrawal);

        return WithdrawalRequestResponse.from(withdrawal);
    }

    // ══════════════════════════════════════════════════════════════
    // STAFF: Xem danh sách yêu cầu rút tiền
    // ══════════════════════════════════════════════════════════════

    @Transactional(readOnly = true)
    public List<WithdrawalRequestResponse> listPendingWithdrawals() {
        return withdrawalRepo.findByStatusOrderByRequestedAtDesc("PENDING")
                .stream()
                .map(this::toWithdrawalResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<WithdrawalRequestResponse> listWithdrawalHistoryForStaff() {
        return withdrawalRepo.findAllByOrderByRequestedAtDesc()
                .stream()
                .sorted((left, right) -> latestWithdrawalTime(right).compareTo(latestWithdrawalTime(left)))
                .map(this::toWithdrawalResponse)
                .collect(Collectors.toList());
    }

    private WithdrawalRequestResponse toWithdrawalResponse(WithdrawalRequest w) {
        UserProfile profile = userProfileRepo.findById(w.getUserId()).orElse(null);
        String name = profile != null && profile.getFullName() != null && !profile.getFullName().isBlank()
                ? profile.getFullName()
                : w.getUserId();
        return WithdrawalRequestResponse.from(w, name);
    }

    private Instant latestWithdrawalTime(WithdrawalRequest request) {
        return request.getProcessedAt() != null
                ? request.getProcessedAt()
                : request.getRequestedAt();
    }

    // ══════════════════════════════════════════════════════════════
    // STAFF: Xác nhận đã chuyển khoản (complete withdrawal)
    // ══════════════════════════════════════════════════════════════

    @Transactional
    public WithdrawalRequestResponse completeWithdrawal(String withdrawalId, String staffId) {
        WithdrawalRequest w = withdrawalRepo.findById(withdrawalId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Yêu cầu rút tiền không tồn tại"));

        if (!"PENDING".equals(w.getStatus())) {
            throw new ApiException(HttpStatus.CONFLICT, "Yêu cầu đã được xử lý");
        }

        w.markCompleted(staffId);
        withdrawalRepo.save(w);

        UserProfile profile = userProfileRepo.findById(w.getUserId()).orElse(null);
        if (profile != null) {
            afterCommit(() -> refundEmailService.sendWithdrawalCompleted(profile, w));
        } else {
            log.warn("Cannot send withdrawal completion email because user profile was not found: {}", w.getUserId());
        }
        String name = profile != null ? profile.getFullName() : w.getUserId();
        return WithdrawalRequestResponse.from(w, name);
    }

    // ══════════════════════════════════════════════════════════════
    // STAFF: Từ chối rút tiền (hoàn lại vào ví)
    // ══════════════════════════════════════════════════════════════

    @Transactional
    public WithdrawalRequestResponse rejectWithdrawal(String withdrawalId, String staffId, String note) {
        WithdrawalRequest w = withdrawalRepo.findById(withdrawalId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Yêu cầu rút tiền không tồn tại"));

        if (!"PENDING".equals(w.getStatus())) {
            throw new ApiException(HttpStatus.CONFLICT, "Yêu cầu đã được xử lý");
        }

        w.markRejected(staffId, note);
        withdrawalRepo.save(w);

        // Hoàn tiền lại vào ví
        walletService.credit(w.getUserId(), w.getAmount(),
                "Hoàn tiền yêu cầu rút bị từ chối", withdrawalId);

        UserProfile profile = userProfileRepo.findById(w.getUserId()).orElse(null);
        if (profile != null) {
            afterCommit(() -> refundEmailService.sendWithdrawalRejected(profile, w, note));
        } else {
            log.warn("Cannot send withdrawal rejection email because user profile was not found: {}", w.getUserId());
        }
        String name = profile != null ? profile.getFullName() : w.getUserId();
        return WithdrawalRequestResponse.from(w, name);
    }
}
