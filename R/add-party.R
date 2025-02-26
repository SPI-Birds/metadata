#' Create an additional party
#'
#' The responsible party (creator), metadata provider, and contact in Jotform are limited to a single entry. In some instances, data contributors wish to add more than one party to these entities. This interactive function will help with the creation of that party.
#'
#' @returns a structured list that can be directly plugged into an EML.xml as a creator, metadata provider, or contact.
#' @export

create_party <- function() {

  cat("Required fields are marked with *.\nIf a field is not relevant, hit Enter.\n")

  type <- utils::menu(choices = c("person", "organisation"),
                      title = "Do you want to create a person or an organisation?")

  # Only if party is a person
  if(type == 1) {

    first_name <- readline("First name*: ")
    if(first_name == "") first_name <- NULL

    surname <- readline("Surname(s)*: ")
    if(surname == "") surname <- NULL

    email_address <- readline("Email address*: ")
    if(email_address == "") email_address <- NULL

    orcid <- readline("ORCID: ")
    if(orcid == "") orcid <- NULL

  }

  organisation <- readline("Organisation name*: ")

  # If party is organisation, organisation cannot be blank
  while(type == 2 & organisation == "") {

    organisation <- readline("Organisation name*: ")

  }

  if(organisation == "") organisation <- NULL

  if(!is.null(organisation)) {

    cat("Provide the address of the organisation")

    organisation_city <- readline("City*: ")
    if(organisation_city == "") organisation_city <- NULL

    organisation_area <- readline("Administrative area: ")
    if(organisation_area == "") organisation_area <- NULL

    organisation_post <- readline("Postal code: ")
    if(organisation_post == "") organisation_post <- NULL

    organisation_country <- readline("Country*: ")
    if(organisation_country == "") organisation_country <- NULL

  }

  if(type == 2) {

    party <- list(organizationName = organisation,
                  address = list(city = organisation_city,
                                 administrativeArea = organisation_area,
                                 postalCode = organisation_post,
                                 country = organisation_country))

  } else if(type == 1) {

    party <- list(individualName = list(givenName = first_name,
                                        surName = surname),
                  electronicMailAddress = email_address,
                  userId = orcid,
                  organizationName = organisation,
                  address = list(city = organisation_city,
                                 administrativeArea = organisation_area,
                                 postalCode = organisation_post,
                                 country = organisation_country))

  }

  return(party)

}

#' Add party to metadata EML.xml
#'
#' The Responsible Party (creator), Metadata Provider, and Contact in Jotform are limited to a single entry. In some instances, data contributors wish to add more than one party to these entities. This function will add the created party (with \link{create_party}) to the right element in the metadata EML.xml.
#'
#' @param file Character indicating file path to the metadata EML.xml to which the party should be added
#' @param party List output form \link{create_party} containing the party details
#' @param add_to Character vector indicating the elements to which the party should be added. At least one of: "creator", "metadataProvider", "contact".
#'
#' @returns an EML.xml from the updated metadata
#' @export

add_party_to_xml <- function(file = file.choose(),
                             party,
                             add_to) {

  # Select xml file
  cat("Select a metadata xml file\n")
  force(file)

  meta <- EML::read_eml(file)

  # New parties have to be added to the relevant element
  # i.e., <creator>, <metadataProvider>, <contact>,
  # as well as to the list of personnel in <project>
  if("creator" %in% add_to) {

    meta$dataset$creator <- list(meta$dataset$creator,
                                 c(party,
                                   id = "creator-2",
                                   scope = "document"))

    if("metadataProvider" %in% add_to) {

      meta$dataset$metadataProvider <- list(references = "creator-2")

    }

    if("contact" %in% add_to) {

      meta$dataset$contact <- list(references = "creator-2")

    }

    meta$dataset$project$personnel <- list(meta$dataset$project$personnel,
                                           list(references = "creator-2",
                                                role = "dataCustodian"))

  } else {

    if("metadataProvider" %in% add_to) {

      meta$dataset$metadataProvider <- list(meta$dataset$metadataProvider,
                                            c(party,
                                              id = "metadata-provider-2",
                                              scope = "document"))

      if("contact" %in% add_to) {

        meta$dataset$contact <- list(references = "metadata-provider-2")

      }

      meta$dataset$project$personnel <- list(meta$dataset$project$personnel,
                                             list(references = "metadata-provider-2",
                                                  role = "metadataProvider"))

    } else {

      meta$dataset$contact <- list(meta$dataset$contact,
                                   c(party,
                                     id = "contact-2",
                                     scope = "document"))

      meta$dataset$project$personnel <- list(meta$dataset$project$personnel,
                                             list(references = "contact-2",
                                                  role = "pointOfContact"))

    }

  }

  # Ensure that the updated EML.xml is still schema valid.
  if(EML::eml_validate(meta) == TRUE) {

    cat("The updated EML document is schema-valid.\n")

    EML::write_eml(eml = meta,
                   file = file,
                   encoding = "UTF-8")

  } else {

    stop("The updated EML document is not schema-valid.")

  }

}
