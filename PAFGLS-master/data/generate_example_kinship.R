# Function to generate kinship pairs ensuring minimum relatives
generate_kinship <- function(demographic_df, min_relatives = 2) {
    n_people <- nrow(demographic_df)
    
    # Initialize empty vectors for relationships
    id1 <- numeric(0)
    id2 <- numeric(0)
    relatedness <- numeric(0)
    
    # Common relatedness values and their probabilities
    relatedness_values <- c(0.5, 0.25, 0.125, 0.0625)
    relatedness_probs <- c(0.4, 0.3, 0.2, 0.1)
    
    # Track relative count for each person
    relative_count <- numeric(n_people)
    
    # First pass: ensure everyone has minimum relatives
    for (person in 1:n_people) {
        while (relative_count[person] < min_relatives) {
            # Select a random relationship type
            rel <- sample(relatedness_values, 1, prob = relatedness_probs)
            
            # Find a suitable relative based on birth dates
            person1_birth <- demographic_df$born_at[person]
            
            # Define age difference based on relationship
            if (rel == 0.5) {
                year_diff <- sample(c(-5:5, 15:50), 1)
            } else if (rel == 0.25) {
                year_diff <- sample(30:80, 1)
            } else {
                year_diff <- sample(-20:20, 1)
            }
            
            target_date <- person1_birth + year_diff * 365.25
            
            # Find possible matches
            possible_matches <- which(
                abs(as.numeric(demographic_df$born_at - target_date)) < 730 &
                seq_len(n_people) != person
            )
            
            if (length(possible_matches) > 0) {
                person2 <- sample(possible_matches, 1)
                new_id1 <- min(person, person2)
                new_id2 <- max(person, person2)
                
                # Add relationship if it doesn't exist
                if (!any(id1 == new_id1 & id2 == new_id2)) {
                    id1 <- c(id1, new_id1)
                    id2 <- c(id2, new_id2)
                    relatedness <- c(relatedness, rel)
                    
                    relative_count[person] <- relative_count[person] + 1
                    relative_count[person2] <- relative_count[person2] + 1
                }
            }
        }
    }
    
    # Create final dataframe
    kinship_df <- data.frame(
        id1 = id1,
        id2 = id2,
        relatedness = relatedness
    )
    
    # Sort by id1, then id2
    kinship_df <- kinship_df[order(kinship_df$id1, kinship_df$id2), ]
    
    return(kinship_df)
}

# Generate kinship data
kinship_df <- generate_kinship(df)

# Check results
print("Summary of relationships:")
summary(kinship_df)

print("\nDistribution of relationship types:")
table(kinship_df$relatedness)

print("\nChecking minimum relatives requirement:")
relative_counts <- table(c(kinship_df$id1, kinship_df$id2))
print(paste("Minimum relatives per person:", min(relative_counts)))
print(paste("Average relatives per person:", mean(relative_counts)))
