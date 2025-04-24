# from flask import Flask, jsonify
# from flask_socketio import SocketIO
# import mysql.connector

# app = Flask(__name__)
# socketio = SocketIO(app, cors_allowed_origins="*")

# # Koneksi ke MySQL
# db = mysql.connector.connect(
#     host="localhost",
#     user="root",
#     password="",
#     database="perpustakaan"
# )

# def get_online_users():
#     cursor = db.cursor(dictionary=True)
#     cursor.execute("SELECT COUNT(*) AS total FROM users WHERE status = 'online'")
#     result = cursor.fetchone()
#     cursor.close()
#     return result['total']

# @app.route('/total_users')
# def total_users():
#     cursor = db.cursor(dictionary=True)
#     cursor.execute("SELECT COUNT(*) AS total FROM users")
#     result = cursor.fetchone()
#     cursor.close()
#     return jsonify(result)

# @socketio.on("get_online_users")
# def send_online_users():
#     total_online = get_online_users()
#     socketio.emit("update_online_users", {"online_users": total_online})

# if __name__ == '__main__':
#     socketio.run(app, host="0.0.0.0", port=5000, debug=True)
