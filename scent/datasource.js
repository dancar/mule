// all data items on the page come from here. We can work in mockup or real world mode
const NOP = function() {}

function mule_mockup () {
  var fixtures_scripts = ["config","key","graph","alert"];
  var fixtures = {};
  const user = "Shmul the mule";
  ns=$.initNamespaceStorage('mule: ');

  save(user,"recent",
       ["brave.backend;1d:2y",
        "event.activation_failed;5m:3d",
        "kashmir_report_db_storer;5m:3d"],function() {});
  var v = $.localStorage.get(user);
  if ( !v ) {
    save(user,"persistent",
         {favorites:["event.bho_blocked_blacklisted;1h:90d",
                     "event.browser_apc_detected;1h:90d",
                     "event.buka_mr_result;1d:2y"],
          dashboards:{},
         },function() {});
  }

  function load_fixture(name_,path_) {
    $.ajax({
      url: "./fixtures/"+name_+".json",
      async: false,
      dataType: 'json',
      success: function (response_) {
        fixtures[name_] = response_.data;
      }
    });
  }

  for (var f in fixtures_scripts) {
    load_fixture(fixtures_scripts[f]);
  }

  function delayed(func_) {
    $.doTimeout(2,func_);
  }

  function config(callback_) {
    delayed(function() {
      callback_(fixtures["config"]);
    });
  }

  function graph(graph_name_,callback_) {
    delayed(function() {
      var gr = fixtures["graph"];
      callback_(gr[graph_name_] || gr["event_processor_us;1d:2y"]);
    });
  }

  function key(key_,callback_) {
    delayed(function() {
      var all_keys = fixtures["key"];
      var k = $.map(all_keys,function(element,index) {return index});
      var rv = []
      if ( key_=="" ) { // no dots -> bring top level only
        $.each(k,function(idx,e) {
          if ( /^[\w-]+;/.test(e) )
            rv.push(e);
        });
      } else {
        var normalized_input = key_[key_.length-1]=='.' ? key_ : key_+".";
        var re = new RegExp("^" + key_+"[\\w;:-]*");
        $.each(k,function(idx,e) {
          if ( re.test(e) )
            rv.push(e);
        });
      }
      callback_(rv);
    });
  }

  function alerts(callback_) {
    delayed(function() {
      callback_(fixtures["alert"]);
    });
  }

  // if key == "persistent" the data is taken from the server, otherwise session storage
  // is used
  function load(user_,key_,callback_) {
    delayed(function() {
      if (key_=="persistent" ) {
        callback_($.localStorage.get(user_+".persistent"));
      } else {
        callback_($.sessionStorage.get(user_+"."+key_));
      }
    });
  }

  function save(user_,key_,data_,callback_) {
    delayed(function() {
      if (key_=="persistent" ) {
        $.localStorage.set(user_+".persistent",data_);
        if ( callback_ ) {
          callback_();
        }
        return;
      }
      $.sessionStorage.set(user_+"."+key_,data_);
      if ( callback_ ) {
        callback_();
      }
    });
  }

  return {
    config : config,
    graph : graph,
    key : key,
    alerts : alerts,
    load: load,
    save: save,
  }


};

function mule_ds() {
  var ns = $.initNamespaceStorage('mule');
  const user = "Shmul the mule";
  const mule_server = "http://v2.mule.trusteer.net/mule/api";
  var cache = new Cache(100);


  function delayed(func_) {
    $.doTimeout(2,func_);
  }

  function mule_get(resource_,callback_,cache_period_) {
    var cached =cache.getItem(resource_);
    if ( cached ) {
      //console.log("cache hit: %s",resource_);
      delayed(callback_(cached));
      return;
    }

    $.ajax({
      url: mule_server+resource_,
      async: true,
      dataType: 'json',
      success: function (response_) {
        if ( cache_period_ ) {
          cache.setItem(resource_,response_.data,{expirationAbsolute: null,
                                                  expirationSliding: cache_period_,
                                                  priority: Cache.Priority.HIGH,
                                                  callback: function(k, v) {
                                                    //console.log("cache remove: %s",k);
                                                  }
                                                 });
        }
        callback_(response_.data);
      },
      error: function(xhr_,internal_error_,http_status_) {
        console.log("%s <%s,%s>",resource_,internal_error_,http_status_);
      }
    });
  }

  function config(callback_) {
    mule_get("/config",callback_,120);
  }

  function graph(graph_,callback_) {
    mule_get("/graph/"+graph_,function(data_) {
      callback_(data_[graph_]);
    },30);
  }

  function key(key_,callback_) {
    if (key_[key_.length-1]=='.' ) {
      key_ = key_.slice(0,key_.length-1);
    }
    mule_get("/key/"+key_+"?level=1",
             function(keys_) {
               var k = $.map(keys_,function(element,index) {return index});
               var rv = []
               if ( key_=="" ) { // no dots -> bring top level only
                 $.each(k,function(idx,e) {
                   if ( /^[\w-]+;/.test(e) )
                     rv.push(e);
                 });
               } else {
                 var normalized_input = key_[key_.length-1]=='.' ? key_ : key_+".";
                 var re = new RegExp("^" + key_+"[\\w;:-]*");
                 $.each(k,function(idx,e) {
                   if ( re.test(e) )
                     rv.push(e);
                 });
               }
               callback_(rv);
             },60);
  }

  function alerts(callback_) {
    mule_get("/alert",callback_,60);
  }

  // if key == "persistent" the data is taken from the server, otherwise session storage
  // is used
  function load(user_,key_,callback_) {
    delayed(function() {
      try {
        if (key_=="persistent" ) {
          callback_(ns.localStorage.get(user_+".persistent"));
        } else {
          callback_(ns.sessionStorage.get(user_+"."+key_));
        }
      } catch(e){
        callback_(null);
      }
    });
  }

  function save(user_,key_,data_,callback_) {
    delayed(function() {
      if (key_=="persistent" ) {
        ns.localStorage.set(user_+".persistent",data_);
        if ( callback_ ) {
          callback_();
        }
        return;
      }
      ns.sessionStorage.set(user_+"."+key_,data_);
      if ( callback_ ) {
        callback_();
      }
    });
  }

  return {
    config : config,
    graph : graph,
    key : key,
    alerts : alerts,
    load: load,
    save: save,
  }

}

scent_ds = /\/test\//.test(location.href) ? mule_mockup() : mule_ds();
