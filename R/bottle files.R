library(TheSource)
library(data.table)
library(openxlsx)

load.bottle = function(bottle.file) {
  con = file(bottle.file)
  dat = readLines(con)
  close(con)
  
  bottle.file = strsplit(bottle.file, split = '/')[[1]]
  bottle.file = bottle.file[length(bottle.file)]
  
  head = dat[grepl('Bottle', dat)]
  head = strsplit(head, split = '\\s+')[[1]]
  
  dat = dat[grepl('avg', dat)] ## Only field data
  dat = strsplit(dat, '\\s+') ## Cut up
  
  bottle = data.frame(Cast = rep(as.numeric(strsplit(strsplit(bottle.file, '_')[[1]][2], '.btl')[[1]]), length(dat)))
  
  for (i in 2:length(head)) {
    bottle[[head[i]]] = NA
  }
  
  for (i in 1:length(dat)) {
    bottle[i,2] = as.numeric(dat[[i]][2])
    
    for (j in 3:length(head)) {
      bottle[i, j+1] = as.numeric(dat[[i]][j+3])
    }
  }
  
  ## Return
  bottle
}


btl.files = list.files('C:/Users/Kelly/Downloads/data/Data (preliminary)/CTD Bottles/Level 1 (btl)/2022/NGA_SKQ202207S_ctdBtl_L1.v1/', full.names = T)

bottle = load.bottle(btl.files[1])
for (i in 2:length(btl.files)) {
  bottle = rbind(bottle, load.bottle(btl.files[i]))
}
bottle$Cruise = 'SKQ202207S'


btl.files = list.files('C:/Users/Kelly/Downloads/data/Data (preliminary)/CTD Bottles/Level 1 (btl)/2022/NGA_TGX202209S_ctdBtl_L1_v1/', full.names = T)

bottle = load.bottle(btl.files[1])
for (i in 2:length(btl.files)) {
  bottle = rbind(bottle, load.bottle(btl.files[i]))
}
bottle$Cruise = 'TGX22'

