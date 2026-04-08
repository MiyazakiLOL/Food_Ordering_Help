# 📋 TỔNG HỢP CHỨC NĂNG: TÍNH TIỀN, GIỎ HÀNG & VOUCHER

## 1️⃣ CHỨC NĂNG GIỎ HÀNG (Cart)

### Lưu trữ dữ liệu
- **Nơi lưu**: SharedPreferences (bộ nhớ thiết bị)
- **Dữ liệu lưu**:
  - Danh sách items trong giỏ
  - Ghi chú đơn hàng (order note)
  - Persisted data (không mất khi đóng app)

### Chức năng chính
- ✅ **Thêm item**: Tự động gộp nếu cùng sản phẩm & customization
- ✅ **Cập nhật số lượng**: Tăng/giảm quantity
- ✅ **Xóa item**: Xoá từng item hoặc clear hết
- ✅ **Chỉnh sửa tùy chỉnh**: Thay đổi size, topping, sugar, ice
- ✅ **Ghi chú**: Thêm ghi chú cho đơn hàng

### Thông tin trong item
```
CartItemModel:
├── item (MenuItemModel) - Thông tin sản phẩm
│   ├── id
│   ├── name - Tên món
│   ├── price - Giá gốc
│   ├── imageUrl
│   └── description
│
├── customization (FoodCustomization) - Tùy chỉnh
│   ├── size (S/M/L)
│   ├── sugar (0%, 30%, 50%, 70%, 100%)
│   ├── ice (Không đá, 50%, 100%)
│   └── toppings (Trân châu, Thạch vải, Kem Cheese)
│
└── quantity - Số lượng
```

---

## 2️⃣ CHỨC NĂNG TÍNH TIỀN (Pricing)

### Công thức tính giá từng item
```
Giá cơ bản = Giá sản phẩm (price)

Giá thêm từ Size:
├── Size S: +0đ
├── Size M: +0đ
└── Size L: +7,000đ

Giá thêm từ Topping:
└── Mỗi topping: +5,000đ

Giá 1 item = Giá cơ bản + Giá Size + (Giá Topping × Số topping)
              (bỏ qua Sugar & Ice vì là optional chỉ để chọn mức độ)

Giá chung = (Giá 1 item) × Số lượng

Ví dụ:
- Trà sữa 30k + Size L (7k) + 2 Topping (5k × 2) = 47k/cup
- Nếu mua 3 cup = 47k × 3 = 141k
```

### Công thức tính đơn hàng
```
Tổng tiền (Subtotal) = Σ (Giá item × Số lượng)

Tiền giảm (Discount) = Tiền voucher (nếu áp dụng & đủ đơn tối thiểu)

Phí ship = 20,000đ (fixed)

Thành tiền (Grand Total) = Subtotal + Phí ship - Tiền giảm
                         = max(0, Subtotal + 20,000 - Discount)
```

### Ví dụ tính cụ thể
```
Item 1: Trà sữa 30k + Size L (7k) + 2 Topping (5k×2) = 47k × 2 cái = 94k
Item 2: Cà phê 25k + Size M (0k) + 0 Topping = 25k × 1 cái = 25k
────────────────────────────────────────────────────────

Subtotal = 94k + 25k = 119k
Phí ship = 20k
Voucher: Giảm 20k (Đơn tối thiểu: 100k) ✅ Áp dụng được
────────────────────────────────────────────────────────
Grand Total = 119k + 20k - 20k = 119k
```

---

## 3️⃣ CHỨC NĂNG VOUCHER (Discount Code)

### Mô hình Voucher
```
VoucherModel:
├── code - Mã voucher (ví dụ: SAVE20, WELCOME10)
├── discountAmount - Tiền giảm cụ thể (VD: 20,000đ)
├── minOrderValue - Đơn tối thiểu để áp dụng (VD: 100,000đ)
├── expirationDate - Ngày hết hạn
├── isActive - Đang hoạt động hay không
└── createdAt - Ngày tạo
```

### Quy tắc áp dụng Voucher
1. **Voucher phải hợp lệ**:
   - ✅ isActive = true (đang hoạt động)
   - ✅ Ngày hiện tại < Ngày hết hạn

2. **Đơn hàng phải đủ điều kiện**:
   - ✅ Subtotal ≥ minOrderValue

### Thông tin Voucher
- **Discount Amount**: Cố định (VD: 20,000đ, 50,000đ, ...)
- **Expiration Text**: Hiển thị "Còn X ngày", "Hôm nay hết", "Đã hết hạn"
- **Expiring Soon**: ⚠️ Cảnh báo nếu còn < 7 ngày
- **History**: Lưu voucher đã sử dụng trong lịch sử

### Ví dụ Voucher
```
Voucher SAVE20:
├── Giảm: 20,000đ
├── Đơn tối thiểu: 100,000đ
└── Còn: 15 ngày

Voucher WELCOME10:
├── Giảm: 50,000đ
├── Đơn tối thiểu: 200,000đ
└── Hết hạn: Hôm nay ⚠️
```

### Quy trình áp dụng Voucher
```
1. Người dùng nhập mã voucher
   ↓
2. Hệ thống kiểm tra:
   - Mã có tồn tại? 
   - Voucher còn hiệu lực?
   - Đơn hàng ≥ minOrderValue?
   ↓
3. Nếu ✅ tất cả:
   - Áp dụng giảm giá
   - Lưu vào lịch sử
   - Hiển thị thông báo thành công
   ↓
4. Nếu ❌ bất kỳ điều kiện:
   - Hiển thị lỗi cụ thể
   - Không áp dụng
```

---

## 4️⃣ FLOW HOÀN CHỈNH MUA HÀNG

```
┌─────────────────────────────────┐
│  1. Duyệt menu chính            │
│     - Xem danh sách sản phẩm    │
└──────────────┬──────────────────┘
               ↓
┌─────────────────────────────────┐
│  2. Chọn sản phẩm               │
│     → Mở dialog chi tiết        │
│     → Chọn Size, Topping, ...   │
│     → Xác nhận "THÊM VÀO GIỎ"   │
└──────────────┬──────────────────┘
               ↓
┌─────────────────────────────────┐
│  3. Đến trang GIỎ HÀNG          │
│     - Xem danh sách items       │
│     - Có thể:                   │
│       • Chỉnh sửa (nhấn item)   │
│       • Thay đổi số lượng       │
│       • Xóa item                │
└──────────────┬──────────────────┘
               ↓
┌─────────────────────────────────┐
│  4. Nhập Voucher (tùy chọn)    │
│     - Nhập mã giảm giá          │
│     - Xem tiền giảm             │
└──────────────┬──────────────────┘
               ↓
┌─────────────────────────────────┐
│  5. Lựa chọn địa chỉ giao hàng  │
│     - Chọn từ danh sách sẵn     │
│     - Hoặc thêm mới             │
└──────────────┬──────────────────┘
               ↓
┌─────────────────────────────────┐
│  6. Xem tóm tắt đơn hàng        │
│     • Subtotal                   │
│     • Phí ship: 20,000đ         │
│     • Giảm giá (nếu có)         │
│     • TỔNG TIỀN                 │
└──────────────┬──────────────────┘
               ↓
┌─────────────────────────────────┐
│  7. Đặt hàng                    │
│     - Bấm "ĐẶT HÀNG"            │
│     - Hệ thống tạo Order       │
│     - Chuyển sang trang chi tiết│
└─────────────────────────────────┘
```

---

## 5️⃣ TÍNH NĂNG NÂNG CAO ĐÃ THÊM

### ✨ Chỉnh sửa Item trong Giỏ
- Nhấn vào bất kỳ item trong giỏ
- Dialog mở với animation zoom + fade
- Có thể thay đổi Size, Topping, Sugar, Ice
- Nhấn "CẬP NHẬT" để lưu lại
- Giá tự động tính lại

### 📦 Persistence
- Tất cả data giỏ hàng lưu vào thiết bị
- Khi đóng app, bật lại vẫn có dữ liệu

### 💾 Order Management
- Lưu toàn bộ thông tin order (items, customization, voucher)
- Liên kết với địa chỉ giao hàng
- Theo dõi lịch sử đơn hàng

---

## 📊 TÓMLƯỢC SỐ LIỆU

| Yếu tố | Chi tiết |
|--------|----------|
| **Size** | S/M/L (L +7k) |
| **Topping** | 3 loại, mỗi +5k |
| **Phí ship** | 20,000đ |
| **Voucher** | Cố định giảm, có điều kiện tối thiểu |
| **Lưu trữ** | SharedPreferences (local device) |
| **Giỏ hàng** | Tự động gộp item trùng |
| **Animation** | Zoom in + Fade (300ms) |

---

**📝 Ghi chú**: Tài liệu này tổng hợp logic từ CartController, VoucherModel, MenuModels & FoodCustomization. Có thể sử dụng trực tiếp cho slide báo cáo.
