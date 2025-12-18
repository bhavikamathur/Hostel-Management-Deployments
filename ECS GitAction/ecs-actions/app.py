import os
from datetime import datetime
from flask import Flask, request, render_template, flash, redirect, url_for, session
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy import create_engine, Column, Integer, String, TIMESTAMP, Boolean
from sqlalchemy.orm import sessionmaker, scoped_session, declarative_base
from sqlalchemy.sql import func
from dotenv import load_dotenv

# Load env
load_dotenv()

# Config
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///hostel.db")
FLASK_SECRET = os.getenv("FLASK_SECRET", "dev-secret-change-me")
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "admin@hostel.com")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "admin123")

# DB setup
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {},
    pool_pre_ping=True,
)
SessionLocal = scoped_session(sessionmaker(bind=engine))
Base = declarative_base()

# Model
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False)
    username = Column(String(150), unique=True, nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    room = Column(String(50))
    phone = Column(String(50))
    fees_paid = Column(Boolean, default=False)
    role = Column(String(20), default="student")  # admin or student
    created_at = Column(TIMESTAMP, server_default=func.now())

Base.metadata.create_all(bind=engine)

# App
app = Flask(__name__, template_folder="templates", static_folder="static")
app.secret_key = FLASK_SECRET

# Helpers
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def current_user():
    uid = session.get("user_id")
    if not uid:
        return None
    db = next(get_db())
    user = db.query(User).filter_by(id=uid).first()
    db.close()
    return user

def login_user(user):
    session["user_id"] = user.id
    session["role"] = user.role

def logout_user():
    session.pop("user_id", None)
    session.pop("role", None)

def create_default_admin():
    db = next(get_db())
    admin = db.query(User).filter_by(role="admin").first()
    if not admin:
        admin_username = ADMIN_EMAIL.split("@")[0]
        admin_user = User(
            name="Admin",
            username=admin_username,
            email=ADMIN_EMAIL,
            password_hash=generate_password_hash(ADMIN_PASSWORD),
            room=None,
            phone=None,
            fees_paid=True,
            role="admin"
        )
        db.add(admin_user)
        db.commit()
    db.close()

create_default_admin()

@app.context_processor
def inject_now():
    return {"now": datetime.utcnow}

# Routes
@app.route("/")
def home():
    user = current_user()
    if not user:
        return redirect(url_for("login"))
    return redirect(url_for("admin_dashboard") if user.role == "admin" else url_for("dashboard"))

# Register
@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        name = request.form.get("name", "").strip()
        username = request.form.get("username", "").strip()
        email = request.form.get("email", "").strip().lower()
        password = request.form.get("password", "")
        room = request.form.get("room", "").strip()
        phone = request.form.get("phone", "").strip() or None

        if not (name and username and email and password):
            flash("Please fill required fields", "danger")
            return redirect(url_for("register"))

        db = next(get_db())

        # Check duplicates
        if db.query(User).filter((User.username == username) | (User.email == email)).first():
            flash("Username or email already exists", "warning")
            db.close()
            return redirect(url_for("register"))

        user = User(
            name=name,
            username=username,
            email=email,
            password_hash=generate_password_hash(password),
            room=room or None,
            phone=phone,
            fees_paid=False,
            role="student"
        )

        db.add(user)
        db.commit()
        db.close()

        flash("Account created. Please login.", "success")
        return redirect(url_for("login"))

    return render_template("register.html")

# Login
@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username_or_email = request.form.get("username_or_email", "").strip()
        password = request.form.get("password", "")

        db = next(get_db())
        user = db.query(User).filter(
            (User.username == username_or_email) | (User.email == username_or_email)
        ).first()
        db.close()

        if user and check_password_hash(user.password_hash, password):
            login_user(user)
            return redirect(url_for("admin_dashboard") if user.role == "admin" else url_for("dashboard"))

        flash("Invalid credentials", "danger")
        return redirect(url_for("login"))

    return render_template("login.html")

# Logout
@app.route("/logout")
def logout():
    logout_user()
    flash("Logged out", "info")
    return redirect(url_for("login"))

# Student dashboard
@app.route("/dashboard")
def dashboard():
    user = current_user()
    if not user or user.role != "student":
        return redirect(url_for("login"))
    return render_template("student_dashboard.html", user=user)

# Profile
@app.route("/profile", methods=["GET", "POST"])
def profile():
    user = current_user()
    if not user:
        return redirect(url_for("login"))

    db = next(get_db())
    u = db.query(User).filter_by(id=user.id).first()

    if request.method == "POST":
        u.name = request.form.get("name", u.name)
        phone = request.form.get("phone", u.phone)

        if phone and (not phone.isdigit() or len(phone) != 10):
            flash("Phone number must be exactly 10 digits.", "danger")
            db.close()
            return redirect(url_for("profile"))

        u.phone = phone

        if u.role == "admin":
            u.room = request.form.get("room", u.room)

        db.commit()
        db.close()
        flash("Profile updated successfully.", "success")
        return redirect(url_for("dashboard") if u.role == "student" else url_for("admin_dashboard"))

    db.close()
    return render_template("profile.html", user=u)

# Admin dashboard
@app.route("/admin")
def admin_dashboard():
    user = current_user()
    if not user or user.role != "admin":
        return redirect(url_for("login"))

    db = next(get_db())
    students = db.query(User).filter(User.role == "student").order_by(User.created_at.asc()).all()
    db.close()

    return render_template("admin_dashboard.html", students=students)

# Admin add student
@app.route("/admin/add", methods=["GET", "POST"])
def admin_add_student():
    user = current_user()
    if not user or user.role != "admin":
        return redirect(url_for("login"))

    if request.method == "POST":
        name = request.form.get("name", "").strip()
        username = request.form.get("username", "").strip()
        email = request.form.get("email", "").strip().lower()
        password = request.form.get("password", "").strip()
        room = request.form.get("room", "").strip()
        phone = request.form.get("phone", "").strip() or None

        if not (name and username and email and password):
            flash("Name, Username, Email, and Password are required.", "danger")
            return redirect(url_for("admin_add_student"))

        if phone and (not phone.isdigit() or len(phone) != 10):
            flash("Phone number must be exactly 10 digits.", "danger")
            return redirect(url_for("admin_add_student"))

        db = next(get_db())

        if db.query(User).filter((User.username == username) | (User.email == email)).first():
            flash("Username or email already exists.", "warning")
            db.close()
            return redirect(url_for("admin_add_student"))

        student = User(
            name=name,
            username=username,
            email=email,
            password_hash=generate_password_hash(password),
            room=room or None,
            phone=phone,
            fees_paid=False,
            role="student"
        )

        db.add(student)
        db.commit()
        db.close()

        flash("Student added successfully.", "success")
        return redirect(url_for("admin_dashboard"))

    return render_template("add_edit_student.html", action="Add", student=None)

# Admin edit student
@app.route("/admin/edit/<int:uid>", methods=["GET", "POST"])
def admin_edit_student(uid):
    user = current_user()
    if not user or user.role != "admin":
        return redirect(url_for("login"))

    db = next(get_db())
    student = db.query(User).filter_by(id=uid, role="student").first()

    if not student:
        db.close()
        flash("Student not found", "warning")
        return redirect(url_for("admin_dashboard"))

    if request.method == "POST":
        student.name = request.form.get("name", student.name)
        student.room = request.form.get("room", student.room)
        phone = request.form.get("phone", student.phone)

        if phone and (not phone.isdigit() or len(phone) != 10):
            flash("Phone number must be exactly 10 digits.", "danger")
            db.close()
            return redirect(url_for("admin_edit_student", uid=uid))

        student.phone = phone

        db.commit()
        db.close()
        flash("Student updated successfully.", "success")
        return redirect(url_for("admin_dashboard"))

    db.close()
    return render_template("add_edit_student.html", action="Edit", student=student)

# Admin mark paid
@app.route("/admin/mark_paid/<int:uid>", methods=["POST"])
def admin_mark_paid(uid):
    user = current_user()
    if not user or user.role != "admin":
        return ("", 403)

    db = next(get_db())
    student = db.query(User).filter_by(id=uid, role="student").first()

    if student:
        student.fees_paid = True
        db.commit()

    db.close()
    flash("Marked fees as paid", "success")
    return redirect(url_for("admin_dashboard"))

# Admin delete student
@app.route("/admin/delete/<int:uid>", methods=["POST"])
def admin_delete(uid):
    user = current_user()
    if not user or user.role != "admin":
        return ("", 403)

    db = next(get_db())
    student = db.query(User).filter_by(id=uid, role="student").first()

    if student:
        db.delete(student)
        db.commit()

    db.close()
    flash("Student removed", "info")
    return redirect(url_for("admin_dashboard"))

# Run
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)), debug=True)
