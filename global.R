require(shiny)
require(shinydashboard)
require(shinyjs)
require(leaflet)
require(ggvis)
library(plyr)
require(dplyr)
library(RColorBrewer)
require(raster)
require(gstat)
require(rgdal)
require(Cairo)
library(sp)
library(htmltools)


readfile <- read.csv("data/OryzaCLIM_data.csv",row.names = NULL)
readfile2 <- read.csv("data/datadescription.csv",row.names = NULL)

FULL.val <-read.csv("data/OryzaCLIM_data.csv")
class(FULL.val)  
na.omit(FULL.val)

vlc <- read.delim("data/variable_label_categoryb.txt", header = FALSE, sep = "\t")
colnames(FULL.val) <- vlc[,2]
cats <- read.delim("data/categoriesb.txt", header = FALSE, sep = "\t")
vars <- vector("list",dim(cats)[1])
names(vars) <- cats$V1
n = dim(vlc)[1]
for(i in 1:n) {
	c <- vlc[i,3]
	l <- vlc[i,2]
	if (is.null(vars[[c]])) {
		vars[c] <- c(l)
	}
	else {
		vars[[c]] <- c(vars[[c]], l)
	}
}

# a data.frame

FULL <- SpatialPointsDataFrame(FULL.val[,c("Longitude (degrees)", "Latitude (degrees)")], FULL.val[,1:417])

#########

descriptiondataset <-read.csv("data/datadescription.csv")


datasets <- list(
  'FULL'=  FULL,
	'cats'= vars,
  'descriptiondataset'
  
)

baselayers <- list(
  'FULL'='Esri.WorldImagery'
)

