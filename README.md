# metadata

> Code to process SPI-Birds metadata submissions through Jotform

## Introduction

As part of SPI-Birds Network and Database, we collect metadata of various studies on birds through our [metadata entry Jotform](https://eu.jotform.com/form/230361997667066). This R package provides the code to process Jotform's metadata submissions, and add them to the [SPI-Birds website](https://spibirds.org).

### Questions or feedback

If you have questions or feedback on the metadata form, or this R package, please reach out to us via the [issues page](https://github.com/SPI-Birds/metadata/issues) on this GitHub repository or by sending an email to [spibirds\@nioo.knaw.nl](mailto:spibirds@nioo.knaw.nl).

------------------------------------------------------------------------

## Guide for the SPI-Birds Team

### Installation

#### PhantomJS

Maps are created through screenshots of [leaflet](https://leafletjs.com/) maps, interactive html maps. For this, [PhantomJS](https://phantomjs.org/) needs to be installed.

``` r
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

#### GitHub repository

If you have troubles cloning this repository locally, contact Stefan ([s.vriend\@nioo.knaw.nl](mailto:s.vriend@nioo.knaw.nl)) to get access.

#### Google Sheets

Contact Stefan ([s.vriend\@nioo.knaw.nl](mailto:s.vriend@nioo.knaw.nl)) to get access to the [SPI-Birds metadata sheet](https://docs.google.com/spreadsheets/d/1sNlpXSbZtGXD_gfvDRcGdUUmfepOVKOOfL6s4znBB20/) and the [SPI-Birds overview sheet](https://docs.google.com/spreadsheets/d/1LoTxe8nIb2qXKagm9ATYzG2NeLp9KHMC9oRb3uKsw1w/edit?gid=1178676937#gid=1178676937).

#### SPI-Birds website

To get access to the SPI-Birds website, which is part of NIOO's web sites, you first have to log in through an eduID associated with your email address.

1. Go to [https://nioo.knaw.nl/en](https://nioo.knaw.nl/en).  
2. Click 'Log in' in the top right.  
3. Click 'Log in'.  
4. Click on 'Use another account'.  
5. Click on 'eduID (NL)'.
6. Click on 'No eduID? Create one!'.
7. Provide email address, first name and last name.
8. Read and agree to the terms of serviec and privacy policy.
9. Click 'Request your eduID'.
10. Go to your email and verify your email address for your eduID. You should then receive an email confirming that your eduID has been created.

Once yourd eduID is set up and linked to the NIOO website, contact Stefan ([s.vriend\@nioo.knaw.nl](mailto:s.vriend@nioo.knaw.nl)) to get editing rights to the [SPI-Birds website](https://spibirds.org). This is done via by the web service team of NIOO, and might take some time to be completed.

### Workflow

#### 1. Pull latest changes & load package

Pull the latest changes of this repository.

``` r
git pull
```

Load package developer environment.

``` r
# Open the R project in the main directory of this repo and load complete package
devtools::load_all(".")
```

#### 2. Check Google Sheet

Navigate to the SPI-Birds metadata Google Sheet.

``` r
browseURL("https://docs.google.com/spreadsheets/d/1sNlpXSbZtGXD_gfvDRcGdUUmfepOVKOOfL6s4znBB20/")
```

Double check that all values for the metadata entry are filled in as expected, without typos. For example:

-   check format of coordinates. Sometimes custodians provide coordinates in degrees, minutes, seconds as decimal degrees, which are somewhat off compared to actual decimal degrees.
-   check whether the DOI is resolvable. DOIs do not necessarily need a prefix for the script to read them correctly. If they do have a prefix, it should be one of: `doi:`, `https://doi.org/`, `doi.org/`.

#### 3. Convert Jotform entry to EML.xml

``` r
# Convert metadata entry to EML
# Use the email address with which you have access to the Google Sheet
meta <- convert_to_eml("example@example.com")
```
The code prompts you to pick a three-letter code for the study site. These can be the first three letters of the name, or the three starting letters if the study site consists of minimally three words. The script will prompt you when a code has already been taken. Please use the [SPI-Birds overview sheet](https://docs.google.com/spreadsheets/d/1LoTxe8nIb2qXKagm9ATYzG2NeLp9KHMC9oRb3uKsw1w/edit?gid=1178676937#gid=1178676937) for inspiration how other study names relate to their three-letter codes.

The code might also prompt you to select a taxon id associated with a species. Enter the **row number** of the record that matches the species. Most often this is the record where rank = species (often row number 1).

#### 4. Add processed metadata to SPI-Birds internal tables

``` r
# Add metadata to internal tables
add_metadata(meta)

# Reload package environment
devtools::load_all(".")
```
The code prompts you to provide a code for the institution associated with the metadata submission. There is no limit to the number of letters you can use here. Again, please use the [SPI-Birds overview sheet](https://docs.google.com/spreadsheets/d/1LoTxe8nIb2qXKagm9ATYzG2NeLp9KHMC9oRb3uKsw1w/edit?gid=1178676937#gid=1178676937) for inspiration how other institutions relate to their codes.

#### 5. Create screenshot of Leaflet map

``` r
create_map(meta$siteID)
```

#### 6. Add metadata to website

##### a. Open a recent metadata web page

We use a recent metadata web page as a template for the web page of the new metadata submission.

1. Go to [https://nioo.knaw.nl/en](https://nioo.knaw.nl/en).
2. Log in to the website using your eduID.

> [!NOTE]
> If you do not have an eduID yet, please follow [these instructions](#spi-birds-website).

3. Click on `Content`.
4. Select as `Inhoudstype` (content type) `Populatie` and click `Filter`.
5. Find one of the recent created web pages and click `Edit`.

![](inst/extdata/images/select-populatie.jpg)

From here on, the instructions will refer to this web page as the **template**.


##### b. Create a new page for the metadata submission

6. In a second tab, go to [https://nioo.knaw.nl/en](https://nioo.knaw.nl/en).
7. Hover over to `Content` > `Add Content` and click `Populatie`.


#### c. Fill new page with metadata

8. For **Title**, fill in the name of the study site.
9. For **Summary**, copy the text from the template and replace the codes, site name, and country.
10. For **Main image**, click `Add media`.
    - Click `Choose file`.
    - Find the map in `~\metadata\inst\extdata\maps` and open.
    - For `Language`, select English.
    - For `Alternative text`, fill in *Map of \<site name\>, \<country\>*.
    - For `Credits`, fill in *OpenStreetMap*.
    - Click `Save` and `Insert selected`.
11. For **Latitude** and **Longitude**, copy the coordinates from the xml file.
12. Under **Metadata**
    - Click `Choose file`
    - Find the xml file in *~\metadata\inst\extdata\eml* and open
13. Under **Dataset Request**
    - Leave **URL** empty
    - Leave **Link text** empty
14. Under **Details**
    - For **Country**, select the country (*see note below)
    - For **Species**, select the species (*see note below)
    - For **Data pipeline**, keep default (`No`)
    - For **Max. nr. of nestboxes**, fill in if relevant
    - For **Nests monitoerd**, leave empty
    - For **Start year**, select one of three options. Note that the direction of the arrows is wrong
    - For **Running period**, tick `Current` if the study is ongoing
    - For **Starts**, fill in the first year of the study
    - For **Ends**, fill in the last year of the study. This field disappears when the `Current` button is ticked
    - For **ID data**, select relevant mark types
    - For **Environmental data**, select relevant measurements
    - For **Individual data**, select relevant measurements
    - For **Habitat**, select relevant habitat *if available*
    - For **Genetic data**, select relevant samples taken
    - For **Basic breeding data**, click `Yes`. This should always be `Yes`, because otherwise the study is not fit for SPI-Birds
    - For **Winter data**, select the relevant activities
    - For **Feeding at nest data**, select whether feeding activity was measured

> [!NOTE]
> If country and/or species are new, check section (--) to see how to add them to the list of options.

### 7. Commit and push changes to GitHub

Commit:

-   updated internal tables in inst/extdata
-   archived internal tables in inst/extdata/archive

Use a concise and informative commit message, such as "Process submission for \<siteID\>" or "Add metadata for \<siteID\>", where \<siteID\> is the three-letter code for the submitted entry.
