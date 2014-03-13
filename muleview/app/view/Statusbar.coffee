Ext.define "Muleview.view.Statusbar",
  extend: "Ext.toolbar.Toolbar"
  alias: "widget.MuleStatusbar"
  height: 25
  margin: 0
  border: false
  defaultText: "Ready"
  items: [
      id: "statusLabel"
      xtype: "label"
      flex: 1
      cls: "statusLabel" # needed to reduce CSS headache
      frame: true
      border: true
      value: "Hello world..."
      enable: false
    ,
      "-"
    ,
      id: "alertsSummaryTotal"
      alertState: "total"
      text: "Total Alerts: ?"
      toggleGroup: "alersSummaryStates"
    ,
      "-"
    ,
      id: "alertsSummaryCritical"
      alertState: "critical"
      iconCls: "alert-summary-critical"
      text: "Critical: ?"
      toggleGroup: "alersSummaryStates"
    ,
      "-"
    ,
      id: "alertsSummaryWarning"
      alertState: "warning"
      iconCls: "alert-summary-warning"
      text: "Warning: ?"
      toggleGroup: "alersSummaryStates"
    ,
      "-"
    ,
      id: "alertsSummaryNormal"
      alertState: "normal"
      iconCls: "alert-summary-normal"
      text: "Normal: ?"
      toggleGroup: "alersSummaryStates"
    ,
      "-"
    ,
      id: "alertsSummaryStale"
      alertState: "stale"
      iconCls: "alert-summary-stale"
      text: "Stale: ?"
      toggleGroup: "alersSummaryStates"
    ,
      "-"
    ,
      xtype: "button"
      id: "alertsSummaryRefresh"
      text: ""
      icon: "resources/default/images/refresh.png"
      tooltip: "Refresh Alerts Now"
      handler: ->
        Muleview.event "alertsChanged"
    ,
      "-"
    ,
      xtype: "container"
      flex: 1
      layout:
        type: "hbox"
        align: "middle"
      items: [
          xtype: "component"
          style: "margin-left: 25px"
          tpl: "Stats: " + ("<span class=statName>#{name}:</span> <span class=statValue>#{value}</span>" for value, name of {"{min}": "Min", "{max}": "Max", "{average}": "Average", "{last}": "Last Value", "{count}/{size}": "Showing"}).join(" ")
          id: "statusStats"
          flex: 1
        ,
          xtype: "progressbar"
          id: "statusProgressbar"
          animate: true
          height: 20
          width: 120
      ]
    ,
      icon: "resources/default/images/mule_icon.png"
      handler: ->
        Ext.MessageBox.show
          title: "About Mule"
          msg: "<p style=\"text-align:center\"><b>Mule</b> is an <a href=http://github.com/trusteer/mule>open-source</a> project written by <a href=mailto:shmul@trusteer.com>Shmulik Regev</a> & <a href=mailto:dan@carmon.org.il>Dan Carmon</a><br /></p>"
          buttons: Ext.Msg.OK
  ]
