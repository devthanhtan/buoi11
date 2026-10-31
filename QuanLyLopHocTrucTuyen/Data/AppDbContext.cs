using Microsoft.EntityFrameworkCore;
using QuanLyLopHocTrucTuyen.Models.Entities;

namespace QuanLyLopHocTrucTuyen.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<VaiTro> VaiTros => Set<VaiTro>();
        public DbSet<NguoiDung> NguoiDungs => Set<NguoiDung>();
        public DbSet<DanhMuc> DanhMucs => Set<DanhMuc>();
        public DbSet<KhoaHoc> KhoaHocs => Set<KhoaHoc>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<NguoiDung>()
                .HasOne(n => n.VaiTro)
                .WithMany(v => v.NguoiDungs)
                .HasForeignKey(n => n.MaVaiTro);

            modelBuilder.Entity<KhoaHoc>()
                .HasOne(k => k.GiangVien)
                .WithMany(n => n.KhoaHocs)
                .HasForeignKey(k => k.MaGiangVien);

            modelBuilder.Entity<KhoaHoc>()
                .HasOne(k => k.DanhMuc)
                .WithMany(d => d.KhoaHocs)
                .HasForeignKey(k => k.MaDanhMuc);
        }
    }
}

