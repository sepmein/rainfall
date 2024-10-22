# Load necessary libraries
library(ggplot2)
library(dplyr)

harmonic_analysis <- function(data, rainfall_column, by_column, analyse_annual_difference = TRUE) {
  rainfall_data <- data[rainfall_collumn] |> st_drop_geometry()
}
# Assume you have the monthly precipitation data (e.g., for one year)
# Replace this with your actual data
monthly_data <- c(1, 2, 5, 10, 15, 21, 23, 10, 10, 3, 1)

# Number of data points
n <- length(monthly_data)

# Apply FFT
fft_result <- fft(monthly_data)

# Calculate amplitudes
amplitude_spectrum <- Mod(fft_result)

# Calculate the corresponding frequencies
freqs <- (0:(n - 1)) / n

# Identify dominant harmonics
first_harmonic <- amplitude_spectrum[2]
second_harmonic <- amplitude_spectrum[3]

# Calculate the ratio of second to first harmonic
harmonic_ratio <- second_harmonic / first_harmonic

# Determine the regime based on the ratio
regime <- ifelse(harmonic_ratio > 1.0, "Biannual", "Annual")

# Print results
cat("First Harmonic Amplitude:", first_harmonic, "\n")
cat("Second Harmonic Amplitude:", second_harmonic, "\n")
cat("Harmonic Ratio:", harmonic_ratio, "\n")
cat("Regime:", regime, "\n")

# Plot the amplitude spectrum
amplitude_data <- data.frame(freq = freqs, amplitude = amplitude_spectrum)
ggplot(amplitude_data, aes(x = freq, y = amplitude)) +
  geom_line() +
  ggtitle("Amplitude Spectrum (Monthly Data)") +
  xlab("Frequency") + ylab("Amplitude") +
  theme_minimal()
