% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/add-metadata.R
\name{add_metadata}
\alias{add_metadata}
\title{Add or update processed metadata to SPI-Birds metadata tables}
\usage{
add_metadata(meta)
}
\arguments{
\item{meta}{List output of \link{convert_to_eml}.}
}
\description{
Store studyID, siteID, siteName, custodianName, country and geographic coordinates in the SPI-Birds metadata tables (\link{site_codes}, \link{study_codes}, \link{species_codes}).
}
