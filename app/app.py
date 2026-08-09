from flask import Flask, request, escape
import sqlite3
import subprocess
import shlex

app = Flask(__name__)


@app.route("/health")
def health():
    return {"status": "ok"}, 200


@app.route("/")
def index():
    return "<h1>DevSecOps Demo App</h1><p>Pipeline security demo</p>"


# ✅ FIX XSS: dùng escape() để sanitize input
@app.route("/greet")
def greet():
    name = request.args.get("name", "World")
    safe_name = escape(name)
    return f"<h1>Hello {safe_name}!</h1>"


# ✅ FIX SQLi: dùng parameterized query
@app.route("/user")
def get_user():
    user_id = request.args.get("id", "")
    conn = sqlite3.connect("app.db")
    result = conn.execute(
        "SELECT * FROM users WHERE id = ?", (user_id,)
    ).fetchone()
    conn.close()
    return str(result)


# ✅ FIX Command Injection: validate input, không dùng shell=True
@app.route("/ping")
def ping():
    host = request.args.get("host", "127.0.0.1")
    # Chỉ cho phép IP address format
    parts = host.split(".")
    if len(parts) != 4 or not all(p.isdigit() and 0 <= int(p) <= 255 for p in parts):
        return {"error": "Invalid IP address"}, 400
    output = subprocess.check_output(["ping", "-c", "1", host])
    return output.decode()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
