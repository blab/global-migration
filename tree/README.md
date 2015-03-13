## Tree estimation

This directory sets up XML files for BEAST to estimate phylogenies from sequences in the [data/](../data/) directory.  XMLs can be built with the supplied [Rakefile](Rakefile).

## Statistics

Running `ruby scripts/statistics.rb` produces statistics from `.log` files and processed `.trees` files.  Here are mean rates of evolution at first and second position sites and third position sites, as well as effective population sizes across analyses.

type | pop size | diversity | TMRCA | time to trunk | pos 1&2 rate | pos 3 rate | rate ratio
---- | -------- | --------- | ----- | ------------- | ------------ | ---------- | ----------
h3_small | 9.2 | 2.87 | 3.21 | 1.39 | 0.003 | 0.0081 | 0.37
h3_small_r2 | 9.2 | 2.9 | 3.25 | 1.37 | 0.0029 | 0.0085 | 0.34
h3_large | 15.1 | 3.03 | 3.89 | 1.42 | 0.0032 | 0.0087 | 0.37
h1_small | 12.5 | 4.57 | 4.57 | 3.18 | 0.0027 | 0.0077 | 0.35
h1_small_r2 | 13.2 | 4.67 | 4.6 | 3.2 | 0.0025 | 0.0072 | 0.35
h1_large | 16.0 | 4.59 | 4.53 | 3.18 | 0.0028 | 0.0078 | 0.36
vic_small | 20.9 | 5.66 | 5.28 | 2.72 | 0.0013 | 0.0052 | 0.25
vic_small_r2 | 20.9 | 5.8 | 5.26 | 2.82 | 0.0013 | 0.0052 | 0.25
vic_large | 21.7 | 5.46 | 5.22 | 2.7 | 0.0014 | 0.0054 | 0.26
yam_small | 16.8 | 6.73 | 7.6 | 2.96 | 0.0013 | 0.0056 | 0.24
yam_small_r2 | 16.0 | 6.67 | 7.55 | 2.91 | 0.0014 | 0.0057 | 0.24
yam_large | 17.1 | 6.83 | 7.62 | 3.09 | 0.0014 | 0.0057 | 0.24

