function app() {
  var user = "Shmul the mule";
    var router = new Grapnel();


  const TIME_UNITS = {s:1, m:60, h:3600, d:3600*24, w:3600*24*7, y:3600*24*365};
  function timeunit_to_seconds(timeunit_) {
    var m = timeunit_.match(/^(\d+)(\w)$/);
    if ( !m[1] || !m[2] ) { return null; }
    var secs = TIME_UNITS[m[2]];
    var a = parseInt(m[1]);
    return a && secs ? secs*a : null;
  }

  function graph_split(graph_) {
    var m = graph_.match(/^([\w\.\-]+);(\d\w+):(\d\w+)$/);
    if ( !m || m.length!=4 ) { return null; }
    m.shift();
    return m;
  }

  function mule_config(callback_) {
    scent_ds.config(function(conf_) {
      callback_(jQuery.extend(true,{},conf_));
    });
  }

  function generate_other_graphs(graph_,callback_) {
    mule_config(function(conf_) {
      var m = graph_.match(/^([\w\-]+)\./);
      if ( !m || !m[1] ) { callback_(); }
      var c = conf_[m[1]];
      if ( !c ) { callback_(); }
      var gs = graph_split(graph_);
      if ( !gs ) { callback_(); }
      var i = c.indexOf(gs[1]+":"+gs[2]);
      if ( i!=-1 ) {
        c.splice(i,1);
      }
      for (var j=0; j<c.length; ++j) {
        c[j] = gs[0]+";"+c[j];
      }
      callback_(c);
    });
  }

  function graph_refresh_time(graph_) {
    var gs = graph_split(graph_);
    if ( !gs) { return null; }
    return timeunit_to_seconds(gs[1]);
  }

  function string_set_add(set_,key_) {
    set_ = set_ || {};
    set_[key_] = true;
    return set_;
  }

  function string_set_add_array(set_,keys_) {
    set_ = set_ || {};
    $.each(keys_,function(idx,k) {
      set_[k] = true;
    });
    return set_;
  }

  function string_set_keys(set_) {
    return $.map(set_ || {},function(key_,idx_) { return idx_; });
  }

  // --- application functions
  function box_header(type_,title_) {
    $("#"+type_+"-box-header-container").empty().html($.templates("#box-header-template").render([{name:""+type_+"",title:title_}]));
  }

  function setup_alerts_menu() {
    var template_data = [
      {Name: "Critical", name: "critical", indicator: "danger", color: "red"},
      {Name: "Warning", name: "warning", indicator: "warning", color: "orange"},
      {Name: "Anomaly", name: "anomaly", indicator: "info", color: "blue"},
      {Name: "Stale", name: "stale", indicator: "info", color: "light-blue"},
      {Name: "Normal", name: "normal", indicator: "success", color: "green"}
    ];
    $("#alerts-menu-container").html($.templates("#alerts-menu-template").render(template_data));
  }

  function update_alerts(category_to_show_) {
    scent_ds.alerts(function(raw_data_) {

      // 0-critical, 1-warning, 2-anomaly, 3-Stale, 4-Normal
      const lookup = {
        0: { title: "Critical", type: "critical"},
        1: { title: "Warning", type: "warning"},
        2: { title: "Anomaly", type: "anomaly"},
        3: { title: "Stale", type: "stale"},
        4: { title: "Normal", type: "normal"},
        critical: 0,
        warning: 1,
        anomaly: 2,
        stale: 3,
        normal: 4
      }

      var date_format = d3.time.format("%Y-%M-%d:%H%M%S");
      var alerts = [[],[],[],[],[]];
      for (n in raw_data_) {
        var current = raw_data_[n];
        var idx = -1;
        switch ( current[7] ) {
        case "CRITICAL LOW":
        case "CRITICAL HIGH": idx = 0; break;
        case "WARNING LOW":
        case "WARNING HIGH": idx = 1; break;
        case "stale": idx = 3; break;
        case "NORMAL": idx = 4; break;
        }
        if ( idx!=-1 ) {
          alerts[idx].push([n,current]);
        }
      }
      var anomalies = raw_data_["anomalies"];
      for (n in anomalies) {
        alerts[2].push([n,anomalies[n]]);
      }

      var template_data = [];
      var category_idx = lookup[category_to_show_];
      for (var i=0; i<5; ++i) {
        var len = alerts[i].length;
        var tr = lookup[i];
        $("#alert-menu-"+tr.type).text(len);
        if ( i!=category_idx ) {
          continue;
        }
        var d = [];
        for (var j=0; j<len; ++j) {
          if ( i==2 ) { //anomalies
            var cur = alerts[i][j][1];
            cur.sort();
            d.push({
              graph : alerts[i][j][0],
              time : date_format(new Date(cur[0]*1000)),
              type : "anomaly" // this is needed for jsrender's predicate in the loop
            });
          } else {
            var cur = alerts[i][j][1];
            d.push({
              graph : alerts[i][j][0],
              time : date_format(new Date(cur[8]*1000)),
              value : cur[6],
              crit_high : cur[3],
              warn_high : cur[2],
              warn_low : cur[1],
              crit_low : cur[0],
              stale : cur[5],
            });
          }
        }
        template_data.push({title:tr.title,type:tr.type,records:d});
      }

      var tr = lookup[category_idx];
      if ( tr ) {
        $("#alert-container").empty();
        $("#alert-container").html($.templates("#alert-template").render(template_data));
        $("#alert-"+tr.type).dataTable({order: [[ 2, "desc" ]]});
        box_header("alert",tr.title);
        $("#alert-box").show();
      }
    });
  }

  function teardown_alerts() {
    $("#alert-container").empty();
    $("#alert-box").hide();
  }

  function setup_menus() {
    function load_graphs_lists(list_name_,data_) {
      if ( data_ && data_.length>0 ) {
        var template_data = [];
        for (var d=0; d<data_.length; ++d) {
          template_data.push({idx:1+d, name:data_[d]});
        }
        $("#"+list_name_+"-container").empty().append($.templates("#"+list_name_+"-template").render(template_data));
      }
    }
    scent_ds.load(user,"persistent",function(persistent_) {
      var favorites = persistent_.favorites;
      var dashboards = persistent_.dashboards;
      load_graphs_lists("favorite",favorites);
      load_graphs_lists("dashboard",dashboards);
    });

    scent_ds.load(user,"recent",function(recent_) {
      load_graphs_lists("recent",recent_);
    });
  }
  function load_graph(name_,target_,no_modal_) {
    function callback(raw_data_) {
      var data = [];
      var m = 0;
      for (var rw in raw_data_) {
        var dt = raw_data_[rw][2];
        var v = raw_data_[rw][0];
        if ( dt>100000 ) {
          data.push({x:dt, y:v});
        }
      };
      data.sort(function(a,b) { return a.x-b.x });

      var markers = [{
        'date': new Date('2014-05-01T00:00:00.000Z'),
        'label': 'Anomaly'
      }];

      var graph = new Rickshaw.Graph( {
        element: document.querySelector(target_),
        renderer: 'line',
        series: [ {
          color: 'steelblue',
          name: '', // this is required to shoosh the 'undefined in the tooltop'
          data: data
        } ]
      } );

      const ticksTreatment = 'glow';
      var x_axis = new Rickshaw.Graph.Axis.Time( {
	      graph: graph,
	      ticksTreatment: ticksTreatment,
	      timeFixture: new Rickshaw.Fixtures.Time.Local()
      } );
      var y_axis = new Rickshaw.Graph.Axis.Y( {
        graph: graph,
        tickFormat: Rickshaw.Fixtures.Number.formatKMBT,
        ticksTreatment: ticksTreatment
      } );
      graph.render();

      /*
        var annotator = new Rickshaw.Graph.Annotate({
        graph: graph,
        element: document.querySelector(target_+'-timeline')
        });
        annotator.add(1423785600,"hello cruel world");
		    annotator.update();
      */

      if ( !no_modal_ ) {
        $(target_).on('click', function() {
          load_graph(name_,"#modal-body",true);
          var el = $("#modal-target");
          $("#modal-target").modal('show');
        });
        // cleanup
        $('#modal-target').on('hidden.bs.modal', function (e) {
          $("#modal-body").html("");
        });
      }
    }
    scent_ds.graph(name_,callback);
  }



  function setup_charts(id) {
    $("#charts-container").empty();

    var template = $.templates("#chart-template");
    var template_data = [];
    for (i=1; i<=6; ++i) {
      template_data.push({idx: i});
    }
    var d = template.render(template_data)
    $("#charts-container").append(d);
    for (i=1; i<=6; ++i) {
      var name = "chart-"+i;
      var g = i%2==0 ? "brave;5m:3d" : "kashmir_report_db_storer;1d:2y";
      load_graph(g,"#"+name);
    }
    box_header("charts",id);
    $("#charts-box").show();

    $("#modal-wide").empty();
    $(".modal-wide").on("show.bs.modal", function() {
      var height = $(window).height();
      $(this).find(".modal-body").css("max-height", height);
    });

  }

  function teardown_charts() {
    $("#charts-container").empty();
    $("#charts-box").hide();
  }

  function setup_search_keys() {
    $("#search-form").submit(function( event ) {
      router.navigate('/graph/'+$("#search-keys-input").val());
      event.preventDefault();
    });
    $("#search-keys-input").typeahead({
      source:function (query,process) {
        function callback(keys_) {
          if ( !this.scent_keys ) {
            this.scent_keys = string_set_add_array({},keys_);
          } else if ( query[query.length-1]=='.') {
            string_set_add_array(this.scent_keys,keys_);
          }
          process(string_set_keys(this.scent_keys));
        }

        if ( !this.scent_keys ) {
          scent_ds.key("",callback);
        } else if ( query[query.length-1]=='.') {
          scent_ds.key(query,callback);
        }
      },
      minLength: 0,
      items: 'all',
    });

  }

  function setup_graph(name_) {
    $("#graph-box").show();
    box_header("graph",name_);
  }

  function teardown_graph() {
    $("#graph-box").hide();
  }

  function run_tests() {
    QUnit.config.hidepassed = true;
    $(".content-wrapper").prepend("<div id='qunit'></div>");
    QUnit.test("utility functions", function( assert ) {
      assert.equal(timeunit_to_seconds("5m"),300);
      assert.equal(timeunit_to_seconds("1y"),60*60*24*365);
      assert.equal(timeunit_to_seconds("1d"),60*60*24);
      assert.deepEqual(graph_split("brave.frontend;1d:2y"),["brave.frontend","1d","2y"]);
      assert.deepEqual(graph_split("event.buka_mr_result;1h:90d"),["event.buka_mr_result","1h","90d"]);
      generate_other_graphs("kashmir_report_db_storer.sql_queries;1h:90d",
                            function(actual_) {
                              assert.deepEqual(actual_,
                                               ["kashmir_report_db_storer.sql_queries;5m:3d",
                                                "kashmir_report_db_storer.sql_queries;1d:2y"]);
                            });

      generate_other_graphs("malware_signature.foo.bar;1h:90d",
                            function(actual_) {
                              assert.deepEqual(actual_,
                                               ["malware_signature.foo.bar;1d:2y"]);
                            });

      generate_other_graphs("malware_signature.foo.bar;60d:90y",
                            function(actual_) {
                              assert.deepEqual(actual_,
                                               ["malware_signature.foo.bar;1h:90d","malware_signature.foo.bar;1d:2y"]);
                            });
      assert.equal(graph_refresh_time("malware_signature.foo.bar;1h:90d"),3600);
      assert.equal(graph_refresh_time("kashmir_report_db_storer.sql_queries;5m:3d"),300);
    });

    const expected = ["brave;1d:2y",
                      "brave;1h:90d",
                      "brave;5m:3d",
                      "brave.backend;1d:2y",
                      "brave.backend;1h:90d",
                      "brave.backend;5m:3d",
                      "brave.hrl_collect;1d:2y",
                      "brave.hrl_collect;1h:90d",
                      "brave.hrl_collect;5m:3d",
                      "brave.request;1d:2y",
                      "brave.request;1h:90d",
                      "brave.request;5m:3d",
                      "brave.frontend;1d:2y",
                      "brave.frontend;1h:90d",
                      "brave.frontend;5m:3d"];
    scent_ds.key("brave",function(actual_) {
      QUnit.test("key 1", function( assert ) {
        assert.deepEqual(actual_,expected);
      });
    });
    scent_ds.key("brave.",function(actual_) {
      QUnit.test("key 2", function( assert ) {
        assert.deepEqual(actual_,expected);
      });
    });
  }

  function set_title(title_) {
    $("title").text("Scent of a Mule | "+title_);
    $("#page-title").text(title_);
    $("#qunit > a").text(title_);
  }

  function setup_router() {

    function globals() {
      setup_menus();
      setup_alerts_menu();
      setup_search_keys();
      update_alerts(); // with no selected category it just updates the count
    }

    router.get(/(index.html)?/, function(req) {
      set_title("");
      var category = req.params.category;
      globals();
      teardown_alerts();
      teardown_charts();
      teardown_graph();
    });

    router.get('alert/:category', function(req) {
      set_title("Alert");
      var category = req.params.category;
      globals();
      teardown_charts();
      teardown_graph();
      update_alerts(category);
    });

    router.get('graph/:id', function(req) {
      globals();
      set_title("Graph");
      teardown_alerts();
      teardown_charts();
      var id = req.params.id;
      setup_graph(id);
    });

    router.get('dashboard/:id', function(req) {
      set_title("Dashboard");
      globals();
      var id = req.params.id;
      teardown_alerts();
      teardown_graph();
      setup_charts(id);
    });

    router.on('navigate', function(event){
      console.log('URL changed to %s', this.fragment.get());
    });
  }


  // call init functions


//  run_tests();
  setup_router();

}


$(app);
