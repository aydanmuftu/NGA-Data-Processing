library(data.table)
library(openxlsx)


ascii.files = list.files('Data/Historic CTD/', pattern = '.ascii', full.names = T, recursive = T)

ascii = list()

for (i in 10:length(ascii.files)) {
  message('Processing file ', i, ': ', ascii.files[i])
  
  name = gsub('.ascii', '', basename(ascii.files[i]))
  tmp = readLines(ascii.files[i])
  
  header.index = which(grepl('name', tmp))
  data.index = which(!grepl('%', tmp))
  
  header = tmp[header.index]
  header.processed = rep('', length(header))
  
  for (j in 1:length(header)) {
    h = strsplit(header[j], split = '= ')[[1]][2]
    header.processed[j] = strsplit(h, split = ':')[[1]][1]
  }
  if (i == 9) {
    header.processed = c(header.processed)
  } else {
    header.processed = c('cruise', 'bottle', header.processed)
  }
  if (name == 'TXS13') {
    header.processed = header.processed[-20]
  }
  
  message('Retreived header.')
  
  dat = tmp[data.index]
  dat = strsplit(dat, '\\s+')
  if (i == 9) {
    output = data.frame(stn = c(1:length(dat)))
  } else {
    output = data.frame(cruise = c(1:length(dat)))
  }
  for (k in 1:length(header.processed)) {
    output[[header.processed[k]]] = NA
  }
  message('Initiated data frame.')
  
  for (j in 1:length(dat)) {
    if (length(dat[[j]]) == ncol(output)) {
      output[j,] = dat[[j]]
    }
  }
  
  message('Cleaning up and saving.')
  for (j in 1:ncol(output)) {
    output[,j] = as.numeric(output[,j])
  }
  
  if ('bottle' %in% colnames(output)) {
    output = output[!is.na(output$bottle),]
  }
  
  output$cruise = name
  ascii[[name]] = output
  
  write.xlsx(output, file= paste0('Data/Historic CTD/', name, ' Casts.xlsx'))
  saveRDS(output, file = paste0('Data/Historic CTD/', name, ' Casts.rds'))
  
}


btl.files = list.files('Data/Historic CTD/', pattern = '.all', full.names = T, recursive = T)

for (i in 16:length(btl.files)) {
  name = gsub('.all', '', basename(btl.files[i]))
  name = gsub('_bottles', '', name)
  raw = readLines(btl.files[i])
  raw = gsub('\xe91', '', raw, useBytes = T)
  raw = gsub('\xe90', '', raw, useBytes = T)
  l = which(grepl('(avg)', raw))
  if (length(l) > 1) {
    raw = raw[c(1, l)]
  }
  raw = gsub('(avg)', '', raw)
  tmp = fread(text = raw)
  
  tmp$cruise = name
  
  write.xlsx(tmp, file = paste0('Data/Historic CTD/', name, ' Bottle.xlsx'))
  
}


#### Combine
cast.files = list.files('Data/Historic CTD/', pattern = 'Casts.rds', full.names = T)

cast = readRDS(cast.files[1])

for (i in 2:length(cast.files)) {
  message(i)
  tmp = readRDS(cast.files[i])
  
  k = which(!colnames(tmp) %in% colnames(cast))
  if (length(k) > 0) {
    for (j in k) {
      cast[[colnames(tmp)[j]]] = NA
    }
  }
  
  k = which(!colnames(cast) %in% colnames(tmp))
  if (length(k) > 0) {
    for (j in k) {
      tmp[[colnames(cast)[j]]] = NA
    }
  }
  
  cast = rbind(cast, tmp)
}

cast$v0 = NULL
cast$v1 = NULL
cast$v2 = NULL
cast$v3 = NULL
cast$v4 = NULL
cast$v5 = NULL
cast$v6 = NULL
cast$v7 = NULL

cast$nbin = NULL
cast$xmiss = NULL
cast$CStarAt0 = NULL
cast$CStarTr0 = NULL
cast$timeJ = NULL
cast$`sbeox0ML/L` = NULL
cast$`sbeox0Mm/Kg` = NULL
cast$`sbeox1Mm/Kg` = NULL
cast$`sbox0Mm/Kg` = NULL
cast$`sbox1Mm/Kg` = NULL
cast$upoly0 = NULL
cast$upoly1 = NULL
cast$gsw_sigma0A0 = NULL
cast$gsw_sigma0A1 = NULL
cast$gsw_saA0 = NULL
cast$gsw_saA1 = NULL
cast$sal00 = NULL
cast$sal11 = NULL
cast$`flECO-AFL` = NULL
cast$flSP = NULL
cast$par = NULL
cast$altM = NULL
cast$`sigma-t00` = NULL
cast$`sigma-t11` = NULL
cast$depSM = NULL

cast = data.frame(cruise = cast$cruise,
                  cast = cast$bottle,
                  longitude = cast$longitude,
                  latitude = cast$latitude,
                  stn = cast$stn,
                  pressure = cast$prDM,
                  #depth = NA,
                  temperature1 = cast$t090C,
                  temperature2 = cast$t190C,
                  conductivity1 = cast$`c0S/m`,
                  conductivity2 = cast$`c1S/m`
                  )

library(TheSource)
cast$salinity1 = conv.cond.to.sal(cast$conductivity1*1e4, cast$temperature1)
cast$salinity2 = conv.cond.to.sal(cast$conductivity2*1e4, cast$temperature2)
cast$conductivity1 = NULL
cast$conductivity2 = NULL


saveRDS(cast, 'Data/Historic CTD/Cast Compilation.rds')
write.xlsx(cast, 'Data/Historic CTD/Cast Compilation.xlsx')
