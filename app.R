library(shiny)
library(httr)
library(jsonlite)

ui <- fluidPage(
  titlePanel("PolicyProof — Compliance Reasoning Engine"),
  
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
)

server <- function(input, output, session) {
  observeEvent(input$check, {
    response <- POST(
      "http://localhost:5000/check",
      body = list(scenario = input$scenario),
      encode = "json"
    )
    result <- content(response, "parsed")
    output$verdict <- renderText({ result$verdict })
  })
}

shinyApp(ui = ui, server = server)
