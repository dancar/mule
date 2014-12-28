require 'calculate_fdi'

local filePath = './fdi/fixtures/graphs_of_interest.txt'
--local filePath = './fixtures/graphs_of_interest.txt'

local matlab = {
[1] = { [1] = {30, 2}, [2] = {31, 3}, [3] = {32, 3}, [4] = {33, 3}, [5] = {87, 3}, [6] = {88, 3}, [7] = {89, 3}, [8] = {93, 3}, [9] = {94, 3}, [10] = {102, 3}, [11] = {103, 3}, [12] = {108, 3}, [13] = {113, 2}, [14] = {114, 2}, [15] = {117, 1}, [16] = {118, 1}, [17] = {119, 1}, [18] = {120, 3}, [19] = {125, 3}, [20] = {126, 2}, [21] = {135, 3}, [22] = {158, 3}, [23] = {159, 3}, [24] = {185, 3}, [25] = {189, 3}, [26] = {190, 3}, [27] = {203, 3}, [28] = {204, 3}, [29] = {223, 3}, [30] = {224, 3}, [31] = {225, 3}, [32] = {227, 3}, [33] = {228, 3}, [34] = {255, 2}, [35] = {256, 1}, [36] = {257, 2}, [37] = {258, 2}, [38] = {267, 2}, [39] = {268, 1}, [40] = {271, 1}, [41] = {272, 1}, [42] = {285, 2}, [43] = {341, 3}, [44] = {358, 2}, [45] = {364, 2}},
[2] = { [1] = {30, 2}, [2] = {31, 3}, [3] = {32, 3}, [4] = {33, 3}, [5] = {37, 1}, [6] = {38, 1}, [7] = {39, 1}, [8] = {40, 1}, [9] = {44, 1}, [10] = {45, 1}, [11] = {46, 1}, [12] = {47, 1}, [13] = {76, 3}, [14] = {89, 3}, [15] = {90, 3}, [16] = {95, 3}, [17] = {96, 3}, [18] = {113, 1}, [19] = {114, 2}, [20] = {115, 2}, [21] = {116, 3}, [22] = {119, 1}, [23] = {120, 3}, [24] = {121, 3}, [25] = {122, 3}, [26] = {124, 3}, [27] = {125, 3}, [28] = {148, 3}, [29] = {150, 3}, [30] = {151, 3}, [31] = {166, 3}, [32] = {179, 3}, [33] = {206, 2}, [34] = {255, 2}, [35] = {258, 2}, [36] = {259, 2}, [37] = {260, 2}, [38] = {261, 2}, [39] = {267, 2}, [40] = {268, 2}, [41] = {270, 2}, [42] = {271, 2}, [43] = {274, 1}, [44] = {341, 2}, [45] = {364, 2}},
[3] = { [1] = {30, 2}, [2] = {31, 3}, [3] = {32, 3}, [4] = {33, 3}, [5] = {38, 1}, [6] = {39, 1}, [7] = {52, 1}, [8] = {53, 1}, [9] = {64, 1}, [10] = {65, 1}, [11] = {75, 3}, [12] = {77, 3}, [13] = {78, 3}, [14] = {97, 3}, [15] = {98, 3}, [16] = {102, 3}, [17] = {103, 3}, [18] = {104, 3}, [19] = {108, 3}, [20] = {109, 3}, [21] = {116, 3}, [22] = {117, 3}, [23] = {128, 3}, [24] = {129, 3}, [25] = {130, 3}, [26] = {131, 3}, [27] = {135, 2}, [28] = {137, 3}, [29] = {138, 3}, [30] = {142, 1}, [31] = {143, 3}, [32] = {144, 3}, [33] = {145, 2}, [34] = {234, 2}, [35] = {235, 2}, [36] = {259, 2}, [37] = {260, 2}, [38] = {264, 1}, [39] = {265, 1}, [40] = {266, 2}, [41] = {267, 1}, [42] = {284, 1}, [43] = {285, 3}, [44] = {291, 1}, [45] = {292, 1}, [46] = {293, 1}, [47] = {294, 1}, [48] = {341, 3}, [49] = {346, 2}, [50] = {352, 2}, [51] = {353, 2}, [52] = {354, 2}, [53] = {355, 2}, [54] = {359, 2}, [55] = {361, 2}, [56] = {362, 2}, [57] = {363, 2}, [58] = {364, 2}},
[4] = { [1] = {31, 2}, [2] = {32, 2}, [3] = {33, 2}, [4] = {34, 2}, [5] = {36, 2}, [6] = {37, 2}, [7] = {38, 2}, [8] = {39, 2}, [9] = {41, 2}, [10] = {42, 2}, [11] = {43, 2}, [12] = {44, 2}, [13] = {47, 2}, [14] = {48, 2}, [15] = {49, 2}, [16] = {51, 2}, [17] = {52, 2}, [18] = {53, 2}, [19] = {54, 2}, [20] = {60, 1}, [21] = {61, 1}, [22] = {67, 1}, [23] = {68, 1}, [24] = {69, 1}, [25] = {70, 1}, [26] = {105, 2}, [27] = {176, 1}, [28] = {177, 1}, [29] = {178, 1}, [30] = {179, 1}, [31] = {205, 1}, [32] = {206, 1}, [33] = {341, 2}},
[5] = { [1] = {28, 2}, [2] = {33, 1}, [3] = {34, 1}, [4] = {35, 1}, [5] = {42, 1}, [6] = {72, 3}, [7] = {113, 2}, [8] = {114, 2}, [9] = {115, 2}, [10] = {116, 2}, [11] = {205, 1}, [12] = {206, 2}, [13] = {207, 1}, [14] = {213, 1}, [15] = {255, 2}, [16] = {258, 2}, [17] = {259, 1}, [18] = {260, 2}, [19] = {261, 2}, [20] = {267, 2}, [21] = {268, 1}, [22] = {270, 2}, [23] = {271, 2}, [24] = {274, 1}, [25] = {275, 1}, [26] = {318, 1}, [27] = {332, 1}, [28] = {341, 2}, [29] = {349, 1}, [30] = {350, 1}, [31] = {351, 1}, [32] = {352, 1}, [33] = {364, 1}},
[6] = { [1] = {339, 3}, [2] = {340, 3}, [3] = {341, 3}, [4] = {342, 3}, [5] = {344, 3}, [6] = {345, 3}, [7] = {346, 3}, [8] = {347, 3}, [9] = {349, 3}, [10] = {350, 3}, [11] = {356, 3}, [12] = {357, 3}, [13] = {363, 3}, [14] = {364, 3}},
[7] = { [1] = {30, 2}, [2] = {31, 3}, [3] = {32, 3}, [4] = {33, 3}, [5] = {40, 1}, [6] = {41, 1}, [7] = {79, 1}, [8] = {84, 1}, [9] = {112, 3}, [10] = {113, 3}, [11] = {118, 1}, [12] = {119, 1}, [13] = {120, 1}, [14] = {121, 1}, [15] = {134, 3}, [16] = {172, 3}, [17] = {173, 3}, [18] = {181, 3}, [19] = {182, 3}, [20] = {185, 3}, [21] = {198, 2}, [22] = {201, 1}, [23] = {202, 2}, [24] = {203, 2}, [25] = {204, 2}, [26] = {213, 1}, [27] = {222, 1}, [28] = {223, 1}, [29] = {224, 1}, [30] = {225, 1}, [31] = {258, 1}, [32] = {259, 1}, [33] = {260, 1}, [34] = {261, 1}, [35] = {271, 1}, [36] = {288, 2}, [37] = {289, 2}, [38] = {316, 1}, [39] = {341, 2}, [40] = {345, 1}, [41] = {354, 1}, [42] = {355, 1}, [43] = {356, 1}, [44] = {357, 1}},
[8] = { [1] = {30, 3}, [2] = {31, 3}, [3] = {32, 3}, [4] = {33, 3}, [5] = {73, 3}, [6] = {74, 3}, [7] = {106, 3}, [8] = {107, 3}, [9] = {112, 3}, [10] = {114, 3}, [11] = {115, 3}, [12] = {122, 3}, [13] = {123, 3}, [14] = {129, 3}, [15] = {130, 3}, [16] = {131, 1}, [17] = {132, 1}, [18] = {163, 3}, [19] = {164, 3}, [20] = {165, 3}, [21] = {189, 2}, [22] = {201, 1}, [23] = {205, 1}, [24] = {206, 2}, [25] = {207, 1}, [26] = {208, 1}, [27] = {210, 3}, [28] = {221, 1}, [29] = {222, 1}, [30] = {223, 1}, [31] = {224, 1}, [32] = {227, 1}, [33] = {228, 1}, [34] = {229, 1}, [35] = {230, 1}, [36] = {266, 1}, [37] = {285, 2}, [38] = {316, 1}, [39] = {341, 3}, [40] = {358, 1}, [41] = {363, 1}, [42] = {364, 2}},
[9] = { [1] = {30, 3}, [2] = {31, 3}, [3] = {32, 3}, [4] = {33, 3}, [5] = {72, 3}, [6] = {78, 3}, [7] = {91, 3}, [8] = {92, 3}, [9] = {94, 3}, [10] = {95, 3}, [11] = {100, 3}, [12] = {101, 3}, [13] = {102, 3}, [14] = {116, 3}, [15] = {117, 3}, [16] = {118, 3}, [17] = {119, 3}, [18] = {125, 3}, [19] = {126, 3}, [20] = {136, 3}, [21] = {140, 3}, [22] = {141, 3}, [23] = {142, 3}, [24] = {146, 3}, [25] = {147, 3}, [26] = {151, 3}, [27] = {153, 3}, [28] = {154, 3}, [29] = {155, 3}, [30] = {161, 2}, [31] = {178, 3}, [32] = {179, 3}, [33] = {200, 1}, [34] = {201, 1}, [35] = {202, 2}, [36] = {203, 2}, [37] = {207, 1}, [38] = {212, 3}, [39] = {213, 3}, [40] = {214, 3}, [41] = {220, 3}, [42] = {221, 3}, [43] = {222, 1}, [44] = {223, 1}, [45] = {225, 3}, [46] = {226, 3}, [47] = {235, 1}, [48] = {266, 1}, [49] = {280, 1}, [50] = {285, 2}, [51] = {316, 1}, [52] = {341, 3}, [53] = {357, 1}, [54] = {358, 1}, [55] = {362, 1}, [56] = {363, 1}, [57] = {364, 2}},
[10] = { [1] = {30, 2}, [2] = {31, 3}, [3] = {32, 3}, [4] = {33, 3}, [5] = {37, 1}, [6] = {38, 1}, [7] = {39, 1}, [8] = {40, 1}, [9] = {45, 1}, [10] = {46, 1}, [11] = {58, 1}, [12] = {59, 1}, [13] = {60, 1}, [14] = {61, 1}, [15] = {72, 3}, [16] = {76, 3}, [17] = {77, 3}, [18] = {81, 3}, [19] = {82, 3}, [20] = {87, 3}, [21] = {88, 3}, [22] = {115, 1}, [23] = {116, 1}, [24] = {117, 1}, [25] = {118, 1}, [26] = {124, 2}, [27] = {125, 2}, [28] = {126, 2}, [29] = {127, 2}, [30] = {132, 2}, [31] = {133, 2}, [32] = {134, 2}, [33] = {135, 2}, [34] = {146, 3}, [35] = {147, 3}, [36] = {148, 3}, [37] = {177, 3}, [38] = {178, 3}, [39] = {205, 1}, [40] = {206, 2}, [41] = {207, 1}, [42] = {240, 1}, [43] = {257, 1}, [44] = {258, 1}, [45] = {259, 1}, [46] = {260, 1}, [47] = {268, 1}, [48] = {271, 1}, [49] = {276, 1}, [50] = {277, 1}, [51] = {278, 1}, [52] = {285, 2}, [53] = {330, 1}, [54] = {331, 1}, [55] = {341, 2}, [56] = {348, 2}, [57] = {349, 2}, [58] = {350, 2}, [59] = {351, 2}, [60] = {353, 2}, [61] = {354, 2}, [62] = {355, 2}, [63] = {356, 2}, [64] = {360, 2}, [65] = {364, 2}},
[11] = { [1] = {288, 3}, [2] = {289, 3}, [3] = {290, 3}, [4] = {291, 3}, [5] = {341, 3}, [6] = {364, 2}},
[12] = { [1] = {30, 3}, [2] = {31, 3}, [3] = {32, 3}, [4] = {33, 3}, [5] = {85, 3}, [6] = {86, 3}, [7] = {113, 2}, [8] = {114, 2}, [9] = {115, 2}, [10] = {116, 2}, [11] = {120, 3}, [12] = {121, 3}, [13] = {132, 3}, [14] = {133, 3}, [15] = {134, 3}, [16] = {255, 2}, [17] = {258, 1}, [18] = {259, 1}, [19] = {260, 1}, [20] = {261, 1}, [21] = {267, 2}, [22] = {268, 2}, [23] = {270, 2}, [24] = {271, 2}, [25] = {272, 2}, [26] = {274, 2}, [27] = {275, 2}, [28] = {276, 2}, [29] = {277, 2}, [30] = {341, 2}, [31] = {364, 2}},
[13] = { [1] = {231, 3}, [2] = {232, 3}, [3] = {233, 3}, [4] = {234, 3}, [5] = {245, 1}, [6] = {246, 2}, [7] = {247, 1}, [8] = {250, 2}, [9] = {251, 2}, [10] = {252, 2}, [11] = {253, 1}, [12] = {285, 2}, [13] = {306, 1}, [14] = {341, 2}, [15] = {364, 2}},
[14] = { [1] = {30, 3}, [2] = {31, 3}, [3] = {32, 3}, [4] = {33, 3}, [5] = {37, 2}, [6] = {38, 2}, [7] = {39, 2}, [8] = {40, 2}, [9] = {44, 1}, [10] = {45, 1}, [11] = {46, 1}, [12] = {47, 1}, [13] = {79, 3}, [14] = {80, 3}, [15] = {82, 3}, [16] = {83, 3}, [17] = {95, 3}, [18] = {100, 3}, [19] = {101, 3}, [20] = {106, 3}, [21] = {113, 1}, [22] = {114, 2}, [23] = {115, 2}, [24] = {116, 2}, [25] = {124, 3}, [26] = {125, 3}, [27] = {126, 3}, [28] = {130, 3}, [29] = {131, 3}, [30] = {135, 3}, [31] = {145, 3}, [32] = {146, 3}, [33] = {148, 3}, [34] = {156, 3}, [35] = {157, 3}, [36] = {192, 2}, [37] = {193, 1}, [38] = {202, 3}, [39] = {206, 2}, [40] = {255, 2}, [41] = {256, 2}, [42] = {257, 2}, [43] = {258, 2}, [44] = {262, 2}, [45] = {263, 2}, [46] = {264, 2}, [47] = {265, 2}, [48] = {270, 1}, [49] = {277, 1}, [50] = {278, 1}, [51] = {279, 1}, [52] = {283, 1}, [53] = {284, 1}, [54] = {294, 1}, [55] = {295, 1}, [56] = {296, 1}, [57] = {297, 1}, [58] = {318, 1}, [59] = {341, 2}, [60] = {364, 2}},
[15] = { [1] = {147, 1}, [2] = {199, 2}, [3] = {200, 2}, [4] = {221, 2}, [5] = {264, 1}, [6] = {282, 1}, [7] = {283, 2}, [8] = {284, 2}, [9] = {285, 2}, [10] = {290, 2}, [11] = {316, 1}},
[16] = { [1] = {30, 3}, [2] = {31, 3}, [3] = {32, 3}, [4] = {33, 3}, [5] = {77, 3}, [6] = {78, 3}, [7] = {79, 3}, [8] = {80, 3}, [9] = {85, 3}, [10] = {89, 3}, [11] = {90, 3}, [12] = {93, 3}, [13] = {94, 3}, [14] = {104, 3}, [15] = {105, 3}, [16] = {109, 3}, [17] = {110, 3}, [18] = {113, 3}, [19] = {114, 3}, [20] = {115, 3}, [21] = {119, 1}, [22] = {120, 1}, [23] = {123, 3}, [24] = {129, 1}, [25] = {143, 3}, [26] = {156, 3}, [27] = {206, 2}, [28] = {212, 3}, [29] = {219, 3}, [30] = {220, 3}, [31] = {222, 3}, [32] = {225, 2}, [33] = {256, 1}, [34] = {257, 2}, [35] = {258, 2}, [36] = {259, 2}, [37] = {267, 1}, [38] = {268, 1}, [39] = {284, 1}, [40] = {285, 2}, [41] = {315, 2}, [42] = {341, 3}, [43] = {351, 1}, [44] = {352, 1}, [45] = {353, 1}, [46] = {354, 1}, [47] = {359, 2}, [48] = {364, 2}},
[17] = { [1] = {31, 3}, [2] = {32, 3}, [3] = {33, 3}, [4] = {34, 3}, [5] = {37, 1}, [6] = {38, 1}, [7] = {44, 2}, [8] = {45, 3}, [9] = {46, 3}, [10] = {47, 3}, [11] = {112, 3}, [12] = {113, 3}, [13] = {114, 3}, [14] = {115, 3}, [15] = {139, 1}, [16] = {140, 1}, [17] = {141, 1}, [18] = {142, 1}, [19] = {146, 1}, [20] = {147, 1}, [21] = {148, 1}, [22] = {149, 1}, [23] = {234, 2}, [24] = {255, 1}, [25] = {259, 2}, [26] = {260, 2}, [27] = {261, 1}, [28] = {262, 1}, [29] = {285, 2}, [30] = {294, 1}, [31] = {295, 1}, [32] = {296, 1}, [33] = {297, 1}, [34] = {341, 3}, [35] = {342, 2}, [36] = {346, 2}, [37] = {352, 2}, [38] = {353, 2}, [39] = {354, 2}, [40] = {355, 2}, [41] = {358, 2}, [42] = {359, 2}, [43] = {360, 2}, [44] = {361, 2}, [45] = {364, 2}},
[18] = { [1] = {31, 3}, [2] = {32, 3}, [3] = {33, 3}, [4] = {34, 3}, [5] = {37, 1}, [6] = {38, 1}, [7] = {44, 2}, [8] = {45, 3}, [9] = {46, 3}, [10] = {47, 3}, [11] = {112, 3}, [12] = {113, 3}, [13] = {114, 3}, [14] = {115, 3}, [15] = {139, 1}, [16] = {140, 1}, [17] = {141, 1}, [18] = {142, 1}, [19] = {146, 1}, [20] = {147, 1}, [21] = {148, 1}, [22] = {149, 1}, [23] = {234, 2}, [24] = {255, 1}, [25] = {259, 2}, [26] = {260, 2}, [27] = {261, 1}, [28] = {262, 1}, [29] = {285, 2}, [30] = {294, 1}, [31] = {295, 1}, [32] = {296, 1}, [33] = {297, 1}, [34] = {341, 3}, [35] = {342, 2}, [36] = {346, 2}, [37] = {352, 2}, [38] = {353, 2}, [39] = {354, 2}, [40] = {355, 2}, [41] = {358, 2}, [42] = {359, 2}, [43] = {360, 2}, [44] = {361, 2}, [45] = {364, 2}},
[19] = {},
[20] = { [1] = {31, 2}, [2] = {32, 2}, [3] = {33, 2}, [4] = {34, 2}, [5] = {36, 2}, [6] = {37, 2}, [7] = {38, 2}, [8] = {39, 2}, [9] = {41, 2}, [10] = {49, 1}, [11] = {92, 2}, [12] = {179, 2}, [13] = {206, 2}, [14] = {213, 2}, [15] = {285, 2}, [16] = {341, 2}, [17] = {358, 2}, [18] = {364, 2}},
[21] = { [1] = {228, 2}, [2] = {229, 2}, [3] = {230, 2}, [4] = {231, 2}, [5] = {233, 2}, [6] = {234, 2}, [7] = {240, 2}, [8] = {241, 2}, [9] = {247, 2}, [10] = {248, 2}, [11] = {260, 1}, [12] = {266, 1}, [13] = {267, 1}, [14] = {268, 1}, [15] = {269, 1}, [16] = {285, 1}, [17] = {286, 1}, [18] = {287, 1}, [19] = {297, 1}, [20] = {298, 1}, [21] = {299, 1}, [22] = {355, 1}, [23] = {356, 1}, [24] = {357, 1}},
[22] = {},
[23] = { [1] = {267, 2}, [2] = {268, 3}, [3] = {269, 2}, [4] = {270, 3}, [5] = {274, 2}, [6] = {275, 3}, [7] = {276, 3}, [8] = {277, 3}, [9] = {280, 2}, [10] = {281, 2}, [11] = {282, 3}, [12] = {283, 2}, [13] = {285, 3}, [14] = {286, 3}, [15] = {288, 3}, [16] = {289, 2}, [17] = {290, 3}, [18] = {291, 2}, [19] = {295, 2}, [20] = {296, 2}, [21] = {298, 2}, [22] = {302, 1}, [23] = {303, 1}},
[24] = { [1] = {179, 3}, [2] = {180, 3}, [3] = {181, 3}, [4] = {182, 3}, [5] = {188, 1}, [6] = {206, 3}, [7] = {211, 2}, [8] = {217, 2}, [9] = {218, 2}, [10] = {219, 2}, [11] = {220, 2}, [12] = {224, 2}, [13] = {227, 3}, [14] = {228, 3}, [15] = {229, 3}, [16] = {230, 3}, [17] = {235, 3}, [18] = {236, 3}, [19] = {237, 3}, [20] = {238, 3}, [21] = {244, 1}, [22] = {255, 1}, [23] = {256, 1}, [24] = {257, 1}, [25] = {258, 1}, [26] = {275, 2}, [27] = {300, 2}, [28] = {308, 1}, [29] = {309, 1}, [30] = {310, 1}, [31] = {354, 1}, [32] = {355, 1}, [33] = {363, 2}},
[25] = { [1] = {208, 2}, [2] = {209, 2}, [3] = {210, 2}, [4] = {211, 2}, [5] = {215, 2}, [6] = {216, 2}, [7] = {217, 2}, [8] = {218, 1}, [9] = {223, 1}, [10] = {362, 1}, [11] = {363, 1}},
[26] = { [1] = {142, 2}, [2] = {143, 2}, [3] = {144, 2}, [4] = {145, 1}, [5] = {150, 1}, [6] = {151, 1}, [7] = {152, 1}, [8] = {158, 1}, [9] = {159, 1}, [10] = {160, 1}, [11] = {161, 1}, [12] = {183, 3}, [13] = {184, 3}, [14] = {185, 3}, [15] = {186, 3}, [16] = {195, 3}, [17] = {196, 3}, [18] = {197, 3}, [19] = {198, 3}, [20] = {203, 1}, [21] = {208, 1}, [22] = {209, 2}, [23] = {210, 2}, [24] = {211, 1}, [25] = {219, 2}, [26] = {220, 2}, [27] = {221, 2}, [28] = {222, 2}, [29] = {225, 2}, [30] = {226, 2}, [31] = {227, 2}, [32] = {228, 2}, [33] = {270, 1}, [34] = {271, 1}, [35] = {272, 1}, [36] = {273, 1}, [37] = {276, 2}, [38] = {278, 2}, [39] = {279, 3}, [40] = {280, 3}, [41] = {281, 3}, [42] = {301, 1}, [43] = {302, 2}, [44] = {303, 1}, [45] = {345, 2}, [46] = {354, 2}, [47] = {360, 2}, [48] = {361, 2}}
}

local zz = 0

for line in io.lines(filePath) do
	local tokens = {}
	local index = 0
	for token in string.gmatch(line,"[_.%w]+") do
		index = index + 1
		tokens[index] = token
	end

	if(tokens[2] == "1d") then

		zz = zz + 1

		if(zz >= 0 and zz <= 30) then

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

			local result = calculate_fdi(0, 86400, graph)

			--[[for key,value in pairs(result) do
				print(key)
				print(value[1])
				print(value[2])
				print(value[3])
		  end]]

			local tdind = 0
			for key,value in pairs(result) do
				if(value[2]) then
						local td = key-1
						tdind = tdind + 1
						assert(matlab[zz][tdind][1] == td, string.format('failed test alarm: signal num = %d, alert num = %d, got %d instead of %d', zz, tdind, td, matlab[zz][tdind][1]))
						assert(matlab[zz][tdind][2] == value[3], string.format('failed test level: signal num = %d, alert num = %d, got %d instead of %d', zz, tdind, value[3], matlab[zz][tdind][2]))
				end
			end
		  assert(tdind == table.getn(matlab[zz]), string.format('failed test: signal num = %d, entries num = %d, expected = %d',zz, tdind, table.getn(matlab[zz])))
		end
	end
end
