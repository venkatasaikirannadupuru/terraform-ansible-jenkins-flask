from flask import Flask, request, redirect, render_template_string
import os
import pymysql

app = Flask(__name__)

DB_HOST = os.getenv("DB_HOST")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_NAME = os.getenv("DB_NAME", "employee_db")


def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor
    )


HTML = """
<!DOCTYPE html>
<html>
<head>
    <title><title>Employee Management System - AWS by Venkata Sai kiran</title></title>
</head>
<body>
    <h1>Employee Management System</h1>

    <h2>Add Employee</h2>

    <form method="POST" action="/add">
        <input type="text" name="name" placeholder="Employee Name" required>
        <input type="text" name="role" placeholder="Role" required>
        <button type="submit">Add Employee</button>
    </form>

    <h2>Employees</h2>

    {% for employee in employees %}
        <p>
            {{ employee.name }} - {{ employee.role }}
            <a href="/delete/{{ employee.id }}">Delete</a>
        </p>
    {% else %}
        <p>No employees found.</p>
    {% endfor %}
</body>
</html>
"""


@app.route("/")
def home():
    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM employees ORDER BY id")
            employees = cursor.fetchall()
    finally:
        connection.close()

    return render_template_string(HTML, employees=employees)


@app.route("/add", methods=["POST"])
def add_employee():
    name = request.form["name"]
    role = request.form["role"]

    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "INSERT INTO employees (name, role) VALUES (%s, %s)",
                (name, role)
            )
        connection.commit()
    finally:
        connection.close()

    return redirect("/")


@app.route("/delete/<int:employee_id>")
def delete_employee(employee_id):
    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "DELETE FROM employees WHERE id = %s",
                (employee_id,)
            )
        connection.commit()
    finally:
        connection.close()

    return redirect("/")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
