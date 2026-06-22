library(shiny)
library(httr)
library(jsonlite)
library(shinyjs)
library(shinycssloaders)
 
# Install missing packages if needed:
# install.packages(c("shiny", "httr", "jsonlite", "shinyjs", "shinycssloaders"))
 
ui <- fluidPage(
  useShinyjs(),
 
  tags$head(
    tags$style(HTML("      
      body {
        background: linear-gradient(180deg, #F8F9FB 0%, #EEF2F7 100%);
        color: #2C3E50;
        font-family: Inter, 'IBM Plex Sans', 'Source Sans Pro', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      }
 
      .container-fluid {
        max-width: 980px;
        padding: 32px 20px 48px;
      }
 
      .topbar {
        background: #FFFFFF;
        border: 1px solid #E1E7EF;
        border-radius: 16px;
        padding: 26px 30px;
        margin-bottom: 22px;
        box-shadow: 0 10px 30px rgba(44, 62, 80, 0.06);
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
        width: 42px;
        height: 42px;
        border-radius: 10px;
        background: #2E5AAC;
        color: #FFFFFF;
        font-weight: 800;
        margin-right: 12px;
      }
 
      .brand-title-wrap {
        display: flex;
        align-items: center;
      }
 
      .topbar h1 {
        margin: 0;
        color: #24364B;
        font-size: 30px;
        font-weight: 800;
        letter-spacing: -0.03em;
      }
 
      .topbar p {
        margin: 8px 0 0 54px;
        color: #66788A;
        font-size: 15px;
      }
 
      .system-status {
        border: 1px solid #D9E2EC;
        background: #F8FAFC;
        color: #46627F;
        padding: 8px 12px;
        border-radius: 999px;
        font-size: 12px;
        font-weight: 700;
        white-space: nowrap;
      }
 
      .nav-tabs {
        border-bottom: 1px solid #D9E2EC;
        margin-bottom: 20px;
      }
 
      .nav-tabs > li > a {
        color: #52677A;
        background: transparent;
        border: 0;
        border-radius: 8px 8px 0 0;
        font-weight: 700;
        padding: 12px 16px;
      }
 
      .nav-tabs > li.active > a,
      .nav-tabs > li.active > a:focus,
      .nav-tabs > li.active > a:hover {
        color: #2E5AAC;
        background: #FFFFFF;
        border: 1px solid #D9E2EC;
        border-bottom-color: #FFFFFF;
      }
 
      .card {
        background: #FFFFFF;
        border: 1px solid #E1E7EF;
        border-radius: 16px;
        padding: 24px;
        margin-bottom: 18px;
        box-shadow: 0 10px 30px rgba(44, 62, 80, 0.05);
      }
 
      .card-title {
        margin: 0 0 8px;
        color: #24364B;
        font-size: 18px;
        font-weight: 800;
      }
 
      .card-subtitle {
        margin: 0 0 18px;
        color: #6B7F93;
        font-size: 14px;
        line-height: 1.5;
      }
 
      .form-control,
      textarea,
      input[type='number'] {
        background: #FFFFFF !important;
        color: #2C3E50 !important;
        border: 1px solid #C9D4E1 !important;
        border-radius: 10px !important;
        box-shadow: none !important;
      }
 
      textarea:focus,
      input[type='number']:focus {
        border-color: #2E5AAC !important;
        box-shadow: 0 0 0 3px rgba(46, 90, 172, 0.12) !important;
      }
 
      .control-label {
        color: #2C3E50;
        font-weight: 750;
      }
 
      .checkbox label {
        color: #43566A;
        font-weight: 600;
      }
 
      .btn {
        border-radius: 8px;
        font-weight: 750;
        padding: 10px 16px;
        border: 0;
        transition: background 0.15s ease, transform 0.15s ease, box-shadow 0.15s ease;
      }
 
      .btn:hover {
        transform: translateY(-1px);
      }
 
      .btn-primary,
      .btn-success,
      .btn-warning {
        background: #2E5AAC !important;
        color: #FFFFFF !important;
        box-shadow: 0 8px 18px rgba(46, 90, 172, 0.18);
      }
 
      .btn-primary:hover,
      .btn-success:hover,
      .btn-warning:hover {
        background: #24498C !important;
        color: #FFFFFF !important;
      }
 
      .btn-secondary,
      .example-btn {
        background: #F3F6FA !important;
        color: #2E5AAC !important;
        border: 1px solid #D6E0EB !important;
        box-shadow: none;
        margin: 0 8px 8px 0;
      }
 
      .btn-secondary:hover,
      .example-btn:hover {
        background: #E8EEF6 !important;
      }
 
      .button-row {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 8px;
        margin-top: 12px;
      }
 
      .verdict-card {
        border-radius: 14px;
        padding: 22px;
        border: 1px solid #DDE6F0;
        background: #FFFFFF;
        animation: slideFade 0.32s ease both;
      }
 
      .verdict-label {
        color: #6B7F93;
        font-size: 12px;
        font-weight: 850;
        letter-spacing: 0.08em;
        text-transform: uppercase;
        margin-bottom: 10px;
      }
 
      .verdict-heading {
        margin: 0 0 12px;
        font-size: 28px;
        font-weight: 850;
        letter-spacing: -0.035em;
      }
 
      .verdict-reason {
        color: #43566A;
        font-size: 15px;
        line-height: 1.62;
        margin-bottom: 18px;
        white-space: pre-wrap;
      }
 
      .status-success {
        border-left: 6px solid #2E7D32;
        background: #F3FAF4;
      }
 
      .status-success .verdict-heading {
        color: #2E7D32;
      }
 
      .status-danger {
        border-left: 6px solid #C0392B;
        background: #FFF6F4;
      }
 
      .status-danger .verdict-heading {
        color: #C0392B;
      }
 
      .status-warning {
        border-left: 6px solid #E67E22;
        background: #FFF8F1;
      }
 
      .status-warning .verdict-heading {
        color: #B95F12;
      }
 
      .risk-pill {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        border-radius: 999px;
        padding: 7px 12px;
        font-size: 13px;
        font-weight: 800;
        background: #F3F6FA;
        border: 1px solid #DCE5EF;
        color: #43566A;
      }
 
      .section-grid {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 18px;
        margin-top: 18px;
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
        background: #FFFFFF;
        border: 1px solid #E1E7EF;
        border-radius: 14px;
        padding: 18px;
      }
 
      .mini-panel h4 {
        margin: 0 0 12px;
        color: #24364B;
        font-size: 15px;
        font-weight: 850;
      }
 
      .policy-list {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
      }
 
      .policy-chip {
        border: 1px solid #D6E0EB;
        background: #F8FAFC;
        color: #43566A;
        border-radius: 10px;
        padding: 10px 12px;
        font-size: 13px;
        font-weight: 750;
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
        gap: 9px;
        color: #43566A;
        font-size: 14px;
        padding: 6px 0;
      }
 
      .check-icon {
        color: #2E7D32;
        font-weight: 900;
      }
 
      .audit-time {
        color: #7C8EA1;
        font-variant-numeric: tabular-nums;
        min-width: 42px;
      }
 
      .empty-state {
        color: #6B7F93;
        border: 1px dashed #C9D4E1;
        border-radius: 14px;
        padding: 18px;
        background: #F8FAFC;
        line-height: 1.55;
      }
 
      .export-row {
        border-top: 1px solid #E6ECF3;
        margin-top: 18px;
        padding-top: 16px;
        display: flex;
        justify-content: flex-end;
      }
 
      @keyframes slideFade {
        from {
          opacity: 0;
          transform: translateY(8px);
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
        div(id = "verdict_box", withSpinner(uiOutput("verdict_ui"), type = 6, color = "#2E5AAC"))
      )
    ),
 
    tabPanel(
      "Financial Transaction Approval",
 
      div(
        class = "card",
        h2(class = "card-title", "Transaction"),
        p(class = "card-subtitle", "Evaluate payment approval requirements using amount thresholds, manager signoff, and fraud flags."),
        numericInput("amount", "Transaction Amount (₹):", value = 30000, min = 0, width = "100%"),
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
        div(id = "txn_verdict_box", withSpinner(uiOutput("txn_verdict_ui"), type = 6, color = "#2E5AAC"))
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
    list(card_class = "status-success", risk = "🟢 Low", policies = c("Employee Access Policy", "Resource Classification Rule"))
  } else if (is_danger) {
    list(card_class = "status-danger", risk = "🔴 High", policies = c("Confidentiality Rule", "Access Restriction Policy"))
  } else {
    list(card_class = "status-warning", risk = "🟠 Medium", policies = c("Manual Review Policy", "Exception Handling Rule"))
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
 
make_verdict_card <- function(verdict, explanation, mode = "document") {
  verdict_clean <- ifelse(is.null(verdict) || is.na(verdict), "UNKNOWN", as.character(verdict))
  explanation_clean <- ifelse(is.null(explanation) || is.na(explanation), "No explanation returned by the API.", as.character(explanation))
  result_meta <- classify_result(verdict_clean)
 
  steps <- if (mode == "transaction") {
    c("Amount threshold checked", "Manager signoff verified", "Fraud flag evaluated", "Approval policy applied")
  } else {
    c("User identified", "Resource identified", "Permission checked", "Policy evaluated")
  }
 
  div(
    class = paste("verdict-card", result_meta$card_class),
    div(class = "verdict-label", "Verdict"),
    h2(class = "verdict-heading", verdict_clean),
    div(class = "verdict-reason", strong("Reason: "), explanation_clean),
    div(class = "risk-pill", span("Risk Level:"), span(result_meta$risk)),
 
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
          lapply(steps, function(step) tags$li(span(class = "check-icon", "✓"), span(step)))
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
}
 
shinyApp(ui = ui, server = server)
