# 📊 TÓM TẮT THUYẾT TRÌNH: CHỨC NĂNG TÍNH TIỀN, GIỎ HÀNG & VOUCHER

---

## 1️⃣ GIỎ HÀNG (CART)

**Định nghĩa**: Giỏ hàng giúp lưu trữ các sản phẩm người dùng muốn mua

**Chức năng chính:**
- ✅ Thêm sản phẩm vào giỏ
- ✅ Chỉnh sửa số lượng & tùy chỉnh (Size, Topping, Sugar, Ice)
- ✅ Xóa sản phẩm khỏi giỏ
- ✅ Lưu dữ liệu trên thiết bị (persistent storage)

**Tùy chỉnh sản phẩm:**
- Size: S / M / L
- Đường: 0% / 30% / 50% / 70% / 100%
- Đá: Không đá / 50% / 100%
- Topping: Trân châu / Thạch vải / Kem Cheese

---

## 2️⃣ TÍNH TIỀN (PRICING)

**Công thức tính giá:**

```
Giá item = Giá sản phẩm + Giá Size + (Giá Topping × Số topping)

Giá Size:
  • S/M: +0đ
  • L: +7,000đ

Giá Topping:
  • Mỗi loại: +5,000đ

Ví dụ:
  Trà sữa 30k + Size L (+7k) + 2 Topping (+5k×2) = 47k/cái
```

---

## 3️⃣ ĐƠN HÀNG (ORDER TOTAL)

**Công thức tính tổng:**

```
Subtotal (Tổng tiền hàng)
    = Σ (Giá item × Số lượng)

    ↓

Discount (Tiền giảm từ Voucher)
    = Tiền voucher (nếu áp dụng được)

    ↓

Grand Total (Thành tiền)
    = Subtotal + Phí ship (20,000đ) - Discount
```

**Ví dụ cực kỳ đơn giản:**
- 2× Trà sữa (47k) = 94,000đ
- 1× Cà phê (25k) = 25,000đ
- **Subtotal = 119,000đ**
- Phí ship = 20,000đ
- Giảm giá = 20,000đ (nếu có voucher)
- **TỔNG = 119,000đ**

---

## 4️⃣ VOUCHER (MÃ GIẢM GIÁ)

**Định nghĩa**: Mã khuyến mãi để giảm giá đơn hàng

**Điều kiện áp dụng:**
1. Mã voucher còn hoạt động
2. Ngày hôm nay < Ngày hết hạn
3. **Tổng tiền hàng ≥ Đơn tối thiểu**

**Quy tắc:**
- Giảm giá = **Cố định** (ví dụ: 20k, 50k, ...)
- **Không áp dụng** nếu đơn hàng < tối thiểu

**Ví dụ Voucher:**
```
Voucher "SAVE20"
  • Giảm: 20,000đ
  • Đơn tối thiểu: 100,000đ
  • Còn: 15 ngày

  → Đơn 119k ✅ Áp dụng
  → Đơn 80k ❌ Không đủ điều kiện
```

---

## 5️⃣ QUY TRÌNH MUA HÀNG

```
1. Xem menu chính
   ↓
2. Chọn sản phẩm → Cấu hình chi tiết → Thêm vào giỏ
   ↓
3. Vào trang GIỎ HÀNG
   • Xem danh sách items
   • Có thể chỉnh sửa (nhấn item)
   • Thay đổi số lượng
   ↓
4. Nhập Voucher (tùy chọn)
   ↓
5. Chọn địa chỉ giao hàng
   ↓
6. Xem tóm tắt:
   • Subtotal
   • Phí ship: 20,000đ
   • Tiền giảm (nếu có)
   • TỔNG TIỀN
   ↓
7. Đặt hàng
```

---

## 🎯 CÁC TÍNH NĂNG NỔI BẬT

✨ **Chỉnh sửa item trong giỏ**
- Nhấn vào item → Dialog mở
- Thay đổi Size, Topping, Sugar, Ice
- Giá tự động cập nhật

💾 **Lưu dữ liệu**
- Giỏ hàng lưu vào thiết bị
- Khi bật lại app vẫn còn

🎨 **Animation mượt**
- Dialog mở với effect zoom + fade (300ms)

---

## 📊 BẢNG TÓMLƯỢC

| Thành phần | Giá trị |
|-----------|--------|
| Giá Size L | +7,000đ |
| Giá Topping | +5,000đ/loại |
| Phí ship | 20,000đ (cố định) |
| Voucher | Cố định (20k-50k,...) |
| Lưu trữ | Local device (SharedPreferences) |

---

## ❓ QA NGẮN

**Q: Có cộng tiền Size + Topping không?**
A: Có. Giá item = Giá cơ bản + Size + Topping

**Q: Sugar & Ice có tính tiền không?**
A: Không. Đó chỉ là tùy chọn, không tính phí

**Q: Voucher có thể dùng nhiều lần không?**
A: Có thể, nhưng mỗi lần phải thỏa điều kiện

**Q: Nếu hủy voucher có hoàn lại tiền không?**
A: Không. Sẽ tính lại tổng tiền mà không voucher

---

**✏️ Ghi chú**: 
- Dễ nhớ, dễ trình bày
- Dùng ví dụ cụ thể để minh họa
- Nhấn mạnh: Subtotal → +Ship → -Voucher = TỔNG
