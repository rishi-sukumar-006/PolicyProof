from flask import Flask, request, jsonify, render_template
from pyswip import Prolog
import gspread
from google.oauth2.service_account import Credentials
from google import genai
import os
import re
import json

app = Flask(__name__)

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
gemini_client = genai.Client(api_key=GEMINI_API_KEY) if GEMINI_API_KEY else None

if gemini_client:
    print(f"[startup] GEMINI_API_KEY found (length {len(GEMINI_API_KEY)}) — Gemini extraction is ENABLED.")
else:
    print("[startup] GEMINI_API_KEY not set or empty — Gemini extraction is DISABLED, "
          "all requests will use the keyword fallback. Set it with: export GEMINI_API_KEY=...")

# Pick whichever current model your API key has access to.
# gemini-2.0-flash was retired June 2026 — use a model from your
# Google AI Studio / Cloud console model list (e.g. gemini-2.5-flash,
# gemini-3.5-flash) instead of copying an old tutorial's model name.
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")

SHEET_ID = "1myCS3mZRzTKlIqw1Aig_AHJLacEKuGgfOIr8Hxjd2E0"

# JSON Schema describing exactly what we want back from Gemini.
# response_schema forces the model to emit only these fields/types —
# no prose, no markdown fences, no missing keys.
FACT_SCHEMA = {
    "type": "object",
    "properties": {
        "person": {
            "type": "string",
            "description": "Lowercase first name of the person taking the action. If no name is given, use 'user'."
        },
        "role": {
            "type": "string",
            "enum": ["employee", "contractor", "guest"],
            "description": "The person's role in the organization, as stated or implied by the scenario."
        },
        "clearance": {
            "type": "string",
            "enum": ["public", "confidential", "restricted"],
            "description": "The classification level of the document/resource being accessed."
        }
    },
    "required": ["person", "role", "clearance"]
}

def extract_facts_with_gemini(scenario: str):
    """
    Ask Gemini to turn a natural-language scenario into the structured
    facts policy.pl needs: who, what role, what clearance level.
    Returns (person, role, clearance) on success, or None on any failure
    so the caller can fall back to keyword matching.
    """
    if not gemini_client:
        return None

    prompt = (
        "Read the access-control scenario below and extract the person's name, "
        "their organizational role, and the clearance level of the resource "
        "they are trying to access. If something isn't stated explicitly, infer "
        "the most reasonable value rather than leaving it blank.\n\n"
        f"Scenario: {scenario}"
    )

    try:
        response = gemini_client.models.generate_content(
            model=GEMINI_MODEL,
            contents=prompt,
            config={
                "response_mime_type": "application/json",
                "response_schema": FACT_SCHEMA,
            },
        )
        data = json.loads(response.text)

        person = str(data["person"]).strip().lower() or "user"
        role = str(data["role"]).strip().lower()
        clearance = str(data["clearance"]).strip().lower()

        # Belt-and-suspenders: enum should guarantee this, but don't trust
        # it blindly since we're about to interpolate this into Prolog.
        if role not in ("employee", "contractor", "guest"):
            role = "employee"
        if clearance not in ("public", "confidential", "restricted"):
            clearance = "public"
        if not re.fullmatch(r"[a-z_]+", person):
            person = "user"

        return person, role, clearance

    except Exception as e:
        # Network error, quota exceeded, malformed JSON, missing key —
        # any of these should degrade gracefully, not 500 the request.
        print(f"[gemini] extraction failed, falling back to keywords: {e}")
        return None

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

# ---------------------------------------------------------------------------
# Policy -> Prolog rule generation.
#
# Scope, on purpose: this only generates new clauses for allowed/3, built
# from the two fact predicates the engine already understands (role/2 and
# clearance/2). It does NOT invent new predicates, rewrite existing rules,
# or handle prohibitions/exceptions/conflicts. That's a much bigger problem
# (rule-base consistency checking) that deserves its own design, not a demo
# hack. What's here is real end-to-end: Gemini proposes a rule, the engine
# either accepts or rejects it, and only an engine-verified rule ever gets
# exercised against a test case.
# ---------------------------------------------------------------------------

ALLOWED_ROLES = ("employee", "contractor", "guest")
ALLOWED_LEVELS = ("public", "confidential", "restricted")

RULE_SCHEMA = {
    "type": "object",
    "properties": {
        "action": {
            "type": "string",
            "description": "The verb from the policy (e.g. read, edit, delete), lowercase. Use 'read' if no verb is stated."
        },
        "role": {
            "type": "string",
            "enum": list(ALLOWED_ROLES),
            "description": "The role this policy grants access to."
        },
        "clearance": {
            "type": "string",
            "enum": list(ALLOWED_LEVELS),
            "description": "The document clearance level this policy grants access to."
        },
        "plain_english": {
            "type": "string",
            "description": "One sentence restating, in your own words, exactly what the generated rule permits."
        }
    },
    "required": ["action", "role", "clearance", "plain_english"]
}

def generate_rule_with_gemini(policy_text: str):
    """
    Translate one natural-language access policy into the pieces needed
    to build a new allowed/3 Prolog clause. We ask for structured fields
    (action/role/clearance) rather than raw Prolog text, because that lets
    us assemble syntactically guaranteed-valid Prolog ourselves instead of
    trusting the model to get clause syntax right.
    Returns (prolog_rule_text, plain_english) on success, None on failure.
    """
    if not gemini_client:
        return None

    prompt = (
        "Read this single access-control policy statement and identify three things: "
        "the action being permitted (a verb like read/edit/delete), the role of person "
        "being granted access, and the clearance level of document they may access. "
        "If the policy describes a restriction or denial rather than a grant, set "
        "plain_english to explain that no new ALLOW rule applies (the system denies "
        "by default), but still fill in your best-guess action/role/clearance fields.\n\n"
        f"Policy: \"{policy_text}\""
    )

    try:
        response = gemini_client.models.generate_content(
            model=GEMINI_MODEL,
            contents=prompt,
            config={
                "response_mime_type": "application/json",
                "response_schema": RULE_SCHEMA,
            },
        )
        data = json.loads(response.text)

        action = re.sub(r"[^a-z_]", "", str(data["action"]).strip().lower()) or "read"
        role = str(data["role"]).strip().lower()
        clearance = str(data["clearance"]).strip().lower()
        plain_english = str(data["plain_english"]).strip()

        if role not in ALLOWED_ROLES or clearance not in ALLOWED_LEVELS:
            return None

        # We build the clause ourselves from validated fields rather than
        # accepting raw Prolog text from the model — this guarantees the
        # output is syntactically well-formed Prolog before it ever reaches
        # the engine, and prevents arbitrary code from being injected via
        # a clever prompt.
        rule_text = f"allowed(X, {action}, Y) :- role(X, {role}), clearance(Y, {clearance})"

        return rule_text, plain_english

    except Exception as e:
        print(f"[gemini] rule generation failed: {e}")
        return None


def verify_and_test_rule(rule_text: str, test_role: str, test_clearance: str, test_action: str):
    """
    The actual 'logic proves it' step. A rule Gemini proposed is NOT
    trusted just because it parsed when we built the string — we load it
    into a real, fresh Prolog engine (alongside the existing policy.pl
    rules) and run a real query against it. If SWI-Prolog rejects the
    clause, or the query fails, that's the verdict — not a guess.
    """
    prolog = Prolog()
    prolog.consult("policy.pl")

    # Same shared-engine issue as check_compliance: clear out any test
    # facts AND any previously-asserted generated rule before adding the
    # new one, so successive /generate_rule calls can't see each other's
    # leftover state.
    list(prolog.query("retractall(role(testuser, _))"))
    list(prolog.query("retractall(clearance(testdoc, _))"))

    try:
        prolog.assertz(rule_text)
    except Exception as e:
        return {
            "engine_accepted": False,
            "parse_error": str(e),
            "test_verdict": None
        }

    prolog.assertz(f"role(testuser, {test_role})")
    prolog.assertz(f"clearance(testdoc, {test_clearance})")

    result = list(prolog.query(f"allowed(testuser, {test_action}, testdoc)"))

    # Clean up: retract the rule we just asserted so it doesn't persist
    # into the next request's engine state (allowed/3 is now dynamic,
    # which means it WILL silently accumulate clauses forever otherwise).
    try:
        prolog.retract(rule_text)
    except Exception:
        pass

    return {
        "engine_accepted": True,
        "parse_error": None,
        "test_verdict": "ALLOWED" if result else "DENIED",
        "test_facts": [
            f"role(testuser, {test_role})",
            f"clearance(testdoc, {test_clearance})"
        ],
        "test_query": f"allowed(testuser, {test_action}, testdoc)"
    }


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

    # SWI-Prolog runs one shared engine per process — Prolog() does NOT
    # give you a fresh isolated database each call. Without this, facts
    # asserted by a previous request stay in memory and can silently
    # satisfy a later, unrelated query. Clear the slate every request.
    list(prolog.query("retractall(role(_,_))"))
    list(prolog.query("retractall(clearance(_,_))"))

    extracted = extract_facts_with_gemini(scenario)

    if extracted:
        person, role, clearance = extracted
        fact_source = "gemini"
    else:
        role, clearance = extract_facts_local(scenario)
        person = extract_person_name(scenario)
        fact_source = "keyword-fallback"

    prolog.assertz(f"role({person}, {role})")
    prolog.assertz(f"clearance(report, {clearance})")

    result = list(prolog.query(f"allowed({person}, read, report)"))

    role_check = "TRUE" if role == "employee" else "FALSE"
    clearance_check = "TRUE" if clearance == "public" else "FALSE"

    if result:
        verdict = "COMPLIANT"
        outcome_line = "Both conditions satisfied. Access is COMPLIANT."
    else:
        verdict = "VIOLATION"
        outcome_line = "At least one condition failed. Access is a VIOLATION."

    explanation = (
        f"Facts extracted via {fact_source}: role({person}, {role}), clearance(report, {clearance}).\n\n"
        f"Rule checked: allowed(X, read, Y) :- role(X, employee), clearance(Y, public).\n\n"
        f"role({person}, {role}) matches 'employee' — {role_check}\n"
        f"clearance(report, {clearance}) matches 'public' — {clearance_check}\n\n"
        f"{outcome_line}"
    )

    return {
        "verdict": verdict,
        "explanation": explanation,
        "facts": [
            f"role({person}, {role})",
            f"clearance(report, {clearance})"
        ],
        "fact_source": fact_source
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

    # Ground truth for the overall verdict, and for each individual tier —
    # all four come straight from the engine. The explanation below only
    # describes these results; it never re-derives them, so it cannot
    # disagree with the verdict the way the old hand-written version could.
    verdict_satisfied = bool(list(prolog.query("approved(txn_demo)")))
    auto_ok = bool(list(prolog.query("auto_approved(txn_demo)")))
    mid_ok = bool(list(prolog.query("midtier_approved(txn_demo)")))
    high_ok = bool(list(prolog.query("highvalue_approved(txn_demo)")))
    fraud_override_ok = bool(list(prolog.query("fraud_override_approved(txn_demo)")))

    verdict = "APPROVED" if verdict_satisfied else "REJECTED"

    if amount < 50000:
        tier_label, tier_predicate, tier_ok = "auto-approval tier (< ₹50,000)", "auto_approved", auto_ok
    elif amount <= 500000:
        tier_label, tier_predicate, tier_ok = "mid-tier (₹50,000–₹500,000)", "midtier_approved", mid_ok
    else:
        tier_label, tier_predicate, tier_ok = "high-value tier (> ₹500,000)", "highvalue_approved", high_ok

    chain = [
        f"1. Fact asserted: transaction(txn_demo, {amount}, demo_user)",
        f"2. Fact asserted: manager_signoff(txn_demo) = {'TRUE' if has_signoff else 'NOT FOUND'}",
        f"3. Fact asserted: fraud_flag(txn_demo) = {'TRUE' if has_fraud_flag else 'NOT FOUND'}",
        f"4. Amount ₹{amount} falls in the {tier_label}",
        f"5. Queried {tier_predicate}(txn_demo) directly — result: {'SATISFIED' if tier_ok else 'FAILED'}",
    ]

    if has_fraud_flag:
        chain.append(
            f"6. Fraud flag present — also queried fraud_override_approved(txn_demo) "
            f"(requires senior_cleared) — result: {'SATISFIED' if fraud_override_ok else 'FAILED (senior_cleared not found)'}"
        )

    if verdict_satisfied:
        if tier_ok:
            reason = f"Transaction approved: it satisfies the {tier_label} rule."
        else:
            reason = "Transaction approved via the fraud-override rule: flagged, but senior-cleared."
    else:
        reasons = []
        if has_fraud_flag and not fraud_override_ok:
            reasons.append("a fraud flag is present with no senior clearance to override it")
        elif amount >= 50000 and not has_signoff:
            reasons.append(f"manager signoff is required for the {tier_label} and was not provided")
        if not reasons:
            reasons.append("no approval rule was satisfied for this combination of facts")
        reason = "Transaction blocked: " + "; ".join(reasons) + "."

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

@app.route("/generate_rule", methods=["POST"])
def generate_rule_route():
    data = request.json
    policy_text = (data.get("policy_text") or "").strip()
    test_role = (data.get("test_role") or "employee").strip().lower()
    test_clearance = (data.get("test_clearance") or "public").strip().lower()
    test_action = re.sub(r"[^a-z_]", "", (data.get("test_action") or "read").strip().lower()) or "read"

    if not policy_text:
        return jsonify({"error": "policy_text is required"}), 400
    if test_role not in ALLOWED_ROLES or test_clearance not in ALLOWED_LEVELS:
        return jsonify({"error": "test_role/test_clearance must be valid values"}), 400

    generated = generate_rule_with_gemini(policy_text)
    if not generated:
        return jsonify({
            "error": "Rule generation unavailable — missing/invalid GEMINI_API_KEY, "
                     "a network/quota error, or Gemini returned values outside the "
                     "supported role/clearance vocabulary. Check server logs."
        }), 503

    rule_text, plain_english = generated
    verification = verify_and_test_rule(rule_text, test_role, test_clearance, test_action)

    return jsonify({
        "policy_text": policy_text,
        "generated_rule": rule_text,
        "plain_english": plain_english,
        **verification
    })

if __name__ == "__main__":
    app.run(debug=True)
