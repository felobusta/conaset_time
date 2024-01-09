totales_por_region <- read_excel("C:/Users/fnbus/OneDrive/Escritorio/conaset/conaset_fb/Informes por feriados/mayo_trabajo/totales_por_region.xlsx")

totales_por_region %>% 
  mutate(Año=as.character(Año),
         region=)->totales_por_region

totales_por_region$region[totales_por_region$region=="Region Aysen Del Grl. Carlos Ibañez Del Campo"] <- "Region de Aysen"

unique(totales_por_region$region)->regiones



for (i in c(regiones)) {
  rmarkdown::render("C:/Users/fnbus/OneDrive/Escritorio/conaset/conaset_fb/Informes por feriados/mayo_trabajo/scripts/tablas_nacional.Rmd", 
                    params = list(Mi_region = i),
                    output_file=paste0(i, ".pptx"))
}
