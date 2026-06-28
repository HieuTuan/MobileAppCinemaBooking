package com.cineluxe.repository;

import com.cineluxe.entity.Movie;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Tìm kiếm & lọc phim — Requirement R3.
 *
 * <p>Luồng theo ảnh:
 * <ol>
 *   <li>GET /api/movies với query params tuỳ chọn</li>
 *   <li>Tìm text: khớp title, director, cast, genres (JPQL, không phân biệt hoa thường)</li>
 *   <li>Lọc theo genre hoặc status: nowShowing / comingSoon</li>
 *   <li>Không filter: tất cả phim active, sắp xếp releaseDate giảm dần</li>
 *   <li>Phân trang: page, pageSize (mặc định 20)</li>
 * </ol>
 *
 * <p>Lỗi & ngoại lệ: Không có kết quả → mảng rỗng, 200 OK
 */
public interface MovieRepository extends JpaRepository<Movie, String> {

    /**
     * Tìm kiếm & lọc phim (Req R3.1–R3.6, R3.8).
     *
     * <p>Dùng subquery EXISTS để tránh cross-product khi kết hợp
     * search trong cast/genres và lọc genre cùng lúc.
     *
     * <ul>
     *   <li>search  → LOWER(title | director | cast member | genre) LIKE %search%</li>
     *   <li>genre   → phim phải có genre đó trong collection</li>
     *   <li>status  → nowShowing: releaseDate <= today | comingSoon: > today</li>
     *   <li>null / blank params → bỏ qua điều kiện đó</li>
     *   <li>Luôn ORDER BY releaseDate DESC</li>
     * </ul>
     */
    @Query("""
            SELECT m FROM Movie m
            WHERE
                (
                    :search IS NULL OR :search = ''
                    OR LOWER(m.title)    LIKE LOWER(CONCAT('%', :search, '%'))
                    OR LOWER(m.director) LIKE LOWER(CONCAT('%', :search, '%'))
                    OR EXISTS (
                        SELECT 1 FROM Movie m2
                        JOIN m2.cast   castMember
                        WHERE m2.id = m.id
                          AND LOWER(castMember) LIKE LOWER(CONCAT('%', :search, '%'))
                    )
                    OR EXISTS (
                        SELECT 1 FROM Movie m3
                        JOIN m3.genres genreItem
                        WHERE m3.id = m.id
                          AND LOWER(genreItem) LIKE LOWER(CONCAT('%', :search, '%'))
                    )
                )
                AND (
                    :genre IS NULL OR :genre = ''
                    OR EXISTS (
                        SELECT 1 FROM Movie m4
                        JOIN m4.genres g4
                        WHERE m4.id = m.id AND g4 = :genre
                    )
                )
                AND (
                    :status IS NULL OR :status = ''
                    OR (:status = 'nowShowing'  AND m.releaseDate <= :today)
                    OR (:status = 'comingSoon'  AND m.releaseDate >  :today)
                )
            ORDER BY m.releaseDate DESC
            """)
    Page<Movie> searchMovies(
            @Param("search") String search,
            @Param("genre")  String genre,
            @Param("status") String status,
            @Param("today")  java.time.LocalDate today,
            Pageable pageable);

    /** Trả tất cả phim sắp xếp releaseDate giảm dần. */
    List<Movie> findByOrderByReleaseDateDesc();
}
