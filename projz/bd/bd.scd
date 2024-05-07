(
s.waitForBoot({
	MIDIClient.init;
	MIDIIn.connectAll;

	// make sure u got a folder of bd samples -- update filepath as needed :)
	~lastNote;
	~currentSampleIndex = 0;
	~swapThresh = 0.2;
	~triggerNote = 39;
	~path = thisProcess.nowExecutingPath.dirname;


	~bds = PathName(~path +/+ "bd-samples").entries.collect({
		arg path;
		Buffer.read(s, path.fullPath);
	});

	SynthDef(\sampler , {
		arg amp=1, out=0, buf, rate=1, atk = 0.001, rel=0.01;
		var sig, env;
		sig = PlayBuf.ar(2, buf, BufRateScale.ir(buf) * rate);
		env = Env.linen(atk, BufDur.ir(buf) - atk - rel, rel, curve: [0.5, 0, 0.5]).ar(2);
		sig = sig * amp * env;
		Out.ar(out, sig);
	}).add;

	MIDIdef.noteOn(\noteOnCapture, { |vel, note|
		var currentTime, elapsedTime, expVel;
		// consider different scaling here for bd velocity?
		expVel = vel.lincurve(1, 127,0.1,0.9, 0.5);
		[note, vel].postln;
		if(note == ~triggerNote){
			Synth(\sampler, [\buf, ~bds[~currentSampleIndex], \rate, -5.midiratio, \amp, expVel]);
			// Get the current time
			currentTime = Main.elapsedTime;

			if (~lastNote.isNil) {
				// If lastNote is nil, it means this is the first note-on event
				~lastNote = currentTime;
			} {
				elapsedTime = currentTime - ~lastNote;
				elapsedTime.round(0.001).postln;
				if(elapsedTime < ~swapThresh){
					"sample swap!".postln;
					~currentSampleIndex = (~currentSampleIndex + 1) % ~bds.size;
					~currentSampleIndex.postln;
				};
				// Update lastNote with the current time
				~lastNote = currentTime;
			}
		};

	}
	);

});


)
