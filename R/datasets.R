#' List of EUNIS habitats
#'
#' SPI-Birds uses European Nature Information System (EUNIS) habitat classification scheme (version 2012, with major updates in 2022) for describing the habitat at a location. The EUNIS classification is hierarchical (up to eight levels), indicated by the length of characters. Data custodians are asked to provide the highest level of detail when possible.
#' @format
#' \describe{
#'    \item{habitatID}{character indicating the habitat code.}
#'    \item{habitatLevel}{numeric indicating the hierarchical level (1 to 8) of the habitat code.}
#'    \item{habitatType}{character indicating the habitat name or title .}
#'    \item{habitatDetails}{character indicating a detailed description of a habitat, often including specific taxa or examples.}
#' }
#' @name habitats

habitats <- readr::read_csv(here::here("inst", "extdata", "habitats.csv"))
