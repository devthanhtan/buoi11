using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuanLyLopHocTrucTuyen.Areas.Admin.Models;
using QuanLyLopHocTrucTuyen.Data;

namespace QuanLyLopHocTrucTuyen.Areas.Admin.Controllers
{
    [Area("Admin")]
    public class DashboardController : Controller
    {
        private readonly AppDbContext _context;

        public DashboardController(AppDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            var vm = new DashboardViewModel
            {
                TongNguoiDung = await _context.NguoiDungs.CountAsync(),
                TongGiangVien = await _context.NguoiDungs.CountAsync(n => n.MaVaiTro == 2),
                TongHocVien = await _context.NguoiDungs.CountAsync(n => n.MaVaiTro == 3),
                TongKhoaHoc = await _context.KhoaHocs.CountAsync(),
                KhoaHocMoiNhat = await _context.KhoaHocs
                    .Include(k => k.DanhMuc)
                    .Include(k => k.GiangVien)
                    .OrderByDescending(k => k.NgayTao)
                    .Take(5)
                    .ToListAsync()
            };
            return View(vm);
        }
    }
}

