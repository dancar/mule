Ext.define "Muleview.view.MuleChartPanel",
  extend: "Ext.panel.Panel"
  layout: "fit"

  initComponent: ->
    @chart = Ext.create "Muleview.view.MuleChart",
      showAreas: true
      keys: @keys
      alerts: @alerts
      store: @store
    @items = [@chart]

    @bbar =
      layout:
        type: "hbox"
      items: [
          slider = Ext.create "Muleview.view.ZoomSlider",
            flex: 1
            store: @store
        ,
          xtype: "button"
          text: "Reset"
          handler: ->
            slider.reset()
      ]
    @callParent()