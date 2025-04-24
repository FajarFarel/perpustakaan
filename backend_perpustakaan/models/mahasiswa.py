import os
import bcrypt
from database import get_connection
from werkzeug.utils import secure_filename

# Folder untuk menyimpan gambar
UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

class Mahasiswa:
    @staticmethod
    def register(nama, alamat, npm, noTelp, email, password, foto):
        conn = get_connection()
        cursor = conn.cursor()
        try:
            # Hash password sebelum disimpan
            hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

            # Cek apakah file gambar ada
            if foto:
                filename = secure_filename(foto.filename)  # Nama file aman
                file_path = os.path.join(UPLOAD_FOLDER, filename)  # Path penyimpanan
                foto.save(file_path)  # Simpan gambar ke folder
            else:
                file_path = None  # Jika tidak ada gambar

            # Simpan ke database
            sql = """INSERT INTO mahasiswa (nama, alamat, npm, noTelp, email, password, foto)
                     VALUES (%s, %s, %s, %s, %s, %s, %s)"""
            cursor.execute(sql, (nama, alamat, npm, noTelp, email, hashed_password, file_path))
            conn.commit()
            return True
        except Exception as e:
            print("Error:", e)
            return False
        finally:
            cursor.close()
            conn.close()
