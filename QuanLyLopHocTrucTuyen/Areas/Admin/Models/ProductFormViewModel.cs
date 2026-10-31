using System.ComponentModel.DataAnnotations;

namespace QuanLyLopHocTrucTuyen.Areas.Admin.Models
{
    public class ProductFormViewModel
    {
        public int MaKhoaHoc { get; set; }

        [Display(Name = "Tên khóa học")]
        [Required(ErrorMessage = "Vui lòng nhập tên khóa học")]
        [StringLength(200, ErrorMessage = "Tên khóa học tối đa 200 ký tự")]
        public string TenKhoaHoc { get; set; } = string.Empty;

        [Display(Name = "Danh mục")]
        [Required(ErrorMessage = "Vui lòng chọn danh mục")]
        public int? MaDanhMuc { get; set; }

        [Display(Name = "Giảng viên")]
        [Required(ErrorMessage = "Vui lòng chọn giảng viên")]
        public int? MaGiangVien { get; set; }

        [Display(Name = "Mô tả")]
        public string? MoTa { get; set; }

        [Display(Name = "Giá (VNĐ)")]
        [Range(0, 1_000_000_000, ErrorMessage = "Giá phải từ 0 đến 1.000.000.000")]
        public decimal Gia { get; set; }

        [Display(Name = "Ảnh đại diện (URL)")]
        [StringLength(500)]
        public string? AnhDaiDien { get; set; }

        [Display(Name = "Trạng thái")]
        [Required]
        public string TrangThai { get; set; } = "BanNhap";

        [Display(Name = "Lý do từ chối")]
        [StringLength(500)]
        public string? LyDoTuChoi { get; set; }
    }
}

