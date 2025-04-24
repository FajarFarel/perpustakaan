import os 
from database import get_connection
from werkzeug.utils import secure_filename

UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

class Buku:
    @staticmethod
    def buku(isbn, judul, author, harga, stock, deskripsi,cover):
        conn = get_connection()
        cursor = conn.cursor()
        try:
            if cover:
                filename = secure_filename(cover.filename)
                file_path = os.path.join(UPLOAD_FOLDER, filename)
                cover.save(file_path)
            else:
                file_path = None
            sql = """INSERT INTO buku (isbn, judul, author, harga, stock, deskripsi, cover)
                     VALUES (%s, %s, %s, %s, %s, %s, %s)"""
            cursor.execute(sql, (isbn, judul, author, harga, stock, deskripsi, file_path))
            conn.commit()
            return True
        except Exception as e:
            print("Error:", e)
            return False
        finally:
            cursor.close()
            conn.close()