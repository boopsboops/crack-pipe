#!/usr/bin/env Rscript
suppressMessages(library("rfishbase"))
suppressMessages(library("ape"))
suppressMessages(library("tidyverse"))
suppressMessages(library("parallel"))
suppressMessages(library("magrittr"))
suppressMessages(library("taxize"))
data(fishbase)

# read in refs
custom.refs <- read.FASTA(file="temp/reference-library/custom-references.fasta")

# make df of names
custom.df <- tibble(code=str_split_fixed(names(custom.refs),"\\|",2)[,1],sciName=str_split_fixed(names(custom.refs),"\\|",2)[,2]) %>%
    mutate(Genus=str_split_fixed(sciName," ",2)[,1])

# get up to date spp list
fishbase.tbl <- rfishbase::species()
# make genus
fishbase.tbl %<>% mutate(genus=str_split_fixed(Species," ",2)[,1])

# add families code
custom.df %<>% mutate(famCode=pull(fishbase.tbl,FamCode)[match(Genus,pull(fishbase.tbl,genus))])

# check which are complete
not.df <- custom.df %>% filter(is.na(famCode))

# consult NCBI for families of those missing
not.ncbi <- taxize::classification(taxize::genbank2uid(id=pull(not.df,code)),db="ncbi",messages=FALSE)

# extract family from result and add to df
extract_fam <- function(x){x %>% filter(rank=="family") %>% pull(name)}
not.df %<>% mutate(fam=purrr::map_chr(not.ncbi,extract_fam))

# get fam codes 
not.df %<>% mutate(famCode=pull(fishbase,FamCode)[match(fam,pull(fishbase,Family))])

# check names validity
print("The following taxa could not be found. Spelling error, or maybe a try a synonym? If empty, all taxa were found.")
not.df %>% filter(is.na(famCode)) %>% print(n=Inf)

# filter the NAs remove temp fam
not.df %<>% filter(!is.na(famCode)) %>% select(-fam)

# merge
joined.df <- bind_rows(custom.df,not.df) %>% filter(!is.na(famCode))

# annotate with fb
joined.df %<>% 
    mutate(family=pull(fishbase,Family)[match(famCode,pull(fishbase,FamCode))],
    order=pull(fishbase,Order)[match(famCode,pull(fishbase,FamCode))],
    class=pull(fishbase,Class)[match(famCode,pull(fishbase,FamCode))],
    kingdom="Animalia",phylum="Chordata") %>%
    mutate(sciName=str_replace_all(sciName,":",".")) %>%
    mutate(label=paste0(code,";tax=k:",kingdom,",p:",phylum,",c:",class,",o:",order,",f:",family,",g:",Genus,",s:",sciName)) %>% 
    mutate(label=str_replace_all(label," ","_"))

# trim names and remove non-matched
names(custom.refs) <- str_split_fixed(names(custom.refs),"\\|",2)[,1]
custom.refs.sub <- custom.refs[which(names(custom.refs) %in% pull(joined.df,code))]

# add new names
names(custom.refs.sub) <- pull(joined.df,label)[match(names(custom.refs.sub), pull(joined.df,code))]

# write out
write.FASTA(custom.refs.sub,file="temp/reference-library/custom-references-annotated.fasta")
