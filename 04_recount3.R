## ----'start', message=FALSE-----------
## Load recount3 R package
library("recount3")


## ----'quick_example'------------------
## Cambiaremos el URL de recount3 a Amazon (AWS)
## para evitar problems de TLS versión 1.2 en
## Windows (luego tiene una versión más vieja).

## Primero vemos el URL actual
getOption(
    "recount3_url",
    "http://duffel.rail.bio/recount3"
)

## Ahora si lo cambiamos
options(recount3_url = "https://recount-opendata.s3.amazonaws.com/recount3/release")

## Y vemos que ya funcionó el cambio.
getOption(
    "recount3_url",
    "http://duffel.rail.bio/recount3"
)

## Revisemos todos los proyectos con datos de humano en recount3
human_projects <- available_projects()

## Encuentra tu proyecto de interés. Aquí usaremos
## SRP009615 de ejemplo
proj_info <- subset(
    human_projects,
    project == "SRP009615" & project_type == "data_sources"
)
## Crea un objeto de tipo RangedSummarizedExperiment (RSE)
## con la información a nivel de genes
rse_gene_SRP009615 <- create_rse(proj_info)
## Explora el objeto RSE
rse_gene_SRP009615


## ----"interactive_display", eval = FALSE----
## ## Explora los proyectos disponibles de forma interactiva
## proj_info_interactive <- interactiveDisplayBase::display(human_projects)
## ## Selecciona un solo renglón en la tabla y da click en "send".
## 
## ## Aquí verificamos que solo seleccionaste un solo renglón.
## stopifnot(nrow(proj_info_interactive) == 1)
## ## Crea el objeto RSE
## rse_gene_interactive <- create_rse(proj_info_interactive)


## ----"tranform_counts"----------------
## Convirtamos las cuentas por nucleotido a cuentas por lectura
## usando compute_read_counts().
## Para otras transformaciones como RPKM y TPM, revisa transform_counts().
assay(rse_gene_SRP009615, "counts") <- compute_read_counts(rse_gene_SRP009615)


## ----"expand_attributes"--------------
## Para este estudio en específico, hagamos más fácil de usar la
## información del experimento
rse_gene_SRP009615 <- expand_sra_attributes(rse_gene_SRP009615)
colData(rse_gene_SRP009615)[
    ,
    grepl("^sra_attribute", colnames(colData(rse_gene_SRP009615)))
]

