import os
import bcrypt
from flask import Blueprint, request, jsonify
from werkzeug.utils import secure_filename
from database import get_connection

# Konfigurasi folder upload
UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

mahasiswa_bp = Blueprint('mahasiswa', __name__)

# Route untuk mendaftarkan mahasiswa baru
@mahasiswa_bp.route('/mahasiswa/register', methods=['POST'])
def register_mahasiswa():
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        nama = request.form.get('nama')
        alamat = request.form.get('alamat')
        npm = request.form.get('npm')
        noTelp = request.form.get('noTelp')
        email = request.form.get('email')
        password = request.form.get('password')
        foto = request.files.get('foto')  # Ambil file foto jika ada
        
        # Hash password sebelum disimpan
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

        # Cek apakah file gambar ada
        if foto:
            filename = secure_filename(foto.filename)  # Nama file aman
            file_path = os.path.join(UPLOAD_FOLDER, filename)  # Path penyimpanan
            foto.save(file_path)  # Simpan gambar ke folder
            foto_url = f"/{UPLOAD_FOLDER}/{filename}"  # Path untuk disimpan di database
        else:
            foto_url = None  # Jika tidak ada gambar

        # Simpan ke database
        sql = """INSERT INTO mahasiswa (nama, alamat, npm, noTelp, email, password, foto)
                 VALUES (%s, %s, %s, %s, %s, %s, %s)"""
        cursor.execute(sql, (nama, alamat, npm, noTelp, email, hashed_password, foto_url))
        conn.commit()

        return jsonify({"message": "Mahasiswa berhasil didaftarkan!"}), 201

    except Exception as e:
        print("Error:", e)
        return jsonify({"message": "Terjadi kesalahan saat mendaftar mahasiswa"}), 500

    finally:
        cursor.close()
        conn.close()

# Route untuk mendapatkan data mahasiswa berdasarkan ID
@mahasiswa_bp.route('/mahasiswa/<int:id>', methods=['GET'])
def get_mahasiswa(id):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        sql = "SELECT id, nama, alamat, npm, noTelp, email, foto FROM mahasiswa WHERE id = %s"
        cursor.execute(sql, (id,))
        mahasiswa = cursor.fetchone()

        if mahasiswa:
            return jsonify(mahasiswa)
        else:
            return jsonify({"message": "Mahasiswa tidak ditemukan"}), 404

    except Exception as e:
        print("Error:", e)
        return jsonify({"message": "Terjadi kesalahan saat mengambil data mahasiswa"}), 500

    finally:
        cursor.close()
        conn.close()

# Route untuk mendapatkan semua mahasiswa
@mahasiswa_bp.route('/mahasiswa', methods=['GET'])
def get_all_mahasiswa():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        sql = "SELECT id, nama, alamat, npm, noTelp, email, foto FROM mahasiswa"
        cursor.execute(sql)
        mahasiswa_list = cursor.fetchall()

        return jsonify(mahasiswa_list)

    except Exception as e:
        print("Error:", e)
        return jsonify({"message": "Terjadi kesalahan saat mengambil data mahasiswa"}), 500

    finally:
        cursor.close()
        conn.close()

# Route untuk mengupdate data mahasiswa
@mahasiswa_bp.route('/mahasiswa/<int:id>', methods=['PUT'])
def update_mahasiswa(id):
    conn = get_connection()
    cursor = conn.cursor()

    try:
        data = request.json
        sql = """UPDATE mahasiswa 
                 SET nama = %s, alamat = %s, npm = %s, noTelp = %s, email = %s 
                 WHERE id = %s"""
        cursor.execute(sql, (data['nama'], data['alamat'], data['npm'], data['noTelp'], data['email'], id))
        conn.commit()

        return jsonify({"message": "Mahasiswa berhasil diperbarui"}), 200

    except Exception as e:
        print("Error:", e)
        return jsonify({"message": "Terjadi kesalahan saat mengupdate mahasiswa"}), 500

    finally:
        cursor.close()
        conn.close()

# Route untuk menghapus mahasiswa
@mahasiswa_bp.route('/mahasiswa/<int:id>', methods=['DELETE'])
def delete_mahasiswa(id):
    conn = get_connection()
    cursor = conn.cursor()

    try:
        sql = "DELETE FROM mahasiswa WHERE id = %s"
        cursor.execute(sql, (id,))
        conn.commit()

        return jsonify({"message": "Mahasiswa berhasil dihapus"}), 200

    except Exception as e:
        print("Error:", e)
        return jsonify({"message": "Terjadi kesalahan saat menghapus mahasiswa"}), 500

    finally:
        cursor.close()
        conn.close()
