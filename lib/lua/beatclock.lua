local BeatClock = {}
BeatClock.__index = BeatClock

function BeatClock.new(name)
  local i = {}
  setmetatable(i, BeatClock)
  
  i.name = name or ""
  i.playing = false
  i.external_ticks_per_step = 6
  i.external_current_ticks = i.external_ticks_per_step - 1
  i.steps_per_beat = 4
  i.beats_per_bar = 4
  i.step = i.steps_per_beat - 1
  i.beat = i.beats_per_bar - 1
  i.bpm = 110
  i.external = false
  
  i.metro = metro.alloc()
  i.metro.count = -1
  i.metro.time = 15/i.bpm
  i.metro.callback = function() i:tick_internal() end

  i.on_step = function(e) print("BeatClock executing step") end
  i.on_select_internal = function(e) print("BeatClock using internal clock") end
  i.on_select_external = function(e) print("BeatClock using external clock") end

  return i
end

function BeatClock:start()
  self.playing = true
  if not self.external then
    self.metro:start()
  end
  self.external_current_ticks = self.external_ticks_per_step - 1
end

function BeatClock:stop()
  self.playing = false
  self.metro:stop()
end

function BeatClock:advance_step()
  self.step = (self.step + 1) % self.steps_per_beat
  if self.step == 0 then
    self.beat = (self.beat + 1) % self.beats_per_bar
  end
  self.on_step()
end

function BeatClock:tick_internal()
  if self.playing and not self.external then
    self:advance_step()
  end 
end

function BeatClock:tick_external()
  if self.external then
    self.external_current_ticks = (self.external_current_ticks + 1) % self.external_ticks_per_step
    if self.playing and self.external_current_ticks == 0 then
      self:advance_step()
    end
  end
end

function BeatClock:reset()
  self.step = self.steps_per_beat - 1
  self.beat = self.beats_per_bar - 1
  self.external_current_ticks = self.external_ticks_per_step - 1
end

function BeatClock:clock_source_change(source)
  if source == 1 then
    self.external = false
    self.external_current_ticks = self.external_ticks_per_step - 1
    if self.playing then
      self.metro:start()
    end
    self.on_select_internal()
  else
    self.external = true
    self.metro:stop()
    self.on_select_external()
  end
end

function BeatClock:bpm_change(bpm)
  self.bpm = bpm
  self.metro.time = (60/self.beats_per_bar) / bpm
end

function BeatClock:add_clock_params()
  params:add_option("clock", {"internal", "external"}, self.external or 2 and 1)
  params:set_action("clock", function(x) self:clock_source_change(x) end)
  params:add_number("bpm", 1, 480, self.bpm)
  params:set_action("bpm", function(x) self:bpm_change(x) end)
end
  
return BeatClock