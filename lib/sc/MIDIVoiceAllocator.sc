MIDIVoiceAllocator {
	classvar defaultPolyphony = 6;
	var polyphony;
	var allocations, freeVoices;
	var <>alloc, <>free;
	
	*new { |polyphony|
		^super.new.init(polyphony);
	}

	init { |argPolyphony|
		polyphony = argPolyphony ? defaultPolyphony;
		allocations = Array.new;
		freeVoices = (0..polyphony-1);
	}

	noteOn { |note, vel|
		var voicenum = if (this.voiceWithNoteIsAllocated(note)) {
			this.getAllocatedVoiceByNote(note);
		} {
			if (freeVoices.isEmpty) { allocations.first.key } { freeVoices.first };
		};
		if (this.voiceIsAllocated(voicenum)) {
			this.voiceOff(voicenum);
			voicenum.debug(\voiceStolen);
		};
		this.voiceOn(voicenum, note, vel);
	}
	
	noteOff { |note|
		this.getAllocatedVoiceByNote(note) !? { |voicenum| this.voiceOff(voicenum) };
	}

	voiceOn { |voicenum, note, vel|
		allocations = allocations.add(voicenum -> note);
		freeVoices.remove(voicenum);
		[voicenum, \allocations -> allocations, \freeVoices -> freeVoices].debug(\voiceOn);
		alloc.value(voicenum, note.midicps);
	}

	voiceOff { |voicenum|
		allocations.removeAllSuchThat { |alloc| alloc.key == voicenum };
		freeVoices = freeVoices.add(voicenum);
		[voicenum, \allocations -> allocations, \freeVoices -> freeVoices].debug(\voiceOff);
		free.value(voicenum);
	}

	voiceIsAllocated { |voicenum| ^allocations.any { |alloc| alloc.key == voicenum } }
	voiceWithNoteIsAllocated { |note| ^allocations.any { |alloc| alloc.value == note } }
	getAllocatedVoiceByNote { |note| ^allocations.detect { |alloc| alloc.value == note } !? _.key }
}
