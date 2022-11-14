source('R/source.r')

## Event Logs
events = load.all('Data/Event Logs/', pattern = '.xlsx')
events = concat(events)
events$GPS_Time = conv.time.excel(as.numeric(events$GPS_Time))

## Load all TSG data
temp = load.all('Data/Underway/', pattern = 'tsg')
pos = concat(temp)
names(pos) = gsub('_', '', make.names(names(pos)))

saveRDS(pos, file = '_rdata/TSG.rdata')
write.xlsx(pos, file = '_rdata/TSG.xlsx')


map = make.map.nga()
add.map.points(map, pos$Longitude.decimaldegreeseast., pos$Latitude.decimaldegreesnorth., pch = '.')


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
