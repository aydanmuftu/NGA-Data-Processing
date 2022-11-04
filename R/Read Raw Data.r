source('R/source.r')

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
chl = concat(temp)
