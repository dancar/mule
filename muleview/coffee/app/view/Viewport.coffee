Ext.define "Muleview.view.Viewport",
  extend: "Ext.container.Viewport"
  layout: "border"
  items: [
      id: "leftPanel"
      xtype: "panel"
      layout: "border"
      region: "west"
      width: "20%"
      split: true
      collapsible: true
      items: [
          xtype: "treepanel"
          region: "center"
          id: "keysTree"
          title: "Available Keys"
          displayField: "name"
          useArrows: true
          rootVisible: false
        ,
          xtype: "tabpanel"
          region: "south"
          height: "40%"
          split: "true"
          collapsible: true
          collapsed: true
          title: "Options"
          items: [
              Ext.create("Muleview.view.AlertsEditor",
                id: "alertsEditor"
              )
            ,
              {
                xtype: "panel"
                title: "Event Labels"
              }
          ]
      ]
    ,
      id: "mainPanel"
      xtype: "tabpanel"
      title: "Main View"
      region: "center"
      layout: "fit"
      tools: [
          type: "maximize"
          id: "mainPanelMaximize"
        ,
          type: "restore"
          id: "mainPanelRestore"
          hidden: true
      ]
    ,
      id: "rightPanel"
      width: "20%"
      split: true
      xtype: "panel"
      region: "east"
      collapsible: true
      title: "Other Views"
      layout:
        type: "vbox"
        align: "stretch"
      defaults:
        flex: 1
  ]
