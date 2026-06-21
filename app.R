library(shiny)
library(httr)
library(jsonlite)

ui <- fluidPage(
  titlePanel("PolicyProof — Compliance Reasoning Engine"),
  
  tabsetPanel(
    tabPanel("Document Access",
      sidebarLayout(
        sidebarPanel(
          textAreaInput("scenario", "Describe a scenario:", 
                        placeholder = "e.g. Alice is an employee and wants to read the public report",
                        rows = 4),
          actionButton("check", "Check Compliance", class = "btn-success")
        ),
        mainPanel(
          h3("Verdict:"),
          verbatimTextOutput("verdict")
        )
      )
    ),
    
    tabPanel("Financial Transaction Approval",
      sidebarLayout(
        sidebarPanel(
          numericInput("amount", "Transaction Amount (₹):", value = 30000, min = 0),
          checkboxInput("signoff", "Manager Signoff Given", value = FALSE),
          checkboxInput("fraud", "Fraud Flag Present", value = FALSE),
          actionButton("check_txn", "Check Transaction", class = "btn-warning")
        ),
        mainPanel(
          h3("Transaction Verdict:"),
          verbatimTextOutput("txn_verdict")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  observeEvent(input$check, {
    response <- POST(
      "http://localhost:5000/check",
      body = list(scenario = input$scenario),
      encode = "json"
    )
    result <- content(response, "parsed")
    output$verdict <- renderText({ 
      paste0(result$verdict, "\n\n", result$explanation)
    })
  })

  observeEvent(input$check_txn, {
    response <- POST(
      "http://localhost:5000/check_transaction",
      body = list(
        amount = input$amount,
        signoff = input$signoff,
        fraud = input$fraud
      ),
      encode = "json"
    )
    result <- content(response, "parsed")
    output$txn_verdict <- renderText({
      paste0(result$verdict, "\n\n", result$explanation)
    })
  })
}

shinyApp(ui = ui, server = server)

