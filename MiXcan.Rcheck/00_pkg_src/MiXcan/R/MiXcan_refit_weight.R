#'  Un-penalized weights for MiXcan selected SNPs
#'
#' Refit MiXcan selected SNPs to  ordinary least square for un-penalized weights.
#'
#' @param model A direct output from MiXcan() function, which includes the
#' prediction weights as well as other summaries of the prediction models.
#' @param y: The pre-cleaned expression level data for a single gene in N samples.
#' @param x: A N by P matrix for all the genetic predictors used to predict the genetically regulated expression  of the gene.
#' @param cov: A N by Q matrix for the covariates adjusted in the model (e.g. age, population stratification).
#' @param pi: An estimation of cell-type faction of the cell type of interest (e.g.
#' epithelial). It can be estimated using existing methods
#' in the literature or from the output of pi_estimation function.
#'
#' @return A data frame with weight for cell 1 and 2, including the potential meta data for the SNP/gene.
#' @export
#'
MiXcan_refit_weight <- function(model, x, y, cov, pi) {
  MiXcan_weight_result <- MiXcan_extract_weight(model = model, keepZeroWeight = F)

  # NoPredictor - no performance

  # NonSpecific
  if (model$type=="NonSpecific") {
    x=as.matrix(x); y=as.matrix(y); p=ncol(x)
    if (is.null(cov)) {xcov=x} else {
      cov=as.matrix(cov); xcov=as.matrix(cbind(x, cov))}
    xreduced=xcov[,which(model$glmnet.tissue$beta!=0)]
    snpidx=which(model$glmnet.tissue$beta[1:p]!=0)
    if (ncol(xreduced)>1) {
      ft=glmnet::glmnet(x=xreduced, y=y, family = "gaussian", alpha=0, lambda = 0)
      beta=ft$beta[1:length(snpidx)]
      MiXcan_weight_result$weight_cell_1=
        MiXcan_weight_result$weight_cell_2=as.numeric(beta)
    } else {
      ft=lm(y~xreduced)
      beta=ft$coefficients[-1]
      MiXcan_weight_result$weight_cell_1=
        MiXcan_weight_result$weight_cell_2=as.numeric(beta)
    }
  }

  # CellTypeSpecific
  if (model$type=="CellTypeSpecific") {

    x=as.matrix(x); y=as.matrix(y); p=ncol(x)
    if (is.null(cov)) {ci=pi-0.5; z=ci*x; z=as.matrix(z); xx=as.matrix(cbind(ci, x, z))
    } else {
      cov=as.matrix(cov); ci=pi-0.5; z=ci*x;
      xx=as.matrix(cbind(ci, x, z, cov))}

    xreduced=xx[,which(model$glmnet.cell$beta!=0)]
    snpidx1=which(model$glmnet.cell$beta[2:(p+1)]!=0)
    snpidx2=which(model$glmnet.cell$beta[(p+2):(2*p+1)]!=0)
    snpidx=union(snpidx1, snpidx2); snpidx=snpidx[order(snpidx)]
    ft=glmnet::glmnet(x=xreduced, y=y, family = "gaussian", alpha=0, lambda = 0)
    est=c(ft$a0,as.numeric(ft$beta))
    beta11=est[3: (p+2)] + est[(p+3): (2*p+2)]/2
    beta21=est[3: (p+2)] - est[(p+3): (2*p+2)]/2

    MiXcan_weight_result$weight_cell_1=beta11[snpidx]
    MiXcan_weight_result$weight_cell_2=beta21[snpidx]

  }
  return(MiXcan_weight_result)
}

