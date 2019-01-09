create_manifest_channel = () ->
  App.manifest = App.cable.subscriptions.create "ManifestChannel",
    connected: ->
      # Called when the subscription is ready for use on the server

    disconnected: ->
      # Called when the subscription has been terminated by the server

    received: (data) ->
      # Called when there's incoming data on the websocket for this channel

$ ->
  if typeof current_provider_id != "undefined" 
    create_manifest_channel()
