# run_paper_figures_tables.R
#
# Runs all R figure scripts in paper_figures_tables/ in sequence.
# Must be executed with code/ as the working directory:
#
#   cd path/to/repo/code
#   Rscript run_paper_figures_tables.R
#
# Before running, install required R packages:
#   install.packages(c("ggplot2", "dplyr", "gridExtra", "tidyr", "scales",
#                      "sf", "viridis", "colorspace", "knitr"))
#
# PDFs are written to paper_figures_tables/output/.
# Table scripts (tableS*.txt) are pre-computed and included as plain text.

run_script <- function(path) {
  cat(sprintf("[%s] Running %s ...\n", format(Sys.time(), "%H:%M:%S"), path))
  tryCatch(
    source(path, local = new.env()),
    error = function(e) {
      cat(sprintf("  ERROR in %s: %s\n", path, conditionMessage(e)))
      stop(e)
    }
  )
  cat(sprintf("  done.\n"))
}

# ── Main figures ──────────────────────────────────────────────────────────────
run_script("paper_figures_tables/fig1.R")
run_script("paper_figures_tables/fig2.R")
run_script("paper_figures_tables/fig3.R")
run_script("paper_figures_tables/fig4.R")
run_script("paper_figures_tables/fig5.R")

# ── Supplementary figures (R only; FigS3 and FigS11 are Python — see runner) ─
run_script("paper_figures_tables/figS1.R")
run_script("paper_figures_tables/figS2.R")
run_script("paper_figures_tables/figS4.R")
run_script("paper_figures_tables/figS5.R")
run_script("paper_figures_tables/figS6.R")
run_script("paper_figures_tables/figS7.R")
run_script("paper_figures_tables/figS8.R")
run_script("paper_figures_tables/figS9.R")
run_script("paper_figures_tables/figS10.R")
run_script("paper_figures_tables/figS12.R")
run_script("paper_figures_tables/figS13.R")

cat(sprintf("\nAll R scripts finished. PDFs are in paper_figures_tables/output/\n"))
cat("Run run_paper_figures_tables.py for FigS3 and FigS11.\n")
