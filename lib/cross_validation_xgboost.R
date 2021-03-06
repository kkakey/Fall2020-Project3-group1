########################
### Cross Validation ###
########################

### Author: Kristen Akey
### Project 3


cv.function <- function(features, labels, K, eta_val, lmd, gam, 
                        nr, reweight = FALSE){
  ### Input:
  ### - features: feature data frame
  ### - labels: label data vector
  ### - K: a number stands for K-fold CV
  ### - eta_val, lmd, gam, nr: tuning parameters 
  ### - reweight: sample reweighting 
  
  set.seed(2020)
  n <- dim(features)[1]
  n.fold <- round(n/K, 0)
  s <- sample(n) %% K + 1
  cv.error <- rep(NA, K)
  cv.AUC <- rep(NA, K)
  
  for (i in 1:K){
    ## create features and labels for train/test
    feature_train_cv <- features[s != i,]
    feature_test_cv <- features[s == i,]
    label_train_cv <- labels[s != i]
    label_test_cv <- labels[s == i]
    
    ## sample reweighting
    weight_train_cv <- rep(NA, length(label_train_cv))
    weight_test_cv <- rep(NA, length(label_test_cv))
    for (v in unique(labels)){
      weight_train_cv[label_train_cv == v] = 0.5 * length(label_train_cv) / length(label_train_cv[label_train_cv == v])
      weight_test_cv[label_test_cv == v] = 0.5 * length(label_test_cv) / length(label_test_cv[label_test_cv == v])
    }
    
    ## model training
    if (reweight){
      model_train <- train(feature_train_cv, label_train_cv, w = weight_train_cv, eta_val, lmd, gam, nr)
    } else {
      model_train <- train(feature_train_cv, label_train_cv, w = NULL, eta_val, lmd, gam, nr)
    }
    
    ## make predictions
    prob_pred <- test(model_train, feature_test_cv)
    label_pred <- ifelse(prob_pred >= 0.5, 1, 0)
    label_test_cv <- ifelse(label_test_cv == 2, 0, 1)
    cv.error[i] <- 1 - sum(weight_test_cv * (label_pred == label_test_cv)) / sum(weight_test_cv)
    tpr.fpr <- WeightedROC(prob_pred, label_test_cv, weight_test_cv)
    cv.AUC[i] <- WeightedAUC(tpr.fpr)
  }
  return(c(mean(cv.error),sd(cv.error), mean(cv.AUC), sd(cv.AUC)))
}
