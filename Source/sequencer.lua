--Remember there's a bug where the sequence won't 
--repeat if there's no note at the last step!!!!!
	--[[
		Dave Hayden:
		"Fractional MIDI notes are allowed in addNote(), and there's no 0-127 limit. I'll double check in a sec, but I think 4 Hz would be, uh.. 69 + 12*log2(4/440) = -12.3763, maybe?"
		
		"Looks like that does the trick! There's one gotcha: turns out the default voice range _is_ 0-127 (because who would ever use notes outside that?) so you have to extend that in addVoice: `inst:addVoice(snd.synth.new(snd.kWaveSquare), -100, 500, 0) -- 0=no transpose`"
	]]

class('Sequencer').extends(playdate.graphics.sprite)

local sound <const> = playdate.sound

local bpm = 120
local fracMidiNote = -1
local poSyncEnabled = false
local poSyncSynth = sound.synth.new(playdate.sound.kWaveSquare)

local syncChannel = sound.channel.new()
local syncInstrument = sound.instrument.new()
local syncTrack = sound.track.new()
local syncNotes = {}

local mainChannel = sound.channel.new()

local loPassFilter = sound.twopolefilter.new("lopass")
local hiPassFilter = sound.twopolefilter.new("hipass")
local delay1 = nil
local delay2 = nil

local sequencerTracks = {}
local noteLengths = {}
local sequence = sound.sequence.new()

function Sequencer:init(samplepackFile, onInit)
	Sequencer.super.init(self)

	poSyncSynth:setParameter(1, 0.3)--square wave duty cycle
	poSyncSynth:setVolume(1)
	
	mainChannel:setVolume(1)
	
	syncChannel:addSource(poSyncSynth)
	syncChannel:setPan(-1)--left
	syncChannel:setVolume(0)
	
	syncChannel:addSource(syncInstrument)
	syncInstrument:addVoice(poSyncSynth, -100, 500, 0)--allow sync instrument to operate outside normal midi note range

	syncTrack:setInstrument(syncInstrument)
	
	mainChannel:addEffect(loPassFilter)
	loPassFilter:setMix(0)
	loPassFilter:setFrequency(10000)
	
	mainChannel:addEffect(hiPassFilter)
	hiPassFilter:setMix(0)
	hiPassFilter:setFrequency(150)
	
	--Load from json
	if playdate.file.exists(samplepackFile) then
		print("found " .. samplepackFile)
	else
		print("" .. samplepackFile .. " not found")
	end

	local file = playdate.file.open(samplepackFile)
	local size = playdate.file.getSize(samplepackFile)	
	local samplepackData = file:read(size)
	file:close()
	
	print(samplepackData)
	
	local samplepack = json.decode(samplepackData)
	
	--Initialise UI:
	onInit(samplepack.name, samplepack.tracks)
	
	sequencerTracks = {}
	--Setup sequencer:
	for t=1,#samplepack.tracks do
		local otrack = samplepack.tracks[t]
		local sample = sound.sample.new(otrack.file)
		print("Loading sample: " .. otrack.file)
		local synth = sound.synth.new(sample)
		mainChannel:addSource(synth)
		synth:setVolume(1)
		
		local instrument = sound.instrument.new()
		mainChannel:addSource(instrument)
		instrument:addVoice(synth)
		
		local track = sound.track.new()
		track:setInstrument(instrument)
		
		if otrack.length ~= nil then
			noteLengths[t] = otrack.length
		else
			noteLengths[t] = 1
		end
		
		
		local seqNoteList = {}
		
		local noteLength = 1
		
		for i=1,#otrack.pattern do
			if otrack.pattern[i] ~= 0 then
				if otrack.length ~= nil then noteLength = otrack.length end
				local velocity = otrack.pattern[i]
				if velocity == -1 then
					seqNoteList[#seqNoteList+1] = { note=60, step=i, length=0.1, velocity=0.1  }
				else
					seqNoteList[#seqNoteList+1] = { note=60, step=i, length=noteLengths[t], velocity=otrack.pattern[i]/10 }
				end
			end
		end
		
		track:setNotes(seqNoteList)
		
		sequencerTracks[t] = {
			seqTrack = track, 
			seqSynth = synth, 
			seqInstrument = instrument, 
			seqPattern = otrack.pattern,
			seqNoteLength = noteLength
		}
	end
	
	--debug, check patterns loaded:
	--[[
	for i=1,#sequencerTracks do
		local seqTrack = sequencerTracks[i]
		print("Track " .. i .. ": " .. self:printPattern(seqTrack.seqPattern))
	end
	--]]
	
	for i=1,#sequencerTracks do sequence:addTrack(sequencerTracks[i].seqTrack) end
	
	--add invisible track on the end for the clock:
	sequence:addTrack(syncTrack)
	
	self:setBPM(bpm)
	
end

function Sequencer:updateStep(_track, _step, value)
	if value == -1 then
		self:markEnd(_track, _step)
		return
	end
	--print("Sequencer:updateStep(): " .. _track .. "," .. _step .. ": " .. value)
	local notes = sequencerTracks[_track].seqPattern --int array
	if notes[_step]/10 ~= value then
		notes[_step] = value
		sequencerTracks[_track].seqPattern = notes --updated int array
		
		local seqNoteList = {}
		
		for i=1,#notes do
			if notes[i] ~= 0 then
				if notes[i] == -1 then
					seqNoteList[#seqNoteList+1] = { note=60, step=i, length=0.1, velocity=0.1 }
				else
					local noteLength = noteLengths[_track]
					print("Note length for track " .. _track .. " is " .. noteLength)
					seqNoteList[#seqNoteList+1] = { note=60, step=i, length=noteLength, velocity=notes[i]/10 }
				end
			end
		end
		
		sequencerTracks[_track].seqTrack:setNotes(seqNoteList)
	end	
end

--Stops a sample from playing
function Sequencer:markEnd(_track, _step)
	--print("Sequencer:updateStep(): " .. _track .. "," .. _step .. ": " .. value)
	local notes = sequencerTracks[_track].seqPattern --int array
	if notes[_step] ~= -1 then
		notes[_step] = -1
		sequencerTracks[_track].seqPattern = notes --updated int array
		
		local seqNoteList = {}
		
		for i=1,#notes do
			if notes[i] ~= 0 then
				if notes[i] == -1 then
					print("Marking terminator")
					seqNoteList[#seqNoteList+1] = { note=60, step=i, length=0.1, velocity=0.1 }
				else
					seqNoteList[#seqNoteList+1] = { note=60, step=i, length=sequencerTracks[_track].seqNoteLength, velocity=notes[i]/10 }
				end
			end
		end
		
		sequencerTracks[_track].seqTrack:setNotes(seqNoteList)
	end	
end

function Sequencer:playing()
	return sequence:isPlaying()
end

function Sequencer:getStep()
	return sequence:getCurrentStep()
end

function Sequencer:play()
	print("play()")
	
	sequence:setLoops(1,16, 0)
	sequence:play()

end

function Sequencer:setTrackMute(track, isMuted)
	sequence:getTrackAtIndex(track):setMuted(isMuted)
end

function Sequencer:setBPM(bpm)
	self.bpm = bpm
	local stepsPerBeat = 4
	local beatsPerSecond = bpm / 60
	local stepsPerSecond = stepsPerBeat * beatsPerSecond
	sequence:setTempo(stepsPerSecond)
	
	if #syncNotes > 0 then
		syncTrack:removeNote(1, fracMidiNote) -- API BUG?
	end

	fracMidiNote = self:bpmToFractionalMidiNote(bpm)
	local syncNote = {step=1, note=fracMidiNote, length=16}
	syncNotes = syncTrack:getNotes()
	syncNotes[1] = syncNote
	syncTrack:setNotes(syncNotes)
	
	self:resetDelay()
end

function Sequencer:resetDelay()
	if delay1 ~= nil then mainChannel:removeEffect(delay1) end
	if delay2 ~= nil then mainChannel:removeEffect(delay2) end
	
	local delay1Time = (self.bpm/60) / 4
	local delay2Time = delay1Time * 1.5
	
	delay1 = sound.delayline.new(delay1Time)
	delay1:setFeedback(0.1)
	delay1:setMix(0.0)
	mainChannel:addEffect(delay1)
	
	delay2 = sound.delayline.new(delay2Time)
	delay2:setFeedback(0.1)
	delay2:setMix(0.0)
	mainChannel:addEffect(delay2)
end

--https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console
function Sequencer:printPattern(o)
	 if type(o) == 'table' then
			local s = ''
			for k,v in pairs(o) do
				 if type(k) ~= 'number' then k = '"'..k..'"' end
				 s = s .. self:printPattern(v) .. ','
			end
			return s
	 else
			return tostring(o)
	 end
end

--Effects
--preset delay mix
function Sequencer:setDelay1Mix(value)	
	delay1:setMix(value)
end

function Sequencer:setDelay2Mix(value)	
	delay2:setMix(value)
end

function Sequencer:setDelay1Feedback(value)	
	delay1:setFeedback(value)
end

function Sequencer:setDelay2Feedback(value)	
	delay2:setFeedback(value)
end

--lo pass:
function Sequencer:setLoPassActive(active)
	if active then
		print("lopass is active")
		loPassFilter:setMix(1)
	else
		print("lopass is INactive")
		loPassFilter:setMix(0)
	end
end

function Sequencer:setLoPassFrquency(freq)
	print("setLoPassFrquency(): " .. freq)
	loPassFilter:setFrequency(freq)
end

function Sequencer:setLoPassResonance(res)
	print("setLoPassResonance(): " .. res)
	loPassFilter:setResonance(res)
end

--hi pass
function Sequencer:setHiPassActive(active)
	if active then
		hiPassFilter:setMix(1)
	else
		hiPassFilter:setMix(0)
	end
end

function Sequencer:setHiPassFrquency(freq)
	print("setHiPassFrquency(): " .. freq)
	hiPassFilter:setFrequency(freq)
end

function Sequencer:setHiPassResonance(res)
	print("setHiPassResonance(): " .. res)
	hiPassFilter:setResonance(res)
end


--Sync
function Sequencer:isSyncEnabled()
	return poSyncEnabled
end

function Sequencer:poSyncActive(active)
	if active then
		syncChannel:setVolume(1)
		poSyncEnabled = true
		mainChannel:setPan(1)
	else
		syncChannel:setVolume(0)
		poSyncEnabled = false
		mainChannel:setPan(0)
	end
end

function Sequencer:bpmToFractionalMidiNote(bpm)
	local Hz = (bpm/60) * 2 --2ppqn
	local fracMidi = 69 + 12 * math.log(Hz/440, 2)
	print("Sequencer:bpmToFractionalMidiNote() bpm: " .. bpm .. " Hz: " .. Hz .. " FracMidi: " .. fracMidi)
	return fracMidi
end
	
