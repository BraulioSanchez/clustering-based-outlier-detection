from math import sqrt
import numpy as np
# np.random.seed(123)
# np.random.seed(456) #v2
# np.random.seed(789) #v3
# np.random.seed(12) #v4
np.random.seed(345) #v5
from math import pi

K = 10

rl = 0.12
rh = rl
kg = 4 # distance multiplier (grid only)

dimensions = 2

overviews = []
overview = []
position = 0
while position <= sqrt(K)*kg*(rl+rh)/2:
	overview.append(position)
	position += kg*(rl+rh)/2
	
for i in range(dimensions):
	overviews.append(overview)

print("cluster centers grid")
print(np.array(overviews), "\n")

overviews = np.random.uniform(low=-0.1,high=1.1,size=(K,dimensions))
print("cluster centers random")
print(overviews)

nc = 1.6
x = [2*pi*i for i in np.arange(K)]
y = [(K/nc)*np.sin(2*pi*i/(K/nc)) for i in np.arange(K)]
print("cluster centers sine")
print(x)
print(y)

