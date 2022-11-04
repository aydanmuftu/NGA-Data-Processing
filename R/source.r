library(data.table)
library(TheSource)
library(openxlsx)


load.all = function(path, pattern = '*.csv', verbose = T) {
  files = list.files(path = path, pattern = pattern, full.names = T)
  
  data = list()
  
  for (f in files) {
    name = strsplit(f, split = '/')[[1]]
    data[[name[length(name)]]] = data.table::fread(f)
  }
  
  data
}

concat = function(data, verbose = T) {
  res = data[[1]]
  
  for (i in 2:length(data)) {
    if (verbose) {message('Loading file ', i, ' of ', length(data), '.')}
    
    ## Add new columns to res
    name = names(data[[i]])[!names(data[[i]]) %in% names(res)]
    
    if (length(name) > 0) {
      if (verbose) {message('Adding ', length(name), ' columns to compilation.')}
      for (n in name) {
        res[[n]] = NA
      }
    }
    
    ## Add pad columns to data[[i]]
    name = names(res)[!names(res) %in% names(data[[i]])]
    
    if (length(name) > 0) {
      if (verbose) {message('Adding ', length(name), ' padding columns .')}
      for (n in name) {
        data[[i]][[n]] = NA
      }
    }
    
    res = rbind(res, data[[i]], fill = T)
  }
  
  ## Retunr
  res
}
