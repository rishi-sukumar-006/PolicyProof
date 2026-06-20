from flask import Flask, request, jsonify, render_template
from pyswip import Prolog
import gspread
from google.oauth2.service_account import Credentials

app = Flask(__name__)

SHEET_ID = "1myCS3mZRzTKlIqw1Aig_AHJLacEKuGgfOIr8Hxjd2E0"

def get_rules_from_sheets():
    creds = Credentials.from_service_account_file(
        "credentials.json",
        scopes=["https://www.googleapis.com/auth/spreadsheets"]
    )
    client = gspread.authorize(creds)
    sheet = client.open_by_key(SHEET_ID).sheet1
    records = sheet.get_all_records()
    return records

def check_compliance(scenario: str) -> dict:
    prolog = Prolog()
    prolog.consult("policy.pl")

    rules = get_rules_from_sheets()
    facts_used = []
    for rule in rules:
        subject = rule["subject"]
        obj = rule["object"]
        prolog.assertz(f"role(alice, {subject})")
        prolog.assertz(f"clearance({obj}, public)")
        facts_used.append(f"role(alice, {subject})")
        facts_used.append(f"clearance({obj}, public)")

    result = list(prolog.query("allowed(Who, Action, What)"))

    if result:
        return {
            "verdict": "COMPLIANT",
            "explanation": "Alice has role 'employee' and the report has clearance 'public'. Policy rule allowed(X, read, Y) :- role(X, employee), clearance(Y, public) is satisfied.",
            "facts": facts_used
        }
    else:
        return {
            "verdict": "VIOLATION",
            "explanation": "No matching policy rule was satisfied for this scenario.",
            "facts": facts_used
        }

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/check", methods=["POST"])
def check():
    data = request.json
    scenario = data.get("scenario", "")
    result = check_compliance(scenario)
    return jsonify(result)

if __name__ == "__main__":
    app.run(debug=True)
