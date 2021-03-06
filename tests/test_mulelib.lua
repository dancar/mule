require "tests.strict"
local lunit = require "lunit"
if _VERSION >= 'Lua 5.2' then
    _ENV = lunit.module('test_mulelib','seeall')
else
  module( "test_mulelib", lunit.testcase, package.seeall )
end

require "mulelib"

pcall(require, "profiler")
require "memory_store"
local cdb = require "column_db"
local mdb = require "lightning_mdb"
local p = require "purepack"
require "indexer"

local function indexer_factory(name_)
  if not name_ then
    return indexer()
  end
  local full_path = "./tests/temp/"..name_
  if not directory_exists(full_path) then
    os.execute("mkdir -p "..full_path)
  end
  return indexer(full_path.."/fts.sqlite3")
end

local function column_db_factory(name_)
  p.set_pack_lib("bits")
  local dir = create_test_directory(name_.."_cdb")
  return cdb.column_db(dir)
end


local function lightning_db_factory(name_)
  p.set_pack_lib("bits")
  local dir = create_test_directory(name_.."_mdb")
  return mdb.lightning_mdb(dir)
end

local function memory_db_factory(name_)
  p.set_pack_lib("purepack")
  return in_memory_db()
end

local function for_each_db(name_,func_)
  local dbs = {
    memory_db_factory(),
    lightning_db_factory(name_),
    --column_db_factory(name_)
  }

  local ind = indexer_factory()
  for _,db in ipairs(dbs) do
    func_(mule(db,ind),db)
    set_hard_coded_time(nil)
  end
end

local function insert_all_args(tbl_)
  return function(...)
    for _,v in ipairs({...}) do
      table.insert(tbl_,v)
    end
         end
end

function test_parse_time_unit()
  local tests = {
    {0,""},
    {0,"1sd"},
    {0,"d"},
    {0," 1s"},
    {0,"1s_"},
    {1,"1s"},
    {1,"1"},
    {60,"1m"}, -- minute
    {2*3600*24,"2d"},
    {7*3600*24*365,"7y"},
    {3600,"3600"},
  }
  for i,v in ipairs(tests) do
    assert_equal(v[1],parse_time_unit(v[2]),i)
  end


  tests = {
    {7*3600*24*365,"7y"},
    {60,"1m"},
    {2*3600*24,"2d"},
    {7*3600*24,"1w"},
    {14*3600*24,"2w"},
  }

  for i,v in ipairs(tests) do
    assert_equal(v[2],secs_to_time_unit(v[1]),i)
  end
end


function test_string_lines()
  local str = "hello\ncruel\nworld"
  local lines = {}
  for i in string_lines(str) do
    table.insert(lines,i)
  end

  assert_equal(lines[1],"hello")
  assert_equal(lines[2],"cruel")
  assert_equal(lines[3],"world")

end

function test_calculate_idx()
  local tests = {
    -- {step,period,timestamp,slot,adjust}
    {1,60,0,0,0},
    {1,60,60,0,60},
    {2,60,61,0,60},
    {2,60,121,0,120},
    {2,60,121,0,120},
    {2,60,123,1,122},
    {300,2*24*60*60,1293836375,275,1293836100}
  }

  for i,t in ipairs(tests) do
    local slot,adjusted = calculate_idx(t[3],t[1],t[2])
    assert_equal(t[4],slot,i)
    assert_equal(t[5],adjusted,i)
  end
end


function test_sequences()
  function helper(_,db_)
    local step,period = parse_time_pair("1m:60m")
    assert_equal(60,step)
    assert_equal(3600,period)
    db_.set_increment(function() end)
    db_._zero_sum_latest = simple_cache(MAX_CACHE_SIZE)
    local seq = sequence(db_,"seq;1m:60m")
    assert_equal(0,seq.slot_index(0))
    assert_equal(0,seq.slot_index(59))
    assert_equal(1,seq.slot_index(60))
    assert_equal(5,seq.slot_index(359))
    assert_equal(6,seq.slot_index(360))

    seq.update(0,1,10)
    assert_equal(10,seq.slot(0)._sum)
    assert_equal(10,seq.slot(seq.latest_slot_index())._sum)
    seq.update(1,1,17)
    assert_equal(27,seq.slot(0)._sum)
    assert_equal(2,seq.slot(0)._hits)
    assert_equal(27,seq.slot(seq.latest_slot_index())._sum)
    seq.update(3660,1,3)
    assert_equal(3,seq.slot(1)._sum)
    assert_equal(3,seq.slot(seq.latest_slot_index())._sum)
    seq.update(60,1,7) -- this is in the past and should be discarded
    assert_equal(3,seq.slot(1)._sum)
    assert_equal(1,seq.slot(1)._hits)
    assert_equal(3,seq.slot(seq.latest_slot_index())._sum)
    seq.update(7260,1,89)
    assert_equal(89,seq.slot(1)._sum)
    assert_equal(1,seq.slot(1)._hits)
    assert_equal(89,seq.slot(seq.latest_slot_index())._sum)

    --seq.serialize(stdout(", "))
    local tbl = {}
    seq.serialize({all_slots=true},insert_all_args(tbl),insert_all_args(tbl))
    assert_equal("seq",tbl[1])
    assert_equal(60,tbl[2]) --
    assert_equal(3600,tbl[3]) -- period

    -- first slot
    assert_equal(27,tbl[4])
    assert_equal(2,tbl[5])
    assert_equal(0,tbl[6])
    -- second slot
    assert_equal(89,tbl[7])
    assert_equal(1,tbl[8])
    assert_equal(7260,tbl[9])
    -- third slot
    assert_equal(0,tbl[10])
    assert_equal(0,tbl[11])
    assert_equal(0,tbl[12])

--[[
      local seq1 = sequence(db_,"seq")
      local tblin = tablein(tbl)
      local function read_3_values()
      return tblin.read(),tblin.read(),tblin.read()
      end

      assert_equal("seq",seq1.deserialize(in_memory_db,true,read_3_values,read_3_values))
--]]

    local tbl1 = {}
    seq.serialize({all_slots=true},insert_all_args(tbl1),insert_all_args(tbl1))
    for i,v in ipairs(tbl) do
      assert_equal(v,tbl1[i],i)
    end

    seq.update(10799,1,43)
    assert_equal(43,seq.slot(59)._sum)
    assert_equal(1,seq.slot(59)._hits)

    seq.update(10800,1,99)
    assert_equal(99,seq.slot(0)._sum)
    assert_equal(1,seq.slot(0)._hits)

    tbl = {}
    seq.serialize({sorted=true,all_slots=true},insert_all_args(tbl),insert_all_args(tbl))

    assert_equal("seq",tbl[1])
    assert_equal(60,tbl[2])
    assert_equal(3600,tbl[3]) -- period

    -- last slot
    local last = 183
    assert_equal(99,tbl[last-2])
    assert_equal(1,tbl[last-1])
    assert_equal(10800,tbl[last-0])
    -- one before last slot
    assert_equal(43,tbl[last-5])
    assert_equal(1,tbl[last-4])
    assert_equal(10740,tbl[last-3])

  end
  for_each_db("test_sequences",helper)
end

function test_to_timestamp()
  local tests = {
    -- {expr_,now,latest,expected}
    {"1",60,0,1},
    {"1+2",60,10,3},
    {"print(1+2)",60,10,nil},
    {"now+2",60,10,62},
    {"latest-7",60,10,3},
    {"latest-1m",60,120,60},
    {"now + latest - 1m",61,121,122},
    {"1..",60,0,nil},
    {"1..2",60,0,{1,2}},
    {"31..2",60,0,{31,2}},
    {"now + latest - 1m..1",61,121,{122,1}},
    {"latest-1m..latest-1m",60,120,{60,60}},
    {"now-10000..now",1430216100,1430215500,{1430206100,1430216100}},
  }

  for i,t in ipairs(tests) do
    local ts = to_timestamp(t[1],t[2],t[3])
    if ts and type(t[4])=="table" then
      assert_equal(t[4][1],ts[1],i)
      assert_equal(t[4][2],ts[2],i)
    else
      assert_equal(t[4],ts,i)
    end
  end

end


local function table_itr(tbl_)
  local current = 0
  return function()
    current = current + 1
    return tbl_[current]
         end
end

function test_remove_comment()
  assert_equal("",remove_comment(""))
  assert_equal("",remove_comment("# hello"))
  assert_equal("",remove_comment("    # hello"))
  assert_equal("",remove_comment("    # hello"))
  assert_equal("hello cruel",remove_comment("hello cruel #world"))
  assert_equal("hello cruel",remove_comment("	hello cruel #world"))
  assert_equal("hello cruel",remove_comment("  hello cruel #world"))
end

function test_parse_input_line()
  local items = parse_input_line("beer.ale 60S:12H 1H:30d")
  assert_equal(3,#items)
  assert_equal("beer.ale",items[1])
end

function test_factories()
  local function helper(m)
    m.configure(table_itr({"beer.ale 60s:12h 1h:30d","beer.ale 60s:24h"}))

    assert_equal(3,#m.get_factories()["beer.ale"].rps)
    local factories = m.get_factories()
    assert(factories["beer.ale"])
    assert_equal(0,#m.matching_sequences("beer.ale"))
    assert_equal(0,#m.matching_sequences("beer.ale.brown.newcastle"))

    m.process("beer.ale.brown.newcastle 20 74857843")
    assert_equal(9,#m.matching_sequences("beer.ale"))
    assert_equal(6,#m.matching_sequences("beer.ale.brown"))
    assert_equal(3,#m.matching_sequences("beer.ale.brown.newcastle"))
    assert_equal(0,#m.matching_sequences("beer.ale.pale"))

    m.process("beer.ale.belgian.trappist 70 56920123")
    assert_equal(15,#m.matching_sequences("beer.ale"))

    m.process("beer.ale.belgian.trappist 99 62910121")
    assert_equal(15,#m.matching_sequences("beer.ale"))
  end
  for_each_db("test_factories",helper)
end

function test_modify_more_factories()
  local function helper(m)

    m.configure(table_itr({"beer.ale 60s:12h 1h:30d","beer.ale 60s:24h"}))

    assert_equal(3,#m.get_factories()["beer.ale"].rps)

    m.modify_factories({{"beer.ale","1h:30d","2h:90d"}})
    assert_equal(3,#m.get_factories()["beer.ale"].rps)
    local factories = m.get_factories()
    assert(factories["beer.ale"])
    -- first retention 60s:12h
    assert_equal(60,factories["beer.ale"].rps[1][1])
    assert_equal(12*60*60,factories["beer.ale"].rps[1][2])
    -- first retention 60s:24h
    assert_equal(60,factories["beer.ale"].rps[2][1])
    assert_equal(24*60*60,factories["beer.ale"].rps[2][2])

    -- 3rd retention is new 2h:90d
    assert_equal(2*60*60,factories["beer.ale"].rps[3][1])
    assert_equal(90*24*60*60,factories["beer.ale"].rps[3][2])
  end
  for_each_db("test_factories_1",helper)
end

local function sequence_any(seq_,callback_)
  local out = {}

  seq_.serialize({all_slots=true},insert_all_args(out),insert_all_args(out))
  local count = 1
  for i,v in ipairs(out) do
    if i>6 then -- first 3 slots are the header
      if callback_(v) then return true end
    end
  end

  return false
end

local function empty_sequence(seq_)
  local rv = sequence_any(seq_,function(v) return v~=0 end)
  return not rv
end

local function non_empty_sequence(seq_)
  local rv = sequence_any(seq_,function(v) return v>0 end)
  return rv
end

local function empty_metrics(metrics_)
  for _,m in ipairs(metrics_ or {}) do
    if not empty_sequence(m) then return false end
  end
  return true
end


local function non_empty_metrics(metrics_)
  if not metrics_ then return false end
  for _,m in ipairs(metrics_) do
    if non_empty_sequence(m) then return true end
  end
  return false
end

function test_metric_hierarchy()
  local ms = metric_hierarchy("foo")
  assert_equal("foo",ms())
  assert_equal(nil,ms())

  ms = metric_hierarchy("foo.bar")
  assert_equal("foo",ms())
  assert_equal("foo.bar",ms())
  assert_equal(nil,ms())

  ms = metric_hierarchy("foo.bar.snark")
  assert_equal("foo",ms())
  assert_equal("foo.bar",ms())
  assert_equal("foo.bar.snark",ms())
  assert_equal(nil,ms())
end

function test_export_configuration()
  local function helper(m)
    m.configure(table_itr({"beer.ale 60s:12h 1h:30d","beer.stout 3m:1h","beer.wheat 10m:1y"}))

    assert(string.find(m.export_configuration(),'"beer.ale":{"matcher": "prefix","retentions":["1m:12h" ,"1h:30d" ]',1,true),
           m.export_configuration())
    assert(string.find(m.export_configuration(),'"beer.wheat":{"matcher": "prefix","retentions":["10m:1y" ]',1,true))
  end
  for_each_db("test_export_configuration",helper)
end

function test_factories_out()
  local function helper(m)
    m.configure(table_itr({"beer.ale 60s:12h 1h:30d","beer.stout 3m:1h","beer.wheat 10m:1y"}))
    assert(string.find(m.export_configuration(),'"beer.ale":{"matcher": "prefix","retentions":["1m:12h" ,"1h:30d" ]',1,true))

    local fo = m.factories_out("beer.wheat")
    assert(string.find(fo,'"beer.wheat": ["10m:1y" ]',1,true))
    assert(string.find(m.export_configuration(),'"beer.wheat":{"matcher": "prefix","retentions":["10m:1y" ]',1,true))

    -- now really remove (with force)
    fo = m.factories_out("beer.wheat",{force=true})
    assert(string.find(fo,'"beer.wheat": ["10m:1y" ]',1,true))
    assert_nil(string.find(m.export_configuration(),'"beer.wheat": ["10m:1y" ]',1,true))

    -- just to verify that we don't crash on non-existing factories
    m.factories_out("wine")
  end
  for_each_db("test_factories_out",helper)
end

function test_process_in_memory()
  local function helper(m)
    m.configure(table_itr({"beer.ale 60s:12h 1h:30d","beer.stout 3m:1h","beer.wheat 10m:1y"}))

    assert_equal(0,#m.matching_sequences("beer.ale"))
    local factories = m.get_factories()
    assert(factories["beer.ale"])
    assert(factories["beer.stout"])
    assert(not factories["beer.lager"])
    assert_equal(1,#factories["beer.stout"].rps)
    assert_equal(2,#factories["beer.ale"].rps)
    assert_equal(nil,factories["beer.ale.brown.newcastle"])

    m.process("beer.ale.mild 20 74857843")

    assert(empty_metrics(m.matching_sequences("beer.stout")))

    assert(empty_metrics(m.matching_sequences("beer.ale.brown.newcastle")))

    assert(non_empty_metrics(m.matching_sequences("beer.ale.mild")))

    m.process("beer.ale.brown.newcastle 98 74857954")
    assert(m.matching_sequences("beer.ale.brown.newcastle"))
    assert(non_empty_metrics(m.matching_sequences("beer.ale.brown.newcastle")))

    m.process("beer.stout.irish 98 74857954")
    assert(non_empty_metrics(m.matching_sequences("beer.stout.irish")))
    assert(non_empty_metrics(m.matching_sequences("beer.stout")))
    assert(empty_metrics(m.matching_sequences("beer.wheat")))


    m.process("beer.stout 143 74858731")
    assert(non_empty_metrics(m.matching_sequences("beer.stout")))
  end
  for_each_db("test_process_in_memory",helper)
end

function test_top_level_factories()

  function helper(m)
    m.configure(table_itr({"beer. 60s:12h 1h:30d","beer 3m:1h"}))
    assert_equal(0,#m.matching_sequences("beer.ale"))
    local factories = m.get_factories()


    assert_equal(1,table_size(factories))
    assert(factories["beer"])
    assert(not factories["beer.lager"])
    assert_equal(nil,factories["beer.ale"])
    assert_equal(nil,factories["beer.ale.brown.newcastle"])


    m.process({"beer.ale.mild 20 74857843","beer.ale.mild.bitter 20 74857843","beer.ale.mild.sweet 30 74857843"})
    assert(non_empty_metrics(m.matching_sequences("beer.ale")))
    assert(empty_metrics(m.matching_sequences("beer.stout")))

    assert(empty_metrics(m.matching_sequences("beer.ale.brown.newcastle")))
    assert(non_empty_metrics(m.matching_sequences("beer")))
    assert(non_empty_metrics(m.matching_sequences("beer.ale.mild")))
    --print(m.latest("beer"))
    assert(string.find(m.latest("beer"),"70,3,74857800"))

    m.process("beer.ale.brown.newcastle 98 74857954")
    assert(m.matching_sequences("beer.ale.brown.newcastle"))
    assert(non_empty_metrics(m.matching_sequences("beer.ale.brown.newcastle")))

    m.process("beer.stout.irish 98 74857954")
    assert(non_empty_metrics(m.matching_sequences("beer.stout.irish")))
    assert(non_empty_metrics(m.matching_sequences("beer.stout")))
    assert(empty_metrics(m.matching_sequences("beer.wheat")))


    m.process("beer.stout 143 74858731")
    assert(non_empty_metrics(m.matching_sequences("beer.stout")))
  end

  for_each_db("top_level",helper)
end

function test_modify_factories()
  local function helper(m)
    m.configure(table_itr({"beer.ale 60s:12h 1h:30d"}))

    m.process("beer.ale.mild 20 74857843")
    assert(non_empty_metrics(m.matching_sequences("beer.ale")))
    assert_equal(4,#m.matching_sequences("beer.ale"))
    assert(string.find(m.graph("beer.ale"),'"beer.ale;1m:12h": [[20,1,74857800]'))
    assert(string.find(m.graph("beer.ale"),'"beer.ale;1h:30d": [[20,1,74857800]'))
    m.modify_factories({{"beer.ale","1h:30d","2h:90d"}})

    assert(non_empty_metrics(m.matching_sequences("beer.ale")))
    assert_nil(string.find(m.graph("beer.ale"),'"beer.ale;1h:30d": [[20,1,74857800]',1,true))

    assert(string.find(m.graph("beer.ale"),'"beer.ale;2h:90d":[^{}]+[20,1,74851200]'),m.graph("beer.ale"))
    assert(string.find(m.graph("beer.ale"),'"beer.ale;2h:90d": [[20,1,74851200]',1,true))
  end
  for_each_db("modify_factories",helper)
end


function test_reset()
  function helper(m)
    m.configure(table_itr({"beer 60s:12h 1h:30d","beer.stout 3m:1h"}))
    assert_equal(0,#m.matching_sequences("beer.ale"))
    local factories = m.get_factories()
    assert(factories["beer.stout"])

    assert_equal(0,#m.matching_sequences("beer.stout"))
    assert_equal(0,#m.matching_sequences("beer.ale.brown.newcastle"))

    m.process("beer.ale.mild 20 74857843")

    assert(non_empty_metrics(m.matching_sequences("beer")))
    assert(empty_metrics(m.matching_sequences("beer.stout")))
    assert(2,#m.matching_sequences("beer.ale"))
    assert(2,#m.matching_sequences("beer.ale.mild"))

    assert(empty_metrics(m.matching_sequences("beer.ale.brown.newcastle")))
    assert(non_empty_metrics(m.matching_sequences("beer.ale.mild")))

    m.process("beer.ale.brown.newcastle 98 74857954")
    assert(m.matching_sequences("beer.ale.brown.newcastle"))
    assert(non_empty_metrics(m.matching_sequences("beer.ale.brown.newcastle")))

    m.process("beer.stout.irish 98 74857954")
    assert(non_empty_metrics(m.matching_sequences("beer.stout.irish")))
    assert(non_empty_metrics(m.matching_sequences("beer.stout")))


    m.process("beer.stout 143 74858731")
    assert(non_empty_metrics(m.matching_sequences("beer.stout")))
    assert(non_empty_metrics(m.matching_sequences("beer")))

    assert(string.find(m.graph("beer.stout;1h:30d"),'[143,1,74858400]',1,true))
    assert(string.find(m.graph("beer.stout;1h:30d"),'[98,1,74854800]',1,true))
    m.process(".reset beer.stout timestamp=74857920&force=false")
    assert(string.find(m.graph("beer.stout;1h:30d"),'[143,1,74858400]',1,true))
    assert(string.find(m.graph("beer.stout;1h:30d"),'[0,0,74854800]',1,true))

    assert_nil(string.find(m.graph("beer.stout;1h:30d"),'[98,1,74858400]',1,true))
    assert(non_empty_metrics(m.matching_sequences("beer")))
    m.process(".reset beer.stout force=true&level=1")
    assert(non_empty_metrics(m.matching_sequences("beer")))

    assert(empty_metrics(m.matching_sequences("beer.stout")))
    assert(empty_metrics(m.matching_sequences("beer.ale.irish")))
    assert(non_empty_metrics(m.matching_sequences("beer.ale.brown.newcastle")))


    m.process(".reset beer.ale force=true&level=2")
    assert(non_empty_metrics(m.matching_sequences("beer")))
    assert(empty_metrics(m.matching_sequences("beer.ale")))
    assert(empty_metrics(m.matching_sequences("beer.ale.brown")))
    assert(empty_metrics(m.matching_sequences("beer.ale.brown.newcastle")))
  end


  for_each_db("reset",helper)
end

function test_reset2()
  function helper(m)
    m.configure(table_itr({"beer.ale 60s:12h 1h:30d","beer.stout 5m:3d"}))
    m.process("./tests/fixtures/reset2.mule")
    assert(string.find(m.graph("beer.stout.irish;5m:3d"),'[8,3,1418602500]',1,true))
    assert(string.find(m.graph("beer.stout.irish;5m:3d"),'[9,4,1418602800]',1,true))
    m.process(".reset beer.stout.irish timestamp=1418602700&force=false&level=1")
    assert(string.find(m.graph("beer.stout.irish;5m:3d"),'[0,0,1418602500]',1,true))
    assert(string.find(m.graph("beer.stout.irish;5m:3d"),'[9,4,1418602800]',1,true))
  end
  for_each_db("reset2",helper)
end

function test_save_load()
  local function helper(m,db)
    m.configure(table_itr({"beer.ale 60s:12h 1h:30d","beer.stout 3m:1h"}))
    assert_equal(2,table_size(m.get_factories()))
    m.process("beer.ale.mild 20 74857843")
    m.process("beer.ale.brown.newcastle 98 74857954")
    m.process("beer.stout.irish 98 74857954")
    m.process("beer.stout 143 74858731")
    m.save()

    local n = mule(db)
    n.load()
    assert_equal(2,table_size(n.get_factories()))
    assert_equal(2,#n.get_factories()["beer.ale"].rps)
    assert_equal(1,#n.get_factories()["beer.stout"].rps)
  end
  for_each_db("save_load",helper)
end


function test_process_other_dbs()
  local function helper(m)
    m.configure(table_itr({"beer.ale 60s:12h 1h:30d","beer.stout 3m:1h","beer.wheat 10m:1y"}))
    assert_equal(0,#m.matching_sequences("beer.ale"))
    local factories = m.get_factories()
    assert(factories["beer.ale"])
    assert(factories["beer.stout"])
    assert(not factories["beer.lager"])
    assert_equal(1,#factories["beer.stout"].rps)
    assert_equal(2,#factories["beer.ale"].rps)
    assert_equal(nil,factories["beer.ale.brown.newcastle"])

    m.process("beer.ale.mild 20 74857843")

    assert(empty_metrics(m.matching_sequences("beer.stout")))

    assert(empty_metrics(m.matching_sequences("beer.ale.brown.newcastle")))
    assert(non_empty_metrics(m.matching_sequences("beer.ale.mild")))

    m.process("beer.ale.brown.newcastle 98 74857954")
    assert(m.matching_sequences("beer.ale.brown.newcastle"))
    assert(non_empty_metrics(m.matching_sequences("beer.ale.brown.newcastle")))

    m.process("beer.stout.irish 98 74857954")
    assert(non_empty_metrics(m.matching_sequences("beer.stout.irish")))
    assert(non_empty_metrics(m.matching_sequences("beer.stout")))
    assert(empty_metrics(m.matching_sequences("beer.wheat")))


    m.process("beer.stout 143 74858731")
    assert(non_empty_metrics(m.matching_sequences("beer.stout")))
  end
  for_each_db("process_tokyo",helper)
end

function test_latest()
  local function helper(m)
    m.configure(table_itr({"beer.ale 60s:12h 1h:30d","beer.stout 3m:1h","beer.wheat 10m:1y"}))

    m.process("beer.ale.brown 3 3")
    assert(string.find(m.latest("beer.ale.brown;1m:12h"),"3,1,0"))
    assert(string.find(m.graph("beer.ale.brown;1m:12h",{timestamps="latest"}),"3,1,0"))
    assert(string.find(m.slot("beer.ale.brown;1m:12h",{timestamps="1"}),"3,1,0"))
    assert(string.find(m.latest("beer.ale.pale;1m:12h"),'"data": {}'))
    assert(string.find(m.graph("beer.ale.pale;1m:12h",{timestamps="latest"}),'"data": {}',1,true))
    assert(string.find(m.latest("beer.ale.pale;1h:30d"),'"data": {}'))


    -- the timestamp is adjusted
    assert(string.find(m.latest("beer.ale.brown"),"3,1,0"))
    assert(string.find(m.latest("beer.ale.brown;1m:12h"),"3,1,0"))


    m.process("beer.ale.pale 2 3601")
    assert(string.find(m.latest("beer.ale.brown;1m:12h"),"3,1,0"))
    assert(string.find(m.graph("beer.ale.brown;1m:12h",{timestamps="latest-90"}),'"beer.ale.brown;1m:12h": []',1,true))
    assert(string.find(m.graph("beer.ale.pale;1m:12h",{timestamps="3604"}),"2,1,3600"))
    assert(string.find(m.graph("beer.ale.pale;1m:12h",{timestamps="latest+10s"}),"2,1,3600"))
    assert_nil(string.find(m.graph("beer.ale.pale;1m:12h",{timestamps="latest+10m,now"}),"2,1,3600"))
    assert(string.find(m.graph("beer.ale.pale;1m:12h",{timestamps="latest+10m"}),'"beer.ale.pale;1m:12h": []',1,true))
    assert(string.find(m.latest("beer.ale;1h:30d"),"2,1,3600"))

    m.process("beer.ale.pale 7 4")
    -- the latest is not affected
    assert(string.find(m.latest("beer.ale;1h:30d"),"2,1,3600"))
    assert(string.find(m.graph("beer.ale.pale;1h:30d","latest-56m"),"7,1,0"))
    -- lets check the range
    local g = m.graph("beer.ale.pale;1h:30d","0..latest")
    assert(string.find(g,"2,1,3600"))
    assert(string.find(g,"7,1,0"))
    g = m.graph("beer.ale.pale;1h:30d","latest..0")

    assert(string.find(g,"[[2,1,3600],[7,1,0]]"))
    m.process("beer.ale.pale 9 64")
    g = m.graph("beer.ale.pale;1m:12h",{timestamps="latest..0"})
    assert(string.find(g,"[[2,1,3600],[9,1,60],[7,1,0]]",1,true))

    m.process("beer.ale.brown 90 4400")
    assert(string.find(m.latest("beer.ale;1h:30d"),"92,2,3600"))
    -- we have two hits 3+7 at times 3 and 4 which are adjusted to 0

    m.process("beer.ale.brown 77 7201")
    assert_nil(string.find(m.graph("beer.ale;1h:30d",{timestamps="latest,latest-2h"}),"92,2,3600"))
    assert(string.find(m.graph("beer.ale;1h:30d","latest-3m"),"92,2,3600"))
  end

  for_each_db("process",helper)
end

function test_update_only_relevant()
  local function helper(m)
    m.configure(table_itr({"beer.ale 60s:12h","beer.stout 3m:1h","beer.wheat 10m:1y"}))

    m.process("beer.ale.pale 7 4")
    m.process("beer.ale.brown 6 54")

    assert(string.find(m.latest("beer.ale;1m:12h"),"13,2,0"))


    m.process("beer.ale.burton 32 91")

    assert(string.find(m.latest("beer.ale.pale;1m:12h"),"7,1,0",1,true))
    assert(string.find(m.latest("beer.ale.brown;1m:12h"),"[6,1,0]",1,true))

    assert(string.find(m.latest("beer.ale.burton;1m:12h"),"[32,1,60]",1,true))
    assert(string.find(m.latest("beer.ale;1m:12h"),"[32,1,60]",1,true))
    assert(string.find(m.slot("beer.ale.burton;1m:12h",{timestamps=93}),"[32,1,60]",1,true))

    m.process("beer.ale 132 121")
    assert(string.find(m.slot("beer.ale;1m:12h",{timestamps="121"}),"[132,1,120]",1,true))
    assert(string.find(m.latest("beer.ale;1m:12h"),"[132,1,120]",1,true))
    assert(string.find(m.latest("beer.ale.pale;1m:12h"),"[7,1,0]",1,true))
    assert(string.find(m.latest("beer.ale.brown;1m:12h"),"[6,1,0]",1,true))
    assert(string.find(m.latest("beer.ale.burton;1m:12h"),"[32,1,60]",1,true))

    m.process("beer.ale =94 121")

    assert(string.find(m.slot("beer.ale;1m:12h",{timestamps="121"}),"[94,1,120]",1,true))

    m.process("beer.ale.burton =164 854")
    assert(string.find(m.slot("beer.ale.burton;1m:12h",{timestamps="latest"}),"[164,1,840]",1,true))

    m.process("beer.ale.burton ^90 854")
    assert(string.find(m.slot("beer.ale.burton;1m:12h",{timestamps="latest"}),"[164,1,840]",1,true))

    m.process("beer.ale.burton ^190 854")
    assert(string.find(m.slot("beer.ale.burton;1m:12h",{timestamps="latest"}),"[190,1,840]",1,true))

  end

  for_each_db("update_only_relevant",helper)
end


function test_metric_one_level_children()
  local function helper(m,db)
    m.configure(table_itr({"beer.ale 60s:12h 1h:30d","beer.stout 3m:1h","beer.wheat 10m:1y"}))

    m.process("beer.ale.pale 7 4")
    m.process("beer.ale.pale.hello 7 4")
    m.process("beer.ale.pale.hello.cruel 7 4")
    m.process("beer.ale.brown 6 54")
    m.process("beer.ale.brown.world 6 54")
    m.process("beer.ale.burton 32 91")
    m.process("beer.ale 132 121")

    local tests = {
      {"beer.ale.brown",4},
      {"beer.ale",8},
      {"beer",2},
      {"",2},
      {"foo",0},
    }

    for j,t in ipairs(tests) do
      local children = 0
      for i in db.matching_keys(t[1],1) do
        if string.find(i,"metadata=",1,true)~=1 then
          children = children + 1
        end
      end
      assert_equal(t[2],children,j)
    end
  end

  for_each_db("one_level_children",helper,true)
end


function test_dump_restore()
  local line = " beer.stout.irish;5m:2d  1 1 1320364800  1 1 1344729900  1 1 1320019800  1 1 1320538500  1 1 1324858800  1 1 1351988700  1 1 1320366600  1 1 1331426100  1 1 1323996000  1 1 1320194700  1 1 1326588600  1 1 1333328100  1 1 1320195600  1 1 1329008700  1 1 1317604200  1 1 1319850900  1 1 1320196800  1 1 1314321900  2 1 1320543000  1 1 1321925700  1 1 1317433200  1 1 1317951900  1 1 1303609800  1 1 1317779700  1 1 1320717900  1 1 1318299000  1 1 1324520100  1 1 1315707900  1 1 1318991400  2 1 1325558100  1 1 1310524800  1 1 1327459500  1 1 1317955800  1 1 1322276100  1 1 1319857200  1 1 1325905500  1 1 1320203400  1 1 1316402100  1 1 1317439200  1 1 1352345100  1 1 1317439800  1 1 1318304400  1 1 1317786300  1 1 1310183400  1 1 1319169300  1 1 1317614400  1 1 1318133100  1 1 1301371800  1 1 1317788100  1 1 1317788400  1 1 1317615900  1 1 1302409800  1 1 1320035700  1 1 1313642400  2 1 1318999500  1 1 1317963000  1 1 1318308900  1 1 1317272400  1 1 1318482300  1 1 1308287400  1 1 1318828500  1 1 1318828800  1 1 1317446700  2 1 1319866200  1 1 1320039300  1 1 1318830000  1 1 1317966300  1 1 1318485000  1 1 1335419700  1 1 1319522400  1 1 1317794700  1 1 1318486200  1 1 1325916900  1 1 1327645200  1 1 1319523900  1 1 1350973800  1 1 1318487700  1 1 1329201600  1 1 1342161900  1 1 1318661400  2 2 1326783300  1 1 1318834800  1 1 1334214300  1 1 1319699400  1 1 1336288500  1 1 1347693600  1 1 1319527500  1 1 1338708600  3 1 1334907300  14 1 1334043600  1 1 1318319100  1 1 1317801000  1 1 1335426900  1 1 1319702400  1 1 1334909100  1 1 1336983000  1 1 1333872900  1 1 1348215600  1 1 1319876700  1 1 1323678600  1 1 1321605300  1 1 1333356000  1 1 1350809100  1 1 1320569400  1 1 1321952100  2 1 1332147600  1 1 1336640700  1 1 1334394600  1 1 1320570900  1 1 1332321600  1 1 1326619500  1 1 1320226200  1 1 1341308100  1 1 1321782000  1 1 1331631900  1 1 1328521800  1 1 1325584500  1 1 1340964000  1 1 1333188300  1 1 1336990200  1 1 1335608100  1 1 1332843600  1 1 1331461500  1 1 1320921000  1 1 1333535700  1 1 1333363200  2 1 1336819500  1 1 1319021400  1 1 1331290500  1 1 1349089200  1 1 1350126300  2 1 1335611400  1 1 1351509300  1 1 1320924000  1 1 1325589900  1 1 1320233400  1 1 1332848100  1 1 1333366800  1 1 1328183100  1 1 1339588200  1 1 1328183700  1 1 1334923200  1 1 1338206700  1 1 1334923800  1 1 1334232900  6 1 1320063600  1 1 1331295900  1 1 1320582600  2 1 1327494900  1 1 1320756000  1 1 1330778700  1 1 1330433400  1 1 1328014500  1 1 1337346000  1 1 1332507900  1 1 1334063400  1 1 1339247700  1 1 1335446400  9 1 1320931500  1 1 1331645400  1 1 1324388100  1 1 1336311600  1 1 1348926300  1 1 1325598600  1 1 1326290100  1 1 1353074400  2 1 1342188300  1 1 1324735800  1 1 1344435300  1 1 1324390800  1 1 1349447100  1 1 1349274600  3 2 1350138900  1 1 1350139200  1 1 1319899500  1 1 1332168600  1 1 1351695300  1 1 1320937200  1 1 1329404700  2 1 1323184200  1 1 1321283700  1 1 1334762400  2 1 1332861900  2 1 1333553400  1 1 1331307300  1 1 1320939600  1 1 1342885500  1 1 1336146600  1 1 1334418900  1 1 1324396800  1 1 1327334700  1 1 1332864600  1 1 1320596100  1 1 1341505200  1 1 1329927900  1 1 1350318600  1 1 1351182900  1 1 1335112800  1 1 1349455500  1 1 1324054200  1 1 1332694500  1 1 1330966800  1 1 1329930300  1 1 1346519400  1 1 1328894100  1 1 1349803200  1 1 1342373100  1 1 1348421400  1 1 1338226500  1 1 1353087600  1 1 1329932700  1 1 1331142600  1 1 1341510900  1 1 1320775200  1 1 1321466700  1 1 1330452600  1 1 1326132900  1 1 1346350800  1 1 1352226300  1 1 1320777000  1 1 1330108500  1 1 1324579200  1 1 1320432300  2 1 1320087000  1 1 1346180100  1 1 1320260400  1 1 1349118300  1 1 1326309000  1 1 1320088500  1 1 1334258400  1 1 1322162700  1 1 1337023800  1 1 1350329700  1 1 1332013200  4 1 1344627900  2 1 1346701800  1 1 1344282900  1 1 1323892800  1 1 1346875500  1 1 1334088600  1 1 1326485700  1 1 1327695600  1 1 1322684700  1 1 1332016200  1 1 1348605300  1 1 1340656800  1 1 1350852300  2 2 1323031800  1 1 1332363300  1 1 1338066000  1 1 1347224700  1 1 1321305000  1 1 1340658900  1 1 1322860800  2 1 1328217900  1 1 1337376600  1 1 1330119300  2 1 1319233200  1 1 1325108700  1 1 1331848200  2 1 1332885300  1 1 1319925600  1 1 1333922700  1 1 1331331000  1 1 1346883300  1 1 1327702800  1 1 1324938300  1 1 1332887400  1 1 1331332500  1 1 1318027200  1 1 1352933100  1 1 1328050200  2 1 1332716100  1 1 1328050800  1 1 1322175900  1 1 1325805000  1 1 1328915700  2 1 1333927200  1 1 1329089100  1 1 1350689400  1 1 1319067300  1 1 1329954000  1 1 1323215100  1 1 1344642600  1 1 1337212500  1 1 1319587200  1 1 1323907500  1 1 1320797400  1 1 1320106500  2 1 1319415600  1 1 1318551900  1 1 1329784200  1 1 1317515700  1 1 1318034400  1 1 1322009100  1 1 1345510200  1 1 1317689700  1 1 1314061200  1 1 1320800700  2 1 1320109800  1 1 1318209300  1 1 1301102400  1 1 1318382700  1 1 1320111000  1 1 1319592900  1 1 1320284400  3 1 1319593500  1 1 1317865800  1 1 1319939700  1 1 1331344800  1 1 1317521100  1 1 1309054200  1 1 1293848100  1 1 1317349200  1 1 1317867900  1 1 1302316200  1 1 1317177300  1 1 1316313600  1 1 1338259500  1 1 1317351000  1 1 1317524100  1 1 1319425200  1 1 1319771100  1 1 1319253000  1 1 1304565300  2 1 1317180000  1 1 1309922700  1 1 1319254200  1 1 1318217700  1 1 1313206800  1 1 1319427900  1 1 1319428200  1 1 1316490900  2 1 1317700800  1 1 1317355500  1 1 1317874200  1 1 1315628100  1 1 1311135600  1 1 1317011100  1 1 1319257800  1 1 1311827700  1 1 1319949600  1 1 1318394700  1 1 1308027000  1 1 1320814500  1 1 1313384400  1 1 1317186300  1 1 1318914600  1 1 1319951700  2 1 1317360000  1 1 1320816300  1 1 1318915800  1 1 1320816900  1 1 1313905200  1 1 1324619100  1 1 1346565000  1 1 1318571700  1 1 1321855200  1 1 1320127500  2 1 1320819000  1 1 1317363300  1 1 1314253200  1 1 1318746300  1 1 1333953000  1 1 1323412500  1 1 1319956800  1 1 1333089900  1 1 1347605400  1 1 1320130500  1 1 1319439600  1 1 1319439900  1 1 1345187400  1 1 1320822900  1 1 1332746400  2 1 1334301900  1 1 1325662200  1 1 1333438500  1 1 1330674000  1 1 1321688700  1 1 1348818600  1 1 1336895700  1 1 1320307200  1 1 1345190700  1 1 1342080600  1 1 1320653700  1 1 1320654000  1 1 1348129500  1 1 1326184200  1 1 1333269300  1 1 1331541600  1 1 1323765900  2 1 1327740600  1 1 1348304100  1 1 1332579600  1 1 1349514300  1 1 1329815400  1 1 1339665300  1 1 1321521600  1 1 1320485100  1 1 1341739800  1 1 1336901700  1 1 1324633200  1 1 1346751900  1 1 1335520200  7 1 1323251700  1 1 1336384800  2 2 1331201100  5 1 1329127800  1 1 1329473700  1 1 1327573200  1 1 1348827900  1 1 1321871400  1 1 1337596500  1 1 1342780800  1 1 1327574700  1 1 1351594200  1 1 1350903300  1 1 1328958000  1 1 1328267100  1 1 1331896200  1 1 1333451700  1 1 1328613600  1 1 1348658700  2 1 1322047800  2 1 1323257700  1 1 1331206800  1 1 1328096700  1 1 1322567400  1 1 1332935700  1 1 1345723200  1 1 1329998700  1 1 1350389400  1 1 1338293700  1 1 1351599600  1 1 1331900700  1 1 1325680200  1 1 1332938100  1 1 1319978400  2 2 1322570700  2 1 1324126200  1 1 1328100900  1 1 1345035600  1 1 1348319100  1 1 1333113000  1 1 1345727700  1 1 1337606400  1 1 1324646700  1 1 1351431000  1 1 1317908100  1 1 1334670000  1 1 1331732700  1 1 1350741000  1 1 1334152500  1 1 1349532000  1 1 1347631500  1 1 1345385400  1 1 1326723300  1 1 1345213200  1 1 1320675900  1 1 1346596200  1 1 1348842900  1 1 1337438400  2 1 1321886700  1 1 1331391000  1 1 1322578500  1 1 1347634800  1 1 1333811100  1 1 1348326600  1 1 1335539700  1 1 1324308000  1 1 1320333900  1 1 1331911800  1 1 1331048100  2 1 1342626000  1 1 1330357500  1 1 1332258600  1 1 1329321300  1 1 1340380800  1 1 1325865900  1 1 1333469400  1 1 1320682500  1 1 1329841200  1 1 1351787100  1 1 1347985800  2 1 1320165300  1 1 1323794400  1 1 1324658700  3 1 1319993400  1 1 1325004900  1 1 1326387600  1 1 1328807100  1 1 1330362600  1 1 1330362900  1 1 1323278400  1 1 1327425900  1 1 1328808600  1 1 1340559300  1 1 1348854000  1 1 1322588700  1 1 1335203400  1 1 1331747700  1 1 1332093600  1 1 1322935500  1 1 1326046200  1 1 1326046500  2 1 1323454800  2 1 1327602300  1 1 1344191400  1 1 1335551700  1 1 1327776000  1 1 1349721900  1 1 1345056600  1 1 1323111300  1 1 1333479600  1 1 1349723100  1 1 1353179400  1 1 1350933300  1 1 1333653600  1 1 1320348300  1 1 1346095800  1 1 1351625700  1 1 1329334800  1 1 1351280700  1 1 1343505000  1 1 1350935700  1 1 1323979200  1 1 1332792300  1 1 1347135000  1 1 1327090500  1 1 1326745200  1 1 1331929500  2 1 1330547400  1 1 1334522100  1 1 1336768800  1 1 1327265100  1 1 1328475000  1 1 1331412900  1 1 1337461200  1 1 1328648700  1 1 1329340200  1 1 1339535700  9 2 1349385600  1 1 1327267500  1 1 1325367000  1 1 1346967300  1 1 1349386800  1 1 1320702300  1 1 1320702600  1 1 1321912500  1 1 1331762400  1 1 1331417100  2 1 1323814200  1 1 1330380900  1 1 1334874000  1 1 1337984700  1 1 1320359400  1 1 1336948500  2 1 1353019200  1 1 1350945900  1 1 1348527000  1 1 1331938500  1 1 1325199600  2 1 1329001500  1 1 1331939400  1 1 1322090100  1 1 1326237600  1 1 1321399500  1 1 1322782200  1 1 1320708900  1 1 1323992400  1 1 1325547900  1 1 1323301800  1 1 1329177300"

  local function helper(m)
    m.configure(table_itr({"beer.ale 60s:12h 1h:30d","beer.stout 5m:2d"}))
    -- the maximal time stamp is 1353179400 and there are exactly 4 slots which are no more
    -- than 48 hours before it
    m.process(line)
    assert(string.find(m.graph("beer.stout.irish;5m:2d",{timestamps="latest-2d+1..latest",filter="latest"}),'"data": {"beer.stout.irish;5m:2d": [[1,1,1353179400],[2,1,1353019200],[1,1,1353074400],[1,1,1353087600]]',1,true))
    assert(string.find(m.graph("beer.stout.irish;5m:2d",{timestamps="latest-2d+1..latest",filter="now"}),'"data": {"beer.stout.irish;5m:2d": []',1,true))
    assert(string.find(m.graph("beer.stout.irish;5m:2d",{filter="latest"}),'"data": {"beer.stout.irish;5m:2d": [[1,1,1353074400],[1,1,1353087600],[1,1,1353179400],[2,1,1353019200]]',1,true))

  end

  for_each_db("dump_restore",helper)
end


function test_pale()
  local function helper(m,db)
    m.configure(table_itr({"beer. 5m:48h 1h:30d 1d:3y","mule. 5m:3d 1h:90d"}))

    m.process("./tests/fixtures/pale.dump")

    assert(string.find(m.slot("beer.ale.pale;1h:30d",{timestamps="1360800000"}),"274,244",1,true))
    assert(string.find(m.slot("beer.ale;5m:2d",{timestamps="1361127300"}),"1526,756",1,true))
    m.process("./tests/fixtures/pale.mule")
    --    m.flush_cache()

    assert(string.find(m.slot("beer.ale.pale;5m:2d",{timestamps="1361300362"}),"19,11",1,true))

    assert(string.find(m.slot("beer.ale.pale.rb;5m:2d",{timestamps="1361300428"}),"11,5",1,true))
    assert(string.find(m.slot("beer.ale;5m:2d",{timestamps="1361300362"}),"46,27",1,true))
  end

  for_each_db("pale",helper)
end

function test_key()
  local function helper(m,db)
    m.configure(table_itr({"beer 5m:48h 1h:30d 1d:3y"}))

    m.process("./tests/fixtures/pale.mule")
    m.flush_cache()
    assert(m.key("beer",{})==m.key("beer",{level=0}))

    -- there are 61 unique keys in pale.mule all are beer.pale sub keys
    -- (cut -d' ' -f 1 tests/fixtures/pale.mule  | sort | uniq | wc -l)
    local tests = {
      {0,1*3}, -- beer
      {1,2*3}, -- beer.ale
      {2,4*3}, -- beer.ale.{pale,brown}
      {3,(2+61)*3} -- beer, beer.ale and then the other keys
    }
    for i,t in ipairs(tests) do
      local g = m.graph("beer",{level=t[1],count=1000})
      local count = #split(g,";")-1
      assert_equal(t[2],count,i..": "..g)
    end

    local all_keys = string.match(m.key("beer",{level=4}),"%{(.+)%}")
    assert_equal(1+(61+2)*3,#split(all_keys,","))
    all_keys = string.match(m.key("beer",{level=4}),"%{(.+)%}")
    assert_equal(1+(61+2)*3,#split(all_keys,","))

    all_keys = string.match(m.key("beer",{level=1}),"{(.+)}")
    assert_equal(1+2*3,#split(all_keys,","))

  end
  for_each_db("key",helper)
end

function test_bounded_by_level()
  assert(bounded_by_level("hello.cruel.world","hello",2))
  assert_false(bounded_by_level("hello.cruel.world","hello",1))
  assert(bounded_by_level("hello.cruel.world","hello.cruel",1))
  assert(bounded_by_level("hello.cruel.world","hello.cruel.world",1))
  assert(bounded_by_level("hello.cruel.world","hello.cruel",12))
end


function test_duplicate_timestamps()
    local function helper(m)
      m.configure(n_lines(109,io.lines("./tests/fixtures/d_conf")))
      m.process(n_lines(109,io.lines("./tests/fixtures/d_input.mule")))
      for l in string_lines(m.dump("Johnston.Morfin",{to_str=true}).get_string()) do
        if #l>0 then
          assert_equal(4,#split(l," "),l)
        end
      end
    end
  for_each_db("test_duplicate_timestamps",helper)
end

function test_dashes_in_keys()
  local function helper(m)
    m.configure(n_lines(110,io.lines("./tests/fixtures/d_conf")))
    m.process("Johnston.Morfin.Jamal.Marcela.Emilia.Zulema 5 10")
    m.process("Johnston.Emilia.Sweet-Nuthin 78 300")
    assert(string.find(m.key("Johnston",{level=4}),"Sweet%-Nuthin"))
    assert(string.find(m.dump("Johnston.Emilia",{to_str=true}).get_string(),"Sweet%-Nuthin;1s:1m 78 1 300"))
    m.process("Johnston.Emilia.Sweet-Nuthin 2 300")
    assert(string.find(m.dump("Johnston.Emilia",{to_str=true}).get_string(),"Sweet%-Nuthin;1m:1h 80 2 300"))
  end
  for_each_db("test_dashes_in_keys",helper)
end

function test_stacked()
  function helper(m)
    m.configure(n_lines(110,io.lines("./tests/fixtures/d_conf")))
    m.process("Johnston.Morfin.Jamal.Marcela.Emilia.Zulema 5 10")
    m.process("Johnston.Emilia.Sweet-Nuthin 78 300")
--    repeat until not m.flush_cache()
    local level1 = m.graph("Johnston.Morfin",{level=1})
    local level2 = m.graph("Johnston.Morfin",{level=2})

    assert(string.find(level2,"Johnston.Morfin.Jamal.Marcela;1s:1m",1,true),level2)
    assert(string.find(level2,"Johnston.Morfin.Jamal;1s:1m",1,true))
    assert_nil(string.find(level1,"Johnston.Morfin.Jamal.Marcela;1s:1m",1,true))
    assert(string.find(level1,"Johnston.Morfin.Jamal;1s:1m",1,true))
    assert(string.find(level1,"Johnston.Morfin.Jamal;1m:1h",1,true))

    level2 = m.graph("Johnston.Morfin;1m:1h",{level=2})
    level1 = m.graph("Johnston.Morfin;1m:1h",{level=1})


    assert(string.find(level2,"Johnston.Morfin.Jamal.Marcela;1m:1h",1,true))
    assert(string.find(level2,"Johnston.Morfin.Jamal;1m:1h",1,true))
    assert_nil(string.find(level2,"Johnston.Morfin.Jamal.Marcela;1s:1m",1,true))
    assert(string.find(level2,"Johnston.Morfin.Jamal.Marcela;1m:1h",1,true))
    assert(string.find(level1,"Johnston.Morfin.Jamal;1m:1h",1,true))
    assert_nil(string.find(level1,"Johnston.Morfin.Jamal;1h:12h",1,true))

    assert_equal(string.find(m.graph("Johnston.Morfin.Jamal",{level=2,count=1}),
                             '{"version": 3,\n"data": {"Johnston.Morfin.Jamal;%d+%w:%d+%w": [[5,1,0]]\n}\n}'))

    local level0 = m.graph("Johnston.Morfin.Jamal;1m:1h",{level=0})
    assert(string.find(level0,"Johnston.Morfin.Jamal;1m:1h",1,true))
    assert_nil(string.find(level0,"Johnston.Morfin.Jamal.",1,true))

    level0 = m.graph("Johnston.Morfin.Jamal",{level=0})
    assert(string.find(level0,"Johnston.Morfin.Jamal;1m:1h",1,true))
    assert(string.find(level0,"Johnston.Morfin.Jamal;1h:12h",1,true))
    assert(string.find(level0,"Johnston.Morfin.Jamal;1s:1m",1,true))
    assert_nil(string.find(level0,"Johnston.Morfin.Jamal.",1,true))
  end
  for_each_db("stacked",helper)
end

function test_rank_output()
  local function helper(m)
    m.configure(n_lines(110,io.lines("./tests/fixtures/d_conf")))
    m.process("Johnston.Morfin.Jamal.Marcela.Emilia.Zulema 5 10")
    m.process("Johnston.Emilia.Sweet-Nuthin 78 300")
    assert_equal(string.find(m.graph("Johnston.Morfin.Jamal",{level=1,count=1}),'{"version": 3,\n"data": {"Johnston.Morfin.%w+;1h:12h": [[5,1,0]]\n}\n}'))
    assert_equal(string.find(m.graph("Johnston.Morfin.Jamal",{level=2,count=1}),'{"version": 3,\n"data": {"Johnston.Morfin.Jamal;%d+%w:%d+%w]+": [[5,1,0]]\n}\n}'))
    assert_equal(string.find(m.graph("Johnston.Morfin.Jamal",{level=1,count=2}),'{"version": 3,\n"data": {"Johnston.Morfin.%w+;1h:12h": [[5,1,0]]\n,"Johnston.Morfin.%w+;1m:1h": [[5,1,0]]\n}\n}'))
  end

  for_each_db("test_rank_output",helper)
end


function test_caching()
  local function helper(m)
    m.configure(n_lines(110,io.lines("./tests/fixtures/d_conf")))
    m.process("Johnston.Morfin.Jamal.Marcela.Emilia.Zulema 5 10")
    m.process("Johnston.Emilia.Sweet-Nuthin 78 300")
    m.graph("Johnston.Morfin.Jamal.Marcela",{level=1,count=1})
    assert_equal(string.find(m.graph("Johnston.Morfin.Jamal",{level=1,count=1}),'{"version": 3,\n"data": {"Johnston.Morfin.Jamal;%w+": [[5,1,0]]\n}\n}'))
    assert_equal(string.find(m.graph("Johnston.Morfin.Jamal",{level=1,count=2}),'{"version": 3,\n"data": {"Johnston.Morfin.%w+;1h:12h": [[5,1,0]]\n,"Johnston.Morfin.%w;1m:1h": [[5,1,0]]\n}\n}'))
    m.process("Johnston.Morfin.Jamal.Marcela.Emilia.Zulema 5 10")
    m.process("Johnston.Emilia.Sweet-Nuthin 78 300")
    assert_equal(string.find(m.graph("Johnston.Morfin.Jamal",{level=1,count=1}),'{"version": 3,\n"data": {"Johnston.Morfin.%w+;1h:12h": [[10,2,0]]\n}\n}'))
    assert_equal(string.find(m.graph("Johnston.Morfin.Jamal",{level=1,count=2}),'{"version": 3,\n"data": {"Johnston.Morfin.%w+;1h:12h": [[10,2,0]]\n,"Johnston.Morfin.%w+;1m:1h": [[10,2,0]]\n}\n}'))
    --MAX_CACHE_SIZE = 1
    m.process("Johnston.Morfin.Jamal.Marcela.Emilia.Zulema 5 10")
    m.process("Johnston.Emilia.Sweet-Nuthin 78 300")
    assert_equal(string.find(m.graph("Johnston.Morfin.Jamal",{level=1,count=1}),'{"version": 3,\n"data": {"Johnston.Morfin.%w+;1h:12h": [[15,3,0]]\n}\n}'))
    assert_equal(string.find(m.graph("Johnston.Morfin.Jamal",{level=1,count=2}),'{"version": 3,\n"data": {"Johnston.Morfin.%w+;1h:12h": [[15,3,0]]\n,"Johnston.Morfin.%w+;1m:1h": [[15,3,0]]\n}\n}'))
  end

  for_each_db("test_caching",helper)
end

function test_sparse_latest()
  local seq = sparse_sequence("beer.ale;1m:1h")

  seq.update(0,1,1)
  assert_equal(0,seq.slots()[1]._timestamp)

  seq.update(63,2,2)
  assert_equal(60,seq.slots()[1]._timestamp)
  assert_equal(2,seq.slots()[1]._hits)
  seq.update(3663,3,3)
  assert_equal(3660,seq.slots()[1]._timestamp)
  assert_equal(3,seq.slots()[1]._hits)
  assert_nil(seq.update(60,4,4))

  seq.update(141,5,5)
  assert_equal(120,seq.slots()[1]._timestamp)
  assert_equal(5,seq.slots()[1]._sum)
  seq.update(3687,6,6)
  assert_equal(9,seq.slots()[2]._sum)
end

function test_table_size()
  assert_equal(0,table_size({}))
  assert_equal(1,table_size({1}))
  assert_equal(1,table_size({a=1}))
  assert_equal(2,table_size({a=1,b=2}))
end

function test_bad_input_lines()
  local function helper(m)
    m.configure(table_itr({"beer.ale 60s:12h 1h:30d","beer.ale 60s:24h"}))
    m.process("beer.ale.pale.012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789 7 4")
    m.process("beer.ale.;brown 6 54")
    m.process("6 54")

    assert_equal('{"version": 4,\n"data": {}\n}',m.graph("beer.ale;1m:12h"))

    m.process("beer.al e.pale 1 1446711103")
    assert_equal('{"version": 4,\n"data": {}\n}',m.graph("beer.ale;1m:12h"))
  end
  for_each_db("test_bad_input_lines",helper)
end

function test_concatenated_lines()
  local line = "beer.ale.brown 27 1427502724 9beer.stout.1.total 19 1427392373"
  local items,t = parse_input_line(line)

  assert_nil(legit_input_line(items[1],items[2],items[3],items[4]))
end

function test_uniq_factories()
  local function helper(m)
    m.configure(table_itr({"beer.ale 60s:12h 1h:30d 60s:12h 1h:30d 60s:12h 1h:30d","beer.ale 60s:24h"}))
    local factories = m.get_factories()
    assert_equal(3,table_size(factories["beer.ale"].rps))
    assert_equal(60,factories["beer.ale"].rps[1][1])
    assert_equal(12*60*60,factories["beer.ale"].rps[1][2])
  end
  for_each_db("test_uniq_factories",helper)
end

function test_distinct_prefixes()
  assert_nil(distinct_prefixes(nil))
  assert_equal(t2s({"cruel","hello","world"}),t2s(distinct_prefixes({"world","hello","cruel"})))
  assert_equal(t2s({"cruel","hello","world"}),t2s(distinct_prefixes({"world","hello","cruel","hello there"})))
  assert_equal(t2s({"cruel","hell","world"}),t2s(distinct_prefixes({"world","hello","cruel","hell"})))
  assert_equal(t2s({"cruel","hello","hoopla","world"}),t2s(distinct_prefixes({"world","hello","cruel","hoopla"})))
end

function test_drop_one_level()
  assert_nil(drop_one_level(nil))
  assert_equal("hello.cruel",drop_one_level("hello.cruel.world"))
  assert_equal("hello.cruel.",drop_one_level("hello.cruel..world"))
  assert_equal("hello",drop_one_level("hello.cruelworld"))
  assert_equal("",drop_one_level("hellocruelworld"))
  assert_equal("",drop_one_level(""))
end

function test_trim_to_level()
  assert_nil(trim_to_level(nil))
  assert_equal("hello.cruel",trim_to_level("hello.cruel.world","hello",1))
  assert_equal("hello.cruel.world",trim_to_level("hello.cruel.world.again","hello",2))
  assert_equal("hello.cruel.world",trim_to_level("hello.cruel.world.again","hello.cruel",1))
  assert_equal("hello.cruel.world",trim_to_level("hello.cruel.world","hello",2))
  assert_equal("hello.cruel.world",trim_to_level("hello.cruel.world","hello",4))
  assert_nil(trim_to_level("hello.cruel.world","bool",1))
  assert_equal("Johnston.Morfin.Jamal",trim_to_level("Johnston.Morfin.Jamal.Marcela.Emilia.Zulema;1h:12h","Johnston.Morfin",1))
  assert_equal("Johnston.Morfin.Jamal.Marcela",trim_to_level("Johnston.Morfin.Jamal.Marcela.Emilia.Zulema;1h:12h","Johnston.Morfin",2))
--  assert_equal("hello.cruel.",drop_one_level("hello.cruel..world"))
--  assert_equal("hello",drop_one_level("hello.cruelworld"))
--  assert_equal("",drop_one_level("hellocruelworld"))
--  assert_equal("",drop_one_level(""))
end

function test_in_memory_serialization()
  function helper(m)
    m.configure(n_lines(110,io.lines("./tests/fixtures/d_conf")))
    m.process("Johnston.Morfin.Jamal.Marcela.Emilia.Zulema 5 10")
    m.process("Johnston.Emilia.Sweet-Nuthin 78 300")
    local gr = m.graph("Johnston.Morfin.Jamal",{level=1,count=1,in_memory=true})
    if gr["Johnston.Morfin.Jamal;1h:12h"] then
      assert(arrays_equal({5,1,0},gr["Johnston.Morfin.Jamal;1h:12h"][1]))
    end
    gr = m.graph("Johnston.Emilia.Sweet-Nuthin",{level=1,count=1,in_memory=true})
    if gr["Johnston.Emilia.Sweet-Nuthin;1h:12h"] then
      assert(arrays_equal({78,1,0},gr["Johnston.Emilia.Sweet-Nuthin;1h:12h"][1]))
    end
  end
  for_each_db("test_in_memory_serialization",helper)
end

function test_find_keys()
  local function helper(m)
    m.configure(n_lines(110,io.lines("./tests/fixtures/d_conf")))
    m.process("Johnston.Morfin.Jamal.Marcela.Emilia.Zulema 5 10")
    m.process("Johnston.Emilia.Sweet-Nuthin 78 300")
    assert(string.find(m.key("",{substring="Nuthin"}),"Sweet-Nuthin",1,true))
    assert(string.find(m.key("Johnston",{substring="Nuthin"}),"Sweet-Nuthin",1,true))
    assert_nil(string.find(m.key("Johnston",{substring="nothing"}),"Sweet-Nuthin",1,true))
    assert_nil(string.find(m.key("Johnston.Emilia",{substring="Jama"}),"Jamal",1,true))
    assert(string.find(m.key("Johnston.Morfin.Jamal.Marcela",{substring="ulem"}),"Zulema",1,true))
    assert_nil(string.find(m.key("mal.Mar",{substring=true}),"Nuthin",1,true))
    assert(string.find(m.key("",{substring="lia.Sw"}),"Nuthin",1,true))
  end
  for_each_db("test_find_keys",helper)
end

function test_hits_provided()
  local function helper(m)
    m.configure(n_lines(110,io.lines("./tests/fixtures/d_conf")))
    m.process("Johnston.Morfin.Jamal.Marcela.Emilia.Zulema 8 10 4")
    m.process("Johnston.Morfin.Jamal.Marcela.Emilia.Zulema 8 10 4")
    m.process("Johnston.Emilia.Sweet-Nuthin 50 300 100")
    local gr = m.graph("Johnston.Morfin.Jamal.Marcela.Emilia",{level=1,in_memory=true,stat="average"})
    assert(arrays_equal({2,8,0},gr["Johnston.Morfin.Jamal.Marcela.Emilia;1h:12h"][1]))
    gr = m.graph("Johnston.Morfin.Jamal.Marcela.Emilia",{level=1,in_memory=true})
    assert(arrays_equal({16,8,0},gr["Johnston.Morfin.Jamal.Marcela.Emilia;1h:12h"][1]))
    gr = m.graph("Johnston.Emilia.Sweet-Nuthin",{level=1,count=1,in_memory=true,stat="average"})
    assert(arrays_equal({0.5,100,0},gr["Johnston.Emilia.Sweet-Nuthin;1h:12h"][1]))
  end
  for_each_db("test_hits_provided",helper)
end

function test_factor()
  local function helper(m)
    m.configure(n_lines(110,io.lines("./tests/fixtures/d_conf")))
    m.process("Johnston.Morfin.Jamal.Marcela.Emilia.Zulema 8 10 4")
    m.process("Johnston.Emilia.Sweet-Nuthin 5 300 100")


    local gr = m.graph("Johnston.Morfin.Jamal.Marcela.Emilia",{level=1,in_memory=true,factor=10})
    assert(gr["Johnston.Morfin.Jamal.Marcela.Emilia;1h:12h"])
    assert(arrays_equal({0.8,4,0},gr["Johnston.Morfin.Jamal.Marcela.Emilia;1h:12h"][1]))
    gr = m.graph("Johnston.Morfin.Jamal.Marcela.Emilia",{level=1,in_memory=true})
    assert(arrays_equal({8,4,0},gr["Johnston.Morfin.Jamal.Marcela.Emilia;1h:12h"][1]))
    gr = m.graph("Johnston.Emilia.Sweet-Nuthin",{level=1,count=1,in_memory=true,factor=100})
    assert(arrays_equal({0.05,100,0},gr["Johnston.Emilia.Sweet-Nuthin;1h:12h"][1]))
  end
  for_each_db("test_factor",helper)

end

function test_same_prefix()
  local function helper(m)
    m.configure(table_itr({"beer 60s:12h 1h:30d","bee 1h:30d"}))
    m.process("beer.ale.pale 7 4")

    local gr = m.graph("beer",{})
    assert(string.find(gr,'"beer;1h:30d": [[7,1,0]]',1,true)) -- both bee and beer define 1h:30d
    assert(string.find(gr,'"beer;1m:12h": [[7,1,0]]',1,true),gr)
    gr = m.graph("beer.ale.pale",{})
    assert(string.find(gr,'"beer.ale.pale;1h:30d": [[7,1,0]]',1,true)) -- both bee and beer define 1h:30d
    assert(string.find(gr,'"beer.ale.pale;1m:12h": [[7,1,0]]',1,true))
    assert_nil(string.find(gr,'"beer;1m:1d": [[7,1,0]]',1,true))
  end
  for_each_db("test_same_prefix",helper)
end

function test_time_now()
  local function helper(m)
    m.configure(table_itr({"beer 60s:12h 1h:30d","bee 1h:30d"}))
    -- there is a slight possibility that the tests will fail if the current time is changed between the
    -- 1st and the 3rd call to os.time AND we switch to the next bucket. We'll take that chance
    local _,now1 = calculate_idx(os.time(),60*60,30*24*60)
    local _,now2 = calculate_idx(os.time(),60,12*60)
    m.process("beer.ale.pale 7 @now")

    local gr = m.graph("beer",{})
    assert(string.find(gr,'"beer;1h:30d": [[7,1,'..now1..']]',1,true))
    assert(string.find(gr,'"beer;1m:12h": [[7,1,'..now2..']]',1,true))
  end
  for_each_db("test_time_now",helper)
end

function test_filter()
  local function helper(m)
    m.configure(table_itr({"beer 60s:1h"}))
    set_hard_coded_time(0)
    local now = time_now()
    m.process("beer.ale.pale 1 "..(now+0))
    m.process("beer.ale.pale 2 "..(now+60))
    m.process("beer.ale.pale 4 "..(now+120))
    local gr = m.graph("beer",{filter="now"})
    assert(string.find(gr,'%[%[1,1,%d+%],%[2,1,%d+%],%[4,1,%d+%]'))
    m.process("beer.ale.pale 8 "..3780)
    set_hard_coded_time(4000)
    gr = m.graph("beer",{filter="now"})
    assert(string.find(gr,'%[%[8,1,%d+%]'))
    set_hard_coded_time(nil)
  end
  for_each_db("test_filter_now",helper)
end

function test_zero_sum_latest()
  local function helper(m)
    m.configure(table_itr({"beer 60s:1h"}))
    set_hard_coded_time(0)
    local now = time_now()
    m.process("beer.ale.pale 1 "..(now+0))
    m.process("beer.ale.pale 2 "..(now+60))
    m.process("beer.ale.pale 4 "..(now+120))
    assert(string.find(m.latest("beer.ale.pale;1m:1h"),"[4,1,120]",1,true))
    m.process("beer.ale.pale 0 "..(now+122))
    assert(string.find(m.latest("beer.ale.pale;1m:1h"),"[4,1,120]",1,true))
    m.process("beer.ale.pale 0 "..(now+190))
    assert(string.find(m.latest("beer.ale.pale;1m:1h"),"[]",1,true))
    set_hard_coded_time(nil)
  end
  if not ZERO_NOT_PROCESSED then
    for_each_db("test_zero_sum_latest",helper)
  end
end

function test_factory_types()
  local function helper(m)
    m.configure(table_itr({"beer 60s:1h gauge"}))
    set_hard_coded_time(0)
    local now = time_now()
    m.process("beer.ale.pale 1 "..(now+0))
    m.process("beer.ale.pale 2 "..(now+60))
    m.process("beer.ale.pale 4 "..(now+120))
    m.process("beer.ale.pale 8 "..(now+120))
    --    print(m.latest("beer.ale.pale;1m:1h"))
    m.flush_cache()
    assert(string.find(m.latest("beer.ale.pale;1m:1h"),"[8,1,120]",1,true))
    set_hard_coded_time(nil)
  end
  for_each_db("test_factory_types",helper)
end

function test_factory_suffix()
  local function helper(m)
    set_hard_coded_time(0)
    local now = time_now()
    m.configure(table_itr({"wine$ 60s:1h"}))
    m.process("red.wine 1 "..(now+0))
    m.process("white.wine 2 "..(now+60))
    m.process("red.wine.chilled 4 "..(now+120))

    assert(string.find(m.latest("red.wine;1m:1h"),"[1,1,0]",1,true))
    assert(string.find(m.latest("white.wine;1m:1h"),"[2,1,60]",1,true))
    assert(string.find(m.latest("red.wine.chilled;1m:1h"),'"data": {}',1,true))

    set_hard_coded_time(nil)
  end
  for_each_db("test_factory_suffix",helper)
end

function test_factory_prefix()
  local function helper(m)
    m.configure(table_itr({":pale 60s:1h"}))
    set_hard_coded_time(0)
    local now = time_now()

    m.process("beer.ale.pale 1 "..(now+0))
    m.process("beer.ale.pale 2 "..(now+60))
    m.process("beer.ale.pale 4 "..(now+120))

    assert(string.find(m.graph("beer.ale.pale;1m:1h"),"[4,1,120]",1,true))
    set_hard_coded_time(nil)
  end
  for_each_db("test_factory_prefix",helper)
end

function test_factory_max()
  local function helper(m)
    set_hard_coded_time(0)
    local now = time_now()

    m.configure(table_itr({"wine$ 60s:1h max"}))
    m.process("red.wine 1 "..(now+0))
    m.process("red.wine 2 "..(now+30))
    m.process("red.wine 4 "..(now+40))
    assert(string.find(m.latest("red.wine;1m:1h"),"[4,1,0]",1,true))
    set_hard_coded_time(nil)
  end
  for_each_db("test_factory_max",helper)
end


function test_factory_min()
  local function helper(m)
    set_hard_coded_time(0)
    local now = time_now()
    m.configure(table_itr({":white 60s:1h min"}))
    m.process("white.wine 1 "..(now+0))
    m.process("white.wine 2 "..(now+30))
    m.process("white.wine 1 "..(now+200))
    m.process("white.wine 8 "..(now+180))

    assert(string.find(m.latest("white.wine;1m:1h"),"[1,1,180]",1,true),m.latest("white.wine;1m:1h"))

    set_hard_coded_time(nil)
  end
  for_each_db("test_factory_min",helper)
end

function test_factory_log()
  local function helper(m)
    set_hard_coded_time(0)
    local now = time_now()
    m.configure(table_itr({":wine 60s:1h 10m:24h log"}))
    m.process("white.wine 1 "..(now+0))
    m.process("white.wine 2 "..(now+30))
    m.process("white.wine 1 "..(now+200))
    m.process("white.wine 8 "..(now+180))
    m.process("white.wine 64 "..(now+364))

    assert(string.find(m.latest("white.wine;1m:1h"),"[64,1,360]",1,true))
    assert(string.find(m.graph("log=white.wine.1;1m:1h"),"[1,1,0]",1,true))

    -- we have two log hits. one at the 0 bucket and the other at the 180 one
    assert(string.find(m.graph("log=white.wine.0;1m:1h"),"[1,1,180]",1,true))
    assert(string.find(m.graph("log=white.wine.0;1m:1h"),"[1,1,0]",1,true))

    assert(string.find(m.graph("log=white.wine.4;1m:1h"),'"data": {}',1,true))
    assert(string.find(m.graph("log=white.wine.6;1m:1h"),"[1,1,360]",1,true))

    assert(string.find(m.graph("log=white.wine.0;10m:1d"),"[2,2,0]",1,true))
    assert(string.find(m.graph("log=white.wine.6;10m:1d"),"[1,1,0]",1,true))

    set_hard_coded_time(nil)
  end
  for_each_db("test_factory_log",helper)
end

function test_factory_with_factor()
  local function helper(m)
    set_hard_coded_time(0)
    local now = time_now()
    m.configure(table_itr({":alcohol_pct 60s:1h 10m:24h gauge centi"}))
    m.process("wine.white.alcohol_pct 12.87 "..now)
    m.process("wine.white.alcohol_pct 13.11 "..now+1)
    m.process("wine.red.alcohol_pct 11.41 "..now)
    m.process("wine.rose.alcohol_pct 10.444 "..now)

    assert(string.find(m.graph("wine.white.alcohol_pct;10m:1d"),"13.11",1,true))
    assert(string.find(m.graph("wine.red.alcohol_pct;10m:1d"),"11.41",1,true))
    assert(string.find(m.graph("wine.rose.alcohol_pct;10m:1d"),"10.44",1,true))
    set_hard_coded_time(nil)
  end
  for_each_db("test_factory_with_factor",helper)
end

function test_factor_with_unit()
  local function helper(m)
    set_hard_coded_time(0)
    local now = time_now()
    m.configure(table_itr({"white 60s:1h 10m:24h milli %"}))
    m.process("white.wine 0.1 "..now)
    m.process("white.wine 0.02 "..(now+30))
    m.process("white.wine 1 "..(now+200))
    m.process("white.wine 0.008 "..(now+180))
    m.process("white.wine 64 "..(now+364))

    assert(string.find(m.latest("white.wine;1m:1h"),"[64.0,1,360]",1,true),m.graph("white.wine;1m:1h"))
    assert(string.find(m.graph("white.wine;1m:1h"),"[0.12,2,0]",1,true),m.graph("white.wine;1m:1h"))
    assert(string.find(m.graph("white.wine;1m:1h"),'"units": {"white.wine;1m:1h": "%"}',1,true))

    set_hard_coded_time(nil)
  end
  for_each_db("test_factory_with_unit",helper)
end

function test_parent_nodes()
    local function helper(m)
      m.configure(table_itr({"beer 60s:1h gauge"}))
      set_hard_coded_time(0)
      local now = time_now()
      m.process("beer.ale.pale 1 "..now)
      m.process("beer.ale.pale 2 "..(now+60))
      m.process("beer.ale.pale 4 "..(now+120))
      m.process("beer.ale.pale 8 "..(now+120))

      assert(string.find(m.latest("beer.ale.pale;1m:1h"),"[8,1,120]",1,true))
      local k = m.key("beer",{level=2})
      assert(string.find(k,"beer;",1,true),k)
      assert(string.find(k,"beer.ale;",1,true))
      local g = m.graph("beer",{level=2})
      assert(string.find(g,'"beer;1m:1h": []',1,true),g)

      set_hard_coded_time(nil)
    end

  for_each_db("test_parent_nodes",helper)
end

function test_factory_export_config_for_metric()
  local function helper(m)
    m.configure(table_itr({":wine 60s:1h 10m:24h log","beer 5m:3d 1d:2y"}))
    assert(string.find(m.export_configuration("wine.red"),'"retentions":.+"1m:1h"'))
    assert(string.find(m.export_configuration("wine.red"),'"retentions":.+"10m:1d"'))
    assert(string.find(m.export_configuration("beer.ale"),'"retentions":.+"5m:3d'))
    assert_nil(string.find(m.export_configuration("beer.ale/wine.red"),'"beer.ale":{ "retentions":.+"1m:1h'))
    assert(string.find(m.export_configuration("beer.ale/wine.red"),'"beer.ale":{"retentions":.+"1d:2y'))
    local now = time_now()
    m.process("beer.ale.pale 8 "..(now+120))
    assert(string.find(m.export_configuration("beer.ale.pale;1d:2y"),'"retentions":.+"5m:3d'))
  end
  for_each_db("test_factory_export_config_for_metric",helper)
end

function test_key_glob()
  local function helper(m)
    m.configure(table_itr({"beer. 60s:12h 1h:30d","beer 3m:1h"}))
    m.process({"beer.ale.mild 20 74857843",
               "beer.ale.mild.bitter 20 74857843",
               "beer.ale.mild.sweet 30 74857843",
               "beer.lager.mild 720 74857843",
               "beer.lager.mild.bitter 72 74857843",
               "beer.lager.mild.sweet 74 74857843"
              })
    local keys = m.graph("beer.*.mild",{level=0,count=100,in_memory=true})
    assert_equal(6,table_size(keys))
    keys = m.key("beer.*.mild;1m:12h",{level=2,count=100,in_memory=true})
    assert_equal(2,table_size(keys))
    keys = m.key("beer.*.mild;1h:30d",{level=2,count=100,in_memory=true})
    assert_equal(2,table_size(keys))
    keys = m.key("beer.lager.mild.*;1h:30d",{level=2,count=100,in_memory=true})
    assert_equal(2,table_size(keys))
    keys = m.key("beer.*.mild",{level=0,count=100,in_memory=true})
    assert_equal(6,table_size(keys))
    keys = m.graph("beer.*.*.",{level=1,count=100,in_memory=true})
    assert_equal(12,table_size(keys))
    keys = m.graph("beer.*.*.",{level=1,count=100,in_memory=true})
    assert_equal(12,table_size(keys))

  end

  for_each_db("test_key_glob",helper)
end

function test_fts()
  local function helper(m)
    m.configure(table_itr({"beer. 60s:12h 1h:30d","beer 3m:1h"}))
    m.process({"beer.ale.mild 20 74857843",
               "beer.ale.mild.bitter 20 74857843",
               "beer.ale.mild.sweet 30 74857843",
               "beer.lager.mild 720 74857843",
               "beer.lager.mild.bitter 72 74857843",
               "beer.lager.mild.sweet 74 74857843"
              })
    local keys = m.key("mild",{level=0,count=100,in_memory=true,search=true})
    assert_equal(6,table_size(keys))
    keys = m.key("ale",{level=0,count=100,in_memory=true,search=true})
    assert_equal(4,table_size(keys))
    keys = m.key("sweet",{level=0,count=100,in_memory=true,search=true})
    assert_equal(2,table_size(keys))
    keys = m.key("sour",{level=0,count=100,in_memory=true,search=true})
    assert_equal(0,table_size(keys))

  end

  for_each_db("test_fts",helper)
end


function test_parent_and_dashes()
  local function helper(m)
    m.configure(table_itr({"beer. parent",":.ale-mild 3m:1h"}))
    m.process({"beer.ale-mild 20 74857843",
               "beer.ale-mild.bitter 20 74857843",
               "beer.ale-mild.sweet 30 74857843",
               "beer.lager.mild 720 74857843",
               "beer.lager.mild.bitter 72 74857843",
               "beer.lager.mild.sweet 74 74857843"
              })
    assert(string.find(m.graph("beer.ale-mild.bitter",{level=1}),"[20,1,74857680]",1,true))
  end

  for_each_db("test_parent_and_dashes",helper)
end

function test_full_match()
    local function helper(m)
  -- TODO test prefix and full matches for matching_keys
      m.configure(table_itr({"beer. parent",":.ale-mild 3m:1h"}))
      m.process({"beer.ale-mild 20 74857843",
                 "beer.ale-mild.bitter 20 74857843",
                 "beer.ale-mild.sweet 30 74857843",
                 "beer.lager.mild 720 74857843",
                 "beer.lager.mild.bitter 72 74857843",
                 "beer.lager.mild.sweet 74 74857843"
      })
      local keys = m.key("beer",{level=1,count=100,in_memory=true,search=true})
      assert_equal(3,table_size(keys))
      keys = m.key("beer",{level=2,count=100,in_memory=true,prefix=true})
      assert_equal(1+3+6,table_size(keys))
      keys = m.key("be",{level=1,count=100,in_memory=true,search=true,prefix=false})
      assert_equal(0,table_size(keys))
    end
    for_each_db("test_full_match",helper)
end

function test_ditto()
    local function helper(m)
      m.configure(table_itr({"beer 60s:1h"}))
      set_hard_coded_time(0)
      local now = time_now()
      m.process("beer.ale.pale 1 "..(now+0))
      m.process("+ 10 "..(now+0))
      m.process("+ 20 "..(now+0))
      m.process("beer.ale.pale 2 "..(now+60))
      m.process("+ 80 "..(now+60))
      m.process("beer.lager 4 "..(now+120))
      m.process("beer.ale.pale 4 "..(now+120))
      m.process("+ 4 "..(now+120))

      assert(string.find(m.graph("beer.ale.pale",{level=1}),"[31,3,0]",1,true))
      assert(string.find(m.graph("beer.ale.pale",{level=1}),"[82,2,60]",1,true))
      assert(string.find(m.graph("beer.ale.pale",{level=1}),"[8,2,120]",1,true))
      assert(string.find(m.graph("beer.lager",{level=1}),"[4,1,120]",1,true))
      set_hard_coded_time(nil)
    end
    for_each_db("test_full_match",helper)
end

--verbose_log(true)
--profiler.start("profiler.out")
