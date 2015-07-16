require 'calculate_fdi'

local filePath = './fdi/fixtures/graphs_of_interest.txt'
--local filePath = './fixtures/graphs_of_interest.txt'

local matlab = {
[1] = { [1] = {1602, 282112, -9}, [2] = {1603, 248350, -16}, [3] = {1604, 320866, -24}, [4] = {1605, 324778, -31}, [5] = {1606, 244930, -38}, [6] = {1607, 317082, -46}, [7] = {1608, 283130, -53}, [8] = {1609, 301839, -60}, [9] = {1610, 362488, -68}, [10] = {1611, 446778, -75}, [11] = {1612, 458181, -83}, [12] = {1613, 465836, -91}, [13] = {1614, 493871, -98}, [14] = {1615, 460857, -106}, [15] = {1616, 455848, -114}, [16] = {1617, 455875, -122}, [17] = {1618, 462783, -129}, [18] = {1619, 474363, -137}, [19] = {1620, 456359, -145}, [20] = {1621, 433692, -153}, [21] = {1622, 367111, -160}, [22] = {1623, 339255, -167}, [23] = {1624, 327989, -175}, [24] = {1625, 304495, -182}, [25] = {1626, 262971, -189}, [26] = {1627, 309906, -190}, [27] = {2094, 445948, -7}},
[2] = { [1] = {582, 1980, 3}, [2] = {583, 1849, 3}, [3] = {584, 2104, 3}, [4] = {1602, 2730, -4}, [5] = {1603, 2413, -7}, [6] = {1604, 2274, -9}, [7] = {1605, 2557, -12}, [8] = {1606, 3977, -15}, [9] = {1607, 5963, -18}, [10] = {1608, 6836, -22}, [11] = {1609, 6912, -25}, [12] = {1610, 6455, -29}, [13] = {1611, 6739, -32}, [14] = {1612, 6368, -36}, [15] = {1613, 6253, -39}, [16] = {1614, 6569, -43}, [17] = {1615, 6588, -46}, [18] = {1616, 6043, -50}, [19] = {1617, 6502, -53}, [20] = {1618, 6277, -56}, [21] = {1619, 6136, -60}, [22] = {1620, 5727, -63}, [23] = {1621, 5483, -67}, [24] = {1622, 4440, -70}, [25] = {1623, 4116, -73}, [26] = {1624, 3098, -75}, [27] = {1625, 2494, -78}, [28] = {1626, 2585, -81}, [29] = {1727, 6916, 3}, [30] = {1738, 8304, 3}, [31] = {1739, 8049, 3}, [32] = {1740, 7475, 4}, [33] = {1741, 6601, 5}},
[3] = { [1] = {340, 12131, -4}, [2] = {343, 12471, -4}, [3] = {344, 11309, -8}, [4] = {346, 10351, -4}, [5] = {348, 11900, -4}, [6] = {349, 10731, -8}, [7] = {357, 2090, -4}, [8] = {360, 8856, -7}, [9] = {441, 57, 4}, [10] = {522, 3491, -6}, [11] = {551, 8726, -7}, [12] = {563, 14390, -8}, [13] = {594, 3259, -6}, [14] = {595, 2548, -8}, [15] = {635, 13347, -8}, [16] = {636, 12527, -12}, [17] = {637, 11258, -15}, [18] = {667, 3803, -5}, [19] = {699, 16179, -8}, [20] = {702, 15913, -8}, [21] = {727, 16343, -8}, [22] = {754, 17189, -8}, [23] = {764, 2674, -7}, [24] = {807, 5823, -7}, [25] = {824, 10974, -9}, [26] = {871, 15724, -10}, [27] = {872, 15172, -13}, [28] = {873, 15392, -17}, [29] = {874, 15171, -20}, [30] = {875, 16190, -24}, [31] = {880, 7717, -9}, [32] = {905, 5182, -11}, [33] = {972, 8495, -15}, [34] = {973, 7638, -17}, [35] = {1617, 5021, -22}, [36] = {1618, 4514, -23}, [37] = {1619, 8761, -24}, [38] = {1620, 10362, -26}},
[4] = { [1] = {604, 50, 4}, [2] = {829, 45, 9}, [3] = {1019, 107, 3}, [4] = {1566, 159, 6}, [5] = {1955, 35, 9}, [6] = {2139, 48, 8}},
[5] = { [1] = {989, 34370, 3}, [2] = {990, 31419, 4}, [3] = {991, 30719, 6}, [4] = {992, 29934, 7}, [5] = {999, 26551, 3}, [6] = {1000, 26253, 4}, [7] = {1001, 23745, 6}, [8] = {1002, 20552, 7}, [9] = {1007, 31717, 3}, [10] = {1602, 25280, -7}, [11] = {1603, 20924, -11}, [12] = {1604, 18995, -16}, [13] = {1605, 18301, -20}, [14] = {1606, 26867, -25}, [15] = {1607, 36635, -30}, [16] = {1608, 42328, -35}, [17] = {1609, 41708, -41}, [18] = {1610, 46011, -46}, [19] = {1611, 59394, -52}, [20] = {1612, 69027, -57}, [21] = {1613, 65405, -63}, [22] = {1614, 66232, -69}, [23] = {1615, 66048, -75}, [24] = {1616, 56580, -80}, [25] = {1617, 61048, -86}, [26] = {1618, 62862, -91}, [27] = {1619, 66721, -97}, [28] = {1620, 57856, -103}, [29] = {1621, 44363, -108}, [30] = {1622, 36273, -113}, [31] = {1623, 33730, -118}, [32] = {1624, 29061, -123}, [33] = {1625, 27504, -128}, [34] = {1626, 24325, -133}},
[6] = { [1] = {373, 34012732, -34}, [2] = {374, 28584692, -45}, [3] = {381, 70683783, -13}, [4] = {392, 60995252, -32}, [5] = {396, 34814716, -12}, [6] = {400, 29844559, -12}, [7] = {414, 53383765, -12}, [8] = {428, 43439850, -12}, [9] = {429, 47416866, -24}, [10] = {459, 82091366, -13}, [11] = {460, 81336084, -25}, [12] = {465, 46533188, -36}, [13] = {491, 47740464, -12}, [14] = {493, 32929218, -12}, [15] = {494, 27356739, -23}, [16] = {495, 31158458, -35}, [17] = {497, 41252768, -12}, [18] = {498, 49977060, -24}, [19] = {500, 58364955, -12}, [20] = {501, 66820641, -25}, [21] = {512, 66562423, -12}, [22] = {515, 50687411, -12}, [23] = {559, 82465688, -13}, [24] = {568, 27093458, -12}, [25] = {569, 37843093, -23}, [26] = {570, 47328234, -35}},
[7] = { [1] = {998, 4494, 4}, [2] = {999, 4286, 6}, [3] = {1000, 4623, 7}, [4] = {1001, 3809, 8}, [5] = {1002, 2943, 9}, [6] = {1003, 2907, 10}, [7] = {1602, 3007, -4}, [8] = {1603, 3404, -7}, [9] = {1604, 3955, -10}, [10] = {1605, 3933, -13}, [11] = {1606, 5390, -16}, [12] = {1607, 6394, -19}, [13] = {1608, 5156, -22}, [14] = {1609, 4949, -25}, [15] = {1610, 5049, -28}, [16] = {1611, 6166, -32}, [17] = {1612, 6270, -35}, [18] = {1613, 5486, -38}, [19] = {1614, 5593, -41}, [20] = {1615, 6442, -45}, [21] = {1616, 5310, -48}, [22] = {1617, 4507, -51}, [23] = {1618, 4146, -54}, [24] = {1619, 4190, -57}, [25] = {1620, 3814, -59}, [26] = {1621, 3619, -62}, [27] = {1622, 3868, -65}, [28] = {1623, 3889, -68}, [29] = {1624, 4041, -71}, [30] = {1625, 3283, -73}, [31] = {1626, 2637, -76}, [32] = {1676, 5081, 4}, [33] = {1677, 4662, 5}, [34] = {1678, 4606, 6}, [35] = {1708, 7445, 5}, [36] = {1779, 7471, -7}, [37] = {1780, 7597, -9}, [38] = {1781, 6651, -11}, [39] = {1782, 6780, -13}, [40] = {1783, 7804, -14}, [41] = {1784, 6438, -16}, [42] = {1785, 5469, -18}, [43] = {1786, 5034, -20}, [44] = {1787, 5087, -23}, [45] = {1788, 4634, -24}, [46] = {1789, 4398, -26}, [47] = {1790, 4699, -27}, [48] = {1806, 5533, -9}, [49] = {1807, 5370, -10}, [50] = {1808, 4887, -11}, [51] = {1809, 4308, -13}, [52] = {1810, 3983, -15}, [53] = {1811, 3485, -17}, [54] = {1812, 3499, -18}, [55] = {1813, 3093, -20}, [56] = {1814, 3396, -21}, [57] = {1815, 2974, -21}, [58] = {1830, 7727, -10}, [59] = {1831, 8256, -11}, [60] = {1832, 6386, -13}, [61] = {1833, 5842, -15}, [62] = {1834, 5024, -17}, [63] = {1835, 3273, -18}, [64] = {1836, 4715, -20}, [65] = {1856, 7084, -11}, [66] = {1857, 6387, -13}, [67] = {1858, 4707, -15}, [68] = {1909, 3276, -19}},
[8] = { [1] = {376, 75154, -6}, [2] = {398, 58402, -6}, [3] = {515, 74990, -6}, [4] = {516, 70139, -12}, [5] = {548, 37509, -5}, [6] = {549, 43411, -8}, [7] = {624, 79671, -6}, [8] = {625, 85177, -12}, [9] = {737, 50284, -6}, [10] = {738, 39857, -9}, [11] = {746, 111884, -8}, [12] = {747, 116346, -12}, [13] = {748, 129470, -16}, [14] = {749, 128297, -22}, [15] = {750, 126046, -26}, [16] = {964, 110800, -6}, [17] = {965, 115232, -13}, [18] = {966, 114167, -19}, [19] = {967, 107882, -25}, [20] = {968, 98986, -32}, [21] = {973, 66559, -6}, [22] = {982, 61196, -6}, [23] = {983, 68267, -12}, [24] = {984, 91954, -18}, [25] = {985, 89012, -24}, [26] = {1000, 58560, 3}, [27] = {1001, 46075, 4}, [28] = {1002, 43335, 5}, [29] = {1003, 38890, 5}, [30] = {1004, 48031, 6}, [31] = {1215, 86022, -6}, [32] = {1216, 84890, -12}, [33] = {1281, 107808, -6}, [34] = {1282, 109011, -13}, [35] = {1308, 72338, -6}, [36] = {1309, 66345, -12}, [37] = {1315, 42765, -5}, [38] = {1316, 45806, -11}, [39] = {1347, 151318, -14}, [40] = {1348, 147686, -21}, [41] = {1367, 135910, -6}, [42] = {1368, 139167, -13}, [43] = {1369, 131364, -19}, [44] = {1374, 161818, -7}, [45] = {1375, 144604, -13}, [46] = {1377, 138159, -6}, [47] = {1383, 80339, -6}, [48] = {1384, 79282, -12}, [49] = {1387, 64823, -6}, [50] = {1388, 68162, -11}, [51] = {1390, 110064, -6}, [52] = {1391, 122954, -13}, [53] = {1420, 146896, -7}, [54] = {1421, 141497, -13}, [55] = {1423, 133137, -6}, [56] = {1424, 128580, -13}, [57] = {1426, 118546, -6}, [58] = {1427, 111370, -12}, [59] = {1451, 107430, -6}, [60] = {1452, 88016, -12}, [61] = {1463, 100759, -6}, [62] = {1470, 108404, -6}, [63] = {1471, 96406, -12}, [64] = {1472, 93062, -18}, [65] = {1487, 74686, -6}, [66] = {1495, 107865, -6}, [67] = {1496, 105203, -12}, [68] = {1506, 0, 5}, [69] = {1507, 0, 11}, [70] = {1528, 63569, -6}, [71] = {1529, 55292, -11}, [72] = {1531, 57151, -5}, [73] = {1532, 63759, -11}, [74] = {1545, 137930, -6}, [75] = {1546, 134440, -13}, [76] = {1601, 52295, -7}, [77] = {1602, 47917, -13}, [78] = {1603, 51376, -18}, [79] = {1604, 61948, -24}, [80] = {1605, 74730, -29}, [81] = {1606, 103389, -35}, [82] = {1607, 109581, -42}, [83] = {1608, 112106, -48}, [84] = {1609, 121259, -54}, [85] = {1610, 138555, -60}, [86] = {1611, 139863, -67}, [87] = {1612, 140212, -73}, [88] = {1613, 145845, -80}, [89] = {1614, 140178, -86}, [90] = {1615, 126620, -92}, [91] = {1616, 117533, -98}, [92] = {1617, 103879, -104}, [93] = {1618, 108143, -111}, [94] = {1619, 106340, -117}, [95] = {1620, 87123, -123}, [96] = {1621, 72733, -128}, [97] = {1622, 63972, -134}, [98] = {1623, 55415, -139}, [99] = {1624, 53425, -145}, [100] = {1625, 46494, -150}, [101] = {1728, 121492, -6}, [102] = {1729, 133193, -13}, [103] = {1751, 122174, -6}, [104] = {1752, 125142, -13}, [105] = {1788, 89854, -6}, [106] = {1789, 75013, -12}, [107] = {1791, 57227, -6}, [108] = {1792, 55172, -11}, [109] = {1830, 107754, -7}, [110] = {1831, 98293, -13}, [111] = {1876, 162250, -7}, [112] = {1877, 163425, -13}, [113] = {1879, 135607, -6}, [114] = {1880, 140059, -13}, [115] = {1899, 165938, -7}, [116] = {1900, 166305, -13}, [117] = {1901, 156795, -20}, [118] = {1904, 148445, -6}, [119] = {1905, 140237, -13}, [120] = {1906, 125635, -19}, [121] = {1937, 61744, -6}, [122] = {1938, 58069, -11}, [123] = {1939, 61417, -17}, [124] = {1940, 74011, -23}, [125] = {1946, 146961, -6}, [126] = {1947, 159955, -13}, [127] = {1955, 106981, -6}, [128] = {1956, 93343, -12}, [129] = {1957, 77927, -18}, [130] = {1960, 57048, -5}, [131] = {1961, 55664, -11}, [132] = {1962, 40027, -16}, [133] = {1984, 46502, -5}, [134] = {1985, 41859, -10}, [135] = {1999, 94212, -6}, [136] = {2000, 97878, -12}, [137] = {2003, 77470, -6}, [138] = {2004, 57507, -11}, [139] = {2034, 46470, -5}, [140] = {2035, 53043, -11}, [141] = {2040, 108979, -6}, [142] = {2041, 113778, -12}, [143] = {2056, 75543, -6}, [144] = {2057, 64973, -11}, [145] = {2059, 61052, -5}, [146] = {2060, 69486, -11}, [147] = {2061, 81368, -17}, [148] = {2131, 39492, -5}, [149] = {2132, 46157, -10}, [150] = {2142, 76315, -6}, [151] = {2143, 63465, -11}},
[9] = { [1] = {991, 83724, 3}, [2] = {992, 77016, 3}, [3] = {1000, 46043, 2}, [4] = {1001, 38559, 3}, [5] = {1002, 27808, 5}, [6] = {1601, 47836, -2}, [7] = {1602, 37178, -7}, [8] = {1603, 34690, -12}, [9] = {1604, 36647, -18}, [10] = {1605, 41384, -23}, [11] = {1606, 56292, -29}, [12] = {1607, 76975, -35}, [13] = {1608, 82188, -41}, [14] = {1609, 82003, -47}, [15] = {1610, 85640, -53}, [16] = {1611, 99894, -59}, [17] = {1612, 109018, -66}, [18] = {1613, 112995, -72}, [19] = {1614, 110345, -78}, [20] = {1615, 103379, -85}, [21] = {1616, 93076, -91}, [22] = {1617, 85651, -97}, [23] = {1618, 82410, -103}, [24] = {1619, 87826, -109}, [25] = {1620, 73692, -115}, [26] = {1621, 57543, -121}, [27] = {1622, 53638, -127}, [28] = {1623, 48656, -132}, [29] = {1624, 43736, -138}, [30] = {1625, 38606, -143}, [31] = {1626, 34205, -148}, [32] = {1952, 105540, -3}, [33] = {1980, 48876, -3}, [34] = {1981, 42224, -4}},
[10] = { [1] = {1184, 2972, 3}, [2] = {1185, 2386, 3}, [3] = {1186, 2613, 4}, [4] = {1206, 2995, 3}, [5] = {1207, 2998, 4}, [6] = {1208, 3361, 5}, [7] = {1235, 3586, 4}, [8] = {1602, 2154, -4}, [9] = {1603, 1866, -6}, [10] = {1604, 1700, -8}, [11] = {1605, 2035, -11}, [12] = {1606, 2850, -13}, [13] = {1607, 4001, -16}, [14] = {1608, 4763, -19}, [15] = {1609, 5390, -22}, [16] = {1610, 5318, -26}, [17] = {1611, 5730, -29}, [18] = {1612, 6331, -32}, [19] = {1613, 6014, -36}, [20] = {1614, 6163, -39}, [21] = {1615, 5378, -42}, [22] = {1616, 6088, -46}, [23] = {1617, 5954, -49}, [24] = {1618, 6000, -52}, [25] = {1619, 5929, -56}, [26] = {1620, 5267, -59}, [27] = {1621, 4758, -62}, [28] = {1622, 3659, -65}, [29] = {1623, 3242, -67}, [30] = {1624, 2434, -70}, [31] = {1625, 1962, -72}, [32] = {1626, 2095, -74}, [33] = {1767, 2685, -3}, [34] = {1773, 1595, -4}, [35] = {1774, 2246, -5}, [36] = {1775, 3165, -6}, [37] = {1776, 3774, -8}, [38] = {1777, 4275, -9}, [39] = {1778, 4217, -11}, [40] = {1779, 4546, -12}, [41] = {1780, 5026, -13}, [42] = {1781, 4773, -15}, [43] = {1782, 4892, -16}, [44] = {1783, 4265, -17}, [45] = {1784, 4833, -18}, [46] = {1785, 4725, -20}, [47] = {1786, 4762, -21}, [48] = {1787, 4705, -23}, [49] = {1788, 4177, -24}, [50] = {1789, 3770, -25}, [51] = {1790, 2892, -26}, [52] = {1791, 2559, -27}, [53] = {1792, 1913, -28}, [54] = {1793, 1537, -29}, [55] = {1794, 1643, -30}, [56] = {1800, 3030, -5}, [57] = {1801, 3351, -6}, [58] = {1802, 3404, -8}, [59] = {1803, 3344, -9}, [60] = {1804, 3331, -10}, [61] = {1805, 3527, -11}, [62] = {1806, 3640, -12}, [63] = {1807, 3568, -14}, [64] = {1808, 3539, -15}, [65] = {1809, 3235, -16}, [66] = {1810, 3025, -17}, [67] = {1811, 2798, -18}, [68] = {1812, 2826, -19}, [69] = {1813, 2447, -21}, [70] = {1814, 1985, -21}, [71] = {1815, 1789, -22}, [72] = {1816, 1486, -23}, [73] = {1817, 1286, -23}, [74] = {1818, 1145, -24}, [75] = {1825, 2628, -4}, [76] = {1826, 2830, -5}, [77] = {1827, 2859, -7}, [78] = {1833, 3175, -6}, [79] = {1834, 3035, -7}, [80] = {1835, 2946, -8}, [81] = {1836, 2956, -9}, [82] = {1837, 2520, -10}, [83] = {1838, 2138, -11}, [84] = {1839, 1812, -11}, [85] = {1840, 1696, -12}, [86] = {1841, 1689, -12}, [87] = {1842, 1467, -13}, [88] = {1850, 3789, -6}, [89] = {1851, 4242, -7}, [90] = {1852, 5186, -8}, [91] = {1853, 5281, -9}, [92] = {1854, 5550, -10}, [93] = {1855, 5565, -11}, [94] = {1856, 6620, -12}, [95] = {1857, 6548, -14}, [96] = {1858, 6419, -15}, [97] = {1859, 5318, -16}, [98] = {1860, 4628, -17}, [99] = {1861, 3851, -18}, [100] = {1862, 3067, -19}, [101] = {1863, 2531, -19}, [102] = {1864, 2200, -20}, [103] = {1865, 1922, -21}, [104] = {1866, 1679, -21}, [105] = {1875, 4690, -7}, [106] = {1876, 5303, -9}, [107] = {1877, 5713, -10}, [108] = {1878, 8209, -11}, [109] = {1879, 7812, -13}, [110] = {1880, 7210, -14}, [111] = {1881, 5330, -15}, [112] = {1882, 5409, -17}, [113] = {1883, 5270, -18}, [114] = {1884, 4867, -19}, [115] = {1885, 3917, -20}, [116] = {1886, 2966, -21}, [117] = {1887, 2348, -22}, [118] = {1888, 1962, -22}, [119] = {1889, 1827, -23}, [120] = {1904, 4824, -7}, [121] = {1905, 4932, -8}, [122] = {2077, 10524, -10}},
[11] = { [1] = {1097, 4292, -2}, [2] = {1266, 3994, -3}, [3] = {1267, 4725, -6}, [4] = {1268, 4710, -10}, [5] = {1269, 4667, -13}, [6] = {1270, 4658, -16}, [7] = {1271, 4582, -19}, [8] = {1272, 4015, -23}, [9] = {1273, 4481, -26}, [10] = {1274, 4477, -29}, [11] = {1275, 4388, -32}, [12] = {1276, 2678, -35}, [13] = {1277, 3325, -38}, [14] = {1278, 4346, -41}, [15] = {1279, 3900, -44}, [16] = {1280, 4227, -47}, [17] = {1281, 3957, -51}, [18] = {1282, 4172, -54}, [19] = {1283, 4509, -57}, [20] = {1284, 4520, -60}, [21] = {1285, 4451, -63}, [22] = {1286, 4773, -67}, [23] = {1287, 4640, -70}, [24] = {1288, 4966, -73}, [25] = {1289, 4406, -76}, [26] = {1290, 4663, -80}},
[12] = { [1] = {1602, 3957234, -12}, [2] = {1603, 3413756, -21}, [3] = {1604, 3454344, -31}, [4] = {1605, 3349242, -40}, [5] = {1606, 3477428, -50}, [6] = {1607, 3803595, -60}, [7] = {1608, 4165386, -70}, [8] = {1609, 4157225, -79}, [9] = {1610, 4097380, -89}, [10] = {1611, 3823224, -99}, [11] = {1612, 4235714, -109}, [12] = {1613, 3971866, -119}, [13] = {1614, 3964598, -128}, [14] = {1615, 3728162, -138}, [15] = {1616, 3668996, -148}, [16] = {1617, 5163411, -158}, [17] = {1618, 5100636, -168}, [18] = {1619, 5238875, -178}, [19] = {1620, 5055328, -188}, [20] = {1621, 4992768, -198}, [21] = {1622, 4427434, -208}, [22] = {1623, 4338454, -218}, [23] = {1624, 4012025, -228}, [24] = {1625, 3844393, -237}, [25] = {1626, 3917817, -247}},
[13] = { [1] = {675, 16046, 3}, [2] = {704, 12031, -5}, [3] = {705, 11691, -7}, [4] = {706, 11364, -11}, [5] = {707, 9467, -15}, [6] = {708, 11237, -19}, [7] = {709, 10295, -19}, [8] = {726, 13314, -4}, [9] = {853, 7760, -5}, [10] = {1603, 3115, -2}, [11] = {1604, 3586, -5}, [12] = {1605, 4290, -8}, [13] = {1606, 6508, -12}, [14] = {1607, 8451, -16}, [15] = {1608, 9707, -20}, [16] = {1609, 10807, -24}, [17] = {1610, 10867, -28}, [18] = {1611, 13404, -32}, [19] = {1612, 13918, -36}, [20] = {1613, 14754, -41}, [21] = {1614, 14623, -45}, [22] = {1615, 14546, -49}, [23] = {1616, 13126, -54}, [24] = {1617, 13763, -58}, [25] = {1618, 13280, -62}, [26] = {1619, 12870, -66}, [27] = {1620, 11785, -70}, [28] = {1621, 9860, -74}, [29] = {1622, 9083, -78}, [30] = {1623, 6554, -82}, [31] = {1624, 4782, -85}, [32] = {1625, 3804, -88}, [33] = {1626, 2919, -91}, [34] = {1627, 2362, -93}, [35] = {1628, 2928, -96}, [36] = {1629, 3355, -99}, [37] = {1630, 4649, -102}, [38] = {1631, 6428, -105}, [39] = {1632, 8312, -108}, [40] = {1633, 9162, -110}, [41] = {1636, 9690, -4}, [42] = {1637, 10037, -7}, [43] = {1638, 9928, -10}, [44] = {1639, 10043, -13}},
[14] = { [1] = {988, 123557, 3}, [2] = {989, 161261, 5}, [3] = {990, 167778, 6}, [4] = {991, 149057, 8}, [5] = {1000, 90086, 5}, [6] = {1001, 117265, 6}, [7] = {1002, 84378, 9}, [8] = {1003, 56917, 11}, [9] = {1004, 51090, 12}, [10] = {1005, 56093, 14}, [11] = {1006, 75687, 16}, [12] = {1007, 105721, 16}, [13] = {1029, 59271, 3}, [14] = {1030, 79214, 4}, [15] = {1031, 97440, 5}, [16] = {1052, 63110, 4}, [17] = {1187, 218990, -5}, [18] = {1602, 151017, -9}, [19] = {1603, 65463, -14}, [20] = {1604, 63153, -20}, [21] = {1605, 69324, -26}, [22] = {1606, 86411, -32}, [23] = {1607, 123981, -38}, [24] = {1608, 154218, -45}, [25] = {1609, 152971, -51}, [26] = {1610, 169942, -58}, [27] = {1611, 252881, -65}, [28] = {1612, 391159, -73}, [29] = {1613, 393438, -80}, [30] = {1614, 334021, -87}, [31] = {1615, 322997, -95}, [32] = {1616, 284174, -102}, [33] = {1617, 254154, -109}, [34] = {1618, 244530, -116}, [35] = {1619, 232009, -123}, [36] = {1620, 201271, -130}, [37] = {1621, 159839, -136}, [38] = {1622, 135210, -143}, [39] = {1623, 157946, -149}, [40] = {1624, 169897, -156}, [41] = {1625, 202056, -163}, [42] = {1626, 169829, -170}},
[15] = { [1] = {396, 31, 4}, [2] = {403, 30, 3}, [3] = {500, 28, 2}, [4] = {821, 30, 3}, [5] = {822, 33, 3}, [6] = {833, 28, 3}, [7] = {843, 46, 5}, [8] = {876, 115, 4}, [9] = {1000, 111, 9}, [10] = {1004, 126, 5}, [11] = {1005, 242, 7}, [12] = {1372, 136, 7}, [13] = {1373, 118, 8}, [14] = {1374, 73, 10}, [15] = {1375, 139, 12}, [16] = {1376, 38, 14}, [17] = {1377, 38, 16}, [18] = {1378, 38, 18}, [19] = {1379, 64, 20}, [20] = {1380, 4, 22}, [21] = {1381, 5, 24}, [22] = {1382, 24, 25}, [23] = {1383, 100, 27}, [24] = {1384, 79, 29}, [25] = {1385, 76, 30}, [26] = {1386, 67, 32}, [27] = {1387, 113, 33}, [28] = {1388, 96, 33}, [29] = {1389, 72, 35}, [30] = {1390, 154, 36}, [31] = {1730, 0, 3}, [32] = {1738, 0, 4}, [33] = {1893, 22, 3}, [34] = {1920, 26, 5}, [35] = {1941, 0, 4}, [36] = {1957, 0, 6}, [37] = {1985, 0, 6}, [38] = {1986, 15, 6}, [39] = {1987, 8, 6}, [40] = {1988, 0, 6}, [41] = {1989, 1, 7}, [42] = {1990, 0, 7}, [43] = {1991, 19, 7}},
[16] = { [1] = {882, 366141, -4}, [2] = {985, 444102, -2}, [3] = {988, 541872, 2}, [4] = {989, 593715, 4}, [5] = {990, 580520, 5}, [6] = {991, 552278, 6}, [7] = {1000, 423902, 2}, [8] = {1001, 460458, 4}, [9] = {1002, 344035, 5}, [10] = {1003, 261088, 7}, [11] = {1004, 222265, 8}, [12] = {1005, 231301, 10}, [13] = {1030, 382413, 3}, [14] = {1031, 468247, 3}, [15] = {1601, 540371, -2}, [16] = {1602, 457763, -10}, [17] = {1603, 321276, -18}, [18] = {1604, 290882, -25}, [19] = {1605, 299915, -32}, [20] = {1606, 389359, -40}, [21] = {1607, 491319, -48}, [22] = {1608, 554574, -56}, [23] = {1609, 550206, -64}, [24] = {1610, 591322, -72}, [25] = {1611, 723122, -80}, [26] = {1612, 872399, -89}, [27] = {1613, 893886, -97}, [28] = {1614, 827981, -105}, [29] = {1615, 822949, -114}, [30] = {1616, 757685, -122}, [31] = {1617, 747872, -130}, [32] = {1618, 737985, -139}, [33] = {1619, 704060, -147}, [34] = {1620, 693717, -155}, [35] = {1621, 588669, -163}, [36] = {1622, 532197, -171}, [37] = {1623, 528106, -179}, [38] = {1624, 496937, -187}, [39] = {1625, 512261, -195}, [40] = {1626, 418681, -203}, [41] = {1779, 750616, 2}, [42] = {1780, 905566, 2}, [43] = {1892, 471384, 2}, [44] = {1893, 517252, 2}, [45] = {2037, 576220, 4}, [46] = {2038, 681432, 4}, [47] = {2039, 817423, 4}},
[17] = { [1] = {485, 14289, -5}, [2] = {618, 8137, -3}, [3] = {705, 22142, -3}, [4] = {706, 22591, -8}, [5] = {707, 23325, -13}, [6] = {708, 23726, -18}, [7] = {709, 21990, -22}, [8] = {867, 17122, -4}, [9] = {1176, 7285, -4}, [10] = {1177, 11919, -8}, [11] = {1602, 9895, -4}, [12] = {1603, 9391, -8}, [13] = {1604, 8331, -12}, [14] = {1605, 7839, -16}, [15] = {1606, 6537, -19}, [16] = {1607, 6852, -23}, [17] = {1608, 9525, -27}, [18] = {1609, 13838, -31}, [19] = {1610, 15405, -36}, [20] = {1611, 16411, -40}, [21] = {1612, 16424, -45}, [22] = {1613, 17577, -49}, [23] = {1614, 18708, -54}, [24] = {1615, 21238, -59}, [25] = {1616, 22267, -63}, [26] = {1617, 28427, -68}, [27] = {1618, 22740, -73}, [28] = {1619, 22739, -78}, [29] = {1620, 20899, -83}, [30] = {1621, 25373, -88}, [31] = {1622, 19104, -92}, [32] = {1623, 14800, -97}, [33] = {1624, 12479, -101}, [34] = {1625, 11112, -105}, [35] = {1626, 8827, -109}, [36] = {1627, 8514, -113}, [37] = {1628, 8376, -117}, [38] = {1629, 7812, -120}, [39] = {1630, 6516, -123}, [40] = {1631, 6775, -126}, [41] = {1632, 8769, -130}, [42] = {1633, 11949, -134}, [43] = {1634, 14414, -137}, [44] = {1637, 18009, -2}, [45] = {1638, 15592, -6}, [46] = {1639, 16261, -10}, [47] = {1640, 17166, -14}, [48] = {1723, 10284, 2}, [49] = {1724, 10734, 3}, [50] = {1725, 8907, 3}, [51] = {1726, 7729, 4}, [52] = {1727, 9010, 5}, [53] = {1728, 11603, 5}, [54] = {1729, 15100, 6}, [55] = {1730, 14451, 7}, [56] = {1731, 17932, 8}, [57] = {1732, 18916, 8}, [58] = {1739, 25850, 3}, [59] = {1740, 25845, 3}, [60] = {1741, 25423, 3}, [61] = {1742, 22745, 4}, [62] = {1743, 19674, 5}, [63] = {1744, 15752, 5}, [64] = {1868, 11707, 2}, [65] = {1869, 10839, 3}, [66] = {1870, 9451, 3}, [67] = {1871, 12385, 3}, [68] = {1872, 13864, 4}, [69] = {1873, 19328, 4}, [70] = {1874, 21663, 4}, [71] = {1875, 21478, 4}, [72] = {1876, 22602, 5}, [73] = {1877, 24502, 5}, [74] = {1878, 27478, 5}, [75] = {1879, 29773, 5}, [76] = {1880, 30891, 5}, [77] = {1881, 32341, 6}, [78] = {1882, 31267, 6}, [79] = {1883, 28129, 6}, [80] = {1884, 30247, 7}, [81] = {1885, 28466, 8}, [82] = {1886, 28366, 9}, [83] = {1887, 25312, 10}, [84] = {1888, 20655, 11}, [85] = {1916, 13590, 3}, [86] = {1917, 11162, 4}, [87] = {1918, 9519, 5}, [88] = {1919, 12037, 6}, [89] = {1920, 14399, 8}, [90] = {1941, 10801, 4}, [91] = {1942, 9223, 5}, [92] = {1943, 9910, 7}, [93] = {1944, 13204, 8}, [94] = {1945, 18178, 8}, [95] = {1946, 20228, 9}, [96] = {1947, 20522, 10}, [97] = {1948, 20589, 11}, [98] = {1971, 14695, 9}, [99] = {1972, 16858, 10}, [100] = {1992, 11438, 6}, [101] = {1993, 14852, 6}},
[18] = { [1] = {485, 4696, -3}, [2] = {618, 2746, -3}, [3] = {705, 7366, -3}, [4] = {706, 7497, -7}, [5] = {707, 7732, -10}, [6] = {708, 7873, -14}, [7] = {709, 7294, -18}, [8] = {867, 5683, -3}, [9] = {1602, 3279, -3}, [10] = {1603, 3122, -6}, [11] = {1604, 2667, -9}, [12] = {1605, 2511, -11}, [13] = {1606, 2177, -14}, [14] = {1607, 2282, -16}, [15] = {1608, 3162, -19}, [16] = {1609, 4590, -23}, [17] = {1610, 5106, -26}, [18] = {1611, 5436, -29}, [19] = {1612, 5443, -33}, [20] = {1613, 5821, -36}, [21] = {1614, 6187, -40}, [22] = {1615, 7028, -44}, [23] = {1616, 7368, -47}, [24] = {1617, 9417, -51}, [25] = {1618, 7525, -55}, [26] = {1619, 7524, -59}, [27] = {1620, 6922, -62}, [28] = {1621, 8393, -66}, [29] = {1622, 6329, -70}, [30] = {1623, 4896, -73}, [31] = {1624, 4135, -76}, [32] = {1625, 3689, -79}, [33] = {1626, 2926, -82}, [34] = {1627, 2837, -85}, [35] = {1628, 2796, -88}, [36] = {1629, 2601, -90}, [37] = {1630, 2164, -93}, [38] = {1631, 2253, -95}, [39] = {1632, 2900, -98}, [40] = {1633, 3941, -101}, [41] = {1634, 4751, -104}, [42] = {1637, 5946, -2}, [43] = {1638, 5145, -5}, [44] = {1639, 5370, -8}, [45] = {1640, 5667, -12}, [46] = {1723, 3434, 2}, [47] = {1724, 3587, 3}, [48] = {1725, 2980, 3}, [49] = {1726, 2526, 4}, [50] = {1727, 3001, 5}, [51] = {1728, 3867, 5}, [52] = {1729, 5016, 6}, [53] = {1730, 5882, 7}, [54] = {1731, 5947, 8}, [55] = {1732, 6276, 8}, [56] = {1738, 8977, 2}, [57] = {1743, 6659, 2}, [58] = {1869, 3678, 2}, [59] = {1870, 3204, 3}, [60] = {1871, 4187, 3}, [61] = {1872, 4660, 3}, [62] = {1873, 6498, 4}, [63] = {1874, 7284, 4}, [64] = {1875, 7220, 4}, [65] = {1876, 7600, 4}, [66] = {1877, 8227, 5}, [67] = {1878, 9230, 5}, [68] = {1879, 10004, 5}, [69] = {1880, 10379, 5}, [70] = {1881, 10860, 5}, [71] = {1882, 10500, 5}, [72] = {1883, 9452, 6}, [73] = {1884, 10161, 7}, [74] = {1885, 9566, 8}, [75] = {1886, 9547, 8}, [76] = {1887, 8510, 9}, [77] = {1888, 6959, 10}, [78] = {1916, 4568, 3}, [79] = {1921, 7447, 4}, [80] = {1922, 7845, 5}, [81] = {1923, 7595, 5}, [82] = {1924, 8278, 6}, [83] = {1941, 3582, 4}, [84] = {1942, 3148, 5}, [85] = {1943, 3379, 6}, [86] = {1944, 4476, 7}, [87] = {1971, 5054, 8}, [88] = {1972, 5767, 9}, [89] = {1994, 6006, 6}, [90] = {1995, 6149, 7}, [91] = {1996, 6263, 7}, [92] = {1997, 6201, 8}, [93] = {1998, 6428, 8}},
[19] = {},
[20] = { [1] = {726, 215, -2}, [2] = {1445, 293, -2}, [3] = {1620, 162, -2}, [4] = {1621, 165, -3}, [5] = {2027, 76, -2}},
[21] = { [1] = {714, 9, 2}, [2] = {738, 64, 2}},
[22] = { [1] = {1625, 72, 5}, [2] = {1626, 70, 10}, [3] = {1627, 82, 15}, [4] = {1628, 80, 19}, [5] = {1629, 84, 24}, [6] = {1630, 61, 28}, [7] = {1631, 43, 30}, [8] = {1640, 1256, -2}, [9] = {1641, 1126, -4}, [10] = {1642, 1047, -6}, [11] = {1643, 742, -7}, [12] = {1655, 32, 4}, [13] = {1656, 18, 10}, [14] = {1657, 12, 15}, [15] = {1658, 14, 20}, [16] = {1659, 11, 25}, [17] = {1660, 13, 29}, [18] = {1661, 28, 32}, [19] = {1662, 35, 37}, [20] = {1664, 1153, -2}, [21] = {1667, 650, -3}, [22] = {1689, 870, -3}, [23] = {1690, 798, -5}, [24] = {1691, 706, -6}, [25] = {1692, 362, -7}, [26] = {1713, 783, -3}, [27] = {1714, 695, -5}, [28] = {1715, 552, -6}, [29] = {1716, 401, -7}, [30] = {1737, 911, -3}, [31] = {1738, 771, -5}, [32] = {1739, 556, -6}, [33] = {1747, 37, 3}, [34] = {1761, 799, -3}, [35] = {1762, 1026, -5}, [36] = {1785, 1009, -3}, [37] = {1786, 898, -5}, [38] = {1822, 4, 4}, [39] = {1831, 11, 7}, [40] = {1836, 29, 4}, [41] = {1837, 14, 5}, [42] = {1838, 16, 7}, [43] = {1839, 12, 8}, [44] = {1840, 111, 9}, [45] = {1841, 82, 11}, [46] = {1842, 16, 13}, [47] = {1843, 28, 15}, [48] = {1844, 21, 17}, [49] = {1845, 17, 19}, [50] = {1846, 15, 22}, [51] = {1847, 63, 24}, [52] = {1848, 54, 26}, [53] = {1849, 0, 29}, [54] = {1850, 0, 31}, [55] = {1851, 0, 34}, [56] = {1852, 0, 36}, [57] = {1853, 0, 39}, [58] = {1854, 5, 41}, [59] = {1855, 12, 43}, [60] = {1856, 403, 43}, [61] = {1864, 20, 5}, [62] = {1865, 22, 6}, [63] = {1866, 18, 8}, [64] = {1867, 26, 10}, [65] = {1868, 28, 12}, [66] = {1869, 20, 14}, [67] = {1870, 17, 16}, [68] = {1871, 11, 18}, [69] = {1872, 0, 20}, [70] = {1873, 0, 22}, [71] = {1874, 0, 25}, [72] = {1875, 0, 27}, [73] = {1876, 0, 29}, [74] = {1877, 5, 31}, [75] = {1878, 6, 33}, [76] = {1879, 15, 35}, [77] = {1880, 390, 35}, [78] = {1889, 24, 5}, [79] = {1890, 26, 7}, [80] = {1891, 31, 8}, [81] = {1892, 31, 10}, [82] = {1893, 29, 12}, [83] = {1894, 23, 14}, [84] = {1895, 13, 16}, [85] = {1896, 1, 18}, [86] = {1897, 1, 20}, [87] = {1898, 0, 23}, [88] = {1899, 0, 25}, [89] = {1900, 0, 27}, [90] = {1901, 10, 29}, [91] = {1902, 11, 31}, [92] = {1903, 23, 33}, [93] = {1904, 408, 34}, [94] = {1912, 33, 5}, [95] = {1913, 40, 7}, [96] = {1914, 37, 9}, [97] = {1918, 43, 6}, [98] = {1919, 33, 8}, [99] = {1920, 18, 9}, [100] = {1921, 8, 11}, [101] = {1922, 7, 14}, [102] = {1923, 6, 16}, [103] = {1924, 15, 18}, [104] = {1925, 24, 20}, [105] = {1926, 27, 23}, [106] = {1927, 41, 25}, [107] = {1928, 585, 26}, [108] = {1937, 56, 6}, [109] = {1938, 56, 8}, [110] = {1939, 59, 9}, [111] = {1940, 64, 11}, [112] = {1941, 65, 13}, [113] = {1942, 55, 14}, [114] = {1943, 41, 16}, [115] = {1944, 39, 18}, [116] = {1945, 23, 20}, [117] = {1946, 19, 22}, [118] = {1947, 21, 24}, [119] = {1948, 28, 25}, [120] = {1949, 36, 27}, [121] = {1950, 41, 30}, [122] = {1951, 59, 32}, [123] = {1952, 631, 32}, [124] = {1980, 54, 8}, [125] = {2139, 93, 10}, [126] = {2140, 55, 13}, [127] = {2141, 59, 16}, [128] = {2142, 68, 19}, [129] = {2143, 294, 21}, [130] = {2144, 1485, 22}, [131] = {2145, 1464, 23}, [132] = {2146, 1843, 24}, [133] = {2147, 987, 25}, [134] = {2155, 50, 10}, [135] = {2156, 36, 11}, [136] = {2157, 38, 13}}
}

local zz = 0

for line in io.lines(filePath) do
	local tokens = {}
	local index = 0
	for token in string.gmatch(line,"[_.%w]+") do
		index = index + 1
		tokens[index] = token
	end

	if(tokens[2] == "1h") then

		zz = zz + 1

		if(zz > 0) then

			local name = tokens[1]
			--print(name)

			local graph = {}
			local size = index/3 - 1

			for ii = 1,size do
				local triple = {}
				triple[1] = tonumber(tokens[3*ii + 1])
				triple[2] = tonumber(tokens[3*ii + 2])
				triple[3] = tonumber(tokens[3*ii + 3])
				graph[ii] = triple
			end

			local result = calculate_fdi(0, 3600, graph)

--[[
			for key,value in pairs(result) do
				print(key)
				print(value[1])
				print(value[2])
				print(value[3])
		  end
]]

			local tdind = 0
			for key,value in pairs(result) do
				if(value[2]) then
						local td = key - 1
						tdind = tdind + 1
						assert(matlab[zz][tdind][1] == td, string.format('failed test alarm: signal num = %d, alert num = %d, got %d instead of %d', zz, tdind, td, matlab[zz][tdind][1]))
						assert(matlab[zz][tdind][2] == math.floor(value[3]+0.5), string.format('failed test estimated: signal num = %d, alert num = %d, got %d instead of %d', zz, tdind, math.floor(value[3]+0.5), matlab[zz][tdind][2]))
						assert(matlab[zz][tdind][3] == value[4], string.format('failed test ano-measure: signal num = %d, alert num = %d, got %d instead of %d', zz, tdind, value[4], matlab[zz][tdind][3]))
				end
			end
			assert(tdind == #matlab[zz], string.format('failed test: signal num = %d, entries num = %d, expected = %d',zz, tdind, #matlab[zz]))
		end
	end
end
