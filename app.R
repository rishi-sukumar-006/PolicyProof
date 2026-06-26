library(shiny)
library(httr)
library(jsonlite)
library(shinyjs)
library(shinycssloaders)
 
 
ui <- fluidPage(
  useShinyjs(),
 
  tags$head(
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=IBM+Plex+Mono:wght@400;500&display=swap"),

    tags$style(HTML("
      /* ── Design tokens ────────────────────────────────────── */
      :root {
        --bg-page:       #F4F6F9;
        --bg-card:       #FFFFFF;
        --border:        #E2E6EC;
        --text-primary:  #1F2A3A;
        --text-secondary:#5B6B82;
        --brand-primary: #2C4870;
        --brand-accent:  #3D5AFE;
        --success:       #2F9E44;
        --danger:        #E03131;
        --warning:       #E67E22;
        --neutral-chip-bg:  #EEF1F6;
        --neutral-chip-text:#2C4870;
        --mono-trace:    #8893A6;

        --radius-card:   12px;
        --radius-input:  8px;
        --radius-chip:   8px;
        --shadow-card:   0 1px 3px rgba(15, 23, 42, 0.06);
        --font-ui:       'Inter', -apple-system, 'Segoe UI', Roboto, sans-serif;
        --font-mono:     'IBM Plex Mono', 'JetBrains Mono', monospace;
      }

      /* ── Reset / base ─────────────────────────────────────── */
      body {
        background: var(--bg-page);
        color: var(--text-primary);
        font-family: var(--font-ui);
        font-size: 15px;
        line-height: 1.55;
      }

      .container-fluid {
        max-width: 980px;
        padding: 32px 20px 48px;
      }

      /* ── Header card ──────────────────────────────────────── */
      .topbar {
        background: var(--bg-card);
        border: 1px solid var(--border);
        border-radius: var(--radius-card);
        padding: 24px 28px;
        margin-bottom: 22px;
        box-shadow: var(--shadow-card);
      }

      .brand-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 16px;
      }

      .brand-mark {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 40px;
        height: 40px;
        border-radius: 8px;
        background: var(--brand-primary);
        color: #FFFFFF;
        font-weight: 700;
        font-size: 15px;
        letter-spacing: -0.02em;
        margin-right: 12px;
      }

      .brand-title-wrap {
        display: flex;
        align-items: center;
      }

      .topbar h1 {
        margin: 0;
        color: var(--text-primary);
        font-size: 26px;
        font-weight: 700;
        letter-spacing: -0.02em;
      }

      .topbar p {
        margin: 6px 0 0 52px;
        color: var(--text-secondary);
        font-size: 14px;
        line-height: 1.5;
      }

      .system-status {
        border: 1px solid var(--border);
        background: var(--bg-page);
        color: var(--text-secondary);
        padding: 6px 14px;
        border-radius: 999px;
        font-size: 12px;
        font-weight: 600;
        white-space: nowrap;
        letter-spacing: 0.01em;
      }

      /* ── Tabs — underline style ───────────────────────────── */
      .nav-tabs {
        border-bottom: 2px solid var(--border);
        margin-bottom: 20px;
      }

      .nav-tabs > li > a {
        color: var(--text-secondary);
        background: transparent;
        border: 0;
        border-radius: 0;
        border-bottom: 2px solid transparent;
        font-weight: 600;
        font-size: 14px;
        padding: 10px 16px;
        margin-bottom: -2px;
        transition: color 0.15s ease, border-color 0.15s ease;
      }

      .nav-tabs > li > a:hover {
        color: var(--brand-primary);
        border-color: transparent;
        background: transparent;
      }

      .nav-tabs > li.active > a,
      .nav-tabs > li.active > a:focus,
      .nav-tabs > li.active > a:hover {
        color: var(--brand-primary);
        background: transparent;
        border: 0;
        border-bottom: 2px solid var(--brand-primary);
        border-radius: 0;
      }

      /* ── Cards ─────────────────────────────────────────────── */
      .card {
        background: var(--bg-card);
        border: 1px solid var(--border);
        border-radius: var(--radius-card);
        padding: 24px;
        margin-bottom: 18px;
        box-shadow: var(--shadow-card);
      }

      .card-title {
        margin: 0 0 6px;
        color: var(--text-primary);
        font-size: 17px;
        font-weight: 700;
      }

      .card-subtitle {
        margin: 0 0 18px;
        color: var(--text-secondary);
        font-size: 14px;
        line-height: 1.5;
      }

      /* ── Form controls ─────────────────────────────────────── */
      .form-control,
      textarea,
      input[type='number'],
      input[type='text'] {
        background: var(--bg-card) !important;
        color: var(--text-primary) !important;
        border: 1px solid var(--border) !important;
        border-radius: var(--radius-input) !important;
        box-shadow: none !important;
        font-family: var(--font-ui) !important;
        font-size: 14px !important;
        transition: border-color 0.15s ease, box-shadow 0.15s ease;
      }

      textarea:focus,
      input[type='number']:focus,
      input[type='text']:focus {
        border-color: var(--brand-accent) !important;
        box-shadow: 0 0 0 3px rgba(61, 90, 254, 0.15) !important;
        outline: none;
      }

      textarea::placeholder {
        color: var(--text-secondary) !important;
      }

      .control-label {
        color: var(--text-primary);
        font-weight: 600;
        font-size: 13px;
      }

      .checkbox label {
        color: var(--text-secondary);
        font-weight: 500;
        font-size: 14px;
      }

      select {
        background: var(--bg-card) !important;
        color: var(--text-primary) !important;
        border: 1px solid var(--border) !important;
        border-radius: var(--radius-input) !important;
        font-family: var(--font-ui) !important;
        font-size: 14px !important;
      }

      /* ── Buttons ───────────────────────────────────────────── */
      .btn {
        border-radius: var(--radius-input);
        font-weight: 600;
        font-size: 14px;
        padding: 9px 18px;
        border: 0;
        transition: background-color 0.15s ease, transform 0s, box-shadow 0s;
      }

      .btn:hover {
        transform: none;
      }

      /* Primary CTA — solid accent, no gradient */
      .btn-primary {
        background: var(--brand-accent) !important;
        color: #FFFFFF !important;
        box-shadow: none;
      }

      .btn-primary:hover,
      .btn-primary:focus {
        background: var(--brand-primary) !important;
        color: #FFFFFF !important;
      }

      .btn-success,
      .btn-warning {
        background: var(--brand-accent) !important;
        color: #FFFFFF !important;
        box-shadow: none;
      }

      .btn-success:hover,
      .btn-warning:hover {
        background: var(--brand-primary) !important;
        color: #FFFFFF !important;
      }

      /* Example / secondary chips */
      .btn-secondary,
      .chip-btn {
        background: var(--neutral-chip-bg) !important;
        color: var(--neutral-chip-text) !important;
        border: none !important;
        box-shadow: none;
        margin: 0 8px 8px 0;
        border-radius: var(--radius-chip) !important;
        font-weight: 600;
        font-size: 13px;
        padding: 7px 14px;
        transition: background-color 0.15s ease;
      }

      .btn-secondary:hover,
      .chip-btn:hover {
        background: #DCE1EA !important;
        color: var(--brand-primary) !important;
      }

      /* legacy .example-btn kept for compatibility */
      .example-btn {
        background: var(--neutral-chip-bg) !important;
        color: var(--neutral-chip-text) !important;
        border: none !important;
        box-shadow: none;
        margin: 0 8px 8px 0;
        border-radius: var(--radius-chip) !important;
        font-weight: 600;
        font-size: 13px;
        padding: 7px 14px;
        transition: background-color 0.15s ease;
      }

      .example-btn:hover {
        background: #DCE1EA !important;
        color: var(--brand-primary) !important;
      }

      .button-row {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 8px;
        margin-top: 12px;
      }

      /* ── Verdict card ──────────────────────────────────────── */
      .verdict-card {
        background: var(--bg-card);
        border: 1px solid var(--border);
        border-radius: var(--radius-card);
        padding: 22px;
        box-shadow: var(--shadow-card);
        animation: slideFade 0.32s ease both;
      }

      .verdict-label {
        color: var(--text-secondary);
        font-size: 11px;
        font-weight: 700;
        letter-spacing: 0.08em;
        text-transform: uppercase;
        margin-bottom: 10px;
      }

      .verdict-heading {
        margin: 0 0 10px;
        font-size: 24px;
        font-weight: 700;
        letter-spacing: -0.02em;
      }

      .verdict-reason {
        color: var(--text-secondary);
        font-size: 14px;
        line-height: 1.6;
        margin-bottom: 16px;
        white-space: pre-wrap;
      }

      /* ── Verdict result box — dynamic states ─────────────── */
      .verdict-box {
        border-radius: var(--radius-card);
        padding: 18px 20px;
        transition: background 0.2s ease, border-color 0.2s ease;
      }

      /* empty / placeholder state */
      .verdict-box.empty-state {
        border: 1px dashed var(--border);
        border-left: none;
        background: transparent;
        border-radius: var(--radius-card);
        padding: 18px;
        color: var(--text-secondary);
        line-height: 1.55;
        font-size: 14px;
      }

      /* COMPLIANT */
      .verdict-box.compliant {
        background: rgba(47, 158, 68, 0.08);
        border-left: 4px solid var(--success);
        border-radius: var(--radius-card);
      }

      .verdict-box.compliant .verdict-heading {
        color: var(--success);
      }

      /* VIOLATION */
      .verdict-box.violation {
        background: rgba(224, 49, 49, 0.08);
        border-left: 4px solid var(--danger);
        border-radius: var(--radius-card);
      }

      .verdict-box.violation .verdict-heading {
        color: var(--danger);
      }

      /* WARNING — kept for edge cases */
      .verdict-box.warning {
        background: rgba(230, 126, 34, 0.08);
        border-left: 4px solid var(--warning);
        border-radius: var(--radius-card);
      }

      .verdict-box.warning .verdict-heading {
        color: var(--warning);
      }

      /* legacy class compatibility */
      .status-success {
        background: rgba(47, 158, 68, 0.08) !important;
        border-left: 4px solid var(--success) !important;
      }

      .status-success .verdict-heading {
        color: var(--success) !important;
      }

      .status-danger {
        background: rgba(224, 49, 49, 0.08) !important;
        border-left: 4px solid var(--danger) !important;
      }

      .status-danger .verdict-heading {
        color: var(--danger) !important;
      }

      .status-warning {
        background: rgba(230, 126, 34, 0.08) !important;
        border-left: 4px solid var(--warning) !important;
      }

      .status-warning .verdict-heading {
        color: var(--warning) !important;
      }

      /* ── Proof trace — signature element ────────────────── */
      .proof-trace {
        font-family: var(--font-mono);
        font-size: 13px;
        font-weight: 400;
        color: var(--mono-trace);
        background: var(--bg-page);
        padding: 2px 6px;
        border-radius: 4px;
        display: inline;
        white-space: pre-wrap;
        word-break: break-word;
      }

      .proof-trace-block {
        margin-top: 10px;
        margin-bottom: 16px;
        padding: 10px 14px;
        background: var(--bg-page);
        border-radius: var(--radius-input);
        border: 1px solid var(--border);
        font-family: var(--font-mono);
        font-size: 13px;
        color: var(--mono-trace);
        line-height: 1.7;
        white-space: pre-wrap;
        word-break: break-word;
      }

      .proof-trace-label {
        font-family: var(--font-ui);
        font-size: 11px;
        font-weight: 700;
        letter-spacing: 0.06em;
        text-transform: uppercase;
        color: var(--text-secondary);
        margin-bottom: 6px;
        display: block;
      }

      /* ── Risk pill ────────────────────────────────────────── */
      .risk-pill {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        border-radius: 999px;
        padding: 5px 12px;
        font-size: 12px;
        font-weight: 600;
        background: var(--neutral-chip-bg);
        border: 1px solid var(--border);
        color: var(--text-secondary);
      }

      /* ── Grid / mini-panels ────────────────────────────────── */
      .section-grid {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 14px;
        margin-top: 16px;
      }

      @media (max-width: 760px) {
        .section-grid {
          grid-template-columns: 1fr;
        }

        .brand-row {
          align-items: flex-start;
          flex-direction: column;
        }

        .topbar p {
          margin-left: 0;
        }
      }

      .mini-panel {
        background: var(--bg-card);
        border: 1px solid var(--border);
        border-radius: var(--radius-card);
        padding: 16px;
      }

      .mini-panel h4 {
        margin: 0 0 10px;
        color: var(--text-primary);
        font-size: 14px;
        font-weight: 700;
      }

      .policy-list {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
      }

      .policy-chip {
        border: 1px solid var(--border);
        background: var(--neutral-chip-bg);
        color: var(--neutral-chip-text);
        border-radius: var(--radius-chip);
        padding: 6px 12px;
        font-size: 12px;
        font-weight: 600;
      }

      .steps-list,
      .audit-list {
        margin: 0;
        padding: 0;
        list-style: none;
      }

      .steps-list li,
      .audit-list li {
        display: flex;
        align-items: flex-start;
        gap: 8px;
        color: var(--text-secondary);
        font-size: 13px;
        padding: 5px 0;
      }

      .check-icon {
        color: var(--success);
        font-weight: 700;
        font-size: 13px;
      }

      .audit-time {
        color: var(--mono-trace);
        font-family: var(--font-mono);
        font-size: 12px;
        min-width: 42px;
      }

      /* ── Empty state ───────────────────────────────────────── */
      .empty-state {
        color: var(--text-secondary);
        border: 1px dashed var(--border);
        border-radius: var(--radius-card);
        padding: 18px;
        background: transparent;
        line-height: 1.55;
        font-size: 14px;
      }

      /* ── Export / footer row ───────────────────────────────── */
      .export-row {
        border-top: 1px solid var(--border);
        margin-top: 16px;
        padding-top: 14px;
        display: flex;
        justify-content: flex-end;
      }

      /* ── Generated rule code block ─────────────────────────── */
      .rule-code {
        background: var(--bg-page);
        border: 1px solid var(--border);
        border-radius: var(--radius-input);
        padding: 14px;
        font-family: var(--font-mono);
        font-size: 13px;
        color: var(--text-primary);
        white-space: pre-wrap;
        line-height: 1.6;
      }

      /* ── Spinner colour ────────────────────────────────────── */
      .shiny-spinner-output { color: var(--brand-primary); }

      /* ── Animation ─────────────────────────────────────────── */
      @keyframes slideFade {
        from {
          opacity: 0;
          transform: translateY(6px);
        }
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }
    "))
  ),
 
  div(
    class = "topbar",
    div(
      class = "brand-row",
      div(
        div(
          class = "brand-title-wrap",
          span(class = "brand-mark", "PP"),
          h1("PolicyProof")
        ),
        p("Compliance Reasoning Engine for access, approvals, and audit-ready policy decisions.")
      ),
      div(class = "system-status", "Deterministic Policy Engine")
    )
  ),
 
  tabsetPanel(
    tabPanel(
      "Document Access",
 
      div(
        class = "card",
        h2(class = "card-title", "Scenario"),
        p(class = "card-subtitle", "Describe the access request in plain language. PolicyProof evaluates the scenario against deterministic compliance rules."),
        textAreaInput(
          "scenario",
          NULL,
          placeholder = "e.g. Alice is an employee and wants to read the public report",
          rows = 6,
          width = "100%"
        ),
        div(
          class = "button-row",
          actionButton("example_employee", "Employee Access", class = "example-btn"),
          actionButton("example_guest", "Guest Download", class = "example-btn"),
          actionButton("example_admin", "Admin Update", class = "example-btn"),
          actionButton("check", "Check Compliance", class = "btn-primary")
        )
      ),
 
      div(
        class = "card",
        h2(class = "card-title", "Verdict"),
        div(id = "verdict_box", withSpinner(uiOutput("verdict_ui"), type = 6, color = "#2C4870"))
      )
    ),
 
    tabPanel(
      "Financial Transaction Approval",
 
      div(
        class = "card",
        h2(class = "card-title", "Transaction"),
        p(class = "card-subtitle", "Evaluate payment approval requirements using amount thresholds, manager signoff, and fraud flags."),
        numericInput("amount", "Transaction Amount (\u20b9):", value = 30000, min = 0, width = "100%"),
        checkboxInput("signoff", "Manager Signoff Given", value = FALSE),
        checkboxInput("fraud", "Fraud Flag Present", value = FALSE),
        div(
          class = "button-row",
          actionButton("example_low_txn", "Low-Risk Payment", class = "example-btn"),
          actionButton("example_high_txn", "High-Value Payment", class = "example-btn"),
          actionButton("example_fraud_txn", "Fraud Review", class = "example-btn"),
          actionButton("check_txn", "Check Transaction", class = "btn-primary")
        )
      ),
 
      div(
        class = "card",
        h2(class = "card-title", "Transaction Verdict"),
        div(id = "txn_verdict_box", withSpinner(uiOutput("txn_verdict_ui"), type = 6, color = "#2C4870"))
      )
    ),

    tabPanel(
      "Policy \u2192 Rule Generator",

      div(
        class = "card",
        h2(class = "card-title", "Natural-Language Policy"),
        p(class = "card-subtitle", "Describe a single access policy in plain English. Gemini proposes a Prolog rule for it, and the rule is only accepted if SWI-Prolog can actually parse and run it \u2014 nothing here is taken on faith."),
        textAreaInput(
          "policy_text",
          NULL,
          placeholder = "e.g. Contractors are allowed to read public documents",
          rows = 4,
          width = "100%"
        ),
        div(
          class = "button-row",
          actionButton("example_policy_contractor", "Contractor Grant", class = "example-btn"),
          actionButton("example_policy_guest", "Guest Restriction", class = "example-btn")
        ),
        div(
          class = "section-grid",
          div(
            selectInput("test_role", "Test as role:", choices = c("employee", "contractor", "guest"), selected = "contractor")
          ),
          div(
            selectInput("test_clearance", "Test against clearance:", choices = c("public", "confidential", "restricted"), selected = "public")
          )
        ),
        textInput("test_action", "Test action:", value = "read", width = "100%"),
        div(
          class = "button-row",
          actionButton("generate_rule", "Generate & Verify Rule", class = "btn-primary")
        )
      ),

      div(
        class = "card",
        h2(class = "card-title", "Generated Rule"),
        div(id = "rule_box", withSpinner(uiOutput("rule_ui"), type = 6, color = "#2C4870"))
      )
    )
  )
)
 
classify_result <- function(verdict) {
  verdict_clean <- ifelse(is.null(verdict) || is.na(verdict), "UNKNOWN", as.character(verdict))
  verdict_upper <- toupper(verdict_clean)
 
  is_success <- grepl("COMPLIANT|APPROVED|ALLOW|ALLOWED|PASS|PERMITTED", verdict_upper)
  is_danger <- grepl("NON|DENIED|DENY|REJECT|BLOCK|FAILED|VIOLATION|FRAUD|ERROR", verdict_upper)
 
  if (is_success) {
    list(card_class = "status-success", risk = "Low", policies = c("Employee Access Policy", "Resource Classification Rule"))
  } else if (is_danger) {
    list(card_class = "status-danger", risk = "High", policies = c("Confidentiality Rule", "Access Restriction Policy"))
  } else {
    list(card_class = "status-warning", risk = "Medium", policies = c("Manual Review Policy", "Exception Handling Rule"))
  }
}

make_audit_rows <- function() {
  now <- format(Sys.time(), "%H:%M")
  tags$ul(
    class = "audit-list",
    tags$li(span(class = "audit-time", now), span("Request received")),
    tags$li(span(class = "audit-time", now), span("Policy facts loaded")),
    tags$li(span(class = "audit-time", now), span("Rule match evaluated")),
    tags$li(span(class = "audit-time", now), span("Verdict generated"))
  )
}

make_verdict_card <- function(verdict, explanation, mode = "document", prolog_trace = NULL) {
  verdict_clean <- ifelse(is.null(verdict) || is.na(verdict), "UNKNOWN", as.character(verdict))
  explanation_clean <- ifelse(is.null(explanation) || is.na(explanation), "No explanation returned by the API.", as.character(explanation))
  result_meta <- classify_result(verdict_clean)
 
  steps <- if (mode == "transaction") {
    c("Amount threshold checked", "Manager signoff verified", "Fraud flag evaluated", "Approval policy applied")
  } else {
    c("User identified", "Resource identified", "Permission checked", "Policy evaluated")
  }

  trace_content <- if (!is.null(prolog_trace) && nchar(prolog_trace) > 0) {
    prolog_trace
  } else {
    gsub("^Reason:\\s*", "", explanation_clean)
  }

  verdict_icon <- if (result_meta$card_class == "status-success") "\u2713 " else if (result_meta$card_class == "status-danger") "\u2717 " else ""

  risk_color <- if (result_meta$card_class == "status-success") "var(--success)" else if (result_meta$card_class == "status-danger") "var(--danger)" else "var(--warning)"

  div(
    class = paste("verdict-card", result_meta$card_class),
    div(class = "verdict-label", "Verdict"),
    h2(class = "verdict-heading", paste0(verdict_icon, verdict_clean)),
    div(class = "verdict-reason", strong("Reason: "), explanation_clean),

    span(class = "proof-trace-label", "Proof Trace"),
    div(class = "proof-trace-block", trace_content),

    div(class = "risk-pill", span("Risk Level:"), span(style = paste0("color:", risk_color, ";font-weight:700;"), result_meta$risk)),
 
    div(
      class = "section-grid",
      div(
        class = "mini-panel",
        h4("Applicable Policies"),
        div(
          class = "policy-list",
          lapply(result_meta$policies, function(policy) div(class = "policy-chip", policy))
        )
      ),
      div(
        class = "mini-panel",
        h4("Analysis"),
        tags$ul(
          class = "steps-list",
          lapply(steps, function(step) tags$li(span(class = "check-icon", "\u2713"), span(step)))
        )
      ),
      div(
        class = "mini-panel",
        h4("Audit Log"),
        make_audit_rows()
      ),
      div(
        class = "mini-panel",
        h4("Report"),
        p(class = "card-subtitle", "Generate an audit-ready compliance summary for this decision."),
        actionButton("download_report_placeholder", "Download Compliance Report", class = "btn-secondary")
      )
    )
  )
}
 
make_rule_card <- function(result) {
  if (!is.null(result$error)) {
    return(div(
      class = "verdict-card status-warning",
      div(class = "verdict-label", "Could Not Generate Rule"),
      div(class = "verdict-reason", result$error)
    ))
  }

  accepted <- isTRUE(result$engine_accepted)
  card_class <- if (accepted) "status-success" else "status-danger"
  heading <- if (accepted) paste("ENGINE VERDICT:", result$test_verdict) else "ENGINE REJECTED RULE"

  test_trace <- if (accepted) {
    paste0(
      "assert(", paste(unlist(result$test_facts), collapse = ", "), ").\n",
      "query(", result$test_query, ") \u2192 ", result$test_verdict, "."
    )
  } else {
    result$parse_error
  }

  div(
    class = paste("verdict-card", card_class),
    div(class = "verdict-label", "Policy \u2192 Rule"),
    h2(class = "verdict-heading", heading),
    div(class = "verdict-reason", strong("Policy: "), result$policy_text),
    div(class = "verdict-reason", strong("Gemini's interpretation: "), result$plain_english),

    span(class = "proof-trace-label", "Generated Rule"),
    tags$pre(class = "rule-code", result$generated_rule),

    if (accepted) {
      tagList(
        span(class = "proof-trace-label", "Test Trace"),
        div(class = "proof-trace-block", test_trace)
      )
    } else {
      tagList(
        span(class = "proof-trace-label", "Parse Error"),
        div(class = "proof-trace-block", test_trace)
      )
    }
  )
}

server <- function(input, output, session) {
  verdict_state <- reactiveVal(NULL)
  txn_state <- reactiveVal(NULL)
 
  observeEvent(input$example_employee, {
    updateTextAreaInput(session, "scenario", value = "Alice is an employee and wants to read the public report.")
  })
 
  observeEvent(input$example_guest, {
    updateTextAreaInput(session, "scenario", value = "Kumar is a guest user and wants to download the confidential financial report.")
  })
 
  observeEvent(input$example_admin, {
    updateTextAreaInput(session, "scenario", value = "Priya is an admin and wants to update the internal access policy document.")
  })
 
  observeEvent(input$example_low_txn, {
    updateNumericInput(session, "amount", value = 12000)
    updateCheckboxInput(session, "signoff", value = FALSE)
    updateCheckboxInput(session, "fraud", value = FALSE)
  })
 
  observeEvent(input$example_high_txn, {
    updateNumericInput(session, "amount", value = 95000)
    updateCheckboxInput(session, "signoff", value = TRUE)
    updateCheckboxInput(session, "fraud", value = FALSE)
  })
 
  observeEvent(input$example_fraud_txn, {
    updateNumericInput(session, "amount", value = 45000)
    updateCheckboxInput(session, "signoff", value = TRUE)
    updateCheckboxInput(session, "fraud", value = TRUE)
  })
 
  output$verdict_ui <- renderUI({
    result <- verdict_state()
 
    if (is.null(result)) {
      return(div(
        class = "empty-state",
        "No decision generated yet. Select an example or enter a scenario, then click Check Compliance."
      ))
    }
 
    make_verdict_card(result$verdict, result$explanation, mode = "document")
  })
 
  output$txn_verdict_ui <- renderUI({
    result <- txn_state()
 
    if (is.null(result)) {
      return(div(
        class = "empty-state",
        "No transaction decision generated yet. Enter transaction details, then click Check Transaction."
      ))
    }
 
    make_verdict_card(result$verdict, result$explanation, mode = "transaction")
  })
 
  observeEvent(input$check, {
    hide("verdict_box")
 
    result <- tryCatch({
      response <- POST(
        "http://localhost:5000/check",
        body = list(scenario = input$scenario),
        encode = "json"
      )
 
      if (http_error(response)) {
        stop(paste("API returned HTTP", status_code(response)))
      }
 
      content(response, "parsed")
    }, error = function(e) {
      list(
        verdict = "ERROR",
        explanation = paste("Could not reach or parse the compliance API:", e$message)
      )
    })
 
    verdict_state(result)
    delay(120, show("verdict_box", anim = TRUE, animType = "fade"))
  })
 
  observeEvent(input$check_txn, {
    hide("txn_verdict_box")
 
    result <- tryCatch({
      response <- POST(
        "http://localhost:5000/check_transaction",
        body = list(
          amount = input$amount,
          signoff = input$signoff,
          fraud = input$fraud
        ),
        encode = "json"
      )
 
      if (http_error(response)) {
        stop(paste("API returned HTTP", status_code(response)))
      }
 
      content(response, "parsed")
    }, error = function(e) {
      list(
        verdict = "ERROR",
        explanation = paste("Could not reach or parse the transaction API:", e$message)
      )
    })
 
    txn_state(result)
    delay(120, show("txn_verdict_box", anim = TRUE, animType = "fade"))
  })

  observeEvent(input$example_policy_contractor, {
    updateTextAreaInput(session, "policy_text", value = "Contractors are allowed to read public documents.")
    updateSelectInput(session, "test_role", selected = "contractor")
    updateSelectInput(session, "test_clearance", selected = "public")
    updateTextInput(session, "test_action", value = "read")
  })

  observeEvent(input$example_policy_guest, {
    updateTextAreaInput(session, "policy_text", value = "Guests are allowed to read public documents only.")
    updateSelectInput(session, "test_role", selected = "guest")
    updateSelectInput(session, "test_clearance", selected = "confidential")
    updateTextInput(session, "test_action", value = "read")
  })

  rule_state <- reactiveVal(NULL)

  output$rule_ui <- renderUI({
    result <- rule_state()

    if (is.null(result)) {
      return(div(
        class = "empty-state",
        "No rule generated yet. Describe a policy, then click Generate & Verify Rule."
      ))
    }

    make_rule_card(result)
  })

  observeEvent(input$generate_rule, {
    hide("rule_box")

    result <- tryCatch({
      response <- POST(
        "http://localhost:5000/generate_rule",
        body = list(
          policy_text = input$policy_text,
          test_role = input$test_role,
          test_clearance = input$test_clearance,
          test_action = input$test_action
        ),
        encode = "json"
      )

      parsed <- content(response, "parsed")

      if (http_error(response)) {
        list(error = if (!is.null(parsed$error)) parsed$error else paste("API returned HTTP", status_code(response)))
      } else {
        parsed
      }
    }, error = function(e) {
      list(error = paste("Could not reach the rule-generation API:", e$message))
    })

    rule_state(result)
    delay(120, show("rule_box", anim = TRUE, animType = "fade"))
  })
}

shinyApp(ui = ui, server = server)
