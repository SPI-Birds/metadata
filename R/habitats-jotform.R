# Make SPI-Birds habitat nested list for Jotform
# SPI-Birds Metadata Form on Jotform: https://form.jotform.com/230361997667066

# Data
habitats |>
  dplyr::filter(.data$habitatLevel <= 3) |> # Remove habitat level 4-8
  tidyr::unite("habitatName", "habitatID", "habitatType", sep = ": ", remove = FALSE) |> # Combine habitatID & habitatType into habitatName
  dplyr::mutate(habitatGroup = stringr::str_sub(.data$habitatID, 1, 1)) |> # Create habitat group
  dplyr::group_by(habitatParent = stringr::str_sub(.data$habitatID, 1, .data$habitatLevel - 1)) |> # Create habitat parent (letter) as grouping variable
  dplyr::group_modify(~ tibble::add_row(.x, habitatName = ".",
                                        habitatLevel = unique(.x$habitatLevel),
                                        habitatGroup = unique(.x$habitatGroup))) |> # Add a '.' row per group-level combination which equals an empty option for Jotform
  dplyr::mutate(habitatID = dplyr::case_when(is.na(.data$habitatID) ~ paste0(.data$habitatParent, "z"),
                                             TRUE ~ .data$habitatID)) |> # Make sure that '.' are at the end of each hierarchy
  #dplyr::filter((.data$habitatLevel == 1 & .data$habitatName != ".") | .data$habitatLevel > 1) |> # Remove empty options for hierarchy level 1
  dplyr::rowwise() |>
  dplyr::mutate(habitatName = stringr::str_pad(.data$habitatName,
                                               width = nchar(.data$habitatName) + .data$habitatLevel - 1,
                                               side = "left",
                                               pad = " ")) |> # Create hierarchy by adding leading spaces dependent on the habitatLevel
  dplyr::arrange(.data$habitatGroup, .data$habitatID)

# Copy list from this .txt file
write.table(habitats$habitatName,
            file = here::here("inst", "extdata", "habitats-jotform.txt"),
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)

# Remove afterwards
file.remove(here::here("inst", "extdata", "habitats-jotform.txt"))
