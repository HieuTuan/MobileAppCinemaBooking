package com.cineluxe.service.impl;

import com.cineluxe.dto.response.MovieResponse;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.MovieRepository;
import com.cineluxe.service.MovieService;
import java.time.LocalDate;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Implementation của {@link MovieService}.
 *
 * <p>Luồng theo ảnh (Requirement R3):
 * <ol>
 *   <li>GET /api/movies với query params tuỳ chọn</li>
 *   <li>Tìm text: khớp title, director, cast, genres (JPQL, không phân biệt hoa thường)</li>
 *   <li>Lọc theo genre hoặc status: nowShowing / comingSoon</li>
 *   <li>Không filter: tất cả phim, sắp xếp releaseDate giảm dần</li>
 *   <li>Phân trang: page, pageSize (mặc định 20)</li>
 * </ol>
 *
 * <p>Lỗi & ngoại lệ: Không có kết quả → mảng rỗng, 200 OK
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class MovieServiceImpl implements MovieService {

    private static final int DEFAULT_PAGE_SIZE = 20;
    private static final int MAX_PAGE_SIZE     = 100;

    private final MovieRepository movieRepository;

    @Override
    public Page<MovieResponse> getMovies(String search, String genre, String status,
                                          int page, int pageSize) {
        // Chuẩn hoá input
        String normalizedSearch = (search  == null || search.isBlank())  ? null : search.trim();
        String normalizedGenre  = (genre   == null || genre.isBlank())   ? null : genre.trim();
        String normalizedStatus = (status  == null || status.isBlank())  ? null : status.trim();

        // Đảm bảo pageSize hợp lệ
        int size = Math.min(Math.max(pageSize, 1), MAX_PAGE_SIZE);
        // Spring Pageable bắt đầu từ 0, client gửi từ 1
        int zeroBasedPage = Math.max(page - 1, 0);

        var pageable = PageRequest.of(zeroBasedPage, size);
        var today    = LocalDate.now();

        log.debug("getMovies: search={}, genre={}, status={}, page={}, size={}",
                normalizedSearch, normalizedGenre, normalizedStatus, page, size);

        // Thực hiện truy vấn — nếu không có kết quả JPQL trả Page rỗng → 200 OK với data=[]
        return movieRepository
                .searchMovies(normalizedSearch, normalizedGenre, normalizedStatus, today, pageable)
                .map(MovieResponse::from);
    }

    @Override
    public MovieResponse getMovieById(String movieId) {
        return movieRepository.findById(movieId)
                .map(MovieResponse::from)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                        "Movie not found: " + movieId));
    }
}
