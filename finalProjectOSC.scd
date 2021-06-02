OSCFunc.trace;
OSCFunc.trace.stop;

NetAddr.localAddr;
thisProcess.openUDPPort(57121);
s.options.outDevice_("ZoomAudioD")


((
(SynthDef("SimpleBass",{
	arg freq = 10000, bus;
	var out;
	var rumble, rumbleDur, rumbleEnv;
	var main, mainEnv, mainDur;
	var emptyEnv;

	mainDur = 0.05;
	main = WhiteNoise.ar(0.27); //Line.kr(1000, 10, mainDur), 0,1);
	main = Clip.ar(main,0.1,0.12);
	main = BPF.ar(main,(Line.kr(1000, 10, mainDur)),3,1,0);
	mainEnv = EnvGen.kr(Env.perc(0, mainDur, 1), 1);

	rumbleDur = 0.5;
	rumble = SinOsc.ar(SinOsc.ar(1,0,0,(SinOsc.ar(freq,SinOsc.ar(5,0,1,0),5,0)*2)),0,4,0.25);
	rumbleEnv = EnvGen.kr(Env.perc(0, rumbleDur),1);


	emptyEnv = EnvGen.kr(Env.perc(0,mainDur+rumbleDur, 1), 1, doneAction:2);

	out = ((rumble*rumbleEnv)+(main*mainEnv))*4;
	Out.ar(bus, out.dup)
})).load(s);
);

(
(SynthDef("QuietSnare",{
	arg bus;
	var out;
	var rumble, rumbleDur, rumbleEnv;
	var main, mainEnv, mainDur;
	var emptyEnv;

	mainDur = 0.05;
	main = WhiteNoise.ar(0.27); //Line.kr(1000, 10, mainDur), 0,1);
	main = Clip.ar(main,0.1,0.12);
	main = BPF.ar(main,(Line.kr(1000, 10, mainDur)),3,1,0);
	mainEnv = EnvGen.kr(Env.perc(0, mainDur, 1), 1);

	emptyEnv = EnvGen.kr(Env.perc(0,mainDur, 1), 1, doneAction:2);

	out = (main*mainEnv)*4;
	Out.ar(bus, out.dup)
})).load(s);
);

(
// short thin snare, almost like knuckles on a wood table
SynthDef("cui_snare",
	{
		arg bus;
		var gliss, crack, crackEnv, out;
		var snare, snareEnv;
		var reson, resonEnv;

		//crack
		gliss = Line.kr(10,200,0.2);
		crack = Pulse.ar(gliss,5,2);
		crackEnv = EnvGen.kr(Env.perc(0.001,));

		//snare
		snare = Dust.ar(0.07);
		snare = HPF.ar(snare, 1000);
		snare = LPF.ar(snare, Line.kr(5000, 2000, 0.01));
		snareEnv = EnvGen.kr(Env.perc(0, 0.2, 1), 1, doneAction:2);

		//reson
		reson = SinOsc.ar(Line.kr(400, 375, 0.02), 0, 0.01);
		resonEnv = EnvGen.kr(Env.perc(0, 0.02, 1), 1);

		out = ((crack*crackEnv) + (snare*snareEnv) + (reson*resonEnv))*4;
		Out.ar(bus, [out,out]);

	}
).load(s);
);

(
//crash drum modelled after victors snare
SynthDef("crash",
	{
		arg bus;
		var gliss, crack, crackEnv, out;
		var snare, snareEnv;
		var reson, resonEnv;

		//crack
		gliss = Line.kr(10000,9500,0.2);
		crack = Pulse.ar(gliss,5,3);
		crackEnv = EnvGen.kr(Env.perc(0.001,0.32,0.1,-4));

		//snare
		snare = WhiteNoise.ar(0.007);
		snare = HPF.ar(snare, 20);
		snare = LPF.ar(snare, Line.kr(10, 10000, 0.01));
		snareEnv = EnvGen.kr(Env.perc(0, 2.2, 1), 1, doneAction:2);

		//reson
		reson = SinOsc.ar(Line.kr(400, 375, 0.02), 1, 0.11);
		resonEnv = EnvGen.kr(Env.perc(0, 2.22, 1), 1);

		out = (crack*crackEnv) + (snare*snareEnv); //+ (reson*resonEnv);
		Out.ar(0, [out,out]);

	}
).load(s);
);
//the reverb SynthDef
//reverbs take up a LOT of CPU, especially when they are created
//therefore we only want one of these that all the synths send audio to
SynthDef("percFX", {arg bus, freq, vol;
	var in, verb, delOsc;
	delOsc = SinOsc.ar(5,0,1,0);
	in = In.ar(bus, 2);
	verb = Limiter.ar(in,0.02,0.01)*4;
	verb = CombC.ar(Mix(verb),0.1,Rand(0.001,0.2),2,1,0);
	//check out the GVerb help file for the various settings (there are a lot)
	verb = GVerb.ar(Mix(verb),
		150, 1, 0.9, 0.2, 15, 0, 0.2, 1
	);
	Out.ar(0, verb);

}).load(s);

)






~percBuffer = Array.newClear;
~percBuffer=["SimpleBass","QuietSnare","cui_snare","crash"];

~percBuffer[1].postln;
(Synth(~percBuffer[3]));
(
var fx, seq, bus, group3, group4, synthLst, vol, prob;

group3 = Group.tail(s);
group4 = Group.tail(s);
bus = Bus.audio(s, 2);
"starting".postln;
prob=1;
vol=4;
fx = Synth("percFX", [\bus, bus], group4);

//Random Sequence of words
seq = Pxrand(#[0,1,2,3], inf).asStream;

OSCFunc({arg msg;
	var mth, node;
	msg.postln;
	"long-tap".postln;
	(Synth(~percBuffer[seq.next],[\bus, bus], group3));
	mth=Rand(0.001,440);
	//fx.set(\freq, mth);
}, '/oscjs/longTap');

);




(Synth("SimpleBass"));
(Synth("QuietSnare"));
(Synth("cui_snare"));
(Synth("crash"));
(Synth("PersistentBeep"));









