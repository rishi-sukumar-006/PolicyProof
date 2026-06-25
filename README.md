# PolicyProof — Compliance Reasoning Engine

**A compliance verification system that proves answers instead of guessing them.**

Built for **Stack Unknown — The Obscure Tech Hackathon** (DCS + GDG on Campus, SASTRA Deemed University)

---

## The Problem

Every AI compliance tool today works the same way: feed an LLM a policy and a scenario, and it generates an answer. The answer sounds confident. It is also a guess — there is no formal proof behind it, no way to verify the reasoning, and no guarantee the same input produces the same output twice.

PolicyProof takes the opposite approach.

## The Idea

Instead of asking an LLM "is this compliant?", PolicyProof converts the question into formal logic and lets a **symbolic reasoning engine** — not a language model — decide the answer. Gemini only extracts facts from natural language. The actual decision comes from logical inference over declared rules, which means every verdict comes with a **traceable, mechanical explanation** of exactly which facts and rules produced it.

This is the difference between an AI that summarizes regulations and an AI that proves whether you violated one.

## Why This Stack Is Obscure

| Layer | Technology | Why It's Strange |
|---|---|---|
| Frontend | **R Shiny** | R is a statistics and data visualization language. Nobody builds production web UIs in it. We did. |
| Backend Logic | **SWI-Prolog** | A logic programming language from 1972, designed for expert systems. It has no business running inside a 2026 web app — except that compliance rules are literally `IF condition THEN allowed`, which is exactly what Prolog was built for. |
| Database | **Google Sheets** | Live policy rules live inside a spreadsheet with a toolbar, not a SQL table. |
| Glue Layer | **Flask + pyswip** | Bridges Python, Prolog, and the outside world. |
| NLP Layer | **Gemini API** | Extracts structured facts from natural language scenarios. |

Every layer of this stack is mismatched to its "normal" use case on purpose. The judge's reaction we're aiming for: *"Wait... you used Prolog as a reasoning engine, and R as a web frontend?"*

Exactly.

## System Architecture

```
User describes a scenario in plain English
              ↓
   R Shiny (frontend, port 3838)
              ↓  HTTP POST
   Flask backend (port 5000)
              ↓
   Gemini API extracts structured facts
   (e.g. role(alice, employee), clearance(report, public))
              ↓
   Google Sheets — live policy rules pulled in real time
              ↓
   SWI-Prolog — formal logical inference
   allowed(X, read, Y) :- role(X, employee), clearance(Y, public).
              ↓
   Verdict + Explanation returned to R Shiny
   "COMPLIANT — because role(alice, employee) and
    clearance(report, public) satisfy the policy rule."
```

Nothing in this pipeline is a black box. Every verdict can be traced back to the exact facts and the exact rule that produced it.

## What Makes the Demo Interesting

Open the Google Sheet in one window and PolicyProof in another. Change a single cell — say, reclassify a document from `public` to `confidential` — and the next query against that document flips from COMPLIANT to VIOLATION instantly. The "database" is a spreadsheet with a toolbar, and the judge watches it drive a live logical proof.

## Tech Stack

- **SWI-Prolog** — symbolic reasoning engine
- **R + Shiny** — frontend web framework
- **Flask (Python)** — backend API and integration layer
- **pyswip** — Python-Prolog bridge
- **Google Sheets API** — live policy database
- **Gemini API** — natural language fact extraction
- **gspread / google-auth** — Sheets authentication

## Running It Locally

**Terminal 1 — Backend:**
```bash
pip install -r requirements.txt --break-system-packages
python3 app.py
```

**Terminal 2 — Frontend:**
```bash
R -e "shiny::runApp('app.R', port=3838, host='0.0.0.0')"
```

Visit `http://localhost:3838`

You'll also need:
- SWI-Prolog installed (`sudo apt install swi-prolog`)
- A Google Cloud service account with Sheets API access, saved as `credentials.json` in the project root
- A Gemini API key (free tier) for the final fact-extraction step

## Team

**Rishi Sukumar, Joe Kelvin, Kelvin Samuel, Mohamed Asil**

Built for Stack Unknown 2026.

