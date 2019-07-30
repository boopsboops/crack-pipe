#!/usr/bin/env Rscript
suppressMessages(library("rfishbase"))
suppressMessages(library("ape"))
suppressMessages(library("tidyverse"))
suppressMessages(library("parallel"))
suppressMessages(library("magrittr"))
data(fishbase)

# read in refs
custom.refs <- read.FASTA(file="temp/reference-library/custom-references.fasta")

# get unique names
custom.df <- tibble(code=str_split_fixed(names(custom.refs),"\\|",2)[,1],sciName=str_split_fixed(names(custom.refs),"\\|",2)[,2])

# add full sci name to fishbase
fishbase %<>% mutate(sciName=paste(Genus,Species))

# check names validity
print("Following species not in FishBase. Spelling error, or maybe a synonym?")
setdiff(unique(pull(custom.df,sciName)),fishbase$sciName)
fishbase %<>% filter(sciName %in% unique(pull(custom.df,sciName)))
#rfishbase::synonyms(setdiff(names.unique,fishbase$sciName))

# make taxonomy
fishbase %<>% mutate(kingdom="Animalia",phylum="Chordata") %>% select(kingdom,phylum,Class,Order,Family,Genus,sciName)

# combine
custom.df <- suppressMessages(left_join(custom.df, fishbase)) %>% 
    filter(!is.na(kingdom)) %>%
    mutate(label=paste0(code,";tax=k:",kingdom,",p:",phylum,",c:",Class,",o:",Order,",f:",Family,",g:",Genus,",s:",sciName)) %>% 
    mutate(label=str_replace_all(label," ","_"))

# trim names and remove non-matched
names(custom.refs) <- str_split_fixed(names(custom.refs),"\\|",2)[,1]
custom.refs.sub <- custom.refs[which(names(custom.refs) %in% pull(custom.df,code))]

# add new names
names(custom.refs.sub) <- pull(custom.df,label)[match(names(custom.refs.sub), pull(custom.df,code))]

# write out
write.FASTA(custom.refs.sub,file="temp/reference-library/custom-references-annotated.fasta")
