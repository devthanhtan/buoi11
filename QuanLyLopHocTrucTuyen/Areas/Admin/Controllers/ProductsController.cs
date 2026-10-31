using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using QuanLyLopHocTrucTuyen.Areas.Admin.Models;
using QuanLyLopHocTrucTuyen.Data;
using QuanLyLopHocTrucTuyen.Models.Entities;

namespace QuanLyLopHocTrucTuyen.Areas.Admin.Controllers
{
    [Area("Admin")]
    public class ProductsController : Controller
    {
        private readonly AppDbContext _context;

        // Danh sách trạng thái khóa học hợp lệ (theo CSDL)
        private static readonly Dictionary<string, string> TrangThaiKhoaHoc = new()
        {
            ["BanNhap"] = "Bản nháp",
            ["ChoDuyet"] = "Chờ duyệt",
            ["DaDuyet"] = "Đã duyệt",
            ["TuChoi"] = "Từ chối"
        };

        public ProductsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: /Admin/Products?keyword=...&maDanhMuc=...
        public async Task<IActionResult> Index(string? keyword, int? maDanhMuc)
        {
            var query = _context.KhoaHocs
                .Include(k => k.DanhMuc)
                .Include(k => k.GiangVien)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                keyword = keyword.Trim();
                query = query.Where(k => k.TenKhoaHoc.Contains(keyword));
            }

            if (maDanhMuc.HasValue)
            {
                query = query.Where(k => k.MaDanhMuc == maDanhMuc.Value);
            }

            ViewBag.Keyword = keyword;
            ViewBag.DanhMucs = new SelectList(await _context.DanhMucs.ToListAsync(), "MaDanhMuc", "TenDanhMuc", maDanhMuc);

            var products = await query.OrderByDescending(k => k.NgayTao).ToListAsync();
            return View(products);
        }

        // GET: /Admin/Products/Details/5
        public async Task<IActionResult> Details(int id)
        {
            var product = await _context.KhoaHocs
                .Include(k => k.DanhMuc)
                .Include(k => k.GiangVien)
                .FirstOrDefaultAsync(k => k.MaKhoaHoc == id);

            if (product == null) return NotFound();
            return View(product);
        }

        // GET: /Admin/Products/Create
        public async Task<IActionResult> Create()
        {
            var vm = new ProductFormViewModel();
            await LoadDropdownsAsync(vm);
            return View(vm);
        }

        // POST: /Admin/Products/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(ProductFormViewModel vm)
        {
            await ValidateAsync(vm);

            if (!ModelState.IsValid)
            {
                await LoadDropdownsAsync(vm);
                return View(vm);
            }

            var product = new KhoaHoc
            {
                TenKhoaHoc = vm.TenKhoaHoc.Trim(),
                MaDanhMuc = vm.MaDanhMuc!.Value,
                MaGiangVien = vm.MaGiangVien!.Value,
                MoTa = vm.MoTa,
                Gia = vm.Gia,
                AnhDaiDien = vm.AnhDaiDien,
                TrangThai = vm.TrangThai,
                LyDoTuChoi = vm.TrangThai == "TuChoi" ? vm.LyDoTuChoi : null,
                NgayTao = DateTime.Now
            };

            _context.KhoaHocs.Add(product);
            await _context.SaveChangesAsync();

            TempData["Success"] = $"Đã thêm khóa học \"{product.TenKhoaHoc}\".";
            return RedirectToAction(nameof(Index));
        }

        // GET: /Admin/Products/Edit/5
        public async Task<IActionResult> Edit(int id)
        {
            var product = await _context.KhoaHocs.FindAsync(id);
            if (product == null) return NotFound();

            var vm = new ProductFormViewModel
            {
                MaKhoaHoc = product.MaKhoaHoc,
                TenKhoaHoc = product.TenKhoaHoc,
                MaDanhMuc = product.MaDanhMuc,
                MaGiangVien = product.MaGiangVien,
                MoTa = product.MoTa,
                Gia = product.Gia,
                AnhDaiDien = product.AnhDaiDien,
                TrangThai = product.TrangThai,
                LyDoTuChoi = product.LyDoTuChoi
            };

            await LoadDropdownsAsync(vm);
            return View(vm);
        }

        // POST: /Admin/Products/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, ProductFormViewModel vm)
        {
            if (id != vm.MaKhoaHoc) return BadRequest();

            var product = await _context.KhoaHocs.FindAsync(id);
            if (product == null) return NotFound();

            await ValidateAsync(vm);

            if (!ModelState.IsValid)
            {
                await LoadDropdownsAsync(vm);
                return View(vm);
            }

            product.TenKhoaHoc = vm.TenKhoaHoc.Trim();
            product.MaDanhMuc = vm.MaDanhMuc!.Value;
            product.MaGiangVien = vm.MaGiangVien!.Value;
            product.MoTa = vm.MoTa;
            product.Gia = vm.Gia;
            product.AnhDaiDien = vm.AnhDaiDien;
            product.TrangThai = vm.TrangThai;
            product.LyDoTuChoi = vm.TrangThai == "TuChoi" ? vm.LyDoTuChoi : null;

            await _context.SaveChangesAsync();

            TempData["Success"] = $"Đã cập nhật khóa học \"{product.TenKhoaHoc}\".";
            return RedirectToAction(nameof(Index));
        }

        // POST: /Admin/Products/Delete/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            var product = await _context.KhoaHocs.FindAsync(id);
            if (product == null) return NotFound();

            try
            {
                _context.KhoaHocs.Remove(product);
                await _context.SaveChangesAsync();
                TempData["Success"] = $"Đã xóa khóa học \"{product.TenKhoaHoc}\".";
            }
            catch (DbUpdateException)
            {
                // Khóa học đã có đơn hàng / học viên đăng ký / đánh giá / chứng chỉ
                TempData["Error"] = $"Không thể xóa \"{product.TenKhoaHoc}\" vì đã có học viên đăng ký, đơn hàng hoặc đánh giá liên quan.";
            }

            return RedirectToAction(nameof(Index));
        }

        private async Task ValidateAsync(ProductFormViewModel vm)
        {
            if (!TrangThaiKhoaHoc.ContainsKey(vm.TrangThai))
            {
                ModelState.AddModelError(nameof(vm.TrangThai), "Trạng thái không hợp lệ");
            }

            if (vm.TrangThai == "TuChoi" && string.IsNullOrWhiteSpace(vm.LyDoTuChoi))
            {
                ModelState.AddModelError(nameof(vm.LyDoTuChoi), "Vui lòng nhập lý do từ chối");
            }

            if (vm.MaDanhMuc.HasValue && !await _context.DanhMucs.AnyAsync(d => d.MaDanhMuc == vm.MaDanhMuc))
            {
                ModelState.AddModelError(nameof(vm.MaDanhMuc), "Danh mục không tồn tại");
            }

            if (vm.MaGiangVien.HasValue && !await _context.NguoiDungs.AnyAsync(n => n.MaNguoiDung == vm.MaGiangVien && n.MaVaiTro == 2))
            {
                ModelState.AddModelError(nameof(vm.MaGiangVien), "Giảng viên không hợp lệ");
            }
        }

        private async Task LoadDropdownsAsync(ProductFormViewModel vm)
        {
            ViewBag.DanhMucs = new SelectList(await _context.DanhMucs.ToListAsync(), "MaDanhMuc", "TenDanhMuc", vm.MaDanhMuc);
            ViewBag.GiangViens = new SelectList(
                await _context.NguoiDungs.Where(n => n.MaVaiTro == 2).OrderBy(n => n.HoTen).ToListAsync(),
                "MaNguoiDung", "HoTen", vm.MaGiangVien);
            ViewBag.TrangThais = new SelectList(TrangThaiKhoaHoc, "Key", "Value", vm.TrangThai);
        }
    }
}
