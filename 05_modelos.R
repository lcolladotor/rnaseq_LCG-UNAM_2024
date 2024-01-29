## ----model.matrix-----------------------------------------------------------------------------------------------------
## ?model.matrix
mat <- with(trees, model.matrix(log(Volume) ~ log(Height) + log(Girth)))
mat
colnames(mat)


## ----lm_example-------------------------------------------------------------------------------------------------------
summary(lm(log(Volume) ~ log(Height) + log(Girth), data = trees))


## ----EMM_example1-----------------------------------------------------------------------------------------------------
## Datos de ejemplo
(sampleData <- data.frame(
    genotype = rep(c("A", "B"), each = 4),
    treatment = rep(c("ctrl", "trt"), 4)
))

## Creemos las imágenes usando ExploreModelMatrix
vd <- ExploreModelMatrix::VisualizeDesign(
    sampleData = sampleData,
    designFormula = ~ genotype + treatment,
    textSizeFitted = 4
)

## Veamos las imágenes
cowplot::plot_grid(plotlist = vd$plotlist)


## ----EMM_example1_interactive, eval = FALSE---------------------------------------------------------------------------
## ## Usaremos shiny otra ves
## app <- ExploreModelMatrix(
##     sampleData = sampleData,
##     designFormula = ~ genotype + treatment
## )
## if (interactive()) shiny::runApp(app)


## ----download_SRP045638-----------------------------------------------------------------------------------------------
library("recount3")

options(recount3_url = "https://recount-opendata.s3.amazonaws.com/recount3/release")

human_projects <- available_projects()

rse_gene_SRP045638 <- create_rse(
    subset(
        human_projects,
        project == "SRP045638" & project_type == "data_sources"
    )
)
assay(rse_gene_SRP045638, "counts") <- compute_read_counts(rse_gene_SRP045638)


## ----describe_issue---------------------------------------------------------------------------------------------------
rse_gene_SRP045638$sra.sample_attributes[1:3]


## ----solve_issue------------------------------------------------------------------------------------------------------
rse_gene_SRP045638$sra.sample_attributes <- gsub("dev_stage;;Fetal\\|", "", rse_gene_SRP045638$sra.sample_attributes)
rse_gene_SRP045638$sra.sample_attributes[1:3]


## ----attributes-------------------------------------------------------------------------------------------------------
rse_gene_SRP045638 <- expand_sra_attributes(rse_gene_SRP045638)

colData(rse_gene_SRP045638)[
    ,
    grepl("^sra_attribute", colnames(colData(rse_gene_SRP045638)))
]


## ----re_cast----------------------------------------------------------------------------------------------------------
## Pasar de character a numeric o factor
rse_gene_SRP045638$sra_attribute.age <- as.numeric(rse_gene_SRP045638$sra_attribute.age)
rse_gene_SRP045638$sra_attribute.disease <- factor(tolower(rse_gene_SRP045638$sra_attribute.disease))
rse_gene_SRP045638$sra_attribute.RIN <- as.numeric(rse_gene_SRP045638$sra_attribute.RIN)
rse_gene_SRP045638$sra_attribute.sex <- factor(rse_gene_SRP045638$sra_attribute.sex)

## Resumen de las variables de interés
summary(as.data.frame(colData(rse_gene_SRP045638)[
    ,
    grepl("^sra_attribute.[age|disease|RIN|sex]", colnames(colData(rse_gene_SRP045638)))
]))


## ----new_variables----------------------------------------------------------------------------------------------------
## Encontraremos diferencias entre muestra prenatalas vs postnatales
rse_gene_SRP045638$prenatal <- factor(ifelse(rse_gene_SRP045638$sra_attribute.age < 0, "prenatal", "postnatal"))
table(rse_gene_SRP045638$prenatal)

## http://rna.recount.bio/docs/quality-check-fields.html
rse_gene_SRP045638$assigned_gene_prop <- rse_gene_SRP045638$recount_qc.gene_fc_count_all.assigned / rse_gene_SRP045638$recount_qc.gene_fc_count_all.total
summary(rse_gene_SRP045638$assigned_gene_prop)
with(colData(rse_gene_SRP045638), plot(assigned_gene_prop, sra_attribute.RIN))

## Hm... veamos si hay una diferencia entre los grupos
with(colData(rse_gene_SRP045638), tapply(assigned_gene_prop, prenatal, summary))


## ----filter_rse-------------------------------------------------------------------------------------------------------
## Guardemos nuestro objeto entero por si luego cambiamos de opinión
rse_gene_SRP045638_unfiltered <- rse_gene_SRP045638

## Eliminemos a muestras malas
hist(rse_gene_SRP045638$assigned_gene_prop)
table(rse_gene_SRP045638$assigned_gene_prop < 0.3)
rse_gene_SRP045638 <- rse_gene_SRP045638[, rse_gene_SRP045638$assigned_gene_prop > 0.3]

## Calculemos los niveles medios de expresión de los genes en nuestras
## muestras.
## Ojo: en un análisis real probablemente haríamos esto con los RPKMs o CPMs
## en vez de las cuentas.
## En realidad usariamos:
# edgeR::filterByExpr() https://bioconductor.org/packages/edgeR/ https://rdrr.io/bioc/edgeR/man/filterByExpr.html
# genefilter::genefilter() https://bioconductor.org/packages/genefilter/ https://rdrr.io/bioc/genefilter/man/genefilter.html
# jaffelab::expression_cutoff() http://research.libd.org/jaffelab/reference/expression_cutoff.html
#
gene_means <- rowMeans(assay(rse_gene_SRP045638, "counts"))
summary(gene_means)

## Eliminamos genes
rse_gene_SRP045638 <- rse_gene_SRP045638[gene_means > 0.1, ]

## Dimensiones finales
dim(rse_gene_SRP045638)

## Porcentaje de genes que retuvimos
round(nrow(rse_gene_SRP045638) / nrow(rse_gene_SRP045638_unfiltered) * 100, 2)


## ----normalize--------------------------------------------------------------------------------------------------------
library("edgeR") # BiocManager::install("edgeR", update = FALSE)
dge <- DGEList(
    counts = assay(rse_gene_SRP045638, "counts"),
    genes = rowData(rse_gene_SRP045638)
)
dge <- calcNormFactors(dge)


## ----explore_gene_prop_by_age-----------------------------------------------------------------------------------------
library("ggplot2")
ggplot(as.data.frame(colData(rse_gene_SRP045638)), aes(y = assigned_gene_prop, x = prenatal)) +
    geom_boxplot() +
    theme_bw(base_size = 20) +
    ylab("Assigned Gene Prop") +
    xlab("Age Group")


## ----statiscal_model--------------------------------------------------------------------------------------------------
mod <- model.matrix(~ prenatal + sra_attribute.RIN + sra_attribute.sex + assigned_gene_prop,
    data = colData(rse_gene_SRP045638)
)
colnames(mod)


## ----run_limma--------------------------------------------------------------------------------------------------------
library("limma")
vGene <- voom(dge, mod, plot = TRUE)

eb_results <- eBayes(lmFit(vGene))

de_results <- topTable(
    eb_results,
    coef = 2,
    number = nrow(rse_gene_SRP045638),
    sort.by = "none"
)
dim(de_results)
head(de_results)

## Genes diferencialmente expresados entre pre y post natal con FDR < 5%
table(de_results$adj.P.Val < 0.05)

## Visualicemos los resultados estadísticos
plotMA(eb_results, coef = 2)

volcanoplot(eb_results, coef = 2, highlight = 3, names = de_results$gene_name)
de_results[de_results$gene_name %in% c("ZSCAN2", "VASH2", "KIAA0922"), ]


## ----pheatmap---------------------------------------------------------------------------------------------------------
## Extraer valores de los genes de interés
exprs_heatmap <- vGene$E[rank(de_results$adj.P.Val) <= 50, ]

## Creemos una tabla con información de las muestras
## y con nombres de columnas más amigables
df <- as.data.frame(colData(rse_gene_SRP045638)[, c("prenatal", "sra_attribute.RIN", "sra_attribute.sex")])
colnames(df) <- c("AgeGroup", "RIN", "Sex")

## Hagamos un heatmap
library("pheatmap")
pheatmap(
    exprs_heatmap,
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    show_rownames = FALSE,
    show_colnames = FALSE,
    annotation_col = df
)


## ----plot_mds---------------------------------------------------------------------------------------------------------
## Para colores
library("RColorBrewer")

## Conviertiendo los grupos de edad a colores
col.group <- df$AgeGroup
levels(col.group) <- brewer.pal(nlevels(col.group), "Set1")
col.group <- as.character(col.group)

## MDS por grupos de edad
plotMDS(vGene$E, labels = df$AgeGroup, col = col.group)

## Conviertiendo los valores de Sex a colores
col.sex <- df$Sex
levels(col.sex) <- brewer.pal(nlevels(col.sex), "Dark2")
col.sex <- as.character(col.sex)

## MDS por sexo
plotMDS(vGene$E, labels = df$Sex, col = col.sex)


## ----respuesta, out.height="1100px"-----------------------------------------------------------------------------------
## Tenemos que usar gene_id y gene_name
rowRanges(rse_gene_SRP045638)

## Alternativamente, podriamos haber usado de_results
head(de_results, n = 3)

## Es la misma información
identical(rowRanges(rse_gene_SRP045638)$gene_id, de_results$gene_id)
identical(rowRanges(rse_gene_SRP045638)$gene_name, de_results$gene_name)

## Guardemos los IDs de nuestros 50 genes
nombres_originales <- rownames(exprs_heatmap)

## Con match() podemos encontrar cual es cual
rownames(exprs_heatmap) <- rowRanges(rse_gene_SRP045638)$gene_name[
    match(rownames(exprs_heatmap), rowRanges(rse_gene_SRP045638)$gene_id)
]

## Vean que tambien podriamos haber usado rank()
identical(
    which(rank(de_results$adj.P.Val) <= 50),
    match(nombres_originales, rowRanges(rse_gene_SRP045638)$gene_id)
)

## Esta es otra solución
identical(
    de_results$gene_name[rank(de_results$adj.P.Val) <= 50],
    rownames(exprs_heatmap)
)

## Por último podemos cambiar el valor de show_rownames de FALSE a TRUE
pheatmap(
    exprs_heatmap,
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    show_rownames = TRUE,
    show_colnames = FALSE,
    annotation_col = df
)

## Guardar la imagen en un PDF largo para poder ver los nombres de los genes
pdf("pheatmap_con_nombres.pdf", height = 14, useDingbats = FALSE)
pheatmap(
    exprs_heatmap,
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    show_rownames = TRUE,
    show_colnames = FALSE,
    annotation_col = df
)
dev.off()


## ----"centered_and_scaled", out.height="1100px"-----------------------------------------------------------------------
## Versión con centering y scaling en los renglones (los genes)
pheatmap::pheatmap(
    exprs_heatmap,
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    show_rownames = TRUE,
    show_colnames = FALSE,
    annotation_col = df,
    scale = "row"
)


## ----"complexheatmap", out.height="1100px"----------------------------------------------------------------------------
## Misma versión pero ahora con ComplexHeatmap en vez del paquete pheatmap
ComplexHeatmap::pheatmap(
    exprs_heatmap,
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    show_rownames = TRUE,
    show_colnames = FALSE,
    annotation_col = df,
    scale = "row"
)

