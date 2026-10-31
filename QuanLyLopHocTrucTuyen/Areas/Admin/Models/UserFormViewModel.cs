using System.ComponentModel.DataAnnotations;

namespace QuanLyLopHocTrucTuyen.Areas.Admin.Models
{
    public class UserFormViewModel
    {
        public int MaNguoiDung { get; set; }

        [Display(Name = "Họ tên")]
        [Required(ErrorMessage = "Vui lòng nhập họ tên")]
        [StringLength(100, ErrorMessage = "Họ tên tối đa 100 ký tự")]
        public string HoTen { get; set; } = string.Empty;

        [Display(Name = "Email")]
        [Required(ErrorMessage = "Vui lòng nhập email")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ")]
        [StringLength(100)]
        public string Email { get; set; } = string.Empty;

        [Display(Name = "Mật khẩu")]
        [DataType(DataType.Password)]
        [StringLength(255, MinimumLength = 6, ErrorMessage = "Mật khẩu tối thiểu 6 ký tự")]
        public string? MatKhau { get; set; }

        [Display(Name = "Số điện thoại")]
        [Phone(ErrorMessage = "Số điện thoại không hợp lệ")]
        [StringLength(20)]
        public string? SoDienThoai { get; set; }

        [Display(Name = "Ảnh đại diện (URL)")]
        [StringLength(500)]
        public string? AnhDaiDien { get; set; }

        [Display(Name = "Giới thiệu")]
        public string? GioiThieu { get; set; }

        [Display(Name = "Vai trò")]
        [Required(ErrorMessage = "Vui lòng chọn vai trò")]
        public int MaVaiTro { get; set; } = 3;

        [Display(Name = "Đã kích hoạt")]
        public bool DaKichHoat { get; set; } = true;

        [Display(Name = "Hoạt động")]
        public bool TrangThai { get; set; } = true;
    }
}

