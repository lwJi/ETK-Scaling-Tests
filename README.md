# ETK-Scaling-Tests

## How many GPUs should be used for weak scaling

### Frontier
| Node | GPUs | dims |
| ---- | ---- | ---- |
| 1 | 8 | $2\times2\times2$
| 8 | 64 | $4\times4\times4$
| 27 | 216 | $6\times6\times6$
| **64** | 512 | $8\times8\times8$
| 125 | 1000 | $10\times10\times10$
| **216** | 1728 | $12\times12\times12$
| 343 | 2744 | $14\times14\times14$
| **512** | 4096 | $16\times16\times16$
| **1000** | 8000 | $20\times20\times20$
| 1728 | 13824 | $24\times24\times24$
| **2197** | 17576 | $26\times26\times26$

#### Option 1

For equal mass (resolution) binary case, assume GPUs on finest few levels have $n_x=n_y=\frac{1}{2}n_z$,
then it has $n_x^3$ GPUs on those levels. We can set $n_x$ to the num of GPUs in $x$-dir of coarse levels.

#### Option 2

For equal mass (resolution) binary case, assume GPUs on finest few levels have $n_x=n_y=n_z$,
then it has $2 n_x^3$ GPUs on those levels. We can set $n_x = n^{(c)}_x/2^{1/3}$.
