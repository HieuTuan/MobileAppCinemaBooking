package com.cineluxe.dto.response;

public record MovieRankingDto(int rank, String movieId, String title, int ticketsSold, long revenue) {}
