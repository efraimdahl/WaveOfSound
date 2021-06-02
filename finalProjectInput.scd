
(
//this is a folder where I have a bunch of sound files
~path = PathName("C:/Users/Efraim/Desktop/Electronic Music/finalProject/Samples/Sways");

//create a list of buffers
~buffers = List.newClear(0);

//look at all the files in the folder and read every file that has the extension .aif into a Buffer and add it to the List of Buffers
~path.files.do{arg item;
	if(item.fullPath.contains(".wav"),{
		~buffers.add(Buffer.read(s, item.fullPath.postln));
	});
};
)

(
//the play SynthDef
SynthDef("playBuf", {arg buf, bus, volume, loRange, hiRange;
	var sound, distance, dirVol, verbVol;

	//play a Buffer at a random speed
	//Rand(0.7,1.01)
	sound = PlayBuf.ar(2, buf,Rand(loRange,hiRange),1,0,0,doneAction:2);
	sound = Compander.ar(sound,sound,0.1,1,1,0.01,0.1,2,0);
	//randomly pan the buffer
	sound = Pan2.ar(sound, Rand(-1,1));

	//calculate the distance of the sound as a random number
	distance = Rand(2,4);

	//calculated the volumes of the direct signal and the reverb signal
	//based on the distance
	//the ratio of reverb signal to direct signal gets higher as the sound gets further away
	dirVol = 1/(distance**2);
	verbVol = 1/distance;

	Out.ar(0, sound*dirVol*volume);
	Out.ar(bus, sound*verbVol*0.2);
}).load(s);



//the reverb SynthDef
//reverbs take up a LOT of CPU, especially when they are created
//therefore we only want one of these that all the synths send audio to
SynthDef("reverb", {arg bus;
	var in, verb;

	in = In.ar(bus, 2);

	//check out the GVerb help file for the various settings (there are a lot)
	verb = GVerb.ar(Mix(in),
		150, 1, 0.9, 0.2, 15, 0, 0.2, 1
	);

	Out.ar(0, verb);

}).load(s);
)

(
var seq, bus, group1, group2, synthLst, vol, prob, loRange, hiRange;

group1 = Group.tail(s);
group2 = Group.tail(s);
bus = Bus.audio(s, 2);
prob=1;
vol=2;
loRange=1;
hiRange=1;
Synth("reverb", [\bus, bus], group2);

//Random Sequence of words
seq = Pxrand(~buffers, inf).asStream;


OSCFunc({arg msg;
	var mth, node;
	hiRange.postln;
	loRange.postln;
	Synth("playBuf", [\buf, seq.next, \bus, bus, \volume, vol,\loRange, loRange, \hiRange, hiRange], group1)
}, '/oscjs/swipe');


OSCFunc({arg msg;
	var val;
	val = msg[1].linlin(0, 255, 0,0.3).postln;
	loRange=1-val;
	hiRange=1+val;
}, '/oscjs/rotate');
)



