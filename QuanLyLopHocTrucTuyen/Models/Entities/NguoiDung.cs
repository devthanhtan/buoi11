using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyLopHocTrucTuyen.Models.Entities
{
    [Table("NguoiDung")]
    public class NguoiDung
    {
        [Key]
        public int MaNguoiDung { get; set; }

        [Required, StringLength(100)]
        public string HoTen { get; set; } = string.Empty;

        [Required, StringLength(100)]
        public string Email { get; set; } = string.Empty;

        [StringLength(255)]
        public string? MatKhau { get; set; }

        [StringLength(20)]
        public string? SoDienThoai { get; set; }

        [StringLength(500)]
        public string? AnhDaiDien { get; set; }

        public string? GioiThieu { get; set; }

        public int MaVaiTro { get; set; }

        [StringLength(50)]
        public string PhuongThucDangNhap { get; set; } = "Local";

        public bool DaKichHoat { get; set; }

        public bool TrangThai { get; set; }

        public DateTime NgayTao { get; set; }

        [ForeignKey(nameof(MaVaiTro))]
        public VaiTro? VaiTro { get; set; }

        public ICollection<KhoaHoc> KhoaHocs { get; set; } = new List<KhoaHoc>();
    }
}

