#' Make SPI-Birds habitat nested list for Jotform
#'
#' Transform .csv of EUNIS habitats (hierarchical level 1-3) into a format for import to SPI-Birds metadata entry form (Jotform). Codes of level 4-8 are discarded in the Jotform, but may still be provided by metadata providers if relevant.
#'
#' @param path Character specifying the name of the directory where the output is stored.
#'
#' @return A text file with Jotform-formatted that can be directly added into the appropriate field in the Jotform builder.

create_habitats_jotform <- function(path) {

  habitats_jotform <- habitats |>
    # Remove habitat level 4-8
    dplyr::filter(.data$habitatLevel <= 3) |>
    # Combine habitatID & habitatType into habitatName
    tidyr::unite("habitatName", "habitatID", "habitatType", sep = ": ", remove = FALSE) |>
    # Create habitat group
    dplyr::mutate(habitatGroup = stringr::str_sub(.data$habitatID, 1, 1)) |>
    # Create habitat parent (letter) as grouping variable
    dplyr::group_by(habitatParent = stringr::str_sub(.data$habitatID, 1, .data$habitatLevel - 1)) |>
    # Add a '.' row per group-level combination which equals an empty option for Jotform
    dplyr::group_modify(~ tibble::add_row(.x, habitatName = ".",
                                          habitatLevel = unique(.x$habitatLevel),
                                          habitatGroup = unique(.x$habitatGroup))) |>
    # Make sure that '.' are at the end of each hierarchy
    dplyr::mutate(habitatID = dplyr::case_when(is.na(.data$habitatID) ~ paste0(.data$habitatParent, "z"),
                                               TRUE ~ .data$habitatID)) |>
    dplyr::rowwise() |>
    # Create hierarchy by adding leading spaces dependent on the habitatLevel
    dplyr::mutate(habitatName = stringr::str_pad(.data$habitatName,
                                                 width = nchar(.data$habitatName) + .data$habitatLevel - 1,
                                                 side = "left",
                                                 pad = " ")) |>
    dplyr::arrange(.data$habitatGroup, .data$habitatID)

  write.table(habitats_jotform$habitatName,
              file = paste0(path, "/habitats-jotform.txt"),
              row.names = FALSE,
              col.names = FALSE,
              quote = FALSE)

}
