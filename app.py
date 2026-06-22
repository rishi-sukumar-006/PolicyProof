from flask import Flask, request, jsonify, render_template
from pyswip import Prolog
import gspread
from google.oauth2.service_account import Credentials
from google import genai
import os
import re

app = Flask(__name__)

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
gemini_client = genai.Client(api_key=GEMINI_API_KEY) if GEMINI_API_KEY else None

SHEET_ID = "1myCS3mZRzTKlIqw1Aig_AHJLacEKuGgfOIr8Hxjd2E0"

def extract_person_name(text):
    match = re.search(r"\b([A-Z][a-z]+)\b", text)
    if match:
        return match.group(1).lower()
    return "user"

def get_rules_from_sheets():
    creds = Credentials.from_service_account_file(
        "credentials.json",
        scopes=["https://www.googleapis.com/auth/spreadsheets"]
    )
    client = gspread.authorize(creds)
    sheet = client.open_by_key(SHEET_ID).sheet1
    records = sheet.get_all_records()
    return records

def extract_facts_local(scenario: str):
    """Simple keyword-based extraction — no API needed, always available."""
    text = scenario.lower()

    if "contractor" in text:
        role = "contractor"
    elif "guest" in text:
        role = "guest"
    else:
        role = "employee"

    if "restricted" in text:
        clearance = "restricted"
    elif "confidential" in text:
        clearance = "confidential"
    else:
        clearance = "public"
    return role, clearance


def check_compliance(scenario: str) -> dict:
    prolog = Prolog()
    prolog.consult("policy.pl")

    try:
        extracted = extract_facts_with_gemini(scenario)
    except NameError:
        extracted = None
    except Exception:
        extracted = None

    if extracted:
        role, clearance = extracted
    else:
        role, clearance = extract_facts_local(scenario)

        person = extract_person_name(scenario)

        prolog.assertz(f"role({person}, {role})")
        prolog.assertz(f"clearance(report, {clearance})")

        result = list(prolog.query(f"allowed({person}, read, report)"))

    if result:
        verdict = "COMPLIANT"
        explanation = (
            f"Facts: role({person}, {role}), clearance(report, {clearance}).\n\n"
            f"Rule checked: allowed(X, read, Y) :- role(X, employee), clearance(Y, public).\n\n"
            f"role({person}, {role}) matches 'employee' — "
            f"{'TRUE' if role == 'employee' else 'FALSE'}\n"
            f"clearance(report, {clearance}) matches 'public' — "
            f"{'TRUE' if clearance == 'public' else 'FALSE'}\n\n"
            f"Both conditions satisfied. Access is COMPLIANT."
        )
    else:
        verdict = "VIOLATION"
        explanation = (
	    f"Facts: role({person}, {role}), clearance(report, {clearance}).\n\n"
            f"Rule checked: allowed(X, read, Y) :- role(X, employee), clearance(Y, public).\n\n"
            f"role({person}, {role}) matches 'employee' — "
            f"{'TRUE' if role == 'employee' else 'FALSE'}\n"
            f"clearance(report, {clearance}) matches 'public' — "
            f"{'TRUE' if clearance == 'public' else 'FALSE'}\n\n"
            f"At least one condition failed. Access is a VIOLATION."
        )

    return {
        "verdict": verdict,
        "explanation": explanation,
        "facts": [
            f"role(alice, {role})",
            f"clearance(report, {clearance})"
        ]
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
    verdict = "APPROVED" if result else "REJECTED"

    chain = []
    chain.append(f"1. Fact asserted: transaction(txn_demo, {amount}, demo_user)")
    chain.append(f"2. Fact asserted: manager_signoff(txn_demo) = {'TRUE' if has_signoff else 'NOT FOUND'}")
    chain.append(f"3. Fact asserted: fraud_flag(txn_demo) = {'TRUE' if has_fraud_flag else 'NOT FOUND'}")

    if has_fraud_flag and not has_signoff:
        chain.append("4. Checking rule: approved(Txn) :- fraud_flag(Txn), senior_cleared(Txn).")
        chain.append("5. senior_cleared(txn_demo) — NOT FOUND")
        chain.append("6. Rule FAILED — fraud flag present with no senior clearance")
        reason = "Transaction blocked: fraud flag present and not senior-cleared."
    elif amount < 50000 and not has_fraud_flag:
        chain.append("4. Checking rule: approved(Txn) :- transaction(Txn, Amount, _), Amount < 50000, \\+ fraud_flag(Txn).")
        chain.append(f"5. {amount} < 50000 — TRUE")
        chain.append("6. Rule SATISFIED — auto-approval tier")
        reason = f"Transaction auto-approved: ₹{amount} is under the ₹50,000 threshold with no fraud flag."
    elif 50000 <= amount <= 500000:
        chain.append("4. Checking rule: approved(Txn) :- transaction(Txn, Amount, _), Amount >= 50000, Amount =< 500000, manager_signoff(Txn), \\+ fraud_flag(Txn).")
        chain.append(f"5. {amount} falls in mid-tier range — TRUE")
        if has_signoff:
            chain.append("6. manager_signoff(txn_demo) — TRUE")
            chain.append("7. Rule SATISFIED")
            reason = f"Transaction approved: ₹{amount} is in the mid-tier range and manager signoff was confirmed."
        else:
            chain.append("6. manager_signoff(txn_demo) — NOT FOUND")
            chain.append("7. Rule FAILED — signoff required for this tier")
            reason = f"Transaction blocked: ₹{amount} requires manager signoff, which was not provided."
    elif amount > 500000:
        chain.append("4. Checking rule: approved(Txn) :- transaction(Txn, Amount, _), Amount > 500000, manager_signoff(Txn), \\+ fraud_flag(Txn).")
        chain.append(f"5. {amount} > 500000 — TRUE")
        if has_signoff:
            chain.append("6. manager_signoff(txn_demo) — TRUE")
            chain.append("7. Rule SATISFIED")
            reason = f"Transaction approved: ₹{amount} exceeds the high-value threshold but manager signoff was confirmed."
        else:
            chain.append("6. manager_signoff(txn_demo) — NOT FOUND")
            chain.append("7. Rule FAILED — high-value transactions require signoff")
            reason = f"Transaction blocked: ₹{amount} exceeds the high-value threshold and requires manager signoff."
    else:
        reason = "No applicable rule matched."

    full_explanation = "\n".join(chain) + f"\n\nFinal verdict: {reason}"

    return {
        "verdict": verdict,
        "explanation": full_explanation,
        "facts": [f"transaction(txn_demo, {amount}, demo_user)"]
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

