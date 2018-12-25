-- fugu  /'fu:gu:/      ___
--                     /o   \/|
--                     \___/\|
--
-- A pufferfish that is eaten as
-- a Japanese delicacy, after
-- some highly poisonous parts
-- have been removed.
--
--
-- page 1 -
-- notes entry
--
-- page 2 -
-- tempo, transpose
-- 2-4 tr loop lengths
--
-- page 3 -
-- pattern seq
-- 1-4 tr loop lengths
--
-- page 4 -
-- note values
--
-- alt is 8,11


engine.name = "MollyThePoly"
local Molly = require 'mark_eats/mollythepoly'
local music = require 'mark_eats/musicutil'
local beatclock = require 'beatclock'
local tab = require 'tabutil'
local TRACKS = 4
local data = {}
local pattern = 1
local scrn = 1
local trvals = {-36, -24, -12, 0, 12, 24, 36, 48}
local divs ={(1/8), (1 / 4), (1 / 2), (3 / 4 ), 1, (3 / 2), 2, 3}
local printdivs = {"1/8", "1/4", "1/2", "3/4", "", "3/2", "x2", "x3"}
local alt = false
local stopped = 1
local project = 1
local mode = #music.SCALES
local scale = music.generate_scale_of_length(60,music.SCALES[mode].name,16)
local notecreen = 1
local lastsaved = 0
local dispnote = 0
local held = {}
local heldmax = {}
local done = {}
local first = {}
local second = {}
local last_note_name = {"none","none","none","none"}
local states = {0,0,0,0}
local position = {0,0,0,0}
local octaveseqpos = {0,0,0,0}
local octaveseqstart = {0,0,0,0}
local octaveseqlen = {7,7,7,7}
local clockseqdiv = {4,4,4,4}
local uidispnote = {0,0,0,0}

local function switch_pattern(pat)
  params:set("bpm", data[pat].bpm)
  pattern = pat
  for i=1,TRACKS do
    metro[i]:bpm_change((params:get("bpm")*divs[data[pattern].clockmult[i]]))
  end
end

local function save_project(num)
  data[pattern].bpm = params:get("bpm")
  data.last_pattern = pattern
  tab.save(data,"/home/we/dust/data/bedtime/fugu-pat-"..num ..".data")
  params:write("bedtime/fugu-param-"..num ..".pset")
end

local function load_project(num)
  saved_data = tab.load("/home/we/dust/data/bedtime/fugu-pat-"..num ..".data")
  if saved_data ~= nil then
    data = saved_data
    pattern = data.last_pattern
    params:read("bedtime/fugu-param-"..num  .. ".pset")
    params:set("bpm", data[pattern].bpm) -- load bpm
  else
    print("no file")
  end
end

local function count_oct(tr)
  octaveseqpos[tr] = util.clamp(((octaveseqpos[tr]  %  octaveseqlen[tr]) + 1),octaveseqstart[tr],octaveseqlen[tr])
  data[pattern].transpose[tr] = octaveseqpos[tr]
end

local function metaseq()
  if data.meta_startpos > 1 then
    data.meta_pos = util.clamp(((data.meta_pos  %  data.meta_lengt) + 1),data.meta_startpos,data.meta_lengt)
  else
    data.meta_pos = (data.meta_pos  %  data.meta_lengt) + 1
  end
  pattern = data.meta_pos
end

local function count(tr)
  if data[pattern].plmode[tr] == 0 then
    position[tr] = util.clamp(((position[tr]  %  data[pattern].lengt[tr]) + 1),data[pattern].startpos[tr],data[pattern].lengt[tr])
  elseif data[pattern].plmode[tr] == 1 then
    position[tr] = ((position[tr] - 1 ) % data[pattern].lengt[tr])
    if position[tr] == data[pattern].startpos[tr] - 1  then position[tr] = data[pattern].lengt[tr] end
  elseif data[pattern].plmode[tr] == 2 then
    position[tr] = util.clamp(math.random(data[pattern].startpos[tr],data[pattern].lengt[tr]), data[pattern].startpos[tr],data[pattern].lengt[tr])
  end
  if data[pattern].steps[position[tr]] ~= 0 then
    last_note_name[tr] = music.note_num_to_name(scale[data[pattern].notevals[data[pattern].steps[position[tr]]]] + trvals[data[pattern].transpose[tr]])
    if data[pattern].probmode[tr] == 0 then
          engine.noteOn(tr,music.note_num_to_freq(scale[data[pattern].notevals[data[pattern].steps[position[tr]]]] + trvals[data[pattern].transpose[tr]]), params:get(tr.."vel")/127)
        end
    if data[pattern].probmode[tr] == 1 then
      if params:get(tr.."probability") == 100 then
          engine.noteOn(tr,music.note_num_to_freq(scale[data[pattern].notevals[data[pattern].steps[position[tr]]]] + trvals[data[pattern].transpose[tr]]), params:get(tr.."vel")/127)
        elseif params:get(tr.."probability") >= math.random(100) then
          engine.noteOn(tr,music.note_num_to_freq(scale[data[pattern].notevals[data[pattern].steps[position[tr]]]] + trvals[data[pattern].transpose[tr]]), params:get(tr.."vel")/127)
        end
      end
      dispnote = data[pattern].notevals[data[pattern].steps[position[tr]]]
      uidispnote[tr] = data[pattern].notevals[data[pattern].steps[position[tr]]]
  else
    engine.noteOff(tr)
    dispnote = 0
    uidispnote[tr] = 0
  end
end

function init()
  data.meta_startpos = 0
  data.meta_lengt = 16
  data.meta_pos = 1
  data.last_pattern = pattern
  for i=1,16 do
    data[i] = {}
    data[i].steps = {}
    data[i].lengt = {16,16,16,16}
    data[i].startpos = {1,1,1,1}
    data[i].clockmult = {5,5,5,5}
    data[i].plmode = {0,0,0,0}
    data[i].probmode = {0,0,0,0}
    data[i].transpose = {4,4,4,4}
    data[i].notevals = {7,6,5,4,3,2,1}
    data[i].bpm = 110
    for l=1,16 do
      table.insert(data[i].steps,0)
    end
  end
  for i = 1,8 do
    held[i] = 0
    heldmax[i] = 0
    done[i] = 0
    first[i] = 0
    second[i] = 0
  end
  for i=1,8 do
    metro[i] = beatclock.new(i)
    if i < 5 then
      metro[i].on_step = function() count(i,1) end
    elseif i >= 5 then
      metro[i].on_step = function() count_oct(i - 4) end
    end
  end
  meta = beatclock.new()
  meta.on_step = metaseq
  meta.on_stop = function() data.meta_pos = 0 end
  metro_redraw = metro.alloc(function(stage) grid_redraw() redraw() end, 1 / 30)
  metro_redraw:start()
  params:add_number("proj","proj",1,16,1)
  params:set_action("proj", function(x) project = x end)
  params:add_trigger ("lproj", "load")
  params:set_action("lproj", function(x) load_project(project)   end)
  params:add_trigger ("sproj", "save")
  params:set_action("sproj", function(x) save_project(project)   end)
  params:add_number("meta_div", "meta divider", 1,32,1)
  for i=1,TRACKS do
    params:add_number(i.."vel", i.." vel", 0,127, 80)
    params:add_number(i.."probability", i.." probability",0,100,50)
    end
  metro[1]:add_clock_params()
  params:add_separator()
  Molly.add_params()
  --
end

function key(n,z)
  if z == 1 then
    if n == 2 then
      for p=1,TRACKS do
        position[p] = 0
      end
    elseif n == 3  and stopped == 1 then
      stopped = 0
      for i = 1,TRACKS do
        position[i] = 1
        metro[i]:start()
      end
      for i=1,TRACKS do
        states[i]= 1
        end
    elseif n == 3 and stopped == 0 then
      stopped = 1
      for i = 1,TRACKS do
        metro[i]:stop()
      end
      meta:stop()
      for i=1,TRACKS do
        states[i]= 0
      end
    end
  end
end

function enc(n,d)
  if n == 1 then
    mix:delta("output",d)
  elseif n == 2 then
    params:delta("bpm",d)
    meta:bpm_change(params:get("bpm")/params:get("meta_div"))
    for i = 1,TRACKS do
      metro[i]:bpm_change((params:get("bpm")*divs[data[pattern].clockmult[i]]))
    end
  elseif n == 3 then
    mode = util.clamp(mode + d, 1, #music.SCALES)
    scale = music.generate_scale_of_length(60,music.SCALES[mode].name,16)
  end
end

function redraw()
  screen.clear()
  screen.aa(1)
  screen.line_width(0.3)
  for i=1,TRACKS do
    if states[i]> 0 then
      screen.level(uidispnote[i] ~= 0 and 6 or 5)
      local offset = i == 1 and 1 or ( 27 * (i-1))
      screen.move(65,7)
      screen.line(25 + offset ,15)
      screen.move(25 + offset ,15)
      screen.line(24 + offset ,27)
      screen.stroke()
    end
  end

  screen.font_size(4)
  screen.level(15)
  screen.font_size(8)

  for i=1,TRACKS do
    local offset = 28
    screen.font_size(8)
    screen.move((offset * i) - 10 ,34)
    screen.level(15)
    if states[i]> 0 then
      screen.text(""..(params:get("bpm")*divs[data[i].clockmult[i]]))
      if uidispnote[i] ~= 0 then
        screen.move((offset*i)-6,36)
        screen.line_width(0.3)
        screen.line((offset*i)-6, 38)
        screen.stroke()
      end
      if data[pattern].clockmult[i] ~= 5 then
        screen.level(0)
        screen.rect((offset*i)-10,18,15,5)
        screen.fill()
      end
      screen.move((offset * i) - 10 ,23)
      if data[pattern].clockmult[i] ~= 5 then
        screen.level(6)
        screen.text(printdivs[data[pattern].clockmult[i]])
      end
      if last_note_name[i] ~= "none" then
        screen.level(0)
        screen.rect((offset*i) - 10,42,10,7)
        screen.fill()
        screen.level(6)
        screen.move(((offset * i) + 2.45) - 12--[[10]], 46)
        screen.text(data[pattern].transpose[i]  .. last_note_name[i])
      end
    end
  end
  screen.level(15)
  screen.font_size(8)
  screen.level(15)
  screen.move(0,62)
  screen.font_size(8)
  screen.text(music.SCALES[mode].name)
  screen.move(60,5)
  screen.text(""..params:get("bpm"))
  screen.update()
end

g = grid.connect()

g.event = function(x,y,z)
  -- if elif mess
  if z==1 and held[y] then
    heldmax[y] = 0
  end
  held[y] = held[y] + (z*2-1)
  if held[y] > heldmax[y] then
    heldmax[y] = held[y]
  end
  if y == 8 and x > 5 and x < 10 then
    scrn = ( x - 5 ) % 5
  elseif y == 8 and x == 11 and z == 1 then
    alt = true
  elseif y == 8 and x == 11 and z == 0 then
    alt = false
  end
  if z == 1 then
    -- toggle between forward and reverse playback
    if y == 8 and x >= 13 then
      if data[pattern].plmode[x - 12] == 0 then
        if alt == false then
          data[pattern].plmode[x - 12] = 1
        elseif alt == true then
          data[pattern].plmode[x - 12] = 2
        end
      elseif data[pattern].plmode[x-12] ~= 0 then
        if alt == false then
        data[pattern].plmode[x-12] = 0
        elseif alt == true then
          data[pattern].plmode[x-12] = 0
        end
      end
    end
    if scrn == 1 then
        if y == data[pattern].steps[x] then
          data[pattern].steps[x] = 0
        elseif y < 8 then
          data[pattern].steps[x] = y
        end
    elseif scrn == 2 then
      if y > 4  and y < 8 then
        if held[y]==1 then
          first[y] = x
        elseif held[y]==2 then
          second[y] = x
          data[pattern].startpos[y - 3] = first[y]
          position[y-3] = first[y]
          data[pattern].lengt[y - 3] = second[y]
        end
        if y > 4 and y < 8 and alt then
          position[y-3] = x
          if metro[y-3].playing == false then
            metro[y-3]:start()
            states[y-3] = 1 end
          end
        elseif y < 5 and x < 9 then
          data[pattern].clockmult[y] = x
          metro[y]:bpm_change((params:get("bpm")*divs[x]))
        end
        if y < 5 and x > 9 and x < 17 and alt == true then
          if held[y]==1 then
            first[y] = x - 9
          elseif held[y]==2 then
            second[y] = x - 9
            octaveseqstart[util.clamp((y),1,TRACKS)] = first[y]
            octaveseqlen[util.clamp((y),1,TRACKS)  % 5] = second[y]
            if y > 0 and y < 5 then
              metro[y+4]:start()
            end
          end
        elseif y < 5 and x > 9 and x < 17 then
          if not alt then
            data[pattern].transpose[y] = x - 9
            if y > 0 and y < 5 then
              metro[y+4]:stop()
            end
          end
        end
      if alt and x > 9 then
        if y > 0 and y < 5 then
          metro[y+4]:bpm_change(params:get("bpm")*divs[x - 9])
        end
        clockseqdiv[y] = x - 9
      end
    elseif scrn == 3 then
      if y == 1 and z == 1 then
        if not alt then
          pattern = x
          switch_pattern(pattern)
        elseif alt then
          data[x] = data[pattern]
        end
      elseif y == 2 then
        if held[y]==1 then
          first[y] = x
        elseif held[y]==2 then
          second[y] = x
          data.meta_startpos = first[y]
          data.meta_lengt = second[y]
        end
        if alt then
          if not meta.playing then
            meta:start()
          elseif meta.playing then
            meta:stop()
          end
        end
      end
      if y == 3 then
        params:set("meta_div",x) meta:bpm_change(params:get("bpm")/params:get("meta_div"))
      elseif y > 3 and y < 8 then
        position[y-3] = x
        if alt and not metro[y-3].playing then
          metro[y-3]:start()
          states[y-3] = 1
        end
      end
      if y < 8 and y > 3 then
        if held[y]==1 then
          first[y] = x
        elseif held[y]==2 then
          second[y] = x
          data[pattern].startpos[util.clamp((y - 3),1,TRACKS)] = first[y]
          data[pattern].lengt[util.clamp((y - 3),1,TRACKS)  % 5] = second[y]
          end
        end
    elseif scrn == 4 then
      if not alt then
        data[pattern].notevals[y] = x
      elseif alt then
      end
    end
    if y == 8 then
      if x > 0 and x < 5 then
        if not alt then
          if metro[x].playing then
            metro[x]:stop()
            last_note_name[x] = "none"
          engine.noteOff(x)
          states[x] = 0
          elseif not metro[x].playing then
            metro[x]:bpm_change((params:get("bpm")*divs[data[pattern].clockmult[x]]))
            metro[x]:start()
            states[x] = 1
          end
        elseif alt then
          if data[pattern].probmode[x] == 0 then
            data[pattern].probmode[x] = 1
          elseif data[pattern].probmode[x] == 1 then
            data[pattern].probmode[x] = 0
          end
        end
      end
    end
  end
  g.refresh()
end

function grid_redraw()
  g.all(0)
  if alt == true then
    g.led(11,8,15)
  elseif alt == false then
    g.led(11,8,1)
  end
  for i=1,TRACKS do
    g.led(i,8,( data[pattern].probmode[i] == 1 and states[i] == 1) and 9 or 1==states[i] and 15 or 4)
    g.led(i + 12, 8, 1 == data[pattern].plmode[i] and 15 or 2 == data[pattern].plmode[i] and 9 or 4)
  end
  for i=1,TRACKS do
    g.led(i + 5, 8, i == scrn and 15 or 4)
  end
  if scrn == 1 then
    for i=1,16 do
      g.led(i,data[pattern].steps[i],8)
    end
    for l=1,TRACKS do
      if states[l] == 1 then
        for i=1,7 do
          g.led(position[l],i, i==data[pattern].steps[position[l]] and 15 or 4)
        end
      end
    end
  elseif scrn == 2 then
    for i=5,8 do
      if metro[i].playing == true then
        for l=octaveseqstart[i - 4 ],octaveseqlen[i - 4] do
          g.led(l+9, 1, true==metro[i].playing and 3 or 0)-- 0==steps[l] and 3 or 6)
        end
      end
    end
    for i=1,TRACKS do
      g.led(5,i,4) -- tempo center mark
      g.led(13,i,4) -- bpm mark
      -- tempo mult
      g.led(data[pattern].clockmult[i],i,15)
      -- transpose
      if alt == false then
        g.led(data[pattern].transpose[i] + 9, i, 15)
      elseif alt == true then
          g.led(data[pattern].transpose[i] + 9, i, 6)
          g.led(clockseqdiv[i] + 9, i, 15)
        end
      end
    for i=1,3 do
      for l=data[pattern].startpos[i + 1],data[pattern].lengt[i + 1 ] do
        g.led(l, i + 4, 0==data[pattern].steps[l] and 3 or 6)
      end
      if metro[i+1].playing then
        g.led(position[i+1],i + 4, 0==data[pattern].steps[position[i+1]] and 9 or 15)
      end
    end
  elseif scrn == 3 then
    --pattern selection
    for i=1,16 do
      g.led(i,1,i==pattern and 15 or 3 )
      g.led(lastsaved,1,lastsaved == pattern and 15 or 6)
      for l=data.meta_startpos,data.meta_lengt do
        g.led(l,2,true==meta.playing and 9 or 3 )
        g.led(params:get("meta_div"),3,15)
      end
    end
    for i=1,TRACKS do
      for l=data[pattern].startpos[i],data[pattern].lengt[i] do
        g.led(l, i + 3, 0==data[pattern].steps[l] and 3 or 6)
      end
      if metro[i].playing then
        g.led(position[i],i + 3, 0==data[pattern].steps[position[i]] and 9 or 15)
      end
    end
  -- note values
  elseif scrn == 4 then
    for i=1,7 do
      for n =1,data[pattern].notevals[i] do
        g.led(n,i,3)
        for p=1,TRACKS do
          g.led(data[pattern].notevals[i],i,data[pattern].notevals[i]==dispnote and 9 or 3)
          end
        end
      end
    end
  g.refresh()
  dispnote = 0
end

cleanup = function()
  save_project(project)
end
