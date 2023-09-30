library(archive)
library(oce)

load.files = function(path) {
  tmp.dir = tempdir(check = T)
  tmp.dir = paste0(tmp.dir, '\\', digest::digest(Sys.time()))
  
  message('Extracting archive.')
  archive_extract(path, dir = tmp.dir)
  cnv.files = list.files(tmp.dir, pattern = '.cnv', full.names = T, recursive = T)
  
  castlist = list()
  for (i in 1:length(cnv.files)) {
    message('Loading file ', i, ' of ', length(cnv.files), '.')
    cast = oce::read.ctd(cnv.files[i])
    #cast@metadata$units
    castlist[[gsub('.cnv', '', basename(cnv.files[i]))]] = as.data.frame(cast@data)
  }
  message('Done.')
  
  castlist
}


## 2018
SKQ201810S = load.files('Data/CTD Downcast/2018/NGA_SKQ201810S_ctd_L1_v1.zip')
TGX201809S = load.files('Data/CTD Downcast/2018/NGA_TGX201809_ctd_L1_v2.zip')
WSD201807S = load.files('Data/CTD Downcast/2018/NGA_WSD201807_ctd_L1_v2.zip')


## 2019
SKQ201915S = load.files('Data/CTD Downcast/2019/NGA_SKQ201915S_ctd_L1_v3.zip')
SKQ201916S = load.files('Data/CTD Downcast/2019/NGA_SKQ201916S_ctd_L1_v1.zip')
TGX201904S = load.files('Data/CTD Downcast/2019/NGA_TGX201904_ctd_L1_v2.zip')
#TGX201909S = load.files('Data/CTD Downcast/2019/NGA_TGX201909_ctd_L1_v2.zip') # Error reading first cnv file...


## 2020
SKQ202006S = load.files('Data/CTD Downcast/2020/NGA_SKQ202006S_ctd_L1_v2.zip')
SKQ202010S = load.files('Data/CTD Downcast/2020/NGA_SKQ202010S_ctd_L1_v2.zip')
SKQ202012S = load.files('Data/CTD Downcast/2020/NGA_SKQ202012S_ctd_L1_v2.zip')


## 2021
SKQ202106S = load.files('Data/CTD Downcast/2021/NGA_SKQ202106S_ctd_L1_v2.zip')
SKQ202110S = load.files('Data/CTD Downcast/2021/NGA_SKQ202110S_ctd_L1_v2.zip')
TGX202109 = load.files('Data/CTD Downcast/2021/NGA_TGX202109_ctd_L1_v1.zip')


## 2022
SKQ202207S = load.files('Data/CTD Downcast/2022/NGA_SKQ202207S_ctd_L1_v1.zip')
SKQ202210S = load.files('Data/CTD Downcast/2022/NGA_SKQ202210S_ctd_L1_v2.zip')
TGX202209S = load.files('Data/CTD Downcast/2022/NGA_TGX202209S_ctd_L1_v1.zip')

## 2023
#SKQ202307S = load.files('Data/CTD Downcast/2023/NGA_SKQ202307S_ctd_L1_v1.zip')
#KM202308S = load.files('Data/CTD Downcast/2023/NGA_KM2308_ctd_L1_v1.zip')



saveRDS(SKQ201810S, file = 'Data/CTD Downcast/SKQ201810S.rds')
saveRDS(TGX201809S, file = 'Data/CTD Downcast/TGX201809S.rds')
saveRDS(WSD201807S, file = 'Data/CTD Downcast/WSD201807S.rds')
saveRDS(SKQ201915S, file = 'Data/CTD Downcast/SKQ201915S.rds')
saveRDS(SKQ201916S, file = 'Data/CTD Downcast/SKQ201916S.rds')
saveRDS(TGX201904S, file = 'Data/CTD Downcast/TGX201904S.rds')
#saveRDS(TGX201909S, file = 'Data/CTD Downcast/TGX201909S.rds')
saveRDS(SKQ202006S, file = 'Data/CTD Downcast/SKQ202006S.rds')
saveRDS(SKQ202010S, file = 'Data/CTD Downcast/SKQ202010S.rds')
saveRDS(SKQ202012S, file = 'Data/CTD Downcast/SKQ202012S.rds')
saveRDS(SKQ202106S, file = 'Data/CTD Downcast/SKQ202106S.rds')
saveRDS(SKQ202110S, file = 'Data/CTD Downcast/SKQ202110S.rds')
saveRDS(TGX202109, file = 'Data/CTD Downcast/TGX202109S.rds')
saveRDS(SKQ202207S, file = 'Data/CTD Downcast/SKQ202207S.rds')
saveRDS(SKQ202210S, file = 'Data/CTD Downcast/SKQ202210S.rds')
saveRDS(TGX202209S, file = 'Data/CTD Downcast/SKQ202209S.rds')
#saveRDS(SKQ202307S, file = 'Data/CTD Downcast/SKQ202307S.rds')
#saveRDS(KM202308S, file = 'Data/CTD Downcast/KM202308S.rds')



