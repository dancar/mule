-- file/stdout logging
local logfile = nil
local logfile_name = nil
local verbose_logging = false
local logfile_rotation_time = nil

function verbose_log(on_)
  verbose_logging = on_
end

local function rotate_log_file(name)
  if logfile then
	logfile:flush()
	logfile:close()
  end
  name = name or logfile_name

  if not name then return nil end

  local f = io.open(name,"a")
  if not f then
	io.stderr:write(name,"\n")
	return nil, string.format("can't open `%s' for writing",name)
  end
  f:setvbuf ("line")
  logfile = f
  logfile_name = name
  logfile_rotation_time = os.time()
end

function log_file(path_)
  local name = string.find(path_,"%.log$") and path_ or string.format("%s.log",path_)
  rotate_log_file(name)
end

local function flog(level,...)
  -- we close and open the file every 60 seconds to facilitate log rotation
  if not logfile_rotation_time or os.time()-logfile_rotation_time>60 then
	rotate_log_file()
  end

  local sarg = {os.date("%y%m%d:%H:%M:%S"),level," "}
  table.foreachi(arg,function(_,v) table.insert(sarg,tostring(v)) end)
  local msg = table.concat(sarg," ")
  if verbose_logging then
	io.stderr:write(msg,"\n")
  end
  if logfile then
	logfile:write(msg,"\n")
  end
  return true
end

function close_log_file()
  if logfile then
	logfile:close()
	logfile = nil
  end
end


function logd(...)
  return ((logfile or verbose_logging) and flog("d",...))
end

function logi(...)
  return ((logfile or verbose_logging) and flog("i",...))
end

function logw(...)
  return ((logfile or verbose_logging) and flog("w",...))
end

function loge(...)
  return ((logfile or verbose_logging) and flog("e",...))
end

function logf(...)
  return ((logfile or verbose_logging) and flog("f",...))
end


local function nop() 
end

function tableout(tbl_)
  local function write(o_)
	table.insert(tbl_,o_)
  end
  


  return {
	write_string = write,
	write_timestamp = write,
	write_number = write,
	start_of_header = nop,
	end_of_header = nop,
	start_of_record = nop,
	end_of_record = nop,
  }

end

function tablein(tbl_)
  local current = 0

  local function read()
	current = current + 1
	return tbl_[current]
  end
  
  return {
	read_string = read,
	read_timestamp = read,
	read_number = read,
  }

end

function ioout_generic(writer_,delim_)
  local function write(o_)
	writer_(tostring(o_))
	writer_(delim_)
  end
  
  local function endof()
	writer_("\n")
  end

  return {
	write_string = write,
	write_timestamp = write,
	write_number = write,
	start_of_header = nop,
	end_of_header = endof,
	start_of_record = nop,
	end_of_record = endof
  }


end

function ioout(io_,delim_)
  return ioout_generic(function(o_)
						 io_:write(o_)
					   end,delim_)
end

function stdout(delim_)
  return ioout(io.output(),delim_)
end

function ioin_generic(lines_itr_,delim_)
  local read = coroutine.wrap(function()								
								for l in lines_itr_() do
								  for p in split_helper(l,delim_) do
									-- as our arrays write the delimiter after every
									-- item, we have to skip the last, empty, one
									if #p~=0 then
									  coroutine.yield(p)
									end
								  end
								end
							  end)
  
  
  return {
	read_string = read,
	read_timestamp = function() return tonumber(read()) end,
	read_number = function() return tonumber(read()) end,
  }


end

function ioin(io_,delim_)
  return ioin_generic(io_.lines,delim_)
end

function strout(delim_)
  local str = {}
  local out = ioout_generic(function(o_)
							  table.insert(str,o_)
							end,delim_ or ",")
  out.get_string = function()
					 return table.concat(str,"")
				   end
  return out
end


function strin(str_)
  return ioin_generic(function() return string_lines(str_) end,",")
end

function jsonout(as_hash_)
  local str = {}
  local first_header = true
  local record_started = false
  local insert = table.insert


  local function push(item_)
	insert(str,item_)
  end
  
  local function write_object(o_)
	if not record_started then
	  push("[")
	  record_started = true
	end
	
	push(o_)
	push(",")
  end

  return {
	write_string = function(o_)
					 if not first_header then
					   if as_hash_ then push("]") end
					   push(",\n")
					 else
					   if as_hash_ then 
						 push("{\n") 
					   else
						 push("[") 
					   end
					 end
					 push(string.format("\"%s\"",tostring(o_)))
				   end,
	write_timestamp = write_object,
	write_number = write_object,
	start_of_header = nop,
	end_of_header = function()
					  if as_hash_ then 
						push(":[") 
					  end
					  first_header = false
					end,
	start_of_record = nop,
	end_of_record = function()
					  push("],")
					  record_started = false
					end,
	close = function()
			  if #str>0 then
				push("]")
				if as_hash_ then 
				  push("\n}")
				end
			  end
			end,
	get_string = function()
				   return table.concat(str,"")
				 end
  }


end

function trim(str)
  if not str then return nil end
  local _,_,s = string.find(str,"^%s*(.-)%s*$")
  return s or ""
end


function ipairs_iterator(array_)
  return function() return ipairs(array_) end
end


function shallow_clone_array(array_)
  local cloned = {}
  for i,a in ipairs(array_) do
	cloned[i] = a
  end
  return cloned
end

function split_helper(str_,delim_)
  return coroutine.wrap(function()
						  local start = 1
						  local t,s
						  local items = {}
						  local ds = #delim_
						  local find,sub = string.find,string.sub
						  local yield = coroutine.yield
						  while str_ and start do
							t = find(str_,delim_,start,true)
							if t then
							  yield(trim(sub(str_,start,t-1)))
							  start = t+ds
							else
							  yield(trim(sub(str_,start)))
							  start = nil
							end
						  end
						end)
end

function split(str_,delim_)
  local items = {}
  for p in split_helper(str_,delim_) do
	if #p>0 then 
	  items[#items+1] = p
	end
  end
  return items
end

function string_lines(str_)
  return split_helper(str_,"\n")
end


function remove_comment(line_)
  local hash = string.find(line_,"#",1,true) 
  
  return trim(hash and string.sub(line_,1,hash-1) or line_)
end

function lines_without_comments(lines_iterator)
  return coroutine.wrap(function()
						  for line in lines_iterator do
							line = remove_comment(line)						
							if #line>0 then coroutine.yield(line) end
						  end
						end)
end

function concat_arrays(lhs_,rhs_,callback_)
  for _,v in ipairs(rhs_) do
	lhs_[#lhs_+1] = callback_ and callback_(v) or v
  end
  return lhs_
end


function t2s(tbl)
  if not tbl then
    return
  end
  if type(tbl)~='table' then return tostring(tbl) end
  local rep = {}
  table.foreach(tbl,function (key,val) 
					  if type(val)=='table' then
						table.insert(rep,string.format('"%s":{%s}',key,t2s(val))) 
					  else
						table.insert(rep,string.format('"%s":"%s"',key,t2s(val))) 
					  end
					end)

  return table.concat(rep,',')
end

function table_size(tbl_)
  if #tbl_>0 then return #tbl_ end
  local current = 0
  for k,v in pairs(tbl_) do
	current = current + 1
  end

  return current
end


function serialize_table_of_arrays(out_,tbl_,callback_)
  out_.write_number(table_size(tbl_))
  for key,items in pairs(tbl_) do
	out_.write_string(key)
	out_.write_number(#items)
	for _,i in ipairs(items) do
	  callback_(out_,i)
	end
  end
end


function deserialize_table_of_arrays(in_,callback_)
  local size = in_.read_number()
  local tbl = {}
  for i=1,size do
	local key = in_.read_string()
	local num_items = in_.read_number()
	local items = {}
	for j=1,num_items do
	  items[#items+1] = callback_(in_)
	end
	tbl[key] = items
  end
  return tbl
end


function with_file(file_,func_)
  local f = io.open(file_,"r")
  if not f then return false end
  func_(f)
  f:close()
  return true
end

function file_exists(file_)
  return with_file(file_,function() end)
end

-- based on http://lua-users.org/wiki/AlternativeGetOpt
-- with slight modification - non '-' prefixed args are accumulated under the "rest" key
function getopt( arg, options )
  local tab = {}
  tab["rest"] = {}
  local prev_in_options = false

  for k, v in ipairs(arg) do
	if string.sub( v, 1, 2) == "--" then
	  local x = string.find( v, "=", 1, true )
	  if x then tab[ string.sub( v, 3, x-1 ) ] = string.sub( v, x+1 )
	  else      tab[ string.sub( v, 3 ) ] = true
	  end
	  prev_in_options = false
	elseif string.sub( v, 1, 1 ) == "-" then
	  local y = 2
	  local l = string.len(v)
	  local jopt
	  while ( y <= l ) do
		jopt = string.sub( v, y, y )
		if string.find( options, jopt, 1, true ) then
		  prev_in_options = true
		  if y < l then
			tab[ jopt ] = string.sub( v, y+1 )
			y = l
		  else
			tab[ jopt ] = arg[ k + 1 ]
		  end
		else
		  tab[ jopt ] = true
		end
		y = y + 1
	  end
	else
	  if not prev_in_options then
		table.insert(tab["rest"],v)
	  end
	  prev_in_options = false
	end
  end
  return tab
end

function copy_table(from_,to_)
  if from_ then
	local key,val = next(from_)
	while key and val do
      to_[key] = val
	  key,val = next(from_,key)
    end
  end
  return to_
end

local TIME_UNITS = {s=1, m=60, h=3600, d=3600*24, w=3600*24*7, y=3600*24*365}
local TIME_UNITS_SORTED = (function() 
							 local array = {}
							 for u,f in pairs(TIME_UNITS) do
							   table.insert(array,{f,u})
							 end
							 table.sort(array,function(a,b)
												return a[1]>b[1]
											  end)
							 return array
						   end)()



function parse_time_unit(str_)
  local secs = nil
  if str_ then
	str_.gsub(str_,"^(%d+)([smhdwy])$",function(num,unit)
									   secs = num*TIME_UNITS[unit]
									 end)
	secs = secs or tonumber(str_) or 0
  end
  return secs
end

local secs_to_time_unit_cache = {}
function secs_to_time_unit(secs_)
  if secs_to_time_unit_cache[secs_] then
	return secs_to_time_unit_cache[secs_]
  end
  local fmod = math.fmod
  for _,v in pairs(TIME_UNITS_SORTED) do
	if secs_>=v[1] and fmod(secs_,v[1])==0 then
	  local rv = (secs_/v[1])..v[2]
	  secs_to_time_unit_cache[secs_] = rv
	  return rv
	end
  end

  return nil
end


function max_timestamp(size_,get_slot_)
  local max = nil
  local idx = 0
  for i=1,size_ do
	local current = get_slot_(i)
	if not max or current._timestamp>max._timestamp then
	  max = current
	  idx = i
	end
  end
  return idx
end

function is_matching(metric_,pattern_)
  return pattern_=="*" or string.find(metric_,pattern_,1,true)==1
end

function parse_time_pair(str_)
  local step,period = string.match(str_,"^(%w+):(%w+)$")
  return parse_time_unit(step),parse_time_unit(period)
end

function calculate_slot(timestamp_,step_,period_)
  local slot = math.floor((timestamp_ % period_) / step_)
  -- adjust the slot it to 1-based arrays
  -- adjust the timestamp so it'll be at the beginning of the step
  return slot+1,math.floor(timestamp_/step_)*step_  
end

function to_timestamp(expr_,now_,latest_)
  local interpolated = string.gsub(expr_,"(%l+)",{now=now_, latest=latest_})
  interpolated = string.gsub(interpolated,"(%w+)",parse_time_unit)
  return string.match(interpolated,"^[%s%d%-%+]+$") and loadstring("return "..interpolated)() or nil
end
