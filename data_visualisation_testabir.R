# Chargement des bibliothèques nécessaires
library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)   # Pour formater les axes
library(plotly)   # Pour rendre les graphiques interactifs

# Chargement des données
climat_data <- read.csv("G:/Mon Drive/Cours Master SIGMA M2/Projet_Datavisualisation_902_1/Jeu_ de _données/Tout_Stations_juin_6015 - perpignan_juin_6015.csv", sep = ",")

# Création de la colonne "Annee" en extrayant les 4 premiers caractères de la colonne "anneemois"
climat_data <- climat_data %>% 
  mutate(Annee = as.numeric(substr(as.character(anneemois), 1, 4)))

# Création de la variable "position" en regroupant latitude et longitude
climat_data <- climat_data %>% 
  mutate(position = paste(latitude, longitude, sep = ", "))

# Définition des choix de variables (on ajoute la position et le nom de station)
var_choices <- c("Température minimale" = "valeur_tn", 
                 "Température maximale" = "valeur_tx", 
                 "Précipitations" = "valeur_rr",
                 "Position géographique" = "position",
                 "Nom de station" = "nom_poste")

# Définition des types de graphiques disponibles
graph_choices <- c("Lignes" = "line", 
                   "Nuage de points" = "scatter", 
                   "Box-plot" = "box")

# Définition des choix pour la variable en abscisse
x_choices <- c("Mois" = "anneemois", 
               "Année" = "Annee",
               "Température minimale" = "valeur_tn", 
               "Température maximale" = "valeur_tx", 
               "Précipitations" = "valeur_rr",
               "Position géographique" = "position",
               "Nom de station" = "nom_poste")

# Interface UI
ui <- fluidPage(
  titlePanel("Analyse des Données Climatiques (1960-2015)"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("x_variable", "Choisir la variable en abscisse :", 
                  choices = x_choices, selected = "anneemois"),
      hr(),
      selectInput("variable", "Choisir la 1ère variable :", choices = var_choices),
      selectInput("graph_type", "Choisir le type de graphique :", choices = graph_choices),
      checkboxGroupInput("annees", "Choisir les années à comparer :", 
                         choices = sort(unique(climat_data$Annee)), 
                         selected = sort(unique(climat_data$Annee))),
      hr(),
      checkboxInput("show_second", "Afficher le 2ème graphique", value = FALSE),
      conditionalPanel(
        condition = "input.show_second == true",
        selectInput("variable2", "Choisir la 2ème variable :", choices = var_choices),
        selectInput("graph_type2", "Type de graphique pour la 2ème variable :", choices = graph_choices)
      )
    ),
    
    mainPanel(
      fluidRow(
        column(12, plotlyOutput("climatPlot"))  # Premier graphique interactif
      ),
      br(),
      conditionalPanel(
        condition = "input.show_second == true",
        fluidRow(
          column(12, plotlyOutput("climatPlot2"))  # Deuxième graphique interactif
        )
      ),
      hr(),
      verbatimTextOutput("summary"),    # Statistiques récapitulatives
      verbatimTextOutput("click_info")    # Informations sur le clic dans le 1er graphique
    )
  )
)

# Partie serveur
server <- function(input, output) {
  
  # Filtrage des données en fonction des années sélectionnées
  filtered_data <- reactive({
    climat_data %>% filter(Annee %in% input$annees)
  })
  
  # Fonction de création d'un graphique selon la variable y, le type et la variable x choisie
  create_plot <- function(data, var, type) {
    xvar <- input$x_variable
    
    # Gestion spéciale pour "position"
    if(var == "position") {
      data <- data %>% mutate(tmp = factor(.data[[var]]))
      mapping <- aes(x = as.factor(.data[[xvar]]), 
                     y = tmp, 
                     color = as.factor(Annee),
                     text = paste(xvar, ":", as.factor(.data[[xvar]]),
                                  "<br>Position :", .data[[var]],
                                  "<br>Année :", Annee))
      ylab_text <- "Position géographique"
    } else if(!is.numeric(data[[var]])) {
      # Pour les variables non numériques (ex : nom de station), les convertir en facteur
      data <- data %>% mutate(temp_y = factor(.data[[var]]))
      mapping <- aes(x = as.factor(.data[[xvar]]),
                     y = temp_y,
                     color = as.factor(Annee),
                     text = paste(xvar, ":", as.factor(.data[[xvar]]),
                                  "<br>Valeur :", .data[[var]],
                                  "<br>Année :", Annee))
      ylab_text <- var
    } else {
      mapping <- aes(x = as.factor(.data[[xvar]]), 
                     y = .data[[var]], 
                     color = as.factor(Annee),
                     text = paste(xvar, ":", as.factor(.data[[xvar]]),
                                  "<br>Valeur :", .data[[var]], 
                                  "<br>Année :", Annee))
      ylab_text <- var
    }
    
    base_plot <- ggplot(data, mapping) +
      labs(x = xvar,
           y = ylab_text,
           color = "Année") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    p <- switch(type,
                "line" = {
                  base_plot +
                    geom_line(linewidth = 1) +
                    geom_point(size = 3) +
                    ggtitle(paste("Évolution de", var, "en fonction de", xvar))
                },
                "scatter" = {
                  base_plot +
                    geom_point(size = 4) +
                    ggtitle(paste("Nuage de points pour", var, "en fonction de", xvar))
                },
                "box" = {
                  ggplot(data, aes(x = as.factor(Annee), 
                                   y = .data[[var]], 
                                   fill = as.factor(Annee),
                                   text = paste("Année :", Annee, 
                                                "<br>Valeur :", .data[[var]]))) +
                    geom_boxplot() +
                    labs(x = "Année",
                         y = var,
                         fill = "Année") +
                    ggtitle(paste("Box-plot de", var, "par année")) +
                    theme_minimal()
                }
    )
    p
  }
  
  # Premier graphique interactif
  output$climatPlot <- renderPlotly({
    data <- filtered_data()
    p <- create_plot(data, input$variable, input$graph_type)
    ggplotly(p, tooltip = "text")
  })
  
  # Deuxième graphique interactif (si activé)
  output$climatPlot2 <- renderPlotly({
    req(input$show_second)
    data <- filtered_data()
    p2 <- create_plot(data, input$variable2, input$graph_type2)
    ggplotly(p2, tooltip = "text")
  })
  
  # Affichage des informations sur le clic dans le 1er graphique
  output$click_info <- renderPrint({
    event_data <- event_data("plotly_click")
    if (is.null(event_data)) {
      "Cliquez sur un point du graphique pour voir les détails."
    } else {
      paste("Valeur X :", event_data$x, "\nValeur Y :", event_data$y)
    }
  })
  
  # Affichage des statistiques récapitulatives pour la variable sélectionnée (si numérique)
  output$summary <- renderPrint({
    data <- filtered_data()
    if (is.numeric(data[[input$variable]])) {
      data %>%
        group_by(Annee) %>%
        summarise(
          Moyenne = mean(.data[[input$variable]], na.rm = TRUE),
          Médiane = median(.data[[input$variable]], na.rm = TRUE),
          Minimum = min(.data[[input$variable]], na.rm = TRUE),
          Maximum = max(.data[[input$variable]], na.rm = TRUE)
        )
    } else {
      "Les statistiques ne sont pas disponibles pour la variable sélectionnée (non numérique)."
    }
  })
}

# Exécution de l'application Shiny
shinyApp(ui, server)
