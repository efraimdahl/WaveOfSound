
(
//this is a folder where I have a bunch of sound files
~pathDrone = PathName("C:/Users/Efraim/Desktop/Electronic Music/finalProject/Samples/VocalDrone");

//create a list of buffers
~buffersDrone = List.newClear(0);

//look at all the files in the folder and read every file that has the extension .aif into a Buffer and add it to the List of Buffers
~pathDrone.files.do{arg item;
	if(item.fullPath.contains(".wav"),{
		~buffersDrone.add(Buffer.read(s, item.fullPath.postln));
	});
};
)

(
//the play SynthDef
SynthDef("MultDrone", {arg buf, bus, volume, totVol;
	var sound, distance, dirVol, verbVol;

	//play a Buffer at a random speed
	//Rand(-1,1)
	sound = PlayBuf.ar(2, buf,Rand(-1,1),1,1,1,0,1);
	//randomly pan the buffer
	sound = Pan2.ar(sound, Rand(-1,1));

	//calculate the distance of the sound as a random number
	distance = Rand(2,20);

	//calculated the volumes of the direct signal and the reverb signal
	//based on the distance
	//the ratio of reverb signal to direct signal gets higher as the sound gets further away
	dirVol = 1/(distance**2);
	verbVol = 1/distance;

	Out.ar(0, sound*dirVol*volume*totVol);
	Out.ar(bus, sound*verbVol*volume*totVol);
}).load(s);

//the play SynthDef
SynthDef("MonDrone", {arg buf, bus, volume, totVol;
	var sound, distance, dirVol, verbVol;

	//play a Buffer at a random speed
	//Rand(-1,1)
	sound = PlayBuf.ar(2, buf,1,1,1,1,0,1);
	//randomly pan the buffer
	sound = Pan2.ar(sound, Rand(-1,1));

	//calculate the distance of the sound as a random number
	distance = Rand(2,20);

	//calculated the volumes of the direct signal and the reverb signal
	//based on the distance
	//the ratio of reverb signal to direct signal gets higher as the sound gets further away
	dirVol = 1/(distance**2);
	verbVol = 1/distance;

	Out.ar(0, sound*dirVol*volume*totVol);
	Out.ar(bus, sound*verbVol*volume*totVol);
}).load(s);


//the reverb SynthDef
//reverbs take up a LOT of CPU, especially when they are created
//therefore we only want one of these that all the synths send audio to
SynthDef("droneFX", {arg bus, freqMod=1;
	var in, verb, con;

	in = In.ar(bus, 2);

	//con = SinOsc.ar(freqMod,0,1,0);

	//check out the GVerb help file for the various settings (there are a lot)
	verb = GVerb.ar(Mix(in),
		150, 1, 0.9, 0.2, 15, 0, 0.2, 1
	);

	//verb = MoogFF.ar(verb,freqMod,2,0,1,0);

	Out.ar(0, verb);

}).load(s);
)

(
var synth, seq, bus, group1, group2, group3, synthLstMult, synthLstMon, vol, prob, totVol, monVol;

group1 = Group.tail(s);
group2 = Group.tail(s);
group3 = Group.tail(s);
bus = Bus.audio(s, 2);
prob=1;
vol=5;
monVol = 3;
totVol=1;
synth = Synth("droneFX", [\bus, bus], group3);
//Random Sequence of words
seq = Pxrand(~buffersDrone, inf).asStream;
synthLstMult = List.new(0);
synthLstMon = List.new(0);


OSCFunc({arg msg;
	var mth, node;
	mth=prob.coin.postln;
	if(mth,{
		synthLstMult.add(Synth("MultDrone", [\buf, seq.next, \bus, bus, \volume, vol, \totVol, totVol], group1));
		synthLstMon.add(Synth("MonDrone", [\buf, seq.next, \bus, bus, \volume, monVol, \totVol, (1-totVol)], group2));
		prob=(prob-0.02).postln;
		synthLstMon.size.postln;
    },{
		prob=(prob+0.02).postln;
		node = synthLstMult.pop.postln;
		node.free;
		node = synthLstMon.pop.postln;
		node.free;
		synthLstMon=synthLstMon.scramble;
		synthLstMult=synthLstMult.scramble;

    })
}, '/oscjs/doubleTap');

OSCFunc({arg msg;
	var volMod;

	msg.postln;

	totVol = msg[1].linlin(0, 255, 0,1).postln;
	synthLstMon.do({arg item, i; item.set(\totVol,(1-totVol))});
	synthLstMult.do({arg item, i; item.set(\totVol,totVol)});

}, '/oscjs/rotate');


)

