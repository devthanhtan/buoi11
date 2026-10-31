using QuanLyLopHocTrucTuyen.Models.Entities;

namespace QuanLyLopHocTrucTuyen.Areas.Admin.Models
{
    public class DashboardViewModel
    {
        public int TongNguoiDung { get; set; }
        public int TongGiangVien { get; set; }
        public int TongHocVien { get; set; }
        public int TongKhoaHoc { get; set; }
        public List<KhoaHoc> KhoaHocMoiNhat { get; set; } = new();
    }
}

