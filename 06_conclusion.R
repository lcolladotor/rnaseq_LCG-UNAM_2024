## ----"speaqeasy_data"-------------------------------------------------------------------------------------------------
speaqeasy_data <- file.path(tempdir(), "rse_speaqeasy.RData")
download.file("https://github.com/LieberInstitute/SPEAQeasy-example/blob/master/rse_speaqeasy.RData?raw=true", speaqeasy_data, mode = "wb")
library("SummarizedExperiment")
load(speaqeasy_data, verbose = TRUE)
rse_gene


## ----"respuestas"-----------------------------------------------------------------------------------------------------
## Exploremos la variable de PrimaryDx
table(rse_gene$PrimaryDx)
## Eliminemos el diagnosis "Other" porque no tiene información
rse_gene$PrimaryDx <- droplevels(rse_gene$PrimaryDx)
table(rse_gene$PrimaryDx)

## Exploremos numéricamente diferencias entre grupos de diagnosis para
## varias variables
with(colData(rse_gene), tapply(totalAssignedGene, PrimaryDx, summary))
with(colData(rse_gene), tapply(mitoRate, PrimaryDx, summary))

## Podemos hacer lo mismo para otras variables
with(colData(rse_gene), tapply(mitoRate, BrainRegion, summary))

## Podemos resolver la primeras preguntas con iSEE
if (interactive()) iSEE::iSEE(rse_gene)

## O hacer graficas nosotros mismos. Aquí les muestro una posible respuesta
## con ggplot2
library("ggplot2")
ggplot(
    as.data.frame(colData(rse_gene)),
    aes(y = totalAssignedGene, group = PrimaryDx, x = PrimaryDx)
) +
    geom_boxplot() +
    theme_bw(base_size = 20) +
    xlab("Diagnosis")

ggplot(
    as.data.frame(colData(rse_gene)),
    aes(y = totalAssignedGene, group = paste0(PrimaryDx, "_", BrainRegion), x = paste0(PrimaryDx, "_", BrainRegion))
) +
    geom_boxplot() +
    theme_bw(base_size = 20) +
    xlab("Diagnosis")

ggplot(
    as.data.frame(colData(rse_gene)),
    aes(y = mitoRate, group = PrimaryDx, x = PrimaryDx)
) +
    geom_boxplot() +
    theme_bw(base_size = 20) +
    xlab("Diagnosis")

ggplot(
    as.data.frame(colData(rse_gene)),
    aes(y = mitoRate, group = paste0(PrimaryDx, "_", BrainRegion), x = paste0(PrimaryDx, "_", BrainRegion))
) +
    geom_boxplot() +
    theme_bw(base_size = 20) +
    xlab("Diagnosis")

## Otras variables
ggplot(
    as.data.frame(colData(rse_gene)),
    aes(y = mitoRate, group = BrainRegion, x = BrainRegion)
) +
    geom_boxplot() +
    theme_bw(base_size = 20) +
    xlab("Brain Region")

## Encontremos el gene SNAP25
rowRanges(rse_gene)
## En este objeto los nombres de los genes vienen en la variable "Symbol"
i <- which(rowRanges(rse_gene)$Symbol == "SNAP25")
i

## Para graficar con ggplot2, hagamos un pequeño data.frame
df <- data.frame(
    expression = assay(rse_gene)[i, ],
    Dx = rse_gene$PrimaryDx
)

## Ya teniendo el pequeño data.frame, podemos hacer la gráfica
ggplot(df, aes(y = log2(expression + 0.5), group = Dx, x = Dx)) +
    geom_boxplot() +
    theme_bw(base_size = 20) +
    xlab("Diagnosis") +
    ylab("SNAP25: log2(x + 0.5)")

## https://bioconductor.org/packages/release/bioc/vignettes/scater/inst/doc/overview.html#3_Visualizing_expression_values
scater::plotExpression(
    as(rse_gene, "SingleCellExperiment"),
    features = rownames(rse_gene)[i],
    x = "PrimaryDx",
    exprs_values = "counts",
    colour_by = "BrainRegion",
    xlab = "Diagnosis"
)

if (requireNamespace("plotly", quietly = TRUE)) {
    ## Lo pueden instalar con
    # install.packages("plotly")

    ## Guardemos el resultado de plotExpression()
    p <- scater::plotExpression(
        as(rse_gene, "SingleCellExperiment"),
        features = rownames(rse_gene)[i],
        x = "PrimaryDx",
        exprs_values = "counts",
        colour_by = "BrainRegion",
        xlab = "Diagnosis"
    )
    ## scater::plotExpression() regresa un objeto de clase ggplot
    class(p)

    ## así que podemos usar plotly para crear una versión
    ## interactiva
    plotly::ggplotly(p)
}

## Para el model estadístico exploremos la información de las muestras
colnames(colData(rse_gene))

## Podemos usar región del cerebro porque tenemos suficientes datos
table(rse_gene$BrainRegion)

## Pero no podemos usar "Race" porque son solo de 1 tipo
table(rse_gene$Race)

## Ojo! Acá es importante que hayamos usado droplevels(rse_gene$PrimaryDx)
## si no, vamos a tener un modelo que no sea _full rank_
mod <- with(
    colData(rse_gene),
    model.matrix(~ PrimaryDx + totalAssignedGene + mitoRate + rRNA_rate + BrainRegion + Sex + AgeDeath)
)

## Exploremos el modelo de forma interactiva
if (interactive()) {
    ## Tenemos que eliminar columnas que tienen NAs.
    info_no_NAs <- colData(rse_gene)[, c(
        "PrimaryDx", "totalAssignedGene", "rRNA_rate", "BrainRegion", "Sex",
        "AgeDeath", "mitoRate", "Race"
    )]
    ExploreModelMatrix::ExploreModelMatrix(
        info_no_NAs,
        ~ PrimaryDx + totalAssignedGene + mitoRate + rRNA_rate + BrainRegion + Sex + AgeDeath
    )

    ## Veamos un modelo más sencillo sin las variables numéricas (continuas) porque
    ## ExploreModelMatrix nos las muestra como si fueran factors (categoricas)
    ## en vez de continuas
    ExploreModelMatrix::ExploreModelMatrix(
        info_no_NAs,
        ~ PrimaryDx + BrainRegion + Sex
    )

    ## Si agregamos + Race nos da errores porque Race solo tiene 1 opción
    # ExploreModelMatrix::ExploreModelMatrix(
    #     info_no_NAs,
    #     ~ PrimaryDx + BrainRegion + Sex + Race
    # )
}

