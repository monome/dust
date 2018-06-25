local beat_clock = {}
beat_clock.__index = beat_clock

function beat_clock.new(name)
  local i = {}
  setmetatable(i, beat_clock)
  
  i.name = name or ""
  i.playing = false
  i.external_ticks_per_step = 6
  i.external_current_ticks = i.external_ticks_per_step - 1
  i.steps_per_beat = 4
  i.beats_per_bar = 4
  i.step = 0
  i.beat = 0
  i.bpm = 110
  i.external = false
  
  i.metro = metro.alloc()
  i.metro.count = -1
  i.metro.time = 15/i.bpm
  i.metro.callback = function() i:tick_internal() end

  i.process_step = function(e) print("beat_clock step") end

  return i
end

function beat_clock:start()
  self.playing = true
  if not self.external then
    self.metro:start()
  end
end

function beat_clock:stop()
  self.playing = false
  self.metro:stop()
end

function beat_clock:advance_step()
  self.step = (self.step + 1) % self.steps_per_beat
  if self.step == 0 then
    self.beat = (self.beat + 1) % self.beats_per_bar
  end
  self.process_step()
end

function beat_clock:tick_internal()
  if self.playing and not self.external then
    self:advance_step()
  end 
end

function beat_clock:tick_external()
  if self.external then
    self.external_current_ticks = (self.external_current_ticks + 1) % self.external_ticks_per_step
    if self.playing and self.external_current_ticks == 0 then
      self:advance_step()
    end
  end
end

function beat_clock:reset()
  self.step = 0
  self.beat = 0
  self:reset_external_clock()
end

function beat_clock:reset_external_clock()
  -- set to pick up on next external clock event
  self.external_current_ticks = self.external_ticks_per_step - 1
end

function beat_clock:clock_source_change(source)
  if source == 1 then
    print("Using internal clock")
    self.external = false
    self:reset_external_clock()
    if self.playing then
      self.metro:start()
    end
  else
    print("Using external clock")
    self.external = true
    self.metro:stop()
  end
end

function beat_clock:bpm_change(bpm)
  self.bpm = bpm
  self.metro.time = (60/self.beats_per_bar) / bpm
end

function beat_clock:add_clock_params()
  params:add_option("clock", {"internal", "external"}, self.external or 2 and 1)
  params:set_action("clock", function(x) self:clock_source_change(x) end)
  params:add_number("bpm", 1, 480, self.bpm)
  params:set_action("bpm", function(x) self:bpm_change(x) end)
end
  
return beat_clock