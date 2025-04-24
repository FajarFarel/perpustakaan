from database import get_connection  # Pastikan sesuai dengan nama file koneksimu

def test_koneksi():
    conn = get_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM mahasiswa")
            data = cursor.fetchall()
            print("Data dari tabel mahasiswa:", data)
        except Exception as e:
            print(f"❌ Error saat mengambil data: {e}")
        finally:
            conn.close()
    else:
        print("❌ Koneksi ke database gagal")

if __name__ == "__main__":
    test_koneksi()
