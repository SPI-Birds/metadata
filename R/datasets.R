#' SPI-Birds site table: study site names and locations
#'
#' Geographic information and SPI-Birds-internal codes for all study sites.
#'
#' @format A data frame of 142 rows and 7 variables
#' \describe{
#'    \item{siteID}{Character indicating the unique ID for a SPI-Birds study site.}
#'    \item{siteName}{Character indicating the name of a SPI-Birds study site.}
#'    \item{country}{Character indicating the name of the country where the study site is located.}
#'    \item{countryCode}{Standard code for the country, using \href{https://www.iso.org/iso-3166-country-codes.html}{ISO 3166-1 alpha-2}.}
#'    \item{decimalLatitude}{Geographic latitude of the geographic center of the study site in decimal degrees (WGS84).}
#'    \item{decimalLongitude}{Geographic longitude of the geographic center of the study site in decimal degrees (WGS84).}
#'    \item{locationAccordingTo}{Provider of the coordinate information. Either "metadataProvider" or "data".}
#' }
#'
#' @name site_codes

site_codes <- readr::read_csv(system.file("extdata", "site_codes.csv", package = "metadata", mustWork = TRUE),
                              show_col_types = FALSE)


#' SPI-Birds study table: studies and data custodians
#'
#' SPI-Birds-internal codes for all studies, the related study sites, and the status of the data and pipeline.
#'
#' @format A data frame of 144 rows and 9 variables
#' \describe{
#'    \item{studyID}{Character indicating the unique ID for a SPI-Birds study.}
#'    \item{studyUUID}{Character indicating the univerisally unique identifier for the SPI-Birds study, to be referenced in the EML metadata file.}
#'    \item{studyName}{Character indicating the name of the SPI-Birds study.}
#'    \item{siteID}{Character indicating the unique ID for the SPI-Birds study site where the study is conducted.}
#'    \item{custodianID}{Character indicating the unique ID for the person or organisation that has custody of the data coming from a study.}
#'    \item{custodianName}{Character indicating the name of the person or organisation that has custody of the data coming from a study.}
#'    \item{pipelineID}{Character indicating the unique ID for the pipeline that converts the data coming from a study into the SPI-Birds standard format.}
#'    \item{data}{Logical indicating whether the data collected during the study are available through SPI-Birds.}
#'    \item{standardFormat}{Logical indicating whether the data, if available through SPI-Birds, are standardised according to the SPI-Birds standard protocol.}
#' }
#'
#' @name study_codes

study_codes <- readr::read_csv(system.file("extdata", "study_codes.csv", package = "metadata", mustWork = TRUE),
                               show_col_types = FALSE)

#' SPI-Birds species table: species IDs, codes, and taxonomic ranks
#'
#' Species information, including various taxonomic ranks, SPI-Birds-internal and external codes.
#'
#' @format A data frame 51 rows and 10 variables
#' \describe{
#'    \item{speciesCode}{SPI-Birds' internal unique and persistent identifier for a species.}
#'    \item{speciesID}{SPI-Birds' 6-letter species identifier. First three letters indicate the genus, last three letters indicate the species indicator.}
#'    \item{speciesEURINGCode}{Species code used by \href{https://euring.org/}{EURING}. NA for species not included in EURING.}
#'    \item{speciesEOLpageID}{Species page ID used by the \href{https://eol.org/}{Encyclopedia of Life}.}
#'    \item{speciesCOLID}{Species ID used by the \href{https://www.catalogueoflife.org/}{Catalogue of Life}.}
#'    \item{speciesGBIFID}{Species ID used by the \href{https://www.gbif.org/dataset/d7dddbf4-2cf0-4f39-9b2a-bb099caae36c}{GBIF Backbone Taxonomy}.}
#'    \item{speciesTSN}{Species taxonomic serial number (TSN) used by the \href{https://itis.gov}{Integrated Taxonomic Information System}.}
#'    \item{scientificName}{Scientific name (genus + specific epithet) of the species according to the \href{https://eol.org/}{Encyclopedia of Life}.}
#'    \item{scientificNameAuthorship}{Authorship information of the scientific name, including date information if known. according to the \href{https://eol.org/}{Encyclopedia of Life}.}
#'    \item{vernacularName}{English common name of species according to \href{https://https://www.wikidata.org/}{Wikidata} and/or GBIF.}
#' }
#'
#' @name species_codes

species_codes <- readr::read_csv(system.file("extdata", "species_codes.csv", package = "metadata", mustWork = TRUE),
                                 show_col_types = FALSE)

#' EURING bird species codes
#'
#' Species name, EURING code, date last updated.
#'
#' @format A data frame
#' \describe{
#'      \item{Status}{Character indicating the status of the code. a = aggregate of (sub)species; f = feral species; h = hybrid species; o = obsolete code; sp = species; ssp = subspecies}
#'      \item{EURING_Code}{5-digit character indicating the EURING code for a (sub)species}
#'      \item{Current_Name}{Current scientific name for (sub)species}
#'      \item{Date_Updated}{Date since the code was last updated}
#'      \item{Notes}{Any additional information on (sub)species}
#'      \item{Old_Name}{Old scientific name for (sub)species}
#'      \item{IOC14_1}{IOC 14.1 code for (sub)species}
#' }
#'
#' @name euring_codes

euring_codes <- readr::read_csv(system.file("extdata", "EURINGSpeciesCodesMay2024.csv", package = "metadata", mustWork = TRUE),
                                show_col_types = FALSE) |>
  dplyr::mutate("EURING_Code" = stringr::str_pad(.data$EURING_Code, side = "left", pad = "0", width = 5))

#' EUNIS habitat codes
#'
#' Habitat classification (version 2012) according to the European Nature Information System (EUNIS). EUNIS habitat classification is hierarchical (up to eight levels).
#'
#' @format A data frame
#' \describe{
#'      \item{habitatID}{Identifier for the habitat as provided by EUNIS.}
#'      \item{habitatLevel}{Hierarchical level for the habitat as provided by EUNIS. Options: 1-8}
#'      \item{habitatType}{Name or short description for the habitat as proved by EUNIS.}
#'      \item{habitatDetails}{Detailed description or definition for the habitat as provided by EUNIS.}
#' }
#' @name habitat_codes

habitat_codes <- readr::read_csv(system.file("extdata", "habitat_codes.csv", package = "metadata", mustWork = TRUE),
                                 show_col_types = FALSE)
