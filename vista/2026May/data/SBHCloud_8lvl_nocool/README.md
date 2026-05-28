# SBH

**THIS DIR IS MISNAMED, IT USES 10 LEVELS INSTEAD of 8 LEVELS**

| Radius | cells| cells/2 | cells/4 | cells/3 | cells/6 | cells x 7/15 |
|:------:|:----:|:----:|:----:|:----:|:----:|:----:|
| 960 |  240 |  120 |  60 |   80   |  40   |  112   |
| 600 |  300 |  150 |  75 |  100   |  50   |  140   |
| 300 |  300 |  150 |  75 |  100   |  50   |  140   |
| 150 |  300 |  150 |  75 |  100   |  50   |  140   |
|  86 |  344 |  172 |  86 |  114.7 |  57.4 |  160.5 |
|  54 |  432 |  216 | 108 |  144   |  72   |  201.6 |
|  38 |  608 |  304 | 152 |  202.7 | 101.4 |  283.7 |
|  30 |  960 |  480 | 240 |  320   | 160   |  448   |
|  26 | 1664 |  832 | 416 |  554.7 | 277.4 |  776.5 |
|  24 | 3072 | 1536 | 768 | 1024   | 512   | 1433.6 |

## Different Mesh

| Mesh | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| G1 | 960 | 600 | 300 | 150 | 86 | 54 | 38 | 30 | 26 | 24 |
| G2 | 12288 | 6144 | 3072 | 1536 | 768 | 384 | 192 | 96 | 48 | 24 |
| G3 | 8192 | 4096 | 2048 | 1024 | 512 | 256 | 128 | 64   | 48   | 24 |
| G4 | 4096 | 2048 | 1024 |  512 | 256 | 128 |  64 | 46.1 | 33.2 | 24 |

Target resolution
* on finest: $\frac{24\times2}{3072}=2^{-6}=0.015625$
* on coarest: $\frac{960\times 2}{240}=8$

| Mesh | dx | M/h | Zcs/s (10^7) | Nodes for Prod | Speed for Prod (M/h) | SUs/15000M | Walltime (days) |
|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|
| G1       |  68.6 |  73.0 | 1.71 |  631 |  8.5 | 1113529 | 74 |
| G2       | 139.6 | 654.4 | 7.37 | 5314 | 37.5 |  |
| G3       | 113.8 | 351.4 | 3.96 | 2878 | 24.7 | 
| G4 (96)  |  85.4 | 157.8 | 2.18 | 1216 | 14.8 | 
| G4 (104) |  78.8 | 114.3 | 2.19 |  956 | 11.6 | 

Translation to Nodes:

$$
\left(\frac{\Delta x}{8}\times [\text{node per dim for } \Delta x]\right)^3
$$

Translation to Speed:

$$
[\text{speed get for }\Delta x] \times \left(\frac{8}{\Delta x}\right)
$$

## Vista vs Horizon

| | Vista | Horizon |
|:---:|:---:|:---:|
| # of nodes      | 600 Grace Hopper | 2000 Grace Blackwell |
| GPUs per node   | 1 | 2 |
| Memory per GPU  | **96 GB** HBM3 + 116GB LPDDR | **185 GB** HBM3 + 120 GB LPDDR5X |
| FP64 per node   | 34 TFlops | 80 TFlops |
