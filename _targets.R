# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  "sf",
  "targets",
  "readr",
  "lubridate",
  "tibble",
  "ggplot2"
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
    "/Users/sepmein/Library/CloudStorage/OneDrive-WorldHealthOrganization/02-ethiopia/1_data/1_shapefile/ETH_ADM1.shp"
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
      snt::sn_read_star(f_list_rainfall, "rainfall") |>
        snt::sn_st_aggregate(shapefile, median)
    }
  ),
  tar_target(
    export,
    rainfall |> st_drop_geometry() |> write_csv("rainfall.csv")
  ),
  tar_target(
    rainfall_adm_year_loop,
    {
      rainfall |>
        st_drop_geometry() |>
        mutate(year = year(dates)) |>
        # change this columns to match the columns to group by
        select(ADM1_NAME, year, rainfall) |>
        group_by(ADM1_NAME, year) |>
        tar_group()
    },
    iteration = "group"
  ),
  tar_target(
    rainfall_adm_loop,
    {
      rainfall |>
        st_drop_geometry() |>
        mutate(year = year(dates)) |>
        # change this columns to match the columns to group by
        select(ADM1_NAME, year, rainfall) |>
        group_by(ADM1_NAME) |>
        tar_group()
    },
    iteration = "group"
  ),
  tar_target(
    adm,
    "ADM1_NAME"
  ),
  tar_target(
    harmonic_per_unit_of_analysis_list,
    {
      adm_name <- rainfall_adm_year_loop |>
        distinct(ADM1_NAME) |>
        pull(ADM1_NAME)

      year <- rainfall_adm_year_loop |>
        distinct(year) |>
        pull(year)

      rainfall_data <- rainfall_adm_year_loop |>
        pull(rainfall)

      n <- length(rainfall_data)

      # Apply FFT
      fft_result <- fft(rainfall_data)

      # Calculate amplitudes
      amplitude_spectrum <- Mod(fft_result)

      # Identify dominant harmonics
      first_harmonic <- amplitude_spectrum[2]
      second_harmonic <- amplitude_spectrum[3]

      # Calculate the ratio of second to first harmonic
      harmonic_ratio <- second_harmonic / first_harmonic

      return(
        tibble(
          adm =  adm_name,
          year = year,
          harmonic = harmonic_ratio,
          mean = mean(rainfall_data, na.rm = TRUE),
          median = median(rainfall_data, na.rm = TRUE),
          standard_deviation = sd(rainfall_data, na.rm = TRUE)
      )
      )

    },
    pattern = map(rainfall_adm_year_loop),
    iteration = "list"
  ),
  tar_target(
    harmonic_per_unit_of_analysis,
    {
      combine_tibbles <- function(x) {
        x
      }

      result <- harmonic_per_unit_of_analysis_list |> purrr::map_dfr( combine_tibbles)
    }
  ),
  tar_target(
    rainfall_plot,
    {
      order = harmonic_sequence |> pull(adm)

      rainfall$ADM1_NAME <-
        factor(rainfall$ADM1_NAME, levels = order)

      rainfall |>
        ggplot(aes(dates, ADM1_NAME, fill= rainfall)) +
        geom_tile(width = 30)   +
        scale_fill_gradient(low="white", high="#008ECE") +
        scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
        #scale_y_discrete(expand=c(0,0)) +
        #coord_fixed() +
        ylab("Province") +
        xlab("") +
        sn_theme()

      #+
       # hrbrthemes::theme_ipsum()
      # Clean theme


    }
  ),
  tar_target(
    harmonic_sequence,
    harmonic_per_unit_of_analysis |>
      group_by(adm) |>
      summarise(harmonic = mean(harmonic)) |>
      arrange(harmonic)
  ),


)
