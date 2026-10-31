using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using QuanLyLopHocTrucTuyen.Areas.Admin.Models;
using QuanLyLopHocTrucTuyen.Data;
using QuanLyLopHocTrucTuyen.Models.Entities;

namespace QuanLyLopHocTrucTuyen.Areas.Admin.Controllers
{
    [Area("Admin")]
    public class UsersController : Controller
    {
        private readonly AppDbContext _context;

        public UsersController(AppDbContext context)
        {
            _context = context;
        }

        // GET: /Admin/Users?keyword=...&maVaiTro=...
        public async Task<IActionResult> Index(string? keyword, int? maVaiTro)
        {
            var query = _context.NguoiDungs.Include(n => n.VaiTro).AsQueryable();

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                keyword = keyword.Trim();
                query = query.Where(n => n.HoTen.Contains(keyword) || n.Email.Contains(keyword));
            }

            if (maVaiTro.HasValue)
            {
                query = query.Where(n => n.MaVaiTro == maVaiTro.Value);
            }

            ViewBag.Keyword = keyword;
            ViewBag.VaiTros = new SelectList(await _context.VaiTros.ToListAsync(), "MaVaiTro", "TenVaiTro", maVaiTro);

            var users = await query.OrderBy(n => n.MaNguoiDung).ToListAsync();
            return View(users);
        }

        // GET: /Admin/Users/Details/5
        public async Task<IActionResult> Details(int id)
        {
            var user = await _context.NguoiDungs
                .Include(n => n.VaiTro)
                .Include(n => n.KhoaHocs)
                .FirstOrDefaultAsync(n => n.MaNguoiDung == id);

            if (user == null) return NotFound();
            return View(user);
        }

        // GET: /Admin/Users/Create
        public async Task<IActionResult> Create()
        {
            await LoadVaiTrosAsync();
            return View(new UserFormViewModel());
        }

        // POST: /Admin/Users/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(UserFormViewModel vm)
        {
            if (string.IsNullOrWhiteSpace(vm.MatKhau))
            {
                ModelState.AddModelError(nameof(vm.MatKhau), "Vui lòng nhập mật khẩu");
            }

            if (await _context.NguoiDungs.AnyAsync(n => n.Email == vm.Email))
            {
                ModelState.AddModelError(nameof(vm.Email), "Email này đã được sử dụng");
            }

            if (!ModelState.IsValid)
            {
                await LoadVaiTrosAsync(vm.MaVaiTro);
                return View(vm);
            }

            var user = new NguoiDung
            {
                HoTen = vm.HoTen.Trim(),
                Email = vm.Email.Trim(),
                MatKhau = vm.MatKhau,
                SoDienThoai = vm.SoDienThoai,
                AnhDaiDien = vm.AnhDaiDien,
                GioiThieu = vm.GioiThieu,
                MaVaiTro = vm.MaVaiTro,
                PhuongThucDangNhap = "Local",
                DaKichHoat = vm.DaKichHoat,
                TrangThai = vm.TrangThai,
                NgayTao = DateTime.Now
            };

            _context.NguoiDungs.Add(user);
            await _context.SaveChangesAsync();

            TempData["Success"] = $"Đã thêm người dùng \"{user.HoTen}\".";
            return RedirectToAction(nameof(Index));
        }

        // GET: /Admin/Users/Edit/5
        public async Task<IActionResult> Edit(int id)
        {
            var user = await _context.NguoiDungs.FindAsync(id);
            if (user == null) return NotFound();

            var vm = new UserFormViewModel
            {
                MaNguoiDung = user.MaNguoiDung,
                HoTen = user.HoTen,
                Email = user.Email,
                SoDienThoai = user.SoDienThoai,
                AnhDaiDien = user.AnhDaiDien,
                GioiThieu = user.GioiThieu,
                MaVaiTro = user.MaVaiTro,
                DaKichHoat = user.DaKichHoat,
                TrangThai = user.TrangThai
            };

            await LoadVaiTrosAsync(vm.MaVaiTro);
            return View(vm);
        }

        // POST: /Admin/Users/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, UserFormViewModel vm)
        {
            if (id != vm.MaNguoiDung) return BadRequest();

            var user = await _context.NguoiDungs.FindAsync(id);
            if (user == null) return NotFound();

            if (await _context.NguoiDungs.AnyAsync(n => n.Email == vm.Email && n.MaNguoiDung != id))
            {
                ModelState.AddModelError(nameof(vm.Email), "Email này đã được sử dụng");
            }

            if (!ModelState.IsValid)
            {
                await LoadVaiTrosAsync(vm.MaVaiTro);
                return View(vm);
            }

            user.HoTen = vm.HoTen.Trim();
            user.Email = vm.Email.Trim();
            user.SoDienThoai = vm.SoDienThoai;
            user.AnhDaiDien = vm.AnhDaiDien;
            user.GioiThieu = vm.GioiThieu;
            user.MaVaiTro = vm.MaVaiTro;
            user.DaKichHoat = vm.DaKichHoat;
            user.TrangThai = vm.TrangThai;

            // Chỉ đổi mật khẩu khi người dùng nhập mật khẩu mới
            if (!string.IsNullOrWhiteSpace(vm.MatKhau))
            {
                user.MatKhau = vm.MatKhau;
            }

            await _context.SaveChangesAsync();

            TempData["Success"] = $"Đã cập nhật người dùng \"{user.HoTen}\".";
            return RedirectToAction(nameof(Index));
        }

        // POST: /Admin/Users/Delete/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            var user = await _context.NguoiDungs.FindAsync(id);
            if (user == null) return NotFound();

            try
            {
                _context.NguoiDungs.Remove(user);
                await _context.SaveChangesAsync();
                TempData["Success"] = $"Đã xóa người dùng \"{user.HoTen}\".";
            }
            catch (DbUpdateException)
            {
                // Người dùng đang có dữ liệu liên quan (khóa học, đơn hàng, đăng ký,...)
                TempData["Error"] = $"Không thể xóa \"{user.HoTen}\" vì đang có dữ liệu liên quan (khóa học, đơn hàng, đăng ký học...). Hãy khóa tài khoản thay vì xóa.";
            }

            return RedirectToAction(nameof(Index));
        }

        // POST: /Admin/Users/ToggleStatus/5  (Khóa / Mở khóa tài khoản)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ToggleStatus(int id)
        {
            var user = await _context.NguoiDungs.FindAsync(id);
            if (user == null) return NotFound();

            user.TrangThai = !user.TrangThai;
            await _context.SaveChangesAsync();

            TempData["Success"] = user.TrangThai
                ? $"Đã mở khóa tài khoản \"{user.HoTen}\"."
                : $"Đã khóa tài khoản \"{user.HoTen}\".";
            return RedirectToAction(nameof(Index));
        }

        private async Task LoadVaiTrosAsync(int? selected = null)
        {
            ViewBag.VaiTros = new SelectList(await _context.VaiTros.ToListAsync(), "MaVaiTro", "TenVaiTro", selected);
        }
    }
}
