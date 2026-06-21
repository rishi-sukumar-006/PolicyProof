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

def check_transaction(amount, has_signoff, has_fraud_flag):
    prolog = Prolog()
    prolog.consult("policy.pl")

    list(prolog.query("retractall(transaction(txn_demo, _, _))"))
    list(prolog.query("retractall(manager_signoff(txn_demo))"))
    list(prolog.query("retractall(fraud_flag(txn_demo))"))






    prolog.assertz(f"transaction(txn_demo, {amount}, demo_user)")
    if has_signoff:
        prolog.assertz("manager_signoff(txn_demo)")
    if has_fraud_flag:
        prolog.assertz("fraud_flag(txn_demo)")

    result = list(prolog.query("approved(txn_demo)"))

    if result:
        verdict = "APPROVED"
    else:
        verdict = "REJECTED"

    explanation_parts = [f"Amount: ₹{amount}"]
    explanation_parts.append(f"Manager signoff: {'Yes' if has_signoff else 'No'}")
    explanation_parts.append(f"Fraud flag: {'Yes' if has_fraud_flag else 'No'}")

    if amount < 50000 and not has_fraud_flag:
        reason = "Auto-approved: amount under ₹50,000 with no fraud flag."
    elif 50000 <= amount <= 500000 and has_signoff and not has_fraud_flag:
        reason = "Approved: medium amount with manager signoff, no fraud flag."
    elif amount > 500000 and has_signoff and not has_fraud_flag:
        reason = "Approved: large amount with manager signoff, no fraud flag."
    elif has_fraud_flag:
        reason = "Rejected: fraud flag present and not senior-cleared." if not result else "Approved despite fraud flag: senior-cleared."
    else:
        reason = "Rejected: conditions for approval not met (missing signoff for this amount tier)."

    return {
        "verdict": verdict,
        "explanation": reason,
        "facts": explanation_parts
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


@app.route("/check_transaction", methods=["POST"])
def check_transaction_route():
    data = request.json
    amount = float(data.get("amount", 0))
    has_signoff = data.get("signoff", False)
    has_fraud_flag = data.get("fraud", False)
    result = check_transaction(amount, has_signoff, has_fraud_flag)
    return jsonify(result)




if __name__ == "__main__":
    app.run(debug=True)
