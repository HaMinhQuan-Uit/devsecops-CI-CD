# app/app.py
from flask import Flask, request
import sqlite3
import subprocess

app = Flask(__name__)
@app.route("/health")
def health():
    return {"status": "ok"}, 200

@app.route("/")
def index():
    return "<h1>DevSecOps Demo App</h1><p>Pipeline security demo</p>"

@app.route("/greet")
def greet():
    name = request.args.get("name", "World")
    return f"<h1>Hello {name}!</h1>"  # KHÔNG escape → XSS
@app.route("/user")
def get_user():
    user_id = request.args.get("id", "")
    conn = sqlite3.connect("app.db")
    query = f"SELECT * FROM users WHERE id = '{user_id}'"  # KHÔNG parameterize → SQLi
    result = conn.execute(query).fetchone()
    conn.close()
    return str(result)


@app.route("/ping")
def ping():
    host = request.args.get("host", "127.0.0.1")
    output = subprocess.check_output(f"ping -c 1 {host}", shell=True)  # shell=True → nguy hiểm
    return output.decode()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
