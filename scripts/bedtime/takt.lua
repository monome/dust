-- takt
--
--
-- takt is a parameter locking
-- sequencer
--
-- row 1
-- key 1 - start/stop
-- key 15/16 - shift/alt
--
-- press step to enter lock edit mode
-- hold step to remove trig
--
-- shift + column 16 - mutes
-- shift + 1-15 - per track dividers
--
--
-- hold btn 1 to enter main menu
--
--

engine.name = 'Ack'
local Ack = require "jah/ack"
local beatclock = require 'beatclock'
local tab = require 'tabutil'

data = {}

local engine_params = {"speed",  "sampleStart","volumeEnvAttack", "volumeEnvRelease",  "delaySend", "reverbSend","volume", "filterCutoff", "filterRes" }
local lock_params = {"_speed","_start_pos","_vol_env_atk", "_vol_env_rel", "_delay_send", "_reverb_send" ,"_vol", "_filter_cutoff", "_filter_res", "_filter_env_mod", "_filter_mode", "_dist", "_pan", "_reverb_send","_filter_env_atk", "_filter_env_rel" }
local disp_meters = {" %"," %"," ms", " ms"," dB",  " dB", " dB", " Hz", " %","","","%","",""}
local tablenames = {"steps_rpt", "steps_rpt_div", "steps_prob", "steps_div", "steps"}
local ui_menu =   {"SPD: ","POS: ", "ATK: ", "REL: ","DEL: ", "REV: " , "VOL: ", "CUT: ", "RES: ","ENV: ", "FLT: ", "DST: " }
local ui_alt_menu =   {"LOOP: ", "LPOS: ","FATK: ", "FREL: " , "MUTE: ", "", "REVERB: ", "SIZE: ", "DAMP: ", "DELAY: ", "TIME: ", "FDBK: "}
local alt_lock_params = {"_loop", "_loop_point", "_filter_env_atk" ,"_filter_env_rel", "_in_mutegroup", "_pan","reverb_level", "reverb_room_size", "reverb_damp", "delay_level", "delay_time", "delay_feedback"}
local ui_lock_menu =   {"SPD: ", "POS: ","ATK: ", "REL: ", "DEL: ", "REV: " ,"VOL: ", "CUT: ", "RES: ", "RPT: ", " / ",  "PRB:  ", "DIV: "}

local val = {}
local next_val = {}
local last_val = {}
local project = 1
local pattern = 1
local patternview = false
local stepsview = true
local mainmenu  = false
local trackeditmode = true
local alttrackeditmode = false
local lockeditmode = false
local patselect = pattern
local down_time = 0
local hold_time = 0
local voice_lock = 1
local step_lock = 1
local disptrack = 1
local enc_line = 1
local metapos = 1
local metaplay = false
local copy_mode = false
local blink = false
local copy_source_x = -1
local copy_source_y = -1
local position = 1
local mute = {}
local trigdisp = {0,0,0,0,0,0,0}
local voicepos = {0,0,0,0,0,0,0}
local VOICES = 7
local alt = false
local shift = false
local ct = 0
local held = {}
local heldmax = {}
local first = {}
local second = {}
local loadchannel = 1
local metroicon = 0
local filesel = false
local project_to_load = 1
local project_to_save = 16
local pattern_to_copy = pattern

local function load_sample(file)
  if file ~= "cancel" then
    if file:find(".aif") or file:find(".wav") then
      params:set(loadchannel.."_sample",file)
    else
      print("not a sound file")
    end
    filesel = false
    redraw()
  end
end

local function textentry_callback(txt)
  if txt then
    data.name = txt
  else
  end
  redraw()
end

local function simplecopy(obj)
  if type(obj) ~= 'table' then return obj end
  local res = {}
  for k, v in pairs(obj) do
    res[simplecopy(k)] = simplecopy(v)
  end
  return res
end

local function copy_pattern(src,dst)
  data[dst] = simplecopy(data[src])
end

local function tempmod(tr,div)
  data[pattern].tempdivtr[tr] = div
  for i=1,VOICES do
    voicepos[i] = position
  end
end

local function set_loop(tr,startp,seql)
  if startp == 1 and seql == 16 then
    tempmod(tr,data[pattern].tempdivtr[tr])
  else
    data[pattern].startpos[tr] = startp
    data[pattern].seqlen[tr] = seql
  end
end

local function save_project(num)
  data[pattern].bpm = params:get("bpm")
  tab.save(data,"/home/we/dust/data/bedtime/takt-pat-"..num ..".data")
  params:write("bedtime/takt-param-"..num ..".pset")
end

local function load_project(num)
  saved_data = tab.load("/home/we/dust/data/bedtime/takt-pat-"..num ..".data")
  if saved_data ~= nil then
    data = saved_data
    params:read("bedtime/takt-param-"..num  .. ".pset")
    pattern = 1
    params:set("bpm", data[pattern].bpm) -- load bpm
    for v=1,VOICES do -- set loop points
      set_loop(v,data[pattern].startpos[v],data[pattern].seqlen[v])
    end
    redraw()
  else
    print("no file")
  end
end

local function switch_pattern(pat)
  pattern = pat
  for v=1,VOICES do
    set_loop(v,data[pattern].startpos[v],data[pattern].seqlen[v])
  end
end

local function randomize_locks(v,p)
  local max_clamp = {500,100,100,1200,0,0,0,20000,100}
  local min_clamp = {0,0,0,0,-60,-60,-30,0,0}
  local delta_mult = {0.01,0.01,0.01,0.01,1,1,1,1,0.01}
  for i=1,16 do
    if data[pattern].steps[v][i] ~= 0 then
      data[pattern].locks[lock_params[p]][v][i] = math.random(min_clamp[p], max_clamp[p]) * delta_mult[p]
    end
  end
end

local function erase_locks(voice)
  for i=1,16 do
    for p = 1,#engine_params do
    data[pattern].locks[lock_params[p]][voice][i] = 0
    end
  end
end

local function erase_lock(voice,step,lock)
  data[pattern].locks[lock_params[lock]][voice][step] = 0
  redraw()
end

local function erase_step(voice,step)
  local defaults = {0,1,100,0,0,0}
  for i=1,#tablenames do
    data[pattern][tablenames[i]][voice][step] = defaults[i]
    end
  for i=1,#engine_params do
    data[pattern].locks[lock_params[i]][voice][step] = 0
  end
end

local function copy_step(x1,y1,x2,y2)
  for i=1,#tablenames do
    data[pattern][tablenames[i]][y2][x2] = data[pattern][tablenames[i]][y1][x1]
  end
  for i=1,#engine_params do
    data[pattern].locks[lock_params[i]][y2][x2] = data[pattern].locks[lock_params[i]][y1][x1]
  end
end

local function read_locks(voice, step)
  for i=1,#engine_params do
    val[voice][i] = data[pattern].locks[lock_params[i]][voice][step]
    next_val[voice][i] = data[pattern].locks[lock_params[i]][voice][step + 1]
    if val[voice][i] ~= 0 and next_val[voice][i] ~= val[voice][i] then
      last_val[voice][i] = val[voice][i]
      data[pattern].displocks[lock_params[i]][voice] = 1
      engine[engine_params[i]](voice - 1, val[voice][i])
    end
  end
end

local function reset_params(voice)
  for i=1,#engine_params do
    if data[pattern].steps[voice][voicepos[voice]] ~= 0 and next_val[voice][i] ~= val[voice][i] then
      engine[engine_params[i]](voice - 1, params:get(voice .. lock_params[i]))
      data[pattern].displocks[lock_params[i]][voice] = 0
    elseif val[voice][i] ~= 0 then
      data[pattern].displocks[lock_params[i]][voice] = 0
    end
  end
end

local function prelisten()
  read_locks(voice_lock,step_lock)
  engine.trig(voice_lock-1)
end


local function metaseq()
  if ct % (data.metatempdiv > 0 and data.metatempdiv or data.metatempdivpat[pattern]) == 0 then
    if metaplay == true then
      if data.metastartpos > 1 then
        metapos = util.clamp(((metapos  %  data.metaseqlen) + 1),data.metastartpos,data.metaseqlen)
      else
        metapos = (metapos  %  data.metaseqlen) + 1
      end
      if data.metaval[metapos] ~= 0 then
       switch_pattern(data.metaval[metapos])
       end
    if not filesel then redraw() else end
    end
  end
end

local function draw_bar()
  screen.level(not lockeditmode and 3 or 8 )
  screen.rect(0,0,128,11)
  screen.fill()
  if trackeditmode or alttrackeditmode then
    screen.level(0)
    screen.rect(2,2,8,8)
    screen.stroke()
    screen.move(4,8)
    screen.text(not lockeditmode and disptrack or voice_lock)
    if lockeditmode then
      screen.move(16,8)
      screen.text_center(step_lock)
      screen.rect(12,2,10,8)
      screen.stroke()
    end
  screen.level(enc_line == 0 and 15 or 0)
  screen.move ((trackeditmode or alttrackeditmode) and not lockeditmode and 12 or 24 ,8)
  screen.text(params:string((not lockeditmode and disptrack or voice_lock) .."_sample"))
  end
  screen.level(not lockeditmode and 3 or 8 )
  screen.rect((metaplay == true and 91 or 100),0,(metaplay == true and 37 or 28),11)
  screen.fill()
  screen.level(0)
  screen.move(102,8)
  screen.line(107,3)
  screen.line(112,8)
  screen.line(103,8)
  screen.stroke()
  screen.move(107,6)
  screen.line(metroicon <=1 and 103 or 111,2)
  screen.stroke()
  screen.level(mainmenu and enc_line == 6 and 15 or 0)
  screen.move(127,8)
  screen.text_right(""..params:get("bpm"))
  if metaplay == true then
    screen.level(metroicon <=1 and 0 or 15)
    screen.move(94,8)
    screen.text("M")
  end
end

local function count()
  ct = ct + 1
  for v = 1,VOICES do
    if ct % (data[pattern].tempdiv[v] > 0 and data[pattern].tempdiv[v] or data[pattern].tempdivtr[v]) == 0 then
      --reset_params(v)
      position = (position % 16) + 1
      voicepos[v] = util.clamp((voicepos[v] % data[pattern].seqlen[v]) + 1, data[pattern].startpos[v], data[pattern].seqlen[v]) -- voice pos
      position = voicepos[v]
      if data[pattern].steps[v][voicepos[v]] ~= 0 then
        if data[pattern].steps_prob[v][voicepos[v]] >= math.random(100) and mute[v] == 0 then
          reset_params(v)
          trigdisp[v] = 15
          if data[pattern].steps_div[v][voicepos[v]] > 0 then
            data[pattern].tempdiv[v] = data[pattern].steps_div[v][voicepos[v]]
          elseif data[pattern].steps_div[v][voicepos[v]] == 0 then
            data[pattern].tempdiv[v] = 0
          end
          read_locks(v,voicepos[v])
          engine.trig(v-1)
          if data[pattern].steps_rpt[v][voicepos[v]] > 0 then
            local rpt_time = ( params:get("bpm") / 7000 )
            metro[v].count = data[pattern].steps_rpt[v][voicepos[v]]
            metro[v].time = rpt_time * data[pattern].steps_rpt_div[v][voicepos[v]]
            metro[v].callback = function() engine.trig(v-1) end
            metro[v]:start()
            end
        else
          trigdisp[v] = 9
        end
      end
    end
  metroicon = (metroicon + 1) % 4
  end
  if filesel then else redraw() end
end

function init()
  for i=1,VOICES do
    metro.alloc(i)
  end
  counter = beatclock.new()
  counter.on_step = function() count() metaseq() end
  counter:add_clock_params()
  metro_grid_redraw = metro.alloc(function(stage) grid_redraw() end, 1 / 30)
  metro_grid_redraw:start()
  metro_blink = metro.alloc(function(stage) blink = not blink end, 1 / 4)
  metro_blink:start()
  params:add_separator()
  Ack.add_effects_params()
  params:add_separator()
  for channel=1,VOICES do
    Ack.add_channel_params(channel)
  end
  params:bang()
  -- init patterns
  data.metaseqlen = 16
  data.metastartpos = 1
  data.metatempdiv = 1
  data.metaval = {}
  data.metatempdivpat = {}
  for i=1,16 do
    data[i] = {}
    data[i].bpm = 110
    data[i].steps = {}
    data[i].steps_rpt = {}
    data[i].steps_rpt_div = {}
    data[i].steps_div = {}
    data[i].steps_prob = {}
    data[i].seqlen = {}
    data[i].startpos = {}
    data[i].tempdiv = {}
    data[i].tempdivtr = {}
    data.metaval[i] = 0
    data.metatempdivpat[i] = 1
    for v=1,VOICES do
      mute[v] = 0
      data[i].steps[v] = {}
      data[i].steps_rpt[v] = {}
      data[i].steps_rpt_div[v] = {}
      data[i].steps_div[v] = {}
      data[i].steps_prob[v] = {}
      data[i].seqlen[v] = 16
      data[i].startpos[v] = 1
      data[i].tempdiv[v] = 1
      data[i].tempdivtr[v] = 1
      for l=1,16 do
        table.insert(data[i].steps[v],0)
        table.insert(data[i].steps_rpt[v],0)
        table.insert(data[i].steps_rpt_div[v],1)
        table.insert(data[i].steps_div[v],0)
        table.insert(data[i].steps_prob[v],100)
      end
    end
  end
  -- init locks data
  for p=1,#data do
    data[p].locks = {}
    data[p].displocks = {}
    for i= 1,#engine_params do
      held[i] = 0
      heldmax[i] = 0
      first[i] = 0
      second[i] = 0
      data[p].locks[lock_params[i]] = {}
      data[p].displocks[lock_params[i]] = {}
      for v = 1,VOICES do
        val[v] = {}
        next_val[v] = {}
        last_val[v] = {}
        data[p].locks[lock_params[i]][v] = {}
        data[p].displocks[lock_params[i]][v] = 0
        for l=1,16 do
          data[p].locks[lock_params[i]][v][l] = 0
        end
      end
    end
  end
end

g = grid.connect()

g.event = function(x,y,z)
  if z==1 and held[y] then
    heldmax[y] = 0
  end
  held[y] = held[y] + (z*2-1)
  if held[y] > heldmax[y] then
    heldmax[y] = held[y]
  end
  if z == 1 then
    if y == 8 then
      if x == 1 then
        if counter.playing then
          counter:stop()
        else
          counter:start()
        end
      elseif x == 9 then
        if patternview then
          stepsview = true
          patternview = false
        else
          patternview = true
          stepsview = false
        end
      elseif x == 16 then
        shift = true
      elseif x == 15 then
        alt = true
      elseif x == 13 then
        copy_mode = true
        copy_source_x = step_lock
        copy_source_y = voice_lock
      end
    end
  elseif z == 0 then
    if y == 8 then
      if x == 16 then shift = false
      elseif x == 15 then alt = false
      elseif x == 13 then copy_mode = false
      end
    end
  end
  if copy_mode then
    if stepsview then
      if y == 8 and x == 12 and z == 1 then
        randomize_locks(lockeditmode and voice_lock or disptrack,2)
        redraw()
      elseif y == 8 and x == 11 and z == 1 then
        randomize_locks(lockeditmode and voice_lock or disptrack,1)
        redraw()
      elseif y == 8 and x == 14 and z == 1 then
        erase_locks(lockeditmode and voice_lock or disptrack)
        redraw()
      elseif y < 8 and z == 1 then
        if copy_source_x ~= -1 and not (copy_source_x == x and copy_source_y == y) then
          copy_step(copy_source_x,copy_source_y,x,y)
        end
      end
    elseif patternview then
      if y == 1 and z == 1 then
        copy_pattern(patselect, x)
      end
    end
  end
  if stepsview then
    if not alt and not shift then
      if z == 1 then down_time = util.time()
      else hold_time = util.time() - down_time
      if y == 8 and x == 5 and lockeditmode then prelisten()
      elseif  y < 8 then
          data[pattern].steps[y][x] = y
          if data[pattern].steps[y][x] == y and hold_time > 0.3 then
            erase_step(y,x)
            lockeditmode = false
            if enc_line > 10 then enc_line = enc_line - 1 end
          elseif data[pattern].steps[y][x] == y and hold_time < 0.3 then
            if not mainmenu then
              lockeditmode = true
              if enc_line == 0 then enc_line = 1 end
            end
            voice_lock = y
            step_lock = x
          end
        end
        if not filesel then redraw() end
      end
    elseif alt then
      if y < 8 then
      -- select step lock
          if held[y] == 1 then
            first[y] = x
          elseif held[y] == 2 then
            second[y] = x
            data[pattern].startpos[y] = first[y]
            data[pattern].seqlen[y] = second[y]
            set_loop(y, data[pattern].startpos[y], data[pattern].seqlen[y])
          end
        end
      end
    if shift and y < 8 then
      if x < 16 then
        tempmod(y,x)
        data[pattern].tempdiv[y] = x
      elseif x == 16 and z == 1 then
        if mute[y] == 0 then
          mute[y] = 1
        else
          mute[y] = 0
        end
      end
    end
  end
  if patternview then
    if z == 1 and not shift then
      if y == 1 and not alt then
        if x ~= patselect then
          patselect = x
        elseif patselect == x then
        switch_pattern(x)
        end
      elseif y == 2 then
          if data.metaval[x] == 0 then
            data.metaval[x] = patselect
          elseif data.metaval[x] ~= patselect then
            data.metaval[x] = patselect
          else
            data.metaval[x] = 0
          end
      elseif  y == 3 then
        if held[y]==1 then
          first[y] = x
        elseif held[y]==2 then
          second[y] = x
          data.metastartpos = first[y]
          data.metaseqlen = second[y]
        end
      elseif y == 4 then
        data.metatempdiv = x * 4
      elseif y == 6 and x == 2 then
        if metaplay == true then
          metaplay = false
        else
          metaplay = true
          metapos = util.clamp(position, data.metastartpos,data.metaseqlen)
        end
      end
    elseif z == 1 and shift then
      if x == 16 and shift and z == 1 then
        if mute[y] == 0 then
          mute[y] = 1
        else
          mute[y] = 0
        end
      end
    end
  end
end

function grid_redraw()
  g.all(0)
  g.led(1,8, counter.playing and 15 or 6) -- play/stop
  g.led(9,8, patternview and 15 or 6) -- alt
  g.led(16,8, shift and 15 or 6) -- alt
  g.led(15,8, alt and 9 or 3) -- shift
  g.led(13,8, copy_mode and 9 or 3)
  g.led(5,8,lockeditmode and 2 or 0) -- prelisten
  if copy_mode and not patternview then
    g.led(11,8,blink and 3  or 1)
    g.led(12,8,blink and 3 or 1)
    g.led(14,8,blink and 3 or 1)
  end
  if patternview then
    g.led(2,6, metaplay and 15 or blink and 6 or 3)
    for i=1,16 do
      g.led(i,1, i == pattern and 15 or i == patselect and blink and 9 or 4)
      g.led(i,2,  data.metaval[i] == 0 and 0 or 8)
      g.led(i,3, (i < data.metastartpos or i > data.metaseqlen) and 0 or 6)
    end
    if shift then
      for v=1,VOICES do
        g.led(15,v,0)
        g.led(16,v,mute[v]== 1 and 15 or 6)
      end
    end
    if metaplay then
      g.led(metapos,2,15)
    end
    g.led(data.metatempdiv == 1 and data.metatempdiv or data.metatempdiv / 4 ,4,9)
    g.led(position,7,metaplay and 9 or 3)
  elseif stepsview then
    if not shift then
      for i=1,16 do
        for v=1,VOICES do
          if alt then
            for i = data[pattern].startpos[v],data[pattern].seqlen[v] do
              g.led(i,v, 0==data[pattern].steps[v][i] and 2 or 6 )
            end
            if mute[v] == 0 then
              g.led(voicepos[v],v,3)
            end
          else
          g.led(i,data[pattern].steps[v][i],
                mute[v] == 1 and 3
                or copy_mode and copy_source_x == i and copy_source_y == v and blink and 4
                or step_lock == i and voice_lock == v and lockeditmode == true and 13
                or i < data[pattern].startpos[v] and 2
                or i > data[pattern].seqlen[v] and 2
                or 8)
          if counter.playing then
            if mute[v] == 0 then
              g.led(voicepos[v],v,0==data[pattern].steps[v][voicepos[v]] and 3 or trigdisp[v])
            else
              g.led(voicepos[v],v,1==data[pattern].steps[v][voicepos[v]] and 3 or 1)
            end
          end
        end
      end
    end
    elseif shift then
      for i=1,16 do
        for v=1,VOICES do
          g.led(i,data[pattern].steps[v][i],alt == false and 2 or 4)
          g.led(14,v,1)
          g.led(16,v,mute[v]== 1 and 15 or 6)
          if mute[v] == 0 then
            g.led(voicepos[v] < data[pattern].seqlen[v] and voicepos[v] or 1,v,voicepos[v] == 16 and 16 or 3 )
          end
            g.led((data[pattern].tempdiv[v] > 0 and data[pattern].tempdiv[v] or data[pattern].tempdivtr[v]),v,9)
        end
      end
    end
  end
  g.refresh()
end

function key(n, z)
  if n == 1 and z == 1 then
    if (trackeditmode or lockeditmode or alttrackeditmode) then
      mainmenu = true
      alttrackeditmode = false
      trackeditmode = false
      lockeditmode = false
    elseif mainmenu then
      alttrackeditmode = false
      trackeditmode = true
      lockeditmode = false
      mainmenu = false
    end
    enc_line = 2
    redraw()
  elseif n == 2 and z == 1 then
    if enc_line == 0 then
      enc_line = 1
      trackeditmode = false
      alttrackeditmode = true
    else
      if lockeditmode then
        disptrack = voice_lock
        loadchannel = disptrack
        lockeditmode = false
        trackeditmode = true
      elseif trackeditmode  then
        if enc_line > 10 then enc_line = enc_line - 1 end
          disptrack = disptrack - 1
          filesel = false
        if disptrack <= 0 then disptrack = 7 end
          disptrack = util.clamp(disptrack,1,VOICES)
      elseif mainmenu then
        mainmenu = false
        trackeditmode = true
      elseif alttrackeditmode then
        alttrackeditmode = false
        trackeditmode = true
        enc_line = enc_line == 1 and enc_line - 1 or enc_line
      end
    end
    redraw()
  elseif n == 3 and z == 1 then
    if mainmenu then
      if enc_line == 1 then
        textentry.enter(textentry_callback, data.name == nil and ("untitled ".. project) or data.name)
      elseif enc_line == 2 then
        load_project(project_to_load) project = project_to_load
      elseif enc_line == 5 then
        copy_pattern(pattern, pattern_to_copy)
      elseif enc_line == 3  then
        save_project(project_to_save)
      end
      redraw()
    elseif lockeditmode then
      erase_lock(voice_lock,step_lock, enc_line)
    elseif trackeditmode then
      if enc_line == 0 then
        loadchannel = disptrack
        filesel = true
        fileselect.enter("/home/we/dust/audio", load_sample)
      else
        disptrack = disptrack + 1
        filesel = false
        if disptrack >= 8 then disptrack = 1 end
        disptrack = util.clamp(disptrack,1,VOICES)
      end
    end
  end
  if filesel then else redraw() end
end

function enc(n,d)
  norns.encoders.set_sens(2,2)
  norns.encoders.set_sens(3,2)
  norns.encoders.set_accel(3, not mainmenu and true or false)
  if n == 1 then
    mix:delta("output",d)
  elseif n == 2 then
    enc_line = util.clamp(enc_line + d, (trackeditmode and not lockeditmode  )and 0 or 1,
    lockeditmode and #ui_lock_menu
    or alttrackeditmode and #ui_alt_menu
    or trackeditmode and #ui_menu
    or mainmenu and 6)
  elseif n == 3 then
    if mainmenu then
      if enc_line == 2 then
        project_to_load = util.clamp(project_to_load + d,1,16)
      elseif enc_line == 3 then
       project_to_save = util.clamp(project_to_save + d,1,16)
      elseif enc_line == 4 then
        pattern = util.clamp(pattern + d,1,16)
        switch_pattern(pattern)
      elseif enc_line == 5 then
       pattern_to_copy = util.clamp(pattern_to_copy + d,1,16)
      elseif enc_line == 6 then
        params:delta("bpm", d)
      end
    elseif lockeditmode == false then
      if not alttrackeditmode then
        if enc_line > 0 then
          params:delta(disptrack..lock_params[enc_line], enc_line == 1 and d / 10 or d)
        end
      elseif alttrackeditmode then
        params:delta((enc_line < 7 and disptrack or "" )..alt_lock_params[enc_line],d)
      end
    elseif lockeditmode == true  then
      local max_clamp = {5,1,1,12,0,0,0,20000,100,16,16,100,16,100,16}
      local min_clamp = {0.01,0.01,0,0.01,-60,-60,-60,0,0,0,1,0,0,0,0}
      local delta_mult = {0.01,0.01,0.01,0.1,1,1,1,100,0.01,0.01,1,1,1,1,1}
      local line = data[pattern].locks[lock_params[util.clamp(enc_line,1,#engine_params)]][voice_lock][step_lock]
      if enc_line < 10 then
        if data[pattern].locks[lock_params[enc_line]][voice_lock][step_lock] == 0 then
          line = params:get(voice_lock .. lock_params[enc_line])
        end
      end
      if enc_line <= 9 then
        data[pattern].locks[lock_params[enc_line]][voice_lock][step_lock] = util.clamp(line + d * delta_mult[enc_line],min_clamp[enc_line],max_clamp[enc_line])
      elseif enc_line > 9 then
        data[pattern][tablenames[enc_line - 9]][voice_lock][step_lock] = util.clamp(data[pattern][tablenames[enc_line - 9]][voice_lock][step_lock] + d, min_clamp[enc_line],max_clamp[enc_line])
      end
    end
  end
  redraw()
end

function redraw()
  if mainmenu then
    screen.clear()
    draw_bar()
    for i=1,VOICES do
      screen.level(enc_line == i and 15 or i == 5 and 1 or i == 1 and 0 or i == 3 and 1 or 2 )
      if i == 1 then
        screen.move(2,8)
        screen.text(data.name == nil and (project .. ": UNTITLED") or (project .. ": "..data.name))
      elseif i <= 3 then
        screen.move(i == 2 and i or i + 35, 20)
        screen.text(i == 2 and "LOAD: " .. project_to_load or i == 3 and "SAVE TO: " .. project_to_save)
      elseif i == 4 then
        screen.move(2,30)
        screen.text("PATTERN: " .. pattern )
      elseif i == 5 then
        screen.move(50,30)
        screen.text("COPY TO: " .. pattern_to_copy)
      end
    end
  elseif alttrackeditmode and (not trackeditmode or not lockeditmode) then
    screen.clear()
    draw_bar()
    for i=1,#ui_alt_menu do
      if i == enc_line then screen.level(15) else screen.level(2) end
      screen.move(i == 6 and 47 or i <= 6 and 2 or 62 ,(i <= 6 and i * 9 or  (i - 6 ) * 9) + (10))
      if i == 6 then screen.text_right(ui_alt_menu[i]..params:string(disptrack..alt_lock_params[i]))
      elseif i < 7 then
        screen.text(ui_alt_menu[i]..params:string(disptrack..alt_lock_params[i]))
      else
        screen.text(ui_alt_menu[i]..params:string(alt_lock_params[i]))
      end
    end
  elseif trackeditmode and not lockeditmode then
    screen.clear()
    draw_bar()
    for i=1,#ui_menu do
      if i == enc_line then screen.level(15) else screen.level(2) end
      screen.move(i <= 6 and 2 or 62 ,(i <= 6 and i * 9 or  (i - 6 ) * 9) + (10))
      if last_val[disptrack][i] ~= nil and i ~= enc_line and val[disptrack][i] ~= 0 then
        screen.level(1)
        screen.text(ui_lock_menu[i] .. util.round(last_val[disptrack][i] * (i == 4 and 1000 or i <  4 and 100 or i == 8 and 0.1 or i == 9 and 100 or i >= 7 and 1 or 1)).. disp_meters[i])
      else
        screen.text(ui_menu[i]..params:string(disptrack..lock_params[i]))
      end
    end
  else
    local disp_meters = {" %"," %"," ms", " ms"," dB",  " dB", " dB", " Hz", " %","","","%","",""}
    local thresholds  = {0,1,100,0,0}
    screen.clear()
    draw_bar()
    for i=1,#ui_lock_menu do
      if i == enc_line then screen.level(15) else screen.level(1) end
      screen.move(i == 11 and 90 or i <= 6 and 2 or 62 , i== 13 and 64 or i== 12 and 55 or i == 11 and 46 or (i <= 6 and i * 9 or  (i - 6 ) * 9) + (10))
      if data[pattern].locks[lock_params[util.clamp(i,1,9)]][voice_lock][step_lock] ~= 0 and i < 10 then
        local line = data[pattern].locks[lock_params[i]][voice_lock][step_lock]
        screen.level(enc_line == i and 16 or 4)
        if i <= 9 then
          screen.text(ui_lock_menu[i] .. util.round(line * (i == 4 and 1000 or i <  4 and 100 or i == 9 and 100 or i >= 7 and 1 or 1)) .. disp_meters[i])
          end
      elseif i > 9 then
        if data[pattern][tablenames[i - 9]][voice_lock][step_lock] ~= thresholds[i - 9] then
          screen.level(enc_line == i and 16 or 4) end
          screen.text(ui_lock_menu[i] .. data[pattern][tablenames[i - 9]][voice_lock][step_lock] ..disp_meters[i])
      else
        screen.text(ui_lock_menu[i] .. params:string(voice_lock .. lock_params[util.clamp(i,1,9)]))
      end
    end
  end
  screen.update()
end
