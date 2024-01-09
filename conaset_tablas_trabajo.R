library(readxl)
library(dplyr)
library(stringr)
library(DescTools)

#siniestros <- read_excel("C:/Users/fnbus/OneDrive/Escritorio/conaset/Informes por feriados/Base 2012-2021 Prueba Técnica 2023.xlsx", 
#                         sheet = 1)
#
siniestros <- read_excel("C:/Users/fnbus/OneDrive/Escritorio/conaset/Informes por feriados/Base 2012-2021 Prueba Técnica 2023.xlsx", 
                         sheet = 1)

siniestros_2022 <- read_excel("2023/Dia del Trabajador 2022.xlsx",
                              sheet=1)

siniestros %>% select(Año,Fecha,Región,`Tipo (CONASET)`,`Tipo Accidente`,Fallecidos,Leves,Graves,`Menos Graves`,`Causa (CONASET)`,`Causa Accidente`)->siniestros
siniestros_2022  %>% select(Año,Fecha,Región,`Tipo (CONASET)`,`Tipo Accidente`,Fallecidos,Leves,Graves,`Menos Graves`,`Causa (CONASET)`,Causa)->siniestros_2022


colnames(siniestros)[11]=colnames(siniestros_2022)[11]

colnames(siniestros)==colnames(siniestros_2022)

rbind(siniestros,siniestros_2022)->siniestros_final

siniestros_final$date <- as.Date(siniestros_final$Fecha)

siniestros_final$region <- factor(stringr::str_to_title(siniestros_final$Región),levels = c("Region Arica Y Parinacota",
                                                                       "Region Tarapaca",
                                                                       "Region Antofagasta",
                                                                       "Region Atacama",
                                                                       "Region Coquimbo",
                                                                       "Region Valparaiso",
                                                                       "Region Metropolitana",
                                                                       "Region Lib.b.o'higgins",
                                                                       "Region Maule",
                                                                       "Region Ñuble",
                                                                       "Region Bio Bio",
                                                                       "Region Araucania",
                                                                       "Region De Los Rios",
                                                                       "Region Los Lagos",
                                                                       "Region Aysen Del Grl. Carlos Ibañez Del Campo",
                                                                       "Region Magallanes Y Antartica Chilena")) 

# create a vector of date ranges
date_ranges <- list(c("2019-04-30", "2019-05-01"),
                    c("2020-04-30", "2020-05-03"),
                    c("2021-04-30", "2021-05-02"),
                    c("2022-04-29", "2022-05-01"))



# convert the date ranges to Date objects
date_ranges <- lapply(date_ranges, function(x) as.Date(x))

# create a function to filter the data by multiple date ranges
filter_by_date <- function(data, date_ranges) {
  data[data$date %in% unlist(lapply(date_ranges, function(x) seq(x[1], x[2], by = "day"))), ]
}

# example usage: filter data by all date ranges
siniestros_final <- filter_by_date(siniestros_final, date_ranges)

siniestros_final %>% writexl::write_xlsx("Dia del Trabajador_2023.xlsx")

siniestros_final%>% 
  group_by(Año) %>% 
  summarise(Total=n(),
            Fa=sum(Fallecidos),
            Gr=sum(Graves),
            MG=sum(`Menos Graves`),
            L=sum(Leves),
            dias = paste(as.numeric(max(date)-min(date)+1),"días"),
            Desde = min(date),
            Hasta = max(date))%>% 
  mutate(Total_lesionados=Gr+MG+L,
         Desde_2 =  paste(DescTools::StrCap(weekdays(Desde)),format(Desde, "%d/%m"),sep=" "),
         Hasta_2 =  paste(DescTools::StrCap(weekdays(Hasta)),format(Hasta, "%d/%m"),sep=" ")) %>% 
  select(Año,Desde=Desde_2,Hasta=Hasta_2,`N° días`=dias,Siniestros=Total,
         Fallecidos=Fa,Graves=Gr,`Menos Graves`=MG,Leves=L,`Total Lesionados`=Total_lesionados) ->tabla_totales_anuales;tabla_totales_anuales




siniestros_final %>% 
  group_by(Año,region) %>% 
  summarise(Total=n()) %>% 
  ungroup() %>% 
  tidyr::pivot_wider(names_from = Año,
                     values_from = c(Total))->siniestros_x_region;siniestros_x_region

siniestros_final %>% 
  group_by(Año,region) %>% 
  summarise(Fallecidos=sum(Fallecidos)) %>% 
  ungroup() %>% 
  tidyr::pivot_wider(names_from = Año,
                     values_from = c(Fallecidos))->Fallecidos_x_region;Fallecidos_x_region



siniestros_final %>% 
  group_by(Año,region) %>% 
  summarise(lesionados=sum(Graves,`Menos Graves`,Leves)) %>% 
  ungroup() %>% 
  tidyr::pivot_wider(names_from = Año,
                     values_from = c(lesionados))->lesionados_x_region;lesionados_x_region


tabla_totales_anuales %>% View()
siniestros_x_region
Fallecidos_x_region
lesionados_x_region


ano_previo<- date_ranges[length(date_ranges)]


previo <- filter_by_date(siniestros_final, date_ranges[2])



# Load the openxlsx package
library(openxlsx)

# Create a list of dataframes
df_list <- list(tabla_totales_anuales,
                siniestros_x_region,
                Fallecidos_x_region,
                lesionados_x_region)

# Set the filename prefix
filename_prefix <- "dataframe_"

# Iterate through the list of dataframes and write each one to an Excel file
for (i in seq_along(df_list)) {
  filename <- paste0(filename_prefix, i, ".xlsx")
  write.xlsx(df_list[[i]], filename)
}

library(dplyr)

previo %>% 
  #filter(Fallecidos!=0) %>% 
  mutate(`Causa (CONASET)` = 
           case_when(`Causa (CONASET)`=="PERDIDA CONTROL VEHICULO"~"VELOCIDAD IMPRUDENTE",
                     T~as.character(`Causa (CONASET)`))) %>% 
  group_by(`Causa (CONASET)`=DescTools::StrCap(tolower(`Causa (CONASET)`))) %>% 
  summarise(`2020` = sum(Fallecidos)) %>% 
  filter(`2020` !=0)->fallecidos_causa_2020;fallecidos_causa_2020

previo %>% 
  mutate(`Causa (CONASET)` = case_when(
    `Causa (CONASET)`=="PERDIDA CONTROL VEHICULO"~"VELOCIDAD IMPRUDENTE",
    T~as.character(`Causa (CONASET)`))) %>% 
  group_by(`Causa (CONASET)`=DescTools::StrCap(tolower(`Causa (CONASET)`)))  %>% 
  summarise(Gr=sum(Graves),
            MG=sum(`Menos Graves`),
            L=sum(Leves))%>% 
  mutate(Total_lesionados=Gr+MG+L) %>% 
  select(`Causa (CONASET)`,Total_lesionados)->lesionados_causa_2020;lesionados_causa_2020


#previo %>% 
#  #filter(Fallecidos!=0) %>% 
#  mutate(`Tipo Accidente`= case_when(grepl("CHOQUE",`Tipo Accidente`) ~"CHOQUE",
#                                     grepl("COLISION", `Tipo Accidente`)~"COLISION",
#                                     T~as.character(`Tipo Accidente`))) %>% 
#  group_by(`Tipo Accidente`=DescTools::StrCap(tolower(`Tipo Accidente`))) %>% 
#  summarise( `2022`= sum(Fallecidos)) %>% 
#  filter(`2022`!=0)

previo %>% 
  mutate(Total_lesionados=Graves+`Menos Graves`+Leves) %>% 
  group_by(`Tipo (CONASET)`=DescTools::StrCap(tolower(`Tipo (CONASET)`))) %>% 
  summarise( `2020`= sum(Fallecidos)) %>% 
  filter(`2020`!=0) -> fallecidos_tipo_2020; fallecidos_tipo_2020

previo %>% 
  mutate(Total_lesionados=Graves+`Menos Graves`+Leves) %>% 
  group_by(`Tipo (CONASET)`=DescTools::StrCap(tolower(`Tipo (CONASET)`))) %>% 
  summarise(Lesionados=sum(Total_lesionados)) -> lesionados_tipo_2020; lesionados_tipo_2020

fallecidos_causa_2020
lesionados_causa_2020
fallecidos_tipo_2020
lesionados_tipo_2020

#siniestros_final %>% 
#  mutate(Total_lesionados=Graves+`Menos Graves`+Leves) %>% 
#  group_by(`Tipo (CONASET)`) %>% 
#  summarise(sum(Total_lesionados))

###personas


personas_p1 <- read_excel("C:/Users/fnbus/OneDrive/Escritorio/conaset/Informes por feriados/Base 2012-2021 Prueba Técnica 2023.xlsx", 
                          sheet = 2)

personas_p2 <- read_excel("C:/Users/fnbus/OneDrive/Escritorio/conaset/Informes por feriados/Base 2012-2021 Prueba Técnica 2023.xlsx", 
                          sheet = 3)


#check names
colnames(personas_p1)    == colnames(personas_p2)
colnames(personas_p1)[3]  = colnames(personas_p2)[3]
colnames(personas_p1)[18] = colnames(personas_p2)[18]
colnames(personas_p1)[19] = colnames(personas_p2)[19]
colnames(personas_p1)[20] = colnames(personas_p2)[20]
colnames(personas_p1)[22] = colnames(personas_p2)[22]
colnames(personas_p1)[21] = colnames(personas_p2)[21]

colnames(personas_p1)    == colnames(personas_p2)

bind_rows(personas_p1,
          personas_p2)->mydf

mydf %>% 
  filter(Año==2021) %>% 
  group_by(Tipo) %>% 
  count(Tipo)
mydf$date <- as.Date(mydf$Fecha)

mydf %>% 
  mutate(sum_lesionados = Graves+`Menos Graves`+Leves,
         `Grupo edad`=case_when(
           Edad >= 0 & Edad <= 14 ~"0 a 14 años",
           Edad >= 15 & Edad <= 29 ~"15 a 29 años",
           Edad >= 30 & Edad <= 44 ~"30 a 44 años",
           Edad >= 45 & Edad <= 59 ~"45 a 59 años",
           Edad >= 60 & Edad < 200 ~"60 años y más",
           Edad > 200 ~"No se informa",
           T ~ as.character(Edad))
  )->mydf 

mydf_filtered <- filter_by_date(mydf , date_ranges[2])
mydf_filtered %>% writexl::write_xlsx("personas_2020.xlsx")

personas_2022 <- read_excel("2023/Dia del Trabajador 2022.xlsx",
                              sheet=2)

mydf_filtered %>% 
  mutate(`Grupo edad`=case_when(
    Edad >= 0 & Edad <= 14 ~"0 a 14 años",
    Edad >= 15 & Edad <= 29 ~"15 a 29 años",
    Edad >= 30 & Edad <= 44 ~"30 a 44 años",
    Edad >= 45 & Edad <= 59 ~"45 a 59 años",
    Edad >= 60 & Edad < 200 ~"60 años y más",
    Edad > 200 ~"No se informa",
    T ~ as.character(Edad))) %>% 
  group_by(`Grupo edad`) %>% 
  summarise(`2020` = sum(Fallecidos)) %>% 
  na.omit()->fallecidos_x_edad_2020;fallecidos_x_edad_2020



mydf_filtered%>% 
  mutate(`Grupo edad`=case_when(
    Edad >= 0 & Edad <= 14 ~"0 a 14 años",
    Edad >= 15 & Edad <= 29 ~"15 a 29 años",
    Edad >= 30 & Edad <= 44 ~"30 a 44 años",
    Edad >= 45 & Edad <= 59 ~"45 a 59 años",
    Edad >= 60 & Edad < 200 ~"60 años y más",
    Edad > 200 ~"No se informa",
    T ~ as.character(Edad))) %>% 
  mutate(sum_lesionados = Graves+`Menos Graves`+Leves) %>% 
  group_by(`Grupo edad`) %>% 
  summarise(Lesionados = sum(sum_lesionados)) %>% 
  na.omit()->lesionados_x_edad_2020;lesionados_x_edad_2020

mydf_filtered %>% 
  #filter(Fallecidos!=0) %>% 
  group_by(Calidad = DescTools::StrCap(tolower(Calidad))) %>% 
  summarise(`2020`= sum(Fallecidos)) %>% 
  na.omit()-> fallecidos_calidad_2020;fallecidos_calidad_2020

mydf_filtered  %>% 
  mutate(sum_lesionados = Graves+`Menos Graves`+Leves) %>% 
  group_by(Calidad = DescTools::StrCap(tolower(Calidad))) %>% 
  summarise(Lesionados = sum(sum_lesionados)) %>% 
  na.omit()-> lesionados_calidad_2020;lesionados_calidad_2020

library(dplyr)
mydf_filtered  %>% 
  filter(Calidad == "CONDUCTOR") %>% 
  group_by(`conductor según tipo de veh` = DescTools::StrCap(tolower(Tipo))) %>% 
  summarise(`2020`=sum(Fallecidos)) %>% 
  filter(`2020`!=0)->fallecidos_conductor_2020;fallecidos_conductor_2020

mydf_filtered  %>% 
  filter(Calidad == "CONDUCTOR") %>% 
  mutate(sum_lesionados = Graves+`Menos Graves`+Leves,
         Tipo = case_when(grepl("CAMION S",Tipo)~"CAMION",
                          T~as.character(Tipo))) %>% 
  group_by(`conductor según tipo de veh` = DescTools::StrCap(tolower(Tipo))) %>% 
  summarise(Lesionados = sum(sum_lesionados)) %>% 
  filter(Lesionados!=0)-> lesionados_conductor_2020;lesionados_conductor_2020
lesionados_conductor_2020 %>% 
  summarise(sum(Lesionados))


fallecidos_causa_2020<-fallecidos_causa_2020     %>% arrange(desc(`2020`))
lesionados_causa_2020<-lesionados_causa_2020     %>% arrange(desc(Total_lesionados))
fallecidos_tipo_2020<-fallecidos_tipo_2020      %>% arrange(desc(`2020`))
lesionados_tipo_2020<-lesionados_tipo_2020      %>% arrange(desc(Lesionados))
fallecidos_x_edad_2020<-fallecidos_x_edad_2020    %>% arrange(desc(`2020`))
lesionados_x_edad_2020<-lesionados_x_edad_2020    %>% arrange(desc(Lesionados))
fallecidos_calidad_2020<-fallecidos_calidad_2020   %>% arrange(desc(`2020`))
lesionados_calidad_2020<-lesionados_calidad_2020   %>% arrange(desc(Lesionados))
fallecidos_conductor_2020<-fallecidos_conductor_2020 %>% arrange(desc(`2020`))
lesionados_conductor_2020<-lesionados_conductor_2020 %>% arrange(desc(Lesionados))

# Define a list of data frames
my_dfs <- list(
  fallecidos_causa_2020=fallecidos_causa_2020,
    lesionados_causa_2020=lesionados_causa_2020,
    fallecidos_tipo_2020=fallecidos_tipo_2020,
    lesionados_tipo_2020=lesionados_tipo_2020,
    fallecidos_x_edad_2020=fallecidos_x_edad_2020,
    lesionados_x_edad_2020=lesionados_x_edad_2020,
    fallecidos_calidad_2020=fallecidos_calidad_2020,
    lesionados_calidad_2020=lesionados_calidad_2020,
    lesionados_conductor_2020=lesionados_conductor_2020,
  fallecidos_conductor_2020=fallecidos_conductor_2020
)

fallecidos_causa_2020

previo %>%  
  #filter(Fallecidos!=0) %>% 
  mutate(`Causa (CONASET)` = 
           case_when(`Causa (CONASET)`=="PERDIDA CONTROL VEHICULO"~"VELOCIDAD IMPRUDENTE",
                     T~as.character(`Causa (CONASET)`))) %>% 
  group_by(region,`Causa (CONASET)`=DescTools::StrCap(tolower(`Causa (CONASET)`))) %>% 
  summarise(`2020` = sum(Fallecidos)) %>% 
  filter(`2020` !=0)->fallecidos_causa_x_region_2020;fallecidos_causa_x_region_2020

previo %>% 
  mutate(Total_lesionados=Graves+`Menos Graves`+Leves) %>% 
  group_by(region,`Tipo (CONASET)`=DescTools::StrCap(tolower(`Tipo (CONASET)`))) %>% 
  summarise( `2020`= sum(Fallecidos)) %>% 
  filter(`2020`!=0) -> fallecidos_tipo_x_region_2020; fallecidos_tipo_x_region_2020


library(openxlsx)

# Create a new workbook
wb <- createWorkbook()

# Add each data frame to a new sheet in the workbook
for (name in names(my_dfs)) {
  addWorksheet(wb, sheetName = name)
  writeData(wb, sheet = name, x = my_dfs[[name]])
}

# Save the workbook to a file
saveWorkbook(wb, "my_dataframes.xlsx", overwrite = TRUE)




############ tablas regionales ##############

#####totales regionales#########
library(desc)
siniestros_final %>% 
  group_by(Año,region) %>% 
  summarise(Total=n(),
            Fa=sum(Fallecidos),
            Gr=sum(Graves),
            MG=sum(`Menos Graves`),
            L=sum(Leves),
            dias = paste(as.numeric(max(date)-min(date)+1),"días"),
            Desde = min(date),
            Hasta = max(date))%>% 
  ungroup() %>% 
  mutate(Total_lesionados=Gr+MG+L,
         Desde_2 =  paste(DescTools::StrCap(weekdays(Desde)),format(Desde, "%d/%m"),sep=" "),
         Hasta_2 =  paste(DescTools::StrCap(weekdays(Hasta)),format(Hasta, "%d/%m"),sep=" ")) %>%
  select(region,Año,Desde_2,Hasta_2,dias,Siniestros=Total,
         Fallecidos=Fa,Graves=Gr,`Menos Graves`=MG,Leves=L,
         `Total Lesionados`=Total_lesionados) %>% 
  arrange(region)->totales_por_region

totales_por_region %>% 
  ungroup() %>% 
  mutate(Desde_2 = case_when(Desde_2 != "Martes 30/04" & Año    == 2019 ~ "Martes 30/04",#2019
                             Desde_2 != "Jueves 30/04" & Año  == 2020 ~ "Jueves 30/04",#2020
                             Desde_2 != "Viernes 30/04" & Año  == 2021 ~ "Viernes 30/04",#2021
                             Desde_2 != "Viernes 29/04" & Año  == 2022 ~ "Viernes 29/04",#2022
                             T~as.character(Desde_2)),
         Hasta_2= case_when(Hasta_2 != "Miércoles 01/05" & Año == 2019 ~ "Miércoles 01/05", #2019
           Hasta_2 != "Domingo 03/05" & Año == 2020 ~ "Domingo 03/05", #2020
           Hasta_2 != "Domingo 02/05" & Año == 2021 ~ "Domingo 02/05", #2021
           Hasta_2 != "Domingo 01/05" & Año == 2022 ~ "Domingo 01/05", #2022
           T~as.character(Hasta_2)))->totales_por_region;totales_por_region

writexl::write_xlsx(totales_por_region,"totales_por_region.xlsx")

totales_por_region 
