using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QuanLyLopHocTrucTuyen.Models.Entities
{
    [Table("DanhMuc")]
    public class DanhMuc
    {
        [Key]
        public int MaDanhMuc { get; set; }

        [Required, StringLength(100)]
        public string TenDanhMuc { get; set; } = string.Empty;

        [StringLength(255)]
        public string? MoTa { get; set; }

        public ICollection<KhoaHoc> KhoaHocs { get; set; } = new List<KhoaHoc>();
    }
}

