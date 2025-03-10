% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/convert-to-eml.R
\name{convert_to_eml}
\alias{convert_to_eml}
\title{Process metadata submission and format following the Ecological Metadata Language}
\usage{
convert_to_eml(email)
}
\arguments{
\item{email}{Character indicating the email address with which you have access to the SPI-Birds metadata sheet}
}
\value{
an EML.xml from the submitted metadata, and a list with metadata fields (i.e., studyID, siteID, siteName, custodianName, country, geographic coordinates,and taxonomic coverage) that are stored in the metadata tables (\code{R/datasets.R})
}
\description{
The Ecological Metadata Language (EML) defines a comprehensive vocabulary and XML markup
for documenting research data in the fields of ecology and environmental sciences. EML
is the standard used by SPI-Birds to structure metadata of studies and associated datasets.
}
