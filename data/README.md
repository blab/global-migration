## Data

This directory contains working sets for `h3`, `h1`, `vic` and `yam`.  These files were produced with the following pipeline:

1. Clean sequences (remove outliers and pre-2000 sequences)
2. Extract locations from strain names
3. Combine locations into the 9 canonical regions
4. Label dates as precise to the day, month or year
5. Subsample sequences, preferring more precise dates or longer sequences

## Sample counts and distributions

*Full* is all samples present post-2000.  *Small* is selecting at most 14 (13 for USA) per year for H3, 30 (28 for USA) per year for H1, 30 (24 for USA) per year for Vic, 40 (25 for USA) per year for Yam.  *Large* is selecting at most 50 (40 for USA) per year for H3, 80 (45 for USA) per year for H1, 80 (45 for USA) per year for Vic, 80 (40 for USA) per year for Yam.  These sampling strategies resulting in similar overall counts across space and time.

Lineage         | Full  | Small | Large 
--------------- | ----- | ----- | -----
[H3N2](h3/)     | 8306  | 1391  | 4006
[H1N1](h1/)     | 3318  | 1372  | 2144  
[B/Vic](vic/)   | 2247  | 1394  | 1999  
[B/Yam](yam/)   | 1556  | 1241  | 1455
