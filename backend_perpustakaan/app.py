import os
import uuid
import bcrypt
import mysql.connector
import base64
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from werkzeug.utils import secure_filename
from routes.mahasiswa_routes import mahasiswa_bp
from datetime import datetime, timedelta
from config import Base_URL
import traceback
import pymysql
from config import DB_HOST, DB_USER, DB_PASSWORD, DB_NAME
import sys
import io
import pymysql.cursors  # atau pastikan ini di bagian atas


sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# 🔹 Inisialisasi Aplikasi Flask
app = Flask(__name__)
CORS(app, origins=[
  "http://127.0.0.1:5500",
  "http://localhost:5500",
  "http://127.0.0.1:5501",  # Tambahkan ini
  "http://localhost:5501"
]) # izinkan domain frontend lokal
# Untuk komunikasi real-time

def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor
    )


UPLOAD_FOLDER = 'uploads'
BUKU_FOLDER = os.path.join(UPLOAD_FOLDER, 'buku')
PROFIL_FOLDER = os.path.join(UPLOAD_FOLDER, 'profil')

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
os.makedirs(BUKU_FOLDER, exist_ok=True)
os.makedirs(PROFIL_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


# Route untuk serve foto profil (profil)
@app.route('/uploads/profil/<filename>')
def uploaded_profile(filename):
    return send_from_directory(PROFIL_FOLDER, filename)


# Route untuk serve foto buku (buku)
@app.route('/uploads/buku/<filename>')
def uploaded_buku(filename):
    return send_from_directory(BUKU_FOLDER, filename)
    
    
@app.route('/users', methods=['GET'])
def get_users():
    try:
        db = get_db_connection()
        cursor = db.cursor(pymysql.cursors.DictCursor)
        cursor.execute("SELECT * FROM mahasiswa")
        users = cursor.fetchall()

        for user in users:
            foto = user.get("foto")
            if foto:
                # Buat URL penuh untuk akses gambar
                user["foto"] = f"{request.host_url}/uploads/profil/{foto}"
            else:
                user["foto"] = None  # kalau tidak ada foto

        return jsonify({"users": users})

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route('/register', methods=['POST'])
def register():
    try:
        data = request.form
        file = request.files.get("gambar")

        # Validasi
        if not all([data.get(k) for k in ["nama", "alamat", "npm", "noTelp", "email", "password", "role"]]) or not file or file.filename == '':
            return jsonify({"error": "Semua field harus diisi dan file foto harus diupload!"}), 400

        if not allowed_file(file.filename):
            return jsonify({"error": "Format file tidak didukung!"}), 400

        # Buat folder profil jika belum ada
        profil_folder = os.path.join(app.config['UPLOAD_FOLDER'], 'profil')
        os.makedirs(profil_folder, exist_ok=True)

        # Simpan file foto dengan nama unik
        filename = secure_filename(file.filename)
        import time
        unique_filename = f"{int(time.time())}_{filename}"
        save_path = os.path.join(profil_folder, unique_filename)
        file.save(save_path)

        # Hash password
        hashed_password = bcrypt.hashpw(data["password"].encode(), bcrypt.gensalt()).decode()

        conn = get_db_connection()
        cursor = conn.cursor()

        # Cek duplikat email / npm
        cursor.execute("SELECT * FROM mahasiswa WHERE email = %s OR npm = %s", (data["email"], data["npm"]))
        if cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Email atau NPM sudah digunakan!"}), 409

        # Simpan ke database, simpan nama file saja
        cursor.execute("""
            INSERT INTO mahasiswa (nama, alamat, npm, noTelp, email, password, foto, role) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            data["nama"], data["alamat"], data["npm"], data["noTelp"],
            data["email"], hashed_password, unique_filename, data["role"]
        ))

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"message": "Registrasi berhasil!", "filename": unique_filename}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.json
        email = data.get("email")
        password = data.get("password")

        if not email or not password:
            return jsonify({"error": "Email dan password harus diisi"}), 400

        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute("SELECT * FROM mahasiswa WHERE email = %s", (email,))
        user = cursor.fetchone()

        if user:
            if user['status'] == 'blokir':
                return jsonify({"error": "Akun Anda telah diblokir."}), 403
            elif user['status'] == 'suspend':
                now = datetime.now()
                suspend_until = user.get('suspend_until')
                if suspend_until and now < suspend_until:
                    return jsonify({"error": f"Akun Anda ditangguhkan hingga {suspend_until.strftime('%Y-%m-%d')}"}), 403
                else:
                    cursor.execute("UPDATE mahasiswa SET status = 'aktif', suspend_until = NULL WHERE id = %s", (user['id'],))
                    conn.commit()
                    user['status'] = 'aktif'

            if bcrypt.checkpw(password.encode(), user["password"].encode()):
                user.pop("password", None)
                # Pastikan Base_URL sudah di-define di config/global
                user["foto"] = f"{Base_URL}/uploads/profil/{user['foto']}" if user.get('foto') else None
                return jsonify({"message": "Login berhasil", "user": user}), 200

        return jsonify({"error": "Email atau password salah"}), 401

    except Exception as e:
        print("LOGIN ERROR:", e)
        return jsonify({"error": str(e)}), 500

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
          
@app.route('/hapus_user', methods=['POST'])
def hapus_user():
    try:
        data = request.get_json()
        user_id = data.get('id')

        if not user_id:
            return jsonify({"message": "ID pengguna tidak ditemukan"}), 400

        conn = get_db_connection()
        cursor = conn.cursor()

        # ❗ Opsional: Cek apakah user dengan ID ini ada
        cursor.execute("SELECT * FROM mahasiswa WHERE id = %s", (user_id,))
        user = cursor.fetchone()
        if not user:
            return jsonify({"message": "Pengguna tidak ditemukan"}), 404

        # 🧨 Hapus data user
        cursor.execute("DELETE FROM mahasiswa WHERE id = %s", (user_id,))
        conn.commit()

        return jsonify({"message": "Pengguna berhasil dihapus"}), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"message": "Terjadi kesalahan pada server", "error": str(e)}), 500

    finally:
        cursor.close()
        conn.close()

   
# 🔹 Update Status Mahasiswa (Admin)
@app.route('/update_status', methods=['POST'])
def update_status():
    data = request.get_json()
    user_id = data.get('id')
    status = data.get('status')
    duration = data.get('duration')  # Jumlah hari untuk suspend, boleh None

    db = get_db_connection()
    cursor = db.cursor()

    if status == "suspend":
        if not duration:
            return jsonify({'message': 'Durasi suspend harus disertakan'}), 400
        suspend_until = datetime.now() + timedelta(days=int(duration))
        cursor.execute("""
            UPDATE mahasiswa SET status = %s, suspend_until = %s WHERE id = %s
        """, (status, suspend_until.strftime('%Y-%m-%d %H:%M:%S'), user_id))
    else:
        # Untuk aktif atau blokir, kosongkan suspend_until
        cursor.execute("""
            UPDATE mahasiswa SET status = %s, suspend_until = NULL WHERE id = %s
        """, (status, user_id))

    db.commit()
    cursor.close()
    db.close()

    return jsonify({'message': f'Status pengguna berhasil diubah ke {status}'})

@app.route('/update_profile/<string:npm>', methods=['POST'])
def update_profile(npm):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)

        cursor.execute("SELECT * FROM mahasiswa WHERE npm = %s", (npm,))
        user = cursor.fetchone()

        if not user:
            return jsonify({"error": "User tidak ditemukan"}), 404

        nama = request.form.get('nama', user['nama'])
        email = request.form.get('email', user['email'])
        alamat = request.form.get('alamat', user['alamat'])
        no_telp = request.form.get('noTelp', user['noTelp'])
        old_password = request.form.get('old_password')
        new_password = request.form.get('new_password')

        # Validasi password jika ingin ganti
        if new_password:
            if not old_password or not bcrypt.checkpw(old_password.encode(), user['password'].encode()):
                return jsonify({"error": "Password lama salah atau tidak diisi!"}), 400
            password_baru = bcrypt.hashpw(new_password.encode(), bcrypt.gensalt()).decode()
        else:
            password_baru = user['password']

        # Handle upload foto → simpan ke folder uploads/profil
        foto_filename = user['foto']  # default foto lama
        if 'gambar' in request.files:
            file = request.files['gambar']
            if file and file.filename != '':
                if not allowed_file(file.filename):
                    return jsonify({"error": "Format file tidak didukung!"}), 400
                from werkzeug.utils import secure_filename
                import uuid
                ext = file.filename.rsplit('.', 1)[-1].lower()
                filename = f"{uuid.uuid4().hex}.{ext}"
                upload_folder = os.path.join(app.config['UPLOAD_FOLDER'], 'profil')
                os.makedirs(upload_folder, exist_ok=True)
                save_path = os.path.join(upload_folder, filename)
                file.save(save_path)
                foto_filename = filename

        # Update database
        cursor.execute("""
            UPDATE mahasiswa SET nama=%s, email=%s, alamat=%s, noTelp=%s, password=%s, foto=%s
            WHERE npm=%s
        """, (nama, email, alamat, no_telp, password_baru, foto_filename, npm))
        conn.commit()

        # Ambil data terbaru
        cursor.execute("SELECT * FROM mahasiswa WHERE npm = %s", (npm,))
        updated_user = cursor.fetchone()

        # Buat URL foto lengkap
        if updated_user['foto']:
            updated_user['foto'] = f"{request.host_url}uploads/profil/{updated_user['foto']}"
        else:
            updated_user['foto'] = None

        updated_user.pop("password", None)

        return jsonify(updated_user), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

# 🔹 Tambah Buku
@app.route('/data_buku', methods=['POST'])
def tambah_data_buku():
    conn = None
    cursor = None
    try:
        conn = get_db_connection()  # ✅ BENAR
        cursor = conn.cursor()

        data = request.form
        file = request.files.get("foto")

        filename = None
        if file and allowed_file(file.filename):
            from werkzeug.utils import secure_filename
            import uuid
            ext = file.filename.rsplit('.', 1)[-1].lower()
            filename = f"{uuid.uuid4().hex}.{ext}"
            filepath = os.path.join(BUKU_FOLDER, filename)
            file.save(filepath)
        else:
            return jsonify({"error": "Format file tidak didukung atau file kosong"}), 400

        # Cek apakah no_buku sudah ada
        cursor.execute("SELECT * FROM data_buku WHERE no_buku = %s", (data["no_buku"],))
        if cursor.fetchone():
            return jsonify({"error": "No Buku sudah digunakan!"}), 400

        cursor.execute(
            "INSERT INTO data_buku (judul, penulis, no_buku, jumlah, deskripsi, foto) VALUES (%s, %s, %s, %s, %s, %s)",
            (
                data["judul"],
                data["penulis"],
                data["no_buku"],
                int(data["jumlah"]),
                data["deskripsi"],
                filename,
            ),
        )
        conn.commit()

        return jsonify({"message": "Data buku berhasil ditambahkan"}), 201

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

# 🔹 lihat buku
@app.route('/data_buku', methods=['GET'])
def get_data_buku():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()  # dapatkan koneksi dari fungsi
        cursor = connection.cursor()
        cursor.execute("SELECT * FROM data_buku")
        result = cursor.fetchall()
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if connection is not None:
            connection.close()  # jangan lupa close koneksi juga
            
# 🔹 update buku
@app.route('/data_buku/<int:id>', methods=['PUT'])
def update_data_buku(id):
    conn = None
    cursor = None
    try:
        if request.is_json:
            data = request.get_json()
            foto_filename = None
        else:
            data = request.form
            file = request.files.get("foto")
            foto_filename = None

        required_fields = ["judul", "penulis", "no_buku", "jumlah", "deskripsi"]
        if not all(field in data and data[field] for field in required_fields):
            return jsonify({"error": "Semua field wajib diisi!"}), 400

        try:
            jumlah = int(data["jumlah"])
        except ValueError:
            return jsonify({"error": "Jumlah harus berupa angka"}), 400

        conn = get_db_connection()
        cursor = conn.cursor()

        # Ambil data lama (foto lama)
        cursor.execute("SELECT foto FROM data_buku WHERE id = %s", (id,))
        row = cursor.fetchone()
        foto_lama = row["foto"] if row and "foto" in row else None

        # Proses file baru
        if file and file.filename != '':
            if not allowed_file(file.filename):
                return jsonify({"error": "Format file tidak didukung!"}), 400

            # Hapus gambar lama
            if foto_lama:
                path_lama = os.path.join(app.config['UPLOAD_FOLDER'], 'buku', foto_lama)
                if os.path.exists(path_lama):
                    os.remove(path_lama)

            # Simpan gambar baru
            import uuid
            from werkzeug.utils import secure_filename
            ext = file.filename.rsplit('.', 1)[1].lower()
            filename = f"{uuid.uuid4().hex}.{ext}"
            upload_folder = os.path.join(app.config['UPLOAD_FOLDER'], 'buku')
            os.makedirs(upload_folder, exist_ok=True)
            file.save(os.path.join(upload_folder, filename))
            foto_filename = filename

        # Update DB
        if foto_filename:
            cursor.execute("""
                UPDATE data_buku
                SET judul=%s, penulis=%s, no_buku=%s, jumlah=%s, deskripsi=%s, foto=%s
                WHERE id=%s
            """, (
                data["judul"], data["penulis"], data["no_buku"], jumlah, data["deskripsi"], foto_filename, id
            ))
        else:
            cursor.execute("""
                UPDATE data_buku
                SET judul=%s, penulis=%s, no_buku=%s, jumlah=%s, deskripsi=%s
                WHERE id=%s
            """, (
                data["judul"], data["penulis"], data["no_buku"], jumlah, data["deskripsi"], id
            ))

        conn.commit()
        return jsonify({"message": "Data buku berhasil diperbarui"}), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

    finally:
        try:
            if cursor:
                cursor.close()
            if conn:
                conn.close()
        except Exception as e:
            print("Error saat close:", e)

# 🔹 Hapus Buku
@app.route('/data_buku/<int:id>', methods=['DELETE'])
def hapus_data_buku(id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM data_buku WHERE id = %s", (id,))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"message": "Data buku berhasil dihapus!"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Pinjam Buku
@app.route('/pinjam', methods=['POST'])
def pinjam_buku():
    try:
        data = request.json
        id_mahasiswa = data["id_mahasiswa"]
        id_buku = data["id_buku"]
        tanggal_pinjam = datetime.now().date()
        tanggal_kembali = datetime.strptime(data["tanggal_kembali"], "%Y-%m-%d").date()

        conn = get_db_connection()
        cursor = conn.cursor()

        # Cek mahasiswa
        cursor.execute("SELECT id FROM mahasiswa WHERE id = %s", (id_mahasiswa,))
        if not cursor.fetchone():
            return jsonify({"error": "Mahasiswa tidak ditemukan"}), 400

        # Cek stok buku
        cursor.execute("SELECT jumlah FROM data_buku WHERE id = %s FOR UPDATE", (id_buku,))
        buku = cursor.fetchone()
        
        if not buku or buku['jumlah'] <= 0:
            return jsonify({"error": "Stok buku habis"}), 400
            
        # Kurangi stok
        cursor.execute("UPDATE data_buku SET jumlah = jumlah - 1 WHERE id = %s", (id_buku,))

        # # Hapus data peminjaman lama yang statusnya sudah dikembalikan
        # cursor.execute("""
        #     DELETE FROM peminjaman_buku
        #     WHERE id_buku = %s AND status = 'dikembalikan'
        # """, (id_buku,))

        # Simpan peminjaman
        cursor.execute("""
            INSERT INTO peminjaman_buku (id_mahasiswa, id_buku, tanggal_pinjam, tanggal_kembali, status)
            VALUES (%s, %s, %s, %s, 'dipinjam')
        """, (id_mahasiswa, id_buku, tanggal_pinjam, tanggal_kembali))
        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({"message": "Buku berhasil dipinjam!"}), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500
        

# 🔹 Kembalikan Buku
@app.route('/kembali/<int:id_peminjaman>', methods=['PUT'])
def kembalikan_buku(id_peminjaman):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Cek peminjaman valid
        cursor.execute("""
            SELECT id_buku FROM peminjaman_buku 
            WHERE id = %s AND status = 'dipinjam'
        """, (id_peminjaman,))
        row = cursor.fetchone()
        if not row:
            return jsonify({"error": "Peminjaman tidak ditemukan"}), 404

        id_buku = row['id_buku']

        # Cek buku ada
        cursor.execute("SELECT jumlah FROM data_buku WHERE id = %s", (id_buku,))
        buku = cursor.fetchone()
        if not buku:
            return jsonify({"error": "Buku tidak ditemukan"}), 404

        # Update status
        cursor.execute("""
            UPDATE peminjaman_buku SET status = 'dikembalikan' WHERE id = %s
        """, (id_peminjaman,))

        # Tambah stok buku
        cursor.execute("""
            UPDATE data_buku SET jumlah = jumlah + 1 WHERE id = %s
        """, (id_buku,))

        conn.commit()
        return jsonify({"message": "Buku berhasil dikembalikan!"}), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

    finally:
        cursor.close()
        conn.close()

@app.route('/peminjaman_aktif', methods=['GET'])
def peminjaman_aktif():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute("""
           SELECT p.id, p.id_mahasiswa, m.nama, p.id_buku, b.judul,
                   p.tanggal_pinjam, p.tanggal_kembali, p.status
            FROM peminjaman_buku p
            JOIN mahasiswa m ON p.id_mahasiswa = m.id
            JOIN data_buku b ON p.id_buku = b.id
            WHERE p.status IN ('dikembalikan', 'dipinjam')
            ORDER BY p.tanggal_pinjam DESC
        """)
        rows = cursor.fetchall()
        data = []
        for row in rows:
            data.append({
                'id': row['id'],
                'id_mahasiswa': row['id_mahasiswa'],
                'nama_mahasiswa': row['nama'],
                'id_buku': row['id_buku'],
                'judul_buku': row['judul'],
                'tanggal_pinjam': row['tanggal_pinjam'],
                'tanggal_kembali': row['tanggal_kembali'],
                'status': row['status']
            })
        cursor.close()
        conn.close()
        return jsonify({'data': data}), 200
    except Exception as e:
        print("Error di /peminjaman_aktif:", str(e))
        return jsonify({'error': str(e)}), 500

@app.route('/pinjam/<int:id>', methods=['PUT'])
def update_peminjaman(id):
    try:
        data = request.json
        id_mahasiswa = data["id_mahasiswa"]
        tanggal_kembali = datetime.strptime(data["tanggal_kembali"], "%Y-%m-%d").date()
        status = data.get("status", "dipinjam")

        conn = get_db_connection()
        cursor = conn.cursor()

        # Cek apakah data peminjaman ada
        cursor.execute("SELECT * FROM peminjaman_buku WHERE id = %s", (id,))
        if not cursor.fetchone():
            return jsonify({"error": "Data peminjaman tidak ditemukan"}), 404

        # Update data
        cursor.execute("""
            UPDATE peminjaman_buku
            SET id_mahasiswa = %s, tanggal_kembali = %s, status = %s
            WHERE id = %s
        """, (id_mahasiswa, tanggal_kembali, status, id))
        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({"message": "Data peminjaman berhasil diperbarui"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/peminjaman_user/<npm>', methods=['GET'])
def get_peminjaman_user(npm):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)

        query = """
        SELECT pb.status, db.foto
        FROM peminjaman_buku pb
        JOIN mahasiswa mhs ON pb.id_mahasiswa = mhs.id
        JOIN data_buku db ON pb.id_buku = db.id
        WHERE mhs.npm = %s
        ORDER BY pb.id DESC
        LIMIT 5
        """
        cursor.execute(query, (npm,))
        data = cursor.fetchall()

        for row in data:
            row['foto'] = f"/uploads/buku/{row['foto']}" if row.get('foto') else None

        return jsonify(data)
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/jumlah-buku-dipinjam', methods=['GET'])
def jumlah_buku_dipinjam():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(id_buku) AS jumlah FROM peminjaman_buku WHERE status = 'dipinjam'")
        result = cursor.fetchone()
        jumlah = result['jumlah'] if result and 'jumlah' in result else 0
        return jsonify({'jumlah': int(jumlah)}), 200
    except Exception as e:
        return jsonify({'error': f'Jumlah buku error: {str(e)}'}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/jumlah-peminjaman-aktif', methods=['GET'])
def jumlah_peminjaman_aktif():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(DISTINCT id_mahasiswa) AS jumlah FROM peminjaman_buku WHERE status = 'dipinjam'")
        result = cursor.fetchone()
        jumlah = result['jumlah'] if result and 'jumlah' in result else 0
        return jsonify({'jumlah': int(jumlah)}), 200
    except Exception as e:
        return jsonify({'error': f'Jumlah aktif error: {str(e)}'}), 500
    finally:
        cursor.close()
        conn.close()

# 🔹 Endpoint Beranda (Health Check)
@app.route('/')
def home():
    return jsonify({"message": "API Perpustakaan Aktif!"})

# 🔹 Jalankan Server
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)