library(openxlsx)
library(TheSource)
library(SimpleMapper)

station = read.xlsx('Data/NGA stations.xlsx')
station$station = toupper(station$station)

log = read.xlsx('Data/Sediment Trap/NGA Sediment Trap Inventory.xlsx', startRow = 2, sheet = 3)
log$deployment.time = conv.time.excel(log$deployment.time)
log$recovery.time = conv.time.excel(log$recovery.time)
log$station = toupper(log$station)

sedtrap = read.xlsx('Data/Sediment Trap/NGA Sediment Trap Chlorophylls.xlsx', startRow = 2)
sedtrap$station = toupper(sedtrap$station)
sedtrap = sedtrap[!is.na(sedtrap$cruise),]
sedtrap$pool.id = paste(sedtrap$cruise, sedtrap$deployment, sedtrap$depth, sep = '.')

deployment = data.frame(pool.id = unique(sedtrap$pool.id),
                        cruise = NA,
                        deployment = NA,
                        station = NA,
                        lat = NA,
                        lon = NA,
                        depth = NA,
                        deployment.time = Sys.time(),
                        recovery.time = Sys.time(),
                        sChl.Flux = NA,
                        sPhaeo.Flux = NA,
                        mChl.Flux = NA,
                        mPhaeo.Flux = NA,
                        lChl.Flux = NA,
                        lPhaeo.Flux = NA,
                        Chl.Flux = NA,
                        Phaeo.Flux = NA)


for (i in 1:nrow(deployment)) {
  
  l = which(sedtrap$pool.id == deployment$pool.id[i])
  
  deployment$cruise[i] = sedtrap$cruise[l[1]]
  deployment$deployment[i] = sedtrap$deployment[l[1]]
  deployment$station[i] = sedtrap$station[l[1]]
  deployment$depth[i] = sedtrap$depth[l[1]]
  
  ## Small
  l = which(sedtrap$pool.id == deployment$pool.id[i] & sedtrap$max.size == 50)
  if (length(l) > 0) {
    deployment$sChl.Flux[i] = mean(sedtrap$Chl.Flux[l])
    deployment$sPhaeo.Flux[i] = mean(sedtrap$Phaeo.Flux[l])
  }
  
  ## Medium
  l = which(sedtrap$pool.id == deployment$pool.id[i] & sedtrap$min.size == 50 & sedtrap$max.size == 200)
  if (length(l) > 0) {
    deployment$mChl.Flux[i] = mean(sedtrap$Chl.Flux[l])
    deployment$mPhaeo.Flux[i] = mean(sedtrap$Phaeo.Flux[l])
  }
  
  ## Large
  l = which(sedtrap$pool.id == deployment$pool.id[i] & sedtrap$max.size == 200)
  if (length(l) > 0) {
    deployment$lChl.Flux[i] = mean(sedtrap$Chl.Flux[l])
    deployment$lPhaeo.Flux[i] = mean(sedtrap$Phaeo.Flux[l])
  }
  
  ## Total
  l = which(sedtrap$pool.id == deployment$pool.id[i] & (is.na(sedtrap$min.size) & is.na(sedtrap$max.size)))
  if (length(l) > 0) {
    deployment$Chl.Flux[i] = mean(sedtrap$Chl.Flux[l])
    deployment$Phaeo.Flux[i] = mean(sedtrap$Phaeo.Flux[l])
  }
  
  ## Try to fill in NAs
  if (is.na(deployment$Chl.Flux[i])) {
    deployment$Chl.Flux[i] = sum(deployment$sChl.Flux[i], deployment$mChl.Flux[i], deployment$lChl.Flux[i], na.rm = T)
  }
  if (is.na(deployment$Phaeo.Flux[i])) {
    deployment$Phaeo.Flux[i] = sum(deployment$sPhaeo.Flux[i], deployment$mPhaeo.Flux[i], deployment$lPhaeo.Flux[i], na.rm = T)
  }
  
  k = which(log$deployment == deployment$deployment[i] & log$cruise == deployment$cruise[i])
  deployment$deployment.time[i] = log$deployment.time[k]
  deployment$recovery.time[i] = log$recovery.time[k]
  
  k = which(station$station == deployment$station[i])
  deployment$lat[i] = station$latitude[k]
  deployment$lon[i] = station$longitude[k]
}

deployment$Deployment = paste(deployment$cruise, deployment$deployment, sep = '-')

tmp = deployment[,c('cruise','deployment','station','depth','deployment.time', 'recovery.time','Chl.Flux', 'Phaeo.Flux')]
colnames(tmp) = c('cruise', 'deployment.id','station', 'depth', 'deployment_datetime', 'recovery_datetime', 'chlorophyll_flux', 'phaeopigment_flux')
tmp$deployment_datetime = paste(tmp$deployment_datetime)
tmp$recovery_datetime = paste(tmp$recovery_datetime)
tmp$chl_flux = round(tmp$chl_flux)
tmp$phaeopigment_flux = round(tmp$phaeopigment_flux)
tmp = tmp[tmp$chl_flux > 0,]

desc = data.frame(parameter = colnames(tmp), type = 'text', units = NA, appropriate_values = NA)

write.csv(tmp, file = 'pub/nga_sediment_trap_chl_L0_Vx.csv', row.names = F)
write.csv(desc, 'pub/nga_sediment_trap_chl_L0_desc.csv', row.names = F)
browseURL('pub/nga_sediment_trap_chl_L0_desc.csv')

#### Chlorophyll & POC inventory

poc = readRDS('../NGA-Data-Processing/_rdata/NPP.rds')
chl = readRDS('../NGA-Data-Processing/_rdata/CHL.rdata')
chl$Depth.m. = as.numeric(chl$Depth.m.)
chl$TotalChlA.ug.L.[is.na(chl$TotalChlA.ug.L.)] = chl$TotalChlA..ug.L.[is.na(chl$TotalChlA.ug.L.)]
chl$TotalPhaeo.ug.L.[is.na(chl$TotalPhaeo.ug.L.)] = chl$TotalPhaeo..ug.L.[is.na(chl$TotalPhaeo.ug.L.)]
chl$FractionChl.20[is.na(chl$FractionChl.20)] = chl$Fraction.Chl..20[is.na(chl$FractionChl.20)]

chl$Fraction.Chl..20 = NULL
chl$TotalPhaeo..ug.L. = NULL
chl$TotalChlA..ug.L. = NULL
chl = chl[!is.na(chl$TotalChlA.ug.L.),]

deployment$Chl = NA
deployment$sChl = NA
deployment$Phaeo = NA
deployment$POC = NA

for (i in 1:nrow(deployment)) {
  k = which(deployment$cruise[i] == poc$Cruise & deployment$station[i] == poc$Station)
  if (length(k) > 0) {
    k.min = k[which.min(poc$Depth.m.[k])]
    deployment$POC[i] = integrate.trapezoid(x = c(0, poc$Depth.m.[k]),
                                            y = c(poc$POC.ugC.L.[k.min], poc$POC.ugC.L.[k]),
                                            xlim = c(0, max(poc$Depth.m.[k], na.rm = T)))
  }
  
  k = which(deployment$cruise[i] == chl$Cruise & deployment$station[i] == chl$Station)
  
  if (length(k) > 1) {
    ## vert integrate:
    k.min = k[which.min(chl$Depth.m.[k])]
    deployment$Chl[i] = integrate.trapezoid(x = c(0, chl$Depth.m.[k]),
                                            y = c(chl$TotalChlA.ug.L.[k.min], chl$TotalChlA.ug.L.[k]),
                                            xlim = c(0, max(chl$Depth.m.[k])))
    if (!is.na(chl$FractionChl.20[k.min])) {
      deployment$sChl[i] = integrate.trapezoid(x = c(0, chl$Depth.m.[k]),
                                               y = c(chl$TotalChlA.ug.L.[k.min] * (1 - chl$FractionChl.20[k.min]), chl$TotalChlA.ug.L.[k] * (1 - chl$FractionChl.20[k])),
                                               xlim = c(0, max(chl$Depth.m.[k])))
    }
    deployment$Phaeo[i] = integrate.trapezoid(x = c(0, chl$Depth.m.[k]),
                                              y = c(chl$TotalPhaeo.ug.L.[k.min], chl$TotalPhaeo.ug.L.[k]),
                                              xlim = c(0, max(chl$Depth.m.[k])))
    
    
  }
}

for (d in unique(deployment$Deployment)) {
  l = which(deployment$Deployment == d)
  l = l[which.min(deployment$depth[l])]
  
  message(d, '\t', deployment$Chl.Flux[l] / deployment$Chl[l],
          ' \t ', deployment$Phaeo.Flux[l] / deployment$Phaeo[l],
          ' \t ', (deployment$Phaeo.Flux[l] + deployment$Chl.Flux[l]) / (deployment$Phaeo[l] + deployment$Chl[l]))
}



deployment$Export.pigment = (deployment$Phaeo.Flux + deployment$Chl.Flux) / (deployment$Phaeo + deployment$Chl)


col = make.qual.pal(deployment$cruise, 'alphabet')
col = make.qual.pal(deployment$deployment, 'alphabet')

plot(deployment$Chl[deployment$depth < 50],
     deployment$Export.pigment[deployment$depth < 50],
     ylim = c(0, 50),
     xlim = c(0, 400),
     col = col[deployment$depth < 50],
     pch = 16)
grid(); box()
legend('bottom', legend = unique(deployment$cruise), col = unique(col), cex = 0.8, ncol = 2, lwd = 3)


<<<<<<< Updated upstream
cce.st = read.xlsx('Data/External/CCELTER Sedtrap Data.xlsx')
cce.chl = read.xlsx('Data/External/CCELTER Chl Data.xlsx')
cce.chl$Cycle = as.numeric(cce.chl$Cycle)

cce.st$Chl = NA

for (i in 1:nrow(cce.st)) {
  k = which(cce.st$studyName[i] == cce.chl$studyName & cce.st$Cycle[i] == cce.chl$Cycle)
  
  if (length(k) > 0) {
    k = which(cce.st$studyName[i] == cce.chl$studyName & cce.st$Cycle[i] == cce.chl$Cycle & cce.chl$Cast[k[1]] == cce.chl$Cast)
    depths = c(0, cce.chl$`Depth.(m)`[k])
    tmp = c(cce.chl$`Chlorophyll.a.(µg/L)`[k[which.min(cce.chl$`Depth.(m)`[k])]], cce.chl$`Chlorophyll.a.(µg/L)`[k])
    cce.st$Chl[i] = integrate.trapezoid(depths, tmp, xlim = range(depths))
  }
}

=======
  plot(deployment$POC[deployment$depth < 50],
       deployment$Export.pigment[deployment$depth < 50],
       ylim = c(0, 50),
       xlim = c(0, 10e3),
       col = col[deployment$depth < 50],
       pch = 16)
abline(a = 0, b= 5e-3)



col = make.qual.pal(deployment$cruise, 'alphabet')
{
  plot(NULL, NULL,
       xlim = c(-2,1),
       ylim = c(200, 0),
       ylab = 'Depth (m)',
       xlab = 'Chl Flux (mg Chl m-2 d-1)',
       xaxt = 'n')
  grid(nx = NA, ny = 4); box()
  add.log.axis(1, base = 10, grid.major = T)
  
  for (d in unique(deployment$Deployment)) {
    k = deployment$Deployment == d
    
    lines(log10(deployment$Chl.Flux[k]/1e3),
          deployment$depth[k],
          col = col[which(d == deployment$Deployment)],
          lwd = 3)
  }
  legend('topleft', legend = unique(deployment$cruise), col = unique(col), cex = 0.8, ncol = 2, lwd = 3)
  
  plot(NULL, NULL,
       xlim = c(-1,2),
       ylim = c(200, 0),
       ylab = 'Depth (m)',
       xlab = 'Pigment Flux (mg m-2 d-1)',
       xaxt = 'n')
  grid(nx = NA, ny = 4); box()
  add.log.axis(1, base = 10, grid.major = T)
  
  for (d in unique(deployment$Deployment)) {
    k = deployment$Deployment == d
    lines(log10(deployment$Chl.Flux[k]/1e3 + deployment$Phaeo.Flux[k]/1e3),
          deployment$depth[k],
          col = col[which(d == deployment$Deployment)],
          lwd = 3)
  }
  legend('topleft', legend = unique(deployment$cruise), col = unique(col), cex = 0.8, ncol = 2, lwd = 3)
}

{
  plot(NULL, NULL,
       xlim = c(0,1),
       ylim = c(200, 0),
       ylab = 'Depth (m)',
       xlab = 'Phaeopigment Ratio')
  grid(); box()
  
  for (d in unique(deployment$Deployment)) {
    k = deployment$Deployment == d
    lines(deployment$Phaeo.Flux[k] / (deployment$Phaeo.Flux[k] + deployment$Chl.Flux[k]), deployment$depth[k], lwd = 3, col = col[which(d == deployment$Deployment)])
  }
  legend('topleft', legend = unique(deployment$cruise), col = unique(col), cex = 0.8, ncol = 1, lwd = 3)
}



## Comparison with CCE
col = pals::alphabet(2)
{
  plot(NULL, NULL,
       xlim = c(-1,2),
       ylim = c(200, 0),
       ylab = 'Depth (m)',
       xlab = 'Pigment Flux (mg m-2 d-1)',
       xaxt = 'n')
  grid(nx = NA, ny = 4); box()
  add.log.axis(1, base = 10, grid.major = T)
  
  for (d in unique(deployment$Deployment)) {
    k = deployment$Deployment == d
    lines(log10(deployment$Chl.Flux[k]/1e3 + deployment$Phaeo.Flux[k]/1e3),
          deployment$depth[k],
          col = col[1],
          lwd = 3)
  }
  
  
  for (d in unique(cce.st$Deployment.Event.Number)) {
    k = cce.st$Deployment.Event.Number == d
    lines(log10(cce.st$`Chlorophyll.a.flux.(µg/m²/day)`[k]/1e3 + cce.st$`Phaeopigment.flux.(µg/m²/day)`[k]/1e3),
          cce.st$`Depth.(m)`[k],
          col = col[2],
          lwd = 3)
  }
  
  
  
  legend('topleft', legend = c('NGA', 'CCE'), col = col[c(1,2)], cex = 0.8, ncol = 2, lwd = 3)
}




















map = make.map.nga()

for (d in unique(deployment$Deployment)) {
  k = which(deployment$Deployment == d)
  add.map.points(map,
                 lon = deployment$Lon[k[1]],
                 lat = deployment$Lat[k[1]],
                 col = make.pal(deployment$Phaeo.Flux[k[which.min(deployment$Depth[k])]], min = 0, max = 20, pal = 'inferno'))
}


###  Size Fractionation

{ # Small and Large Phaeopigment Flux
  plot(NULL, NULL,
       xlim = c(0,25),
       ylim = c(200, 0),
       ylab = 'Depth (m)',
       xlab = 'Pigment Flux')
  grid(); box()
  
  for (d in unique(deployment$Deployment)) {
    k = deployment$Deployment == d
    lines(deployment$sPhaeo.Flux[k]/1e3, deployment$depth[k], lwd = 3)
    
  }
  
  plot(NULL, NULL,
       xlim = c(0,25),
       ylim = c(200, 0),
       ylab = 'Depth (m)',
       xlab = 'Pigment Flux')
  grid(); box()
  
  for (d in unique(deployment$Deployment)) {
    k = deployment$Deployment == d
    lines(deployment$lPhaeo.Flux[k]/1e3, deployment$depth[k], lwd = 3)
  }
}

{ # Small and Large Phaeopigment Ratio
  plot(NULL, NULL,
       xlim = c(0,1),
       ylim = c(200, 0),
       ylab = 'Depth (m)',
       xlab = 'Pigment Flux')
  grid(); box()
  
  for (d in unique(deployment$Deployment)) {
    k = deployment$Deployment == d
    lines(deployment$sPhaeo.Flux[k] / (deployment$sChl.Flux[k] + deployment$sPhaeo.Flux[k]), deployment$depth[k], lwd = 3)
  }
  
  plot(NULL, NULL,
       xlim = c(0,1),
       ylim = c(200, 0),
       ylab = 'Depth (m)',
       xlab = 'Pigment Flux')
  grid(); box()
  
  for (d in unique(deployment$Deployment)) {
    k = deployment$Deployment == d
    lines(deployment$lPhaeo.Flux[k] / (deployment$lPhaeo.Flux[k] + deployment$lChl.Flux[k]), deployment$depth[k], lwd = 3)
  }
  
}

{ # Small and Large Chl Ratio
  plot(NULL, NULL,
       xlim = c(0,10),
       ylim = c(200, 0),
       ylab = 'Depth (m)',
       xlab = 'Chl Flux')
  grid(); box()
  
  for (d in unique(deployment$Deployment)) {
    k = deployment$Deployment == d
    lines(deployment$sChl.Flux[k]/1e3, deployment$depth[k], lwd = 3)
    lines(deployment$lChl.Flux[k]/1e3, deployment$depth[k], lwd = 3, col = 'dark green')
  }
  
  plot(NULL, NULL,
       xlim = c(0,10),
       ylim = c(200, 0),
       ylab = 'Depth (m)',
       xlab = 'Phaeo Flux')
  grid(); box()
  
  for (d in unique(deployment$Deployment)) {
    k = deployment$Deployment == d
    lines(deployment$sPhaeo.Flux[k]/1e3, deployment$depth[k], lwd = 3, col = 'dark grey')
    lines(deployment$lPhaeo.Flux[k]/1e3, deployment$depth[k], lwd = 3)
  }
}












