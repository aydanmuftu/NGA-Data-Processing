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
