library(shiny)

# Interfejs oraz parametry wejściowe
ui <- fluidPage(
  h2("Parametry rozkładu dwumianowego:"),
  sliderInput(
    "size",
    "Ilość prób:",
    min = 1,
    max = 100,
    value = 50,
    step = 1
  ),
  sliderInput(
    "prob",
    "Prawdopodobieństwo sukcesu:",
    min = 0,
    max = 1,
    value = 0.5,
    step = 0.01
  ),
  h2("Parametry symulacji: "),
  sliderInput(
    "n",
    "Liczebność próby losowej:",
    min = 2,
    max = 200,
    value = 50,
    step = 1
  ),
  sliderInput(
    "iterations",
    "Liczba symulacji:",
    min = 10,
    max = 1000,
    value = 500,
    step = 10
  ),
  sliderInput(
    "conf_level",
    "Poziom ufności:",
    min = 0,
    max = 1,
    value = 0.75,
    step = 0.01
  ),
  selectInput(
    "simulation_type",
    "Przedział ufności dla:",
    choices = c("Wariancji", "Średniej")
  ),
  actionButton("go", "Start"),
  verbatimTextOutput("prop_correct"),
)

server <- function(input, output) {
  results <- eventReactive(input$go, {
    res <- vector("numeric", input$iterations)
    
    #wartości teoretyczne dla rozkładu dwumianowego
    binom_mean <- input$size * input$prob
    binom_variation <- input$size * input$prob * (1 - input$prob)
    
    for (i in 1:input$iterations) {
      # wygenerowanie próby losowej oraz obliczenie jej parametrów
      sample <- rbinom(input$n, input$size, input$prob)
      sample_mean <- mean(sample)
      sample_sd <- sd(sample)
      
      if (input$simulation_type == "Średniej") {
        t_value <- qt(1 - (1 - input$conf_level) / 2, df = input$n - 1)
        margin_of_error <- t_value * sample_sd / sqrt(length(sample))
        lower_bound <- sample_mean - margin_of_error
        upper_bound <- sample_mean + margin_of_error
        tested_value <- binom_mean
      }
      
      if (input$simulation_type == "Wariancji") {
        lower_bound <- (sample_sd ^ 2) * (input$n - 1) / qchisq(1 - (1 - input$conf_level) / 2, df = input$n - 1)
        upper_bound <- (sample_sd ^ 2) * (input$n - 1) / qchisq((1 - input$conf_level) / 2, df = input$n - 1)
        tested_value <- binom_variation
      }
      
      # jeśli wartość teoretyczna mieści się w obliczonym przedziale to
      # aktualna iteracja symulacji jest sukcesem
      if (tested_value > lower_bound & tested_value < upper_bound) {
        res[i] <- 1
      } else {
        res[i] <- 0
      }
    }
    res
  })
  output$prop_correct <- renderPrint({
    # wyświetl procent udanych iteracji
    mean(results())
  })
}

shinyApp(ui, server)