missing_token <- function(x) {
  is.na(x) | trimws(toupper(as.character(x))) %in% c("", "NA", "N/A", "NR", "NOT REPORTED")
}

qc_table <- function(d, sheet, known_ids = NULL, unique_ids = FALSE) {
  findings <- data.frame(sheet=character(), row=integer(), field=character(),
                         severity=character(), issue=character())
  add <- function(rows, field, severity, issue) {
    if (length(rows)) findings <<- rbind(findings, data.frame(
      sheet=sheet, row=as.integer(rows)+1L, field=field, severity=severity, issue=issue))
  }
  if ("Study_ID" %in% names(d)) {
    add(which(missing_token(d$Study_ID)), "Study_ID", "error", "Missing study identifier")
    if (!is.null(known_ids)) add(which(!d$Study_ID %in% known_ids), "Study_ID", "error", "Unknown study identifier")
    if (unique_ids) add(which(duplicated(d$Study_ID)), "Study_ID", "error", "Duplicate study identifier")
  }
  add(which(duplicated(d)), "row", "warning", "Exact duplicate row retained for review")
  numeric_fields <- intersect(names(d), c("Year", "Sample_Size_Total", "Intervention_N",
    "Comparator_N", "Intervention_Total", "Comparator_Total", "Intervention_Events", "Comparator_Events",
    "Intervention_Target_Attained_N", "Comparator_Target_Attained_N",
    "Intervention_Mean", "Comparator_Mean", "Intervention_SD", "Comparator_SD",
    "Effect_Estimate", "CI_Lower", "CI_Upper"))
  for (field in numeric_fields) {
    present <- !missing_token(d[[field]])
    values <- suppressWarnings(as.numeric(d[[field]]))
    add(which(present & !is.finite(values)), field, "warning", "Non-numeric value requires source review; retained")
    if (grepl("_N$|_Total$|_Events$|Sample_Size_Total|Year",field)) {
      add(which(present & is.finite(values) & (values < 0 | values != floor(values))), field,
          "error", "Invalid count or year")
    }
    if (grepl("_SD$",field)) add(which(present & is.finite(values) & values < 0), field,"error","Negative standard deviation")
  }
  for (arm in c("Intervention", "Comparator")) {
    denominator <- if (paste0(arm,"_Total") %in% names(d)) paste0(arm,"_Total") else paste0(arm,"_N")
    for (event in c(paste0(arm,"_Events"),paste0(arm,"_Target_Attained_N"))) {
      if (all(c(denominator,event) %in% names(d))) {
        n <- suppressWarnings(as.numeric(d[[denominator]])); e <- suppressWarnings(as.numeric(d[[event]]))
        add(which(is.finite(n) & is.finite(e) & e > n),event,"error","Events exceed denominator")
      }
    }
  }
  if (all(c("CI_Lower","CI_Upper") %in% names(d))) {
    lo <- suppressWarnings(as.numeric(d$CI_Lower)); hi <- suppressWarnings(as.numeric(d$CI_Upper))
    add(which(is.finite(lo) & is.finite(hi) & lo > hi),"CI","error","Reversed confidence interval")
    if ("Effect_Estimate" %in% names(d)) {
      e <- suppressWarnings(as.numeric(d$Effect_Estimate))
      add(which(is.finite(e) & is.finite(lo) & is.finite(hi) & (e < lo | e > hi)),
          "Effect_Estimate","warning","Estimate outside reported confidence interval")
    }
  }
  # Study-level totals need not equal outcome-specific or overlapping arm populations.
  # Deliberately do not enforce arm sums or pool participant totals.
  findings
}

count_values <- function(x, label) {
  counts <- as.data.frame(table(x, useNA="ifany"), stringsAsFactors=FALSE)
  names(counts) <- c(label,"study_count")
  counts
}

compare_rob <- function(summary, embedded) {
  expected <- c("Study_ID", "Risk_of_Bias_Tool", "Overall_Risk_of_Bias")
  if (is.null(embedded) || !all(expected %in% names(embedded)))
    return("Embedded risk-of-bias sheet or required columns missing")
  if (anyDuplicated(embedded$Study_ID) || any(missing_token(embedded$Study_ID)))
    return("Embedded risk-of-bias identifiers missing or duplicated")
  if (!setequal(summary$Study_ID, embedded$Study_ID))
    return("Risk-of-bias identifier sets differ across workbooks")
  matched <- embedded[match(summary$Study_ID, embedded$Study_ID), , drop=FALSE]
  bad <- missing_token(matched$Overall_Risk_of_Bias) |
    missing_token(summary$Overall_Judgment) |
    missing_token(matched$Risk_of_Bias_Tool) | missing_token(summary$Tool) |
    summary$Overall_Judgment != matched$Overall_Risk_of_Bias |
    summary$Tool != matched$Risk_of_Bias_Tool
  if (any(bad)) return(paste("Risk-of-bias mismatch or missing judgment:",
                            paste(summary$Study_ID[bad], collapse=", ")))
  character()
}

review_queue <- function(rob, exclusions, effects) {
  out <- data.frame(sheet=character(),row=integer(),record_id=character(),issue=character(),status=character())
  add <- function(sheet, row, id, issue) {
    if (length(row)) out <<- rbind(out,data.frame(sheet=sheet,row=row,record_id=id,
                                                 issue=issue,status="investigator review required"))
  }
  domains <- intersect(paste0("Domain_",1:7),names(rob))
  if (length(domains)) {
    unknown <- apply(rob[,domains,drop=FALSE],1,function(x) any(x=="No information",na.rm=TRUE))
    i <- which(unknown)
    add("Overall Summary",i+1L,rob$Study_ID[i],"Domain has No information: verify overall judgment against assessment tool")
  }
  if (!is.null(exclusions)) {
    i <- which(apply(exclusions,1,function(x) any(grepl("Citation identity unavailable",x,fixed=TRUE))))
    add("Full-Text Exclusions",i+1L,exclusions$Exclusion_ID[i],"Recover citation identity and original screening decision")
  }
  if (!is.null(effects) && nrow(effects)) {
    add("Meta-Analysis Data",seq_len(nrow(effects))+1L,effects$Study_ID,
        "Verify source, estimand direction, adjustment, denominator, time point and dependent effects before pooling")
  }
  out
}
