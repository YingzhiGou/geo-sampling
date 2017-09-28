#Intersect rasters with target points and then sample representatively
############################################################
sample_clhs <- function(cov_names, data_folder, shape_file, output_folder, no_samples){
  
  source("install_import_packages.R")
  required_packages <- c("raster","clhs","rgdal","moments")
  dummy <- install_import_packages(required_packages)
  
  r <- raster(paste(data_folder,paste0(cov_names[1],".tif"), sep = "/"))
  cov_stack <- stack(r)
  for(i in 2:length(cov_names)){
    r <- raster(paste(data_folder,paste0(cov_names[i],".tif"), sep = "/"))
    cov_stack <- stack(cov_stack,r)
  }
  
  S <- readOGR(dsn = data_folder, layer = shape_file, verbose = FALSE)
  
  #Intersect the covariates with the target locations
  cov_intersected <- extract(cov_stack, S)
  df <- data.frame(cov_intersected)
  #Convert to categorical
  df$si_geol1 <- as.factor(df$si_geol1)
  
  #exp_folder = "/home/masoud/cLHS_withCAT_experiments"
  old_par <- par()
  par(mfrow = c(3,1))
  
  for (i in no_samples){  
    dsn_folder_cLHS = paste(output_folder, paste0("cLHS_", i,"points"), sep = "/")
    dir.create(dsn_folder_cLHS, recursive = TRUE)
    res <- clhs(df, size = i, iter = 5000, progress = FALSE, simple = FALSE )
    
    S_clhs <- S[res$index_samples,]
    #plot(coordinates(S_clhs))
    writeOGR(S_clhs, dsn = dsn_folder_cLHS, layer = shape_file, driver = "ESRI Shapefile", overwrite_layer = TRUE)
    
    dsn_folder_RND = paste(output_folder, paste0("RND_", i,"points"), sep = "/")
    RND_samples <- sample(1:nrow(S),i)
    S_RND <- S[RND_samples,]
    writeOGR(S_RND, dsn = dsn_folder_RND, layer = shape_file, driver = "ESRI Shapefile", overwrite_layer = TRUE)
    #plot(coordinates(ss), add=TRUE )
    
    #Save histograms in the folders
    for(i in 1:length(cov_names)){
      tmp_cov <- res$initial_object[[i]]
      if(!is.numeric(tmp_cov))  tmp_cov <- as.numeric(tmp_cov)
      hist(tmp_cov, main = paste("Original histogram of",cov_names[i]), xlab = paste("Mean:",mean(tmp_cov), ", Variance", var(tmp_cov)), freq = FALSE)
      tmp_cov <- res$sampled_data[[i]]
      if(!is.numeric(tmp_cov))  tmp_cov <- as.numeric(tmp_cov)
      hist(tmp_cov, main = paste("cLHS histogram of",cov_names[i]), xlab = paste("Mean:",mean(tmp_cov), ", Variance", var(tmp_cov)), freq = FALSE)
      tmp_cov <- res$initial_object[[i]][RND_samples]
      if(!is.numeric(tmp_cov))  tmp_cov <- as.numeric(tmp_cov)
      hist(tmp_cov, main = paste("RND histogram of",cov_names[i]), xlab = paste("Mean:",mean(tmp_cov), ", Variance", var(tmp_cov)), freq = FALSE)
      dev.print(pdf, paste(dsn_folder_cLHS, paste0(cov_names[i],".pdf"), sep = "/"))
    }
  }
  par(mfrow = c(1,1))
  plot(res)
}
#dev.print(pdf, paste(dsn_folder_cLHS, "cost.pdf", sep = "/"))