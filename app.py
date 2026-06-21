from flask import Flask, request, jsonify, render_template
from pyswip import Prolog
import gspread
from google.oauth2.service_account import Credentials
from google import genai
import re
import os
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
gemini_client = genai.Client(api_key=GEMINI_API_KEY)
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
def extract_facts_with_gemini(scenario: str):
    """Returns (role, clearance) extracted from natural language, or None on failure."""
    try:
        response = gemini_client.models.generate_content(
            model="gemini-2.0-flash",
            contents=(
                f"Extract two values from this scenario: the person's role "
                f"(employee, contractor, or guest) and the document's clearance "
                f"level (public, confidential, or restricted). "
                f"Scenario: {scenario}\n"
                f"Respond with ONLY two words separated by a comma, nothing else. "
                f"Example: employee,public"
            )
        )
        text = response.text.strip()
        match = re.match(r"(\w+)\s*,\s*(\w+)", text)
        if match:
            role, clearance = match.group(1), match.group(2)
            return role, clearance
        return None
    except Exception as e:
        print(f"Gemini extraction failed: {e}")
        return None

def check_compliance(scenario: str) -> dict:
    prolog = Prolog()
    prolog.consult("policy.pl")

    extracted = extract_facts_with_gemini(scenario)

    if extracted:
        role, clearance = extracted
        source = "Gemini-extracted"
    else:
        role, clearance = "employee", "public"
        source = "fallback mock (Gemini unavailable)"

    prolog.assertz(f"role(alice, {role})")
    prolog.assertz(f"clearance(report, {clearance})")

    result = list(prolog.query("allowed(alice, read, report)"))

    if result:
        verdict = "COMPLIANT"
        explanation = f"Facts used ({source}): role=alice/{role}, clearance=report/{clearance}. Policy rule allowed(X, read, Y) :- role(X, employee), clearance(Y, public) is satisfied."
    else:
        verdict = "VIOLATION"
        explanation = f"Facts used ({source}): role=alice/{role}, clearance=report/{clearance}. No matching policy rule was satisfied."

    return {
        "verdict": verdict,
        "explanation": explanation,
        "facts": [f"role(alice, {role})", f"clearance(report, {clearance})"]
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
