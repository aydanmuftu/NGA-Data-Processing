library(openxlsx)


inventory = read.xlsx('Data/Sediment Trap/NGA Sediment Trap Inventory.xlsx')
deployments = read.xlsx('Data/Sediment Trap/NGA Sediment Trap Inventory.xlsx', 'deployments', startRow = 2)
lookup = read.xlsx('Data/Sediment Trap/pom analyses/Sample Placements.xlsx')

tray = list()

for (n in c('FB473', 'JT05', 'KT98', 'KT99', 'NIT5', 'NSR2')) {
  tray[[n]] = read.xlsx(paste0('Data/Sediment Trap/pom analyses/Tray ', n, '.xlsx'))
}

inventory = inventory[inventory$analysis.type == 'POM',]

sum(inventory$id %in% lookup$id)
sum(lookup$id %in% inventory$id)

lookup$id[!lookup$id %in% inventory$id]
inventory$id[!inventory$id %in% lookup$id]

lookup$tmpid = paste(lookup$cruise, lookup$deployment, lookup$tube, lookup$min, lookup$max, lookup$type, sep = '.')
lookup$tmpid = gsub('NA', '', lookup$tmpid)

lookup$id[lookup$id != lookup$tmpid]


inventory$tmpid = paste(inventory$cruise, inventory$deployment, inventory$tube.id, inventory$min.size, inventory$max.size, inventory$analysis.type, sep = '.')
inventory$tmpid = gsub('NA', '', inventory$tmpid)

inventory$id[inventory$id != inventory$tmpid]
inventory$tmpid[inventory$tmpid != inventory$id]

## First get CN data into lookup

lookup$C.ug = NA
lookup$N.ug = NA
lookup$N15 = NA
lookup$C13 = NA

for (i in 1:nrow(lookup)) {
  if (lookup$tray[i] %in% names(tray)) {
    tt = lookup$tray[i]
    k = which(lookup$well[i] == tray[[tt]]$well)
    
    if (length(k) == 1) {
      lookup$C.ug[i] = tray[[tt]]$C.ug[k] / lookup$filter.fraction[i]
      lookup$N.ug[i] = tray[[tt]]$N.ug[k] / lookup$filter.fraction[i]
      lookup$N15[i] = tray[[tt]]$delN15[k]
      lookup$C13[i] = tray[[tt]]$delC13[k]
    }
  }
}

sum(is.na(lookup$C.ug))
tmpfile = tempfile(fileext = '.xlsx')
write.xlsx(lookup, tmpfile)
browseURL(tmpfile)

## Now take those values, and add them to the inventory
inventory$POC.ug = NA
inventory$PC.ug = NA
inventory$PN.ug = NA
inventory$PN.N15 = NA
inventory$POC.C13 = NA
inventory$PC.C13 = NA
inventory$duration = NA

for (i in 1:nrow(inventory)) {
  k.pn = which(inventory$id[i] == lookup$id)
  k.poc = which(inventory$id[i] == lookup$id & lookup$acidified == 0)
  k.pc = which(inventory$id[i] == lookup$id & lookup$acidified == 1)
  
  if (length(k.pn) > 0) {
    inventory$PN.ug[i] = median(lookup$N.ug[k.pn], na.rm = T)
    inventory$PN.N15[i] = median(lookup$N15[k.pn], na.rm = T)
  }
  
  if (length(k.poc) > 0) {
    inventory$POC.ug[i] = median(lookup$C.ug[k.poc], na.rm = T)
    inventory$POC.C13[i] = median(lookup$C13[k.poc], na.rm = T)
  }
  
  if (length(k.pc) > 0) {
    inventory$PC.ug[i] = median(lookup$C.ug[k.pc], na.rm = T)
    inventory$PC.C13[i] = median(lookup$C13[k.pc], na.rm = T)
  }
  
  l = which(deployments$cruise == inventory$cruise[i] & deployments$deployment == inventory$deployment[i])
  if (length(l) > 0) {
    inventory$duration[i] = deployments$duration[l]
  }
}


inventory$PIC.ug = inventory$PC.ug - inventory$POC.ug
inventory = inventory[!is.na(inventory$POC.ug),]

inventory$POC.flux = inventory$POC.ug / inventory$duration / inventory$tube.fraction
inventory$PN.flux = inventory$PN.ug / inventory$duration / inventory$tube.fraction

summ = unique(inventory[,c('cruise', 'station', 'deployment', 'depth')])
summ$POC.flux = NA
summ$PN.flux = NA

inventory$min.size[is.na(inventory$min.size)] = 0
inventory$max.size[is.na(inventory$max.size)] = Inf

for (i in 1:nrow(summ)) {
  k = which(inventory$cruise == summ$cruise[i] & inventory$deployment == summ$deployment[i] & inventory$depth == summ$depth[i])
  
  tmp = unique(inventory[k,c('min.size', 'max.size')])
  tmp$POC.flux = NA
  tmp$PN.flux = NA
  
  for (j in 1:nrow(tmp)) {
    kk = which(inventory$cruise == summ$cruise[i] & 
                 inventory$deployment == summ$deployment[i] &
                 inventory$depth == summ$depth[i] &
                 inventory$min.size == tmp$min.size[j] &
                 inventory$max.size == tmp$max.size[j])
    tmp$POC.flux[j] = median(inventory$POC.flux[kk], na.rm = T)
    tmp$PN.flux[j] = median(inventory$PN.flux[kk], na.rm = T)
  }
  summ$POC.flux[i] = sum(tmp$POC.flux)
  summ$PN.flux[i] = sum(tmp$PN.flux)
  
}

tmpfile = tempfile(fileext = '.xlsx')
write.xlsx(inventory, tmpfile)
browseURL(tmpfile)

summ$id = paste(summ$cruise, summ$deployment, sep = '-')

plot(NULL, NULL, xlim = c(0, 3e3), ylim = c(200, 0))

for (dep in unique(summ$id)) {
  l = which(summ$id == dep)
  lines(summ$POC.flux[l], summ$depth[l])
}

tmpfile = tempfile(fileext = '.xlsx')
write.xlsx(summ, tmpfile)
browseURL(tmpfile)






flux = read.xlsx('Data/Sediment Trap/NGA Sediment Trap Chlorophylls.xlsx', startRow = 2)

chlflux = unique(flux[,c('cruise', 'station', 'deployment', 'depth')])
chlflux$Chl.flux = NA
chlflux$Phaeo.flux = NA

for (i in 1:nrow(chlflux)) {
  k = which(chlflux$cruise[i] == flux$cruise & chlflux$deployment[i] == flux$deployment & chlflux$depth[i] == flux$depth)
  chlflux$Chl.flux[i] = median(flux$Chl.Flux[k], na.rm = T)
  chlflux$Phaeo.flux[i] = median(flux$Phaeo.Flux[k], na.rm = T)
}

chl.files = list.files('Data/Chlorophyll/', '.csv', full.names = T)
tmp = read.csv(chl.files[1])
colnames(tmp) = c('Cruise', 'Station', 'Type', 'Datetime', 'Long', 'Lat', 'BotDepth',
                  'Cast', 'Depth', 'Bottle', 'SmallChl', 'LargeChl', 'Chl', 'Phaeo', 'Frac', 'Quality')
for (f in chl.files[-1]) {
  new = read.csv(f)[,c(1:16)]
  colnames(new) = colnames(tmp)
  tmp = rbind(tmp, new)
}
tmp$Chl = as.numeric(tmp$Chl)
tmp$Depth = as.numeric(tmp$Depth)
tmp = tmp[!is.na(tmp$Cruise),]
tmp = tmp[tmp$Cruise != '',]


library(TheSource)

extract = unique(tmp[,c('Cruise', 'Station')])
extract$IntChl = NA

for (i in 1:nrow(extract)) {
  k = which(extract$Cruise[i] == tmp$Cruise & extract$Station[i] == tmp$Station)
  extract$IntChl[i] = integrate.trapezoid(x = tmp$Depth[k], y = tmp$Chl[k], xlim = c(0, max(tmp$Depth[k], na.rm = T)))
}

chlflux$IntChl = NA
for (i in 1:nrow(chlflux)) {
  k = which(extract$Cruise == chlflux$cruise[i] & extract$Station == chlflux$station[i])
  if (length(k) > 0) {
    chlflux$IntChl[i] = mean(extract$IntChl[k], na.rm = T)
  } else {
    message(chlflux$cruise[i])
  }
}



tmpfile = tempfile(fileext = '.xlsx')
write.xlsx(chlflux, tmpfile)
browseURL(tmpfile)

