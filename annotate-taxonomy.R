#!/usr/bin/env Rscript
suppressMessages(library("rfishbase"))
suppressMessages(library("ape"))
suppressMessages(library("tidyverse"))
suppressMessages(library("parallel"))
suppressMessages(library("magrittr"))

# read in refs and remove duplicates
custom.refs <- read.FASTA(file="temp/reference-library/custom-references.fasta")
custom.refs <- custom.refs[!duplicated(str_split_fixed(names(custom.refs),"\\|",2)[,1])]

# make df of names
custom.df <- tibble(code=str_split_fixed(names(custom.refs),"\\|",2)[,1],sciName=str_split_fixed(names(custom.refs),"\\|",2)[,2]) %>%
    mutate(Genus=str_split_fixed(sciName," ",2)[,1])

# get up to date spp list and taxonomy
fishbase.species <- rfishbase::species(server="fishbase")
fishbase.taxonomy <- rfishbase::load_taxa(server="fishbase")
fishbase.synonyms <- rfishbase::synonyms(server="fishbase")

# anotate the dataframe with taxonomy
custom.df.annotated <- custom.df %>% 
    mutate(Family=pull(fishbase.taxonomy,Family)[match(Genus,pull(fishbase.taxonomy,Genus))],
    Order=pull(fishbase.taxonomy,Order)[match(Genus,pull(fishbase.taxonomy,Genus))],
    Class=pull(fishbase.taxonomy,Class)[match(Genus,pull(fishbase.taxonomy,Genus))])

# get the genera not annotated
annotated.not <- custom.df.annotated %>% filter(is.na(Family)) %>% pull(Genus) %>% unique()

# get the taxonomic info for genus synonyms
fishbase.synonyms.not <- fishbase.synonyms %>% 
    mutate(Genus=str_split_fixed(synonym," ",2)[,1]) %>% 
    filter(Genus %in% annotated.not) %>% 
    mutate(Family=pull(fishbase.taxonomy,Family)[match(SpecCode,pull(fishbase.taxonomy,SpecCode))],
    Order=pull(fishbase.taxonomy,Order)[match(SpecCode,pull(fishbase.taxonomy,SpecCode))],
    Class=pull(fishbase.taxonomy,Class)[match(SpecCode,pull(fishbase.taxonomy,SpecCode))])

# add this info to the df
custom.df.annotated %<>% mutate(Family=if_else(is.na(Family),pull(fishbase.synonyms.not,Family)[match(Genus,pull(fishbase.synonyms.not,Genus))],Family),
    Order=if_else(is.na(Order),pull(fishbase.synonyms.not,Order)[match(Genus,pull(fishbase.synonyms.not,Genus))],Order),
    Class=if_else(is.na(Class),pull(fishbase.synonyms.not,Class)[match(Genus,pull(fishbase.synonyms.not,Genus))],Class))

# check names validity
print("The following taxa could not be found. Spelling error, or maybe a try a synonym? If empty, all taxa were found.")
custom.df.annotated %>% filter(is.na(Family)) %>% print(n=Inf)

# filter the NAs remove temp fam
custom.df.annotated %<>% filter(!is.na(Family))

# annotate with fb
custom.df.annotated %<>% 
    mutate(Kingdom="Animalia",Phylum="Chordata") %>%
    mutate(sciName=str_replace_all(sciName,":",".")) %>%
    mutate(label=paste0(code,";tax=k:",Kingdom,",p:",Phylum,",c:",Class,",o:",Order,",f:",Family,",g:",Genus,",s:",sciName)) %>% 
    mutate(label=str_replace_all(label," ","_"))

# trim names and remove non-matched
names(custom.refs) <- str_split_fixed(names(custom.refs),"\\|",2)[,1]
custom.refs.sub <- custom.refs[which(names(custom.refs) %in% pull(custom.df.annotated,code))]

# add new names
names(custom.refs.sub) <- pull(custom.df.annotated,label)[match(names(custom.refs.sub), pull(custom.df.annotated,code))]

# write out
write.FASTA(custom.refs.sub,file="temp/reference-library/custom-references-annotated.fasta")
