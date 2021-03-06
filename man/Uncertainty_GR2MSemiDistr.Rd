% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Uncertainty_GR2MSemiDistr.R
\name{Uncertainty_GR2MSemiDistr}
\alias{Uncertainty_GR2MSemiDistr}
\title{Uncertainty analysis of GR2M model parameters with the MCMC algorithm.}
\usage{
Uncertainty_GR2MSemiDistr(Data, Subbasins, Dem, RunIni, RunEnd,
  WarmUp = NULL, Parameters, Parameters.Min, Parameters.Max, Niter,
  IniState = NULL, Positions = NULL, MCMC = NULL)
}
\arguments{
\item{Data}{File with input data in airGR format (DatesR,P,E,Q).}

\item{Subbasins}{Subbasins shapefile.}

\item{Dem}{Raster DEM filename.}

\item{RunIni}{Initial date of model simulation (in mm/yyyy format).}

\item{RunEnd}{Final date of model simulation (in mm/yyyy format).}

\item{WarmUp}{Number of months for warm-up. NULL as default.}

\item{Parameters}{GR2M model parameters and correction factor of P and E.}

\item{Parameters.Min}{Minimum values of GR2M model parameters and correction factor of P and E.}

\item{Parameters.Max}{Maximum values of GR2M model parameters and correction factor of P and E.}

\item{Niter}{Number of iterations. 1000 as default.}

\item{IniState}{Initial GR2M states variables. NULL as default.}

\item{Positions}{Cell numbers to extract data faster for each subbasin. NULL as default.}

\item{MCMC}{MCMC data in .Rda format.}
}
\value{
Lower(Q5) and upper (Q95) streamflows uncertainty bounds.
}
\description{
Uncertainty analysis of GR2M model parameters with the MCMC algorithm.
}
