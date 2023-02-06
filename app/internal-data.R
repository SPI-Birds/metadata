#' Countries and dependencies
#'
#' List of countries and dependencies.
#' @format A data frame with 249 rows, 2 columns
#' \describe{
#'    \item{id}{Two-letter ISO 3166-1 alpha-2 code for a country/dependency}
#'    \item{name}{Name of the country/dependency}
#' }
#' @name countries
#' @import tibble
#'

countries <- utils::read.csv("data/countries.csv") |>
  tibble::as_tibble()

#' SPI-Birds' species taxonomic ranks and codes
#'
#' Species information, including various taxonomic ranks, internal and external codes.
#' @format A data frame with 34 rows and 2 variables
#' \describe{
#'   \item{id}{SPI-Birds' internal persistent identifier for a species.}
#'   \item{name}{Binomial name (i.e., genus and specific epithet) of the species.}
#'   }
#'@name species_codes
#'@import dplyr
#'@import tidyr

species <- utils::read.csv("data/species.csv") |>
  tibble::as_tibble() |>
  dplyr::select(id = "speciesID", "genus", "specificEpithet") |>
  tidyr::unite("name", "genus", "specificEpithet", sep = " ") |>
  dplyr::arrange(.data$name)

#'Habitat types and descriptions
#'
#'Habitat descriptions according to European Nature Information System (EUNIS) \href{https://www.eea.europa.eu/data-and-maps/data/eunis-habitat-classification-1}{Habitats Classification Scheme} (version 2012).
#'
#'@format A data frame with 4185 rows and 2 variables
#'\describe{
#'  \item{id}{Identifier for the habitat as provided by EUNIS.}
#'  \item{name}{Identifier and name or short description for the habitat as proved by EUNIS.}
#'  }
#'@name habitats
#'@rdname habitats
#'@aliases habitatList

habitats <- utils::read.csv("data/habitats.csv") |>
  tibble::as_tibble() |>
  dplyr::select(id = "habitatID", "habitatType") |>
  tidyr::unite("name", "id", "habitatType", sep = ": ", remove = FALSE) |>
  dplyr::select(-"habitatType")

#'Habitat types and descriptions
#'
#'Habitat descriptions according to European Nature Information System (EUNIS) \href{https://www.eea.europa.eu/data-and-maps/data/eunis-habitat-classification-1}{Habitats Classification Scheme} (version 2012).
#'
#'@format A data frame with 4185 rows and 2 variables
#'\describe{
#'  \item{id}{Identifier for the habitat as provided by EUNIS.}
#'  \item{name}{Identifier and name or short description for the habitat as proved by EUNIS.}
#'  }
#'@name habitatList
#'@rdname habitats

habitatList <- as.list(habitats$id)
names(habitatList) <- habitats$name

#' Licenses
#'
#' Data owner licenses that describe the terms under which their data can be used.
#' @format A data frame with 1 rows and 2 variables
#'\describe{
#'  \item{id}{Identifier for the license.}
#'  \item{name}{Name or short description for the license.}
#'  }
#' @name licenses

licenses <- tibble::tibble(id = c(1),
                           name = c("dummy"))

#' Required fields
#'
#' Metadata fields that the data owner are required to fill in; i.e., the minimal adequate metadata.
#' @format A vector of 17 field names
#' @name requiredFields

requiredFields <- c("creator_organizationName",
                    "creator_city",
                    "creator_postalCode",
                    "creator_country",
                    "metadataProvider_givenName",
                    "metadataProvider_surName",
                    "metadataProvider_positionName",
                    "metadataProvider_electronicMailAddress",
                    "intellectualRights",
                    "maintenanceUpdateFrequency",
                    "geographicCoverage_altitudeMinimum",
                    "geographicCoverage_altitudeMaximum",
                    "temporalCoverage_beginDate",
                    "taxonomicCoverage",
                    "studyAreaDescription_habitat",
                    "methods_individualDataTypes",
                    "methods_broodDataTypes")

#' Individual data types
#'
#' Variables monitored at the individual level that might be collected in a study site.
#' @format A vector of 8 variables
#' @name individualDataTypes

individualDataTypes <- c("age", "immigration status", "size (weight, wing, tarsus, etc.)", "plumage characteristics", "parasites", "feeding", "personality scores", "physiological data") |> sort()

#' Brood data types
#'
#' Variables monitored at the brood level that might be collected in a study site.
#' @format A vector of 7 variables
#' @name broodDataTypes

broodDataTypes <- c("clutch size", "clutch type", "brood size", "fledgling number", "lay date", "hatch date", "fledge date") |> sort()

#' Tag types
#'
#' Types of tags that might be applied to individuals such that they can be individually recognized.
#' @format A vector of 9 variables
#' @name tagTypes

tagTypes <- c("metal leg ring", "coloured leg ring", "coloured neck ring", "coloured wing tag", "radio-tracking device", "transponder", "nasal mark", "GPS logger") |> sort()

#' Genetic data types
#'
#' Samples that might be taken of individuals in a study site to be used in genetic analyses.
#' @format A vector of 2 variables
#' @name geneticDataTypes

geneticDataTypes <- c("blood", "feather") |> sort()

#' Environmental data types
#'
#' Environmental data types that might be monitored in a study site.
#' @format A vector of 5 variables
#' @name environmentalDataTypes

environmentalDataTypes <- c("predation", "vegetation", "temperature", "rainfall", "food availability") |> sort()

#' Other monitoring activities
#'
#' Other activities that might be conducted at a study site.
#' @format A vector of 3 variables
#' @name otherActivities

otherActivities <- c("roosting checks", "winter tagging", "experimental manipulations") |> sort()
