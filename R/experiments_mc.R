source('risk.R')
library(parallel)
run_experiments_mc <- function(my_path){
  #' Risk model algorithm experiments
  #' 
  #' Iterates through all csv files in the path and runs risk mod
  #' @param my_path character path to folder of csv files (assumes
  #' files are stored as (x)_data.csv and (x)_weights.csv)
  #' @return results are saved as a csv file results_R.csv in the same folder
  
  # Files in path
  files <- list.files(my_path)
  
  # Iterate through files
  files.data <- files[grep("_data.csv", files)]

  res <- mclapply(files.data, function(f){
    # Print for ease
    # Discard print due to parallell 
    #print(paste0(my_path,f))
    
    # Read in data
    df <- read.csv(paste0(my_path,f))
    y <- df[[1]]
    X <- as.matrix(df[,2:ncol(df)])
    X <- cbind(rep(1,nrow(X)), X) # adds intercept column
    
    # Add weights file if needed
    weights <- rep(1, nrow(X))
    weights_file <- paste0(substr(f,1,nchar(f)-9),"_weights.csv") # Caution! Need to change string length per conditions
    if (file.exists(weights_file)){
      weights <- read.csv(weights_file)
      weights <- weights[[1]]
    }
    
    # Run algorithm to get risk model
    # Testing for lambda_min as lambda 0
    t1 <- Sys.time()
    #lambda0 <- cv_risk_mod(X, y, weights=weights, nfolds = 5)$lambda_min # chenge for cv
    #lambda1se <- cv_risk_mod(X, y, weights=weights, nfolds = 5)$lambda_1se
    mod <- risk_mod(X, y, weights=weights, lambda0 = 0) # change for cv
    t2 <- Sys.time()
    
    
    # Get evaluation metrics
    time_secs <- t2 - t1
    res_metrics <- get_metrics(mod)
    non_zeros <- sum(mod$beta[-1] != 0)
    med_abs <- median(abs(mod$beta[-1]))
    max_abs <- max(abs(mod$beta[-1]))
    
    # Add row to data frame
    file_row <- data.frame(data=f, n = nrow(X), p = ncol(X), lambda0 = 0, 
                           non_zeros = non_zeros, med_abs = med_abs, max_abs = max_abs,
                           acc = res_metrics$acc, sens = res_metrics$sens, 
                           spec = res_metrics$spec, sec = time_secs) # change for cv  
    return(file_row)
  },mc.cores = 8)
  

  results <- do.call(rbind, lapply(res, data.frame))
  write.csv(results, paste0("/Users/oscar/Documents/GitHub/Risk_Model_Research/", "ncd_nocv_mc.csv"), row.names=FALSE)
}

t1.2 <- Sys.time()
run_experiments_mc("/Users/oscar/Documents/GitHub/Risk_Model_Research/sim_dat_new/")
t2.2 <- Sys.time()
time_mclapply <- t2.2 - t1.2