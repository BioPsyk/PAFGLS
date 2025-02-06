# Set seed for reproducibility
set.seed(42)

# Generate 50,000 records
n <- 50000

# Generate IDs
id <- 1:n

# Generate sex (K = female, M = male)
sex <- sample(c("K", "M"), n, replace = TRUE)

# Generate birth dates between 1940 and 2000
birth_years <- sample(1940:2000, n, replace = TRUE)
birth_months <- sample(1:12, n, replace = TRUE)
birth_days <- sample(1:28, n, replace = TRUE)  # Using 28 to avoid invalid dates
born_at <- as.Date(paste(birth_years, birth_months, birth_days, sep = "-"))

# Function to extract year from Date
year_from_date <- function(date) {
    as.numeric(format(date, "%Y"))
}

# Create baseline risk by birth year window and sex
get_base_risk <- function(birth_year, sex) {
    # Basic life expectancy model (simplified)
    base <- 0.3  # baseline risk
    year_factor <- (birth_year - 1940) / (2000 - 1940)  # normalized year effect
    sex_factor <- ifelse(sex == "K", 0.8, 1)  # women tend to live longer
    
    # Combine factors and ensure risk is between 0 and 1
    risk <- base * sex_factor * (1 - year_factor * 0.5)
    return(pmax(pmin(risk, 1), 0))
}

# Calculate end of follow-up date
end_date <- as.Date("2017-12-31")

# Generate death status and ages
dead <- numeric(n)
age_dx <- numeric(n)
k_p <- numeric(n)

for (i in 1:n) {
    # Calculate base risk for this person
    base_risk <- get_base_risk(year_from_date(born_at[i]), sex[i])
    
    # Adjust risk based on age
    age_factor <- as.numeric(end_date - born_at[i]) / 365.25 / 100
    k_p[i] <- pmin(base_risk * (1 + age_factor), 1)
    
    # Determine death status based on risk
    dead[i] <- rbinom(1, 1, k_p[i])
    
    # Calculate age at end of follow-up or death
    if (dead[i] == 1) {
        # For dead individuals, generate death date between birth and end of follow-up
        days_until_death <- runif(1) * as.numeric(end_date - born_at[i])
        age_dx[i] <- days_until_death / 365.25
    } else {
        # For alive individuals, calculate age at end of follow-up
        age_dx[i] <- as.numeric(end_date - born_at[i]) / 365.25
    }
}

# Create the final dataframe
df <- data.frame(
    id = id,
    sex = sex,
    born_at = born_at,
    dead = dead,
    age_dx = round(age_dx, 2),
    k_p = round(k_p, 4)
)
