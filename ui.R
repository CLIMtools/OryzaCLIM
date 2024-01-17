library(scales)
library(shiny)
library(shinyalert)
library(DT)
library(ggplot2)
library(dplyr)
library(readr)
library(ggrepel)
library(plotly)
library(shinythemes)
library(shinyjs)
library(ggdark)
library(shinycssloaders)
library(jquerylib)
library(shinydashboard)
library(RSQLite)
library(sqldf)
library(shinyjqui)
library(feather)

shinyUI(fluidPage(
  
  # Add Javascript
  tags$head(
    tags$link(rel="stylesheet", type="text/css",href="style.css"),
    tags$head(includeScript("google-analytics.html")),
    tags$script('!function(d,s,id){var js,fjs=d.getElementsByTagName(s)    [0],p=/^http:/.test(d.location)?\'http\':\'https\';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+"://platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");')
    
  ),
  useShinyjs(),
  
  uiOutput("app"),
   headerPanel(
    list(
      tags$head(
        tags$style(
          "body {background-color: white;}",
          ".app-header {background-color: #32ff32; padding: 50px;}",
          ".app-title {color: white; font-size: 80px; margin-bottom: 10px;}",
          ".app-subtitle {color: #2c3e50; font-size: 30px;}"
        )
      ),
      HTML(
        '<div class="app-header">
        <img src="OryzaCLIM_logo2.png" height="225px" style="float:left; margin-left: -50px; margin-top: -40px;"/>
        <div style="display: flex; flex-direction: column; margin-left: 10px;">
          <p class="app-title">OryzaCLIM</p>
          <p class="app-subtitle">Explore the local environment of local rice landraces</p>
        </div>
      </div>'
      )
    )
  ),
  
  theme = shinytheme("readable") , 
  
  tabsetPanel(
    tabPanel(
      type = "pills",
      title = "Climate explorer",
      
      # Sidebar
      
      sidebarPanel(
        width = 3,
        wellPanel(
          uiOutput('xvar'),
          uiOutput('yvar'),
          selectInput("pal", "Color palette",
                      selected = 'YlGn',
                      rownames(subset(
                        brewer.pal.info, category %in% c("seq", "div")
                      ))),
          uiOutput("ui")
        ),
       # wellPanel(a(h4('' ))),
        wellPanel(
          a("Tweets by @ClimTools", class = "twitter-timeline"
            , href = "https://twitter.com/ClimTools"),
          style = "overflow-y:scroll; max-height: 1000px"
        ),
        h6('Contact us: clim.tools.lab@gmail.com'), wellPanel(tags$a(div(
          img(src = 'github.png',  align = "middle"), style = "text-align: center;"
        ), href = "https://github.com/CLIMtools/OryzaCLIM"))
      )
      
      
      ###################################################
      ,
      dashboardSidebar(
        
        
        
      ),
      dashboardBody(),
      
      mainPanel(
        downloadButton("downloadData", label="Download complete dataset", class = "butt1"),
        # style font family as well in addition to background and font color
        tags$head(tags$style(".butt1{background-color:orange;} .butt1{color: black;} .butt1{font-family: Courier New}")), 
        fixedRow(column(
          12, h3(textOutput("selected_var")), wellPanel(leafletOutput("map"))
        )),
        fixedRow(
          column(
            12,
            jqui_draggable(fluidRow(
              wellPanel(
                div(style = "height: 435px;", style = "padding:20px;",
                    ggvisOutput("p"))
              ))),
            jqui_draggable(wellPanel(fluidRow(
              column(
                width = 6,
                h3(textOutput("selected_bothb")),
                div(style = "height: 250px;",
                    ggvisOutput("p2"))
              ),
              column(
                width = 6,
                h3(textOutput("selected_bothc")),
                div(style = "height: 250px;",
                    ggvisOutput("p3"))
              )
            )))
          )
        )
      )
    ),
    
    
    tabPanel(title = "Description of climate variables",  mainPanel(fixedRow(
      downloadButton("downloadData2", label="Download environmental descriptors", class = "butt1"),
      # style font family as well in addition to background and font color
      tags$head(tags$style(".butt1{background-color:orange;} .butt1{color: black;} .butt1{font-family: Courier New}")), 
      width = 12,
      div(DT::dataTableOutput("a"), style = "font-size: 75%; width: 75%")
    ))),
    tabPanel(title = "About",  mainPanel(
      h1(div("About OryzaCLIM", style = "color:green; text-align: center; font-family: Arial, sans-serif;")), 
      h3(div("OryzaCLIM is an SHINY component of CLIMtools that provides an interactive spatial analysis web platform using Leaflet. Data points represent the sites of collection of sequenced landraces in an interactive world map. OryzaCLIM allows the inspection of two environment variables simultaneously. The user can first choose an environmental variable (Environmental variable A) that is displayed on the map using a color gradient within the ranges and units detailed in the color palette within the map. Clicking on any of the data points on the map provides information on the selected accession, including its curation details, and the value of the chosen environmental variable for the selected rice landrace varieties", 
             style = "color:grey; text-align: justify; font-family: Arial, sans-serif;")),
      h3(div("OryzaCLIM allows the user to analyze pairwise environmental conditions for these 1,131 accessions using the ggvis package in SHINY. The environmental variable selected on the map (Environmental variable A) can be compared with a second environmental variable that is user-specified (Environmental variable B); the two variables are displayed with a linear correlation provided based on data for the local environments of the 2,999 accessions. We also provide an interactive tabulated database describing the environmental variables available at OryzaCLIM, including their source, units and period of data collection using the DT package in SHINY.", 
             style = "color:grey; text-align: justify; font-family: Arial, sans-serif;")),
      div(style = "display: flex; justify-content: center;",
          tags$a(img(src='climtools.png', width = 150, height = 150, style="margin-right: 10px; border: 1px solid black;"), href="https://www.gramene.org/CLIMtools/"),
          tags$a(img(src='PSU.png', width = 200, height = 150, style="margin-right: 10px; border: 1px solid black;"), href="http://www.personal.psu.edu/sma3/CLIMtools.html"),
          tags$a(img(src='Gramene.jpg', width = 200, height = 150, style="margin-right: 10px; border: 1px solid black;"), href="https://www.gramene.org/")
      )
        
      )
    )
  )
))
