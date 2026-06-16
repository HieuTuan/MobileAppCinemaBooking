# AGENTS.md

> Hướng dẫn cho AI agent khi làm việc trên `organic_mart_be`.
> Base package: `com.bryan`.
> Tất cả quy tắc dưới đây là bắt buộc để đảm bảo chất lượng code và tránh ảo tưởng (hallucination).

---

## Project Overview & Prerequisite Check

| Field | Value |
|---|---|
| Framework | Spring Boot **4.0.6** (Jakarta EE 10+ APIs, no `javax.*`) |
| Java | **21** (LTS) |
| Database | PostgreSQL |
| Schema Management | Managed manually via JPA/Hibernate `ddl-auto=validate` (No migration tool like Flyway/Liquibase is used) |
| Boilerplate | Lombok (`@Getter`, `@Setter`, `@NoArgsConstructor`, `@RequiredArgsConstructor`, `@Slf4j`) |
| File Upload | Cloudinary |
| API Docs | SpringDoc OpenAPI 2.8.8 (Swagger: `/swagger-ui.html`) |

### ⚠️ MapStruct Smart Check (BẮT BUỘC)
*   Dự án sử dụng **MapStruct 1.6.3** cho DTO Mapping (`@Mapper(componentModel = "spring")`).
*   **Quy tắc AI:** Trước khi tạo hoặc chỉnh sửa bất kỳ Mapper nào, AI **phải** kiểm tra xem `pom.xml` đã cài MapStruct chưa. Nếu **chưa**, AI phải yêu cầu User phê duyệt thêm đoạn code XML sau vào `pom.xml`:
    ```xml
    <properties>
        <mapstruct.version>1.6.3</mapstruct.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.mapstruct</groupId>
            <artifactId>mapstruct</artifactId>
            <version>${mapstruct.version}</version>
        </dependency>
    </dependencies>
    <!-- Thêm mapstruct-processor trong maven-compiler-plugin -> annotationProcessorPaths -->
    ```

---

## Hard Rules (Tuyệt đối không vi phạm)

- **NEVER** `@Data` on JPA entities — use `@Getter @Setter @NoArgsConstructor` only.
- **NEVER** return raw `@Entity` from controller — always map to Response DTO.
- **NEVER** set `FetchType.EAGER` on any `@ManyToOne` / `@OneToMany` relations.
- **NEVER** put business logic in controllers.
- **NEVER** return `null` from service to indicate "not found" — throw typed exception.
- **NEVER** call `repository.save()` on a managed entity inside `@Transactional` unless explicit update modification touch is needed.
- **NEVER** add any dependency to `pom.xml` without explicit user approval.
- **NEVER** modify database schema without user approval since Flyway is disabled.
- **NEVER** hard-delete any entity without explicit user approval — always prefer soft delete (see Soft Delete section).
- **NEVER** use `@Enumerated(EnumType.ORDINAL)` — always use `@Enumerated(EnumType.STRING)` for all enum fields.
- **NEVER** commit secrets, credentials, or environment-specific config values — use `application-{profile}.yml` and environment variables.

---

## Package Structure

Dự án tuân thủ cấu trúc layered package phẳng trong `com.bryan`:

```
com.bryan/
├── controller/         ← REST controllers (returns ResponseEntity<ApiResponse<T>>)
├── dto/
│   ├── request/        ← Java records, Bean Validation (Tiếng Việt)
│   └── response/       ← Java records, no validation
├── entity/             ← JPA entities (User, Product, Cart, ...)
├── exception/          ← BadRequestException, ResourceNotFoundException, GlobalExceptionHandler
├── filter/             ← JwtAuthFilter
├── mapper/             ← MapStruct interfaces
├── repository/         ← Spring Data JPA
├── security/           ← CustomUserDetails, CustomUserDetailsService
├── service/            ← Service interfaces (returns Response DTO)
│   └── impl/           ← Service implementations
├── config/             ← SecurityConfig, CloudinaryConfig, etc.
└── utils/              ← Helper classes (JwtUtils, DateUtils, etc.)
```

**Quy tắc luồng phụ thuộc (Dependency Rule):**
```
controller → service (interface) → impl → repository → entity
     ↓              ↓
    dto          exception
                 utils (sử dụng được ở mọi nơi)
                 config / filter (độc lập)
```
*   `controller` chỉ inject Service interface, không biết đến `ServiceImpl`.
*   `impl` là nơi duy nhất chứa business logic và xử lý mapping DTO ↔ Entity.
*   `utils` không được phép import bất kỳ package nghiệp vụ nào khác trong dự án.

---

## Java 21 Conventions

- Luôn dùng **Java record** cho các lớp DTO (Request và Response).
- Khuyến khích dùng **sealed classes / interfaces** cho các nhóm trạng thái cố định hoặc domain events.
- Sử dụng **pattern matching** (`instanceof` mới, switch-case kiểu mới) thay vì ép kiểu thủ công.
- Sử dụng **text blocks** (`"""`) khi cần biểu diễn chuỗi JSON hoặc SQL nhiều dòng trong code test.
- Sử dụng `var` khi và chỉ khi kiểu dữ liệu ở vế phải đã rõ ràng (ví dụ: `var users = userRepository.findAll();`).

---

## Lombok Conventions

Dự án **được phép và khuyến khích** dùng Lombok để giảm boilerplate. Tuân thủ các quy tắc sau:

### Annotation được phép dùng

| Annotation | Được dùng ở | Ghi chú |
|---|---|---|
| `@Getter` | Entity, config class | Dùng ở class-level hoặc field-level |
| `@Setter` | Entity, config class | Dùng ở class-level hoặc field-level |
| `@NoArgsConstructor` | Entity | Bắt buộc cho JPA |
| `@RequiredArgsConstructor` | Service, Controller, Component | Thay thế constructor injection thủ công |
| `@AllArgsConstructor` | Chỉ dùng khi thực sự cần | Không dùng trên Entity |
| `@Builder` | Entity (thận trọng), DTO helper class | Xem quy tắc bên dưới |
| `@Slf4j` | ServiceImpl, Controller, Filter, Component | Tạo logger `log` tự động |
| `@ToString` | Entity | **Bắt buộc** exclude lazy collections |
| `@EqualsAndHashCode` | Entity | **Bắt buộc** `onlyExplicitlyIncluded = true` |
| `@Value` | Immutable config/value object (không phải Entity) | Tạo class final, all-args constructor, getters |
| `@With` | Record/immutable object | Tạo copy với field thay đổi |

### Annotation **CẤM** dùng

| Annotation | Lý do |
|---|---|
| `@Data` trên Entity | Sinh `equals/hashCode` dựa toàn bộ fields → vòng lặp vô hạn với Lazy collection |
| `@EqualsAndHashCode` không có `onlyExplicitlyIncluded = true` trên Entity | Tương tự lý do trên |
| `@ToString` không có `exclude` trên Entity có quan hệ Lazy | Trigger N+1 hoặc LazyInitializationException khi log |
| `@Autowired` trực tiếp trên field | Dùng `@RequiredArgsConstructor` + `private final` thay thế |
| `@SneakyThrows` | Che giấu checked exception, khó debug |

### JPA Entities — Template chuẩn
```java
@Entity
@Table(name = "snake_case_table_names")
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(exclude = {"orders", "items"}) // Exclude tất cả lazy collections
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    // ...
}
```

### @Builder trên Entity — Quy tắc thận trọng
Khi dùng `@Builder` trên Entity **phải** kết hợp với `@NoArgsConstructor` và `@AllArgsConstructor`, nếu không JPA sẽ lỗi vì thiếu no-args constructor:
```java
@Entity
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Product { ... }
```

### Services & Controllers — Constructor Injection
Dùng `@RequiredArgsConstructor` + `private final`. Tuyệt đối không dùng `@Autowired` trực tiếp lên field:
```java
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class UserServiceImpl implements UserService {
    private final UserRepository userRepository;
    private final UserMapper userMapper;
    // ...
}
```

---

## DTO & Bean Validation

### Request DTOs
- Luôn là **Java record**.
- Validate input bằng Jakarta Bean Validation (`@NotNull`, `@NotBlank`, `@Size`, `@Positive`, v.v.).
- Tất cả message thông báo lỗi validate bắt buộc phải viết bằng **Tiếng Việt**.
- Không bao giờ chứa `id`, `createdAt`, `updatedAt` trong request body.
```java
public record AddCartItemRequest(
        @NotNull(message = "ID sản phẩm không được để trống")
        Long productId,
        @NotNull(message = "Số lượng không được để trống")
        @Positive(message = "Số lượng phải lớn hơn 0")
        BigDecimal quantity
) {}
```

### Response DTOs
- Luôn là **Java record**, tuyệt đối không có annotation validate.
- Che giấu hoàn toàn các thông tin nhạy cảm (như `passwordHash`).
- Sử dụng `LocalDateTime` cho các trường ngày giờ. Enums sẽ tự động serialize thành String qua cấu hình mặc định của Spring Boot.

### Pagination DTOs (BẮT BUỘC cho mọi API trả danh sách)
Mọi endpoint trả về danh sách dữ liệu **phải** dùng `PageResponse<T>` thay vì `List<T>`:

```java
// dto/response/PageResponse.java
public record PageResponse<T>(
                List<T> content,
                int page,
                int size,
                long totalElements,
                int totalPages,
                boolean last
        ) {
    public static <T> PageResponse<T> of(Page<T> page) {
        return new PageResponse<>(
                page.getContent(),
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.getTotalPages(),
                page.isLast()
        );
    }
}
```

**Service** nhận `Pageable`, trả `PageResponse<T>`:
```java
PageResponse<ProductResponse> getProducts(Pageable pageable);
```

**Controller** nhận `@PageableDefault`:
```java
@GetMapping
public ResponseEntity<ApiResponse<PageResponse<ProductResponse>>> getProducts(
        @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable
) {
    return ResponseEntity.ok(ApiResponse.success(productService.getProducts(pageable)));
}
```

---

## MapStruct Conventions

Tất cả các Mapper phải khai báo dưới dạng Spring Bean:
```java
@Mapper(componentModel = "spring")
public interface CartMapper {
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    Cart toEntity(AddCartItemRequest request);

    @Mapping(source = "product.id", target = "productId")
    @Mapping(target = "subtotal", expression = "java(calculateSubtotal(item))")
    CartItemResponse toResponse(CartItem item);

    default BigDecimal calculateSubtotal(CartItem item) { ... }
}
```
*   **Quy tắc Mapper update:** Dùng `@MappingTarget` và thiết lập chiến lược bỏ qua giá trị null:
    ```java
    @Mapper(componentModel = "spring", nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    ```
*   **Bắt buộc:** Luôn thêm `@Mapping(target = "id", ignore = true)` cho các trường ID tự tăng và các trường Audit (`createdAt`, `updatedAt`) khi tạo mới hoặc cập nhật Entity.

---

## Entity & Database Conventions

### Naming
- Tất cả Table và Column đặt tên theo dạng `snake_case`, bảng ở dạng số nhiều (`users`, `products`).
- Kiểu khóa chính đồng nhất: `BIGSERIAL PRIMARY KEY` (PostgreSQL) ⟺ Java `Long` với `@GeneratedValue(strategy = GenerationType.IDENTITY)`.

### Index
Bắt buộc tạo index cho các trường FK để tối ưu hiệu năng:
```java
@Table(name = "orders", indexes = {
        @Index(name = "idx_orders_user_id", columnList = "user_id"),
        @Index(name = "idx_orders_status", columnList = "status")
})
```

### Enum Mapping
**Bắt buộc** dùng `EnumType.STRING`. Không bao giờ dùng `EnumType.ORDINAL`:
```java
@Enumerated(EnumType.STRING)
@Column(nullable = false)
private OrderStatus status;
```

### Audit Fields (BẮT BUỘC trên mọi Entity)
Mọi Entity **phải** kế thừa `BaseEntity` hoặc tự khai báo audit fields:
```java
// entity/BaseEntity.java
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
@Getter
public abstract class BaseEntity {

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
```

Bật JPA Auditing trong config:
```java
// config/JpaConfig.java
@Configuration
@EnableJpaAuditing
public class JpaConfig {}
```

### Soft Delete (BẮT BUỘC — không được hard delete)
Mọi Entity quan trọng **phải** dùng soft delete. **KHÔNG BAO GIỜ** hard delete mà không có explicit approval từ user:
```java
@Entity
@Getter @Setter
@NoArgsConstructor
@SQLRestriction("is_deleted = false")  // Spring Boot 4.x / Hibernate 6.x
public class Product extends BaseEntity {

    @Column(name = "is_deleted", nullable = false)
    private boolean isDeleted = false;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;
}
```

Service thực hiện soft delete:
```java
public void deleteProduct(Long id) {
    var product = productRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm với id: " + id));
    product.setDeleted(true);
    product.setDeletedAt(LocalDateTime.now());
    // Không cần gọi save() nếu đang trong @Transactional managed context
}
```

### N+1 Prevention
Chỉ sử dụng `FetchType.LAZY`. Khi cần truy xuất dữ liệu liên kết, dùng `@EntityGraph` hoặc `JOIN FETCH`:
```java
@EntityGraph(attributePaths = {"items", "items.product"})
Optional<Cart> findByUserId(Long userId);
```

---

## Service Layer Conventions

### Quy tắc Interface + Impl (BẮT BUỘC)

**NEVER** tạo `ServiceImpl` mà không có Service interface tương ứng. Mọi service **phải** có đủ 2 file:

| File | Package | Naming |
|---|---|---|
| Interface | `com.bryan.service` | `{Entity}Service` (ví dụ: `ProductService`) |
| Implementation | `com.bryan.service.impl` | `{Entity}ServiceImpl` (ví dụ: `ProductServiceImpl`) |

Controller chỉ được inject **interface**, tuyệt đối không inject trực tiếp `ServiceImpl`.

### Service Interface — Template chuẩn

```java
// service/ProductService.java
public interface ProductService {

    // Trả về PageResponse cho mọi API list
    PageResponse<ProductResponse> getProducts(Pageable pageable);

    // Trả về Response DTO, không bao giờ trả Entity
    ProductResponse getProductById(Long id);

    ProductResponse createProduct(CreateProductRequest request);

    ProductResponse updateProduct(Long id, UpdateProductRequest request);

    void deleteProduct(Long id);
}
```

### Service Implementation — Template chuẩn

```java
// service/impl/ProductServiceImpl.java
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional          // Default cho write operations ở class level
public class ProductServiceImpl implements ProductService {

    private final ProductRepository productRepository;
    private final ProductMapper productMapper;

    @Override
    @Transactional(readOnly = true)     // BẮT BUỘC cho mọi method chỉ đọc
    public PageResponse<ProductResponse> getProducts(Pageable pageable) {
        return PageResponse.of(
            productRepository.findAllByIsDeletedFalse(pageable)
                .map(productMapper::toResponse)
        );
    }

    @Override
    @Transactional(readOnly = true)
    public ProductResponse getProductById(Long id) {
        var product = productRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException(
                "Không tìm thấy sản phẩm với id: " + id));
        return productMapper.toResponse(product);
    }

    @Override
    public ProductResponse createProduct(CreateProductRequest request) {
        var product = productMapper.toEntity(request);
        var saved = productRepository.save(product);
        return productMapper.toResponse(saved);
    }

    @Override
    public ProductResponse updateProduct(Long id, UpdateProductRequest request) {
        var product = productRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException(
                "Không tìm thấy sản phẩm với id: " + id));
        productMapper.updateEntity(request, product);   // @MappingTarget, IGNORE null
        return productMapper.toResponse(product);
        // Không gọi save() — managed entity trong @Transactional tự flush
    }

    @Override
    public void deleteProduct(Long id) {
        var product = productRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException(
                "Không tìm thấy sản phẩm với id: " + id));
        product.setDeleted(true);
        product.setDeletedAt(LocalDateTime.now());
    }
}
```

### Các quy tắc bắt buộc

- `@Transactional` đặt ở **class level** (áp dụng cho toàn bộ write methods).
- `@Transactional(readOnly = true)` đặt ở **method level** cho mọi method chỉ đọc — giúp Hibernate tắt dirty checking, tăng hiệu năng.
- **Luôn dùng DTO**: nhận `Request DTO` → trả `Response DTO`. Không bao giờ nhận hoặc trả `Entity`.
- Không bao giờ trả `null` khi không tìm thấy dữ liệu — ném exception cụ thể:
    - `ResourceNotFoundException` → 404
    - `BadRequestException` → 400 / 409

---

## Security & JWT

### Endpoint Whitelist (Không cần Auth):
- `POST /api/v1/auth/signup`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/forgot-password`
- `POST /api/v1/auth/reset-password`
- `GET /api/v1/products/**`
- `GET /api/v1/product-categories/**`
- `GET /api/v1/farms`
- Các tài liệu API: `/v3/api-docs/**`, `/swagger-ui/**`, `/swagger-ui.html`

### JWT Structure
- **Access Token:** Chứa `sub` (email), `id` (userId), `roles`, `type = "access"`.
- **Refresh Token:** Chứa `sub` (email), `id` (userId), `type = "refresh"`.

### Lấy thông tin User hiện tại trong Service:
```java
CustomUserDetails userDetails = (CustomUserDetails)
        SecurityContextHolder.getContext().getAuthentication().getPrincipal();
Long userId = userDetails.getId();
```

### CORS Configuration
Khai báo CORS trong `SecurityConfig`. Không để wildcard `*` trên production:
```java
@Bean
CorsConfigurationSource corsConfigurationSource() {
    var config = new CorsConfiguration();
    config.setAllowedOrigins(List.of(
            "http://localhost:3000",   // local dev
            "https://organicmart.vn"   // production — thay bằng domain thực
    ));
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
    config.setAllowedHeaders(List.of("*"));
    config.setAllowCredentials(true);
    var source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/api/**", config);
    return source;
}
```

### Role Hierarchy
Dự án sử dụng 2 roles cố định. Không tự ý thêm role mới mà không có approval:

| Role | Quyền |
|---|---|
| `ROLE_ADMIN` | Toàn bộ endpoint, bao gồm quản lý user và sản phẩm |
| `ROLE_USER` | Endpoint của user thường (cart, order, profile) |

---

## API Response & HTTP Status Codes

Tất cả Controllers phải bọc dữ liệu trả về bằng `ResponseEntity<ApiResponse<T>>`. Xem class `ApiResponse` và format JSON đầy đủ ở section **Exception Handling** bên dưới.

### Static Helpers in `ApiResponse`:
- `ApiResponse.success(T data)` — 200 OK
- `ApiResponse.success(T data, String message)` — 200 OK với thông điệp
- `ApiResponse.success(201, T data)` — 201 Created
- `ApiResponse.success(201, T data, "Tạo thành công")`
- `ApiResponse.error(statusCode, "message")`
- `ApiResponse.validationError(List<ValidationError>)` — 400 với mảng lỗi trong `data`

### HTTP Status Matrix:
- **200**: Trả về danh sách, chi tiết, cập nhật, xóa thành công (kèm message).
- **201**: Tạo mới thành công.
- **400**: Validate lỗi hoặc Request không hợp lệ.
- **401**: Token không hợp lệ hoặc sai thông tin đăng nhập.
- **403**: Không có quyền truy cập.
- **404**: Không tìm thấy tài nguyên.
- **409**: Dữ liệu bị trùng lặp (ví dụ: email đã được sử dụng).
- **413**: File upload vượt quá giới hạn kích thước.
- **429**: Rate limit — quá nhiều request.
- **502**: AI/external service trả về dữ liệu không hợp lệ.
- **504**: AI/external service timeout.
- **500**: Lỗi hệ thống — KHÔNG lộ message gốc ra client.

---

## Exception Handling

Được tập trung xử lý tại `GlobalExceptionHandler` (`@RestControllerAdvice` quét package `com.bryan.controller`).

### Custom Exceptions

```java
// exception/ResourceNotFoundException.java
// KHÔNG dùng @ResponseStatus — để GlobalExceptionHandler kiểm soát hoàn toàn response format
public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
}

// exception/BadRequestException.java
public class BadRequestException extends RuntimeException {
    public BadRequestException(String message) {
        super(message);
    }
}

// exception/AiResponseParseException.java
public class AiResponseParseException extends RuntimeException {
    public AiResponseParseException(String message) { super(message); }
}

// exception/AiTimeoutException.java
public class AiTimeoutException extends RuntimeException {
    public AiTimeoutException(String message) { super(message); }
}

// exception/MealPlanRateLimitException.java
public class MealPlanRateLimitException extends RuntimeException {
    public MealPlanRateLimitException(String message) { super(message); }
}
```

> **Lý do KHÔNG dùng `@ResponseStatus` trên Exception class:** Khi có `@ResponseStatus`, Spring MVC xử lý exception theo cơ chế riêng và bỏ qua `GlobalExceptionHandler` trong một số trường hợp, khiến response trả về không đúng format `ApiResponse`. Chỉ dùng `@ExceptionHandler` trong `GlobalExceptionHandler` để đảm bảo 100% response đi qua `ApiResponse` wrapper.

### Exception → HTTP Status Matrix

| Exception | HTTP Status | Ghi chú |
|---|---|---|
| `ResourceNotFoundException` | 404 | Không tìm thấy tài nguyên |
| `BadRequestException` | 400 | Request không hợp lệ |
| `BadRequestException` (message chứa `"already in use"`) | 409 | Dữ liệu trùng lặp |
| `BadRequestException` (message chứa `"Invalid email or password"`) | 401 | Sai thông tin đăng nhập |
| `MethodArgumentNotValidException` | 400 | Trả về **mảng** `[{field, message}]` trong `data` |
| `MaxUploadSizeExceededException` | 413 | File vượt quá giới hạn |
| `MultipartException` | 400 | Dữ liệu multipart không hợp lệ |
| `AiResponseParseException` | 502 | AI trả về dữ liệu không parse được |
| `AiTimeoutException` | 504 | AI timeout |
| `MealPlanRateLimitException` | 429 | Rate limit |
| `AccessDeniedException` | 403 | Không có quyền |
| `AuthenticationException` | 401 | Chưa xác thực |
| `Exception` (catch-all) | 500 | **Chỉ log nội bộ, KHÔNG trả message gốc ra client** |

### GlobalExceptionHandler — Template chuẩn

```java
@RestControllerAdvice(basePackages = "com.bryan.controller")
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleResourceNotFoundException(ResourceNotFoundException ex) {
        return ApiResponse.error(404, ex.getMessage());
    }

    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<ApiResponse<Void>> handleBadRequestException(BadRequestException ex) {
        int statusCode = 400;
        if (ex.getMessage().contains("already in use")) statusCode = 409;
        else if (ex.getMessage().contains("Invalid email or password")) statusCode = 401;
        return ApiResponse.error(statusCode, ex.getMessage());
    }

    // Trả về TOÀN BỘ lỗi validation (tất cả fields), không chỉ lỗi đầu tiên
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<List<ValidationError>>> handleValidationExceptions(
            MethodArgumentNotValidException ex) {
        var errors = ex.getBindingResult().getFieldErrors().stream()
                .map(e -> new ValidationError(e.getField(), e.getDefaultMessage()))
                .toList();
        return ApiResponse.validationError(errors); // Xem ApiResponse bên dưới
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiResponse<Void>> handleMaxUploadSizeExceededException(MaxUploadSizeExceededException ex) {
        return ApiResponse.error(413, "Ảnh không được vượt quá 5MB.");
    }

    @ExceptionHandler(MultipartException.class)
    public ResponseEntity<ApiResponse<Void>> handleMultipartException(MultipartException ex) {
        return ApiResponse.error(400, "Dữ liệu tải ảnh không hợp lệ.");
    }

    @ExceptionHandler(AiResponseParseException.class)
    public ResponseEntity<ApiResponse<Void>> handleAiParseException(AiResponseParseException ex) {
        return ApiResponse.error(502, "Không thể tạo thực đơn. Vui lòng thử lại: " + ex.getMessage());
    }

    @ExceptionHandler(AiTimeoutException.class)
    public ResponseEntity<ApiResponse<Void>> handleAiTimeoutException(AiTimeoutException ex) {
        return ApiResponse.error(504, "Máy chủ AI đang quá tải. Vui lòng thử lại sau vài phút.");
    }

    @ExceptionHandler(MealPlanRateLimitException.class)
    public ResponseEntity<ApiResponse<Void>> handleRateLimitException(MealPlanRateLimitException ex) {
        return ApiResponse.error(429, ex.getMessage());
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handleAccessDeniedException(AccessDeniedException ex) {
        return ApiResponse.error(403, "Bạn không có quyền thực hiện thao tác này.");
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiResponse<Void>> handleAuthenticationException(AuthenticationException ex) {
        return ApiResponse.error(401, "Vui lòng đăng nhập để tiếp tục.");
    }

    // KHÔNG trả ex.getMessage() ra ngoài — bảo mật thông tin hệ thống
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleGlobalException(Exception ex) {
        log.error("Unhandled exception: {}", ex.getMessage(), ex);
        return ApiResponse.error(500, "Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.");
    }
}
```

### ApiResponse — Class chuẩn (bao gồm validation overload)

```java
// dto/response/ValidationError.java
public record ValidationError(String field, String message) {}
```

```java
// dto/response/ApiResponse.java
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {

    private final int status;
    private final String message;
    private final T data;

    private ApiResponse(int status, String message, T data) {
        this.status = status;
        this.message = message;
        this.data = data;
    }

    // ── Success helpers ──────────────────────────────────────────
    public static <T> ResponseEntity<ApiResponse<T>> success(T data) {
        return success(HttpStatus.OK.value(), data, "Success");
    }

    public static <T> ResponseEntity<ApiResponse<T>> success(T data, String message) {
        return success(HttpStatus.OK.value(), data, message);
    }

    public static <T> ResponseEntity<ApiResponse<T>> success(int status, T data) {
        return success(status, data, "Success");
    }

    public static <T> ResponseEntity<ApiResponse<T>> success(int status, T data, String message) {
        return ResponseEntity.status(status).body(new ApiResponse<>(status, message, data));
    }

    // ── Error helpers ────────────────────────────────────────────
    public static <T> ResponseEntity<ApiResponse<T>> error(int status, String message) {
        return ResponseEntity.status(status).body(new ApiResponse<>(status, message, null));
    }

    // Dùng riêng cho MethodArgumentNotValidException — trả mảng lỗi trong data
    public static ResponseEntity<ApiResponse<List<ValidationError>>> validationError(
            List<ValidationError> errors) {
        return ResponseEntity.status(400)
                .body(new ApiResponse<>(400, "Dữ liệu không hợp lệ", errors));
    }

    // ── Getters ──────────────────────────────────────────────────
    public int getStatus() { return status; }
    public String getMessage() { return message; }
    public T getData() { return data; }
}
```

### Response format chuẩn theo từng trường hợp

```json
// 200 OK
{ "status": 200, "message": "Success", "data": { ... } }

// 404 Not Found
{ "status": 404, "message": "Không tìm thấy sản phẩm với id: 5", "data": null }

// 400 Validation Error — data là mảng, KHÔNG phải string
{
  "status": 400,
  "message": "Dữ liệu không hợp lệ",
  "data": [
    { "field": "email", "message": "Email không được để trống" },
    { "field": "quantity", "message": "Số lượng phải lớn hơn 0" }
  ]
}

// 500 Internal Error — KHÔNG lộ message gốc
{ "status": 500, "message": "Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.", "data": null }
```

---

## Environment & Configuration

### Profile Structure
Dự án sử dụng Spring profiles. **Không bao giờ** hardcode giá trị config vào code:

```
src/main/resources/
├── application.yml              ← Config chung (không chứa secrets)
├── application-local.yml        ← Local dev (gitignored)
├── application-dev.yml          ← Dev server
└── application-prod.yml         ← Production (secrets từ env vars)
```

### application.yml (template chung)
```yaml
spring:
  application:
    name: organic-mart-be
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: true
  jackson:
    default-property-inclusion: non_null
    serialization:
      write-dates-as-timestamps: false

logging:
  level:
    com.bryan: DEBUG          # override thành INFO trên prod
    org.hibernate.SQL: DEBUG  # override thành WARN trên prod
```

### Secrets — Quy tắc bắt buộc
- **KHÔNG BAO GIỜ** commit `DB_PASSWORD`, `JWT_SECRET`, `CLOUDINARY_SECRET`, API key vào git.
- Dùng biến môi trường và đọc qua `${ENV_VAR_NAME}` trong yml:
```yaml
# application-prod.yml
spring:
  datasource:
    url: ${DB_URL}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
jwt:
  secret: ${JWT_SECRET}
  expiration: ${JWT_EXPIRATION:3600000}
```

### Logging Level theo Environment

| Profile | `com.bryan` | `org.hibernate.SQL` |
|---|---|---|
| local | DEBUG | DEBUG |
| dev | DEBUG | WARN |
| prod | INFO | WARN |

---

## Database & Repository Conventions

(Xem thêm Entity & Database Conventions bên trên cho Index, Enum, Audit, Soft Delete)

### Repository Pattern
```java
// Dùng Optional, không bao giờ trả null
Optional<User> findByEmail(String email);

// JOIN FETCH để tránh N+1
@Query("SELECT p FROM Product p JOIN FETCH p.category WHERE p.isDeleted = false")
List<Product> findAllWithCategory();

// Pagination
Page<Product> findAllByIsDeletedFalse(Pageable pageable);
```

---

## Testing Conventions

### Unit Tests (Service Layer)
- Đặt tại: `src/test/java/.../service/impl/{Name}ServiceImplTest.java`.
- Chú thích: `@ExtendWith(MockitoExtension.class)` (Không tải Spring context lên để chạy nhanh).
- Quy tắc đặt tên hàm test: `should{ExpectedBehavior}_when{Condition}`.

```java
@ExtendWith(MockitoExtension.class)
class ProductServiceImplTest {

    @Mock ProductRepository productRepository;
    @Mock ProductMapper productMapper;
    @InjectMocks ProductServiceImpl productService;

    @Test
    void shouldThrowResourceNotFoundException_whenProductNotFound() {
        when(productRepository.findById(99L)).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class,
                () -> productService.getProductById(99L));
    }
}
```

### Slice Tests (Controller Layer)
- Đặt tại: `src/test/java/.../controller/{Name}ControllerTest.java`.
- Sử dụng `@WebMvcTest(controllers = {Name}Controller.class)`. Mock Service layer bằng `@MockBean`.
- Dùng `MockMvc` để gọi API và kiểm tra JSON trả về.

### Integration Tests
- Dùng `@SpringBootTest` + `@AutoConfigureMockMvc` khi cần test toàn bộ luồng (auth flow, complex transaction).
- Dùng `@Transactional` trên test class để rollback data sau mỗi test.
- Không viết Integration test cho mọi trường hợp — chỉ khi Unit test không đủ bao phủ.

### Test Data Setup
```java
@BeforeEach
void setUp() {
    user = User.builder()
            .id(1L)
            .email("test@example.com")
            .build();
}
```

---

## Git & Workflow Conventions

### Git Branching
- `feature/{ticket}-description` — Phát triển tính năng mới.
- `fix/{ticket}-description` — Sửa lỗi.
- `refactor/{ticket}-description` — Cải tiến cấu trúc code.
- `chore/{ticket}-description` — Cấu hình, update dependency.

### Commit Messages (Conventional Commits)
Sử dụng cấu trúc: `type: description`
- `feat:` tính năng mới
- `fix:` sửa lỗi
- `refactor:` cải tiến cấu trúc code
- `test:` viết/sửa code test
- `docs:` cập nhật tài liệu
- `chore:` build tool, update thư viện

---

## Build & Verify Commands (PowerShell)

```powershell
.\mvnw.cmd compile -q          # 1. Biên dịch nhanh kiểm tra lỗi cú pháp
.\mvnw.cmd test                # 2. Chạy toàn bộ các unit test
.\mvnw.cmd clean verify        # 3. Build sạch sẽ & chạy kiểm tra toàn diện
.\mvnw.cmd spring-boot:run -Dspring-boot.run.profiles=local  # Chạy app ở local
```

---

## Definition of Done (Định nghĩa Hoàn thành)

- [ ] Cập nhật đồng bộ toàn bộ các Layer: DTO Request → Entity → Repository → Mapper → Service Interface → Service Impl → DTO Response → Controller.
- [ ] Tất cả Request DTO đều có validation ràng buộc chặt chẽ bằng Tiếng Việt.
- [ ] API trả danh sách dùng `PageResponse<T>`, không dùng `List<T>` raw.
- [ ] Entity mới kế thừa `BaseEntity` (có `createdAt`, `updatedAt`).
- [ ] Entity có dữ liệu quan trọng dùng soft delete (`isDeleted`, `deletedAt`).
- [ ] Enum fields dùng `@Enumerated(EnumType.STRING)`.
- [ ] Service ném ra Exception rõ ràng thay vì trả về null.
- [ ] Code pass qua lệnh biên dịch cú pháp `.\mvnw.cmd compile -q`.
- [ ] Không rò rỉ thực thể `@Entity` trực tiếp ra ngoài controller.
- [ ] Không có secret/credential nào bị hardcode trong code hoặc config file được commit.
- [ ] Tài liệu API Swagger `/swagger-ui.html` hiển thị chính xác endpoint mới.