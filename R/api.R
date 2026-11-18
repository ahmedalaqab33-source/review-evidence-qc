# New staging API; wraps existing source functions without changing their semantics.
validate_extraction <- function(data, known_ids=NULL, unique_ids=FALSE) {
  if (!is.data.frame(data)) stop("data must be a data.frame")
  if (anyDuplicated(names(data))) stop("Duplicate column names are not supported")
  if (!"Study_ID" %in% names(data)) stop("Study_ID column is required")
  if (!is.logical(unique_ids) || length(unique_ids)!=1L || is.na(unique_ids))
    stop("unique_ids must be a single non-missing logical")
  qc_table(data, "extraction", known_ids, unique_ids)
}
