<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Koneksi ke database
$conn = new mysqli("localhost", "sagiscor_leo", "Nova0920", "sagiscor_backend_perpustakaan");
if ($conn->connect_error) {
    die("Koneksi gagal: " . $conn->connect_error);
}

// Fungsi format tanggal
function formatTanggal($tgl) {
    $bulan = [
        1 => 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    $pecah = explode('-', $tgl); // yyyy-mm-dd
    return $pecah[2] . ' ' . $bulan[(int)$pecah[1]] . ' ' . $pecah[0];
}

// Ambil parameter filter
$status = isset($_GET['status']) ? $_GET['status'] : null;
$start = isset($_GET['start']) ? $_GET['start'] : null;  // format yyyy-mm
$end = isset($_GET['end']) ? $_GET['end'] : null;        // format yyyy-mm

$sql = "
    SELECT p.id, m.nama AS nama_mahasiswa, b.judul AS judul_buku, 
           p.tanggal_pinjam, p.tanggal_kembali, p.status
    FROM peminjaman_buku p
    JOIN mahasiswa m ON p.id_mahasiswa = m.id
    JOIN data_buku b ON p.id_buku = b.id
    WHERE 1=1
";

// Filter status
if ($status) {
    $sql .= " AND p.status = '" . $conn->real_escape_string($status) . "'";
}

// Filter tanggal pinjam
if ($start && $end) {
    $start_date = $start . "-01";
    $end_date = $end . "-31"; // asumsi akhir bulan
    $sql .= " AND p.tanggal_pinjam BETWEEN '$start_date' AND '$end_date'";
}

$sql .= " ORDER BY p.tanggal_pinjam DESC";

$result = $conn->query($sql);

// Header Excel
header("Content-Type: application/vnd.ms-excel");
header("Content-Disposition: attachment; filename=laporan_peminjaman.xls");
header("Pragma: no-cache");
header("Expires: 0");

echo "<html><meta charset='UTF-8'><body>";
echo "<h2 style='text-align:center;'>LAPORAN PEMINJAMAN BUKU</h2>";
echo "<p><strong>Tanggal Cetak:</strong> " . date("d-m-Y H:i") . "</p>";

if ($start && $end) {
    echo "<p><strong>Periode:</strong> " . date("F Y", strtotime($start_date)) . " - " . date("F Y", strtotime($end_date)) . "</p>";
}

echo "<table border='1' cellpadding='6' cellspacing='0'>";
echo "<tr style='background-color:#f0f0f0;'>
        <th>No</th>
        <th>Nama Mahasiswa</th>
        <th>Judul Buku</th>
        <th>Tanggal Pinjam</th>
        <th>Tanggal Kembali</th>
        <th>Status</th>
      </tr>";

$no = 1;
while ($row = $result->fetch_assoc()) {
    echo "<tr>
            <td>{$no}</td>
            <td>{$row['nama_mahasiswa']}</td>
            <td>{$row['judul_buku']}</td>
            <td>" . formatTanggal($row['tanggal_pinjam']) . "</td>
            <td>" . formatTanggal($row['tanggal_kembali']) . "</td>
            <td>{$row['status']}</td>
          </tr>";
    $no++;
}

echo "</table>";
echo "</body></html>";

$conn->close();
?>
