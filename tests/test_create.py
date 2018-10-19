from ancls import NCLS

import numpy as np

starts = np.array([1, 2, 5, 3], dtype=np.uint32)

ends = starts + np.array([2, 10, 1, 7], dtype=np.uint32)

print(list(zip(starts, ends)))
print(NCLS(starts, ends, starts))
