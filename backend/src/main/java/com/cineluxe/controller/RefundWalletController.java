package com.cineluxe.controller;

import com.cineluxe.dto.request.CreateWithdrawalRequest;
import com.cineluxe.dto.request.ProcessRefundRequest;
import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.RefundRequestResponse;
import com.cineluxe.dto.response.WalletResponse;
import com.cineluxe.dto.response.WithdrawalRequestResponse;
import com.cineluxe.service.RefundAndWalletService;
import static com.cineluxe.dto.response.ApiResponse.created;
import static com.cineluxe.dto.response.ApiResponse.success;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Tất cả các API liên quan đến hoàn tiền, ví điện tử và rút tiền.
 *
 * Customer endpoints:
 *   POST   /api/bookings/{id}/request-cancel          — gửi yêu cầu hủy
 *   GET    /api/users/{userId}/wallet                  — lấy số dư + lịch sử
 *   POST   /api/users/{userId}/wallet/withdraw         — yêu cầu rút tiền
 *   GET    /api/users/{userId}/refund-requests         — danh sách yêu cầu của mình
 *
 * Staff endpoints:
 *   GET    /api/staff/refund-requests                  — danh sách chờ duyệt
 *   POST   /api/staff/refund-requests/{id}/approve     — duyệt
 *   POST   /api/staff/refund-requests/{id}/reject      — từ chối
 *   GET    /api/staff/withdrawal-requests              — danh sách rút tiền chờ
 *   POST   /api/staff/withdrawal-requests/{id}/complete — xác nhận đã chuyển khoản
 *   POST   /api/staff/withdrawal-requests/{id}/reject  — từ chối rút tiền
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Tag(name = "Refund & Wallet", description = "Hoàn tiền, Ví điện tử và Rút tiền")
public class RefundWalletController {

    private final RefundAndWalletService service;

    // ── Customer: yêu cầu hủy vé ─────────────────────────────────────────────

    @Operation(summary = "Gửi yêu cầu hủy vé (chờ staff duyệt)")
    @PostMapping("/bookings/{bookingId}/request-cancel")
    public ResponseEntity<ApiResponse<RefundRequestResponse>> requestCancel(
            @PathVariable String bookingId,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        return created(service.requestCancel(bookingId, userId),
                "Yêu cầu hủy vé đã được gửi, vui lòng chờ xác nhận từ nhân viên");
    }

    // ── Customer: ví điện tử ──────────────────────────────────────────────────

    @Operation(summary = "Lấy thông tin ví điện tử và lịch sử giao dịch")
    @GetMapping("/users/{userId}/wallet")
    public ResponseEntity<ApiResponse<WalletResponse>> getWallet(
            @PathVariable String userId) {
        return success(service.getWallet(userId));
    }

    @Operation(summary = "Gửi yêu cầu rút tiền từ ví")
    @PostMapping("/users/{userId}/wallet/withdraw")
    public ResponseEntity<ApiResponse<WithdrawalRequestResponse>> withdraw(
            @PathVariable String userId,
            @RequestBody CreateWithdrawalRequest req) {
        return created(service.requestWithdrawal(userId, req),
                "Yêu cầu rút tiền đã được gửi");
    }

    @Operation(summary = "Lịch sử yêu cầu hoàn tiền của khách")
    @GetMapping("/users/{userId}/refund-requests")
    public ResponseEntity<ApiResponse<List<RefundRequestResponse>>> myRefundRequests(
            @PathVariable String userId) {
        return success(service.listRefundHistoryForUser(userId));
    }

    // ── Staff: xử lý hoàn tiền ───────────────────────────────────────────────

    @Operation(summary = "[Staff] Danh sách yêu cầu hoàn tiền chờ duyệt")
    @GetMapping("/staff/refund-requests")
    public ResponseEntity<ApiResponse<List<RefundRequestResponse>>> listRefunds() {
        return success(service.listRefundHistoryForStaff());
    }

    @Operation(summary = "[Staff] Duyệt yêu cầu hoàn tiền → tiền vào ví khách")
    @PostMapping("/staff/refund-requests/{id}/approve")
    public ResponseEntity<ApiResponse<RefundRequestResponse>> approveRefund(
            @PathVariable String id,
            @RequestHeader(value = "X-Staff-Id", defaultValue = "staff") String staffId) {
        return success(service.approveRefund(id, staffId),
                "Đã duyệt yêu cầu hoàn tiền");
    }

    @Operation(summary = "[Staff] Từ chối yêu cầu hoàn tiền → booking active trở lại")
    @PostMapping("/staff/refund-requests/{id}/reject")
    public ResponseEntity<ApiResponse<RefundRequestResponse>> rejectRefund(
            @PathVariable String id,
            @RequestHeader(value = "X-Staff-Id", defaultValue = "staff") String staffId,
            @RequestBody(required = false) ProcessRefundRequest body) {
        String reason = body != null ? body.reason() : null;
        return success(service.rejectRefund(id, staffId, reason),
                "Đã từ chối yêu cầu hoàn tiền");
    }

    // ── Staff: xử lý rút tiền ────────────────────────────────────────────────

    @Operation(summary = "[Staff] Danh sách yêu cầu rút tiền chờ xử lý")
    @GetMapping("/staff/withdrawal-requests")
    public ResponseEntity<ApiResponse<List<WithdrawalRequestResponse>>> listWithdrawals() {
        return success(service.listWithdrawalHistoryForStaff());
    }

    @Operation(summary = "[Staff] Xác nhận đã chuyển khoản thành công")
    @PostMapping("/staff/withdrawal-requests/{id}/complete")
    public ResponseEntity<ApiResponse<WithdrawalRequestResponse>> completeWithdrawal(
            @PathVariable String id,
            @RequestHeader(value = "X-Staff-Id", defaultValue = "staff") String staffId) {
        return success(service.completeWithdrawal(id, staffId),
                "Đã xác nhận chuyển khoản thành công");
    }

    @Operation(summary = "[Staff] Từ chối yêu cầu rút tiền → hoàn lại vào ví")
    @PostMapping("/staff/withdrawal-requests/{id}/reject")
    public ResponseEntity<ApiResponse<WithdrawalRequestResponse>> rejectWithdrawal(
            @PathVariable String id,
            @RequestHeader(value = "X-Staff-Id", defaultValue = "staff") String staffId,
            @RequestBody(required = false) ProcessRefundRequest body) {
        String note = body != null ? body.reason() : null;
        return success(service.rejectWithdrawal(id, staffId, note),
                "Đã từ chối và hoàn tiền vào ví");
    }
}
