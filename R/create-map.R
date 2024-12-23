#' Create leaflet map of study site
#'
#' Create a static image of an interactive leaflet map for the SPI-Birds website.
#'
#' @param site Character indicating the siteID of the site. If NULL, a map will be generated for all sites.
#' @param zoom Integer indicating the zoom level. See \link[leaflet]{setView}.
#' @param tiles Character indicating the source for the base map. One of \link[leaflet]{providers}.
#' @param file_format Character indicating the format to save in. Either 'png' or 'html'.
#'
#' @export

# Function to make map for website
create_map <- function(site = NULL,
                       zoom = 12,
                       tiles = "OpenStreetMap",
                       file_format = c("png", "html")) {

  file_format <- match.arg(file_format)

  # Create icon to indicate study site's centroid
  icon <- leaflet::makeAwesomeIcon(
    text = fontawesome::fa("crow"),
    markerColor = "darkred"
  )

  if(!is.null(site)) {

    site <- site_codes |>
      dplyr::filter(.data$siteID == {{site}})

    # Select study site
    message(paste0("Selecting data for ",
                   dplyr::pull(site, "siteID"), " - ",
                   dplyr::pull(site, "siteName"), "..."))

    # Create and save map
    message("Creating leaflet map...")

    leaflet::leaflet(data = site) |>
      leaflet::setView(lng = site$decimalLongitude,
                       lat = site$decimalLatitude,
                       zoom = zoom) |>
      leaflet::addProviderTiles(provider = tiles) |>
      leaflet::addAwesomeMarkers(lng = ~decimalLongitude,
                                 lat = ~decimalLatitude,
                                 icon = icon,
                                 clusterOptions = leaflet::markerClusterOptions()) |>

      htmlwidgets::saveWidget(file = here::here("inst", "extdata", "maps",
                                                paste0(site$siteID, "-map.html")),
                              selfcontained = FALSE)

    if(file_format == "png") {

      message("Converting html widget into png...")

      webshot::webshot(url = here::here("inst", "extdata", "maps", paste0(site$siteID, "-map.html")),
                       file = here::here("inst", "extdata", "maps", paste0(site$siteID, "-map.png")),
                       vheight = 600, vwidth = 1400)

      # Remove other files/folders
      file.remove(here::here("inst", "extdata", "maps",
                             paste0(site$siteID, "-map.html")))

      unlink(here::here("inst", "extdata", "maps",
                        paste0(site$siteID, "-map", "_files")),
             recursive = TRUE)

    }

  } else {

    # Total map
    total_loc <- locs |>
      dplyr::filter(!is.na(decimalLongitude), !is.na(decimalLatitude))

    message("Creating leaflet map...")

    leaflet::leaflet(data = total_loc) |>
      leaflet::addProviderTiles(providers$OpenStreetMap) |>
      leaflet::addAwesomeMarkers(lng = ~decimalLongitude,
                                 lat = ~decimalLatitude,
                                 icon = icon,
                                 clusterOptions = leaflet::markerClusterOptions()) |>
      htmlwidgets::saveWidget(file = here::here("inst", "extdata", "maps",
                                                paste0("SPI-Birds", "-map.html")))

    if(file_format == "png") {

      message("Converting html widget into png...")

      webshot::webshot(url = here::here("inst", "extdata", "maps",
                                        paste0("SPI-Birds", "-map.html")),
                       file = here::here("inst", "extdata", "maps",
                                         paste0("SPI-Birds", "-map.png")),
                       vwidth = 1600, vheight = 1200)

      # Remove other files/folders
      file.remove(here::here("inst", "extdata", "maps",
                             paste0("SPI-Birds", "-map.html")))

      unlink(here::here("inst", "extdata", "maps",
                        paste0("SPI-Birds", "-map", "_files")),
             recursive = TRUE)

    }

  }

}
