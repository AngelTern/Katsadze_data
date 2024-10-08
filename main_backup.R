library(readxl)
library(dplyr)
library(rstudioapi)
#library(jsonlite)
library(tidyr)
library(ggplot2)
library(writexl)

if (requireNamespace("rstudioapi", quietly = TRUE)) {
  # Print a message indicating the script is running in RStudio
  print("Running in RStudio")
  
  # Get the path of the active script
  script_path <- rstudioapi::getActiveDocumentContext()$path
  print(paste("Script path:", script_path))
  
  if (!is.null(script_path) && script_path != "") {
    # Extract the directory from the script path
    script_dir <- dirname(script_path)
    print(paste("Script directory:", script_dir))
    
    # Set the working directory to the script's directory
    setwd(script_dir)
    
    # Print the new working directory
    print(paste("New working directory:", getwd()))
  } else {
    print("Script path is null or empty. Ensure the script is sourced from an active RStudio document.")
  }
} else {
  stop("This script requires RStudio to run.")
}

excel_files <- list.files(file.path(script_dir, "data_main"), pattern = "\\.xlsx$", full.names = TRUE)

# Function to create valid R list element names from file names
make_valid_name <- function(file_path) {
  file_name <- basename(file_path) # Get the base name of the file
  file_name <- tools::file_path_sans_ext(file_name) # Remove the file extension
  file_name <- make.names(file_name) # Make it a valid R list element name
  return(file_name)
}

# Initialize an empty list to store the data frames
data_list <- list()

# Iterate over the list of Excel files and read each one
for (file in excel_files) {
  # Create a valid list element name from the file name
  var_name <- make_valid_name(file)
  
  # Read the Excel file and store it in the list with the name
  data_list[[var_name]] <- read_excel(file)
}

# Filtering criteria
columns_to_keep_1st_revision <- c("ReportCode", "IdCode", "ReportYear", "FVYear", "CategoryMain", "FormName",
                                  "SheetName", "LineItemGEO", "LineItemENG", "Value", "GEL", "LineItem")

# Define necessary variables lists
variables_financial_non_financial <- list('Cash and cash equivalents', 'Current Inventory', 'Non current inventory', 'Trade receivables',
                                          'Biological assets', 'Other current assets', 'Other non current assets', 'Property, plant and equipment',
                                          'Total assets', 'Trade payables', 'Provisions for liabilities and charges', 'Total liabilities',
                                          'Share premium', 'Treasury shares', 'Retained earnings / (Accumulated deficit)', 'Other reserves',
                                          'Total equity', 'Total liabilities and equity', 'Cash advances made to other parties', 'Investment property',
                                          'Investments in subsidiaries', 'Goodwill', 'Other intangible assets', 'Finance lease payable', 'Unearned income',
                                          'Current borrowings', 'Non current borrowings', 'Received grants', 'Total current assets', 'Total current liabilities',
                                          'Share capital')

variables_financial_other <- list('Cash and cash equivalents', 'Inventories', 'Trade receivables',
                                  'Biological assets', 'Other current assets', 'Other non current assets', 'Property, plant and equipment',
                                  'Total assets', 'Trade payables', 'Provisions for liabilities and charges', 'Total liabilities',
                                  'Share premium', 'Treasury shares', 'Retained earnings / (Accumulated deficit)', 'Other reserves',
                                  'Total equity', 'Total liabilities and equity', 'Cash advances made to other parties', 'Investment property',
                                  'Investments in subsidiaries', 'Goodwill', 'Other intangible assets', 'Finance lease payable', 'Unearned income',
                                  'Current borrowings', 'Non current borrowings', 'Received grants', 'Total current assets', 'Total current liabilities',
                                  'Share capital')

variables_profit_loss <- list('Net Revenue', 'Cost of goods sold', 'Gross profit', 'Other operating income',
                              'Personnel expense', 'Rental expenses', 'Depreciation and amortisation',
                              'Other administrative and operating expenses', 'Operating income', 
                              'Impairment (loss)/reversal of financial assets', 'Net gain (loss) from foreign exchange operations', 'Dividends received',
                              'Other net operating income/(expense)', 'Profit/(loss) before tax from continuing operations',
                              'Income tax', 'Profit/(loss)', 'Revaluation reserve of property, plant and equipment',
                              'Other (include Share of associates and joint ventures in revaluation reserve of property, plant and equipment and defined benefit obligation)',
                              'Total other comprehensive (loss) income', 'Total comprehensive income / (loss)')

variables_cash_flow <- list('Net cash from operating activities', 'Net cash used in investing activities',
                            'Net cash raised in financing activities', 'Net cash inflow for the year',
                            'Effect of exchange rate changes on cash and cash equivalents',
                            'Cash at the beginning of the year', 'Cash at the end of the year')

## Initialize a new list to store the corrected dataframes
data_list_adjusted <- list()

# Define the correct_lineitems function
correct_lineitems <- function(df) {
  df <- df %>%
    # Apply the initial filtering
    #select(all_of(columns_to_keep_1st_revision)) %>%
    filter(CategoryMain != "III ჯგუფი") %>%
    filter(FormName != "ფინანსური ინსტიტუტებისთვის (გარდა მზღვეველებისა)") %>%
    
    # Apply the corrections to FormName and SheetName
    mutate(
      FormName = case_when(
        FormName == "არაფინანსური ინსტიტუტებისთვის" ~ "non-financial institutions",
        FormName == "გამარტივებული ფორმები მესამე კატეგორიის საწარმოებისთვის" ~ "Cat III forms",
        FormName == "მეოთხე კატეგორიის საწარმოთა ანგარიშგების ფორმები" ~ "Cat IV forms",
        TRUE ~ FormName
      ),
      SheetName = case_when(
        SheetName == "საქმიანობის შედეგები" ~ "profit-loss",
        SheetName == "ფინანსური მდგომარეობა" ~ "financial position",
        SheetName == "ფულადი სახსრების მოძრაობა" ~ "cash flow",
        TRUE ~ SheetName
      )
    ) %>%
    
    # Apply the corrections to LineItemENG and LineItemGEO
    mutate(
      LineItemENG = case_when(
        LineItemENG == "Retained earnings (Accumulated deficit)" ~ "Retained earnings / (Accumulated deficit)",
        LineItemENG == "Impairment loss/reversal of  financial assets" ~ "Impairment (loss)/reversal of financial assets",
        LineItemENG == "Total comprehensive income" ~ "Total comprehensive income / (loss)",
        LineItemENG == "Total comprehensive income(loss)" ~ "Total comprehensive income / (loss)",
        LineItemENG == "Prepayments" ~ "Cash advances made to other parties",
        LineItemENG == "Cash advances to other parties" ~ "Cash advances made to other parties",
        LineItemENG == 'Share capital (in case of Limited Liability Company - "capital", in case of cooperative entity - "unit capital"' ~ "Share capital",
        LineItemENG == "- inventories" ~ "Inventories",
        TRUE ~ LineItemENG
      ),
      LineItemGEO = case_when(
        LineItemGEO == "ამონაგები" ~ "ნეტო ამონაგები",
        LineItemGEO == "სხვა პირებზე ავანსებად და სესხებად გაცემული ფულადი სახსრები" ~ "სხვა მხარეებზე ავანსებად გაცემული ფულადი სახსრები",
        TRUE ~ LineItemGEO
      )
    ) %>%
    
    # Convert 'Value' to numeric if it exists
    mutate(Value = if ("Value" %in% colnames(df)) as.numeric(Value) else Value) %>%
    
    # Adjust 'Value' for specific cases
    mutate(
      Value = case_when(
        GEL == ".000 ლარი" & !is.na(Value) ~ Value * 1000,
        TRUE ~ Value
      )
    ) %>%
    
    # Apply filtering based on FormName, SheetName, and LineItemENG
    filter(!(FormName == "non-financial institutions" & SheetName == "financial position" & !LineItemENG %in% variables_financial_non_financial)) %>%
    filter(!(FormName != "non-financial institutions" & SheetName == "financial position" & !LineItemENG %in% variables_financial_other)) %>%
    filter(!(SheetName == "profit-loss" & !LineItemENG %in% variables_profit_loss)) %>%
    filter(!(SheetName == "cash flow" & !LineItemENG %in% variables_cash_flow)) %>%
    
    # Arrange the dataframe by ReportCode
    arrange(ReportCode)
  
  return(df)
}

correct_geo_dfs <- function(df) {
  df <- df %>%
    # Check if 'Category' or 'CategoryMain' exists before applying the filter
    filter(if ("Category" %in% colnames(df)) Category != "III ჯგუფი" else if ("CategoryMain" %in% colnames(df)) CategoryMain != "III ჯგუფი" else TRUE) %>%
    filter(FormName != "ფინანსური ინსტიტუტებისთვის (გარდა მზღვეველებისა)") %>%
    
    # Apply the corrections to FormName and SheetName
    mutate(
      FormName = case_when(
        FormName == "არაფინანსური ინსტიტუტებისთვის" ~ "non-financial institutions",
        FormName == "გამარტივებული ფორმები მესამე კატეგორიის საწარმოებისთვის" ~ "Cat III forms",
        FormName == "მეოთხე კატეგორიის საწარმოთა ანგარიშგების ფორმები" ~ "Cat IV forms",
        TRUE ~ FormName
      ),
      SheetName = case_when(
        SheetName == "საქმიანობის შედეგები" ~ "profit-loss",
        SheetName == "ფინანსური მდგომარეობა" ~ "financial position",
        SheetName == "ფულადი სახსრების მოძრაობა" ~ "cash flow",
        TRUE ~ SheetName
      )
    ) %>%
    mutate(LineItem = case_when(
      LineItem == "ამონაგები" ~ "ნეტო ამონაგები",
      LineItem == "სხვა პირებზე ავანსებად და სესხებად გაცემული ფულადი სახსრები" ~ "სხვა მხარეებზე ავანსებად გაცემული ფულადი სახსრები",
      TRUE ~ LineItem
    )) %>%
    
    # Convert 'Value' to numeric if it exists
    mutate(Value = if ("Value" %in% colnames(df)) as.numeric(Value) else Value) %>%
    
    # Adjust 'Value' for specific cases
    mutate(
      Value = case_when(
        GEL == ".000 ლარი" & !is.na(Value) ~ Value * 1000,
        TRUE ~ Value
      )
    )
  return(df)
}

# Initialize two lists: one for adjusted dataframes, one for those without LineItemENG
data_list_adjusted <- list()
data_list_no_eng <- list()

# Iterate over each dataframe in the data_list
for (i in seq_along(data_list)) {
  
  # Access the current dataframe
  df <- data_list[[i]] 
  
  # Check if 'LineItemENG' exists in the current dataframe
  if (!"LineItemENG" %in% colnames(df)) {
    # Correct the dataframe and save it into 'data_list_no_eng'
    df_geo_corrected <- correct_geo_dfs(df)
    data_list_no_eng[[names(data_list)[i]]] <- df_geo_corrected
  } else {
    # Step 1: Apply the specific filter only if LineItemENG exists
    df <- df %>%
      filter(!(SheetName == "profit-loss" & LineItemENG == "Inventories"))
    
    # Step 2: Correct the line items if 'LineItemENG' exists
    df_corrected <- correct_lineitems(df)
    
    # Step 3: Save the corrected dataframe to 'data_list_adjusted'
    data_list_adjusted[[names(data_list)[i]]] <- df_corrected
    
    # Step 4: Check and print variables for financial sections
    df_filtered_financial_non_financial <- df_corrected %>%
      filter(FormName == "non-financial institutions" & SheetName == "financial position")
    
    if (all(variables_financial_non_financial %in% df_filtered_financial_non_financial$LineItemENG) == TRUE) {
      print(paste("All found in financial_non_financial for", names(data_list)[i], ":", TRUE))
    } else {
      print(paste("Variables not found in financial_non_financial for", names(data_list)[i], ":", 
                  setdiff(variables_financial_non_financial, df_filtered_financial_non_financial$LineItemENG)))
    }
    
    # Step 5: Filter for financial_other and print result
    df_filtered_financial_other <- df_corrected %>%
      filter(FormName != "non-financial institutions" & SheetName == "financial position")
    
    if (all(variables_financial_other %in% df_filtered_financial_other$LineItemENG) == TRUE) {
      print(paste("All found in financial_other for", names(data_list)[i], ":", TRUE))
    } else {
      print(paste("Variables not found in financial_other for", names(data_list)[i], ":", 
                  setdiff(variables_financial_other, df_filtered_financial_other$LineItemENG)))
    }
    
    # Step 6: Filter for profit_loss and print result
    df_filtered_profit_loss <- df_corrected %>%
      filter(SheetName == "profit-loss")
    
    if (all(variables_profit_loss %in% df_filtered_profit_loss$LineItemENG) == TRUE) {
      print(paste("All found in profit_loss for", names(data_list)[i], ":", TRUE))
    } else {
      print(paste("Variables not found in profit_loss for", names(data_list)[i], ":", 
                  setdiff(variables_profit_loss, df_filtered_profit_loss$LineItemENG)))
    }
    
    # Step 7: Filter for cash_flow and print result
    df_filtered_cash_flow <- df_corrected %>%
      filter(SheetName == "cash flow")
    
    if (all(variables_cash_flow %in% df_filtered_cash_flow$LineItemENG) == TRUE) {
      print(paste("All found in cash_flow for", names(data_list)[i], ":", TRUE))
    } else {
      print(paste("Variables not found in cash_flow for", names(data_list)[i], ":", 
                  setdiff(variables_cash_flow, df_filtered_cash_flow$LineItemENG)))
    }
  }
}

combined_variable_list <- union(
  union(variables_financial_non_financial, variables_financial_other),
  union(variables_profit_loss, variables_cash_flow)
)

# Function to return a list of LineItemENG and corresponding unique LineItemGEO values
check_unique_geo_values <- function(df, variables_list) {
  result_list <- list()  # Initialize an empty list to store the found results
  missing_variables <- c()  # Initialize a vector to store missing variables
  
  for (var in variables_list) {
    if (var %in% df$LineItemENG) {
      # Filter rows where LineItemENG matches the variable
      filtered_df <- df %>% filter(LineItemENG == var)
      
      # Get the unique LineItemGEO values
      unique_geo_values <- unique(filtered_df$LineItemGEO)
      
      # Store the result as a named list (LineItemENG and its corresponding LineItemGEO values)
      result_list[[var]] <- unique_geo_values
    } else {
      # If the variable is not found, add it to the missing variables list
      missing_variables <- c(missing_variables, var)
    }
  }
  
  # Return both found results and missing variables
  return(list(found = result_list, missing = missing_variables))
}

# Initialize an empty list to store the results for all dataframes
all_results <- list()

# Iterate over each dataframe in data_list_adjusted and store the result
for (i in seq_along(data_list_adjusted)) {
  if ("LineItemENG" %in% colnames(data_list_adjusted[[i]])) {
    df <- data_list_adjusted[[i]]
    
    # Call the function and store the result in a named list
    result <- check_unique_geo_values(df, combined_variable_list)
    
    # Store the result for each dataframe in a named element of all_results
    all_results[[paste("DataFrame", i)]] <- result
    
    # Output the found and missing variables for this dataframe
    cat(paste("\nFor DataFrame", i, ":\n"))
    
    # Print found variables and their corresponding LineItemGEO
    if (length(result$found) > 0) {
      cat("Found variables and their LineItemGEO values:\n")
      print(result$found)
    }
    
    # Print missing variables
    if (length(result$missing) > 0) {
      cat("\nMissing variables from LineItemENG:\n")
      print(result$missing)
    } else {
      cat("All variables found in LineItemENG.\n")
    }
  }
}

# Function to check the consistency of LineItemENG-LineItemGEO pairs across dataframes
check_consistency_across_dataframes <- function(all_results) {
  # Initialize the reference mapping using the first dataframe's results
  reference_pairs <- all_results[[1]]$found
  inconsistent_pairs <- list()  # To store inconsistencies found
  
  # Iterate through each subsequent dataframe's results and compare
  for (i in 2:length(all_results)) {
    current_pairs <- all_results[[i]]$found
    
    # Compare each LineItemENG in the reference with the current dataframe
    for (line_item in names(reference_pairs)) {
      if (line_item %in% names(current_pairs)) {
        # Check if the LineItemGEO values are the same
        if (!identical(reference_pairs[[line_item]], current_pairs[[line_item]])) {
          # Record the inconsistency
          inconsistent_pairs[[paste("DataFrame", i, "LineItem:", line_item)]] <- list(
            reference = reference_pairs[[line_item]],
            current = current_pairs[[line_item]]
          )
        }
      }
    }
  }
  
  # Print inconsistent pairs if found
  if (length(inconsistent_pairs) > 0) {
    cat("\nInconsistent LineItemENG-LineItemGEO pairs found across dataframes:\n")
    print(inconsistent_pairs)
  } else {
    cat("\nAll LineItemENG-LineItemGEO pairs are consistent across dataframes.\n")
  }
}

# After processing all results, check for consistency
check_consistency_across_dataframes(all_results)



#Load corresponding geo-eng lineitems

##Convert JSON list to dataframe making sure both English and Georgian names are put in columns (and not in column names)

lookup_table <- data.frame(
  English = names(all_results$`DataFrame 1`$found),      # English LineItemENG names
  Georgian = unlist(all_results$`DataFrame 1`$found)     # Corresponding Georgian LineItemGEO values
)


###Reset row names to null
rownames(lookup_table) <- NULL

#Make dataframes uniform

make_identical <- function(df, lookup_table) {
  
  # Rename columns
  df <- df %>%
    rename(
      LineItemGEO = any_of("LineItem"),
      CategoryMain = any_of("Category")
    )
  
  # Filter out values in 'LineItemGEO' that are not in the lookup table before the join
  df <- df %>%
    filter(LineItemGEO %in% lookup_table$Georgian)
  
  # Check for missing Georgian variables
  missing_georgian_vars <- setdiff(lookup_table$Georgian, df$LineItemGEO)
  
  if (length(missing_georgian_vars) > 0) {
    cat("Warning: The following Georgian variables were not found in the dataframe:\n")
    print(missing_georgian_vars)
  } else {
    cat("All Georgian variables from the lookup table are found in the dataframe.\n")
  }
  
  # Check if 'LineItemENG' already exists, and only add it if it doesn't
  if (!"LineItemENG" %in% colnames(df)) {
    df <- df %>%
      left_join(lookup_table, by = c("LineItemGEO" = "Georgian")) %>%
      rename(LineItemENG = English)
  }
  
  return(df)
}


# Apply the function to dataframes in data_list_no_eng
data_list_no_eng_adjusted <- lapply(data_list_no_eng, make_identical, lookup_table = lookup_table)

# Combine the two lists into one
combined_data_list <- c(data_list_adjusted, data_list_no_eng_adjusted)


names(combined_data_list) <- make.unique(c(names(data_list_adjusted), names(data_list_no_eng_adjusted)))

#####უნდა გავაერთიანო

combined_data_list <- lapply(combined_data_list, function(df) {
  df <- df %>%
    mutate(Value = as.numeric(Value))  # Convert Value to numeric
  return(df)
})

# Combine the list of dataframes into one dataframe
combined_df <- bind_rows(combined_data_list)

####gadavamowmot rom gaetianebulshi yvelaferi sworia


####

# Apply group_split on each dataframe in combined_data_list, first by ReportCode, then by LineItemENG


nested_list_of_dfs_group_split <- function(df) {
  
  # Step 1: Group and split by ReportCode
  list_of_dfs_group_split_by_report_code <- df %>% group_split(ReportCode)
  
  # Step 2: For each dataframe from the ReportCode split, group and split by LineItemENG
  nested_list_of_dfs_group_split_by_lineitemeng <- lapply(list_of_dfs_group_split_by_report_code, function(df_grouped) {
    df_grouped %>% group_split(LineItemENG)
  })
  
  # Return the nested list of dataframes grouped by LineItemENG within ReportCode
  return(nested_list_of_dfs_group_split_by_lineitemeng)
}

# Apply this function to a single dataframe, 'your_dataframe'
nested_list_of_dfs_group_split <- nested_list_of_dfs_group_split(combined_df)  

#
process_df_secondary <- function(df) {
  processed_year <- list()
  column_to_check <- 'ReportYear'
  instances_over_two <- 0
  
  cat("Processing dataframe with", nrow(df), "rows\n")
  
  for (i in 1:nrow(df)) {
    current_value <- df$FVYear[i]
    
    if (!(current_value %in% processed_year)) {
      processed_year <- append(processed_year, current_value)
      found_matches <- which(df$FVYear == current_value)
      cat("Found matches for FVYear =", current_value, ":", found_matches, "\n")
      
      if (length(found_matches) > 1) {
        cat("Multiple rows for FVYear", current_value, "\n")
        
        if (length(found_matches) > 2) {
          instances_over_two <- instances_over_two + 1
        }
        
        # Extract the column data and check if it's numeric
        column_data <- df[[column_to_check]][found_matches]
        value_data <- df[["Value"]][found_matches]
        
        # Convert column_data to numeric, handling any non-numeric values
        column_data_numeric <- suppressWarnings(as.numeric(as.character(column_data)))
        if (any(is.na(column_data_numeric))) {
          cat("Warning: Non-numeric values found in ReportYear. Treating as NA:\n", column_data, "\n")
          column_data_numeric <- ifelse(is.na(column_data_numeric), -Inf, column_data_numeric) # Handle NAs by assigning a very low value
        }
        
        # Sort column_data and value_data in decreasing order
        sorted_indices <- order(column_data_numeric, decreasing = TRUE)
        column_data_numeric <- column_data_numeric[sorted_indices]
        value_data <- value_data[sorted_indices]
        
        cat("Column data after sorting:", column_data_numeric, "\n")
        cat("Value data after sorting:", value_data, "\n")
        
        # Find the first non-zero value in the sorted order
        non_zero_index <- which(value_data != 0)
        if (length(non_zero_index) > 0) {
          # Use the first non-zero value
          max_value_index <- found_matches[sorted_indices[non_zero_index[1]]]
          cat("Non-zero value found at index:", max_value_index, "\n")
        } else {
          # All values are zero, use the latest year value
          max_value_index <- found_matches[sorted_indices[1]]
          cat("All zero values, keeping latest year at index:", max_value_index, "\n")
        }
        
        # Remove rows that are not the max_value_index
        found_matches <- found_matches[found_matches != max_value_index]
        
        if (length(found_matches) > 0) {
          # Debugging: Print the indices to be removed
          cat("Dropping rows with indices:", found_matches, "\n")
          df <- df[-found_matches, ]
        }
      }
    }
  }
  
  # Debugging: Print the number of rows after processing
  cat("Number of rows after processing:", nrow(df), "\n")
  cat("Number of instances with more than two matches:", instances_over_two, "\n")
  
  return(df)
}


final_processed_list <- lapply(nested_list_of_dfs_group_split, function(inner_list){
  lapply(inner_list, function(df) process_df_secondary(df))
})

transform_to_wide_format <- function(df) {
  # Ensure Value is numeric
  df <- df %>%
    mutate(Value = as.numeric(Value))
  
  # Group by IdCode, FVYear, and LineItemENG
  df_grouped <- df %>%
    group_by(IdCode, FVYear, LineItemENG) %>%
    summarise(Value = sum(Value, na.rm = TRUE), .groups = 'drop')
  
  # Transform the dataframe from long to wide format using pivot_wider
  df_wide <- df_grouped %>%
    pivot_wider(names_from = LineItemENG, values_from = Value)
  
  # Optionally, reorder columns to have IdCode and FVYear at the front
  df_wide <- df_wide %>%
    select(IdCode, FVYear, everything())
  
  return(df_wide)
}



flattened_final_processed_list <- unlist(final_processed_list, recursive = FALSE)

combined_df_processed <- bind_rows(flattened_final_processed_list)

final_wide_df <- transform_to_wide_format(combined_df_processed)

#Benefitiaries

benefitiaries_path <- "benefitiaries_data.xlsx"

beneficiaries_df <- read_excel(benefitiaries_path)


beneficiaries_df <- beneficiaries_df %>%
  rename(
    IdCode = `ს/კ`,  # Changing ს/კ to RegistrationCode
    ReportCode = `რეპორტ კოდი`,  # Changing რეპორტ კოდი to ReportCode
    Program = პროგრამა  # Changing პროგრამა to Program
  ) %>%
  mutate(
    Program = case_when(
      Program == "ინდუსტრიული" ~ 1,
      Program == "უნივერსალური" ~ 2,
      Program == "საკრედიტო-საგარანტიო" ~ 3,
      Program == "ორივე პროგრამით სარგებლობა" ~ 4,
      TRUE ~ NA_real_ 
    )
  )


# Step 1: Ensure 'IdCode' columns are of the same type in both data frames
beneficiaries_df$IdCode <- as.character(beneficiaries_df$IdCode)
final_wide_df$IdCode <- as.character(final_wide_df$IdCode)



# Step 2: Identify IdCodes in beneficiaries_df that are present in final_wide_df
matched_idcodes <- beneficiaries_df %>%
  filter(IdCode %in% final_wide_df$IdCode)

# Step 3: Identify IdCodes in beneficiaries_df that are not present in final_wide_df
unmatched_idcodes <- beneficiaries_df %>%
  filter(!IdCode %in% final_wide_df$IdCode)

# Step 4: Merge matched_idcodes with final_wide_df
# Combine the Program values for each IdCode by collapsing them into a single string
beneficiaries_collapsed <- matched_idcodes %>%
  group_by(IdCode) %>%
  summarise(ProgramBeneficiary = paste(unique(Program), collapse = ","), .groups = "drop")

# Perform the left join with final_wide_df
final_wide_df_with_program <- final_wide_df %>%
  left_join(beneficiaries_collapsed, by = "IdCode")

# Perform the left join with final_wide_df
final_wide_df_with_program <- final_wide_df %>%
  left_join(beneficiaries_collapsed, by = "IdCode")


# Step 5: Reorder columns to place 'ProgramBeneficiary' at the beginning
# Get the names of the columns
col_names <- names(final_wide_df_with_program)

# Move 'ProgramBeneficiary' to the front
final_wide_df_with_program <- final_wide_df_with_program %>%
  select(ProgramBeneficiary, everything())

# Now, final_wide_df_with_program has 'ProgramBeneficiary' as the first column.

# Output the number of matched and unmatched IdCodes
cat("Number of IdCodes in beneficiaries_df:", nrow(beneficiaries_df), "\n")
cat("Number of IdCodes matched in final_wide_df:", nrow(matched_idcodes), "\n")
cat("Number of IdCodes not matched:", nrow(unmatched_idcodes), "\n")

# Optional: View the unmatched IdCodes
print("Unmatched IdCodes:")
print(unmatched_idcodes)

###
#operator values "*", "/", "+", "-"
create_new_variables <- function(df, column1, column2, new_column_name, operator){
  if (all(c(column1, column2) %in% colnames(df))) {
    
    df <- df %>%
      mutate(
        !!new_column_name := case_when(
          operator == "+" ~ ifelse(is.na(.data[[column1]]) | is.na(.data[[column2]]), 
                                   NA, 
                                   .data[[column1]] + .data[[column2]]),
          operator == "-" ~ ifelse(is.na(.data[[column1]]) | is.na(.data[[column2]]), 
                                   NA, 
                                   .data[[column1]] - .data[[column2]]),
          operator == "*" ~ ifelse(is.na(.data[[column1]]) | is.na(.data[[column2]]), 
                                   NA, 
                                   .data[[column1]] * .data[[column2]]),
          operator == "/" ~ ifelse(is.na(.data[[column1]]) | is.na(.data[[column2]]) | .data[[column2]] == 0, 
                                   NA, 
                                   .data[[column1]] / .data[[column2]]),
          TRUE ~ NA_real_ 
        )
      )
    
  } else {
    cat("One or both of the specified columns do not exist in the dataframe.\n")
  }
  
  return(df)
}


##create Margin variable
final_wide_df_with_program <- create_new_variables(final_wide_df_with_program, "Profit/(loss)", "Net Revenue", "Margin", "/")
##create Liabilities to Assets
final_wide_df_with_program <- create_new_variables(final_wide_df_with_program, "Total liabilities", "Total assets", "Liabilities to Assets", "/")
##Create Total Borrowings, then Borrowings to assets
final_wide_df_with_program <- create_new_variables(final_wide_df_with_program, "Current borrowings", "Non current borrowings", "Total Borrowings", "+")
final_wide_df_with_program <- create_new_variables(final_wide_df_with_program, "Total Borrowings", "Total assets", "Borrowings to Assets", "/")
##Create Cash to assets
final_wide_df_with_program <- create_new_variables(final_wide_df_with_program, "Cash and cash equivalents", "Total assets", "Cash to Assets", "/")
##Create operating income to assets
final_wide_df_with_program <- create_new_variables(final_wide_df_with_program, "Operating income", "Total assets", "Operating income to Assets", "/")
##Create Liabilities to Operating income
final_wide_df_with_program <- create_new_variables(final_wide_df_with_program, "Total liabilities", "Operating income", "Liabilities to Operating income", "/")




'''# Function to plot columns vs percentiles with an option to apply percentile cutoffs
plot_columns_vs_percentiles <- function(df, columns) {
  
  # Loop over each specified column
  for (column_name in columns) {
    
    # Check if the column exists in the dataframe
    if (column_name %in% colnames(df)) {
      
      # Get the original values from the column, along with their IdCode
      data_with_id <- df %>%
        select(IdCode, all_of(column_name)) %>%
        drop_na()  # Remove NA values
      
      values <- sort(data_with_id[[column_name]])
      
      # Create percentiles (X axis) using empirical cumulative distribution function (ecdf)
      percentiles <- ecdf(values)(values)
      
      # Create a dataframe for plotting
      plot_data <- data.frame(Percentile = percentiles, Value = values)
      
      # Generate the plot
      p <- ggplot(plot_data, aes(x = Percentile, y = Value)) +
        geom_line() +
        geom_point() +
        labs(title = paste("Plot of", column_name, "vs Percentiles (Sorted)"),
             x = "Percentiles",
             y = "Sorted Values") +
        theme_minimal()
      
      # Display the plot
      print(p)
      
      # Ask the user if they want to apply percentile cutoffs
      apply_cutoff <- readline(prompt = "Do you want to apply percentile cutoffs? (yes/no): ")
      
      # If the user chooses to apply cutoff
      if (tolower(apply_cutoff) == "yes") {
        
        # Ask for the cutoff values from the beginning and the end
        cutoff_start <- as.numeric(readline(prompt = "Enter the percentile to cut from the beginning (0-1): "))
        cutoff_end <- as.numeric(readline(prompt = "Enter the percentile to cut from the end (0-1): "))
        
        # Ensure cutoff values are within valid range
        if (!is.na(cutoff_start) && !is.na(cutoff_end) && cutoff_start >= 0 && cutoff_start <= 1 && cutoff_end >= 0 && cutoff_end <= 1) {
          
          # Filter the values based on the percentile cutoffs
          values_filtered <- values[percentiles >= cutoff_start & percentiles <= (1 - cutoff_end)]
          
          # Retain only the rows where the values were not filtered out
          retained_rows <- data_with_id[data_with_id[[column_name]] %in% values_filtered, ]
          
          # Drop rows from the original dataframe where IdCode is not in retained_rows
          df <- df[df$IdCode %in% retained_rows$IdCode, ]
          
          cat(paste("Values for column", column_name, "trimmed based on percentiles, and corresponding rows have been dropped.\n"))
          
        } else {
          cat("Invalid percentiles provided. Moving to the next plot.\n")
        }
        
      } else {
        cat(paste("No cutoff applied for column", column_name, ". Moving to the next plot.\n"))
      }
      
    } else {
      cat(paste("Column", column_name, "does not exist in the dataframe.\n"))
    }
  }
  
  cat("All plots have been displayed.\n")
  return(df)
}

columns_to_check <- c("Margin", "Liabilities to Assets", "Borrowings to Assets", "Cash to Assets", "Operating income to Assets", "Liabilities to Operating income")

final_wide_processed <- plot_columns_vs_percentiles(final_wide_df_with_program, columns_to_check)'''

###
calculate_statistics_by_year <- function(df, columns) {
  
  summary_list <- list()
  
  for (column_name in columns) {
    
    if (column_name %in% colnames(df)) {
      
      summary_stats <- df %>%
        group_by(FVYear) %>%
        summarise(
          Mean = mean(.data[[column_name]], na.rm = TRUE),
          Median = median(.data[[column_name]], na.rm = TRUE),
          Percentile_1 = quantile(.data[[column_name]], 0.01, na.rm = TRUE),
          Percentile_5 = quantile(.data[[column_name]], 0.05, na.rm = TRUE),
          Percentile_10 = quantile(.data[[column_name]], 0.1, na.rm = TRUE),
          Percentile_25 = quantile(.data[[column_name]], 0.25, na.rm = TRUE),
          Percentile_50 = quantile(.data[[column_name]], 0.5, na.rm = TRUE),
          Percentile_75 = quantile(.data[[column_name]], 0.75, na.rm = TRUE),
          Percentile_90 = quantile(.data[[column_name]], 0.9, na.rm = TRUE),
          Percentile_95 = quantile(.data[[column_name]], 0.95, na.rm = TRUE),
          Percentile_99 = quantile(.data[[column_name]], 0.99, na.rm = TRUE),
        ) %>%
        mutate(Column = column_name)  # Add a column to identify the column name
      
      cat("\nSummary statistics for", column_name, "grouped by FVYear:\n")
      print(summary_stats)
      
      summary_list[[column_name]] <- summary_stats
      
    } else {
      cat(paste("Column", column_name, "does not exist in the dataframe.\n"))
    }
  }
  
  combined_summary_df <- bind_rows(summary_list)
  
  return(combined_summary_df)
}

###Processed Statistic
###Margin process
df_wide_margin <- final_wide_df_with_program %>%
  filter(Margin > -1 & Margin < 1)

df_wide_margin_beneficiaries <- df_wide_margin %>%
  filter(!is.na(ProgramBeneficiary))
df_wide_margin_non_beneficiaries <- df_wide_margin %>%
  filter(is.na(ProgramBeneficiary))

summary_margin_beneficiaries <- calculate_statistics_by_year(df_wide_margin_beneficiaries, "Margin")
summary_margin_non_beneficiaries <- calculate_statistics_by_year(df_wide_margin_non_beneficiaries, "Margin")

##Drop percentails
drop_percentiles_for_column <- function(df, column_name) {
  # Calculate the 1st and 99th percentiles for the specified column 
  lower_bound <- quantile(df[[column_name]], 0.01, na.rm = TRUE)
  upper_bound <- quantile(df[[column_name]], 0.99, na.rm = TRUE)
  
  # Filter the dataframe based on these percentiles for the specific column
  df_filtered <- df %>%
    filter(df[[column_name]] >= lower_bound & df[[column_name]] <= upper_bound)
  
  return(df_filtered)
}
##
###Liabilites to operating process
df_wide_liabilities_to_operating <- drop_percentiles_for_column(final_wide_df_with_program, "Liabilities to Operating income")
df_wide_liabilities_to_operating_beneficiaries <- df_wide_liabilities_to_operating %>%
  filter(!is.na(ProgramBeneficiary))
df_wide_liabilities_to_operating_non_beneficiaries <- df_wide_liabilities_to_operating %>%
  filter(is.na(ProgramBeneficiary))

summary_liabilities_to_operating_beneficiaries <- calculate_statistics_by_year(df_wide_liabilities_to_operating_beneficiaries, "Liabilities to Operating income")
summary_liabilities_to_operating_non_beneficiaries <- calculate_statistics_by_year(df_wide_liabilities_to_operating_non_beneficiaries, "Liabilities to Operating income")

###Operating to assets process
df_wide_operating_to_assets <- drop_percentiles_for_column(final_wide_df_with_program, "Operating income to Assets")
df_wide_operating_to_assets_beneficiaries <- df_wide_operating_to_assets %>%
  filter(!is.na(ProgramBeneficiary))
df_wide_operating_to_assets_non_beneficiaries <- df_wide_operating_to_assets %>%
  filter(!is.na(ProgramBeneficiary))

summary_operating_to_assets_beneficiaries <- calculate_statistics_by_year(df_wide_operating_to_assets_beneficiaries, "Operating income to Assets")
summary_operating_to_assets_non_beneficiaries <- calculate_statistics_by_year(df_wide_operating_to_assets_non_beneficiaries, "Operating income to Assets")

###Split main df
###Summary for columns that did not need processing
final_wide_df_with_program_beneficiaries <- final_wide_df_with_program %>%
  filter(!is.na(ProgramBeneficiary))
final_wide_df_with_program_non_beneficiaries <- final_wide_df_with_program %>%
  filter(is.na(ProgramBeneficiary))
unporcessed_columns <- c("Liabilites to Assets", "Borrowings to Assets", "Cash to Assets")

summary_for_unprocessed_beneficiaries <- calculate_statistics_by_year(final_wide_df_with_program_beneficiaries, unporcessed_columns)
summary_for_unprocessed_non_beneficiaries <- calculate_statistics_by_year(final_wide_df_with_program_non_beneficiaries, unporcessed_columns)

summary_beneficiaries <- bind_rows(summary_margin_beneficiaries, summary_liabilities_to_operating_beneficiaries,
                                      summary_operating_to_assets_beneficiaries, summary_for_unprocessed_beneficiaries)

summary_non_beneficiaries <- bind_rows(summary_margin_non_beneficiaries, summary_liabilities_to_operating_non_beneficiaries,
                                       summary_operating_to_assets_non_beneficiaries, summary_for_unprocessed_non_beneficiaries)

#####
write_xlsx(summary_beneficiaries, "final/summary_beneficiaries.xlsx")
write.csv(summary_beneficiaries, "final/summary_beneficiaries.csv")

write_xlsx(summary_non_beneficiaries, "final/summary_non_beneficiaries.xlsx")
write.csv(summary_non_beneficiaries, "final/summary_non_beneficiaries.csv")

write_xlsx(final_wide_df_with_program, "final/final_data.xlsx")
write.csv(final_wide_df_with_program, "final/final_data.csv")
