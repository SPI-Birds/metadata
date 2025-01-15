# metadata

> Code to process SPI-Birds metadata submissions through Jotform

## Introduction

As part of SPI-Birds Network and Database, we collect metadata of various studies on birds through our [metadata entry Jotform](https://eu.jotform.com/form/230361997667066). This R package provides the code to process Jotform's metadata submissions, and add them to the [SPI-Birds website](https://spibirds.org).

### Questions or feedback

If you have questions or feedback on the metadata form, or this R package, please reach out to us via the [issues page](https://github.com/SPI-Birds/metadata/issues) on this GitHub repository or by sending an email to [spibirds@nioo.knaw.nl](mailto:spibirds@nioo.knaw.nl).

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
On Mac, using Homebrew, type:
```
brew tap homebrew/cask
brew cask install phantomjs
```

### Access & editing rights

#### Google Sheet

Contact Stefan ([s.vriend@nioo.knaw.nl](mailto:s.vriend@nioo.knaw.nl)) to get access to the [SPI-Birds metadata Google Sheet](https://docs.google.com/spreadsheets/d/1sNlpXSbZtGXD_gfvDRcGdUUmfepOVKOOfL6s4znBB20/).

#### SPI-Birds website

Contact Stefan ([s.vriend@nioo.knaw.nl](mailto:s.vriend@nioo.knaw.nl)) to get editing rights to the [SPI-Birds website](https://spibirds.org) (hosted at NIOO-KNAW). This is done through a NIOO guest account, issued by NIOO's IT department, which might take some time.

### Workflow

#### Step 1: Load package

Load package environment.

```r
# Regular load
library(metadata)

# Alternatively, if you have opened the R project in the main directory of this repo
devtools::load_all(".")
```


#### Step 2: Check Google Sheet

Navigate to the SPI-Birds metadata Google Sheet.

```r
browseURL("https://docs.google.com/spreadsheets/d/1sNlpXSbZtGXD_gfvDRcGdUUmfepOVKOOfL6s4znBB20/")

```
Double check that all values for the metadata entry are filled in as expected, without typos. For example:

- check format of coordinates. Sometimes custodians provide coordinates in degrees, minutes, seconds as decimal degrees, which are somewhat off compared to actual decimal degrees.
- check format of DOI. It should start with one of: `doi:`, `https://doi.org/`, `doi.org/`


#### Step 3: Convert Jotform entry to EML.xml

```r
# Convert metadata entry to EML
# Use the email address with which you have access to the Google Sheet
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

