import pymysql
from config import DB_HOST, DB_USER, DB_PASSWORD, DB_NAME

def get_connection():
    try:
        conn = pymysql.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            cursorclass=pymysql.cursors.DictCursor
        )
        print("✅ Koneksi ke database berhasil")
        return conn
    except pymysql.MySQLError as e:
        print(f"❌ Gagal koneksi ke database: {e}")
        return None
