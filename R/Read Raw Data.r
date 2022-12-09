source('R/source.r')

## Event Logs
events = load.all('Data/Event Logs/', pattern = '.xlsx')
events = concat(events)
events$GPS_Time = conv.time.excel(as.numeric(events$GPS_Time))


## Load all TSG data
temp = load.all('Data/Underway/TSG/', pattern = '*')
pos = concat(temp)
names(pos) = gsub('_', '', make.names(names(pos)))
pos = pos[,order(names(pos))]

for (i in 1:nrow(pos)) {
  if (is.na(pos$DateTime.UTC.[i]) & !is.na(pos$YYYY[i])) {
    pos$DateTime.UTC.[i] = make.time(year = pos$YYYY[i],
                                     month = pos$MM[i],
                                     day = pos$DD[i],
                                     hour = pos$hh[i],
                                     minute = pos$mm[i],
                                     second = pos$ss[i],
                                     tz = 'UTC')
  }
  
  ## Fix lat/lon if not present
  if (is.na(pos$Longitude[i])) { pos$Longitude[i] = pos$Longitude.1[i]}
  if (is.na(pos$Longitude[i])) { pos$Longitude[i] = pos$Longitude.decimaldegreeseast.[i]}
  
  if (is.na(pos$Latitude[i])) { pos$Latitude[i] = pos$Latitude.1[i]}
  if (is.na(pos$Latitude[i])) { pos$Latitude[i] = pos$Latitude.decimaldegreesnorth.[i]}
  
  ## Fix T/S
  if (is.na(pos$Temperature.C.[i])) { pos$Temperature.C.[i] = pos$TemperatureUNCSW.C.[i]}
  if (is.na(pos$Temperature.C.[i])) { pos$Temperature.C.[i] = pos$TemperatureTurner.C.[i]}
  
  if (is.na(pos$Salinity.psu.[i])) { pos$Salinity.psu.[i] = pos$SAL[i]}
}

pos = data.frame(Cruise = pos$Cruise,
                 Datetime = pos$DateTime.UTC.,
                 Longitude = pos$Longitude,
                 Latitude = pos$Latitude,
                 Temp = pos$Temperature.C.,
                 Sal = pos$Salinity.psu.)

summary(pos)

saveRDS(pos, file = '_rdata/TSG.rdata')
write.xlsx(pos, file = '_rdata/TSG.xlsx')


map = make.map.nga()
add.map.points(map, pos$Longitude, pos$Latitude, pch = '.', col = make.qual.pal(pos$Cruise, pal = 'kelly'))


## Load Chlorophyll
temp = load.all('Data/Chlorophyll/')
for (i in 1:length(temp)) {
  temp[[i]]$Cast_Number = as.numeric(temp[[i]]$Cast_Number)
  if (is.na(temp[[i]]$Date_Time[1])) {
    k = which(events$Cruise == temp[[i]]$Cruise[1] & as.numeric(events$Cast) == temp[[i]]$Cast_Number[1] & events$Instrument == 'CTD911')
    
    if (length(k) > 0) {
      temp[[i]]$Date_Time = events$GPS_Time[k[1]]
      temp[[i]]$`Latitude_[decimal_degrees_north]` = as.numeric(events$Latitude[k[1]])
      temp[[i]]$`Longitude_[decimal_degrees_east]` = as.numeric(events$Longitude[k[1]])
    } else {
      message('Nope for ', i)
    }
  }
}

chl = concat(temp)
names(chl) = gsub('_', '', make.names(gsub('<', 'Ls.', gsub('>', 'Gr.', names(chl)))))


saveRDS(chl, file = '_rdata/CHL.rdata')
write.xlsx(chl, file = '_rdata/CHL.xlsx')



### Load POC
temp = load.all('Data/POC/')
poc = concat(temp)
saveRDS(poc, file = '_rdata/POC.rdata')




#### CTD Bottles

temp = load.all('Data/CTD Bottle/')
bottle = concat(temp)

oxy.log = read.xlsx('../NGA-Projects/Data/Oxygen/NGA Oxygen Titration Log.xlsx', sheet = 2, startRow = 2)
oxy.log$ctd = NA

for (i in 1:nrow(oxy.log)) {
  k = which(bottle$Cruise == oxy.log$Cruise[i] & bottle$Cast_Number == oxy.log$Cast[i] & bottle$Bottle_Number == oxy.log$Niskin[i])
  
  if (length(k) > 0) {
    message('sdf')
    oxy.log$ctd[i] = mean(bottle$Oxygen_.umol.kg.[k], na.rm = T)
  }
}
