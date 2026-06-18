package com.cineluxe.dto.response;

public record RevenueByPaymentMethodDto(String method, long amount, int count) {}
