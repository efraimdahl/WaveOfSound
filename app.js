'use strict';

const server = require('http').createServer();
const app = require('./http-server');
const port = process.env.PORT || 3000;
const WebSocket = require('ws');


// Mount our express HTTP router into our server
server.on('request', app);
console.log('Node server running on port 3000');


var osc = require("osc");

var udpPort = new osc.UDPPort({
    // This is the port we're listening on.
    localAddress: "127.0.0.1",
    localPort: 57122,

    // This is where sclang is listening for OSC messages.
    remoteAddress: "127.0.0.1",
    remotePort: 57121,
    metadata: true
});

// Open the socket.
udpPort.open();

const wss = new WebSocket.Server({ server });

let rotationValue = 255;

function heartbeat() {
    this.isAlive = true;
};

function broadcast(message) {
    wss.clients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(message);
        }
    });
}



// Establish connections and handle events
wss.on('connection', (ws) => {
    ws.isAlive = true;
    ws.room = '';
    ws.nick = '';
    ws.inGame = false;
    console.log("Websocket connected");
    ws.on('pong', heartbeat);

    ws.on('message', (message) => {
        //console.log(message);
        try{
        var parsedMessage = JSON.parse(message);
        } catch(e){
            const response = {
                messageType: 'UFHH',
                roomCode: 'noRoom',
                method: "big_ufh"    
            }
            ws.send(JSON.stringify(response));
            return;
        }
        //console.log(parsedMessage);
        //ws.room = radishMsg.roomCode.toLowerCase();
        switch (parsedMessage.messageType) {
        case 'PLAYER_INPUT':{
            console.log(parsedMessage.message);
            
            if(parsedMessage.message=="rotate"){
                rotationValue=mapRotation(rotationValue + parsedMessage.content)
                console.log(rotationValue)
                let customResponse = {
                    messageType: "rotateUpdate",
                    value: rotationValue
                }
                broadcast(JSON.stringify(customResponse))
                sendOSCMessage("/oscjs/"+parsedMessage.message,rotationValue)
            }
            else{
                sendOSCMessage("/oscjs/"+parsedMessage.message,parsedMessage.content)
            }
            if(parsedMessage.message=="longTap"){
                console.log(parsedMessage.content)
                let customResponse = {
                    messageType: "longTapUpdate",
                    value: parsedMessage.content
                }
                broadcast(JSON.stringify(customResponse))
            }if(parsedMessage.message=="swipe"){
                let customResponse = {
                    messageType:"swipeUpdate",
                    value:0
                }
                broadcast(JSON.stringify(customResponse))
            }
            
        }
        break;
    }
    });
});


function mapRotation(rot){
    if(rot<0){
        return 0
    }if(rot>255){
        return 255
    }else{
        return rot
    }
}
function broadcast(message) {
    wss.clients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(message);
        }
    });
}

function sendOSCMessage(string,value){
    {
        let type = "a"
        if(string){
            type = "f"
        }
        var msg = {
            address: string,
            args: [
                {
                    type: type,
                    value: value
                }
            ]
        };
    
        console.log("Sending message", msg.address, msg.args, "to", udpPort.options.remoteAddress + ":" + udpPort.options.remotePort);
        udpPort.send(msg);
    }
}

server.listen(port, () => console.log(`Supercollider Server is listening on port ${port}`));