import os
from database import get_connection
from werkzeug.utils import secure_filename
from flask import Blueprint, request, jsonify

UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

buku_bp = Blueprint('buku', __name__)

 