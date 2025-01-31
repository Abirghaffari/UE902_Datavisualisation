import dash
from dash import dcc, html
from dash.dependencies import Input, Output
import pandas as pd
import plotly.graph_objects as go
import numpy as np

# Charger les données
df = pd.read_csv("C:/Users/abir/Desktop/Peupliers/data_final/tableaux/df_px_filtre_dept10.csv")


# Liste des métriques à vérifier pour les valeurs manquantes
metriques = ['grid_PAI', 'grid_CC', 'grid_MOCH', 'grid_ENL']


# Définir les couleurs pour chaque source
source_colors = {
    "dep47": "yellow",
    "dep73": "blue",
    "dep82_bb": "green",
    "dep82_sp": "red",
    "dep10": "purple"
}


# Initialiser l'application Dash
app = dash.Dash(__name__, suppress_callback_exceptions=True)
app.title = "Analyse Interactive des métriques et de l'indice de confiance en fonction de l'âge"

# Définir la disposition et mise en page
app.layout = html.Div(
    style={
        'backgroundColor': 'white',
        'padding': '20px',
        'fontFamily': 'Arial, sans-serif'
    },
    children=[
        html.H1('Analyse Interactive des Indices de Confiance', style={'color': 'black', 'textAlign': 'center'}),

        # Conteneur pour les sélections
        html.Div(
            style={'display': 'flex', 'flexWrap': 'wrap', 'justifyContent': 'space-between', 'gap': '20px'},
            children=[
                html.Div([
                    html.Label('Sélectionnez le(s) Cultivar(s):', style={'color': 'black', 'fontWeight': 'bold'}),
                    dcc.Dropdown(
                        id='cultivar-dropdown',
                        options=sorted_cultivars,
                        value=[],
                        multi=True,
                        placeholder="Sélectionnez un ou plusieurs cultivars",
                        style={'backgroundColor': 'white', 'color': 'black'}
                    )
                ], style={'width': '30%', 'minWidth': '250px'}),
                html.Div([
                    html.Label('Sélectionnez la variable pour l\'axe X:', style={'color': 'black', 'fontWeight': 'bold'}),
                    dcc.Dropdown(
                        id='xaxis-dropdown',
                        options=[
                            {'label': 'Âge de la plantation', 'value': 'age_plan'},
                            {'label': 'grid_PAI', 'value': 'grid_PAI'},
                            {'label': 'grid_CC', 'value': 'grid_CC'},
                            {'label': 'grid_ENL', 'value': 'grid_ENL'},
                            {'label': 'grid_MOCH', 'value': 'grid_MOCH'},
                            {'label': 'grid_VCI', 'value': 'grid_VCI'},
                            {'label': 'Date de Raster', 'value': 'year'},
                            {'label': 'Année de plantation', 'value': 'annee_plan'},
                            {'label': 'Valeur', 'value': 'valeur'}
                           
                        ],
                        value='age_plan',
                        style={'backgroundColor': 'white', 'color': 'black'}
                    )
                ], style={'width': '30%', 'minWidth': '250px'}),
                html.Div([
                    html.Label('Variable pour Y (Graphique 1):', style={'color': 'black', 'fontWeight': 'bold'}),
                    dcc.Dropdown(
                        id='yaxis1-dropdown',
                        options=[
                            {'label': 'Valeur', 'value': 'valeur'},
                            {'label': 'grid_PAI', 'value': 'grid_PAI'},
                            {'label': 'grid_CC', 'value': 'grid_CC'},
                            {'label': 'grid_ENL', 'value': 'grid_ENL'},
                            {'label': 'grid_MOCH', 'value': 'grid_MOCH'},
                            {'label': 'grid_VCI', 'value': 'grid_VCI'}   
                        ],
                        value='valeur',
                        style={'backgroundColor': 'white', 'color': 'black'}
                    )
                ], style={'width': '30%', 'minWidth': '250px'}),
                html.Div([
                    html.Label('Variable pour Y (Graphique 2):', style={'color': 'black', 'fontWeight': 'bold'}),
                    dcc.Dropdown(
                        id='yaxis2-dropdown',
                        options=[
                            {'label': 'Valeur', 'value': 'valeur'},
                            {'label': 'grid_PAI', 'value': 'grid_PAI'},
                            {'label': 'grid_ENL', 'value': 'grid_ENL'},
                            {'label': 'grid_MOCH', 'value': 'grid_MOCH'},
                            {'label': 'grid_VCI', 'value': 'grid_VCI'},
                            {'label': 'grid_CC', 'value': 'grid_CC'}
                        ],
                        value='biomass_mean',
                        style={'backgroundColor': 'white', 'color': 'black'}
                    )
                ], style={'width': '30%', 'minWidth': '250px'}),
            ]
        ),
        html.Div([
            dcc.Graph(id='graphique-1', style={'width': '100%', 'height': '400px'}),
            dcc.Graph(id='graphique-2', style={'width': '100%', 'height': '400px'}),
        ], style={'marginTop': '50px'})
    ]
)

@app.callback(
    [Output('graphique-1', 'figure'), Output('graphique-2', 'figure')],
    [
        Input('cultivar-dropdown', 'value'),
        Input('xaxis-dropdown', 'value'),
        Input('yaxis1-dropdown', 'value'),
        Input('yaxis2-dropdown', 'value')
    ]
)
def update_graphs(cultivars_selectionnes, variable_x, variable_y1, variable_y2):
    filtered_df = df[df['cultivar_n'].isin(cultivars_selectionnes)] if cultivars_selectionnes else df

    def create_figure(variable_y):
        fig = go.Figure()

        for source, color in source_colors.items():
            source_data = filtered_df[filtered_df['source'] == source]

            # Box-Notch
            fig.add_trace(go.Box(
                x=source_data[variable_x],
                y=source_data[variable_y],
                name=f"Box {source}",
                marker_color='gray',  # Couleur des boxes
                boxpoints=False,      # Pas de points sur le box
                notched=True
            ))

            # Nuage de points
            fig.add_trace(go.Scatter(
                x=source_data[variable_x] + 0.2,  # Décalage horizontal
                y=source_data[variable_y],
                mode='markers',
                marker=dict(color=color, size=6),
                name=f"Points {source}"
            ))

        fig.update_layout(
            title=f"{variable_y} en fonction de {variable_x}",
            xaxis_title=variable_x,
            yaxis_title=variable_y,
            template='simple_white'
        )
        return fig

    # Graphiques
    fig1 = create_figure(variable_y1)
    fig2 = create_figure(variable_y2)

    return fig1, fig2

if __name__ == '__main__':
    app.run_server(debug=True, host='127.0.0.1', port=8050)
