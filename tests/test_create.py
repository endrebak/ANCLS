from ancls import NCLS

import numpy as np

starts = np.array([1, 2, 5, 3], dtype=np.uint32)

ends = starts + 10

NCLS(starts, ends, starts)
