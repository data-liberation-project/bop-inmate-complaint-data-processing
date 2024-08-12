.PHONY: dependencies format data scrape

default:

dependencies:
	Rscript -e "renv::restore()"

format:
	Rscript -e "install.packages('styler'); library(styler); style_dir('code');"

data:
	Rscript code/fac_clean.R
	Rscript code/merge.R

scrape:
	Rscript code/scrape.R
