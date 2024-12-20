#' Retrieve taxonomic classification, ids, and common names for a species
#'
#' Get identifiers from the \href{https://www.gbif.org/dataset/d7dddbf4-2cf0-4f39-9b2a-bb099caae36c}{GBIF Backbone Taxonomy}, \href{https://eol.org/}{Encyclopedia of Life}(EOL), \href{https://www.catalogueoflife.org/}{Catalogue of Life}(COL), the \href{https://www.itis.gov/}{Integrated Taxonomic Information System}(ITIS), and \href{https://euring.org/data-and-codes/euring-databank-species-index}{EURING} where available.
#'
#' Only used within \link{convert_to_eml}.
#'
#' @param species The scientific name of the species. Format: '<genus> <specific epithet>'. For example, 'Parus major'.
#'
#' @returns a data frame with the taxonomic classification of the species and the associated ids of each rank in the classification. The data frame has 4 columns: name (taxon name), rank (taxon rank), id (taxon id), and db (the url to the database from which the record is retrieved).
#'
#' @import taxize
#' @importFrom jsonlite fromJSON
#' @importFrom httr GET content
#' @importFrom WikidataQueryServiceR query_wikidata

get_taxon_ids <- function(species) {

  # Ensure that provided input is the scientific name of a species
  species_name <- taxize::tax_name(sci = species,
                                   get = "species") |>
    dplyr::pull("species")

  if(!is.na(species_name)) {

    # Get IDs
    # - GBIF Backbone Taxonomy ID
    gbif <- taxize::get_gbifid_(sci = species_name) %>%
      dplyr::bind_rows() %>%
      dplyr::filter(.data$status == "ACCEPTED" & .data$matchtype == "EXACT") %>%
      dplyr::pull("usagekey")

    # - EOL page ID
    eol <- taxize::get_eolid(sci_com = species_name,
                             data_source = "EOL.*2022", rank = "species")

    # - COL ID
    col <- httr::GET(paste0("https://api.checklistbank.org/dataset/3LR/match/nameusage?q=",
                            stringr::str_replace(species_name, " ", "+"))) |>
      httr::content()

    # - ITIS TSN
    tsn <- taxize::get_tsn(sci = species_name)

    # - EURING code
    if(species_name %in% euring_codes$Current_Name) {

      euring <- tibble::tibble(
        "name" = species_name,
        "rank" = "species",
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
    gbif_class <- rbind(taxize::classification(gbif, db = "gbif")) %>%
      dplyr::mutate("db" = "https://www.gbif.org",
                    "id" = as.character(.data$id))

    # - EOL
    eol_class <- tibble::tibble(
      "name" = species_name,
      "rank" = "species",
      "id" = attributes(eol)$pageid,
      "db" = "https://eol.org"
    )

    # - COL
    if("usage" %in% names(col)) {

      col_class <- dplyr::bind_rows(col$usage$classification) %>%
        dplyr::select("name", "rank", "id") %>%
        dplyr::add_row("name" = col$usage$name,
                       "rank" = col$usage$rank,
                       "id" = col$usage$id) %>%
        dplyr::mutate("db" = "https://www.catalogueoflife.org")

    } else { # Skip for species not in COL

      col_class <- NULL

    }

    # - ITIS
    itis_class <- rbind(taxize::classification(tsn, db = "itis")) %>%
      dplyr::mutate("db" = "https://www.itis.gov")

    # Combine ids, names and classifications
    # Only include the ranks 'kingdom', 'phylum', 'class', 'order', 'family', 'genus', and 'species'
    species_df <- dplyr::bind_rows(gbif_class, col_class, eol_class, itis_class, euring) %>%
      dplyr::select(-"query") %>%
      dplyr::filter(.data$rank %in% c("kingdom", "phylum", "class", "order",
                                      "family", "genus", "species"))

    return(species_df)

    # If species name cannot be found, return NULL
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
