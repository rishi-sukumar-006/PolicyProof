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
            model="gemini-1.5-flash",
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
        source = "extracted from your scenario by Gemini"
    else:
        role, clearance = "employee", "public"
        source = "demonstration facts (Gemini quota unavailable — using representative role='employee', clearance='public' rather than parsing this exact scenario)"

    prolog.assertz(f"role(alice, {role})")
    prolog.assertz(f"clearance(report, {clearance})")

    result = list(prolog.query("allowed(alice, read, report)"))

    if result:
        verdict = "COMPLIANT"
        explanation = (
            f"Facts used ({source}): role=alice/{role}, clearance=report/{clearance}.\n\n"
            f"Rule checked: allowed(X, read, Y) :- role(X, employee), clearance(Y, public).\n\n"
            f"role(alice, {role}) matches 'employee' — TRUE\n"
            f"clearance(report, {clearance}) matches 'public' — TRUE\n\n"
            f"Both conditions satisfied. Access is COMPLIANT."
        )
    else:
        verdict = "VIOLATION"
        explanation = (
            f"Facts used ({source}): role=alice/{role}, clearance=report/{clearance}.\n\n"
            f"Rule checked: allowed(X, read, Y) :- role(X, employee), clearance(Y, public).\n\n"
            f"role(alice, {role}) matches 'employee' — {'TRUE' if role == 'employee' else 'FALSE'}\n"
            f"clearance(report, {clearance}) matches 'public' — {'TRUE' if clearance == 'public' else 'FALSE'}\n\n"
            f"At least one condition failed. Access is a VIOLATION."
        )

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
    verdict = "APPROVED" if result else "REJECTED"

    # Build a step-by-step reasoning chain
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
        chain.append(f"4. Checking rule: approved(Txn) :- transaction(Txn, Amount, _), Amount < 50000, \\+ fraud_flag(Txn).")
        chain.append(f"5. {amount} < 50000 — TRUE")
        chain.append("6. Rule SATISFIED — auto-approval tier")
        reason = f"Transaction auto-approved: ₹{amount} is under the ₹50,000 threshold with no fraud flag."
    elif 50000 <= amount <= 500000:
        chain.append(f"4. Checking rule: approved(Txn) :- transaction(Txn, Amount, _), Amount >= 50000, Amount =< 500000, manager_signoff(Txn), \\+ fraud_flag(Txn).")
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
        chain.append(f"4. Checking rule: approved(Txn) :- transaction(Txn, Amount, _), Amount > 500000, manager_signoff(Txn), \\+ fraud_flag(Txn).")
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
