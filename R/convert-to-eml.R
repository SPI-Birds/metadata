#' Process metadata submission and format following the Ecological Metadata Language
#'
#' The Ecological Metadata Language (EML) defines a comprehensive vocabulary and XML markup
#' for documenting research data in the fields of ecology and environmental sciences. EML
#' is the standard used by SPI-Birds to structure metadata of studies and associated datasets.
#'
#' @importFrom lubridate year
#' @importFrom tidyselect where
#' @importFrom forcats fct_relevel
#' @importFrom magrittr %>%
#' @importFrom purrr map
#' @importFrom httr GET
#' @importFrom jsonlite fromJSON
#' @export

convert_to_eml <- function() {

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

    endYear <- paste0(lubridate::year(Sys.time()), " (ongoing)")

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

    metadataProvider <- list(individualName = list(givenName = entry$metadataProvider_givenName,
                                                   surName = entry$metadataProvider_surName),
                             organizationName = entry$metadataProvider_organizationName,
                             electronicMailAddress = metadataProviderEmail,
                             userId = list(directory = "https://orcid.org/",
                                           userId = entry$metadataProvider_userId))

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

    contact <- list(individualName = list(givenName = entry$contact_givenName,
                                          surName = entry$contact_surName),
                    organizationName = entry$metadataProvider_organizationName,
                    electronicMailAddress = contactEmail,
                    userId = list(directory = "https://orcid.org/",
                                  userId = entry$contact_userId))

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

  if(is.na(endDate)) endDate <- lubridate::year(Sys.Date())

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

                            # Ensure that input is a scientific name
                            species_name <- taxize::tax_name(sci = .x,
                                                             get = "species") |>
                              dplyr::pull(species)

                            # Get GBIF ID
                            gbif <- taxize::get_gbifid_(sci = species_name) %>%
                              dplyr::bind_rows() %>%
                              dplyr::filter(status == "ACCEPTED" & matchtype == "EXACT") %>%
                              dplyr::pull(usagekey)

                            # Get EOL page ID
                            eol <- taxize::get_eolid(sci_com = species_name,
                                                     data_source = "EOL.*2022", rank = "species")

                            # Get COL ID
                            res <- httr::GET(paste0("https://api.checklistbank.org/dataset/3LR/match/nameusage?q=",
                                                    stringr::str_replace(species_name, " ", "+")))

                            col <- jsonlite::fromJSON(rawToChar(res$content))

                            # Get ITIS
                            tsn <- taxize::get_tsn(sci = species_name)

                            # Get EURING code
                            if(.x %in% euring_codes$Current_Name) {

                              euring <- tibble::tibble(
                                name = species_name,
                                rank = "species",
                                id = euring_codes %>%
                                  dplyr::filter(Current_Name == name) %>%
                                  dplyr::pull("EURING_Code"),
                                db = "https://euring.org"
                              )

                            } else { # Skip for species not in EURING

                              euring <- NULL

                            }

                            # Get GBIF classification
                            gbif_class <- rbind(taxize::classification(gbif, db = "gbif")) %>%
                              dplyr::mutate(db = "https://www.gbif.org",
                                            id = as.character(.data$id))

                            # Get EOL classification
                            eol_class <- tibble::tibble(
                              name = species_name,
                              rank = "species",
                              id = attributes(eol)$pageid,
                              db = "https://eol.org"
                            )

                            # Get COL classification
                            if("usage" %in% names(col)) {

                              col_class <- col$usage$classification %>%
                                dplyr::select("name", "rank", "id") %>%
                                dplyr::add_row(name = col$usage$name,
                                               rank = col$usage$rank,
                                               id = col$usage$id) %>%
                                dplyr::mutate(db = "https://www.catalogueoflife.org")

                            } else { # Skip for species not in COL

                              col_class <- NULL

                            }

                            # Get ITIS classification
                            itis_class <- rbind(taxize::classification(tsn, db = "itis")) %>%
                              dplyr::mutate(db = "https://www.itis.gov")

                            # Combine and filter for rank 'kingdom', 'phylum', 'class', 'order', 'family', 'genus', and 'species'
                            dplyr::bind_rows(gbif_class, col_class, eol_class, itis_class, euring) %>%
                              dplyr::select(-"query") %>%
                              dplyr::filter(rank %in% c("kingdom", "phylum", "class", "order",
                                                        "family", "genus", "species"))

                          })

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

}

#' Connect to Google Drive and read SPI-Birds metadata sheet
#'
#' SPI-Birds metadata submissions are collected through Jotform and stored on Google Sheets.
#'
#' Only used within `convert_to_eml()`.
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
    dplyr::select(-"streetAddress", -"streetAddressLine2") %>%
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
#' Only used within `convert_to_eml()`.
#'
#' @param taxa a single-row data frame representing a single metadata entry
#' @importFrom stringr str_detect

set_study_site_ids <- function(entry) {

  # If site exists, use associated siteID
  if(entry$studySiteName %in% site_codes$siteName) {

    # Extract siteID
    siteID <- site_codes |>
      dplyr::filter("siteName" == entry$studySiteName) |>
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

  return(list(siteID = siteID,
              studyID = studyID))

}


#' Create EML's hierarchical taxonomy and refer to relevant taxon ids where available
#'
#' Per studied species, this function will create a nested taxonomy including kingdom, phylum, class, order, family, genus, species
#'
#' Only used within `convert_to_eml()`.
#'
#' @param taxa list of taxonomic names, ranks and ids per species
#' @importFrom stringr str_to_sentence
#' @importFrom WikidataQueryServiceR query_wikidata

create_nested_taxonomy <- function(taxa) {

  if(length(taxa) > 1) {

    list(
      taxonRankName = taxa[[1]][1,]$rank,
      taxonRankValue = taxa[[1]][1,]$name,
      taxonId = purrr::map(.x = seq_len(nrow(taxa[[1]])),
                           .f = ~{

                             list(provider = taxa[[1]][.x,]$db,
                                  taxonId = taxa[[1]][.x,]$id)

                           }),
      taxonomicClassification = create_nested_taxonomy(taxa[-1])
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
      taxonRankName = taxa[[1]][1,]$rank,
      taxonRankValue = taxa[[1]][1,]$name,
      commonName = commonName,
      taxonId = purrr::map(.x = seq_len(nrow(taxa[[1]])),
                           .f = ~{

                             list(provider = taxa[[1]][.x,]$db,
                                  taxonId = taxa[[1]][.x,]$id)

                           })
    )

  }

}
