## ----install, eval = FALSE---------------------------------------------------
## ## For installing Bioconductor packages
## if (!requireNamespace("BiocManager", quietly = TRUE)) {
##     install.packages("BiocManager")
## }
## 
## ## Install required packages
## BiocManager::install(
##     c(
##         "usethis", ## Utilities
##         "here",
##         "biocthis",
##         "lobstr",
##         "postcards",
##         "sessioninfo",
##         "SummarizedExperiment", ## Main containers / vis
##         "iSEE",
##         "edgeR", ## RNA-seq
##         "ExploreModelMatrix",
##         "limma",
##         "recount3",
##         "pheatmap", ## Visualization
##         "ggplot2",
##         "patchwork",
##         "RColorBrewer",
##         "ComplexHeatmap",
##         "spatialLIBD" ## Advanced
##     )
## )


## ----session_packages, eval = TRUE, message = FALSE--------------------------
## Load the package at the top of your script
library("sessioninfo")

##  Utilities
library("BiocStyle")
library("biocthis")
library("here")
library("lobstr")
library("postcards")
library("usethis")
library("sessioninfo")

## Main containers / vis
library("SummarizedExperiment")
library("iSEE")

## RNA-seq
library("edgeR")
library("ExploreModelMatrix")
library("limma")
library("recount3")

## Visualization
library("ComplexHeatmap")
library("ggplot2")
library("patchwork")
library("pheatmap")
library("RColorBrewer")

## Advanced
library("spatialLIBD")


## ----session_info------------------------------------------------------------
## Reproducibility information
options(width = 120)
session_info()
proc.time()

