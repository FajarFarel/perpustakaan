import os
import uuid
import bcrypt
import mysql.connector
import base64
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from flask_socketio import SocketIO, emit
from werkzeug.utils import secure_filename
from routes.mahasiswa_routes import mahasiswa_bp
from datetime import datetime, timedelta
from config import Base_URL
import traceback
from flask_socketio import SocketIO, emit

# 🔹 Inisialisasi Aplikasi Flask
app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")  # Untuk komunikasi real-time

# 🔹 Konfigurasi Database
db_config = {
    "host": "localhost",
    "user": "root",
    "password": "",
    "database": "perpustakaan"
}

def get_db_connection():
    return mysql.connector.connect(**db_config)

# 🔹 Konfigurasi Upload File
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# 🔹 Blueprint untuk Mahasiswa (modular routing)
app.register_blueprint(mahasiswa_bp, url_prefix="/mahasiswa")

# 🔹 Socket.IO: Real-time Online Users
online_users = {}

@socketio.on('connect')
def handle_connect():
    user_id = request.args.get('user_id')
    if user_id:
        online_users[user_id] = request.sid
    emit('update_online_users', list(online_users.keys()), broadcast=True)

@socketio.on('disconnect')
def handle_disconnect():
    user_id = next((k for k, v in online_users.items() if v == request.sid), None)
    if user_id:
        del online_users[user_id]
    emit('update_online_users', list(online_users.keys()), broadcast=True)

# 🔹 Serve File Gambar (static file access)
@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# 🔹 GET Semua Mahasiswa (Admin)

@app.route('/users', methods=['GET'])
def get_users():
    db = get_db_connection()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM mahasiswa")
    users = cursor.fetchall()
    cursor.close()
    db.close()

    # Ubah kolom bertipe bytes jadi base64
    for user in users:
        for key, value in user.items():
            if isinstance(value, bytes):
                user[key] = base64.b64encode(value).decode('utf-8')

    return jsonify(users)


# 🔹 Register Mahasiswa
@app.route('/register', methods=['POST'])
def register():
    try:
        data = request.form
        file = request.files.get("gambar")

        if not all([data.get(k) for k in ["nama", "alamat", "npm", "noTelp", "email", "password", "role"]]) or not file:
            return jsonify({"error": "Semua field harus diisi!"}), 400

        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
        else:
            return jsonify({"error": "Format file tidak didukung!"}), 400

        hashed_password = bcrypt.hashpw(data["password"].encode(), bcrypt.gensalt()).decode()
        conn = get_db_connection()
        cursor = conn.cursor()

        # Cek duplikasi
        cursor.execute("SELECT * FROM mahasiswa WHERE email = %s OR npm = %s", (data["email"], data["npm"]))
        if cursor.fetchone():
            return jsonify({"error": "Email atau NPM sudah digunakan!"}), 409

        cursor.execute("""
            INSERT INTO mahasiswa (nama, alamat, npm, noTelp, email, password, foto, role) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (data["nama"], data["alamat"], data["npm"], data["noTelp"],
              data["email"], hashed_password, filename, data["role"]))

        conn.commit()
        socketio.emit('update_statistik')
        cursor.close()
        conn.close()

        return jsonify({
    "message": "Registrasi berhasil!",
    "foto": f"{Base_URL}/uploads/{filename}"  # ⬅️ ini penting!
}), 201


    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Login Mahasiswa
@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.json
        email = data.get("email")
        password = data.get("password")

        if not email or not password:
            return jsonify({"error": "Email dan password harus diisi"}), 400

        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM mahasiswa WHERE email = %s", (email,))
        user = cursor.fetchone()

        if user and bcrypt.checkpw(password.encode(), user["password"].encode()):
            user.pop("password", None)

            # ✅ Decode nama file jika masih dalam bentuk bytes
            if isinstance(user.get("foto"), bytes):
                user["foto"] = user["foto"].decode(errors="ignore")

            # ✅ Buat URL untuk gambar
            user["foto"] = f"{Base_URL}/uploads/{user['foto']}"  # ✅ fix!  # di /login endpoint

            return jsonify({"message": "Login berhasil", "user": user}), 200

        return jsonify({"error": "Email atau password salah"}), 401

    except Exception as e:
        return jsonify({"error": str(e)}), 500
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
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT * FROM mahasiswa WHERE npm = %s", (npm,))
        user = cursor.fetchone()

        if not user:
            return jsonify({"error": "User tidak ditemukan"}), 404

        nama = request.form.get('nama')
        email = request.form.get('email')
        alamat = request.form.get('alamat')
        no_telp = request.form.get('noTelp')
        old_password = request.form.get('old_password')
        new_password = request.form.get('new_password')

        # Validasi password jika ingin ganti
        if new_password:
            if not bcrypt.checkpw(old_password.encode(), user['password'].encode()):
                return jsonify({"error": "Password lama salah!"}), 400
            password_baru = new_password
        else:
            password_baru = user['password']

        # Handle upload foto (tetap blob)
        foto_blob = user['foto']
        if 'gambar' in request.files:
            file = request.files['gambar']
            if file.filename != '':
                foto_blob = file.read()

        # Update ke database
        cursor.execute("""
            UPDATE mahasiswa SET nama=%s, email=%s, alamat=%s, noTelp=%s, password=%s, foto=%s
            WHERE npm=%s
        """, (nama, email, alamat, no_telp, password_baru, foto_blob, npm))
        conn.commit()

        # Ambil data terbaru
        cursor.execute("SELECT * FROM mahasiswa WHERE npm = %s", (npm,))
        updated_user = cursor.fetchone()

        # Encode foto (blob) ke base64
        if updated_user['foto']:
            encoded_foto = base64.b64encode(updated_user['foto']).decode('utf-8')
            updated_user['foto'] = f"data:image/jpeg;base64,{encoded_foto}"
        else:
            updated_user['foto'] = ""

        updated_user.pop("password", None)

        return jsonify(updated_user), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

# 🔹 Tambah Buku
@app.route("/data_buku", methods=["POST"])
def tambah_data_buku():
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()

        data = request.form
        file = request.files.get("foto")
        foto_blob = file.read() if file else None

        # Ganti dari: FROM buku
        cursor.execute("SELECT * FROM data_buku WHERE no_buku = %s", (data["no_buku"],))
        existing_book = cursor.fetchone()
        if existing_book:
            return jsonify({"error": "No Buku sudah digunakan!"}), 400

        # Ganti ke: INTO data_buku
        cursor.execute(
            "INSERT INTO data_buku (judul, penulis, no_buku, jumlah, deskripsi, foto) VALUES (%s, %s, %s, %s, %s, %s)",
            (
                data["judul"],
                data["penulis"],
                data["no_buku"],
                int(data["jumlah"]),
                data["deskripsi"],
                foto_blob,
            ),
        )
        conn.commit()

        return jsonify({"message": "Data buku berhasil ditambahkan"}), 201

    except Exception as e:
        print("❌ Error saat menambahkan buku:")
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

    finally:
        cursor.close()
        conn.close()

# 🔹 Lihat Semua Buku
@app.route('/data_buku', methods=['GET'])
def lihat_data_buku():
    try:
        with get_db_connection() as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.execute("SELECT * FROM data_buku")
                rows = cursor.fetchall()

                for row in rows:
                    if row['foto']:
                        row['foto'] = base64.b64encode(row['foto']).decode('utf-8')
                    else:
                        row['foto'] = None

        return jsonify({"data_buku": rows}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Update Buku
@app.route('/data_buku/<int:id>', methods=['PUT'])
def update_data_buku(id):
    try:
        if request.is_json:
            data = request.get_json()
            foto_blob = None
        else:
            data = request.form
            file = request.files.get("foto")
            foto_blob = file.read() if file else None

        if not all([data.get(k) for k in ["judul", "penulis", "no_buku", "jumlah", "deskripsi"]]):
            return jsonify({"error": "Semua field wajib diisi!"}), 400

        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                if foto_blob:
                    cursor.execute("""
                        UPDATE data_buku
                        SET judul = %s, penulis = %s, no_buku = %s, jumlah = %s, deskripsi = %s, foto = %s
                        WHERE id = %s
                    """, (
                        data["judul"], data["penulis"], data["no_buku"],
                        int(data["jumlah"]), data["deskripsi"], foto_blob, id
                    ))
                else:
                    cursor.execute("""
                        UPDATE data_buku
                        SET judul = %s, penulis = %s, no_buku = %s, jumlah = %s, deskripsi = %s
                        WHERE id = %s
                    """, (
                        data["judul"], data["penulis"], data["no_buku"],
                        int(data["jumlah"]), data["deskripsi"], id
                    ))

                conn.commit()

        return jsonify({"message": "Data buku berhasil diperbarui"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Hapus Buku
@app.route('/data_buku/<int:id>', methods=['DELETE'])
def hapus_data_buku(id):
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("DELETE FROM data_buku WHERE id = %s", (id,))
                conn.commit()
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

        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                # Cek mahasiswa
                cursor.execute("SELECT id FROM mahasiswa WHERE id = %s", (id_mahasiswa,))
                if not cursor.fetchone():
                    return jsonify({"error": "Mahasiswa tidak ditemukan"}), 400

                # Cek stok buku
                cursor.execute("SELECT jumlah FROM data_buku WHERE id = %s FOR UPDATE", (id_buku,))
                buku = cursor.fetchone()

                if not buku or buku[0] <= 0:
                    return jsonify({"error": "Stok buku habis"}), 400

                # Kurangi stok
                cursor.execute("UPDATE data_buku SET jumlah = jumlah - 1 WHERE id = %s", (id_buku,))

                # Hapus data peminjaman lama yang statusnya sudah dikembalikan
                cursor.execute("""
                    DELETE FROM peminjaman_buku
                    WHERE id_buku = %s AND status = 'dikembalikan'
                """, (id_buku,))


                # Simpan peminjaman
                cursor.execute("""
                    INSERT INTO peminjaman_buku (id_mahasiswa, id_buku, tanggal_pinjam, tanggal_kembali, status)
                    VALUES (%s, %s, %s, %s, 'dipinjam')
                """, (id_mahasiswa, id_buku, tanggal_pinjam, tanggal_kembali))
                conn.commit()

        return jsonify({"message": "Buku berhasil dipinjam!"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# 🔹 Kembalikan Buku
@app.route('/kembali/<int:id_peminjaman>', methods=['PUT'])
def kembalikan_buku(id_peminjaman):
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                # Cari peminjaman yang masih aktif
                cursor.execute("""
                    SELECT id_buku FROM peminjaman_buku 
                    WHERE id = %s AND status = 'dipinjam'
                """, (id_peminjaman,))
                row = cursor.fetchone()

                if not row:
                    return jsonify({"error": "Data peminjaman tidak ditemukan atau sudah dikembalikan"}), 404

                id_buku = row[0]

                # Update status peminjaman
                cursor.execute("""
                    UPDATE peminjaman_buku SET status = 'dikembalikan' WHERE id = %s
                """, (id_peminjaman,))

                # Tambah stok buku
                cursor.execute("""
                    UPDATE data_buku SET jumlah = jumlah + 1 WHERE id = %s
                """, (id_buku,))

                conn.commit()
                socketio.emit('update_statistik')

        return jsonify({"message": "Buku berhasil dikembalikan!"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/peminjaman_aktif', methods=['GET'])
def peminjaman_aktif():
    try:
        with get_db_connection() as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.execute("""
                SELECT 
                    p.id,
                    p.id_buku,
                    p.id_mahasiswa,
                    m.nama AS nama_mahasiswa,
                    b.judul AS judul_buku,
                    p.tanggal_pinjam,
                    p.tanggal_kembali,
                    p.status
                FROM peminjaman_buku p
                JOIN mahasiswa m ON p.id_mahasiswa = m.id
                JOIN data_buku b ON p.id_buku = b.id
                WHERE p.status = 'dipinjam'
                ORDER BY p.tanggal_pinjam DESC
            """)
                data = cursor.fetchall()

        return jsonify(data), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/pinjam/<int:id>', methods=['PUT'])
def update_peminjaman(id):
    try:
        data = request.json
        id_mahasiswa = data["id_mahasiswa"]
        tanggal_kembali = datetime.strptime(data["tanggal_kembali"], "%Y-%m-%d").date()
        status = data.get("status", "dipinjam")

        with get_db_connection() as conn:
            with conn.cursor() as cursor:
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

        return jsonify({"message": "Data peminjaman berhasil diperbarui"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/peminjaman_user/<npm>', methods=['GET'])
def peminjaman_by_npm(npm):
    try:
        with get_db_connection() as conn:
            with conn.cursor(dictionary=True) as cursor:
                cursor.execute("""
                    SELECT 
                        b.judul AS title,
                        b.no_buku AS isbn,
                        b.foto,
                        p.tanggal_pinjam,
                        p.tanggal_kembali
                    FROM peminjaman_buku p
                    JOIN mahasiswa m ON p.id_mahasiswa = m.id
                    JOIN data_buku b ON p.id_buku = b.id
                    WHERE m.npm = %s AND p.status = 'dipinjam'
                """, (npm,))
                data = cursor.fetchall()

                for d in data:
                    # Tangani foto
                    if isinstance(d["foto"], bytes):
                        d["cover"] = f"data:image/jpeg;base64,{base64.b64encode(d['foto']).decode()}"
                    else:
                        d["cover"] = None

                    # Tangani tanggal
                    d["borrowDate"] = d["tanggal_pinjam"].isoformat() if d["tanggal_pinjam"] else ""
                    d["returnDate"] = d["tanggal_kembali"].isoformat() if d["tanggal_kembali"] else ""

                    # Hapus kolom mentah
                    del d["foto"]
                    del d["tanggal_pinjam"]
                    del d["tanggal_kembali"]

        return jsonify(data), 200

    except Exception as e:
        print(f"❌ Error di /peminjaman_user/<npm>: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/jumlah-buku-dipinjam', methods=['GET'])
def jumlah_buku_dipinjam():
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT COUNT(id_buku) FROM peminjaman_buku")
                jumlah = cursor.fetchone()[0]
        return jsonify({'jumlah': jumlah}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/jumlah-peminjaman-aktif', methods=['GET'])
def jumlah_peminjaman_aktif():
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT COUNT(DISTINCT id_mahasiswa)
                    FROM peminjaman_buku
                    WHERE status = 'dipinjam'
                """)
                jumlah = cursor.fetchone()[0]
        return jsonify({'jumlah': jumlah}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# 🔹 Endpoint Beranda (Health Check)
@app.route('/home')
def home():
    return jsonify({"message": "API Perpustakaan Aktif!"})

# 🔹 Jalankan Server
if __name__ == "__main__":
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
