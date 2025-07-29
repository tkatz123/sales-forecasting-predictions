# ------------------------------------------------------------------------------
# Title: Load Required Packages
# Author: Tyler Katz
# Description:
# Utility function to install and load required R packages. Accepts a character
# vector of package names, checks if they are installed, installs any that are 
# missing, and then loads them into the session.
# ------------------------------------------------------------------------------

load_required_packages <- function(packages) {
  installed <- rownames(installed.packages())
  
  for (pkg in packages) {
    if (!(pkg %in% installed)) {
      install.packages(pkg, dependencies = TRUE)
    }
    library(pkg, character.only = TRUE)
  }
}