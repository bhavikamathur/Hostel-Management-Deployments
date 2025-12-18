import os
from flask import Flask, render_template, request, redirect, session, url_for, flash
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)

# -----------------------------
#           CONFIG
# -----------------------------
app.secret_key = os.getenv("SECRET_KEY", "defaultsecret")

DB_HOST = os.getenv("DB_HOST")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_NAME = os.getenv("DB_NAME")

app.config['SQLALCHEMY_DATABASE_URI'] = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# -----------------------------
#           MODELS
# -----------------------------
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(100), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)

class Review(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    movie = db.Column(db.String(200), nullable=False)
    content = db.Column(db.Text, nullable=False)
    rating = db.Column(db.Integer, nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"))
    user = db.relationship("User", backref="reviews")

# -----------------------------
#           ROUTES
# -----------------------------
@app.route("/")
def index():
    reviews = Review.query.order_by(Review.id.desc()).all()
    return render_template("index.html", reviews=reviews)


# -----------------------------
#       AUTH ROUTES
# -----------------------------
@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        username = request.form["username"]
        email = request.form["email"]
        password = generate_password_hash(request.form["password"])

        if User.query.filter_by(email=email).first():
            flash("Email already registered!", "danger")
            return redirect("/register")

        new_user = User(username=username, email=email, password=password)
        db.session.add(new_user)
        db.session.commit()

        flash("Registration successful! Please log in.", "success")
        return redirect("/login")

    return render_template("register.html")


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form["email"]
        password = request.form["password"]

        user = User.query.filter_by(email=email).first()

        if user and check_password_hash(user.password, password):
            session["user_id"] = user.id
            session["username"] = user.username
            return redirect("/")

        flash("Invalid credentials", "danger")
        return redirect("/login")

    return render_template("login.html")


@app.route("/logout")
def logout():
    session.clear()
    return redirect("/")


# -----------------------------
#       REVIEW ROUTES
# -----------------------------
@app.route("/new_review", methods=["GET", "POST"])
def new_review():
    if "user_id" not in session:
        return redirect("/login")

    if request.method == "POST":
        movie = request.form["movie"]
        content = request.form["content"]
        rating = request.form["rating"]

        review = Review(
            movie=movie,
            content=content,
            rating=int(rating),
            user_id=session["user_id"]
        )

        db.session.add(review)
        db.session.commit()
        return redirect("/")

    return render_template("new_review.html")


@app.route("/review/<int:id>")
def view_review(id):
    review = Review.query.get_or_404(id)
    return render_template("view_review.html", review=review)


# -----------------------------
#       SEARCH ROUTE
# -----------------------------
@app.route("/search")
def search():
    q = request.args.get("q", "")
    results = []

    if q:
        results = Review.query.filter(Review.movie.ilike(f"%{q}%")).all()

    return render_template("search_results.html", results=results, q=q)


# -----------------------------
#       USERS LIST
# -----------------------------
@app.route("/users")
def users_list():
    users = User.query.all()
    return render_template("users_list.html", users=users)


# -----------------------------
#       USER PROFILE
# -----------------------------
@app.route("/profile/<int:id>")
def user_profile(id):
    user = User.query.get_or_404(id)
    return render_template("user_profile.html", user=user)


# -----------------------------
#       RUN APP (LOCAL ONLY)
# -----------------------------
if __name__ == "__main__":
    app.run(debug=True)
