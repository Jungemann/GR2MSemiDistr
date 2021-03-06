#' Uncertainty analysis of GR2M model parameters with the MCMC algorithm.
#'
#' @param Data        File with input data in airGR format (DatesR,P,E,Q).
#' @param Subbasins   Subbasins shapefile.
#' @param Dem         Raster DEM filename.
#' @param RunIni      Initial date of model simulation (in mm/yyyy format).
#' @param RunEnd      Final date of model simulation (in mm/yyyy format).
#' @param WarmUp      Number of months for warm-up. NULL as default.
#' @param Parameters      GR2M model parameters and correction factor of P and E.
#' @param Parameters.Min  Minimum values of GR2M model parameters and correction factor of P and E.
#' @param Parameters.Max  Maximum values of GR2M model parameters and correction factor of P and E.
#' @param Niter 	        Number of iterations. 1000 as default.
#' @param IniState    Initial GR2M states variables. NULL as default.
#' @param Positions    Cell numbers to extract data faster for each subbasin. NULL as default.
#' @param MCMC    MCMC data in .Rda format.
#' @return  Lower(Q5) and upper (Q95) streamflows uncertainty bounds.
#' @export
#' @import  rgdal
#' @import  raster
#' @import  rgeos
#' @import  FME
#' @import  parallel
#' @import  tictoc
#' @import  airGR
#' @import  abind
Uncertainty_GR2MSemiDistr <- function(Data,
                                      Subbasins,
                                      Dem,
                                      RunIni,
                                      RunEnd,
                                      WarmUp=NULL,
                                      Parameters,
                                      Parameters.Min,
                                      Parameters.Max,
                                      Niter,
                                      IniState=NULL,
                                      Positions=NULL,
                                      MCMC=NULL){
  # Data=Ans1
  # Subbasins=roi
  # Dem='Basin.tif'
  # RunIni='08/1981'
  # RunEnd='12/1981'
  # WarmUp=2
  # Parameters=BestParam
  # Parameters.Min=c(1, 0.01, 0.8, 0.8) # Minimum values for X1, X2, Fpp, and Fpet
  # Parameters.Max=c(2000, 2, 1.2, 1.2) # Maximum values for X1, X2, Fpp, and Fpet
  # Niter=5
  # IniState=NULL
  # Positions=NULL
  # MCMC=NULL

  # Load packages
  require(rgdal)
  require(raster)
  require(rgeos)
  require(parallel)
  require(tictoc)
  require(airGR)
  require(FME)
  require(abind)
  tic()

  # Generate parameters
  if(is.null(MCMC)==TRUE){

    # Show message
    cat('\f')
    message('Calculating parameter uncertainty with MCMC')
    message('Please wait...')

    # Residual function
    RFUN <- function(Variable){

      Ans <- Run_GR2MSemiDistr(Data=Data,
                               Subbasins=Subbasins,
                               RunIni=RunIni,
                               RunEnd=RunEnd,
                               Parameters=Variable,
                               IniState=IniState,
                               Regional=FALSE,
                               Update=FALSE,
                               Save=FALSE)

      # Calculate residuals
      if(is.null(WarmUp)==TRUE){
        Qobs <- Ans$Qout$obs
        Qsim <- Ans$Qout$sim
      }else{
        Qobs <- Ans$Qout$obs[-WarmUp:-1]
        Qsim <- Ans$Qout$sim[-WarmUp:-1]
      }
      mRes <- as.vector(na.omit(Qsim-Qobs))
      return(mRes)
    } # End function

    msr  <- mean((RFUN(Parameters))^2)
    MCMC <- modMCMC(f=RFUN,
                    p=Parameters,
                    lower=Parameters.Min,
                    upper=Parameters.Max,
                    niter=Niter,
                    var0=msr)
    dir.create(file.path(getwd(),'Inputs'),recursive=T,showWarnings=F)
    save(MCMC, file=file.path(getwd(),'Inputs','MCMC.Rda'))
  }else{
    load(file.path(getwd(),'Inputs','MCMC.Rda'))
  }


  # Show message
  cat('\f')
  message('Generating streamflow uncertainty bounds')
  message('Please wait...')
  pars <- unique(MCMC$pars)
  Ans  <- list()
  for(w in 1:nrow(pars)){
    # Run model
    Qmod <- Run_GR2MSemiDistr(Data=Data,
                              Subbasins=Subbasins,
                              RunIni=RunIni,
                              RunEnd=RunEnd,
                              Parameters=pars[w,],
                              IniState=IniState,
                              Regional=FALSE,
                              Update=FALSE,
                              Save=FALSE)
    if(is.null(WarmUp)==TRUE){
      Ans[[w]] <- as.matrix(Qmod$Qsub)
      Dates    <- Qmod$Dates
    }else{
      Ans[[w]] <- as.matrix(Qmod$Qsub[-WarmUp:-1,])
      Dates    <- Qmod$Dates[-WarmUp:-1]
    }
  }
  qsub <- abind(Ans, along=3)
  q5   <- apply(qsub, c(1,2), function(x) quantile(x,0.05))
  q95  <- apply(qsub, c(1,2), function(x) quantile(x,0.95))

  # Routing streamflow for each subbasin at quantile 5
  M5 <- list(Qsub=q5,Dates=Dates)
  Q5 <- Routing_GR2MSemiDistr(Model=M5,
                              Subbasins=Subbasins,
                              Dem=Dem,
                              AcumIni=format(as.Date(head(Dates,1)),'%m/%Y'),
                              AcumEnd=format(as.Date(tail(Dates,1)),'%m/%Y'),
                              Positions=Positions,
                              Save=FALSE,
                              Update=FALSE)

  M95 <- list(Qsub=q95,Dates=Dates)
  Q95 <- Routing_GR2MSemiDistr(Model=M95,
                               Subbasins=Subbasins,
                               Dem=Dem,
                               AcumIni=format(as.Date(head(Dates,1)),'%m/%Y'),
                               AcumEnd=format(as.Date(tail(Dates,1)),'%m/%Y'),
                               Positions=Positions,
                               Save=FALSE,
                               Update=FALSE)

  # Prepare data to export
  sub.id <- paste0('GR2M_ID_',as.vector(Subbasins$GR2M_ID))
  QR5  <- as.data.frame(round(Q5,3))
  QR95 <- as.data.frame(round(Q95,3))
  colnames(QR5)  <- sub.id
  colnames(QR95) <- sub.id
  rownames(QR5)  <- as.Date(Dates)
  rownames(QR95) <- as.Date(Dates)
  Ans <- list(lower=QR5,
              upper=QR95)

  # Show message
  message("Done!")
  toc()
  return(Ans)

} # End (not run)
