# SPI-Birds metadata form submission via Shiny
# Inspired by https://github.com/daattali/UBC-STAT545/tree/master/shiny-apps/request-basic-info

#' Server set-up of metadata app
#' @importFrom utils write.csv
#' @param input The session's input object
#' @param output The session's output object


resultsDir <- file.path("metadata")
dir.create(resultsDir, recursive = TRUE, showWarnings = FALSE)

# Set app server
server <- function(input, output) {

  # Hide/show boxes
  shiny::observe({

    # metadataProvider: organizationName
    if(input$metadataProvider_organizationName_cb == TRUE) {

      shinyjs::show(id = "metadataProvider_organizationName")

      # Hide tick box if organizationName is filled in
      if(input$metadataProvider_organizationName != "") {

        shinyjs::hide(id = "metadataProvider_organizationName_cb")

      } else {

        shinyjs::show(id = "metadataProvider_organizationName_cb")

      }

    }

    if(input$metadataProvider_organizationName_cb == FALSE) {

      shinyjs::hide(id = "metadataProvider_organizationName")

    }

    # metadataProvider: electronicMailAddress
    if(input$metadataProvider_electronicMailAddress != "") {

      shinyjs::show(id = "metadataProvider_electronicMailAddress_display")

    }

    if(input$metadataProvider_electronicMailAddress == "") {

      shinyjs::hide(id = "metadataProvider_electronicMailAddress_display")

    }

    # contact fields: show if not the same as metadataProvider
    if(input$contact_cb == TRUE) {

      shinyjs::show(id = "contact_givenName")
      shinyjs::show(id = "contact_surName")
      shinyjs::show(id = "contact_organizationName_cb")
      shinyjs::show(id = "contact_organizationName")
      shinyjs::show(id = "contact_positionName")
      shinyjs::show(id = "contact_electronicMailAddress")
      shinyjs::show(id = "contact_onlineUrl")
      shinyjs::show(id = "contact_userId")

      # # contact: organizationName
      # if(input$contact_organizationName_cb == TRUE) {
      #
      #   shinyjs::show(id = "contact_organizationName")
      #
      #   # Hide tick box if organizationName is filled in
      #   if(input$contact_organizationName != "") {
      #
      #     shinyjs::hide(id = "contact_organizationName_cb")
      #
      #   } else {
      #
      #     shinyjs::show(id = "contact_organizationName_cb")
      #
      #   }
      #
      # }

      # contact: electronicMailAddress
      if(input$contact_electronicMailAddress != "") {

        shinyjs::show(id = "contact_electronicMailAddress_display")

      }

      if(input$contact_electronicMailAddress == "") {

        shinyjs::hide(id = "contact_electronicMailAddress_display")

      }

    } else {

      shinyjs::hide(id = "contact_givenName")
      shinyjs::hide(id = "contact_surName")
      shinyjs::hide(id = "contact_organizationName_cb")
      shinyjs::hide(id = "contact_organizationName")
      shinyjs::hide(id = "contact_positionName")
      shinyjs::hide(id = "contact_electronicMailAddress")
      shinyjs::hide(id = "contact_onlineUrl")
      shinyjs::hide(id = "contact_userId")

    }



    # geographicCoverage: boundingCoordinates (bounding box or centre point)
    if(input$geographicCoverage_coordinates == "the four margins (N, S, E, W) of a bounding box") {

      shinyjs::show(id = "geographicCoverage_northBoundingCoordinate")
      shinyjs::show(id = "geographicCoverage_southBoundingCoordinate")
      shinyjs::show(id = "geographicCoverage_westBoundingCoordinate")
      shinyjs::show(id = "geographicCoverage_eastBoundingCoordinate")
      shinyjs::hide(id = "geographicCoverage_latitude")
      shinyjs::hide(id = "geographicCoverage_longitude")

    } else if(input$geographicCoverage_coordinates == "a centre point") {

      shinyjs::show(id = "geographicCoverage_latitude")
      shinyjs::show(id = "geographicCoverage_longitude")
      shinyjs::hide(id = "geographicCoverage_northBoundingCoordinate")
      shinyjs::hide(id = "geographicCoverage_southBoundingCoordinate")
      shinyjs::hide(id = "geographicCoverage_westBoundingCoordinate")
      shinyjs::hide(id = "geographicCoverage_eastBoundingCoordinate")

    }

    # temporalCoverage: gap years
    if(input$temporalCoverage_continuous == "No") {

      shinyjs::show(id = "temporalCoverage_gaps")

    } else {

      shinyjs::hide(id = "temporalCoverage_gaps")

    }

  })

  # Add project members
  ## Track number of project members to render
  memberCounter <- shiny::reactiveValues(n = 0)

  shiny::observeEvent(input$addMember,
                      {memberCounter$n <- memberCounter$n + 1}) # Add

  shiny::observeEvent(input$removeMember,
                      {if(memberCounter$n > 0) memberCounter$n <- memberCounter$n - 1}) # Remove

  ## Render fields for each project member
  memberToggle <- shiny::reactive({

    n <- memberCounter$n

    if(n > 0) {

      shiny::isolate({

        lapply(seq_len(n), function(i) {

          shiny::tagList(

            # Header
            shiny::tags$br(),
            shiny::strong(paste0("Member #", i)),

            # First name
            shiny::textInput(inputId = paste0("personnel_givenName", i),
                             label = shiny::div("First name",
                                                shiny::icon("circle-exclamation")),
                             width = htmltools::validateCssUnit("50%")),

            # Surname
            shiny::textInput(inputId = paste0("personnel_surName", i),
                             label = shiny::div("Surname",
                                                shiny::icon("circle-exclamation")),
                             width = htmltools::validateCssUnit("50%")),

            # Organization
            shiny::textInput(inputId = paste0("personnel_organizationName", i),
                             label = shiny::div("Organization name",
                                                shiny::icon("circle-exclamation")),
                             width = htmltools::validateCssUnit("50%")),

            # Position
            shiny::textInput(inputId = paste0("personnel_positionName", i),
                             width = htmltools::validateCssUnit("50%"),
                             label = shiny::tags$span("Position",
                                                      shiny::icon("circle-exclamation"),
                                                      tippy::tippy(text = shiny::icon("question-circle"),
                                                                   tooltip = "Role (or title) of person within the organization; e.g., data manager, technician.",
                                                                   trigger = "mouseenter click",
                                                                   placement = "right"))),

            # Email
            shiny::textInput(inputId = paste0("personnel_electronicMailAddress", i),
                             width = htmltools::validateCssUnit("50%"),
                             label = shiny::div("Email address",
                                                shiny::icon("circle-exclamation"))),

            # Display email
            shinyWidgets::prettyRadioButtons(inputId = paste0("personnel_electronicMailAddress_display", i),
                                             label = "I allow SPI-Birds to display this email address in the metadata file and on the website. If you select 'No', the email address will only be known to the SPI-Birds team.",
                                             choices = c("Yes", "No"),
                                             inline = TRUE,
                                             shape = "curve",
                                             status = "primary",
                                             icon = shiny::icon("check")),

            # Website
            shiny::textInput(inputId = paste0("personnel_onlineUrl", i),
                             width = htmltools::validateCssUnit("50%"),
                             label = "Personal website"),

            # ORCID
            shiny::textInput(inputId = paste0("personnel_userId", i),
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

            # Project role
            shiny::textInput(inputId = paste0("personnel_role", i),
                             width = htmltools::validateCssUnit("50%"),
                             label = shiny::tags$span("Role",
                                                      shiny::icon("circle-exclamation"),
                                                      tippy::tippy(text = shiny::icon("question-circle"),
                                                                   tooltip = "Role of the person within the study",
                                                                   trigger = "mouseenter click",
                                                                   placement = "right")))

          )

        })

      })

    }

  })

  output$memberFields <- shiny::renderUI({memberToggle()})

  # Enable submit button when all required fields are filled
  shiny::observe({

    shinyjs::toggleState(id = "submitButton",
                         condition = all(unlist(sapply(requiredFields, function(x) input[[x]] != ""))))

  })

  # Ask confirmation
  shiny::observeEvent(input$submitButton, {

    shinyWidgets::ask_confirmation(
      inputId = "submitConfirm",
      title = "Please confirm submission of the metadata form",
      type = "info",
      closeOnClickOutside = TRUE,
      allowEscapeKey = TRUE,
      btn_colors = c("#999999", "#337ab7")
    )

  })

  # Confirmation count
  confirmed_status <- shiny::reactiveVal(0)

  shiny::observeEvent(input$submitConfirm, {
    if (isTRUE(input$submitConfirm)) {

      x <- confirmed_status() + 1
      confirmed_status(x)

    } else {

      x <- confirmed_status()
      confirmed_status(x)

    }
  }, ignoreNULL = TRUE)

  # Output thank you message when metadata are submitted
  output$thanks <- shiny::renderText({

    paste0("Thank you for submitting your metadata!")

  })

  # A dummy variable to indicate when the form was submitted
  output$formSubmitted <- shiny::reactive({

    FALSE

  })

  shiny::outputOptions(output, 'formSubmitted', suspendWhenHidden = FALSE)

  # Submit the form (if confirmed)
  shiny::observe({

    if (input$submitButton < 1 | confirmed_status() == 0) return(NULL)

    # Read the info into a data frame
    shiny::isolate(

      infoList <- t(sapply(names(input), function(x) x = input[[x]]))

    )

    # Generate a metadata file
    shiny::isolate(
      fileName <- paste0(
        paste(
          input$creator_organizationName,
          #digest::digest(infoList, algo = "md5"),
          sep = "_"
        ),
        ".csv"
      )
    )

    # Write out the results
    ### This code chunk writes a response and will have to change
    ### based on where we store persistent data
    utils::write.csv(x = infoList,
                     file = file.path(resultsDir, fileName),
                     row.names = FALSE)

    # Indicate the the form was submitted to show a thank you page so that the
    # user knows they're done
    output$formSubmitted <- shiny::reactive({ TRUE })

  })

}
