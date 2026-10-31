using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyLopHocTrucTuyen.Models.Entities
{
    [Table("KhoaHoc")]
    public class KhoaHoc
    {
        [Key]
        public int MaKhoaHoc { get; set; }

        [Required, StringLength(200)]
        public string TenKhoaHoc { get; set; } = string.Empty;

        public int MaDanhMuc { get; set; }

        public int MaGiangVien { get; set; }

        public string? MoTa { get; set; }

        [Column(TypeName = "decimal(18,0)")]
        public decimal Gia { get; set; }

        [StringLength(500)]
        public string? AnhDaiDien { get; set; }

        [StringLength(30)]
        public string TrangThai { get; set; } = "BanNhap";

        [StringLength(500)]
        public string? LyDoTuChoi { get; set; }

        public DateTime NgayTao { get; set; }

        [ForeignKey(nameof(MaDanhMuc))]
        public DanhMuc? DanhMuc { get; set; }

        [ForeignKey(nameof(MaGiangVien))]
        public NguoiDung? GiangVien { get; set; }
    }
}

