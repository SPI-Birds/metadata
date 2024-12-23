# metadata

> Code to process SPI-Birds metadata submissions through Jotform

## Introduction

As part of SPI-Birds Network and Database, we collect metadata of various studies on birds through our [metadata entry Jotform](https://eu.jotform.com/form/230361997667066). This R package provides the code to process Jotform's metadata submissions, and add them to the [SPI-Birds website](https://spibirds.org).

### Questions or feedback

If you have questions or feedback on the metadata form, or this R package, please reach out to us via the [issues page](https://github.com/SPI-Birds/metadata/issues) on this GitHub repository or by [email](mailto:spibirds@nioo.knaw.nl).

---

## Guide for the SPI-Birds Team

### Installation

```r
# Install from Github
remotes::install_github("SPI-Birds/metadata")
```

#### PhantomJS

Maps are created through screenshots of [leaflet](https://leafletjs.com/) maps, interactive html maps. For this, [PhantomJS](https://phantomjs.org/) needs to be installed.
```r
# Install PhantomJS through {webshot} (Windows only)
if(!webshot::is_phantomjs_installed()) {
  
  webshot::install_phantomjs()
  
}
```

### Workflow

#### Step 1: Load package

Load package environment.

```r
# Regular load
library(metadata)

# Alternatively, if you are in the R project of the development version
devtools::load_all(".")
```


#### Step 2: Check Google Sheet

Navigate to the SPI-Birds metadata Google Sheet.

```r
browseURL("https://docs.google.com/spreadsheets/d/1sNlpXSbZtGXD_gfvDRcGdUUmfepOVKOOfL6s4znBB20/")

```
Double check that all values for the metadata entry are filled in as expected, without typos.
Double check that the provided coordinates are correct. Sometimes custodians provide coordinates in degrees, minutes, seconds, which are somewhat of compared to decimal degrees.


#### Step 3: Convert Jotform entry to EML.xml

```r
# Convert metadata entry to EML
meta <- convert_to_eml("example@example.com")
```

#### Step 4: Add processed metadata to SPI-Birds internal tables

```r
# Add metadata to internal tables
add_metadata(meta)
```
#### Step 5: Create screenshot of Leaflet map

```r
# Create map
create_map(meta$siteID)
```

#### Step 6: Add metadata to website
