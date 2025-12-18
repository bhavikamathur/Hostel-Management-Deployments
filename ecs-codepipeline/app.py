# import os
# from datetime import datetime
# from flask import Flask, request, render_template, flash, redirect, url_for
# from sqlalchemy import create_engine, Column, Integer, String, TIMESTAMP, Boolean
# from sqlalchemy.orm import sessionmaker, scoped_session, declarative_base
# from sqlalchemy.sql import func
# from sqlalchemy.exc import IntegrityError
# from dotenv import load_dotenv

# # Load environment variables
# load_dotenv()

# # -------------------- DB CONFIG ---------------------
# DB_USER = os.getenv("DB_USER", "root")
# DB_PASSWORD = os.getenv("DB_PASSWORD", "admin@123")
# DB_HOST = os.getenv("DB_HOST", "hostel-db")
# DB_PORT = os.getenv("DB_PORT", "3306")
# DB_NAME = os.getenv("DB_NAME", "hostel_db")

# DATABASE_URL = (
#     f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
# )

# engine = create_engine(
#     DATABASE_URL,
#     pool_size=10,
#     max_overflow=20,
#     pool_pre_ping=True,
# )

# SessionLocal = scoped_session(sessionmaker(bind=engine))
# Base = declarative_base()

# # -------------------- ORM MODEL ----------------------
# class Student(Base):
#     __tablename__ = "students"

#     id = Column(Integer, primary_key=True)
#     name = Column(String(255), nullable=False)
#     room = Column(String(50), nullable=False)
#     phone = Column(String(50))
#     email = Column(String(255))
#     fees_paid = Column(Boolean, default=False)
#     created_at = Column(TIMESTAMP, server_default=func.now())

# # Auto-create tables
# Base.metadata.create_all(bind=engine)

# # -------------------- FLASK APP ----------------------
# app = Flask(__name__)
# app.secret_key = os.getenv("FLASK_SECRET", "dev-secret")

# @app.context_processor
# def inject_now():
#     return {"now": datetime.utcnow}

# def get_db():
#     db = SessionLocal()
#     try:
#         yield db
#     finally:
#         db.close()

# # -------------------- ROUTES -------------------------

# @app.route("/")
# def index():
#     keyword = request.args.get("keyword", "")
#     db = next(get_db())

#     if keyword:
#         like = f"%{keyword}%"
#         students = db.query(Student).filter(
#             (Student.id.like(like)) |
#             (Student.name.like(like)) |
#             (Student.room.like(like)) |
#             (Student.phone.like(like))
#         ).order_by(Student.created_at.desc()).all()
#     else:
#         students = db.query(Student).order_by(Student.created_at.desc()).all()

#     return render_template("index.html", students=students, keyword=keyword)

# @app.route("/add", methods=["GET", "POST"])
# def add_student():
#     if request.method == "POST":
#         db = next(get_db())
#         try:
#             student = Student(
#                 id=int(request.form["id"]),
#                 name=request.form["name"],
#                 room=request.form["room"],
#                 phone=request.form.get("phone") or None,
#                 email=request.form.get("email") or None,
#             )
#             db.add(student)
#             db.commit()
#             flash("Student added successfully", "success")
#         except IntegrityError:
#             db.rollback()
#             flash("Student ID already exists", "danger")
#         return redirect(url_for("index"))

#     return render_template("add_edit_student.html", action="Add", student=None)

# @app.route("/edit/<int:sid>", methods=["GET", "POST"])
# def edit_student(sid):
#     db = next(get_db())
#     student = db.query(Student).filter_by(id=sid).first()

#     if not student:
#         flash("Student not found", "warning")
#         return redirect(url_for("index"))

#     if request.method == "POST":
#         student.name = request.form["name"]
#         student.room = request.form["room"]
#         student.phone = request.form.get("phone")
#         student.email = request.form.get("email")
#         db.commit()
#         flash("Student updated", "success")
#         return redirect(url_for("index"))

#     return render_template("add_edit_student.html", action="Edit", student=student)

# @app.route("/pay/<int:sid>")
# def pay_fees(sid):
#     db = next(get_db())
#     student = db.query(Student).filter_by(id=sid).first()

#     if student:
#         student.fees_paid = True
#         db.commit()
#         flash("Fees marked as paid", "success")

#     return redirect(url_for("index"))

# @app.route("/delete/<int:sid>", methods=["GET", "POST"])
# def delete_student(sid):
#     db = next(get_db())
#     student = db.query(Student).filter_by(id=sid).first()

#     if request.method == "POST":
#         if student:
#             db.delete(student)
#             db.commit()
#             flash("Student deleted", "success")
#         return redirect(url_for("index"))

#     return render_template("confirm_delete.html", student=student)

# # -------------------- MAIN ---------------------------

# if __name__ == "__main__":
#     app.run(host="0.0.0.0", port=5000)

import os
from datetime import datetime
from flask import Flask, request, render_template, flash, redirect, url_for
from sqlalchemy import create_engine, Column, Integer, String, TIMESTAMP, Boolean
from sqlalchemy.orm import sessionmaker, scoped_session, declarative_base
from sqlalchemy.sql import func
from sqlalchemy.exc import IntegrityError
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# -------------------- DB CONFIG ---------------------
# USE SQLITE INSTEAD OF MYSQL
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///hostel.db")

# SQLite cannot use pool_size/max_overflow. Keep it simple.
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {},
)

SessionLocal = scoped_session(sessionmaker(bind=engine))
Base = declarative_base()

# -------------------- ORM MODEL ----------------------
class Student(Base):
    __tablename__ = "students"

    id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False)
    room = Column(String(50), nullable=False)
    phone = Column(String(50))
    email = Column(String(255))
    fees_paid = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP, server_default=func.now())

# Auto-create tables
Base.metadata.create_all(bind=engine)

# -------------------- FLASK APP ----------------------
app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET", "dev-secret")

@app.context_processor
def inject_now():
    return {"now": datetime.utcnow}

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# -------------------- ROUTES -------------------------

@app.route("/")
def index():
    keyword = request.args.get("keyword", "")
    db = next(get_db())

    if keyword:
        like = f"%{keyword}%"
        students = db.query(Student).filter(
            (Student.id.like(like)) |
            (Student.name.like(like)) |
            (Student.room.like(like)) |
            (Student.phone.like(like))
        ).order_by(Student.created_at.desc()).all()
    else:
        students = db.query(Student).order_by(Student.created_at.desc()).all()

    return render_template("index.html", students=students, keyword=keyword)

@app.route("/add", methods=["GET", "POST"])
def add_student():
    if request.method == "POST":
        db = next(get_db())
        try:
            student = Student(
                id=int(request.form["id"]),
                name=request.form["name"],
                room=request.form["room"],
                phone=request.form.get("phone") or None,
                email=request.form.get("email") or None,
            )
            db.add(student)
            db.commit()
            flash("Student added successfully", "success")
        except IntegrityError:
            db.rollback()
            flash("Student ID already exists", "danger")
        return redirect(url_for("index"))

    return render_template("add_edit_student.html", action="Add", student=None)

@app.route("/edit/<int:sid>", methods=["GET", "POST"])
def edit_student(sid):
    db = next(get_db())
    student = db.query(Student).filter_by(id=sid).first()

    if not student:
        flash("Student not found", "warning")
        return redirect(url_for("index"))

    if request.method == "POST":
        student.name = request.form["name"]
        student.room = request.form["room"]
        student.phone = request.form.get("phone")
        student.email = request.form.get("email")
        db.commit()
        flash("Student updated", "success")
        return redirect(url_for("index"))

    return render_template("add_edit_student.html", action="Edit", student=student)

@app.route("/pay/<int:sid>")
def pay_fees(sid):
    db = next(get_db())
    student = db.query(Student).filter_by(id=sid).first()

    if student:
        student.fees_paid = True
        db.commit()
        flash("Fees marked as paid", "success")

    return redirect(url_for("index"))

@app.route("/delete/<int:sid>", methods=["GET", "POST"])
def delete_student(sid):
    db = next(get_db())
    student = db.query(Student).filter_by(id=sid).first()

    if request.method == "POST":
        if student:
            db.delete(student)
            db.commit()
            flash("Student deleted", "success")
        return redirect(url_for("index"))

    return render_template("confirm_delete.html", student=student)

# -------------------- MAIN ---------------------------

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
