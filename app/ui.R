# SPI-Birds metadata form submission via Shiny
# Inspired by https://github.com/daattali/UBC-STAT545/tree/master/shiny-apps/request-basic-info

# User interface with all the input fields

# Read in internal data object
source("internal-data.R")

# Create app user interface
ui <- shiny::fluidPage(

  # Webpage title
  title = "SPI-Birds Metadata Form",

  theme = bslib::bs_theme(base_font = bslib::font_google("Open Sans", local = TRUE)),

  # Language for html metadata
  lang = "en",

  # Use shinyjs in this Shiny app
  shinyjs::useShinyjs(),

  # Contentg
  shiny::h2("SPI-Birds Metadata Form"),

  shiny::conditionalPanel(
    # only show this form before the form is submitted
    condition = "!output.formSubmitted",

    # Legend
    shiny::code("Legend:",
                shiny::tags$br(),
                shiny::icon("circle-exclamation"),
                shiny::strong("required field"),
                shiny::tags$br(),
                shiny::tags$i(class = "fa-solid fa-registered"),
                shiny::strong("recommended field"),
                shiny::tags$br(),
                "all other non-marked fields are",
                shiny::strong("optional"),
                shiny::tags$br(),
                tippy::tippy(text = shiny::icon("question-circle"),
                             tooltip = "This tooltip provides additional information on a metadata field",
                             trigger = "mouseenter click",
                             placement = "bottom"),
                shiny::strong("tooltip; hover to display extra info on a metadata field")),

    ### creator
    shiny::tags$br(),
    shiny::h3("Creator"),
    shiny::p("The creator and owner of the dataset; i.e., the responsible organization"),

    # organizationName
    shiny::textInput(inputId = "creator_organizationName",
                     width = htmltools::validateCssUnit("50%"),
                     label = shiny::div("Organization name",
                                        shiny::icon("circle-exclamation"))),

    ## Organization address
    shiny::tags$br(),
    shiny::h5("Organization Address"),

    # city
    shiny::textInput(inputId = "creator_city", # city
                     width = htmltools::validateCssUnit("50%"),
                     label = shiny::div("City",
                                        shiny::icon("circle-exclamation"))),

    # administrativeArea
    shiny::textInput(inputId = "creator_administrativeArea",
                     width = htmltools::validateCssUnit("50%"),
                     label = shiny::tags$span("Administrative area",
                                              shiny::tags$i(class = "fa-solid fa-registered"),
                                              tippy::tippy(text = shiny::icon("question-circle"),
                                                           tooltip = "Political area of a country; e.g., state in the USA, province in Canada.",
                                                           trigger = "mouseenter click",
                                                           placement = "right"))),

    # postalCode
    shiny::textInput(inputId = "creator_postalCode",
                     width = htmltools::validateCssUnit("50%"),
                     label = shiny::div("Postal code",
                                        shiny::icon("circle-exclamation"))),

    # country
    shinyWidgets::pickerInput(inputId = "creator_country",
                              label = shiny::div("Country",
                                                 shiny::icon("circle-exclamation")),
                              choices = c("Search for country/dependency" = '', countries$name),
                              options = list(`live-search` = TRUE),
                              inline = FALSE),

    ### metadataProvider
    shiny::tags$br(),
    shiny::h3("Metadata Provider"),
    shiny::p("The person who provided the metadata"),

    # givenName
    shiny::textInput(inputId = "metadataProvider_givenName",
                     width = htmltools::validateCssUnit("50%"),
                     label = shiny::div("First name",
                                        shiny::icon("circle-exclamation"))),

    # surName
    shiny::textInput(inputId = "metadataProvider_surName",
                     width = htmltools::validateCssUnit("50%"),
                     label = shiny::div("Surname(s)",
                                        shiny::icon("circle-exclamation"))),

    # organizationName (if not the same as creator)
    shiny::div(shinyWidgets::prettyCheckbox(inputId = "metadataProvider_organizationName_cb",
                                            label = "The organization of the Metadata Provider is different than provided under Creator",
                                            shape = "curve"),
               style = "font-style: italic"),
    shinyjs::hidden(shiny::textInput(inputId = "metadataProvider_organizationName",
                                     width = htmltools::validateCssUnit("50%"),
                                     label = shiny::div("Organization name",
                                                        shiny::icon("circle-exclamation")))),

    # positionName
    shiny::textInput(inputId = "metadataProvider_positionName",
                     width = htmltools::validateCssUnit("50%"),
                     label = shiny::tags$span("Position",
                                              shiny::icon("circle-exclamation"),
                                              tippy::tippy(text = shiny::icon("question-circle"),
                                                           tooltip = "Role (or title) of person within the organization; e.g., data manager, technician.",
                                                           trigger = "mouseenter click",
                                                           placement = "right"))),

    # electronicMailAddress (allow publicly displayed or not)
    shiny::textInput(inputId = "metadataProvider_electronicMailAddress",
                     width = htmltools::validateCssUnit("50%"),
                     label = shiny::div("Email address",
                                        shiny::icon("circle-exclamation"))),

    shinyjs::hidden(shinyWidgets::prettyRadioButtons(inputId = "metadataProvider_electronicMailAddress_display",
                                                     label = "I allow SPI-Birds to display this email address in the metadata file and on the website. If you select 'No', the email address will only be known to the SPI-Birds team.",
                                                     choices = c("Yes", "No"),
                                                     inline = TRUE,
                                                     shape = "curve",
                                                     status = "primary",
                                                     icon = shiny::icon("check"))),

    # onlineUrl (personal website)
    shiny::textInput(inputId = "metadataProvider_onlineUrl",
                     width = htmltools::validateCssUnit("50%"),
                     label = "Personal website"),

    # userId (ORCID)
    shiny::textInput(inputId = "metadataProvider_userId",
                     width = htmltools::validateCssUnit("50%"),
                     label = shiny::span("ORCID",
                                         shiny::tags$i(class = "fa-solid fa-registered"),
                                         tippy::tippy(text = shiny::icon("question-circle"),
                                                      tooltip = shiny::tags$div(shiny::tags$a(href = "https://orcid.org/",
                                                                                              "https://orcid.org/",
                                                                                              .noWS = "after"),
                                                                                ";",
                                                                                "16-digit number of the form XXXX-XXXX-XXXX-XXXX"),
                                                      trigger = "mouseenter click",
                                                      placement = "right",
                                                      interactive = "true"))),

    ### contact
    shiny::tags$br(),
    shiny::h3("Contact Person"),
    shiny::p("The person to contact with questions about the use and/or
              interpretation of the data set"),
    shiny::div(shinyWidgets::prettyCheckbox(inputId = "contact_cb",
                                            label = "The Contact Person is someone else than the Metadata Provider",
                                            shape = "curve"),
               style = "font-style: italic"),

    # givenName
    shinyjs::hidden(shiny::textInput(inputId = "contact_givenName",
                                     width = htmltools::validateCssUnit("50%"),
                                     label = shiny::div("First name",
                                                        shiny::icon("circle-exclamation")),
                                     value = NA)),

    # surName
    shinyjs::hidden(shiny::textInput(inputId = "contact_surName",
                                     width = htmltools::validateCssUnit("50%"),
                                     label = shiny::div("Surname(s)",
                                                        shiny::icon("circle-exclamation")))),

    # organizationName
    shinyjs::hidden(shiny::textInput(inputId = "contact_organizationName",
                                     width = htmltools::validateCssUnit("50%"),
                                     label = shiny::div("Organization name",
                                                        shiny::icon("circle-exclamation")))),

    # positionName
    shinyjs::hidden(shiny::textInput(inputId = "contact_positionName",
                                     width = htmltools::validateCssUnit("50%"),
                                     label = shiny::tags$span("Position",
                                                              shiny::icon("circle-exclamation"),
                                                              tippy::tippy(text = shiny::icon("question-circle"),
                                                                           tooltip = "Role (or title) of person within the organization; e.g., data manager, technician.",
                                                                           trigger = "mouseenter click",
                                                                           placement = "right")))),

    # electronicMailAddress (allow publicly displayed or not)
    shinyjs::hidden(shiny::textInput(inputId = "contact_electronicMailAddress",
                                     width = htmltools::validateCssUnit("50%"),
                                     label = shiny::div("Email address",
                                                        shiny::icon("circle-exclamation")))),

    shinyjs::hidden(shinyWidgets::prettyRadioButtons(inputId = "contact_electronicMailAddress_display",
                                                     label = "I allow SPI-Birds to display this email address in the metadata file and on the website. If you select 'No', the email address will only be known to the SPI-Birds team.",
                                                     choices = c("Yes", "No"),
                                                     inline = TRUE,
                                                     shape = "curve",
                                                     status = "primary",
                                                     icon = shiny::icon("check"))),

    # onlineUrl (personal website)
    shinyjs::hidden(shiny::textInput(inputId = "contact_onlineUrl",
                                     width = htmltools::validateCssUnit("50%"),
                                     label = "Personal website")),

    # userId (ORCID)
    shinyjs::hidden(shiny::textInput(inputId = "contact_userId",
                                     width = htmltools::validateCssUnit("50%"),
                                     label = shiny::span("ORCID",
                                                         shiny::tags$i(class = "fa-solid fa-registered"),
                                                         tippy::tippy(text = shiny::icon("question-circle"),
                                                                      tooltip = shiny::tags$div(shiny::tags$a(href = "https://orcid.org/",
                                                                                                              "https://orcid.org/",
                                                                                                              .noWS = "after"),
                                                                                                ";",
                                                                                                "16-digit number of the form XXXX-XXXX-XXXX-XXXX"),
                                                                      trigger = "mouseenter click",
                                                                      placement = "right",
                                                                      interactive = "true")))),


    ### intellectualRights
    shiny::tags$br(),
    shiny::h3("License"),
    shiny::selectInput(inputId = "intellectualRights",
                       width = htmltools::validateCssUnit("50%"),
                       label = shiny::div("This work is licensed under:",
                                          shiny::icon("circle-exclamation")),
                       selectize = TRUE,
                       choices = c("Select license" = '', licenses$name)),

    ### maintenance
    shiny::h3("Data Maintenance"),
    shiny::selectInput(inputId = "maintenanceUpdateFrequency",
                       width = htmltools::validateCssUnit("50%"),
                       label = shiny::div("The frequency with which SPI-Birds will receive updates of the data:",
                                          shiny::icon("circle-exclamation")),
                       selectize = TRUE,
                       choices = c("Select frequency" = "",
                                   "annually",
                                   "as needed" = "asNeeded",
                                   "unknown")),

    ### coverage
    shiny::h3("Data Coverage"),
    ## geographic coverage
    shiny::h5("Geographic Coverage"),
    shiny::h6(shiny::strong("Coordinates")),
    shinyWidgets::awesomeRadio(inputId = "geographicCoverage_coordinates",
                               label = "I want to specify the coordinates as",
                               choices = c("the four margins (N, S, E, W) of a bounding box",
                                           "a centre point"),
                               width = htmltools::validateCssUnit("50%")),
    shiny::numericInput(inputId = "geographicCoverage_northBoundingCoordinate",
                        label = shiny::tags$span("North",
                                                 shiny::icon("circle-exclamation"),
                                                 tippy::tippy(text = shiny::icon("question-circle"),
                                                              tooltip = "Northern-most limit of the study site, expressed in decimal degrees of latitude [-90, 90]",
                                                              trigger = "mouseenter click",
                                                              placement = "right")),
                        value = NA,
                        min = -90,
                        max = 90,
                        width = htmltools::validateCssUnit("50%")),
    shiny::numericInput(inputId = "geographicCoverage_southBoundingCoordinate",
                        label = shiny::tags$span("South",
                                                 shiny::icon("circle-exclamation"),
                                                 tippy::tippy(text = shiny::icon("question-circle"),
                                                              tooltip = "Southern-most limit of the study site, expressed in decimal degrees of latitude [-90, 90]",
                                                              trigger = "mouseenter click",
                                                              placement = "right")),
                        value = NA,
                        min = -90,
                        max = 90,
                        width = htmltools::validateCssUnit("50%")),
    shiny::numericInput(inputId = "geographicCoverage_eastBoundingCoordinate",
                        label = shiny::tags$span("East",
                                                 shiny::icon("circle-exclamation"),
                                                 tippy::tippy(text = shiny::icon("question-circle"),
                                                              tooltip = "Eastern-most limit of the study site, expressed in decimal degrees of longitude [-180, 180]",
                                                              trigger = "mouseenter click",
                                                              placement = "right")),
                        value = NA,
                        min = -180,
                        max = 180,
                        width = htmltools::validateCssUnit("50%")),
    shiny::numericInput(inputId = "geographicCoverage_westBoundingCoordinate",
                        label = shiny::tags$span("West",
                                                 shiny::icon("circle-exclamation"),
                                                 tippy::tippy(text = shiny::icon("question-circle"),
                                                              tooltip = "Western-most limit of the study site, expressed in decimal degrees of longitude [-180, 180]",
                                                              trigger = "mouseenter click",
                                                              placement = "right")),
                        value = NA,
                        min = -180,
                        max = 180,
                        width = htmltools::validateCssUnit("50%")),
    shiny::numericInput(inputId = "geographicCoverage_latitude",
                        label = shiny::tags$span("Latitude",
                                                 shiny::icon("circle-exclamation"),
                                                 tippy::tippy(text = shiny::icon("question-circle"),
                                                              tooltip = "Latitude of centre point expressed decimal degrees [-90, 90]",
                                                              trigger = "mouseenter click",
                                                              placement = "right")),
                        value = NA,
                        min = -90,
                        max = 90,
                        width = htmltools::validateCssUnit("50%")),
    shiny::numericInput(inputId = "geographicCoverage_longitude",
                        label = shiny::tags$span("Longitude",
                                                 shiny::icon("circle-exclamation"),
                                                 tippy::tippy(text = shiny::icon("question-circle"),
                                                              tooltip = "Longitude of centre point expressed decimal degrees [-180, 180]",
                                                              trigger = "mouseenter click",
                                                              placement = "right")),
                        value = NA,
                        min = -180,
                        max = 180,
                        width = htmltools::validateCssUnit("50%")),

    ## altitude
    shiny::h6(shiny::strong("Elevation")),
    shiny::numericInput(inputId = "geographicCoverage_altitudeMinimum",
                        label = shiny::tags$span("Minimum elevation",
                                                 shiny::icon("circle-exclamation"),
                                                 tippy::tippy(text = shiny::icon("question-circle"),
                                                              tooltip = "The minimum elevation of the study site in meters above mean sea level",
                                                              trigger = "mouseenter click",
                                                              placement = "right")),
                        value = NA,
                        width = htmltools::validateCssUnit("50%")),

    shiny::numericInput(inputId = "geographicCoverage_altitudeMaximum",
                        label = shiny::tags$span("Maximum elevation",
                                                 shiny::icon("circle-exclamation"),
                                                 tippy::tippy(text = shiny::icon("question-circle"),
                                                              tooltip = "The maximum elevation of the study site in meters above mean sea level",
                                                              trigger = "mouseenter click",
                                                              placement = "right")),
                        value = NA,
                        width = htmltools::validateCssUnit("50%")),

    ## temporal coverage
    shiny::tags$br(),
    shiny::h5("Temporal Coverage"),
    shiny::numericInput(inputId = "temporalCoverage_beginDate",
                        label = shiny::tags$span("Start year",
                                                 shiny::icon("circle-exclamation")),
                        value = NA,
                        width = htmltools::validateCssUnit("50%")),
    shiny::numericInput(inputId = "temporalCoverage_endDate",
                        label = shiny::tags$span("End year",
                                                 tippy::tippy(text = shiny::icon("question-circle"),
                                                              tooltip = "If the field study is ongoing, you may leave this field empty",
                                                              trigger = "mouseenter click",
                                                              placement = "right")),
                        value = NA,
                        width = htmltools::validateCssUnit("50%")),
    # continuity of data collection
    shinyWidgets::prettyRadioButtons(inputId = "temporalCoverage_continuous",
                                     label = "The data were collected continuously over the study period",
                                     choices = c("Yes", "No"),
                                     inline = TRUE,
                                     shape = "curve",
                                     status = "primary",
                                     icon = shiny::icon("check")),
    shinyjs::hidden(shiny::textInput(inputId = "temporalCoverage_gaps",
                                     label = shiny::tags$span("Gap years",
                                                              shiny::tags$i(class = "fa-solid fa-registered"),
                                                              tippy::tippy(text = shiny::icon("question-circle"),
                                                                           tooltip = shiny::tags$span("List years during which data were",
                                                                                                      shiny::em("not"),
                                                                                                      "collected, separated by space vertical bar space (' | '); e.g., '1809 | 1823'"),
                                                                           trigger = "mouseenter click",
                                                                           placement = "right")))),

    ## taxonomic coverage
    shiny::tags$br(),
    shiny::h5("Taxonomic Coverage"),
    shinyWidgets::multiInput(inputId = "taxonomicCoverage",
                             label = shiny::tags$span("Species",
                                                      shiny::icon("circle-exclamation"),
                                                      tippy::tippy(text = shiny::icon("question-circle"),
                                                                   tooltip = "You may select multiple species",
                                                                   trigger = "mouseenter click",
                                                                   placement = "right")),
                             choices = species$name,
                             width = htmltools::validateCssUnit("50%")),

    shiny::textInput(inputId = "taxonomicCoverage_others",
                     label = shiny::tags$span("Other species not listed above:",
                                              tippy::tippy(text = shiny::icon("question-circle"),
                                                           tooltip = "You may list multiple species, separated by space vertical bar space (' | '); e.g., 'Raphus cucullatus | Ectopistes migratorius'",
                                                           trigger = "mouseenter click",
                                                           placement = "right")),
                     width = htmltools::validateCssUnit("50%")),

    ### researchProject
    shiny::tags$br(),
    shiny::h3("Study Information"),

    #TODO: Add study site name, size, and major site changes
    shiny::textInput(inputId = "title",
                     width = htmltools::validateCssUnit("50%"),
                     label = shiny::div("Name of the study site",
                                        shiny::icon("circle-exclamation")),
                     value = NA),

    shiny::numericInput(inputId = "studyAreaDescription_size",
                        width = htmltools::validateCssUnit("50%"),
                        label = shiny::div("Size of the study site",
                                           shiny::icon("circle-exclamation")),
                        value = NA),

    shiny::textInput(inputId = "studyAreaDescription_siteChanges",
                     label = shiny::tags$span("Major site changes",
                                              tippy::tippy(text = shiny::icon("question-circle"),
                                                           tooltip = "Please specify any major site changes (e.g., in size) that have happened",
                                                           trigger = "mouseenter click",
                                                           placement = "right")),
                     width = htmltools::validateCssUnit("50%")),

    ## studyAreaDescription
    shiny::h5("Study Area"),
    shinyWidgets::pickerInput(inputId = "studyAreaDescription_habitat",
                              label = shiny::tags$span("Habitat",
                                                       shiny::icon("circle-exclamation"),
                                                       tippy::tippy(text = shiny::icon("question-circle"),
                                                                    tooltip = shiny::tags$div("Habitat description of the study site, using the EUNIS habitat classification scheme (version 2012). See the",
                                                                                              shiny::tags$a(href = "https://github.com/SPI-Birds/documentation/blob/master/standard_protocol/SPI_Birds_Appendices.pdf",
                                                                                                            "Appendices"),
                                                                                              "to SPI-Birds' standard format for more information."),
                                                                    trigger = "mouseenter click",
                                                                    placement = "right",
                                                                    interactive = "true")),
                              choices = c("Select a EUNIS habitat" = '', habitatList),
                              width = "100%",
                              options = list(`live-search` = TRUE)),

    ## citation to study area description
    shiny::textInput(inputId = "studyAreaDescription_citation",
                     label = shiny::span("DOI",
                                         tippy::tippy(text = shiny::icon("question-circle"),
                                          tooltip = "DOI of the reference/publication in which the study area is described in detail",
                                          trigger = "mouseenter click",
                                          placement = "right")),
                     width = htmltools::validateCssUnit("50%")),

    ## personnel
    shiny::tags$br(),
    shiny::h5("Project Members"),

    shiny::p("Add people other than provided under Contact and/or Metadata Provider who have contributed to running the study site."),

    shinyWidgets::actionBttn(inputId = "addMember",
                        label = "Add member",
                        style = "unite",
                        size = "sm",
                        color = "primary"),
    shinyWidgets::actionBttn(inputId = "removeMember",
                        label = "Remove member",
                        style = "unite",
                        size = "sm",
                        color = "warning"),
    shiny::uiOutput(outputId = "memberFields"),

    ### methods
    shiny::tags$br(),
    shiny::h3("Data collected"),
    shiny::p("Types of data collected at the study site.",
             shiny::br(),
             shiny::strong("Note:"),
             "this does not include",
             shiny::tags$em("derived"),
             "variables, such as number of recruits."),

    ## tags
    shiny::h5("Tagging"),
    shinyWidgets::pickerInput(inputId = "methods_tagTypes",
                              label = shiny::div("Select the tags that you use to identify individuals",
                                                 shiny::icon("circle-exclamation"),
                                                 tippy::tippy(text = shiny::icon("question-circle"),
                                                              tooltip = "You may select multiple tags",
                                                              trigger = "mouseenter click",
                                                              placement = "right")),
                              multiple = TRUE,
                              inline = FALSE,
                              width = "75%",
                              choices = tagTypes,
                              options = shinyWidgets::pickerOptions(noneSelectedText = "No tag selected")),
    shiny::textInput(inputId = "methods_tagTypes_others",
                     label = shiny::tags$span("Other tags/additional information",
                                              tippy::tippy(text = shiny::icon("question-circle"),
                                                           tooltip = "Please add details here; e.g., whether the tags were not used for all study species, and/or if you used tags not listed above",
                                                           trigger = "mouseenter click",
                                                           placement = "right")),
                     width = htmltools::validateCssUnit("50%")),

    ## individual data
    shiny::h5("Individual data"),
    shinyWidgets::pickerInput(inputId = "methods_individualDataTypes",
                              label = shiny::div("Variables collected at the individual level",
                                                 shiny::icon("circle-exclamation"),
                                                 tippy::tippy(text = shiny::icon("question-circle"),
                                                              tooltip = "You may select multiple variables",
                                                              trigger = "mouseenter click",
                                                              placement = "right")),
                              multiple = TRUE,
                              inline = FALSE,
                              width = "75%",
                              choices = individualDataTypes,
                              options = shinyWidgets::pickerOptions(noneSelectedText = "No variable selected")),
    shiny::textInput(inputId = "methods_individualDataTypes_others",
                     label = shiny::tags$span("Other variables/additional information",
                                              tippy::tippy(text = shiny::icon("question-circle"),
                                                           tooltip = "Please add details here; e.g., whether the variables were not monitored for all study species, and/or if you collected variables not listed above",
                                                           trigger = "mouseenter click",
                                                           placement = "right")),
                     width = htmltools::validateCssUnit("50%")),

    ## brood data
    shiny::h5("Brood data"),
    shinyWidgets::pickerInput(inputId = "methods_broodDataTypes",
                              label = shiny::div("Variables collected at the brood level",
                                                 shiny::icon("circle-exclamation"),
                                                 tippy::tippy(text = shiny::icon("question-circle"),
                                                              tooltip = "You may select multiple variables",
                                                              trigger = "mouseenter click",
                                                              placement = "right")),
                              multiple = TRUE,
                              inline = FALSE,
                              width = "75%",
                              choices = broodDataTypes,
                              options = shinyWidgets::pickerOptions(noneSelectedText = "No variable selected")),
    shiny::textInput(inputId = "methods_broodDataTypes_others",
                     label = shiny::tags$span("Other variables/additional information",
                                              tippy::tippy(text = shiny::icon("question-circle"),
                                                           tooltip = "Please add details here; e.g., whether the variables were not monitored for all study species, and/or if you collected variables not listed above.",
                                                           trigger = "mouseenter click",
                                                           placement = "right")),
                     width = htmltools::validateCssUnit("50%")),

    ## genetic data
    shiny::h5("Genetic data"),
    shinyWidgets::pickerInput(inputId = "methods_geneticDataTypes",
                              label = shiny::div("Genetic data collected by sampling",
                                                 tippy::tippy(text = shiny::icon("question-circle"),
                                                              tooltip = "You may select multiple",
                                                              trigger = "mouseenter click",
                                                              placement = "right")),
                              multiple = TRUE,
                              inline = FALSE,
                              width = "75%",
                              choices = geneticDataTypes,
                              options = shinyWidgets::pickerOptions(noneSelectedText = "No sample selected")),
    shiny::textInput(inputId = "methods_geneticDataTypes_others",
                     label = shiny::tags$span("Other variables/additional information",
                                              tippy::tippy(text = shiny::icon("question-circle"),
                                                           tooltip = "Please add details here; e.g., whether the samples were not taken for all study species, and/or if you collected samples not listed above.",
                                                           trigger = "mouseenter click",
                                                           placement = "right")),
                     width = htmltools::validateCssUnit("50%")),

    ## genetic data
    shiny::h5("Environmental data"),
    shinyWidgets::pickerInput(inputId = "methods_environmentalDataTypes",
                              label = shiny::div("Types of environmental data collected",
                                                 tippy::tippy(text = shiny::icon("question-circle"),
                                                              tooltip = "You may select multiple",
                                                              trigger = "mouseenter click",
                                                              placement = "right")),
                              multiple = TRUE,
                              inline = FALSE,
                              width = "75%",
                              choices = environmentalDataTypes,
                              options = shinyWidgets::pickerOptions(noneSelectedText = "No data type selected")),
    shiny::textInput(inputId = "methods_environmentalDataTypes_others",
                     label = shiny::tags$span("Other variables/additional information",
                                              tippy::tippy(text = shiny::icon("question-circle"),
                                                           tooltip = "Please add details here; e.g., whether the data were not collected for all study species, and/or if you collected data types not listed above.",
                                                           trigger = "mouseenter click",
                                                           placement = "right")),
                     width = htmltools::validateCssUnit("50%")),


    ## other activities
    shiny::h5("Other activities"),
    shinyWidgets::pickerInput(inputId = "methods_otherActivities",
                              label = shiny::div("The following other activities were carried out",
                                                 tippy::tippy(text = shiny::icon("question-circle"),
                                                              tooltip = "You may select multiple activities",
                                                              trigger = "mouseenter click",
                                                              placement = "right")),
                              multiple = TRUE,
                              inline = FALSE,
                              width = "75%",
                              choices = otherActivities,
                              options = shinyWidgets::pickerOptions(noneSelectedText = "No activity selected")),
    shiny::textInput(inputId = "methods_otherActivities_others",
                     label = shiny::tags$span("Other activities/additional information",
                                              tippy::tippy(text = shiny::icon("question-circle"),
                                                           tooltip = "Please add details here; e.g., whether the activities were not carried out for all study species, and/or if you carried out activities not listed above.",
                                                           trigger = "mouseenter click",
                                                           placement = "right")),
                     width = htmltools::validateCssUnit("50%")),

    ### Submit button
    shiny::h3("Submit"),
    shiny::p("Make sure you have filled in all",
             shiny::strong("required fields"),
             shiny::icon("circle-exclamation"),
             "before you submit your metadata form."),
    shiny::p("By submitting the form, you agree with SPI-Birds data policy and terms of use."),
    shinyjs::disabled(shiny::actionButton(inputId = "submitButton",
                                          label = "Submit")),
    shiny::tags$br(),
    shiny::tags$br()

  ),

  # Thank you screen after metadata form is submitted
  shiny::conditionalPanel(
    condition = "output.formSubmitted",
    shiny::h3(shiny::textOutput("thanks"))
  ),

  # Credits
  shiny::hr(),
  shiny::em(
    shiny::span("Created by Stefan J.G. Vriend, SPI-Birds",
                shiny::HTML("&#8212;"),
                "Published:",
                format(Sys.Date(), "%d %B %Y")),
    shiny::br(),
    shiny::br(),
    style = "font-size: 75%"
  )

)
