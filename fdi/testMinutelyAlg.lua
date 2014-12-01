require 'calculate_fdi'

local filePath = './fdi/fixtures/graphs_of_interest.txt'
--local filePath = './fixtures/graphs_of_interest.txt'

local matlab = {
[1] = { [1] = {1611, 3}, [2] = {1633, 3}, [3] = {1738, 2}, [4] = {1812, 3}, [5] = {1823, 3}, [6] = {1936, 2}, [7] = {1952, 2}, [8] = {2017, 3}, [9] = {2024, 3}, [10] = {2025, 3}, [11] = {2027, 2}, [12] = {2053, 3}, [13] = {2107, 3}, [14] = {2119, 3}, [15] = {2120, 3}, [16] = {2171, 3}, [17] = {2288, 3}, [18] = {2313, 2}, [19] = {2374, 2}, [20] = {2375, 3}, [21] = {2394, 3}},
[2] = { [1] = {1624, 2}, [2] = {1625, 2}},
[3] = { [1] = {1823, 2}, [2] = {1959, 1}, [3] = {2004, 2}, [4] = {2009, 1}, [5] = {2012, 1}},
[4] = { [1] = {1965, 2}, [2] = {2394, 2}},
[5] = { [1] = {1730, 2}, [2] = {1731, 2}, [3] = {2017, 2}, [4] = {2020, 1}, [5] = {2021, 2}, [6] = {2022, 1}, [7] = {2023, 2}, [8] = {2305, 2}, [9] = {2306, 2}, [10] = {2307, 2}, [11] = {2310, 1}},
[6] = { [1] = {1730, 2}, [2] = {1731, 1}, [3] = {1734, 1}, [4] = {1771, 1}, [5] = {1772, 1}, [6] = {1773, 1}, [7] = {1823, 2}, [8] = {2006, 1}, [9] = {2066, 1}, [10] = {2305, 2}, [11] = {2310, 1}},
[7] = { [1] = {1729, 1}, [2] = {1730, 1}, [3] = {1956, 2}, [4] = {1957, 2}, [5] = {1958, 2}, [6] = {1959, 2}, [7] = {2004, 2}, [8] = {2005, 2}, [9] = {2006, 2}, [10] = {2017, 1}, [11] = {2065, 1}, [12] = {2305, 1}, [13] = {2306, 1}},
[8] = { [1] = {1531, 3}, [2] = {1532, 3}, [3] = {1533, 3}, [4] = {1534, 3}, [5] = {1536, 2}, [6] = {1540, 3}, [7] = {1541, 3}, [8] = {1542, 3}, [9] = {1543, 3}, [10] = {1823, 2}, [11] = {2046, 2}},
[9] = {},
[10] = { [1] = {1530, 2}, [2] = {1531, 2}, [3] = {1532, 3}, [4] = {1533, 3}, [5] = {1535, 2}, [6] = {1536, 2}, [7] = {1538, 2}, [8] = {1539, 2}, [9] = {1541, 2}, [10] = {1542, 2}, [11] = {1544, 2}, [12] = {1545, 2}, [13] = {1547, 2}, [14] = {1550, 2}, [15] = {1553, 2}, [16] = {1555, 2}, [17] = {1556, 2}},
[11] = {},
[12] = { [1] = {2332, 2}},
[13] = { [1] = {1824, 2}},
[14] = { [1] = {2219, 2}}
}

local zz = 0

for line in io.lines(filePath) do
	local tokens = {}
	local index = 0
	for token in string.gmatch(line,"[_.%w]+") do
		index = index + 1
		tokens[index] = token
	end

	if(tokens[2] == "5m") then

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

			local result = calculate_fdi(0, 300, graph)

			local tdind = 0
			for key,value in pairs(result) do
				if(value[2]) then
						local td = (value[1] - (1357344000 + 72 * 7 * 86400)) / 300
						tdind = tdind + 1
						assert(matlab[zz][tdind][1] == td, string.format('failed test alarm: signal num = %d, alert num = %d, got %d instead of %d', zz, tdind, td, matlab[zz][tdind][1]))
						assert(matlab[zz][tdind][2] == value[3], string.format('failed test level: signal num = %d, alert num = %d, got %d instead of %d', zz, tdind, value[3], matlab[zz][tdind][2]))
				end
			end
      assert(tdind == table.getn(matlab[zz]), string.format('failed test: signal num = %d, entries num = %d, expected = %d',zz, tdind, table.getn(matlab[zz])))
		end
	end
end





