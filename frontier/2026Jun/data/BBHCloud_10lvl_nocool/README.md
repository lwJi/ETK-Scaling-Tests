# BBHCloud 10 levels

| Radius | cells | cellsx7/15 | cells/2 | cells/4 | cells/5 | cellsx11/60 |
|:------:|:-----:|:----------:|:-------:|:-------:|:-------:|:-----------:|
|   960  |   240 |    112     |   120   |    60   |   48    |  44   |
|   600  |   300 |    140     |   150   |    75   |   60    |  55   |
|   300  |   300 |    140     |   150   |    75   |   60    |  55   |
|   150  |   300 |    140     |   150   |    75   |   60    |  55   |
|    86  |   344 |    160.5   |   172   |    86   |   68.8  |  63   |
|    54  |   432 |    201.6   |   216   |   108   |   86.4  |  79.2 |
|    38  |   608 |    283.7   |   304   |   152   |  121.6  | 111.5 |
|    30  |   960 |    448     |   480   |   240   |  192    | 176   |
|    26  |  1664 |    776.5   |   832   |   416   |  332.8  | 305   |
|    24  |  3072 |   1433.6   |  1536   |   768   |  614.4  | 563.2 |


Given the the target resolution can be fit in at least $128$ nodes ($128\times8=8^3\times2$ GPUs),

* we can scale down to $2$ nodes ($2^3\times2$ GPUs), each GPU should contain
$3072/4=768$ cells in each dir, then set `max_grid_size` = $[384, 384, 384/2]$

* we can also scale down to $1$ node ($2^3$ GPUs), each GPU should contain $(768^3/2)^{1/3}=609.562$ cells, we pick $3072/5=614.4$

## Different Mesh

| Mesh | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|:----:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|  G1  | 

Target resolution

| Mesh |  dx  | M/h | Zcs/s (10^7) | Nodes (Prod) | Speed (M/h) | SUs/15000M | Walltime (days) |
|:----:|:----:|:---:|:------------:|:------------:|:-----------:|:----------:|:---------------:|
| G1   |  
