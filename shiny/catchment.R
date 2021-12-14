

library(shiny)
library(leaflet)
library(jsonlite)
# rsconnect::deployApp(account='OWRC')

shinyApp(
  ui = fluidPage(
    leafletOutput("map")
  ),

  server = function(input, output, session) {

    ormgp.region <- readOGR("shp/ORMGP-region.geojson",verbose = FALSE)
    
    output$map <- renderLeaflet({
     leaflet(ormgp.region) %>%
      addProviderTiles( providers$Stamen.TonerLite, options = providerTileOptions(noWrap = TRUE) ) %>%
      addPolygons(fill = FALSE)
    })

    observe({
      leafletProxy("map") %>% clearPopups()
      event <- input$map_click
      if (is.null(event)) return()
      lat <- round(event$lat,3)
      lng <- round(event$lng, 3)
      
      showNotification(paste0("querying to ",lat, ', ', lng))
      qstr <- paste0("https://golang.oakridgeswater.ca/carea/",event$lat,"/",event$lng)
      geojson <- readLines(qstr) %>% paste(collapse = "\n")
      gg <- fromJSON(geojson)
      isolate(leafletProxy("map") %>%
                clearGeoJSON() %>%
                addPopups(event$lng,event$lat,paste0(lat, ', ', lng,'<br>Area ', gg$features$properties$area,'km²'))
              ) %>%
        addGeoJSON(geojson)
    })
    
    session$onSessionEnded(stopApp)
  }#,
  # options = list(height = 600)
)
