################################################################################
# Function to create metadata files from an imported csv file
################################################################################


# Load required libraries

librarian::shelf(dplyr,
                 tidyr,
                 lubridate)

# Define a function to retrieve metadata from a data frame and save it to a text file
get_metadata <- function(data_df, file_path) {
  # Extract file-specific information
  file_name <- tools::file_path_sans_ext(basename(file_path))
  file_size_MB <- round(file.info(file_path)$size / (1024 * 1024), 2)  # Convert to MB
  creation_date <- format(as.Date(file.info(file_path)$ctime), "%m/%d/%y")
  file_type <- tools::file_ext(file_path)
  
  # Define output directory and file path
  metadata_dir <- "./metadata"
  output_txt_path <- file.path(metadata_dir, paste0("metadata_", file_name, ".txt"))
  
  # Extract data-specific information
  dataset_length <- nrow(data_df)
  variables_included <- colnames(data_df)
  variable_formats <- sapply(data_df, class)
  complete_case_columns <- colnames(data_df)[colSums(is.na(data_df)) == 0]
  incomplete_case_columns <- colnames(data_df)[colSums(is.na(data_df)) > 0]
  na_columns <- colnames(data_df)[colSums(is.na(data_df)) > 0]
  
  # Ensure the metadata directory exists
  if (!dir.exists(metadata_dir)) {
    dir.create(metadata_dir)
  }
  
  # Write the metadata and additional information to a text file
  sink(output_txt_path)
  cat("File Name:", file_name, "\n\n")
  cat("File Size (in MB):", file_size_MB, "\n\n")
  cat("Creation Date (mm/dd/yy):", creation_date, "\n\n")
  cat("File Type:", file_type, "\n\n")
  cat("Length of the dataset (number of rows):", dataset_length, "\n\n")
  cat("Variables included in the dataset:", paste(variables_included, collapse = ", "), "\n\n")
  cat("Format of variables in the dataset:\n")
  print(variable_formats)
  cat("\n")
  cat("Names of columns with complete cases:", paste(complete_case_columns, collapse = ", "), "\n\n")
  cat("Names of columns with incomplete cases:", paste(incomplete_case_columns, collapse = ", "), "\n\n")
  cat("Names of columns with NA values:", paste(na_columns, collapse = ", "), "\n\n")
  sink()
  
  return(data_df)
}



