-- =======================================================================================
-- ĐỒ ÁN: PHÂN TÍCH THIẾT KẾ HỆ THỐNG THÔNG TIN / LẬP TRÌNH WEB
-- ĐỀ TÀI: HỆ THỐNG QUẢN LÝ KHÓA HỌC TRỰC TUYẾN
-- HỆ QUẢN TRỊ CSDL: MICROSOFT SQL SERVER
-- ĐẶC ĐIỂM: 
--   - Toàn bộ tên bảng và thuộc tính bằng TIẾNG VIỆT không dấu (chuẩn đào tạo ĐH tại VN)
--   - Thiết kế vừa phải, tinh gọn, đáp ứng trọn vẹn 7 nghiệp vụ trọng tâm
--   - Kèm ràng buộc nghiệp vụ, Trigger thông minh, View thống kê và Dữ liệu mẫu (Seed Data)
-- =======================================================================================

USE master;
GO

IF DB_ID('QuanLyLopHocTrucTuyen') IS NOT NULL
BEGIN
    ALTER DATABASE QuanLyLopHocTrucTuyen SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QuanLyLopHocTrucTuyen;
END
GO

CREATE DATABASE QuanLyLopHocTrucTuyen
COLLATE Vietnamese_CI_AS;
GO

USE QuanLyLopHocTrucTuyen;
GO

-- =======================================================================================
-- PHẦN 1: TẠO CÁC BẢNG DỮ LIỆU (18 BẢNG TINH GỌN THEO 7 NGHIỆP VỤ)
-- =======================================================================================

-- ---------------------------------------------------------------------------------------
-- NGHIỆP VỤ 1: QUẢN LÝ TÀI KHOẢN VÀ PHÂN QUYỀN
-- ---------------------------------------------------------------------------------------

-- 1. Bảng Vai Trò (Admin, GiangVien, HocVien)
CREATE TABLE VaiTro (
    MaVaiTro INT IDENTITY(1,1) PRIMARY KEY,
    TenVaiTro NVARCHAR(50) NOT NULL UNIQUE,     -- N'Admin', N'GiangVien', N'HocVien'
    MoTa NVARCHAR(255) NULL
);
GO

-- 2. Bảng Người Dùng (Hỗ trợ tài khoản thường và mạng xã hội)
CREATE TABLE NguoiDung (
    MaNguoiDung INT IDENTITY(1,1) PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    MatKhau VARCHAR(255) NULL,                 -- NULL nếu đăng nhập Google/Facebook
    SoDienThoai VARCHAR(20) NULL,
    AnhDaiDien NVARCHAR(500) NULL,
    GioiThieu NVARCHAR(MAX) NULL,
    MaVaiTro INT NOT NULL DEFAULT 3,           -- Mặc định là Học viên (MaVaiTro = 3)
    PhuongThucDangNhap VARCHAR(50) NOT NULL DEFAULT 'Local', -- 'Local', 'Google', 'Facebook'
    DaKichHoat BIT NOT NULL DEFAULT 1,         -- Kích hoạt qua email
    TrangThai BIT NOT NULL DEFAULT 1,          -- 1: Hoạt động, 0: Bị khóa
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_NguoiDung_VaiTro FOREIGN KEY (MaVaiTro) REFERENCES VaiTro(MaVaiTro)
);
GO

-- 3. Bảng Yêu Cầu Nâng Cấp Lên Giảng Viên
CREATE TABLE YeuCauGiangVien (
    MaYeuCau INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT NOT NULL,
    FileCV NVARCHAR(500) NOT NULL,             -- Đường dẫn CV
    FileChungChi NVARCHAR(500) NULL,           -- Đường dẫn chứng chỉ chuyên môn
    MoTaNangLuc NVARCHAR(MAX) NOT NULL,
    TrangThai NVARCHAR(30) NOT NULL DEFAULT N'ChoDuyet', -- N'ChoDuyet', N'DaDuyet', N'TuChoi'
    LyDoTuChoi NVARCHAR(500) NULL,             -- Quản trị viên phản hồi nếu từ chối
    NgayGui DATETIME NOT NULL DEFAULT GETDATE(),
    NgayDuyet DATETIME NULL,
    CONSTRAINT FK_YeuCau_NguoiDung FOREIGN KEY (MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung)
);
GO

-- ---------------------------------------------------------------------------------------
-- NGHIỆP VỤ 2: QUẢN LÝ KHÓA HỌC
-- ---------------------------------------------------------------------------------------

-- 4. Bảng Danh Mục Khóa Học
CREATE TABLE DanhMuc (
    MaDanhMuc INT IDENTITY(1,1) PRIMARY KEY,
    TenDanhMuc NVARCHAR(100) NOT NULL UNIQUE,
    MoTa NVARCHAR(255) NULL
);
GO

-- 5. Bảng Khóa Học
CREATE TABLE KhoaHoc (
    MaKhoaHoc INT IDENTITY(1,1) PRIMARY KEY,
    TenKhoaHoc NVARCHAR(200) NOT NULL,
    MaDanhMuc INT NOT NULL,
    MaGiangVien INT NOT NULL,
    MoTa NVARCHAR(MAX) NULL,
    Gia DECIMAL(18,0) NOT NULL DEFAULT 0,      -- Giá bán (0: miễn phí)
    AnhDaiDien NVARCHAR(500) NULL,
    TrangThai NVARCHAR(30) NOT NULL DEFAULT N'BanNhap', -- N'BanNhap', N'ChoDuyet', N'DaDuyet', N'TuChoi'
    LyDoTuChoi NVARCHAR(500) NULL,             -- Admin phản hồi lý do từ chối
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_KhoaHoc_DanhMuc FOREIGN KEY (MaDanhMuc) REFERENCES DanhMuc(MaDanhMuc),
    CONSTRAINT FK_KhoaHoc_GiangVien FOREIGN KEY (MaGiangVien) REFERENCES NguoiDung(MaNguoiDung)
);
GO

-- 6. Bảng Chương Học
CREATE TABLE ChuongHoc (
    MaChuong INT IDENTITY(1,1) PRIMARY KEY,
    MaKhoaHoc INT NOT NULL,
    TenChuong NVARCHAR(200) NOT NULL,
    ThuTu INT NOT NULL DEFAULT 1,
    CONSTRAINT FK_ChuongHoc_KhoaHoc FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc) ON DELETE CASCADE
);
GO

-- 7. Bảng Bài Học (Lưu Video YouTube Unlisted & Tài liệu)
CREATE TABLE BaiHoc (
    MaBaiHoc INT IDENTITY(1,1) PRIMARY KEY,
    MaChuong INT NOT NULL,
    TenBaiHoc NVARCHAR(200) NOT NULL,
    ThuTu INT NOT NULL DEFAULT 1,
    LoaiBaiHoc NVARCHAR(20) NOT NULL DEFAULT N'Video', -- N'Video', N'TaiLieu'
    MaVideoYoutube VARCHAR(50) NULL,                   -- ID video YouTube Unlisted
    ThoiLuongGiay INT NOT NULL DEFAULT 0,              -- Thời lượng video
    TrangThaiVideo NVARCHAR(30) NOT NULL DEFAULT N'SanSang', -- N'DangXuLy', N'SanSang', N'Loi'
    FileTaiLieu NVARCHAR(500) NULL,                    -- File đính kèm (PDF, ZIP,...)
    ChoHocThu BIT NOT NULL DEFAULT 0,                  -- 1: Cho phép xem trước miễn phí
    CONSTRAINT FK_BaiHoc_ChuongHoc FOREIGN KEY (MaChuong) REFERENCES ChuongHoc(MaChuong) ON DELETE CASCADE
);
GO

-- ---------------------------------------------------------------------------------------
-- NGHIỆP VỤ 3: MUA KHÓA HỌC VÀ THANH TOÁN (VNPAY / MOMO)
-- ---------------------------------------------------------------------------------------

-- 8. Bảng Giỏ Hàng
CREATE TABLE GioHang (
    MaGioHang INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT NOT NULL,
    MaKhoaHoc INT NOT NULL,
    NgayThem DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_GioHang_NguoiDung FOREIGN KEY (MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung) ON DELETE CASCADE,
    CONSTRAINT FK_GioHang_KhoaHoc FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc),
    CONSTRAINT UQ_GioHang UNIQUE (MaNguoiDung, MaKhoaHoc)
);
GO

-- 9. Bảng Đơn Hàng
CREATE TABLE DonHang (
    MaDonHang INT IDENTITY(1,1) PRIMARY KEY,
    MaGiaoDich VARCHAR(50) NOT NULL UNIQUE,            -- Mã đơn hàng sinh ngẫu nhiên
    MaNguoiDung INT NOT NULL,
    TongTien DECIMAL(18,0) NOT NULL DEFAULT 0,
    PhuongThuc NVARCHAR(50) NOT NULL,                  -- N'VNPAY', N'MOMO'
    TrangThai NVARCHAR(30) NOT NULL DEFAULT N'ChoThanhToan', -- N'ChoThanhToan', N'DaThanhToan', N'DaHuy'
    MaGiaoDichCong VARCHAR(100) NULL,                  -- Mã giao dịch phản hồi từ VNPAY/MoMo
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
    NgayThanhToan DATETIME NULL,
    CONSTRAINT FK_DonHang_NguoiDung FOREIGN KEY (MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung)
);
GO

-- 10. Bảng Chi Tiết Đơn Hàng (Tính hoa hồng sàn & tiền giảng viên)
CREATE TABLE ChiTietDonHang (
    MaChiTiet INT IDENTITY(1,1) PRIMARY KEY,
    MaDonHang INT NOT NULL,
    MaKhoaHoc INT NOT NULL,
    GiaMua DECIMAL(18,0) NOT NULL,
    TyLeHoaHong DECIMAL(5,2) NOT NULL DEFAULT 20.00,   -- Tỷ lệ % hoa hồng sàn cấu hình
    TienSan DECIMAL(18,0) NOT NULL DEFAULT 0,          -- Tiền sàn nhận = GiaMua * TyLeHoaHong / 100
    TienGiangVien DECIMAL(18,0) NOT NULL DEFAULT 0,    -- Tiền giảng viên = GiaMua - TienSan
    CONSTRAINT FK_ChiTiet_DonHang FOREIGN KEY (MaDonHang) REFERENCES DonHang(MaDonHang) ON DELETE CASCADE,
    CONSTRAINT FK_ChiTiet_KhoaHoc FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc),
    CONSTRAINT UQ_ChiTiet_DonHang_KhoaHoc UNIQUE (MaDonHang, MaKhoaHoc)
);
GO

-- 11. Bảng Đăng Ký Khóa Học (Khóa học học viên đã sở hữu và theo dõi tiến độ)
CREATE TABLE DangKyKhoaHoc (
    MaDangKy INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT NOT NULL,
    MaKhoaHoc INT NOT NULL,
    NgayDangKy DATETIME NOT NULL DEFAULT GETDATE(),
    TienDoPhanTram DECIMAL(5,2) NOT NULL DEFAULT 0.00, -- Cập nhật tự động (0 - 100%)
    DaHoanThanh BIT NOT NULL DEFAULT 0,                -- 1: Hoàn thành 100% bài học
    NgayHoanThanh DATETIME NULL,
    CONSTRAINT FK_DangKy_NguoiDung FOREIGN KEY (MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_DangKy_KhoaHoc FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc),
    CONSTRAINT UQ_DangKy_NguoiDung_KhoaHoc UNIQUE (MaNguoiDung, MaKhoaHoc)
);
GO

-- ---------------------------------------------------------------------------------------
-- NGHIỆP VỤ 4: HỌC TẬP VÀ THEO DÕI TIẾN ĐỘ
-- ---------------------------------------------------------------------------------------

-- 12. Bảng Tiến Độ Từng Bài Học (Theo dõi thời gian xem qua YouTube IFrame API)
CREATE TABLE TienDoBaiHoc (
    MaTienDo INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT NOT NULL,
    MaBaiHoc INT NOT NULL,
    ThoiGianDaXem INT NOT NULL DEFAULT 0,      -- Tổng số giây xem tích lũy
    ViTriDung INT NOT NULL DEFAULT 0,          -- Vị trí dừng (giây) để xem tiếp
    DaHoanThanh BIT NOT NULL DEFAULT 0,        -- 1: Hoàn thành khi xem >= 90% hoặc mở tài liệu
    NgayCapNhat DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_TienDo_NguoiDung FOREIGN KEY (MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_TienDo_BaiHoc FOREIGN KEY (MaBaiHoc) REFERENCES BaiHoc(MaBaiHoc) ON DELETE CASCADE,
    CONSTRAINT UQ_TienDo_NguoiDung_BaiHoc UNIQUE (MaNguoiDung, MaBaiHoc)
);
GO

-- ---------------------------------------------------------------------------------------
-- NGHIỆP VỤ 5: KIỂM TRA VÀ CẤP CHỨNG CHỈ
-- ---------------------------------------------------------------------------------------

-- 13. Bảng Bài Kiểm Tra (Trắc nghiệm theo chương hoặc Bài thi cuối khóa)
CREATE TABLE BaiKiemTra (
    MaBaiKiemTra INT IDENTITY(1,1) PRIMARY KEY,
    MaKhoaHoc INT NOT NULL,
    MaChuong INT NULL,                         -- NULL nếu là Bài thi cuối khóa
    TieuDe NVARCHAR(200) NOT NULL,
    LoaiBai NVARCHAR(30) NOT NULL DEFAULT N'TracNghiemChuong', -- N'TracNghiemChuong', N'ThiCuoiKhoa'
    ThoiGianPhut INT NOT NULL DEFAULT 15,      -- Thời gian làm bài (phút)
    DiemDat DECIMAL(5,2) NOT NULL DEFAULT 80.00, -- Điểm chuẩn để đạt (trên 100)
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_BaiKiemTra_KhoaHoc FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc) ON DELETE CASCADE,
    CONSTRAINT FK_BaiKiemTra_ChuongHoc FOREIGN KEY (MaChuong) REFERENCES ChuongHoc(MaChuong)
);
GO

-- 14. Bảng Câu Hỏi Trắc Nghiệm
CREATE TABLE CauHoi (
    MaCauHoi INT IDENTITY(1,1) PRIMARY KEY,
    MaBaiKiemTra INT NOT NULL,
    NoiDung NVARCHAR(MAX) NOT NULL,
    Diem DECIMAL(5,2) NOT NULL DEFAULT 1.00,
    CONSTRAINT FK_CauHoi_BaiKiemTra FOREIGN KEY (MaBaiKiemTra) REFERENCES BaiKiemTra(MaBaiKiemTra) ON DELETE CASCADE
);
GO

-- 15. Bảng Đáp Án
CREATE TABLE DapAn (
    MaDapAn INT IDENTITY(1,1) PRIMARY KEY,
    MaCauHoi INT NOT NULL,
    NoiDung NVARCHAR(MAX) NOT NULL,
    LaDapAnDung BIT NOT NULL DEFAULT 0,        -- 1: Đáp án đúng
    CONSTRAINT FK_DapAn_CauHoi FOREIGN KEY (MaCauHoi) REFERENCES CauHoi(MaCauHoi) ON DELETE CASCADE
);
GO

-- 16. Bảng Kết Quả Bài Thi Của Học Viên
CREATE TABLE KetQuaBaiThi (
    MaKetQua INT IDENTITY(1,1) PRIMARY KEY,
    MaBaiKiemTra INT NOT NULL,
    MaNguoiDung INT NOT NULL,
    DiemSo DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    KetQua NVARCHAR(20) NOT NULL DEFAULT N'ChuaDat', -- N'Dat', N'ChuaDat'
    NgayNop DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_KetQua_BaiKiemTra FOREIGN KEY (MaBaiKiemTra) REFERENCES BaiKiemTra(MaBaiKiemTra),
    CONSTRAINT FK_KetQua_NguoiDung FOREIGN KEY (MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung)
);
GO

-- 17. Bảng Chứng Chỉ Điện Tử (Cấp khi hoàn thành 100% bài học và Đạt bài thi cuối khóa)
CREATE TABLE ChungChi (
    MaChungChi INT IDENTITY(1,1) PRIMARY KEY,
    MaDinhDanh VARCHAR(50) NOT NULL UNIQUE,    -- Ví dụ: CC-2026-0001
    MaNguoiDung INT NOT NULL,
    MaKhoaHoc INT NOT NULL,
    MaKetQua INT NOT NULL,                     -- Điểm bài thi cuối khóa
    MaQR NVARCHAR(500) NOT NULL,               -- Link QR tra cứu chứng chỉ
    NgayCap DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_ChungChi_NguoiDung FOREIGN KEY (MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_ChungChi_KhoaHoc FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc),
    CONSTRAINT FK_ChungChi_KetQua FOREIGN KEY (MaKetQua) REFERENCES KetQuaBaiThi(MaKetQua),
    CONSTRAINT UQ_ChungChi_NguoiDung_KhoaHoc UNIQUE (MaNguoiDung, MaKhoaHoc)
);
GO

-- ---------------------------------------------------------------------------------------
-- NGHIỆP VỤ 6: ĐÁNH GIÁ KHÓA HỌC
-- ---------------------------------------------------------------------------------------

-- 18. Bảng Đánh Giá Khóa Học (Điều kiện: Tiến độ học tập >= 50%)
CREATE TABLE DanhGia (
    MaDanhGia INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT NOT NULL,
    MaKhoaHoc INT NOT NULL,
    SoSao INT NOT NULL CHECK (SoSao >= 1 AND SoSao <= 5),
    BinhLuan NVARCHAR(MAX) NULL,
    DaAn BIT NOT NULL DEFAULT 0,               -- 1: Bị Quản trị viên ẩn/kiểm duyệt
    NgayDanhGia DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_DanhGia_NguoiDung FOREIGN KEY (MaNguoiDung) REFERENCES NguoiDung(MaNguoiDung),
    CONSTRAINT FK_DanhGia_KhoaHoc FOREIGN KEY (MaKhoaHoc) REFERENCES KhoaHoc(MaKhoaHoc),
    CONSTRAINT UQ_DanhGia_NguoiDung_KhoaHoc UNIQUE (MaNguoiDung, MaKhoaHoc)
);
GO

-- =======================================================================================
-- PHẦN 2: CÁC TRIGGER RÀNG BUỘC NGHIỆP VỤ QUAN TRỌNG
-- =======================================================================================

-- Trigger 1: Ngăn không cho thêm khóa học đã sở hữu vào giỏ hàng
CREATE OR ALTER TRIGGER trg_KiemTraGioHang
ON GioHang
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        INNER JOIN DangKyKhoaHoc dk ON i.MaNguoiDung = dk.MaNguoiDung AND i.MaKhoaHoc = dk.MaKhoaHoc
    )
    BEGIN
        RAISERROR (N'Học viên đã sở hữu khóa học này, không thể thêm vào giỏ hàng!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- Trigger 2: Ràng buộc chỉ học viên hoàn thành từ 50% tiến độ trở lên mới được đánh giá
CREATE OR ALTER TRIGGER trg_KiemTraDanhGia
ON DanhGia
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        LEFT JOIN DangKyKhoaHoc dk ON i.MaNguoiDung = dk.MaNguoiDung AND i.MaKhoaHoc = dk.MaKhoaHoc
        WHERE dk.MaDangKy IS NULL OR dk.TienDoPhanTram < 50.00
    )
    BEGIN
        RAISERROR (N'Học viên phải hoàn thành ít nhất 50% tiến độ khóa học mới được quyền đánh giá!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- Trigger 3: Tự động cập nhật tỷ lệ % tiến độ vào DangKyKhoaHoc khi học xong bài học
CREATE OR ALTER TRIGGER trg_CapNhatTienDoHoc
ON TienDoBaiHoc
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(DaHoanThanh)
    BEGIN
        ;WITH ThongKeTienDo AS (
            SELECT 
                td.MaNguoiDung,
                kh.MaKhoaHoc,
                COUNT(bh.MaBaiHoc) AS TongSoBai,
                SUM(CASE WHEN td.DaHoanThanh = 1 THEN 1 ELSE 0 END) AS SoBaiHoanThanh
            FROM TienDoBaiHoc td
            INNER JOIN BaiHoc bh ON td.MaBaiHoc = bh.MaBaiHoc
            INNER JOIN ChuongHoc ch ON bh.MaChuong = ch.MaChuong
            INNER JOIN KhoaHoc kh ON ch.MaKhoaHoc = kh.MaKhoaHoc
            WHERE td.MaNguoiDung IN (SELECT DISTINCT MaNguoiDung FROM inserted)
            GROUP BY td.MaNguoiDung, kh.MaKhoaHoc
        )
        UPDATE dk
        SET 
            dk.TienDoPhanTram = CASE 
                WHEN tk.TongSoBai > 0 THEN ROUND((CAST(tk.SoBaiHoanThanh AS DECIMAL(5,2)) / tk.TongSoBai) * 100.0, 2)
                ELSE 0.00 
            END,
            dk.DaHoanThanh = CASE 
                WHEN tk.TongSoBai > 0 AND tk.SoBaiHoanThanh = tk.TongSoBai THEN 1 
                ELSE 0 
            END,
            dk.NgayHoanThanh = CASE 
                WHEN tk.TongSoBai > 0 AND tk.SoBaiHoanThanh = tk.TongSoBai AND dk.NgayHoanThanh IS NULL THEN GETDATE() 
                ELSE dk.NgayHoanThanh 
            END
        FROM DangKyKhoaHoc dk
        INNER JOIN ThongKeTienDo tk ON dk.MaNguoiDung = tk.MaNguoiDung AND dk.MaKhoaHoc = tk.MaKhoaHoc;
    END
END;
GO

-- =======================================================================================
-- PHẦN 3: CÁC THỦ TỤC LƯU TRỮ CHÍNH (STORED PROCEDURES)
-- =======================================================================================

-- SP 1: Xử lý kích hoạt khóa học khi cổng thanh toán (VNPAY/MoMo) báo thành công
CREATE OR ALTER PROCEDURE sp_XacNhanThanhToanDonHang
    @MaGiaoDich VARCHAR(50),
    @MaGiaoDichCong VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @MaDonHang INT, @MaNguoiDung INT;

        SELECT @MaDonHang = MaDonHang, @MaNguoiDung = MaNguoiDung
        FROM DonHang
        WHERE MaGiaoDich = @MaGiaoDich AND TrangThai = N'ChoThanhToan';

        IF @MaDonHang IS NULL
        BEGIN
            RAISERROR(N'Đơn hàng không tồn tại hoặc đã được xử lý trước đó!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 1. Cập nhật đơn hàng thành Đã thanh toán
        UPDATE DonHang
        SET 
            TrangThai = N'DaThanhToan',
            MaGiaoDichCong = @MaGiaoDichCong,
            NgayThanhToan = GETDATE()
        WHERE MaDonHang = @MaDonHang;

        -- 2. Kích hoạt quyền truy cập các khóa học trong đơn hàng cho học viên
        INSERT INTO DangKyKhoaHoc (MaNguoiDung, MaKhoaHoc, NgayDangKy, TienDoPhanTram, DaHoanThanh)
        SELECT @MaNguoiDung, ct.MaKhoaHoc, GETDATE(), 0.00, 0
        FROM ChiTietDonHang ct
        WHERE ct.MaDonHang = @MaDonHang
          AND NOT EXISTS (
              SELECT 1 FROM DangKyKhoaHoc dk 
              WHERE dk.MaNguoiDung = @MaNguoiDung AND dk.MaKhoaHoc = ct.MaKhoaHoc
          );

        -- 3. Xóa các khóa học đã thanh toán khỏi giỏ hàng
        DELETE FROM GioHang
        WHERE MaNguoiDung = @MaNguoiDung
          AND MaKhoaHoc IN (SELECT MaKhoaHoc FROM ChiTietDonHang WHERE MaDonHang = @MaDonHang);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =======================================================================================
-- PHẦN 4: CÁC VIEW PHỤC VỤ BÁO CÁO VÀ THỐNG KÊ (NGHIỆP VỤ 7)
-- =======================================================================================

-- 1. View Thống kê chi tiết khóa học
CREATE OR ALTER VIEW v_ThongKeKhoaHoc
AS
SELECT 
    kh.MaKhoaHoc,
    kh.TenKhoaHoc,
    dm.TenDanhMuc,
    gv.HoTen AS TenGiangVien,
    kh.Gia,
    kh.TrangThai,
    ISNULL(dk.SoHocVien, 0) AS SoHocVien,
    ISNULL(dg.DiemSaoTB, 0.0) AS DiemSaoTB,
    ISNULL(dg.SoLuotDanhGia, 0) AS SoLuotDanhGia,
    ISNULL(dt.TongDoanhThu, 0) AS TongDoanhThu
FROM KhoaHoc kh
INNER JOIN DanhMuc dm ON kh.MaDanhMuc = dm.MaDanhMuc
INNER JOIN NguoiDung gv ON kh.MaGiangVien = gv.MaNguoiDung
OUTER APPLY (
    SELECT COUNT(MaDangKy) AS SoHocVien 
    FROM DangKyKhoaHoc dk 
    WHERE dk.MaKhoaHoc = kh.MaKhoaHoc
) dk
OUTER APPLY (
    SELECT 
        ROUND(AVG(CAST(SoSao AS FLOAT)), 1) AS DiemSaoTB,
        COUNT(MaDanhGia) AS SoLuotDanhGia
    FROM DanhGia dg 
    WHERE dg.MaKhoaHoc = kh.MaKhoaHoc AND dg.DaAn = 0
) dg
OUTER APPLY (
    SELECT SUM(ct.GiaMua) AS TongDoanhThu
    FROM ChiTietDonHang ct
    INNER JOIN DonHang dh ON ct.MaDonHang = dh.MaDonHang
    WHERE ct.MaKhoaHoc = kh.MaKhoaHoc AND dh.TrangThai = N'DaThanhToan'
) dt;
GO

-- 2. View Báo cáo doanh thu Giảng viên (Đã trừ hoa hồng sàn)
CREATE OR ALTER VIEW v_BaoCaoDoanhThuGiangVien
AS
SELECT 
    gv.MaNguoiDung AS MaGiangVien,
    gv.HoTen AS TenGiangVien,
    gv.Email,
    COUNT(DISTINCT kh.MaKhoaHoc) AS SoKhoaHoc,
    COUNT(DISTINCT dk.MaDangKy) AS TongSoHocVien,
    ISNULL(SUM(ct.GiaMua), 0) AS TongDoanhThuGoc,
    ISNULL(SUM(ct.TienSan), 0) AS TienHoaHongSan,
    ISNULL(SUM(ct.TienGiangVien), 0) AS DoanhThuThucNhan
FROM NguoiDung gv
LEFT JOIN KhoaHoc kh ON gv.MaNguoiDung = kh.MaGiangVien
LEFT JOIN ChiTietDonHang ct ON kh.MaKhoaHoc = ct.MaKhoaHoc
LEFT JOIN DonHang dh ON ct.MaDonHang = dh.MaDonHang AND dh.TrangThai = N'DaThanhToan'
LEFT JOIN DangKyKhoaHoc dk ON kh.MaKhoaHoc = dk.MaKhoaHoc
WHERE gv.MaVaiTro = 2 -- Giảng viên
GROUP BY gv.MaNguoiDung, gv.HoTen, gv.Email;
GO

-- 3. View Báo cáo tổng thể cho Quản trị viên (Admin Dashboard)
CREATE OR ALTER VIEW v_BaoCaoTongQuanAdmin
AS
SELECT 
    (SELECT COUNT(*) FROM NguoiDung WHERE MaVaiTro = 3) AS TongSoHocVien,
    (SELECT COUNT(*) FROM NguoiDung WHERE MaVaiTro = 2) AS TongSoGiangVien,
    (SELECT COUNT(*) FROM KhoaHoc WHERE TrangThai = N'DaDuyet') AS TongKhoaHocHienCo,
    (SELECT COUNT(*) FROM KhoaHoc WHERE TrangThai = N'ChoDuyet') AS KhoaHocChoDuyet,
    (SELECT COUNT(*) FROM YeuCauGiangVien WHERE TrangThai = N'ChoDuyet') AS YeuCauGiangVienChoDuyet,
    (SELECT COUNT(*) FROM DonHang WHERE TrangThai = N'DaThanhToan') AS TongDonHangThanhCong,
    (SELECT ISNULL(SUM(TongTien), 0) FROM DonHang WHERE TrangThai = N'DaThanhToan') AS TongDoanhThuHeThong,
    (SELECT ISNULL(SUM(TienSan), 0) FROM ChiTietDonHang ct INNER JOIN DonHang dh ON ct.MaDonHang = dh.MaDonHang WHERE dh.TrangThai = N'DaThanhToan') AS DoanhThuHoaHongSan,
    (SELECT COUNT(*) FROM ChungChi) AS TongChungChiDaCap;
GO

-- =======================================================================================
-- PHẦN 5: DỮ LIỆU MẪU (SEED DATA ĐỦ VÀ CHUẨN ĐỂ TEST ĐẦY ĐỦ 7 NGHIỆP VỤ)
-- =======================================================================================

-- 1. Thêm Vai trò
INSERT INTO VaiTro (TenVaiTro, MoTa)
VALUES 
(N'Admin', N'Quản trị viên quản lý toàn bộ hệ thống'),
(N'GiangVien', N'Giảng viên tạo nội dung bài giảng và theo dõi doanh thu'),
(N'HocVien', N'Học viên mua khóa học, học tập và thi nhận chứng chỉ');
GO

-- 2. Thêm Người dùng mẫu
INSERT INTO NguoiDung (HoTen, Email, MatKhau, SoDienThoai, AnhDaiDien, GioiThieu, MaVaiTro, DaKichHoat, TrangThai)
VALUES 
(N'Quản Trị Viên Hệ Thống', 'admin@lms.edu.vn', '123456', '0901234567', 'https://placehold.co/150', N'Admin quản trị hệ thống đào tạo trực tuyến', 1, 1, 1),
(N'ThS. Nguyễn Văn An', 'gv.nguyenvanan@lms.edu.vn', '123456', '0912345678', 'https://placehold.co/150', N'Giảng viên Khoa CNTT với 10 năm kinh nghiệm ASP.NET Core và SQL Server', 2, 1, 1),
(N'TS. Trần Thị Bích', 'gv.tranthib@lms.edu.vn', '123456', '0923456789', 'https://placehold.co/150', N'Chuyên gia Trí tuệ Nhân tạo & Xử lý ngôn ngữ tự nhiên', 2, 1, 1),
(N'Lê Văn Cường', 'sv.levanc@student.huit.edu.vn', '123456', '0934567890', 'https://placehold.co/150', N'Sinh viên ngành CNTT đam mê Web Back-end', 3, 1, 1),
(N'Phạm Thị Dung', 'sv.phamthid@student.huit.edu.vn', '123456', '0945678901', 'https://placehold.co/150', N'Sinh viên ngành Kỹ thuật phần mềm', 3, 1, 1),
(N'Hoàng Văn Em', 'sv.hoangvane@student.huit.edu.vn', '123456', '0956789012', 'https://placehold.co/150', N'Sinh viên yêu thích AI & Machine Learning', 3, 1, 1);
GO

-- 3. Thêm Yêu cầu nâng cấp Giảng viên mẫu
INSERT INTO YeuCauGiangVien (MaNguoiDung, FileCV, FileChungChi, MoTaNangLuc, TrangThai, LyDoTuChoi, NgayDuyet)
VALUES 
(2, N'/uploads/cv/cv_nguyenvanan.pdf', N'/uploads/certs/cert_mcp.pdf', N'Thạc sĩ CNTT, 10 năm giảng dạy đại học', N'DaDuyet', NULL, DATEADD(DAY, -30, GETDATE())),
(3, N'/uploads/cv/cv_tranthib.pdf', N'/uploads/certs/cert_ai.pdf', N'Tiến sĩ Khoa học máy tính', N'DaDuyet', NULL, DATEADD(DAY, -20, GETDATE()));
GO

-- 4. Thêm Danh mục khóa học
INSERT INTO DanhMuc (TenDanhMuc, MoTa)
VALUES 
(N'Lập trình Web', N'Phát triển ứng dụng Web Front-end và Back-end với ASP.NET Core, React, Vue'),
(N'Cơ sở dữ liệu', N'Thiết kế, chuẩn hóa và tối ưu hóa truy vấn SQL Server'),
(N'Trí tuệ nhân tạo', N'Học máy Machine Learning, Deep Learning cơ bản đến nâng cao');
GO

-- 5. Thêm Khóa học
INSERT INTO KhoaHoc (TenKhoaHoc, MaDanhMuc, MaGiangVien, MoTa, Gia, AnhDaiDien, TrangThai)
VALUES 
(N'Lập trình Web hiện đại với ASP.NET Core và SQL Server', 1, 2, N'Học từ cơ bản đến nâng cao về kiến trúc MVC, Entity Framework và bảo mật Web.', 599000, 'https://placehold.co/600x400', N'DaDuyet'),
(N'Machine Learning thực chiến với Python', 3, 3, N'Khám phá các thuật toán phân lớp, hồi quy và học sâu qua các bài toán thực tế.', 799000, 'https://placehold.co/600x400', N'DaDuyet'),
(N'Tối ưu hóa và thiết kế CSDL SQL Server chuyên sâu', 2, 2, N'Nắm vững Index, Store Procedure và Transaction trong SQL Server.', 499000, 'https://placehold.co/600x400', N'BanNhap');
GO

-- 6. Thêm Chương học (Cho Khóa 1)
INSERT INTO ChuongHoc (MaKhoaHoc, TenChuong, ThuTu)
VALUES 
(1, N'Chương 1: Tổng quan và Thiết lập môi trường ASP.NET Core', 1),
(1, N'Chương 2: Thiết kế Cơ sở dữ liệu và Entity Framework Core', 2);
GO

-- 7. Thêm Bài học (Video YouTube Unlisted & Tài liệu)
INSERT INTO BaiHoc (MaChuong, TenBaiHoc, ThuTu, LoaiBaiHoc, MaVideoYoutube, ThoiLuongGiay, TrangThaiVideo, FileTaiLieu, ChoHocThu)
VALUES 
-- Chương 1
(1, N'Bài 1: Giới thiệu mô hình MVC và .NET', 1, N'Video', 'dQw4w9WgXcQ', 600, N'SanSang', NULL, 1),
(1, N'Bài 2: Hướng dẫn cài đặt Visual Studio và SQL Server', 2, N'Video', 'e-ORhEE9VVg', 900, N'SanSang', N'/materials/huong_dan_cai_dat.pdf', 0),
-- Chương 2
(2, N'Bài 3: Ánh xạ Model với Entity Framework Core', 1, N'Video', 'kJQP7kiw5Fk', 1200, N'SanSang', NULL, 0),
(2, N'Bài 4: Tài liệu lý thuyết chuẩn hóa CSDL 3NF', 2, N'TaiLieu', NULL, 300, N'SanSang', N'/materials/ly_thuyet_3nf.pdf', 0);
GO

-- 8. Thêm Đơn hàng & Chi tiết đơn hàng
INSERT INTO DonHang (MaGiaoDich, MaNguoiDung, TongTien, PhuongThuc, TrangThai, MaGiaoDichCong, NgayThanhToan)
VALUES 
('DH2026100101', 4, 599000, N'VNPAY', N'DaThanhToan', 'VNPAY_TRANS_8899', DATEADD(DAY, -10, GETDATE())),
('DH2026100502', 5, 599000, N'MOMO', N'DaThanhToan', 'MOMO_TRANS_5566', DATEADD(DAY, -5, GETDATE())),
('DH2026101503', 6, 799000, N'VNPAY', N'ChoThanhToan', NULL, NULL);
GO

INSERT INTO ChiTietDonHang (MaDonHang, MaKhoaHoc, GiaMua, TyLeHoaHong, TienSan, TienGiangVien)
VALUES 
-- Đơn hàng 1 (Cường mua Khóa 1): Hoa hồng sàn 20% = 119.800đ, Giảng viên nhận 479.200đ
(1, 1, 599000, 20.00, 119800, 479200),
-- Đơn hàng 2 (Dung mua Khóa 1)
(2, 1, 599000, 20.00, 119800, 479200),
-- Đơn hàng 3 (Em mua Khóa 2, đang chờ thanh toán)
(3, 2, 799000, 20.00, 159800, 639200);
GO

-- 9. Thêm Học viên Đăng ký khóa học (DangKyKhoaHoc)
INSERT INTO DangKyKhoaHoc (MaNguoiDung, MaKhoaHoc, NgayDangKy, TienDoPhanTram, DaHoanThanh, NgayHoanThanh)
VALUES 
-- Cường đã học xong 100% bài học Khóa 1
(4, 1, DATEADD(DAY, -10, GETDATE()), 100.00, 1, DATEADD(DAY, -2, GETDATE())),
-- Dung đã học 50% Khóa 1 (2/4 bài học) -> Đủ điều kiện đánh giá
(5, 1, DATEADD(DAY, -5, GETDATE()), 50.00, 0, NULL);
GO

-- 10. Thêm Tiến độ học tập từng bài (TienDoBaiHoc)
INSERT INTO TienDoBaiHoc (MaNguoiDung, MaBaiHoc, ThoiGianDaXem, ViTriDung, DaHoanThanh)
VALUES 
-- Cường hoàn thành cả 4 bài
(4, 1, 600, 600, 1),
(4, 2, 900, 900, 1),
(4, 3, 1200, 1200, 1),
(4, 4, 300, 300, 1),
-- Dung hoàn thành 2 bài đầu
(5, 1, 600, 600, 1),
(5, 2, 900, 900, 1);
GO

-- 11. Thêm Bài kiểm tra (1 Bài theo chương, 1 Bài thi cuối khóa mở khi học xong 100%)
INSERT INTO BaiKiemTra (MaKhoaHoc, MaChuong, TieuDe, LoaiBai, ThoiGianPhut, DiemDat)
VALUES 
(1, 1, N'Trắc nghiệm củng cố Chương 1', N'TracNghiemChuong', 10, 80.00),
(1, NULL, N'BÀI THI TỔNG KẾT CUỐI KHÓA ASP.NET CORE', N'ThiCuoiKhoa', 20, 80.00);
GO

-- 12. Thêm Câu hỏi & Đáp án cho Bài thi cuối khóa
INSERT INTO CauHoi (MaBaiKiemTra, NoiDung, Diem)
VALUES 
(2, N'Trong kiến trúc MVC, thành phần nào tiếp nhận Request và gọi tầng Business Logic?', 5.00),
(2, N'Lệnh nào trong Package Manager Console dùng để cập nhật Schema vào CSDL SQL Server?', 5.00);
GO

INSERT INTO DapAn (MaCauHoi, NoiDung, LaDapAnDung)
VALUES 
(1, N'Model', 0),
(1, N'Controller', 1),
(1, N'View', 0),
(2, N'Add-Migration', 0),
(2, N'Update-Database', 1);
GO

-- 13. Thêm Kết quả làm bài thi của học viên Cường (Đạt 10/10 điểm bài thi cuối khóa)
INSERT INTO KetQuaBaiThi (MaBaiKiemTra, MaNguoiDung, DiemSo, KetQua, NgayNop)
VALUES 
(2, 4, 10.00, N'Dat', DATEADD(DAY, -1, GETDATE()));
GO

-- 14. Thêm Chứng chỉ điện tử cho Cường (kèm mã QR tra cứu)
INSERT INTO ChungChi (MaDinhDanh, MaNguoiDung, MaKhoaHoc, MaKetQua, MaQR, NgayCap)
VALUES 
('CC-2026-IT-0001', 4, 1, 1, N'https://lms.huit.edu.vn/xac-thuc-chung-chi?ma=CC-2026-IT-0001', DATEADD(DAY, -1, GETDATE()));
GO

-- 15. Thêm Đánh giá khóa học
-- Cường học 100% (>= 50%) và Dung học 50% (>= 50%) -> Cả 2 đều thỏa điều kiện đánh giá
INSERT INTO DanhGia (MaNguoiDung, MaKhoaHoc, SoSao, BinhLuan, DaAn)
VALUES 
(4, 1, 5, N'Khóa học rất hay, bài giảng chi tiết và dễ hiểu, thực hành sát với thực tế doanh nghiệp!', 0),
(5, 1, 5, N'Nội dung chuẩn chỉ, video YouTube nhúng xem rất mượt mà và tài liệu kèm theo đầy đủ.', 0);
GO

-- =======================================================================================
-- KIỂM TRA NHANH KẾT QUẢ TRUY VẤN CSDL
-- =======================================================================================
PRINT N'======================================================================';
PRINT N'ĐÃ TẠO DATABASE [QuanLyLopHocTrucTuyen] VÀ KHỞI TẠO DỮ LIỆU THÀNH CÔNG!';
PRINT N'======================================================================';

-- 1. Xem Thống kê Khóa học
SELECT * FROM v_ThongKeKhoaHoc;

-- 2. Xem Báo cáo Doanh thu Giảng viên
SELECT * FROM v_BaoCaoDoanhThuGiangVien;

-- 3. Xem Tổng quan Báo cáo Quản trị viên
SELECT * FROM v_BaoCaoTongQuanAdmin;
GO
