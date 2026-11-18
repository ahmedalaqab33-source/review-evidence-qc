source("R/qc.R")
source("R/api.R")
fails <- function(expr) inherits(try(force(expr),silent=TRUE),"try-error")
stopifnot(fails(validate_extraction(NULL)), fails(validate_extraction(data.frame(x=1))),
          fails(validate_extraction(data.frame(Study_ID="S1"),unique_ids=NA)))
dup <- data.frame(Study_ID="S1",x=1); names(dup)[2] <- "Study_ID"
stopifnot(fails(validate_extraction(dup)))
empty <- data.frame(Study_ID=character(),Intervention_N=integer(),Intervention_Events=integer())
stopifnot(nrow(validate_extraction(empty))==0L)
x <- data.frame(Study_ID=c("S1","S2"),Intervention_N=c(10L,10L),Intervention_Events=c(0L,11L))
before <- x
a <- validate_extraction(x,c("S1","S2"),TRUE)
b <- validate_extraction(x,c("S1","S2"),TRUE)
stopifnot(identical(a,b),identical(x,before),nrow(a)==1L,
          identical(a$issue,"Events exceed denominator"),a$row==3L)
cat("API input, empty-frame, determinism, non-mutation and denominator boundary tests passed.\n")
