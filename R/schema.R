validate_manifest <- function(manifest) {
  required <- c("role", "file", "sha256")
  if (!all(required %in% names(manifest)) || nrow(manifest) != 2L)
    stop("Manifest must contain exactly two source workbooks and role/file/sha256 columns.")
  if (anyNA(manifest[, required]) || anyDuplicated(manifest$role) ||
      !setequal(manifest$role,c("extraction","risk_of_bias"))) stop("Invalid manifest roles.")
  if (anyDuplicated(manifest$file) || any(!grepl("^[^/\\\\]+[.]xlsx$",manifest$file)) ||
      any(grepl("^[.]|:",manifest$file))) stop("Manifest filenames must be unique local xlsx basenames.")
  if (any(!grepl("^[a-f0-9]{64}$",manifest$sha256))) stop("Invalid SHA-256 in manifest.")
  invisible(TRUE)
}

validate_prisma <- function(prisma, study_count) {
  required <- c("Stage","Count")
  if (is.null(prisma) || !all(required %in% names(prisma))) return("PRISMA count schema missing")
  if (anyDuplicated(prisma$Stage)) return("Duplicate PRISMA stage")
  needed <- c("Scopus records","PubMed/MEDLINE records","IEEE Xplore records","Total records identified",
    "Duplicate records removed","Unique records screened","Records excluded after title/abstract",
    "Full-text reports assessed","Full-text reports excluded","Studies included in review")
  if (!all(needed %in% prisma$Stage)) return("PRISMA stages incomplete")
  counts <- suppressWarnings(as.numeric(prisma$Count[match(needed,prisma$Stage)]))
  if (any(!is.finite(counts)) || any(counts<0 | counts!=floor(counts)))
    return("PRISMA counts must be finite nonnegative integers")
  if (sum(counts[1:3])!=counts[4] || counts[4]-counts[5]!=counts[6] ||
      counts[6]-counts[7]!=counts[8] || counts[8]-counts[9]!=counts[10] ||
      counts[10]!=study_count) return("PRISMA count arithmetic or included count does not reconcile")
  character()
}
