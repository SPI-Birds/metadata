#' Process metadata submission and format following the Ecological Metadata Language
#'
#' The Ecological Metadata Language (EML) defines a comprehensive vocabulary and XML markup
#' for documenting research data in the fields of ecology and environmental sciences. EML
#' is the standard used by SPI-Birds to structure metadata of studies and associated datasets.
#'
#' @param email Character indicating the email address with which you have access to the SPI-Birds metadata sheet
#'
#' @returns an EML.xml from the submitted metadata, and a list with metadata fields (i.e., studyID, siteID, siteName, custodianName, country, geographic coordinates,and taxonomic coverage) that are stored in the metadata tables (`R/datasets.R`)
#'
#' @import dplyr
#' @importFrom lubridate year
#' @importFrom tidyselect where
#' @importFrom forcats fct_relevel
#' @importFrom magrittr %>%
#' @importFrom purrr map
#' @importFrom tibble tibble
#' @importFrom uuid UUIDgenerate
#' @importFrom stats na.omit
#' @importFrom utils menu
#' @importFrom rlang .data
#' @importFrom stringi stri_remove_empty
#' @importFrom rcrossref cr_cn
#' @export

convert_to_eml <- function(email) {

  if(missing(email)) {

    stop("Please provide an email address with which you have access to the SPI-Birds metadata sheet.")

  }

  # Load metadata from Google Drive
  metadata <- read_metadata(email = email)

  # Select metadata entry
  # - Last submitted: the most recently submitted entry
  # - Last updated: the most recently updated entry
  # - Row number in Google Sheet of the metadata entry
  selectedEntry <- utils::menu(choices = c("Last submitted",
                                           "Last updated",
                                           "Select metadata entry by row number"),
                               title = "Which metadata entry do you wish to convert to EML?")

  if(selectedEntry == 3) {

    rowNumber <- as.numeric(readline("Enter the row number of the Google Sheet record: "))

    entry <- metadata %>%
      dplyr::slice({rowNumber})

  } else if(selectedEntry == 1) {

    entry <- metadata %>%
      dplyr::arrange(.data$submissionDate) %>%
      dplyr::slice(dplyr::n())

  } else if(selectedEntry == 2) {

    entry <- metadata %>%
      dplyr::filter(!is.na(.data$lastUpdateDate)) %>%
      dplyr::arrange(.data$lastUpdateDate) %>%
      dplyr::slice(dplyr::n())

  }

  # Set any character string "NA" (explicitly filled in by the metadata provider) to the logical constant NA
  entry <- entry |>
    dplyr::mutate(dplyr::across(.cols = tidyselect::where(is.character),
                                .fns = ~dplyr::na_if(., "NA")))

  ## EML sections

  # <endDate>
  # Set end year to current year if project is missing and ongoing.
  if(is.na(entry$temporalCoverage_endDate)) {

    endYear <- paste0(lubridate::year(max(c(entry$submissionDate, entry$lastUpdateDate), na.rm = TRUE)), " (ongoing)")

  } else {

    endYear <- entry$temporalCoverage_endDate

  }

  # <title>
  # Description of data collected, research site and time frame
  title <- list(paste0("Field study of bird breeding ecology at ",
                       entry$studySiteName, ", ", entry$studySiteCountry,
                       " from ", entry$temporalCoverage_beginDate, " to ", endYear, "."))


  # <shortName>
  # A concise name that describes the resource; here we use it to display the studyID
  study_ids <- set_study_site_ids(entry)

  # Return registered siteID & studyID
  cat(paste0("Registered siteID for this metadata entry: ", study_ids$siteID, "\n"))
  cat(paste0("Registered studyID for this metadata entry: ", study_ids$studyID, "\n"))

  shortName <- list(study_ids$studyID)

  # <abstract>
  abstractBody = paste0(study_ids$studyID,
                        " is a field study of the breeding ecology of individually-marked birds at ",
                        entry$studySiteName, ", ", entry$studySiteCountry,
                        " from ", entry$temporalCoverage_beginDate, " to ", endYear, ".")

  # Mention 'nest box' if nest boxes are used in the study
  if(!is.na(entry$studyAreaDescription_nestboxes)) {

    abstractSiteType <- "The field study uses nest boxes to monitor brood-level and individual-level information."

  } else {

    abstractSiteType <-  "The field study monitors brood-level and individual-level information."

  }

  # Add data custodian to abstract
  abstractCustody <- paste0("The field study is administered by ", entry$creator_organizationName, ".")

  abstract <- list(para = paste(abstractBody,
                                abstractSiteType,
                                abstractCustody))


  # <creator>
  # Responsible Party in Jotform
  # Creator can be a person or an organization who is responsible for taking care of the data

  if(entry$creator_entity == "a person") {

    # Verify whether the email address may be displayed
    if(entry$creator_displayElectronicMailAddress == "Yes") {

      creatorEmail <- entry$creator_electronicMailAddress

    } else if(entry$creator_displayElectronicMailAddress == "No") {

      creatorEmail <- NULL

    }

    # Add ORCID if available
    if(!is.na(entry$creator_userId)) {

      user_id <- list(directory = "https://orcid.org/",
                      userId = entry$creator_userId)

    } else {

      user_id <- NULL

    }

    creator <- list(individualName = list(givenName = entry$creator_givenName,
                                          surName = entry$creator_surName),
                    electronicMailAddress = creatorEmail,
                    userId = user_id,
                    organizationName = entry$creator_organizationName,
                    address = list(city = entry$creator_city,
                                   administrativeArea = entry$creator_administrativeArea,
                                   postalCode = entry$creator_postalCode,
                                   country = entry$creator_country))

  } else if(entry$creator_entity == "an organization") {

    creator <- list(organizationName = entry$creator_organizationName,
                    address = list(city = entry$creator_city,
                                   administrativeArea = entry$creator_administrativeArea,
                                   postalCode = entry$creator_postalCode,
                                   country = entry$creator_country))

  }

  # Assign node id
  # node ids can be used to refer to other nodes when nodes are identical.
  # e.g., if creator = metadataProvider, the info is stored in creator,
  # and metadataProvider refers to creator using the associated node id
  creator <- c(creator,
               id = "creator-1",
               scope = "document")

  # <metadataProvider>
  # The person who provided the metadata

  # Create metadataProvider if creator != metadataProvider
  # Else refer to node id of creator
  if(!is.na(entry$metadataProvider_entity) & entry$metadataProvider_entity == "someone else" | entry$creator_entity == "an organization") {

    # Verify whether the email address may be displayed
    if(entry$metadataProvider_displayElectronicMailAddress == "Yes") {

      metadataProviderEmail <- entry$metadataProvider_electronicMailAddress

    } else if(entry$metadataProvider_displayElectronicMailAddress == "No") {

      metadataProviderEmail <- NULL

    }

    # Add ORCID if available
    if(is.na(entry$metadataProvider_userId) | entry$metadataProvider_userId == "") {

      meta_user_id <- NULL

    } else {

      meta_user_id <- list(directory = "https://orcid.org/",
                           userId = entry$metadataProvider_userId)

    }

    metadataProvider <- list(individualName = list(givenName = entry$metadataProvider_givenName,
                                                   surName = entry$metadataProvider_surName),
                             organizationName = entry$metadataProvider_organizationName,
                             electronicMailAddress = metadataProviderEmail,
                             userId = meta_user_id)

    # Assign node id
    metadataProvider <- c(metadataProvider,
                          id = "metadata-provider-1",
                          scope = "document")

  } else {

    metadataProvider <- list(references = creator$id)

  }

  # <contact>
  # The person to contact with questions about the use and/or interpretation of the data set

  # Case 1: Contact = Creator
  if(entry$contact_entity == "the same as the Responsible Party") {

    contact <- list(references = creator$id)

    # Case 2: Contact = Metadata Provider
  } else if(entry$contact_entity == "the same as the Metadata Provider") {

    # Case 2A: Contact = Metadata Provider = Responsible Party
    if(!is.null(metadataProvider$references)) {

      contact <- list(references = creator$id)

      # Case 2B: Contact = Metadata Provider != Responsible Party
    } else {

      contact <- list(references = metadataProvider$id)

    }

    # Case 3: Contact is new person
  } else if(entry$contact_entity == "someone other than above") {

    # Verify whether the email address may be displayed
    if(entry$contact_displayElectronicMailAddress == "Yes") {

      contactEmail <- entry$contact_electronicMailAddress

    } else if(entry$contact_displayElectronicMailAddress == "No") {

      contactEmail <- NULL

    }

    # Add ORCID if available
    if(is.na(entry$contact_userId) | entry$contact_userId == "") {

      contact_user_id <- NULL

    } else {

      contact_user_id <- list(directory = "https://orcid.org/",
                              userId = entry$contact_userId)

    }

    contact <- list(individualName = list(givenName = entry$contact_givenName,
                                          surName = entry$contact_surName),
                    organizationName = entry$metadataProvider_organizationName,
                    electronicMailAddress = contactEmail,
                    userId = contact_user_id)

    # Assign node id
    contact <- c(contact,
                 id = "contact-1",
                 scope = "document")

  }

  # <intellectualRights>
  # only if data are or will be submitted
  if(entry$data_submitted == "Yes") {

    intellectualRights <- list(para = licenses[licenses$license == entry$intellectualRights,]$description)

  } else {

    intellectualRights <- NULL

  }

  # <maintenance>
  # expected update frequency of data
  maintenanceUpdateFrequency <- ifelse(entry$maintenanceUpdateFrequency == "as needed", "asNeeded", entry$maintenanceUpdateFrequency)

  maintenance <- list(description = list(para = ""),
                      maintenanceUpdateFrequency = maintenanceUpdateFrequency)

  # <temporalCoverage>
  beginDate <- entry$temporalCoverage_beginDate
  endDate <- entry$temporalCoverage_endDate

  if(is.na(endDate)) endDate <- lubridate::year(max(c(entry$submissionDate, entry$lastUpdateDate), na.rm = TRUE))

  # <geographicCoverage>
  # geographic description + bounding box or centroid
  geographicDescription <- paste(entry$studySiteName, entry$studySiteCountry, sep = ", ")

  if(entry$geographicCoverage_coordinates == "the four margins (N, S, E, W) of a bounding box") {

    westBoundingCoordinate <- entry$geographicCoverage_westBoundingCoordinate
    eastBoundingCoordinate <- entry$geographicCoverage_eastBoundingCoordinate
    northBoundingCoordinate <- entry$geographicCoverage_northBoundingCoordinate
    southBoundingCoordinate <- entry$geographicCoverage_southBoundingCoordinate

  } else if(entry$geographicCoverage_coordinates == "a centre point") {

    westBoundingCoordinate <- entry$geographicCoverage_longitude
    eastBoundingCoordinate <- entry$geographicCoverage_longitude
    northBoundingCoordinate <- entry$geographicCoverage_latitude
    southBoundingCoordinate <- entry$geographicCoverage_latitude

  }

  # altitude
  # Can only be added to EML when both are provided
  if(any(is.na(entry$geographicCoverage_altitudeMinimum),
         is.na(entry$geographicCoverage_altitudeMaximum))) {

    altitudeMinimum <- NULL
    altitudeMaximum <- NULL
    altitudeUnits <- NULL

  } else {

    altitudeMinimum <- entry$geographicCoverage_altitudeMinimum
    altitudeMaximum <- entry$geographicCoverage_altitudeMaximum
    altitudeUnits <- "meter"

  }

  # <coverage>
  # an umbrella term covering temporal coverage, geographic coverage
  # and taxonomic coverage (which is added below)
  coverage <- EML::set_coverage(beginDate = beginDate,
                                endDate = endDate,
                                geographicDescription = geographicDescription,
                                westBoundingCoordinate = westBoundingCoordinate,
                                eastBoundingCoordinate = eastBoundingCoordinate,
                                northBoundingCoordinate = northBoundingCoordinate,
                                southBoundingCoordinate = southBoundingCoordinate,
                                altitudeMinimum = altitudeMinimum,
                                altitudeMaximum = altitudeMaximum,
                                altitudeUnits = altitudeUnits)

  # <taxonomicCoverage>
  # Select listed species
  # NB: May be NA when study only monitors non-listed species
  if(!is.na(entry$taxonomicCoverage)) {

    listedSpecies <- stringr::str_split_1(entry$taxonomicCoverage, "\r\n")

  } else {

    listedSpecies <- NULL

  }

  # Select species added manually by metadata provider
  # NB: May be NA when study only monitors listed species
  if(!is.na(entry$otherTaxonomicCoverage)) {

    otherSpecies <-  stringr::str_split_1(entry$otherTaxonomicCoverage, "\r\n|\\s*(\r\n)+| \\| ")

  } else {

    otherSpecies <- NULL

  }

  # Concatenate listed and new species
  # NB: it should not possible that both are empty
  species <- c(listedSpecies, otherSpecies)

  # Retrieve taxonomic classification, ids, and common names
  # NB: might take a while because the EOL server is often slow
  taxon_ids <- purrr::map(.x = species,
                          .f = ~{

                            get_taxon_ids(.x)

                          }) |>
    purrr::keep(~!is.null(.x))

  # Create nested taxonomy per species
  nested_taxa <- purrr::map(.x = purrr::map(.x = taxon_ids,
                                            .f = ~{

                                              .x %>%
                                                dplyr::group_by(rank_number = forcats::fct_relevel(.f = rank,
                                                                                                   c("kingdom", "phylum", "class", "order",
                                                                                                     "family", "genus", "species"))) %>%
                                                dplyr::group_split()

                                            }),
                            .f = ~{

                              create_nested_taxonomy(.x)

                            })

  # Add <taxonomicCoverage> to <coverage>
  coverage$taxonomicCoverage <- list(taxonomicClassification = nested_taxa)

  # <project>
  # <title>
  project_title <- title

  # <personnel>
  # Project Members in Jotform
  # People who have contributed to running the field study. Also refer to:
  # Creator, Metadata Provider, Contact

  person_refs <- tibble::tibble(
    id = character(),
    role = character()
  )

  if(entry$creator_entity == "a person") {

    person_refs <- person_refs %>%
      dplyr::add_row(
        id = creator$id,
        role = "dataCustodian"
      )

  }

  if(!is.null(metadataProvider$id)) {

    person_refs <- person_refs %>%
      dplyr::add_row(
        id = metadataProvider$id,
        role = "metadataProvider"
      )

  }

  if(!is.null(contact$id)) {

    person_refs <- person_refs %>%
      dplyr::add_row(
        id = contact$id,
        role = "pointOfContact"
      )

  }

  # Add as reference to <personnel>
  personnelReferences <- purrr::pmap(.l = list(person_refs$id,
                                               person_refs$role),
                                     .f = ~{

                                       list(references = ..1,
                                            role = ..2)

                                     })

  # Add other personnel, if provided
  if(!is.na(entry$personnel)) {

    # Separate info in list in case there are multiple persons
    otherPersonnel <- purrr::map(.x = stringr::str_split_1(entry$personnel, "\n"),
                                 .f = ~{

                                   # Split info per person
                                   person_info <- stringr::str_split_1(string = .x,
                                                                       pattern = "^([^:]*):\\s|,\\s([^:]*):\\s|,\\s([^:]*):")[-1]

                                   # Verify whether the email address may be displayed
                                   if(person_info[5] == "Yes") {

                                     personEmail <- person_info[4]

                                   } else if(person_info[5] == "No") {

                                     personEmail <- NULL

                                   }

                                   if(person_info[7] == "" | is.na(person_info[7])) {

                                     user_id <- NULL

                                   } else {

                                     user_id <- list(directory = "https://orcid.org/",
                                                     userId = person_info[7])

                                   }

                                   list(individualName = list(givenName = person_info[1],
                                                              surName = person_info[2]),
                                        organizationName = person_info[3],
                                        role = tolower(person_info[6]),
                                        electronicMailAddress = personEmail,
                                        userId = user_id)

                                 })

  } else {

    otherPersonnel <- NULL

  }

  personnel <- c(personnelReferences, otherPersonnel)

  # <funding>
  if(!is.na(entry$funding)) {

    funding <- list(para = stringr::str_replace_all(entry$funding, "\r\n", "; "))

  } else {

    funding <- NULL

  }

  # <studyAreaDescription>
  # <habitat>
  # Set habitat (levels 1-3 of EUNIS habitat code)
  habitats <- stringr::str_split_1(entry$studyAreaDescription_habitat, "\\s*(\r\n)+| \\| ") %>%
    stringr::str_split("\\: ")

  # Split when multiple other habitats are provided
  if(!is.na(entry$studyAreaDescription_otherHabitat)) {

    otherHabitats_split <- stringi::stri_remove_empty(
      stringr::str_split_1(string = entry$studyAreaDescription_otherHabitat,
                           pattern = "(,|\\||;)\\s*"))

    # Extract each higher level of EUNIS habitat code
    # For example, if data custodian provided a level-6 habitat, also extract levels 4 and 5.
    otherHabitats_codes <- purrr::map(.x = otherHabitats_split,
                                      .f = ~{

                                        if(stringr::str_detect(.x, "X", negate = TRUE)) {

                                          all_codes <- stringr::str_sub(.x, 1, nchar(.x):1)

                                          # Set impossible habitat codes (ending in '.') to NA
                                          all_codes <- all_codes[stringr::str_ends(all_codes,
                                                                                   pattern = "\\.",
                                                                                   negate = TRUE)]

                                          # Habitat code X is not fully hierarchical, e.g., X2 is not a higher level code of X23.
                                          # So only select higher level X
                                        } else {

                                          all_codes <- stringr::str_sub(.x, 1, 1)

                                        }

                                      }) %>%
      purrr::list_c() %>%
      unique()

    # Add habitat type descriptions to codes
    otherHabitats <- purrr::map(.x = otherHabitats_codes,
                                .f = ~{

                                  habitat_codes %>%
                                    dplyr::filter(.data$habitatID == .x) %>%
                                    dplyr::mutate("habitatList" = purrr::map2(.x = habitatID,
                                                                              .y = habitatType,
                                                                              .f = ~{

                                                                                c(.x, .y)

                                                                              })) %>%
                                    dplyr::select("habitatLevel", "habitatList")

                                }) %>%
      purrr::list_rbind() %>%
      dplyr::arrange(.data$habitatLevel) %>%
      dplyr::pull("habitatList")


    # Concatenate otherHabitats with selected habitats, and keep unique codes
    habitats <- c(habitats, otherHabitats) %>% unique()

  }

  habitat_list = purrr::map(.x = habitats,
                            .f = ~{

                              list(
                                citableClassificationSystem = "true",
                                name = "EUNIS habitat code",
                                descriptorValue = list(descriptorValue = .x[2],
                                                       name_or_id = .x[1])
                              )

                            })
  # Add habitats & surface area to <studyAreaDescription>
  studyAreaDescription <- list(descriptor = list(habitat_list,
                                                 list(citableClassificationSystem = "false",
                                                      name = "physical",
                                                      descriptorValue = list(descriptorValue = paste(entry$studyAreaDescription_studySiteSize,
                                                                                                     "ha"),
                                                                             name_or_id = "surface area"))))

  # <designDescription>
  # Set major site changes & nest box information as part of <designDescription>
  if(!is.na(entry$studyAreaDescription_nestboxes)) {

    nestBoxes <- list(para = paste0("The field study monitors artificial nest boxes",
                                    ", with a minimum of ", entry$studyAreaDescription_minimumNestBoxes,
                                    " and a maximum of ", entry$studyAreaDescription_maximumNestBoxes,
                                    " throughout the study period.")
    )

  } else {

    nestBoxes <- NULL

  }

  if(!is.na(entry$studyAreaDescription_studySiteChanges)) {

    studySiteChanges <- list(para = paste("Information related to (major) changes to the study site,",
                                          "supplied by the metadata provider:",
                                          entry$studyAreaDescription_studySiteChanges))

  } else {

    studySiteChanges <- NULL

  }

  # Gap years in monitoring
  if(entry$temporalCoverage_continuous == "No") {

    gapYears <- list(para = paste0("The data were not collected continuously over the study period as indicated by the temporal coverage.",
                                   "Data are missing from", stringr::str_replace_all(entry$temporalCoverage_gaps,
                                                                                     pattern = "\r\n\\s*(\r\n)+| \\| ",
                                                                                     replacement = ", ")))

  } else if(entry$temporalCoverage_continuous == "Yes") {

    gapYears <- NULL

  }

  # Link to website describing study
  if(!is.na(entry$studyAreaDescription_url)) {

    studyUrl <- list(para = paste("Link to website that describes project/field study:",
                                  entry$studyAreaDescription_url))

  } else {

    studyUrl <- NULL

  }

  # Combine all in <designDescription>
  designDescription <- list(description = list(nestBoxes, studySiteChanges, gapYears, studyUrl))

  # Finalise <project>
  project <- list(title = project_title,
                  personnel = personnel,
                  funding = funding,
                  studyAreaDescription = studyAreaDescription,
                  designDescription = designDescription)

  # <methods>
  # Types of data collected
  ## Tag types
  tagTypes <- stringr::str_split_1(entry$methods_tagTypes, "\r\n")

  if(!is.na(entry$methods_otherTagTypes)) {

    otherTagTypes <-  paste0("Other tags used/additional details supplied by the metadata provider: ",
                             paste0(stringr::str_split_1(entry$methods_otherTagTypes, "\r\n|\\s*(\r\n)+| \\| "),
                                    collapse = ", "), ".")

  } else {

    otherTagTypes <- NULL

  }

  tagging <- list(description = list(para = list("Tagging",
                                                 paste0("Birds were fitted with tags (i.e., ",
                                                        paste0(tagTypes, collapse = ", "),
                                                        ") to monitor the development and life histories of individuals."),
                                                 otherTagTypes)))

  ## Individual data & genetic data
  individualDataTypes <- stringr::str_split_1(entry$methods_individualDataTypes, "\r\n")

  if(!is.na(entry$methods_otherIndividualDataTypes)) {

    otherIndividualDataTypes <-  paste0("Other individual-level data collected/additional details supplied by the metadata provider: ",
                                        paste0(stringr::str_split_1(entry$methods_otherIndividualDataTypes, "\r\n|\\s*(\r\n)+| \\| "),
                                               collapse = ", "), ".")

  } else {

    otherIndividualDataTypes <- NULL

  }

  individual <- list(description = list(para = list("Individual data",
                                                    paste0("The following individual-level data were collected: ",
                                                           paste0(individualDataTypes, collapse = ", "), "."),
                                                    otherIndividualDataTypes)))

  ## Genetic data
  if(!is.na(entry$methods_geneticDataTypes)) {

    geneticDataTypes <- stringr::str_split_1(entry$methods_geneticDataTypes, "\r\n")

  } else {

    geneticDataTypes <-  NULL

  }

  if(!is.na(entry$methods_otherGeneticDataTypes)) {

    otherGeneticDataTypes <-  paste0("Other genetic data collected/additional details supplied by the metadata provider: ",
                                     paste0(stringr::str_split_1(entry$methods_otherGeneticDataTypes, "\r\n|\\s*(\r\n)+| \\| "),
                                            collapse = ", "), ".")

  } else {

    otherGeneticDataTypes <- NULL

  }

  if(all(is.null(geneticDataTypes), is.null(otherGeneticDataTypes))) {

    genetic <- NULL

  } else {

    genetic <- list(description = list(para = list("Genetic data",
                                                   paste0("The following samples were taken for genetic analysis: ",
                                                          paste0(geneticDataTypes, collapse = ", "), "."),
                                                   otherGeneticDataTypes)))

  }

  ## Brood data
  broodDataTypes <- stringr::str_split_1(entry$methods_broodDataTypes, "\r\n|\n")

  if(!is.na(entry$methods_otherBroodDataTypes)) {

    otherBroodDataTypes <-  paste0("Other brood-level data collected/additional details supplied by the metadata provider: ",
                                   paste0(stringr::str_split_1(entry$methods_otherBroodDataTypes, "\r\n|\\s*(\r\n)+| \\| "),
                                          collapse = ", "), ".")

  } else {

    otherBroodDataTypes <- NULL

  }

  brood <- list(description = list(para = list("Brood data",
                                               paste0("Nests were visited regularly to collect breeding ecology variables (i.e., ",
                                                      paste0(broodDataTypes, collapse = ", "), ")."),
                                               otherBroodDataTypes)))

  ## Environmental data
  if(!is.na(entry$methods_abioticDataTypes)) {


    abiotic <- paste0("The following abiotic variables were collected: ",
                      paste0(stringr::str_split_1(entry$methods_abioticDataTypes, "\r\n"), collapse = ", "), ".")

  } else {

    abiotic <- NULL

  }

  if(!is.na(entry$methods_bioticDataTypes)) {

    biotic <- paste0("The following biotic variables were collected: ",
                     paste0(stringr::str_split_1(entry$methods_bioticDataTypes, "\r\n"), collapse = ", "), ".")

  } else {

    biotic <- NULL

  }

  if(!is.na(entry$methods_otherEnvironmentalDataTypes)) {

    otherEnvironmentalDataTypes <-  paste0("Other environmental data collected/additional details supplied by the metadata provider: ",
                                           paste0(stringr::str_split_1(entry$methods_otherEnvironmentalDataTypes, "\r\n|\\s*(\r\n)+| \\| "),
                                                  collapse = ", "), ".")

  } else {

    otherEnvironmentalDataTypes <- NULL

  }

  if(all(is.null(abiotic), is.null(biotic), is.null(otherEnvironmentalDataTypes))) {

    environmental <- NULL

  } else {

    environmental <- list(description = list(para = list("Environmental data",
                                                         biotic,
                                                         abiotic,
                                                         otherEnvironmentalDataTypes)))

  }

  ## Other activities

  if(!is.na(entry$methods_otherActivities)) {

    otherActivities <- stringr::str_split_1(entry$methods_otherActivities, "\r\n")

  } else {

    otherActivities <- NULL

  }

  if(!is.na(entry$methods_otherOtherActivities)) {

    nonlistedActivities <- entry$methods_otherOtherActivities

  } else {

    nonlistedActivities <- NULL

  }

  if(all(is.null(otherActivities), is.null(nonlistedActivities))) {

    activities <- NULL

  } else {

    activities <- list(description = list(para = list("Other activities",
                                                      paste0("The following activities were undertaken: ",
                                                             paste(stats::na.omit(c(otherActivities, nonlistedActivities)), sep = ", "), "."))))

  }

  # Finalise <methods>
  methods <- list(methodStep = list(tagging, brood, individual, genetic, environmental, activities))

  # Reference publication & literature cited
  if(!is.na(entry$studyAreaDescription_citation)) {

    citations <- stringr::str_split_1(entry$studyAreaDescription_citation, "; | \\| ")

    # Get bibtex from DOI
    bibs <- purrr::map(.x = citations,
                       .f = ~{

                         citation <- stringr::str_remove(string = .x,
                                                         pattern = "doi:|https://doi.org/|doi.org/")

                         studyAreaBib <- rcrossref::cr_cn(citation, format = "bibtex")

                       })

    # First provided DOI is reference publication
    # i.e., a citation to an additional publication that serves as an important reference for a datase
    referencePublication <- list(bibtex = bibs[[1]])

    # Others will be listed as literatureCited
    # i.e., a citation to articles or products which were referenced in the dataset or its associated metadata.
    # The list represents the bibliography of works related to the dataset, whether for reference, comparison, or other purposes
    if(length(bibs) > 1) {

      literatureCited <- list(bibtex = bibs[[-1]])

    } else {

      literatureCited <- NULL

    }

  } else {

    referencePublication <- NULL
    literatureCited <- NULL

  }

  # Check for UUID in study_codes for existing studies
  if(study_ids$studyID %in% study_codes$studyID) {

    packageId <- study_codes %>%
      dplyr::filter(.data$studyID == study_ids$studyID) %>%
      dplyr::pull("studyUUID")

    # Generate new UUID for new metadata entries
  } else {

    packageId <- uuid::UUIDgenerate()

  }

  # <id>
  system <-  "uuid"
  alternateIdentifier <- packageId

  # <language>
  lang <- "en"

  # <pubDate>
  # This is the submission date when metadata are first submitted, and the last update date when metadata are updated
  pubDate <- format(max(c(entry$submissionDate, entry$lastUpdateDate),
                        na.rm = TRUE),
                    format = "%Y-%m-%d")

  # Construct <eml>
  fileName <- paste0(paste(packageId, pubDate, sep = "_"), ".xml")

  # Create eml directory if it does not exist
  if(!dir.exists(here::here("inst", "extdata", "eml"))) {

    dir.create(here::here("inst", "extdata", "eml"))

  }

  # Write EML
  EML::write_eml(eml = list(dataset = list(title = title,
                                           alternateIdentifier = list(alternateIdentifier, shortName),
                                           creator = creator,
                                           metadataProvider = metadataProvider,
                                           coverage = coverage,
                                           project = project,
                                           methods = methods,
                                           contact = contact,
                                           intellectualRights = intellectualRights,
                                           maintenance = maintenance,
                                           pubDate = pubDate,
                                           referencePublication = referencePublication,
                                           literatureCited = literatureCited),
                            packageId = packageId,
                            system = system,
                            lang = lang),
                 file = paste0("inst/extdata/eml/", fileName),
                 encoding = "UTF-8")

  # Validate EML
  validation <- EML::eml_validate(EML::read_eml(paste0("inst/extdata/eml/", fileName)))

  if(EML::eml_validate(EML::read_eml(paste0("inst/extdata/eml/", fileName))) == TRUE) {

    cat("The created EML document is schema-valid.\n")

  } else {

    stop("The created EML document is not schema-valid.\n",
         "Create an issue on GitHub or make fixes to the function.",
         "\n",
         paste("Validation error found in:", attr(validation, "errors"), "\n"),
         call. = FALSE)

  }

  # Return values for metadata files
  return(list("studyID" = study_ids$studyID,
              "studyUUID" = packageId,
              "siteID" = study_ids$siteID,
              "siteName" = entry$studySiteName,
              "custodianName" = entry$creator_organizationName,
              "country" = entry$studySiteCountry,
              "lat" = mean(c(northBoundingCoordinate, southBoundingCoordinate)),
              "lon" = mean(c(westBoundingCoordinate, eastBoundingCoordinate)),
              "taxa" = taxon_ids))

}

#' Connect to Google Drive and read SPI-Birds metadata sheet
#'
#' SPI-Birds metadata submissions are collected through Jotform and stored on Google Sheets.
#'
#' Only used within \link{convert_to_eml}.
#'
#' @param email Character indicating the email address with which you have access to the SPI-Birds metadata sheet
#'
#' @importFrom googlesheets4 gs4_auth read_sheet
#' @importFrom janitor clean_names
#' @export

read_metadata <- function(email) {

  # Authorise googlesheets4 to connect to SPI-Birds metadata Google Sheets
  googlesheets4::gs4_auth(email = email)

  # Read Google Sheet as data frame
  google_metadata <- googlesheets4::read_sheet("1sNlpXSbZtGXD_gfvDRcGdUUmfepOVKOOfL6s4znBB20",
                                               sheet = 1)

  metadatabase <- google_metadata %>%
    janitor::clean_names(case = "lower_camel") %>%
    dplyr::rename(creator_entity = "theResponsiblePartyIs",
                  creator_givenName = "firstName",
                  creator_surName = "surnameS",
                  creator_organizationName = "organizationName",
                  creator_city = "city",
                  creator_administrativeArea = "administrativeArea",
                  creator_postalCode = "postalCode",
                  creator_country = "country",
                  creator_electronicMailAddress = "emailAddress",
                  creator_displayElectronicMailAddress = "iAllowSpiBirdsToDisplayThisEmailAddressInTheMetadataFileAndOnTheWebsite",
                  creator_userId = "orcid",
                  metadataProvider_entity = "theMetadataProviderIs",
                  metadataProvider_givenName = "nameFirstName",
                  metadataProvider_surName = "nameSurnameS",
                  metadataProvider_organizationName = "organizationName2",
                  metadataProvider_electronicMailAddress = "emailAddress2",
                  metadataProvider_displayElectronicMailAddress = "iAllowSpiBirdsToDisplayThisEmailAddressInTheMetadataFileAndOnTheWebsite2",
                  metadataProvider_userId = "orcid2",
                  contact_entity = "theContactPersonIs",
                  contact_givenName = "nameFirstName2",
                  contact_surName = "nameSurnameS2",
                  contact_organizationName = "organizationName3",
                  contact_electronicMailAddress = "emailAddress3",
                  contact_displayElectronicMailAddress =         "iAllowSpiBirdsToDisplayThisEmailAddressInTheMetadataFileAndOnTheWebsite3",
                  contact_userId = "orcid3",
                  personnel = "projectMembers",
                  funding = "fundingInformation",
                  data_submitted = "iWishToSubmitTheDataThatAreDescribedByTheseMetadata",
                  intellectualRights = "dataUsageLicense",
                  maintenanceUpdateFrequency = "theFrequencyWithWhichSpiBirdsWillReceiveUpdatesOfTheData",
                  studySiteName = "name",
                  studySiteCountry = "country2",
                  studyAreaDescription_studySiteSize = "sizeHa",
                  studyAreaDescription_studySiteChanges = "majorSiteChanges",
                  studyAreaDescription_citation = "doiOfTheReferenceThatDescribesTheStudySiteInDetail",
                  studyAreaDescription_url = "linkToAWebsiteThatDescribesTheFieldStudyInDetail",
                  studyAreaDescription_nestboxes = "nestboxCb",
                  studyAreaDescription_minimumNestBoxes = "minimumNumberOfDeployedNestBoxes",
                  studyAreaDescription_maximumNestBoxes = "maximumNumberOfDeployedNestBoxes",
                  studyAreaDescription_habitat = "habitatCode",
                  studyAreaDescription_otherHabitat = "moreDetailedHabitatCode",
                  geographicCoverage_coordinates = "iWantToSpecifyTheStudySitesCoordinates",
                  geographicCoverage_northBoundingCoordinate = "north",
                  geographicCoverage_southBoundingCoordinate = "south",
                  geographicCoverage_eastBoundingCoordinate = "east",
                  geographicCoverage_westBoundingCoordinate = "west",
                  geographicCoverage_latitude = "latitude",
                  geographicCoverage_longitude = "longitude",
                  geographicCoverage_altitudeMinimum = "minimumElevation",
                  geographicCoverage_altitudeMaximum = "maximumElevation",
                  temporalCoverage_beginDate = "startYear",
                  temporalCoverage_endDate = "endYear",
                  temporalCoverage_continuous = "theDataWereCollectedContinuouslyOverTheStudyPeriod",
                  temporalCoverage_gaps = "gapYears",
                  taxonomicCoverage = "species",
                  otherTaxonomicCoverage = "otherSpeciesNotListedAbove",
                  methods_tagTypes = "tagging",
                  methods_otherTagTypes = "otherTagsAdditionalInformation",
                  methods_individualDataTypes = "individualData",
                  methods_otherIndividualDataTypes = "otherVariablesAdditionalInformation",
                  methods_broodDataTypes = "broodData",
                  methods_otherBroodDataTypes = "otherVariablesAdditionalInformation2",
                  methods_geneticDataTypes = "geneticData",
                  methods_otherGeneticDataTypes = "otherVariablesAdditionalInformation3",
                  methods_bioticDataTypes = "bioticData",
                  methods_abioticDataTypes = "abioticData",
                  methods_otherEnvironmentalDataTypes = "otherVariablesAdditionalInformation4",
                  methods_otherActivities = "otherActivities",
                  methods_otherOtherActivities = "otherActivitiesAdditionalInformation",
                  consent_archive = "iConsentThatTheMetadataMayBeArchivedAsPartOfTheSpiBirdsDatabase",
                  consent_website = "iConsentThatTheMetadataMayBePubliclyVisibleOnTheSpiBirdsWebsite",
                  permission_submit = "iConfirmThatIHaveTheRightsOrPermissionsToSubmitTheMetadataProvidedAboveToSpiBirds")

  return(metadatabase)

}

#' Set the siteID and studyID for a metadata entry
#'
#' This function asks the user for a three-letter siteID, and creates an associated studyID.
#' If the metadata entry involves a new study at an existing site, a new studyID is automatically assigned.
#' If the metadata entry involves an update of an existing study, the user is asked to provide the associated studyID.
#'
#' Only used within \link{convert_to_eml}.
#'
#' @param entry a single-row data frame representing a single metadata entry
#' @importFrom stringr str_detect

set_study_site_ids <- function(entry) {

  # If site exists, use associated siteID
  if(entry$studySiteName %in% site_codes$siteName) {

    # Extract siteID
    siteID <- site_codes |>
      dplyr::filter(.data$siteName == entry$studySiteName) |>
      dplyr::pull("siteID")

    # Does the metadata entry belong to a study already part of SPI-Birds?
    existingStudy <- utils::menu(choices = c("Yes", "No"),
                                 title = "Does this metadata entry belong to an existing study?")

    # If yes, ask for studyID
    if(existingStudy == 1) {

      studyID <- readline(paste0("Provide the studyID (siteID: ", siteID, "): "))

      # Error handling when a wrong studyID is entered
      if(stringr::str_detect(studyID, pattern = "[:upper:]{3}-[:digit:]{1}", negate = TRUE)) {

        print("Your provided studyID should be of the form 'HOG-1'.\n")
        studyID <- readline(paste0("Please provide a new ID: "))

      }

      while(!(studyID %in% study_codes[study_codes$siteID == siteID, ]$studyID)) {

        print("Your provided studyID does not exist.\n")
        studyID <- readline(paste0("Please provide a new ID: "))

      }

      # If no, assign new studyID to same site
    } else if(existingStudy == 2) {

      studyID <- paste0(siteID, "-", nrow(study_codes[study_codes$siteID == siteID, ]) + 1)

    }

    # If site does not exist, ask for new siteID
  } else {

    siteID <- readline(paste0("Provide a three-letter siteID (", entry$studySiteName, "): "))
    siteID <- toupper(siteID)

    # Error handling when a wrong siteID is entered
    if(stringr::str_length(siteID) != 3) {

      print("A siteID should be three letters.\n")
      siteID <- readline(paste0("Please provide a new ID: "))

    }

    while(siteID %in% site_codes$siteID) {

      print("This siteID already exists.\n")
      siteID <- readline(paste0("Please provide a new ID: "))
      siteID <- toupper(siteID)

    }

    studyID <- paste0(siteID, "-", 1)

  }

  return(list("siteID" = siteID,
              "studyID" = studyID))

}
