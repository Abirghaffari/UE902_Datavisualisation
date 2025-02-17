library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(bslib) # Pour un meilleur design
library(plotly)
# Chargement des données

climat_1975 <- read.csv("../socoa_1975.csv", sep=",")
climat_2015 <- read.csv("../socoa_7515/socoa_2015.csv", sep=",")

# Ajout d'une colonne "Année" pour la comparaison
climat_1975$Annee <- 1975
climat_2015$Annee <- 2015

# Combinaison des données
climat_data <- bind_rows(climat_1975, climat_2015)

# Interface UI améliorée
ui <- fluidPage(
  theme = bs_theme(bootswatch = "flatly"),
  
  # Ajout des logos en haut de la page
  fluidRow(
    column(2, img(src = "jjr.png", height = "80px")), # Logo 1
    column(2, img(src = "inp.png", height = "80px")), # Logo 2
    column(8, h5("UE 902_2, Laurent JEGOU", style = "text-align: right;")) # Titre vers la droite
  ),
  # Petit logo avant le titre
  fluidRow(
    column(12, img(src = "application-meteo.png", height = "40px", style = "float: left; margin-right: 10px;"), 
           titlePanel("Visualisation graphiques de données climatiques de Socoa (1975 vs 2015) 🌡️"))
  ),
  fluidRow(
    column(12, wellPanel(
      style = "background-color: #f0f8ff; padding: 20px; border-radius: 10px;",
      h4(strong("📊 Objectif de l'analyse")),
      p("Cette application interactive permet d'explorer et de comparer les données climatiques de Socoa sur deux périodes distinctes : 1975 et 2015. L'objectif principal est d'analyser les évolutions des températures minimales et maximales ainsi que des précipitations sur ces 40 ans. Grâce à une interface dynamique, les utilisateurs peuvent sélectionner différentes variables et types de représentations graphiques pour identifier des tendances et des variations climatiques significatives.")
    ))
  ),
  
  fluidRow(
    column(12, wellPanel(
      style = "background-color: #fff0f5; padding: 20px; border-radius: 10px; margin-top: 20px;",
      h4(strong("🛠 Méthodologie et Justification des choix")),
      p(
        "1. ", strong("Chargement et prétraitement des données"), " : Les données climatiques sont importées et fusionnées, avec une colonne 'Année' pour permettre des comparaisons directes. La transformation en format long facilite leur analyse.", br(),
        "2. ", strong("Interface interactive avec Shiny"), " : Utilisation de 'shiny' et 'bslib' pour une expérience fluide et esthétique. L'utilisateur peut choisir les variables et années à comparer.", br(),
        "3. ", strong("Choix des types de graphiques et justification"), " :", br(),
        "   - ", strong("Graphiques en lignes"), " : Pour suivre l'évolution des valeurs.", br(),
        "   - ", strong("Diagrammes en violin avec Boxplots"), " : Pour analyser la distribution et la variabilité des données.", br(),
        "   - ", strong("Heatmap"), " : Pour visualiser l'intensité des valeurs et les tendances saisonnières.", br(),
        "   - ", strong("Graphique en aire"), " : Pour explorer les relations entre variables et les variations temporelles.", br(),
        "4. ", strong("Statistiques descriptives"), " : Affichage des moyennes, médianes, minimums et maximums des variables pour détecter d'éventuelles anomalies climatiques.", br(),
        "5. ", strong("Interactivité et exploration"), " : Clic interactif sur les graphiques pour afficher des détails sur les valeurs sélectionnées.", br(),
        "L'application permet ainsi une vision complète des évolutions climatiques de Socoa sur 40 ans et met en évidence d'éventuels changements climatiques affectant la région."
      )
    ))
  ),
  sidebarLayout(
    sidebarPanel(
      style = "background-color: #f5f5f5; padding: 20px; border-radius: 10px;",
      # Choix multiple de variables
      checkboxGroupInput("variables", "Choisir une ou plusieurs variables :", 
                         choices = c("Température minimale" = "valeur_tn", 
                                     "Température maximale" = "valeur_tx", 
                                     "Précipitations" = "valeur_rr"),
                         selected = "valeur_tn"), # Par défaut, une variable est sélectionnée
      selectInput("graph_type", "Choisir le type de graphique :", 
                  choices = c("Lignes" = "line", 
                              "Violin avec Boxplot" = "violin_boxplot",
                              "Heatmap" = "heatmap",
                              "Graphique en Aire" = "area")),
      checkboxGroupInput("annees", "Choisir les années à comparer :", 
                         choices = c(1975, 2015), selected = c(1975, 2015))
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("📉 Graphiques", plotlyOutput("climatPlot")),
        tabPanel("📊 Statistiques", tableOutput("summary"))
      )
    )
  ),
  
  # Liste des participants en bas de la page
  div(
    style = "text-align: center; padding: 15px; margin-top: 30px; background-color: #f8f9fa; border-top: 2px solid #dee2e6;",
    h4("👥 Liste des Participantes"),
    p("Abir, Aby, Kadiatou")  
  )
)  

# Partie serveur
server <- function(input, output) {
  
  filtered_data <- reactive({
    climat_data %>% filter(Annee %in% input$annees)
  })
  
  output$climatPlot <- renderPlotly({
    data <- filtered_data()
    
    # Transformer les données en format long pour faciliter la représentation de plusieurs variables
    data_long <- data %>%
      pivot_longer(cols = starts_with("valeur_"), 
                   names_to = "Variable", 
                   values_to = "Valeur") %>%
      filter(Variable %in% input$variables) # Filtrer selon les variables sélectionnées
    
    # Extraire le mois et le convertir en facteur avec des étiquettes textuelles
    data_long <- data_long %>%
      mutate(Mois = substr(anneemois, 5, 6)) %>%
      mutate(Mois = factor(Mois, 
                           levels = c("01", "02", "03", "04", "05", "06", 
                                      "07", "08", "09", "10", "11", "12"),
                           labels = c("Jan", "Fév", "Mar", "Avr", "Mai", "Jui", 
                                      "Jui", "Aoû", "Sep", "Oct", "Nov", "Déc")))
    
    # Générer le graphique en fonction du type sélectionné
    if (input$graph_type == "line") {
      p <- ggplot(data_long, aes(x = Mois, y = Valeur, group = interaction(Annee, Variable), color = interaction(Annee, Variable))) +
        geom_line(size = 1) + 
        geom_point(size = 3) +
        labs(title = paste("Évolution mensuelle des variables sélectionnées"),
             x = "Mois", y = "Valeur", color = "Année et Variable") +
        scale_color_manual(values = c("1975.valeur_tn" = "blue", 
                                      "2015.valeur_tn" = "lightblue", 
                                      "1975.valeur_tx" = "red", 
                                      "2015.valeur_tx" = "pink",
                                      "1975.valeur_rr" = "darkgreen",
                                      "2015.valeur_rr" = "lightgreen")) +
        theme_minimal() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
      
    } else if (input$graph_type == "violin_boxplot") {
      # Violon avec boxplot
      p <- ggplot(
        data_long, 
        aes(x = interaction(Annee, Variable), y = Valeur, fill = interaction(Annee, Variable), color = interaction(Annee, Variable))
      ) +
        geom_violin(trim = FALSE, alpha = 0.4) + # Ajouter de la transparence au violon
        geom_boxplot(width = 0.2, fill = "white", color = "black", outlier.shape = NA) + # Ajuster la largeur et la couleur
        labs(
          title = "Distribution des variables sélectionnées par année",
          x = "Année et Variable", 
          y = "Valeur", 
          fill = "Année et Variable"
        ) +
        theme_minimal() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
      
      # Convertir en graphique interactif avec plotly
      ggplotly(p)
      
    } else if (input$graph_type == "heatmap") {
      p <- ggplot(data_long, aes(x = Mois, y = interaction(Annee, Variable), fill = Valeur), color = interaction(Annee, Variable)) +
        geom_tile() + scale_fill_gradient(low = "white", high = "brown") +
        labs(title = paste("Heatmap des variables sélectionnées"), x = "Mois", y = "Année et Variable", fill = "Valeur") +
        theme_minimal() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
      
    } else if (input$graph_type == "area") {
      # Graphique en aire
      p <- ggplot(
        data_long, 
        aes(x = Mois, y = Valeur, group = interaction(Annee, Variable), fill = interaction(Annee, Variable))
      ) +
        geom_area(position = "identity", alpha = 0.5) +
        labs(
          title = "Évolution mensuelle des variables sélectionnées",
          x = "Mois", 
          y = "Valeur", 
          fill = "Année et Variable"
        ) +
        theme_minimal() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
      
      # Convertir en graphique interactif avec plotly
      ggplotly(p)
    }
  })
  
  output$summary <- renderTable({
    filtered_data() %>%
      group_by(Annee) %>%
      summarise(across(starts_with("valeur_"), list(Moyenne = mean, Médiane = median, Minimum = min, Maximum = max), na.rm = TRUE))
  })
}

# Lancer l'application
shinyApp(ui, server)