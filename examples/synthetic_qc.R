source("R/qc.R")
source("R/api.R")
invented <- data.frame(Study_ID=c("SYNTHETIC_A","SYNTHETIC_B"),
  Intervention_N=c(10L,8L),Intervention_Events=c(0L,9L))
findings <- validate_extraction(invented,known_ids=invented$Study_ID,unique_ids=TRUE)
stopifnot(nrow(findings)==1L,findings$row==3L)
print(findings,row.names=FALSE)
