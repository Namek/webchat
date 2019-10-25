const app = Elm.Main.init({
  node: document.getElementById("elm-main"),
  flags: {}
});

app.ports.createSubscriptions.subscribe(function(subscription) {
  const ws = new WebSocket("ws://" + document.location.host + "/graphql", 'graphql-ws')
  const sendJson = json => ws.send(JSON.stringify(json))

  ws.onopen = evt => {
    sendJson({ type: 'connection_init', payload: {} })
    sendJson({ type: 'start', id: "1", payload: {
      extensions: {},
      operationName: null,
      query: subscription,
      variables: {}
    }})
  }
  ws.onmessage = evt => {
    var msg = JSON.parse(evt.data)
    console.log(msg)
    if (msg.type == 'connection_ack') {
      app.ports.socketStatusConnected.send(null)
    }
    else if (msg.type == 'data') {
      if (msg.payload.data.chatStateUpdated) {
        app.ports.gotChatStateUpdate.send(msg.payload)
      }
    }
  }
  ws.onerror = evt => console.log(evt)
  ws.onclose = evt => {
    // TODO socketStatusReconnecting
  }
})
