require 'fdi/dailyAlg'
require 'fdi/hourlyAlg'
require 'helpers'

-- costants
local DAY_INTERVAL = 86400
local HOUR_INTERVAL = 3600

function calculate_fdi(epoh_time_, interval_, graph_)

  -- prepare time and value series
  local size = #graph_

  local min = 2000000000
  local max = 0
  for _,v in ipairs(graph_) do
    local t = v[3]
    if(t > max) then max = t end
    if((t < min) and (t > 1357344000)) then min = t end
  end

  local range = 1 + (max - min) / interval_

  local times = {}
  local values = {}

  for ii=1,range do
    times[ii] = min + interval_ * (ii-1)
    values[ii] = 0
  end

  for _,v in ipairs(graph_) do
    local ind = (v[3] - min) / interval_
    if(ind >= 0) then
      values[ind+1] = v[1]
    end
  end

  -- run days algorithm
	if interval_==DAY_INTERVAL then
		return calculate_fdi_days(times, values)
  elseif interval_==HOUR_INTERVAL then
	  return calculate_fdi_hours(times, values)
  else
	  logw('calculate_fdi - current version supports only 86400 (day) or 3600 (hour) intervals')
    return nil
  end

end
