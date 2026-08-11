from flask import Flask, request, render_template
import sqlite3
import subprocess

app = Flask(__name__)


@app.route("/health")
def health():
    return {"status": "ok"}, 200


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/greet")
def greet():
    name = request.args.get("name", "World")
    return render_template("greet.html", name=name)


@app.route("/user")
def get_user():
    user_id = request.args.get("id", "")
    conn = sqlite3.connect("app.db")
    result = conn.execute(
        "SELECT * FROM users WHERE id = ?", (user_id,)
    ).fetchone()
    conn.close()
    return str(result)


@app.route("/ping")
def ping():
    host = request.args.get("host", "127.0.0.1")
    parts = host.split(".")
    if len(parts) != 4 or not all(p.isdigit() and 0 <= int(p) <= 255 for p in parts):
        return {"error": "Invalid IP address"}, 400
    output = subprocess.check_output(["ping", "-c", "1", host])
    return output.decode()


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=False)
