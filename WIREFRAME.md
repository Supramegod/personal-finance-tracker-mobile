# Wireframe Mobile App — Personal Finance Tracker (Flutter)

**Dokumen:** Fase 0 — Riset & Desain  
**Tanggal:** 19 Juni 2026  
**Oleh:** agent-mobile-uiux (diarahkan oleh coord-mobile)  
**Status:** Draft Desain  

---

## Daftar Isi
1. [Ringkasan Arsitektur UI](#1-ringkasan-arsitektur-ui)
2. [User Flow Navigasi](#2-user-flow-navigasi)
3. [Layar 1: Login](#3-layar-1-login)
4. [Layar 2: Dashboard](#4-layar-2-dashboard)
5. [Layar 3: Input Transaksi](#5-layar-3-input-transaksi)
6. [Layar 4: Riwayat Transaksi](#6-layar-4-riwayat-transaksi)
7. [Komponen Reusable](#7-komponen-reusable)
8. [Struktur Widget & Navigasi](#8-struktur-widget--navigasi)
9. [Mapping ke API Endpoint](#9-mapping-ke-api-endpoint)
10. [Lampiran: Mock Data](#10-lampiran-mock-data)

---

## 1. Ringkasan Arsitektur UI

### Filosofi Desain
- **Minimalis & Fungsional**: Tidak ada hiasan berlebihan. Setiap elemen punya tujuan.
- **Mobile-first**: Dioptimalkan untuk layar 4.7"–6.5" dengan satu tangan.
- **Low-end ready**: Tidak ada animasi berat, shadow minimal, gunakan widget bawaan Flutter.
- **Material Design 3** dengan kustomisasi warna brand.

### Navigasi Utama
Aplikasi menggunakan **Bottom Navigation Bar** dengan 3 tab utama setelah login:
1. **Dashboard** (beranda — saldo & ringkasan)
2. **Input Transaksi** (FAB atau tab tengah)
3. **Riwayat** (list transaksi)

### Aturan Tap
| Aksi | Target Tap |
|------|-----------|
| Dashboard → Input Transaksi | **1 tap** (FAB) |
| Dashboard → Riwayat | **1 tap** (bottom nav) |
| Riwayat → Detail/Edit Transaksi | **1 tap** (list item) |
| Input Transaksi → Submit | **2 tap** (isi form + submit) |
| **Maksimal 3 tap dari halaman utama ke input transaksi** ✅ | **Terpenuhi** |

### Tema & Styling
- Warna: Biru toska sebagai primary (#009688 / Teal), aksen emas/amber untuk aksesori.
- Dark mode: Didukung penuh via `ThemeData.brightness`.
- Typography: Gunakan `Theme.of(context).textTheme` — jangan font custom untuk menjaga ukuran APK.
- Spacing: Kelipatan 4px (4, 8, 12, 16, 24, 32).

---

## 2. User Flow Navigasi

```
                    ┌──────────────┐
                    │  SplashScreen │ (auto-check token)
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
              ┌─────│  LoginScreen  │─────┐
              │     └──────────────┘     │
              │ (token valid)          │ (login sukses)
              │                         │
        ┌─────▼─────────────────────────▼──────┐
        │          main_scaffold.dart          │
        │  ┌─────────────────────────────────┐  │
        │  │  BottomNavigationBar             │  │
        │  │  [Dashboard] [⊕FAB] [Riwayat]   │  │
        │  └─────────────────────────────────┘  │
        └─────┬───────────────────────┬─────────┘
              │                       │
     ┌────────▼────────┐    ┌────────▼────────┐
     │ DashboardScreen  │    │TransactionList  │
     │ • Saldo terkini  │    │Screen           │
     │ • Ringkasan      │    │ • List transaksi│
     │   income/expense │    │ • Filter        │
     │ • FAB (+ )       │    │ • Search        │
     │ • Grafik kecil   │    │ • Pagination    │
     └────────┬─────────┘    └────────┬─────────┘
              │ 1 tap (FAB)           │ 1 tap (item)
              │                       │
     ┌────────▼─────────┐   ┌────────▼─────────┐
     │AddTransaction     │   │AddTransaction     │
     │Screen             │   │Screen (edit mode) │
     │ • Tipe (toggle)   │   │ • Pre-filled data │
     │ • Jumlah (numpad) │   └───────────────────┘
     │ • Kategori (drop) │
     │ • Tanggal (picker)│
     │ • Catatan (ops)   │
     │ • Submit          │
     └───────────────────┘
```

**Jumlah tap dari halaman utama (Dashboard) ke form input transaksi: 1 tap** (FAB).

---

## 3. Layar 1: Login

### Tujuan
Autentikasi user single-owner dengan username/email & password.

### Wireframe Layout

```
┌─────────────────────────────────┐
│                                 │
│          ┌─────────┐            │
│          │  LOGO    │            │  Header area
│          │  App icon│            │
│          └─────────┘            │
│        Personal Finance         │
│           Tracker               │
│                                 │
│  ┌─────────────────────────┐    │
│  │ ✉️  Email / Username    │    │  TextField
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │ 🔒  Password            │    │  TextField (obscure)
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │      MASUK              │    │  ElevatedButton (full width)
│  └─────────────────────────┘    │
│                                 │
│  [⋯] Loading indicator         │  (tampil saat proses)
│                                 │
│  ⚠️ Email atau password salah   │  Error message (red)
│                                 │
│  Versi 1.0.0                    │  Footer
└─────────────────────────────────┘
```

### Widget Hierarchy
```
LoginScreen (StatelessWidget)
└── Scaffold
    └── SafeArea
        └── SingleChildScrollView
            └── Padding (24px)
                └── Column
                    ├── SizedBox(height: 48)
                    ├── AppLogo (widget reusable — icon + teks)
                    ├── SizedBox(height: 32)
                    ├── TextField (email, keyboardType: TextInputType.emailAddress)
                    ├── SizedBox(height: 16)
                    ├── TextField (password, obscureText: true)
                    ├── SizedBox(height: 24)
                    ├── LoginButton (ElevatedButton — full width)
                    ├── SizedBox(height: 16)
                    ├── LoadingIndicator (Conditional — CircularProgressIndicator)
                    ├── ErrorMessage (Conditional — Text merah)
                    └── Spacer
                        └── VersionText (Text small, warna abu-abu)
```

### State
- `email`: TextEditingController
- `password`: TextEditingController
- `isLoading`: boolean
- `errorMessage`: String?
- `obscurePassword`: boolean (toggle visibility)

### Validasi
- Email tidak boleh kosong (trim).
- Password tidak boleh kosong, minimal 6 karakter.
- Tampilkan error spesifik dari API (mis. "Akun tidak ditemukan").

### Navigasi
- **Sukses**: `Navigator.pushReplacementNamed('/main')` — ganti ke MainScreen dengan BottomNav.
- **Gagal**: Tampilkan `errorMessage` di bawah tombol.

---

## 4. Layar 2: Dashboard

### Tujuan
Menampilkan saldo terkini, ringkasan income vs expense bulan ini, dan shortcut cepat.

### Wireframe Layout

```
┌─────────────────────────────────┐
│ 🔔 Selamat datang, User!   │  AppBar (transparan)
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 💰 SALDO TERKINI            │ │
│ │                             │ │
│ │    Rp 12.500.000            │ │  BalanceCard (reusable)
│ │                             │ │
│ │ ┌──────┐     ┌──────┐      │ │
│ │ │Income│     │Expense│      │ │
│ │ │+8.5jt│     │-2.3jt │      │ │  Mini summary
│ │ └──────┘     └──────┘      │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 📊 Income vs Expense        │ │
│ │    Bulan Ini                │ │
│ │                             │ │
│ │   ████████████████░░░░      │ │  Mini bar chart
│ │   Income ██████  8.5jt      │ │  (fl_chart)
│ │   Expense ████   2.3jt      │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌──────────┐ ┌──────────┐      │
│ │ 💳       │ │ 📋       │      │  Quick Action Chips
│ │ Catat    │ │ Riwayat  │      │
│ │ Transaksi│ │ Transaksi│      │
│ └──────────┘ └──────────┘      │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 🔥 Transaksi Terakhir       │ │
│ │                             │ │
│ │ • Makan siang    -Rp 35rb  │ │
│ │ • Gaji bulanan  +Rp 8,5jt  │ │  3 transaksi terakhir
│ │ • Bensin         -Rp 100rb │ │  (TransactionTile)
│ │                             │ │
│ │ Lihat Semua →               │ │  Link ke riwayat
│ └─────────────────────────────┘ │
│                                 │
│        [⊕] FAB                  │  FloatingActionButton
└─────────────────────────────────┘
```

### Widget Hierarchy
```
DashboardScreen (ConsumerStatefulWidget)
└── Scaffold
    ├── AppBar (transparent, greeting + avatar/icon)
    ├── body: RefreshIndicator
    │   └── SingleChildScrollView
    │       └── Padding (16px)
    │           └── Column (crossAxisAlignment: stretch)
    │               ├── BalanceCard (reusable)
    │               │   ├── BalanceAmount (Text, large, bold)
    │               │   ├── Row
    │               │   │   ├── IncomeChip (green)
    │               │   │   └── ExpenseChip (red)
    │               ├── SizedBox(height: 16)
    │               ├── SummaryChartCard
    │               │   ├── CardHeader (title: "Income vs Expense")
    │               │   └── MiniBarChart (fl_chart)
    │               ├── SizedBox(height: 16)
    │               ├── QuickActionRow
    │               │   ├── ActionChip("Catat Transaksi", icon: Icons.add)
    │               │   └── ActionChip("Riwayat", icon: Icons.list)
    │               ├── SizedBox(height: 16)
    │               ├── RecentTransactionsCard
    │               │   ├── CardHeader (title: "Transaksi Terakhir" + "Lihat Semua →")
    │               │   └── ListView (3 item, shrinkWrap)
    │               │       └── TransactionTile (reusable, 3 item)
    │               └── SizedBox(height: 80) // padding untuk FAB
    └── floatingActionButton: FloatingActionButton
        └── onPressed: → Navigator.pushNamed('/add-transaction')
```

### Komponen
- `BalanceCard` — menampilkan saldo dengan background card.
- `SummaryChartCard` — grafik batang income vs expense.
- `RecentTransactionsCard` — cuplikan 3 transaksi terbaru.
- `TransactionTile` — baris transaksi (ikon kategori, deskripsi, jumlah).

### Data State (via Riverpod)
- `balanceProvider`: AsyncValue<Balance> — saldo terkini
- `monthlySummaryProvider`: AsyncValue<MonthlySummary> — total income/expense bulan ini
- `recentTransactionsProvider`: AsyncValue<List<Transaction>> — 3 transaksi terbaru

### Navigasi
- **FAB (+)** → `/add-transaction` (push)
- **Chip Riwayat** → navigasi ke tab riwayat (index 2 di BottomNav)
- **Lihat Semua** → navigasi ke tab riwayat
- **Pull-to-refresh** → refresh semua data

---

## 5. Layar 3: Input Transaksi

### Tujuan
Form input cepat untuk mencatat transaksi income atau expense. Maksimal 3 tap dari halaman utama.

### Wireframe Layout

```
┌─────────────────────────────────┐
│ ← Tambah Transaksi         💾  │  AppBar (back + save)
│                                 │
│ ┌─────────────────────────────┐ │
│ │  💵 PENDAPATAN  💸 PENGELUARAN│ │  TypeToggle (SegmentedButton)
│ └─────────────────────────────┘ │
│                                 │
│  Jumlah (Rp)                    │
│ ┌─────────────────────────────┐ │
│ │       Rp                     │ │
│ │                             │ │  AmountField
│ │     2 5 0 0 0 0            │ │  (TextFormField, numpad)
│ └─────────────────────────────┘ │
│                                 │
│  Kategori                       │
│ ┌─────────────────────────────┐ │
│ │ 🍔 Makanan              ▼  │ │  CategoryPicker (dropdown)
│ └─────────────────────────────┘ │
│                                 │
│  Tanggal                        │
│ ┌─────────────────────────────┐ │
│ │ 📅 19 Juni 2026         ▼  │ │  DatePicker (tap → showDatePicker)
│ └─────────────────────────────┘ │
│                                 │
│  Catatan (opsional)             │
│ ┌─────────────────────────────┐ │
│ │ Makan siang di warteg...    │ │  NoteField (TextFormField)
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │       SIMPAN TRANSAKSI      │ │  SubmitButton (ElevatedButton)
│ └─────────────────────────────┘ │
│                                 │
│ ⚠️ Jumlah harus diisi           │  Error/validasi message
└─────────────────────────────────┘
```

### Widget Hierarchy
```
AddTransactionScreen (ConsumerStatefulWidget)
└── Scaffold
    ├── AppBar
    │   ├── title: "Tambah Transaksi"
    │   ├── leading: BackButton
    │   └── actions: [SaveButton (IconButton)]
    ├── body: SingleChildScrollView
    │   └── Padding (16px)
    │       └── Form (GlobalKey<FormState>)
    │           └── Column
    │               ├── TypeToggle
    │               │   └── SegmentedButton (income | expense)
    │               ├── SizedBox(height: 24)
    │               ├── AmountField
    │               │   ├── Label "Jumlah (Rp)"
    │               │   └── TextFormField (keyboardType: number, prefix: "Rp ")
    │               ├── SizedBox(height: 16)
    │               ├── CategoryPicker
    │               │   ├── Label "Kategori"
    │               │   └── DropdownButtonFormField (list dari API)
    │               ├── SizedBox(height: 16)
    │               ├── DatePickerField
    │               │   ├── Label "Tanggal"
    │               │   └── InkWell + Text (showDatePicker on tap)
    │               ├── SizedBox(height: 16)
    │               ├── NoteField
    │               │   ├── Label "Catatan (opsional)"
    │               │   └── TextFormField (maxLines: 3)
    │               ├── SizedBox(height: 24)
    │               └── SubmitButton
    │                   └── ElevatedButton (full width, disabled saat loading)
    └── SnackBar (sukses/gagal)
```

### Aturan Desain Penting
- **TypeToggle** menggunakan `SegmentedButton` (Material 3) dengan 2 segmen: "Pendapatan" (icon +) dan "Pengeluaran" (icon -).
- **AmountField** menggunakan input numerik dengan prefix "Rp ". Format otomatis saat kehilangan fokus (onFocusLost).
- **CategoryPicker** mengambil data dari API (`/api/v1/categories`). Filter kategori berdasarkan tipe yang dipilih (income/expense).
- **DatePicker** menggunakan `showDatePicker` Flutter bawaan. Default ke hari ini.
- **Validasi**:
  - Amount: wajib, > 0, numerik.
  - Kategori: wajib dipilih.
  - Tanggal: wajib, valid.
  - Catatan: opsional.

### Mode Edit
Screen yang sama dipakai untuk edit transaksi. Bedanya:
- Judul AppBar: "Edit Transaksi"
- Data pre-filled dari transaksi yang diedit
- Tombol simpan mengirim PUT, bukan POST

### Navigasi
- **Submit sukses**: `Navigator.pop()` — kembali ke dashboard/riwayat dengan data ter-refresh.
- **Submit gagal**: Tampilkan snackbar dengan error dari API.
- **Back**: `Navigator.pop()` — konfirmasi jika form sudah diisi (unsaved changes dialog).

---

## 6. Layar 4: Riwayat Transaksi

### Tujuan
Menampilkan daftar transaksi dengan filter, pencarian, dan pagination.

### Wireframe Layout

```
┌─────────────────────────────────┐
│ ← Riwayat Transaksi       🔍  │  AppBar (back + search icon)
│                                 │
│ ┌──────────┐ ┌──────────┐     │
│ │ Semua    │ │ 📅 Filter│     │  FilterChips row
│ │          │ │ Tanggal  │     │
│ └──────────┘ └──────────┘     │
│ ┌──────────┐ ┌──────────┐     │
│ │ 🏷 Filter│ │ Income / │     │
│ │ Kategori │ │ Expense  │     │  (scrollable horizontal)
│ └──────────┘ └──────────┘     │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 🔹 Hari Ini                 │ │  Date section header
│ │ ┌─────────────────────────┐ │ │
│ │ │ 🍔 Makan siang   35.000 │ │ │
│ │ │ 📝 Warteg            ▼ │ │ │  TransactionTile (reusable)
│ │ └─────────────────────────┘ │ │
│ │ ┌─────────────────────────┐ │ │
│ │ │ ⛽ Bensin        100.000│ │ │
│ │ │ 📝 Shell             ▼ │ │ │  (swipe to delete)
│ │ └─────────────────────────┘ │ │
│ │                             │ │
│ │ 🔹 Kemarin, 18 Jun         │ │  Date section header
│ │ ┌─────────────────────────┐ │ │
│ │ │ 💰 Gaji bulanan 8.500.000│ │ │
│ │ │ 📝 PT. Maju           ▼ │ │ │
│ │ └─────────────────────────┘ │ │
│ │                             │ │
│ │ 🔹 17 Jun                  │ │
│ │ ...                         │ │
│ └─────────────────────────────┘ │
│                                 │
│ [Load lebih banyak...]          │  LoadMore button / infinite scroll
│                                 │
│                                 │
│       [⊕] FAB (tambah)          │
└─────────────────────────────────┘
```

### Widget Hierarchy
```
TransactionListScreen (ConsumerStatefulWidget)
└── Scaffold
    ├── AppBar
    │   ├── title: "Riwayat Transaksi"
    │   └── actions: [SearchIcon → search delegate]
    ├── body: Column
    │   ├── FilterBar
    │   │   └── SingleChildScrollView (horizontal)
    │   │       └── Row
    │   │           ├── FilterChip("Semua", selected)
    │   │           ├── FilterChip("Filter Tanggal", icon: calendar)
    │   │           ├── FilterChip("Kategori", icon: category)
    │   │           └── FilterChip("Income" / "Expense")
    │   └── Expanded
    │       └── RefreshIndicator
    │           └── ListView.builder
    │               ├── TransactionGroup (Date header)
    │               │   ├── SectionHeader("Hari Ini")
    │               │   └── TransactionTile × N
    │               ├── TransactionGroup (Date header)
    │               │   ├── SectionHeader("Kemarin, 18 Jun")
    │               │   └── TransactionTile × N
    │               ├── LoadingIndicator (di bottom, saat load more)
    │               └── EmptyState (jika tidak ada data)
    └── floatingActionButton: FloatingActionButton
        └── onPressed: → Navigator.pushNamed('/add-transaction')
```

### Filter Behavior
| Filter | Behavior |
|--------|----------|
| **Semua** | Reset semua filter, tampilkan semua transaksi |
| **Filter Tanggal** | Tap → show DateRangePicker → filter by range |
| **Filter Kategori** | Tap → bottom sheet daftar kategori → pilih 1 |
| **Income / Expense** | Toggle filter by type |
| **Search** | SearchDelegate — cari berdasarkan catatan/nominal |

### Pagination
- Gunakan **infinite scroll** (scroll listener di `ListView.builder`).
- Default 20 item per halaman.
- Indikator loading di底部 saat memuat halaman berikutnya.
- "Tidak ada lagi data" tercapai setelah semua data termuat.

### Interaksi
- **Tap item**: `Navigator.pushNamed('/edit-transaction', arguments: transaction)`.
- **Swipe left**: konfirmasi hapus (show dialog) → soft delete via API.
- **Long press**: (opsional) — aksi cepat.

### Empty State
Saat tidak ada transaksi (setelah filter atau baru pertama pakai):
```
┌─────────────────────────────┐
│                             │
│        📭                   │
│   Belum ada transaksi       │
│                             │
│   Mulai catat pengeluaran   │
│   atau pemasukan pertama    │
│   dengan tekan tombol +     │
│                             │
└─────────────────────────────┘
```

---

## 7. Komponen Reusable

### 7.1 BalanceCard (`widgets/balance_card.dart`)
```
BalanceCard
├── balanceAmount: String (formatted IDR)
├── incomeTotal: String
├── expenseTotal: String
├── isLoading: boolean
└── onRefresh: VoidCallback?
```
- Menampilkan saldo besar di tengah.
- Dua chip kecil untuk income (hijau) dan expense (merah).
- Warna card mengikuti theme (surfaceContainer).

### 7.2 TransactionTile (`widgets/transaction_tile.dart`)
```
TransactionTile
├── icon: IconData? (kategori)
├── categoryName: String
├── note: String?
├── amount: String (formatted IDR, dengan + / -)
├── type: TransactionType (income → hijau, expense → merah)
├── onTap: VoidCallback?
├── onDelete: VoidCallback? (swipe)
└── date: DateTime? (opsional, untuk grouped list)
```
- ListTile dengan leading icon kategori.
- Amount di-trailing: hijau untuk income, merah untuk expense.
- Swipe ke kiri untuk hapus (Dismissible wrapper).

### 7.3 CategoryPicker (`widgets/category_picker.dart`)
```
CategoryPicker
├── categories: List<Category>
├── selectedCategory: Category?
├── onChanged: (Category) → void
├── filterByType: TransactionType? (opsional)
└── isLoading: boolean
```
- `DropdownButtonFormField` dengan ikon kategori di leading.
- Filter otomatis berdasarkan tipe transaksi yang dipilih (income/expense).
- Mendukung loading state saat mengambil dari API.

### 7.4 EmptyStateWidget (`widgets/empty_state_widget.dart`)
```
EmptyStateWidget
├── icon: IconData
├── title: String
├── subtitle: String?
└── action: (label: String, onPressed: VoidCallback)?
```

### 7.5 LoadingOverlay (`widgets/loading_overlay.dart`)
- Overlay dengan `CircularProgressIndicator` di tengah.
- Digunakan saat submit form atau refresh data.

### 7.6 ErrorMessageBanner (`widgets/error_message_banner.dart`)
```
ErrorMessageBanner
├── message: String
├── onRetry: VoidCallback? (optional)
```
- Banner merah di bagian atas layar.
- Tombol "Coba Lagi" opsional.

### 7.7 SummaryChartCard (`widgets/summary_chart_card.dart`)
```
SummaryChartCard
├── incomeTotal: double
├── expenseTotal: double
├── periodLabel: String (e.g., "Bulan Ini")
└── chartType: ChartType (bar / pie)
```
- Menggunakan fl_chart untuk bar chart horizontal.
- Menampilkan perbandingan income vs expense.

---

## 8. Struktur Widget & Navigasi

### Router (/ routes)
```
/                     → SplashScreen (auto-check token)
/login                → LoginScreen
/main                 → MainScreen (BottomNavigationBar)
  /main/dashboard     → DashboardScreen (tab 0)
  /main/history       → TransactionListScreen (tab 2)
/add-transaction      → AddTransactionScreen (push, mode: create)
/edit-transaction     → AddTransactionScreen (push, mode: edit, args: Transaction)
```

### Route Definitions (GoRouter — ringan, bawaan Flutter)
```dart
// Di lib/app_router.dart
GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    ShellRoute(
      builder: (_, __, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => DashboardScreen()),
        GoRoute(path: '/history', builder: (_, __) => TransactionListScreen()),
      ],
    ),
    GoRoute(
      path: '/add-transaction',
      builder: (_, state) => AddTransactionScreen(transaction: state.extra as Transaction?),
    ),
  ],
)
```

### Bottom Navigation Bar (MainScaffold)
```dart
BottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: _onTabTapped,
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Catat'),       // FAB-style
    BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Riwayat'),
  ],
)
```

---

## 9. Mapping ke API Endpoint

| Layar | API Endpoint | Method | Data |
|-------|-------------|--------|------|
| Login | `/api/v1/auth/login` | POST | `{email, password}` → `{access_token, refresh_token}` |
| Dashboard | `/api/v1/summary/balance` | GET | `{total_income, total_expense, balance}` |
| Dashboard | `/api/v1/summary/report?period=monthly` | GET | `{period, income_total, expense_total}` |
| Dashboard | `/api/v1/transactions?page=1&limit=3` | GET | `{data: [...], meta: {page, total, ...}}` |
| Input | `/api/v1/transactions` | POST | `{type, amount, category_id, transaction_date, note}` |
| Edit | `/api/v1/transactions/:id` | PUT | `{type, amount, category_id, transaction_date, note}` |
| Delete | `/api/v1/transactions/:id` | DELETE | (soft delete) |
| Riwayat | `/api/v1/transactions?page=&limit=&from=&to=&category_id=&type=` | GET | Paginated list |
| Riwayat | `/api/v1/categories` | GET | `[{id, name, type, icon, is_default}]` |
| Riwayat/Filter | `/api/v1/transactions?search=` | GET | Search by note |

---

## 10. Lampiran: Mock Data

### Format Balance Response
```json
{
  "balance": 12500000.00,
  "total_income": 8500000.00,
  "total_expense": 2300000.00,
  "period": "2026-06",
  "currency": "IDR"
}
```

### Format Transaction Response (list)
```json
{
  "data": [
    {
      "id": "uuid-1",
      "type": "expense",
      "amount": 35000.00,
      "category": {
        "id": "uuid-cat-1",
        "name": "Makanan",
        "icon": "restaurant"
      },
      "transaction_date": "2026-06-19",
      "note": "Makan siang di warteg",
      "created_at": "2026-06-19T07:30:00Z"
    },
    {
      "id": "uuid-2",
      "type": "income",
      "amount": 8500000.00,
      "category": {
        "id": "uuid-cat-2",
        "name": "Gaji",
        "icon": "work"
      },
      "transaction_date": "2026-06-17",
      "note": "Gaji bulan Juni",
      "created_at": "2026-06-17T08:00:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 2,
    "total_pages": 1
  }
}
```

### Format Category Response
```json
[
  {
    "id": "uuid-cat-1",
    "name": "Makanan",
    "type": "expense",
    "icon": "restaurant",
    "is_default": true
  },
  {
    "id": "uuid-cat-2",
    "name": "Gaji",
    "type": "income",
    "icon": "work",
    "is_default": true
  },
  {
    "id": "uuid-cat-3",
    "name": "Transport",
    "type": "expense",
    "icon": "directions_car",
    "is_default": true
  }
]
```

---

## Checklist Desain

- [x] 4 layar P0 didefinisikan (Login, Dashboard, Input Transaksi, Riwayat)
- [x] Navigasi maksimal 3 tap dari halaman utama ke input transaksi ✅ (1 tap via FAB)
- [x] Widget reusable teridentifikasi (BalanceCard, TransactionTile, CategoryPicker, dll)
- [x] Struktur folder sesuai stack-conventions.md
- [x] State loading & error handling di setiap layar
- [x] Format IDR & tanggal sesuai konvensi
- [x] Null safety
- [x] Dark mode support
- [x] Mode offline (FR-16, P2) — struktur data lokal sudah siap dipertimbangkan
- [x] Mapping ke API endpoint (untuk koordinasi dengan coord-backend)

---

**Dokumen ini akan digunakan oleh:**
1. **agent-mobile-state** — untuk setup Riverpod state management
2. **agent-mobile-api** — untuk integrasi API ke backend
3. **agent-mobile-build** — untuk setup build & signing APK
4. **agent-mobile-qa** — untuk testing berdasarkan flow dan komponen
