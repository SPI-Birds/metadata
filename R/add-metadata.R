#' Add or update processed metadata to SPI-Birds metadata tables
#'
#' Store studyID, siteID, siteName, custodianName, country and geographic coordinates in the SPI-Birds metadata tables (\link{site_codes}, \link{study_codes}, \link{species_codes}).
#'
#' @param meta List output of \link{convert_to_eml}.
#'
#' @importFrom ISOcodes ISO_3166_1
#' @importFrom tibble add_row
#' @importFrom readr write_csv
#' @importFrom here here
#' @export

add_metadata <- function(meta) {

  # Save current tables to archive
  readr::write_csv(study_codes, file = here::here("inst", "extdata", "archive", "study_codes.csv"))
  readr::write_csv(site_codes, file = here::here("inst", "extdata", "archive", "site_codes.csv"))
  readr::write_csv(species_codes, file = here::here("inst", "extdata", "archive", "species_codes.csv"))

  # Check that the metadata info is correctly processed
  cat(paste0("Registered studyID for this metadata entry: ", meta$studyID, "\n"))
  cat(paste0("Registered studyUUID for this metadata entry: ", meta$studyUUID, "\n"))
  cat(paste0("Registered siteID for this metadata entry: ", meta$siteID, "\n"))

  # Assign custodian ID
  newCustodianID <- assign_custodianID(meta)

  # Add or update study metadata
  if(meta$studyID %in% study_codes$studyID) {

    study_codes <- study_codes %>%
      dplyr::mutate(custodianID = dplyr::case_when(studyID == meta$studyID ~ newCustodianID,
                                                   TRUE ~ custodianID),
                    custodianName = dplyr::case_when(studyID == meta$studyID ~ meta$custodianName,
                                                     TRUE ~ custodianName),
                    data = dplyr::case_when(studyID == meta$studyID ~ primaryData,
                                            TRUE ~ data),
                    standardFormat = dplyr::case_when(studyID == meta$studyID ~ formattedData,
                                                      TRUE ~ standardFormat))

  } else {

    study_codes <- study_codes %>%
      tibble::add_row(
        studyID = meta$studyID,
        studyUUID = meta$studyUUID,
        siteID = meta$siteID,
        custodianID = newCustodianID,
        custodianName = meta$custodianName,
        data = primaryData,
        standardFormat = formattedData
      )

  }

  # Add or update site metadata
  if(meta$siteID %in% site_codes$siteID) {

    site_codes <- site_codes %>%
      dplyr::mutate(decimalLatitude = dplyr::case_when(siteID == meta$siteID ~ meta$lat,
                                                       TRUE ~ decimalLatitude),
                    decimalLongitude = dplyr::case_when(siteID == meta$siteID ~ meta$lon,
                                                        TRUE ~ decimalLongitude))

  } else {

    # Retrieve ISO-3166-1-alpha-2 code for study country
    if(meta$country %in% ISOcodes::ISO_3166_1$Name) {

      countryCode <-ISOcodes::ISO_3166_1 %>%
        dplyr::filter(Name == meta$country) %>%
        dplyr::pull("Alpha_2")

    } else {

      countryCode <- ISOcodes::ISO_3166_1 %>%
        dplyr::filter(stringr::str_detect(Name, meta$country)) %>%
        dplyr::pull("Alpha_2")

    }

    site_codes <- site_codes %>%
      tibble::add_row(
        siteID = meta$siteID,
        siteName = meta$siteName,
        country = meta$country,
        countryCode = countryCode,
        decimalLatitude = meta$lat,
        decimalLongitude = meta$lon,
        locationAccordingTo = "metadataProvider"
      )

  }

  # Add new species metadata to species codes table
  taxa <- purrr::map(.x = taxx,
                     .f = ~{
                       species_name <- .x |>
                         dplyr::filter(rank == "species") |>
                         dplyr::distinct(name) |>
                         dplyr::pull(name)

                       if(!(species_name %in% species_codes$scientificName)) {

                         output <- .x

                       } else {

                         output <- NULL

                       }

                       return(output)

                     }) |>
    purrr::keep(~!is.null(.x))

  if(length(taxa) != 0) {

    species_codes <- dplyr::add_species(taxa)

  }

  # Save new tables
  readr::write_csv(study_codes, file = here::here("inst", "extdata", "study_codes.csv"))
  readr::write_csv(site_codes, file = here::here("inst", "extdata", "site_codes.csv"))
  readr::write_csv(species_codes, file = here::here("inst", "extdata", "species_codes.csv"))

}

#' Manually assign an ID for the custodian
#'
#' Pick an ID for the custodian of a new metadata entry. custodianIDs are often based on abbreviations of the organisation.
#' For example, 'LDZ' is the custodianID for 'University of Lodz' and 'TRN' is the custodianID for 'University of Turin'.
#' The function checks whether the provided ID is already assigned to another study, and will ask you whether you wish to assign the
#' same custodian to the new entry, or otherwise, pick a new unique ID.
#'
#' Only used within \link{add_metadata}.
#'
#' @param meta List output of \link{convert_to_eml}.
#'

assign_custodianID <- function(meta) {

  cat(paste0("Registered custodianName for this metadata entry: ", meta$custodianName, "\n"))
  custodianID <- readline("Please provide a custodianID associated with this custodianName: ")

  if(custodianID %in% study_codes$custodianID) {

    custodian_check <- menu(choices = c("Yes", "Provide a new ID"),
                            title = "This custodianID already exists. Do you wish to add this custodianID to this metadata entry?")

    if(custodian_check == 2) {

      custodianID <- readline("Please provide a new custodianID: ")

    }

  }

  return(custodianID)

}

#' Create new species entry to SPI-Birds
#'
#' Create new species entry for the SPI-Birds species code table (\link{species_codes}).
#'
#' Taxon ids are generated through \link{get_taxon_ids} as part of \link{convert_to_eml}. This function generates SPI-Birds internal ids. `speciesCode` is a running number; `specisID` is a 6-letter code created from the first three letters of the genus and thre first three letters of the specific epithet. If this code already exists, the user is prompted to provide a unique code. Vernacular names are taken from Wikidata and GBIF; if multiple English vernacular names are in use, the user is prompted to pick one. Tip: use the Common Names section of a taxon on EOL to find the 'preferred name'.
#'
#' Only used within \link{add_metadata}.
#'
#' @param taxa List of taxa, eq of list output of \link{convert_to_eml}.
#'
#' @returns A data frame with a number of rows equal to the number of species to be added, and variables equal to the structure of \link{species_codes}.

add_species <- function(meta) {

  # Pivot taxononic classification from convert_to_eml() to wide format of species_codes
  species_ids <- dplyr::bind_rows(taxa) |>
    dplyr::filter(rank == "species") |>
    dplyr::mutate(db = dplyr::case_when(db == "https://www.gbif.org" ~ "speciesGBIFID",
                                        db == "https://www.catalogueoflife.org" ~ "speciesCOLID",
                                        db == "https://eol.org" ~ "speciesEOLpageID",
                                        db == "https://www.itis.gov" ~ "speciesTSN",
                                        db == "https://euring.org" ~ "speciesEURINGCode")) |>
    tidyr::pivot_wider(values_from = "id",
                       names_from = "db") |>
    dplyr::mutate(speciesEOLpageID = as.numeric(speciesEOLpageID),
                  speciesTSN = as.numeric(speciesTSN)) |>
    dplyr::rename("scientificName" = "name") |>
    dplyr::select(-"rank")

  # Add missing info authorship & vernacular name
  species <- species_ids |>
    dplyr::mutate(scientificNameAuthorship = purrr::map_chr(.x = speciesGBIFID,
                                                            .f = ~{

                                                              authorship <- taxize::gbif_name_usage(.x)$authorship
                                                              stringr::str_remove_all(authorship, "\\(|\\)|\\)\\s|\\s$")

                                                            }),
                  vernacularName = purrr::map_chr(.x = scientificName,
                                                  .f = ~{

                                                    get_vernacular_name(.x)

                                                  })) |>
    # Add internal speciesCode and speciesID
    dplyr::mutate(speciesCode = max(species_codes$speciesCode) + dplyr::row_number(),
                  # Create internal speciesID
                  # - Format: first three letters of genus + first three letters of specific epithet
                  # - If this combination of letters already exist, ask user to provide one.
                  speciesID = purrr::map_chr(.x = scientificName,
                                             .f = ~{

                                               species_id <- stringr::str_split_1(string = .x, pattern = " ") |>
                                                 stringr::str_sub_all(start = 1, end = 3) |>
                                                 unlist() |>
                                                 paste(collapse = "") |>
                                                 toupper()

                                               if(species_id %in% species_codes$speciesID) {

                                                 species_id <- readline(paste0("The speciesID ", species_id,
                                                                               " already exists. Provide a new one: "))

                                                 species_id <- toupper(species_id)

                                               }

                                               return(species_id)

                                             }))

  output <- dplyr::bind_rows(species_codes, species)

  return(output)

}

#' Get English vernacular name of a species
#'
#' Get English vernacular name of a species from Wikidata and GBIF Backbone Taxonomy. If multiple vernacular names are used, the user is prompted to select one. If neither Wikidata nor GBIF provides a common name, user is prompted to select EOL common name.
#'
#' Only used within \link{add_species}, and with that, \link{add_metadata}.
#'
#' @param species The scientific name of the species. Format: '<genus> <specific epithet>'. For example, 'Parus major'.

get_vernacular_name <- function(species) {

  # Get GBIF vernacular name
  gbif_vern <- stringr::str_to_sentence(taxize::gbif_name_usage(name = species)$vernacularName)

  # Query common name from Wikidata
  common_query <- paste0('
                        SELECT
                          ?item ?common_name ?label
                          WHERE {
                            ?item wdt:P225', '"', species, '"', ';
                                  wdt:P1843 ?common_name;
                                  rdfs:label ?label.

                          FILTER(LANGMATCHES(LANG(?common_name), "en"))
                          FILTER(LANGMATCHES(LANG(?label), "en"))

                          SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }}
                        ')

  common_name <- WikidataQueryServiceR::query_wikidata(sparql_query = common_query,
                                                       format = "smart") |>
    dplyr::mutate(common_name = stringr::str_to_sentence(common_name),
                  label = stringr::str_to_sentence(label)) |>
    dplyr::pull(common_name) |>
    unique()

  # If there are multiple vernacular names...
  if(length(common_name) > 1) {

    # Select name that matches the vernacular name used in GBIF
    if(any(common_name %in% gbif_vern)) {

      output <- gbif_vern

      # Else, prompt user to select one
    } else {

      selected <- utils::menu(choices = common_name,
                              title = "Which vernacular name to use")

      output <- common_name[selected]

    }

    # If Wikidata has no common name, use GBIF
  } else if(length(common_name) == 0) {

    output <- gbif_vern

    # If GBIF has no common name, prompt user
  } else if(length(gbif_vern) == 0) {

    output <- readline("Enter preferred name according to EOL: ")

  } else {

    output <- common_name

  }

  return(output)

}
