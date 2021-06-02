let socket = new WebSocket(location.origin.replace(/^http/, 'ws'));

let sendInput = function (inputstr, content) {
  //console.log("pressed a button: " + inputstr);
  let messageToGame = {
      messageType: 'PLAYER_INPUT',
      message: inputstr,
      content: content,
      method: "player_input"
  };
  socket.send(JSON.stringify(messageToGame));
}

//Detect different touch gestures 
//ROTATION (src=https://codepen.io/zingchart/pen/GqWVww)
let target = document.getElementById('wrapper');
let region = new ZingTouch.Region(target);

region.bind(target, 'rotate', function(e) {
  console.log("rotating");
  sendInput('rotate',Math.floor(e.detail.distanceFromLast))
});

//TWO FINGER TAP (src=https://codepen.io/zingchart/pen/pbeMVv)
let TwoFingerTap = new ZingTouch.Tap({
  numInputs: 2,
  maxDelay: 1000
});

region.bind(target, TwoFingerTap, function(e){
  //console.log("tapping");
  sendInput('doubleTap',Math.floor(e.detail.interval))
})

//LONG TAP
let longTap = new ZingTouch.Tap({
  maxDelay: 2000
})
region.bind(target, longTap, function(e){
  //console.log("tapping");
  if(Math.floor(e.detail.interval)>500){
    //console.log(e.detail.events[0].clientX)
    sendInput('longTap',JSON.stringify({X:e.detail.events[0].clientX,Y:e.detail.events[0].clientY}))
  }
})
//SWIPE
region.bind(target, 'swipe', function(e){
  console.log("swiping");
  if(e.detail.data[0].velocity > 2){
    sendInput('swipe',Math.floor(e.detail.data[0].velocity)*Math.floor(e.detail.data[0].currentDirection))
  }
})
//PANNING
/*
let customPan = new ZingTouch.Pan({
  theshold: 200,
  numInputs: 2,
})
region.bind(target,customPan, function(e){
  console.log("panning")
  if(e.detail.data[0].distanceFromOrigin>200){
    sendInput('pan',Math.floor(e.detail.data[0].distanceFromOrigin))
  }
})
*/