library(shiny)
library(shinyjs)
library(shiny)
library(shinyjs)
library(leaflet.extras)
library(dplyr)

shinyServer(function(input, output) {
  # credentials <- shinyauthr::loginServer(
  #   id = "login",
  #   data = user_base,
  #   user_col = user,
  #   pwd_col = password,
  #   log_out = reactive(logout_init())
  # )
  
  # call the logout module with reactive trigger to hide/show
  # logout_init <- shinyauthr::logoutServer(
  #   id = "logout",
  #   active = reactive(credentials()$user_auth)
  # )
  #
  # output$user_table <- renderTable({
  #   # use req to only render results when credentials()$user_auth is TRUE
  #   req(credentials()$user_auth)
  #   credentials()$info
  # })
  
  output$map <- renderLeaflet({
    print('render map')
    leaflet(FULL) %>% 
      addProviderTiles("OpenTopoMap") %>%
      addProviderTiles("OpenStreetMap.Mapnik", group = "OpenStreetmap") %>%
      addProviderTiles("Esri.WorldImagery", group = "Esri.WorldImagery") %>%
      addProviderTiles("Esri.WorldGrayCanvas", group = "Esri.WorldGrayCanvas") %>%
      addProviderTiles("Esri.NatGeoWorldMap", group = "Esri.NatGeoWorldMap") %>%
      addProviderTiles("Esri.OceanBasemap", group = "Esri.OceanBasemap") %>%
      addProviderTiles("CartoDB.DarkMatter", group = "DarkMatter (CartoDB)") %>%
      addHeatmap(lng = ~`Longitude (degrees)`, lat = ~`Latitude (degrees)`, radius = 5) %>%
      setView(lng = 0, lat = 50, zoom = 2) %>%
      addLayersControl(baseGroups = c("OpenStreetmap","OpenTopoMap",'Esri.WorldImagery',"Esri.WorldGrayCanvas","Esri.NatGeoWorldMap","Esri.OceanBasemap",'DarkMatter (CartoDB)' ),
                       options = layersControlOptions(collapsed = TRUE, autoZIndex = F, position = 'bottomleft' ))
    
    
  })
  
  
  df <- datasets[['FULL']]
  makeReactiveBinding('df')
  
  observeEvent(input$dataset,{
    print('dataset')
    leafletProxy('map')%>%clearShapes()
    df <<- datasets[[input$dataset]]  
    i.active <<- NULL
    
  })
  
  
  coords <- reactive({
    print('coords')
    
    crds <- data.frame(coordinates(df))
    leafletProxy('map')%>%fitBounds(lng1=min(crds[,1]),lng2=max(crds[,1]),
                                    lat1=min(crds[,2]),lat2=max(crds[,2]))
    
    crds
    
  })
  
  output$yvar <- renderUI(selectInput('yvar',label='Environmental variable B',choices = datasets[['cats']], selected='SRTM 90m Digital Elevation Database v4.1 (m)'))
  output$xvar <- renderUI(selectInput('xvar',label='Environmental variable A (mapped)',choices = datasets[['cats']], selected='CERES Solar insolation spring (W/m2)'))
  
  xVar <- reactive({
    print('xVar')
    if(is.null(input$xvar)) return(names(df)[1])
    # xvar_ <<- input$xvar
    input$xvar})
  
  yVar <- reactive({
    if(is.null(input$yvar)) return(names(df)[2])
    input$yvar})      
  
  
  IDVar <- reactive({
    print('ID')
    if(is.null(input$color)) return(names(df)[3])
    input$color})
  
  
  
  
  ggvisdf <- reactive({
    print('ggvesdf1')
    df1 <- df@data
    gdf <- df1[, c(xVar(), yVar(), "Longitude (degrees)", "Latitude (degrees)")]
    names(gdf) <- c("x", "y", "lng", "lat")
    gdf
  })  
  
  colorData <- reactive({
    print(names(input))
    print('colData')
    df1 <- df@data
    df1[,xVar()]})
  colorpal <- reactive(colorNumeric(input$pal, colorData()))
  
  pal <- reactive({colorpal()(colorData())})
  
  
  
  observe({
    
    print('update map size/opa/color')
    x <- coords()[,1]
    y <- coords()[,2]
    leafletProxy('map')%>%
      addCircleMarkers(lng=x,fillColor = pal(),
                       lat=y,
                       stroke = F,
                       layerId = as.character(1:length(x)),
                       radius = input$size/10, 
                       color = 'red',
                       fillOpacity = 1, 
                       
                       popup = paste("ID:", FULL$ID, "<br>",
                                     "Name: ", FULL$Name, "<br>",
                                     "Group: ", FULL$SSP, "<br>",
                                     "COUNTRY: ", FULL$COUNTRY)  ) 
    
  })
  
  
  
  
  observe({
    print('legend')
    leafletProxy("map")%>%
      clearControls() %>% 
      addLegend(opacity = 1,position = "bottomright",title = xVar(),
                pal = colorpal(), values = rev(colorData()))
    
  })
  
  
  mapData <- reactive({
    print('mapdata')
    
    mb <- input$map_bounds
    
    if(is.null(mb))
      return(1)#as.vector(rep(1,nrow(coords()))))
    if(nrow(coords())!=nrow((ggvisdf())))
      return(1)
    
    as.numeric(coords()[,1]>mb$west&coords()[,1]<mb$east&
                 coords()[,2]>mb$south&coords()[,2]<mb$north)+0.1
    
  })
  
  
  tooltip <- function(x) {
    ggvisHover <<- x
    if(is.null(x)) return(NULL)
    tt<<-paste0(c(xVar(),yVar()), ": ", format(x[1:2]), collapse = "<br/>")
    leafletProxy('map') %>%addControl(tt,layerId = 'tt',position = 'topright')
    tt
  }
  
  click_tooltip <- function(x) {
    point <- ggvisdf()[ggvisdf()$x == x$x & ggvisdf()$y == x$y, ]
    if(nrow(point) == 1) {
      leafletProxy('map') %>%
        removeMarker('hover') %>%
        addCircleMarkers(lat=point$lat, opacity = 1,
                         fillOpacity = 0,
                         radius = (input$size/5),
                         lng=point$lng,
                         layerId = 'hover',weight = 6,
                         color = 'red',fill = FALSE)
    }
    NULL
  }
  
  
  ggvisHover <- NULL
  makeReactiveBinding('ggvisHover')
  i.active <- NULL
  makeReactiveBinding('i.active')
  
  
  observeEvent(ggvisHover,{
    h <- ggvisHover[1:2]
    i.active <<- ggvisdf()[,'x']==h[[1]]&ggvisdf()[,'y']==h[[2]]
  })
  
  observeEvent(input$map_marker_mouseover,{
    id <- as.numeric(input$map_marker_mouseover$id)
    if(!is.na(id)){
      i.active <<- id
    }
  })
  
  
  
  observeEvent(i.active,{
    leafletProxy('map') %>%
      removeMarker('hover') %>%
      addCircleMarkers(lat=coords()[i.active,2],opacity = 1,
                       fillOpacity = 0,
                       radius = (input$size/5),
                       lng=coords()[i.active,1],
                       layerId = 'hover',weight = 6,
                       color = 'red',fill = FALSE) 
  })
  
  mouseOver <- reactive({
    
    p <- ggvisdf()[i.active,c('x','y')]
    if(class(i.active)=='numeric'){tooltip(p)}
    p
  })
  
  
  ####reactive text
  #   output$selected_var <- renderText({ 
  #    paste(input$color)
  #  })
  
  #   output$selected_both <- renderText({ 
  #      paste("var. A:", input$color, "vs. var. B:", input$yvar)
  #   })
  #   output$selected_bothb <- renderText({ 
  #     paste(input$color)
  #   })
  
  # output$selected_bothc <- renderText({ 
  #     paste(input$yvar)
  #     })
  
      #######Table
      output$a <- DT::renderDataTable(descriptiondataset, filter = 'top', options = list(
        pageLength = 50, autoWidth = TRUE))
      output$FULL <- DT::renderDataTable(FULL.val, filter = 'top', options = list(
        pageLength = 50, autoWidth = TRUE))
      #Xx<-input$xvar
      #Yy<-input$yvar
      
      ######Big plot X vs y
      reactive({
        ggvisdf %>% 
          ggvis(~x,~y) %>%
          set_options(width = "auto", height = "auto", resizable=TRUE) %>%    
          # add_axis("x", title = xVar())  %>% 
          add_axis("x", title = xVar(), grid = TRUE, title_offset = 40,  properties = axis_props(
            axis = list(stroke = "red"),title = list(fontSize = 20),
            labels = list(fontSize = 16)))  %>% 
          add_axis("y", title = yVar(), grid = TRUE, title_offset = 60,  properties = axis_props(
            axis = list(stroke = "blue"),title = list(fontSize = 10),
            labels = list(fontSize = 16)))  %>%      
          layer_points(size := input_slider(1, 100, value = 50,id='size',label = 'Size'),
                       opacity := 1,
                       fill := pal) %>% 
          
          add_tooltip(tooltip, "hover") %>%
          add_tooltip(click_tooltip, "click") %>%
          
          layer_points(data =mouseOver,stroke:='red',size := 150,fillOpacity=0,strokeWidth:=5) %>%
          layer_model_predictions(model = "lm", se = TRUE)
      }) %>% bind_shiny("p",'ui')
      
      
      
      #####density plot X
      ggvisdf %>% 
        ggvis(~x) %>%
        set_options(width = "auto", height = "auto", resizable=TRUE) %>%    
        add_axis("x", title = "Environmental variable A (mapped)",properties = axis_props(
          axis = list(stroke = "red"),
          title = list(fontSize = 20),
          labels = list(fontSize = 12)))  %>% 
        add_axis("y", title = 'count', properties = axis_props(
          axis = list(stroke = "red"),
          title = list(fontSize = 15),
          labels = list(fontSize = 10)))  %>%   
        
        layer_histograms(width = 0.5, center = 20, fill := "red") %>%     
        layer_points(data =mouseOver,stroke:='black',shape := "triangle-down", size := 50) %>%
        bind_shiny("p2")
      
      #####density plot y
      ggvisdf %>% 
        ggvis(~y) %>%
        set_options(width = "auto", height = "auto", resizable=TRUE) %>%    
        add_axis("x", title = 'Environmental variable B', properties = axis_props(
          axis = list(stroke = "blue"),
          title = list(fontSize = 20),
          labels = list(fontSize = 10)))  %>%   
        
        add_axis("y", title = 'count', properties = axis_props(
          axis = list(stroke = "blue"),
          title = list(fontSize = 20),
          labels = list(fontSize = 10)))  %>%  
        layer_histograms(width = 0.5, center = 20, fill := "blue") %>%   
        layer_points(data =mouseOver,stroke:='black',shape := "triangle-down", size := 50) %>%
        bind_shiny("p3")
      
      
      

      ####

      output$downloadData <- downloadHandler(
        filename = function() { 
          paste("AraCLIM V2.0_", Sys.Date(), ".csv", sep="")
        },
        content = function(file) {
          write.csv(readfile, file)
        })
      output$downloadData2 <- downloadHandler(
        filename = function() { 
          paste("AraCLIM V2.0_Environmental descriptors_", Sys.Date(), ".csv", sep="")
        },
        content = function(file) {
          write.csv(readfile2, file)
        })
      
      
    })
  

