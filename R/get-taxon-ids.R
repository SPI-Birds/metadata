#' Retrieve taxonomic classification, ids, and common names for a (sub)species
#'
#' Get identifiers from the \href{https://www.gbif.org/dataset/d7dddbf4-2cf0-4f39-9b2a-bb099caae36c}{GBIF Backbone Taxonomy}, \href{https://eol.org/}{Encyclopedia of Life}(EOL), \href{https://www.catalogueoflife.org/}{Catalogue of Life}(COL), the \href{https://www.itis.gov/}{Integrated Taxonomic Information System}(ITIS), and \href{https://euring.org/data-and-codes/euring-databank-species-index}{EURING} where available.
#'
#' Only used within \link{convert_to_eml}.
#'
#' @param species The scientific name of the species or subspecies. Format: '<genus> <specific epithet>' (e.g., 'Parus major') or '<genus> <specific epithet> <subspecific epithet>' (e.g., 'Limosa limosa limosa').
#'
#' @returns a data frame with the taxonomic classification of the (sub)species and the associated ids of each rank in the classification. The data frame has 4 columns: name (taxon name), rank (taxon rank), id (taxon id), and db (the url to the database from which the record is retrieved).
#'
#' @import taxize
#' @importFrom jsonlite fromJSON
#' @importFrom httr GET content
#' @importFrom WikidataQueryServiceR query_wikidata

get_taxon_ids <- function(species) {

  # Get expected rank (species or subspecies) of input
  nomen <- stringr::str_split_1(species, pattern = " ")
  expected_rank <- ifelse(length(nomen) == 2, "species", "subspecies")

  # Ensure that provided input is the scientific name of a species
  gbif_usage <- taxize::gbif_name_usage(name = species)

  if(length(gbif_usage$results) > 0) {

    # Get IDs
    # - GBIF Backbone Taxonomy ID
    gbif <- taxize::get_gbifid_(sci = species) %>%
      dplyr::bind_rows() %>%
      dplyr::filter(.data$status == "ACCEPTED" & .data$matchtype == "EXACT")

    if(nrow(gbif) == 0) {

      gbif_synonym <- taxize::get_gbifid_(sci = species) %>%
        dplyr::bind_rows() %>%
        dplyr::filter(.data$status == "SYNONYM" & .data$matchtype == "EXACT")

      message("\nThis taxon is marked as 'SYNONYM' by GBIF.")
      message("\nEnter row number to select a taxon:\n")
      print(gbif_synonym)
      take <- scan(n = 1, quiet = TRUE, what = "raw")

      gbif_key <- gbif_synonym |>
        dplyr::slice(as.numeric(take)) |>
        dplyr::select("usagekey", "status")

    } else if(nrow(gbif) > 1){

      message("\nEnter row number to select a taxon:\n")
      print(gbif)
      take <- scan(n = 1, quiet = TRUE, what = "raw")

      gbif_key <- gbif |>
        dplyr::slice(as.numeric(take)) |>
        dplyr::select("usagekey", "status")

    } else {

      gbif_key <- gbif |>
        dplyr::select("usagekey", "status")

    }

    # - EOL page ID
    eol <- taxize::get_eolid(sci_com = species,
                             data_source = "EOL.*2022")

    if(length(eol) == 0) {

      eol <- NULL

    }

    # - COL ID
    if(expected_rank == "species") {

      col <- httr::GET(paste0("https://api.checklistbank.org/dataset/3LR/match/nameusage?q=",
                              stringr::str_replace(species, " ", "+"))) |>
        httr::content()

      if(col$match == FALSE) {

        col <- NULL

      }

    } else if(expected_rank == "subspecies") {

      col <- NULL

    }

    # - ITIS TSN
    tsn <- taxize::get_tsn(sci = species, accepted = TRUE, ask = FALSE)

    if(is.na(tsn)) {

      tsn <- NULL

    }

    # - EURING code
    if(species %in% euring_codes$Current_Name) {

      euring <- tibble::tibble(
        "name" = species[species %in% euring_codes$Current_Name],
        "rank" = expected_rank,
        "id" = euring_codes %>%
          dplyr::filter(Current_Name == name) %>%
          dplyr::pull("EURING_Code"),
        "db" = "https://euring.org"
      )

    } else { # Skip for species not in EURING

      euring <- NULL

    }

    # Get taxonomic classifications
    # - GBIF
    gbif_class <- rbind(taxize::classification(gbif_key$usagekey, db = "gbif")) %>%
      dplyr::mutate("db" = "https://www.gbif.org",
                    "id" = as.character(.data$id))

    if(gbif_key$status == "SYNONYM") {

      gbif_class <- gbif_class |>
        dplyr::slice(1:(dplyr::n()-1)) |>
        dplyr::add_row(
          name = species,
          rank = gbif_class |> dplyr::slice_tail(n = 1) |> dplyr::pull(rank),
          id = as.character(gbif_key$usagekey),
          query = as.character(gbif_key$usagekey),
          db = "https://www.gbif.org"
        )

    }

    # - EOL
    if(!is.null(eol)) {

      eol_class <- tibble::tibble(
        "name" = species,
        "rank" = expected_rank,
        "id" = attributes(eol)$pageid,
        "db" = "https://eol.org"
      )

    } else {

      eol_class <- NULL

    }

    # - COL
    if("usage" %in% names(col)) {

      col_class <- dplyr::bind_rows(col$usage$classification) %>%
        dplyr::select("name", "rank", "id") %>%
        dplyr::add_row("name" = col$usage$name,
                       "rank" = col$usage$rank,
                       "id" = col$usage$id) %>%
        dplyr::mutate("db" = "https://www.catalogueoflife.org")

    } else { # Skip for (sub)species not in COL

      col_class <- NULL

    }

    # - ITIS
    if(!is.null(tsn)) {

      itis_class <- rbind(taxize::classification(tsn, db = "itis")) %>%
        dplyr::mutate("db" = "https://www.itis.gov")

    } else {

      itis_class <- NULL

    }

    # Combine ids, names and classifications
    # Only include the ranks 'kingdom', 'phylum', 'class', 'order', 'family', 'genus', and 'species'
    species_df <- dplyr::bind_rows(gbif_class, col_class, eol_class, itis_class, euring) %>%
      dplyr::select(-"query") %>%
      dplyr::filter(.data$rank %in% c("kingdom", "phylum", "class", "order",
                                      "family", "genus", "species", "subspecies")) |>
      dplyr::mutate(status = dplyr::case_when(.data$rank == {{expected_rank}} & .data$name == {{species}} ~ "accepted",

                                              TRUE ~ NA))

    return(species_df)

    # If (sub)species name cannot be found, return NULL
  } else {

    return(NULL)

  }

}


#' Create EML's hierarchical taxonomy and refer to relevant taxon ids where available
#'
#' Per studied species, this function will create a nested taxonomy including kingdom, phylum, class, order, family, genus, species
#'
#' Only used within \link{convert_to_eml}.
#'
#' @param taxa list of taxonomic names, ranks and ids per species
#' @importFrom stringr str_to_sentence
#' @importFrom WikidataQueryServiceR query_wikidata

create_nested_taxonomy <- function(taxa) {

  if(length(taxa) > 1) {

    list(
      "taxonRankName" = taxa[[1]][1,]$rank,
      "taxonRankValue" = taxa[[1]][1,]$name,
      "taxonId" = purrr::map(.x = seq_len(nrow(taxa[[1]])),
                             .f = ~{

                               list(provider = taxa[[1]][.x,]$db,
                                    taxonId = taxa[[1]][.x,]$id)

                             }),
      "taxonomicClassification" = create_nested_taxonomy(taxa[-1])
    )

  } else {

    # Query common name from Wikidata
    commonQuery <- paste0('
      SELECT
        ?item ?common_name
        WHERE {
          ?item wdt:P225', '"', taxa[[1]][1,]$name, '"', ';
                wdt:P1843 ?common_name.

        FILTER(LANGMATCHES(LANG(?common_name), "en"))

        SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }}
      ')

    commonName <- WikidataQueryServiceR::query_wikidata(sparql_query = commonQuery,
                                                        format = "smart") |>
      dplyr::pull("common_name") |>
      stringr::str_to_sentence() |>
      unique()

    list(
      "taxonRankName" = taxa[[1]][1,]$rank,
      "taxonRankValue" = taxa[[1]][1,]$name,
      "commonName" = commonName,
      "taxonId" = purrr::map(.x = seq_len(nrow(taxa[[1]])),
                             .f = ~{

                               list(provider = taxa[[1]][.x,]$db,
                                    taxonId = taxa[[1]][.x,]$id)

                             })
    )

  }

}
