s.boot;
MIDIClient.init;
MIDIIn.connectAll;

~bds = Array.new;
~folder = PathName.new("/Users/ptrk/Documents/supercollider/projz/bd/bd-samples");

(
~folder.entries.do({
	arg path;
	~bds = ~bds.add(Buffer.read(s, path.fullPath));
});
)

(
SynthDef.new(\sampler , {
	arg amp=1, out=0, buf, rate=1, da=2;
	var sig;
	sig = PlayBuf.ar(2, buf, BufRateScale.kr(buf) * rate, doneAction:da);
	amp.postln;
	sig = sig * amp;
	Out.ar(out, sig);
}).add;
)

(
var lastNote, currentSampleIndex = 0, swapThresh = 0.5;

MIDIdef.noteOn(\noteOnCapture, { |vel, note|
var currentTime, elapsedTime, expVel;
	// consider different scaling here for bd velocity?
    expVel = vel.linexp(1, 127,0.1,0.9);
    // [note, vel].postln;
    if(note == 60){
    	Synth.new(\sampler, [\buf, ~bds[currentSampleIndex].bufnum, \rate, -5.midiratio, \amp, expVel]);
    	// Get the current time
    	currentTime = Main.elapsedTime;

    	if (lastNote.isNil) {
    		// If lastNote is nil, it means this is the first note-on event
    		lastNote = currentTime;
    	} {
    		elapsedTime = currentTime - lastNote;
    		elapsedTime.round(0.001).postln;
    		if(elapsedTime < swapThresh){
    			"sample swap!".postln;
    			currentSampleIndex = (currentSampleIndex + 1) % ~bds.size;
    			currentSampleIndex.postln;
    		};
    		// Update lastNote with the current time
    		lastNote = currentTime;
    	}
    };

}, nil, // Add nil as the third argument to avoid automatic removal of the MIDIdef
);
)
