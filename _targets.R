# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  "sf",
  "targets",
  "readr"
)
# packages to read DHIS2 API
pacman::p_load_gh("WorldHealthOrganization/snt")


# Set target options:
tar_option_set(
  packages = c("snt", "sf", "readr") # packages that your targets need to run
)

options(clustermq.scheduler = "multicore")

future::plan(future.callr::callr)

tar_source()

list(
  tar_target(
    rainfall_file_list,
    "/Users/sepmein/Library/CloudStorage/OneDrive-个人/10-40_work/snt-data/Global/Data/CHIRPS_Global_raster_files/chirps-v2.0.*yyyy*.*mm*.tif"
  ),
  tar_target(
    shapefile_path,
    "/Users/sepmein/Library/CloudStorage/OneDrive-WorldHealthOrganization/ethieopia/1_data/1_shapefile/ETH_ADM2.shp"
  ),
  tar_target(
    f_list_rainfall,
    snt::sn_get_files(rainfall_file_list),
    cue = tar_cue("always")
    ),
  tar_target(shapefile, read_sf(shapefile_path) |> sf::st_make_valid() |> sf::st_simplify()),
  tar_target(
    rainfall,
    {
      browser()
      snt::sn_read_star(f_list_rainfall, "rainfall") |>
        snt::sn_st_aggregate(shapefile, mean)
    }
  ),
  tar_target(
    export,
    rainfall |> st_drop_geometry() |> write_csv("rainfall.csv")
  ),
  tar_target(

  ),
  tar_target(
    harmonic_per_unit_of_analysis,
    {
      harmonic_analysis(

      )
    }
  )
)
