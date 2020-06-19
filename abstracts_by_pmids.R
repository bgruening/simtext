#!/usr/bin/env Rscript
#TOOL2 abstracts_by_pmid
#
#This tool retrieves for all PMIDs in each row of a table the according abstracts and saves them in additional columns.
#
#Input: Tab-delimited table with columns containing PMIDs. The names of the PMID columns should start with “PMID”, e.g. “PMID_1”, “PMID_2” etc.
#
#Output: Input table with additional columns containing abstracts corresponding to the PMIDs from PubMed. 
#The abstract columns are called "ABSTRACT_1", "ABSTARCT_2" etc. 
#
# packages: r-argparse-2.0.1, r-reutils-0.2.3, r-easypubmed-2.13, r-textclean-0.9.3
#
# Usage: $ T2_abstracts_by_pmid.R [-h] [-i INPUT] [-o OUTPUT]
# 
# optional arguments:
# -h, --help                 show help message
# -i INPUT, --input INPUT    input file name. add path if file is not in working directory
# -o OUTPUT, --output OUTPUT output file name. [default "T2_output"]


if (!require('argparse')) install.packages('argparse');
suppressPackageStartupMessages(library("argparse"))

if (!require("reutils")) install.packages("reutils"); 
library("reutils") 

if (!require('easyPubMed')) install.packages('easyPubMed');
suppressPackageStartupMessages(library("easyPubMed"))

if (!require('textclean')) install.packages('textclean');
suppressPackageStartupMessages(library("textclean"))


parser <- ArgumentParser()
parser$add_argument("-i", "--input", 
                    help = "input fie name. add path if file is not in workind directory")
parser$add_argument("-o", "--output", default="T2_output",
                    help = "output file name. [default \"%(default)s\"]")

args <- parser$parse_args()

data = read.delim(args$input, stringsAsFactors=FALSE, header= TRUE, sep='\t')
pmids_cols_index <- grep("PMID", names(data))

for(row in 1:nrow(data)){
  PMIDs=as.character(unique(data[row, pmids_cols_index]))
  
  if(length(PMIDs) > 0){
    efetch_result = try(efetch(uid=PMIDs, db="pubmed", retmode = "xml"),silent=TRUE)
    abstracts= custom_grep(efetch_result$content, tag = "Abstract", format = "char")
    cat(length(abstracts), " abstracts were found for PMIDs of row", row, "\n")
    abstracts= sapply(1:length(abstracts), function(i){paste(custom_grep(abstracts[i], tag="AbstractText", format="char"),collapse="")})
    abstracts = sapply(1:length(abstracts), function(x){replace_html(abstracts[x])})
    data[row, sapply(seq_along(abstracts),function(x){as.character(paste0("ABSTRACT_",x))})] <- abstracts
    Sys.sleep(0.75) #sys.sleep in order to avoid curl error of fetching abstracts
    
    if(round(row/10) == row/10){
      Sys.sleep(5)
    }
  }
}

write.table(data, args$output, sep = '\t', row.names = FALSE, col.names = TRUE)


