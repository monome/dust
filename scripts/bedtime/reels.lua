--
-- reel to reel tape player
--
-- hold btn 1 for settings
-- btn 2 play / pause
-- btn 3 rec on/off
--
-- enc 1 - switch track
-- enc 2 - change speed
-- enc 3 - overdub level

engine.name = "SoftCut"

local UI = require "mark_eats/ui"
local tab = require 'tabutil'

local playing = false
local recording = false
local filesel = false
local settings = false
local mounted = false
local warble_state = false
local tape_tension = 30
local plhead_lvl = 35 -- playhead height
local plhead_slvl = 0 -- playhead brightness
local speed = 0 -- default speed
local reel_pos_x = 28  -- default
local reel_pos_y = 21 -- default
local c_pos_x = 20
local c_pos_y = 58
local bind_vals = {20,48,80,108,0,0,0,0,0,0}
local clip_len_s = 120
local rec_vol = 0.5
local fade = 0.01
local TR = 4 -- temp
local WARBLE_AMOUNT = 10
local trk = 1
local blink = false
local r_reel = {{},{},{},{},{},{}}
local l_reel = {{},{},{},{},{},{}}
local speed_disp = {">",">>",">>>",">>>>","<","<<","<<<","<<<<"}
local reel = {}
local rec_time = 0
local play_time = {0,0,0,0}
local mutes = {true,true,true,true}


local function update_rate(i)
  local n = math.pow(2,reel.speed)
  reel.speed = math.abs(speed)
  if reel.rev == 1 then n = -n end
  engine.rate(i, n / reel.q[i])
end

local function warble(state)
  local n = {}
  if state == true then
    for i=1,TR do
      n[i] = (math.pow(2,reel.speed) / reel.q[i])
      engine.rate(i, n[i] + l_reel[i].position / WARBLE_AMOUNT)
      update_rate(i)
    end
  end
end

local function count()
  if reel.rec == 1 then
    rec_time = rec_time + (0.01 / (reel.q[trk] - math.abs(speed)))
    if reel.loop == 1 then
      if rec_time >= reel.loop_end[trk] then
        rec_time = 0
      end
    elseif reel.loop == 0 then
      if rec_time >= reel.length[trk] then
        rec_time = 0
      end
    end
  end
end

local function play_count()
  for i=1,TR do
    if reel.rev == 0 then
      play_time[i] = play_time[i] + (0.01 / (reel.q[i] - math.abs(speed / 2 )))
      if play_time[i] >= (reel.loop == 1 and reel.loop_end[i] or reel.length[i]) then
        if reel.loop == 1 then
          play_time[i] = reel.loop_start[i]
        elseif reel.loop == 0 then
          if play_time[i] > reel.length[i] then
            playing = false
            play_time[i] = 0
            for i=1,TR do
              engine.pos(i,reel.s[i])
              engine.reset(i)
              engine.stop(i)
            end
          end
        end
      end
    elseif reel.rev == 1 then
      play_time[i] = play_time[i] - (0.01 / (reel.q[i] - math.abs(speed / 2)))
      if play_time[i] <= (reel.loop == 1 and reel.loop_start[i] or 0) then
        if reel.loop == 1 then
          play_time[i] = reel.loop_end[i]
        else
          play_time[i] = reel.length[i]
        end
      end
    end
  end
  warble(warble_state)
end

local function update_params_list()
  settings_list.entries = {"Tr " .. trk .. (mutes[trk] == false and "  Vol " or " "), "Start", "End", "Quality","--","Loop", "--", "Load clip", "Save clip",  "--", "Clear clip", not mounted and "New reel" or "Clear all", "--", "Save reel", "Load reel", "Warble"}
  settings_amounts_list.entries = {mutes[trk] == false and util.round(reel.vol[trk]*100) or (reel.clip[trk] == 0 and "Load" or "muted") or "" .. util.round(reel.vol[trk]*100),util.round(reel.loop_start[trk],0.1),util.round(reel.loop_end[trk],0.1),reel.q[trk] ,"",reel.loop == 1 and "On" or "Off","","","","","","","","","", warble_state == true and "On" or "Off"}
end
-- REEL
local function set_loop(tr, st, en)
  st = reel.s[tr] + st
  en = reel.s[tr] + en
  engine.loop_start(tr,st)
  engine.loop_end(tr,en)
  if play_time[tr] > en or play_time[tr] < st then
    engine.pos(tr,s)
    play_time[trk] = reel.loop_start[trk]
  end
end

local function loop(state)
  if state == true then
    reel.loop = 1
    for i=1,TR do
      set_loop(i,reel.loop_start[i],reel.loop_end[i])
      engine.loop_on(i,1)
    end
  elseif state == false then
    reel.loop = 0
    for i=1,TR do
      set_loop(i,0,reel.loop_end[i]) --?? lenght
      engine.loop_on(i,0)
      play_time[i] = 0
    end
  end
end

local function rec(tr, state)
  if state == true then -- start rec
    if rec_time ~= 0 then
      rec_time = 0
    end
    recording = true
    if not reel.name[tr]:find("*") then
      reel.name[tr] = "*" .. reel.name[tr]
    end
    reel.rec[tr] = 1
    engine.rec_on(tr,rec_vol)
    engine.pre(tr,rec_vol)
    engine.rec(tr,rec_vol)
    counter:start()
  elseif state == false then -- stop rec
    recording = false
    reel.rec[tr] = 0
    engine.rec_on(tr,0)
    reel.clip[tr] = 1
    counter:stop()
    update_params_list()
  end
end

local function mute(tr,state)
  if state == true then
    engine.amp(tr,0)
    mutes[tr] = true
  elseif state == false then
    mutes[tr] = false
    engine.amp(tr,reel.vol[tr])
  end
end

local function play(state)
  if state == true then
    playing = true
    play_counter:start()
    for i=1,TR do
      engine.start(i)
      reel.play[i] = 1
    end
  elseif state == false then
    playing = false
    play_counter:stop()
    for i=1,TR do
    if reel.rec[i] == 1 then rec(i,false) end
      engine.stop(i)
      reel.play[i] = 0
    end
  end
end

-- not working
local function clear_track(tr)
  reel.clip[tr] = 1
  engine.clear_range(reel.s[tr], clip_len_s * 48000)
  print("Clear buffer region " .. reel.s[tr] + clip_len_s * 48000)
end
-- PERSISTENCE
local function new_reel()
  engine.clear()
  reel.name = {"-","-","-","-"}
  settings_list.index = 1
  settings_amounts_list.index = 1
  rec_time = 0
  playing = false
  for i=1,TR do
    table.insert(reel.q,1)
    table.insert(reel.play,0)
    table.insert(reel.loop_end,16)
    table.insert(reel.length,120)
    table.insert(reel.clip,0)
    set_loop(i,0,reel.loop_end[i])
    engine.pos(i,reel.s[i])
    engine.reset(i)
    engine.stop(i)
  end
  mounted = true
  loop(true)
  update_params_list()
end

local function load_clip(path)
  if path ~= "cancel" then
    if path:find(".aif") or path:find(".wav") then
      local ch, len = sound_file_inspect(path)
      --print("file length > "..len/48000)
      --print("file > "..path.." "..reel.s[trk])
      engine.read(path, reel.s[trk], len/48000)
      reel.paths[trk] = path
      reel.clip[trk] = 1
      reel.name[trk] = path:match("[^/]*$")
      reel.length[trk] = len/48000
      reel.e[trk] = reel.s[trk] + len/48000
      reel.loop_end[trk] = reel.length[trk]
      engine.amp(trk, reel.vol[trk])
      mute(trk,false)
      mounted = true
      engine.pos(trk,reel.s[trk])
      engine.reset(trk)
      update_rate(trk)
      update_params_list()
      -- default loop on
      set_loop(trk,0,reel.loop_end[trk])
      loop(true)
      if not playing then engine.stop(trk) end
    else
      print("not a sound file")
    end
  end
  settings = true
  filesel = false
end

local function load_reel_data(pth)
  saved = tab.load(pth)
  if saved ~= nil then
    print("reel data found")
    reel = saved
  else
    print("no reel data")
  end
end

local function load_mix(path)
  if path ~= "cancel" then
    if path:find(".reel") then
      load_reel_data(path)
      trk = 1
      for i=1,TR do
        if reel.name[i] ~= "-" then
          --print("reading file > " ..reel.paths[i])
          load_clip(reel.paths[i])
          trk = util.clamp(trk + 1,1,TR)
          mounted = true
          play_time[i] = reel.loop_start[i]
          engine.pos(i,reel.s[i] + reel.loop_start[i])
          engine.reset(i)
          update_rate(i)
          engine.stop(i)
          update_params_list()
        end
      end
    else
      print("not a reel file")
    end
  end
  trk = 1
  settings = true
  filesel = false
end

local function save_clip(txt)
  if txt then
    local c_start = reel.s[trk]
    local c_len = reel.e[trk]
    print("SAVE " .. audio_dir .. txt .. ".aif", c_start, c_len)
    engine.write(audio_dir..txt..".aif",c_start,c_len)
    reel.name[trk] = txt
  else
    print("save cancel")
  end
  filesel = false
end

local function save_project(txt)
  if txt then
    reel.proj = txt
    for i=1,TR do
      if reel.name[i] ~= "-" then
        if reel.name[i]:find("*") then
          local name = reel.name[i] == "*-" and (txt .. "-rec-" .. i .. ".aif") or reel.name[i]:sub(2,-1) -- remove asterisk
          local save_path = audio_dir .."reels/" .. name
          reel.paths[i] = save_path
          print("saving "..i .. "clip at " .. save_path, reel.s[i],reel.e[i])
          engine.write(audio_dir.."reels/" .. name, reel.s[i],reel.e[i])
        end
      end
    end
    tab.save(reel, audio_dir.."reels/".. txt ..".reel")
  else
    print("save cancel")
  end
  filesel = false
end
-- UI
local function update_reel()
  for i=1,6 do
    l_reel[i].velocity = util.linlin(0, 1, 0.01, (speed/1.9)/(reel.q[1]/2), 0.15)
    l_reel[i].position = (l_reel[i].position - l_reel[i].velocity) % (math.pi * 2)
    l_reel[i].x = 30 + l_reel[i].orbit * math.cos(l_reel[i].position)
    l_reel[i].y = 25 + l_reel[i].orbit * math.sin(l_reel[i].position)
    r_reel[i].velocity = util.linlin(0, 1, 0.01, (speed/1.5)/(reel.q[1]/2), 0.15)
    r_reel[i].position = (r_reel[i].position - r_reel[i].velocity) % (math.pi * 2)
    r_reel[i].x = 95 + r_reel[i].orbit * math.cos(r_reel[i].position)
    r_reel[i].y = 25 + r_reel[i].orbit * math.sin(r_reel[i].position)
  end
end

local function animation()
  if playing == true then
    update_reel()
    if plhead_lvl > 31 then
      plhead_lvl = plhead_lvl - 1
    elseif plhead_lvl < 32 and plhead_lvl > 25 then
      plhead_lvl = plhead_lvl - 1
    end
    if tape_tension > 20 and plhead_lvl < 32  then
      tape_tension = tape_tension - 1
      plhead_slvl = util.clamp(plhead_slvl + 1,0,5)
    end
  elseif playing == false then
    if plhead_lvl < 35 then
      plhead_lvl = plhead_lvl + 1
    elseif plhead_lvl > 25 then
      end
    if tape_tension < 30 then
      tape_tension = tape_tension + 1
      plhead_slvl = util.clamp(plhead_slvl - 1,0,5)
    end
  end
  if settings == true and reel_pos_x > -20 then
    reel_pos_x = reel_pos_x - 5
  elseif settings == false and reel_pos_x <= 30 then
    reel_pos_x = reel_pos_x + 5
  end
  -- cursor position
  if c_pos_x ~= bind_vals[trk] then
    if c_pos_x <= bind_vals[trk] then
      c_pos_x = util.clamp(c_pos_x + 3,bind_vals[trk]-20,bind_vals[trk])
    elseif c_pos_x >= bind_vals[trk] then
      c_pos_x = util.clamp(c_pos_x - 3,bind_vals[trk],bind_vals[trk]+20)
    end
  end
end

local function draw_reel(x,y)
  local l = util.round(speed * 10)
  if l < 0 then
    l = math.abs(l) + 4
  elseif l >= 4 then
    l = 4
  end
  screen.level(1)
  screen.line_width(1.9)
  local pos = {1,3,5}
  for i = 1, 3 do
    screen.move((x + r_reel[pos[i]].x) - 30, (y + r_reel[pos[i]].y) - 25)--, 0.5)
    screen.line((x + r_reel[pos[i]+1].x) - 30, (y + r_reel[pos[i]+1].y) - 25)
    screen.stroke()
    screen.move((x + l_reel[pos[i]].x) - 30, (y + l_reel[pos[i]].y) - 25)--, 0.5)
    screen.line((x + l_reel[pos[i]+1].x) - 30, (y + l_reel[pos[i]+1].y) - 25)
    screen.stroke()
  end
  screen.line_width(1)
  -- speed icons >>>>
  screen.move(x + 32, y + 2)-- - 19)
  screen.level(speed == 0 and 1 or 6)
  screen.text_center(speed_disp[util.clamp(l,1,8)])
  screen.stroke()
  --
  screen.level(1)
  screen.circle(x+5,y+28,2)
  screen.fill()
  screen.circle(x+55,y+28,2)
  screen.fill()
  screen.level(0)
  screen.circle(x+5,y+28,1)
  screen.circle(x+55,y+28,1)
  screen.fill()
  --right reel
  screen.level(1)
  screen.circle(x+65,y,1)
  screen.stroke()
  screen.circle(x+65,y,20)
  screen.stroke()
  screen.circle(x+65,y,3)
  screen.stroke()
  -- left
  screen.circle(x,y,20)
  screen.stroke()
  screen.circle(x,y,1)
  screen.stroke()
  screen.circle(x,y,3)
  screen.stroke()
  -- tape
  if mounted then
    if reel.loop == 1 then
      screen.level(6)
      screen.move(x,y-17)
      screen.line(x+65,y-12)
      screen.stroke()
    end
    screen.level(6)
    screen.circle(x,y,18)
    screen.stroke()
    screen.level(3)
    screen.circle(x,y,17)
    screen.stroke()
    screen.level(6)
    screen.circle(x+65,y,14)
    screen.stroke()
    screen.level(3)
    screen.circle(x+65,y,13)
    screen.stroke()
    screen.level(6)
    screen.move(x+75,y+10)
    screen.line(x+55,y+30)
    screen.stroke()
    screen.move(x-9,y+16)
    screen.line(x+5,y+30)
    screen.stroke()
    screen.move(x+5,y+30)
    screen.curve(x+40,y+tape_tension,x+25,y+tape_tension,x+56,y+30)
    screen.stroke()
  end
  -- playhead
  screen.level(plhead_slvl)
  screen.circle(x + 32,y + plhead_lvl + 1,3)
  screen.rect(x + 28,y + plhead_lvl,8,4)
  screen.fill()
end

local function draw_bars(x,y)
  for i=1,TR do
    screen.level(mutes[i] and 1 or reel.rec[i] == 1 and 9 or 3)
    screen.rect((x * i *2) - 24,y,26,3)
    screen.stroke()
    if reel.loop == 1 then
      screen.level(mutes[i] and 1 or reel.rec[i] == 1 and 9 or 3)
      screen.rect((x * i *2) - 24,y,25,3)
      screen.fill()
      screen.stroke()
      screen.level(0)
      -- display loop start / end points
      screen.rect(((x * i *2) - 24) + (reel.loop_start[i] / reel.length[i] * 25), 61, (reel.loop_end[i] / reel.length[i] * 25) - (reel.loop_start[i] / reel.length[i] * 25), 2)
      screen.fill()
      end
    screen.level(15)
    screen.move(((x * i *2) - 24) + (((play_time[i]) / (reel.length[i]) * 25)), 61)
    screen.line_rel(0,2)
    screen.stroke()
  end
end

local function draw_cursor(x,y)
  screen.level(9)
  screen.move(x-3,y-3)
  screen.line(x,y)
  screen.line_rel(3,-3)
  screen.stroke()
end

local function draw_rec_vol_slider(x,y)
  screen.level(1)-- 28 21
  screen.move(x - 30, y - 17)
  screen.line(x - 30, y + 29)
  screen.stroke()
  screen.level(6)
  screen.rect(x - 33, 48 - rec_vol / 3 * 132  ,5,2)
  screen.fill()
end

function init()
  reel.proj = "untitled"
  reel.s = {}
  reel.e = {}
  reel.paths = {}
  reel.name = {"-","-","-","-"}
  reel.play = {0,0,0,0}
  reel.rec = {0,0,0,0}
  reel.rec_level = 1
  reel.pre_level = 0
  reel.loop = 0
  reel.loop_start = {0,0,0,0}
  reel.loop_end = {16,16,16,16}
  reel.vol = {1,1,1,1}
  reel.clip = {0,0,0,0}
  reel.pos = 0
  reel.speed = 0
  reel.rev = 0
  reel.length = {16,16,16,16}
  reel.q = {1,1,1,1}

  for i=1,TR do
    engine.rec_on(i,1) -- always on!!
    engine.pre(i,1)
    engine.pre_lag(i,0.01)
    engine.fade_pre(i,fade)
    engine.amp(i,1)
    engine.rec(i,0)
    engine.rec_lag(i,0.01)
    engine.fade_rec(i,fade)
    engine.adc_rec(1,i,0.8)
    engine.adc_rec(2,i,0.8)
    engine.play_dac(i,1,1)
    engine.play_dac(i,2,1)
    engine.loop_start(i,reel.s[i])
    engine.loop_end(i,reel.e[i])
    engine.loop_on(i,0)
    engine.fade_rec(i,0.01)
    engine.fade(i,fade)
    engine.env_time(i,0.01)
    engine.rate_lag(i,0.6)
    reel.s[i] = (i-1)*clip_len_s
    reel.e[i] = reel.s[i] + (clip_len_s - 2)
  end
  -- reel graphics
  for i=1,6 do
    r_reel[i].orbit = math.fmod(i,2)~=0 and 6 or 15
    r_reel[i].position = i <= 2 and 0 or i <= 4 and 2 or 4
    r_reel[i].velocity = util.linlin(0, 1, 0.01, speed, 1)
    l_reel[i].orbit = math.fmod(i,2)~=0 and 6 or 15
    l_reel[i].position = i <= 2 and 3 or i <= 4 and 5 or 7.1
    l_reel[i].velocity = util.linlin(0, 1, 0.01, speed*3, 0.2)
  end
  update_reel()
  -- settings
  settings_list = UI.ScrollingList.new(75, 12, 1, {"Load reel", "New reel"})
  settings_list.num_visible = 4
  settings_list.num_above_selected = 0
  settings_list.active = false
  settings_amounts_list = UI.ScrollingList.new(125, 12)
  settings_amounts_list.num_visible = 4
  settings_amounts_list.num_above_selected = 0
  settings_amounts_list.text_align = "right"
  settings_amounts_list.active = false
  --
  counter = metro.alloc(count, 0.01, -1)
  counter:start()
  play_counter = metro.alloc(function(stage) if playing == true then play_count() end end,0.01,-1)
  blink_metro = metro.alloc(function(stage) blink = not blink end, 1 / 2)
  blink_metro:start()
  reel_redraw = metro.alloc(function(stage) redraw() animation() end, 1 / 60)
  reel_redraw:start()
  --
  loop(true)
end
-- HW
function key(n,z)
  if z == 1 then
    if n == 1 then
      if not settings then
        settings = true
        settings_list.active = true
        settings_amounts_list.active = true
      else
        settings = false
      end
    elseif n == 2 then
      if  reel.play[trk] ==  0 then
          play(true)
      elseif reel.play[trk] == 1 then
        if reel.rec[trk] == 1 then
          rec(trk,false)
        else
          play(false)
        end
      elseif filesel then
        filesel = false
      end
    elseif n == 3 then
      if settings == false and mounted then
        if reel.rec[trk] == 0 then
          rec(trk,true)
        elseif reel.rec[trk] == 1 then
          rec(trk,false)
        end
      elseif settings == true then
        if settings_list.index == 1 then
          if mounted then
            if reel.clip[trk] == 0  then
              filesel = true
              fileselect.enter(os.getenv("HOME").."/dust/audio", load_clip)
            elseif reel.clip[trk] == 1 then
              mute(trk, not mutes[trk])
            end
          else
            filesel = true
            fileselect.enter(os.getenv("HOME").."/dust/audio/reels/", load_mix)
          end
        elseif settings_list.index == 2 then
          if not mounted then new_reel() end
        elseif settings_list.index == 6 then
          reel.loop = reel.loop == 1 and 0 or 1
          loop(reel.loop == 1 and true or false)
        elseif settings_list.index == 8 then
          filesel = true
          fileselect.enter(os.getenv("HOME").."/dust/audio", load_clip)
        elseif settings_list.index == 9 then
          filesel = true
          textentry.enter(save_clip, reel.name[trk] == "-*" and "reel-" .. (math.random(9000)+1000) or (reel.name[trk]:find("*") and reel.name[trk]:match("[^.]*")):sub(2,-1))
        elseif settings_list.index == 11 then
          clear_track(trk)
        elseif settings_list.index == 12 then
          new_reel()
        elseif settings_list.index == 14 then
          filesel = true
          textentry.enter(save_project, reel.proj)
        elseif settings_list.index == 15 then
          filesel = true
          fileselect.enter(os.getenv("HOME").."/dust/audio/reels/", load_mix)
        elseif settings_list.index == 16 then
          warble_state = not warble_state
        end
        update_params_list()
      end
    end
  end
end

function enc(n,d)
  norns.encoders.set_sens(1,4)
  norns.encoders.set_sens(2,3)
  norns.encoders.set_sens(3,1)
  norns.encoders.set_accel(1,false)
  norns.encoders.set_accel(2,false)
  norns.encoders.set_accel(3,false)
  if n == 1 then
    trk = util.clamp(trk + d,1,TR)
    if mounted then
      update_params_list()
    end
    if c_pos_x ~= bind_vals[trk] then
      c_pos_x = (c_pos_x + d)
    end
  elseif n == 2 then
    if not settings then
      speed = util.clamp(util.round((speed + d /  100 ),0.001),-0.8,0.8)
      if speed < 0 then
        reel.rev = 1
      elseif speed >= 0 then
        reel.rev = 0
      end
      for i=1,TR do
        update_rate(i)
      end
    elseif settings then
      settings_list:set_index_delta(util.clamp(d, -1, 1), false)
      settings_amounts_list:set_index(settings_list.index)
    end
  elseif n == 3 then
    if not settings then
      rec_vol = util.clamp(rec_vol + d / 100, 0,1)
    elseif settings then
      if settings_list.index == 1 and mutes[trk] == false then
        reel.vol[trk] = util.clamp(reel.vol[trk] + d / 100, 0,1)
        engine.amp(trk,reel.vol[trk])
        update_params_list()
      elseif settings_list.index == 2 then
        reel.loop_start[trk] = util.clamp(reel.loop_start[trk] + d / 10,0,reel.length[trk])
        if reel.loop_start[trk] <= reel.loop_end[trk] then
          reel.loop_end[trk] = util.clamp(reel.loop_end[trk] + d / 10,0,util.round(reel.length[trk],0.1))
        end
        set_loop(trk,reel.loop_start[trk],reel.loop_end[trk])
      elseif settings_list.index == 3 then
        reel.loop_end[trk] = util.clamp(reel.loop_end[trk] + d / 10,0,util.round(reel.length[trk],0.1))
        if reel.loop_end[trk] <= reel.loop_start[trk] then
          reel.loop_start[trk] = util.clamp(reel.loop_start[trk] + d / 10,0,reel.length[trk])
        end
        set_loop(trk,reel.loop_start[trk],reel.loop_end[trk])
      elseif settings_list.index == 4 then
        reel.q[trk] = util.clamp(reel.q[trk] + d,1,24)
        update_rate(trk) -- ?
      elseif settings_list.index == 6 then
        reel.loop = util.clamp(reel.loop + d, 0,1)
        loop(reel.loop)
      end
      update_params_list()
    end
  end
end

function redraw()
  if not filesel then
    screen.clear()
    draw_reel(reel_pos_x,reel_pos_y)
    draw_cursor(c_pos_x,c_pos_y)
    draw_bars(15,61)
    if recording then
      screen.level(blink and 5 or 15)
      screen.circle(reel_pos_x + 80,reel_pos_y + 30,4)
      screen.fill()
      screen.stroke()
    end
    if not settings then
      draw_rec_vol_slider(reel_pos_x,reel_pos_y)
    end
    if settings and reel_pos_x < -15 then
      if mounted then
        screen.level(6)
        screen.move(128,5)
        screen.text_right(reel.name[trk]:match("[^.]*"))
        screen.stroke()
        settings_list:redraw()
        settings_amounts_list:redraw()
      else
        screen.level(6)
        settings_list:redraw()
      end
    end
  end
  screen.update()
end
