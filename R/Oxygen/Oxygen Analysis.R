library(openxlsx)
library(TheSource)

## Load in datasets
o2 = read.xlsx('Data/Oxygen/NGA Oxygen Titration Log 20230929.xlsx', sheet = 2, startRow = 2)
o2 = o2[o2$Flag == 1,]

## Downcast to Winkler comparison
downcast = list()
downcast$SKQ202106S = readRDS(file = 'Data/CTD Downcast/SKQ202106S.rds')
downcast$SKQ202110S = readRDS(file = 'Data/CTD Downcast/SKQ202110S.rds')
downcast$TGX202109 = readRDS(file = 'Data/CTD Downcast/TGX202109S.rds')
downcast$SKQ202207S = readRDS(file = 'Data/CTD Downcast/SKQ202207S.rds')
downcast$SKQ202210S = readRDS(file = 'Data/CTD Downcast/SKQ202210S.rds')
downcast$TGX202209S = readRDS(file = 'Data/CTD Downcast/SKQ202209S.rds')

o2$downcast1 = NA
o2$downcast2 = NA


for (i in 1:nrow(o2)) {
  if (o2$Cruise[i] %in% names(downcast) & !is.na(o2$Cast[i])) {
    cast = pad.number(o2$Cast[i], pad = 3)
    l = which(grepl(cast, names(downcast[[o2$Cruise[i]]])))
    
    if (length(l) > 0) {
      l = l[1]
      o2$downcast1[i] = approx(downcast[[o2$Cruise[i]]][[l]]$pressure, downcast[[o2$Cruise[i]]][[l]]$oxygen, xout = o2$Depth[i])$y
      o2$downcast2[i] = approx(downcast[[o2$Cruise[i]]][[l]]$pressure, downcast[[o2$Cruise[i]]][[l]]$oxygen2, xout = o2$Depth[i])$y
    }
  }
}

#tf = tempfile(fileext = '.xlsx')
#write.xlsx(o2, tf)
#browseURL(tf)

plot(o2$Oxygen, o2$downcast1, pch = 16, xlab = 'Discrete Oxygen Concentration', ylab = 'Primary Oxygen Sensor')
abline(a = 0, b = 1, col = 'darkgrey', lwd = 2)
grid(); box()
lm(o2$Oxygen ~ o2$downcast1)

plot(o2$Oxygen, o2$downcast2, pch = 16, xlab = 'Discrete Oxygen Concentration', ylab = 'Secondary Oxygen Sensor')
abline(a = 0, b = 1)
grid(); box()
lm(o2$Oxygen ~ o2$downcast2)



rmarkdown::render(input = 'R/Oxygen/Oxygen Analysis Report.Rmd', output_dir = 'pub/', envir = globalenv())
