###############################################################################
# Text data preparation for analysis from reference collection exported from 
# Zotero
################################################################################

#Code author: Francisco J. Guerrero


#Cleaning memory resources
gc()

#loading required packages
librarian::shelf(dplyr, tidytext, tidyverse,
                 widyr,igraph, ggraph, plotly,
                 wordcloud, reshape2, graphlayouts,
                 pluralize, quanteda, qgraph, cowplot, readr,
                 ggwordcloud,tm,scales, ggrepel, ggplotify,zoo,
                 htmlwidgets, htmltools, visNetwork)


# Import and Export paths
pubs <- "./data" 
metadata <- "./metadata"
export <- "../../../2-sie-analytical.engine/text_analysis_tidy_references/data"
reading_file <- "231031_reproducible_research_compendia.csv"

# Import functions
source("./source/function_get_metadata.R")


# reading the data
references_raw_dat <- as_tibble(read_csv(paste(pubs,
                                               reading_file,sep='/'),
                                         show_col_types = FALSE))
head(references_raw_dat)

# creating metadata file for our raw data
file_path <- reading_file
data <- get_metadata(references_raw_dat, file_path)


################################################################################
# Data preparation
###############################################################################

# 1. Data Assembly

# For our analyses below, we won't need DOIs, PMIDs or arXiv IDs. We will focus
# on Title, Abstract, Authors, Journal, Year. To keep column names formatting
# simple, I use lowercase and spaces are added with (_) when needed.

# In some cases is possible that the abstracts for the papers are not retrieved. 
# In such cases,the value returned would be NA (which is read as a character string 
# and not as the typical NA). It could also happen that the abstracts could be 
# partially retrieved. To filter these cases out, we will add another column to 
# the dataframe to count the character length of each abstract, and remove those 
# that are less than 20 characters long. Finally, we will add a sequential id and 
# make it a factor for visualization purposes.

references_dat <- references_raw_dat %>% 
  distinct() %>% 
  select(Key, Title,`Abstract Note`,Author,`Publication Title`,`Publication Year`) %>% 
  rename(key = Key,
         title = Title,
         abstract = `Abstract Note`,
         authors = Author,
         journal = `Publication Title`,
         year = `Publication Year`) %>% 
  mutate(abstract_lenght = nchar(abstract)) %>% 
  filter(abstract_lenght > 20)%>% 
  mutate(id = seq(from =1, to= nrow(.),by=1)) %>% 
  mutate(id = factor(id))

head(references_dat)

# In this case we have abstracts retrieved for all 50 publication items.

# 2. Data cleaning and tokenization

# Tidying text and tokenization

# Our first step to analyze the selected publication component, is to make sure that 
# our text data is tidy. Tidy text data is all in lower case, singular forms, 
# with no punctuation, numeric characters or symbols. These cleaning process could be
# done on each abstract as a whole, but we found that it was most efficient to tokenize
# the abstracts (i.e., break them into individual words) and save the tokens in a new
# data frame. We then clean all the tokens and reassmenble the 'tokenized' abstracts
# back into "clean" paragprahps.

# There are several packages you could use to tokenize a piece of text, here we 
# will use the `tidytext` package for most of our analysis. 

# How to unnest and nest text data in using tidytext? check this post: 
# https://stackoverflow.com/questions/49118539/opposite-of-unnest-tokens-in-r


# Define the components to be processed
pub_comps <- c("title", "abstract")

# Initialize the first component to start with
pub_dat_all <- NULL

# Loop through each component (i.e., title and abstract)
for (pub_comp in pub_comps) {
  
  # 1) Select the relevant columns from the original data
  pub_dat <- dplyr::select(references_dat, 
                           id, 
                           authors, 
                           year, 
                           journal, 
                           all_of(pub_comp)) %>%
    # Rename the selected publication component (title or abstract) for processing
    rename(pub_comp_words = all_of(pub_comp)) %>% 
    
    # 2) Break the chunk of (nested) text into tokens (output = word)
    unnest_tokens(input = pub_comp_words, 
                  output = word, 
                  drop = TRUE) %>%  
    
    # 3) Ensure all words are in lower caps and in their singular form
    mutate(word = str_to_lower(word),
           word = if_else(word == "data",
                          word,
                          singularize(word))) %>% 
    
    # 4) Remove punctuation, numeric characters, and stop-words
    filter(!str_detect(word, "[:punct:]|[:digit:]")) %>% 
    anti_join(stop_words, by = "word") %>% 
    
    # 5) Reassemble the tokens back by nesting them
    nest(data = word) %>%  
    
    # 6) Unlist the tokens into tidy paragraphs
    mutate(!!paste0(pub_comp) := map_chr(map(data, unlist), paste, collapse = " "))  
  
  # Combine the tidied data with previous results
  if (is.null(pub_dat_all)) {
    pub_dat_all <- pub_dat
  } else {
    pub_dat_all <- full_join(pub_dat_all, pub_dat, by = c("id", "authors", "year", "journal"))
  }
}

# Select only the desired columns
pub_dat_all <- select(pub_dat_all, id, authors, year, journal, title, abstract)

# Display the first few rows of the result
head(pub_dat_all)

# Export data into the analysis engine. 

write.csv(pub_dat_all,paste(export,"tidy_sie_literature_review.csv",sep = '/'),
          row.names = FALSE)
