source("R/qc.R")
source("R/schema.R")
stopifnot(identical(missing_token(c(NA,"NR","NA","0","")),c(TRUE,TRUE,TRUE,FALSE,TRUE)))
d <- data.frame(Study_ID=c("S1","S1","X"),Intervention_N=c("10","10","NR"),
                Intervention_Events=c("11","-1","unknown"),CI_Lower=c("2","NR","0"),
                CI_Upper=c("1","NR","1"),stringsAsFactors=FALSE)
before <- d
q <- qc_table(d,"synthetic_test",known_ids="S1",unique_ids=TRUE)
stopifnot(identical(d,before),all(c("Events exceed denominator","Reversed confidence interval",
  "Unknown study identifier","Duplicate study identifier","Invalid count or year") %in% q$issue))
good <- data.frame(Study_ID="S1",Intervention_N="10",Intervention_Events="0",CI_Lower="NR",CI_Upper="NR")
stopifnot(nrow(qc_table(good,"synthetic_test","S1",TRUE))==0L)
meta <- data.frame(Study_ID="S1",Intervention_N="NA",Intervention_Total="10",Intervention_Events="11")
stopifnot(any(qc_table(meta,"synthetic_test","S1")$issue=="Events exceed denominator"))
repeated <- rbind(good,good)
stopifnot(any(qc_table(repeated,"synthetic_test","S1")$issue=="Exact duplicate row retained for review"),nrow(repeated)==2L)
cat("QC regression tests passed; all fixtures are synthetic.\n")

s <- data.frame(Study_ID=c("S1","S2"),Tool=c("RoB 2","ROBINS-I"),
                Overall_Judgment=c("Some concerns","Serious"))
e <- data.frame(Study_ID=c("S2","S1"),Risk_of_Bias_Tool=c("ROBINS-I","RoB 2"),
                Overall_Risk_of_Bias=c("Serious","Some concerns"))
stopifnot(length(compare_rob(s,e))==0L)
bad <- e; bad$Overall_Risk_of_Bias[1] <- NA
stopifnot(length(compare_rob(s,bad))==1L)
bad <- e; bad$Overall_Risk_of_Bias[1] <- "Moderate"
stopifnot(length(compare_rob(s,bad))==1L)
stopifnot(length(compare_rob(s,e[1,,drop=FALSE]))==1L,
          length(compare_rob(s,NULL))==1L,
          length(compare_rob(s,rbind(e,e[1,])))==1L)
s$Domain_1 <- c("Low risk","No information")
ex <- data.frame(Exclusion_ID=c("E1","R2"),Author_Year=c("Study A","Citation identity unavailable"))
effects <- data.frame(Study_ID=c("S1","S1"))
queue <- review_queue(s,ex,effects)
stopifnot(nrow(queue)==4L,all(queue$status=="investigator review required"))
cat("Cross-workbook and scientific review queue regressions passed.\n")

stages <- c("Scopus records","PubMed/MEDLINE records","IEEE Xplore records","Total records identified",
  "Duplicate records removed","Unique records screened","Records excluded after title/abstract",
  "Full-text reports assessed","Full-text reports excluded","Studies included in review")
prisma <- data.frame(Stage=stages,Count=c(8,6,1,15,2,13,8,5,2,3))
stopifnot(length(validate_prisma(prisma,3))==0L)
for (value in c(-1,1.5,Inf,NA)) {
  bad <- prisma;bad$Count[1]<-value
  stopifnot(length(validate_prisma(bad,3))==1L)
}
stopifnot(length(validate_prisma(rbind(prisma,prisma[1,]),3))==1L,
          length(validate_prisma(prisma[-1,],3))==1L,
          length(validate_prisma(prisma,4))==1L)
manifest <- data.frame(role=c("extraction","risk_of_bias"),file=c("a.xlsx","b.xlsx"),sha256=rep(strrep("a",64),2))
validate_manifest(manifest)
for (value in c("../a.xlsx","C:\\a.xlsx","/a.xlsx","a.csv")) {
  bad <- manifest;bad$file[1]<-value
  stopifnot(inherits(try(validate_manifest(bad),silent=TRUE),"try-error"))
}
cat("Manifest and PRISMA boundary regressions passed.\n")
