#' Extract the gene expression prediction summary
#'
#' Extract the gene expression prediction summary (e.g. No of SNPs, R^2, correlation) function.
#' The output can be directly applied to GWAS data for cell-type specific TWAS.
#'
#' @param model A direct output from MiXcan() function, which includes the
#' prediction weights as well as other summaries of the prediction models.
#' @param y: The pre-cleaned expression level data for a single gene in N samples.
#' @param x: A N by P matrix for all the genetic predictors used to predict the genetically regulated expression  of the gene.
#' @param cov: A N by Q matrix for the covariates adjusted in the model (e.g. age, population stratification).
#' @param pi: An estimation of cell-type fraction for the cell type of interest.
#'

#' @return A data frame with weight for cell 1 and 2, including the potential meta data for the SNP
#' @export
#'
MiXcan_refit_summary_test <- function(model, x, y, pi, cov=NULL) {
  #summary <- MiXcan_extract_summary(x=x, y=y, pi=pi, model=model)
  weights=model
  w2 = subset(model, model$weight_cell_1  != 0 & model$weight_cell_2 !=0 )
  idx=match(w2$xNameMatrix, weights$xNameMatrix)
  weights$weight_cell_1[idx]=w2$weight_cell_1
  weights$weight_cell_2[idx]=w2$weight_cell_2
  
  yhat=x %*% weights$weight_cell_1 *pi + x %*% weights$weight_cell_2 *(1-pi)
  
  r=cor.test(y,yhat, use="complete.obs")
  summary = data.frame()
  summary[1,1] = r$estimate^2
  summary[1,2] = r$p.value
  
  colnames(summary)[1] = "in_sample_r2_refit"
  colnames(summary)[2] = "in_sample_cor_pvalue_refit"
  
  return(summary)
}




