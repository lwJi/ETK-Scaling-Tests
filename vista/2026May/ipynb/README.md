# SBH

| Radius | target cells per level | target cells per level $\times$ 7/15 |
|:------:|:----:|:----:|
| 960 |  240 |  112   |
| 600 |  300 |  140   |
| 300 |  300 |  140   |
| 150 |  300 |  140   |
|  86 |  344 |  160.5 |
|  54 |  432 |  201.6 |
|  38 |  608 |  283.7 |
|  30 |  960 |  448   |
|  26 | 1664 |  776.5 |
|  24 | 3072 | 1433.6 |

The target cells (resolution) requires $\sim(3072/384)^3 =512$ GPUs, which is not avaliable on Vista. So we reduce the cells (resolution) to $1434$, which requires $\sim\text{floor}(1434/384)^3=64$ GPUs.
