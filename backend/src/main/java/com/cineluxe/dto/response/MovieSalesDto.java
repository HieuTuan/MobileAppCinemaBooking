package com.cineluxe.dto.response;

public record MovieSalesDto(
    String movieId, String title, int ticketsSold, long revenue
) {}
