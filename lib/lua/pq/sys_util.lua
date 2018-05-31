--- sys_util
--
-- system utilities and conveniences.
--
local sys_util = {}

function sys_util.reload(module_name)
  if (package.loaded[module_name] ~= nil) then
    package.loaded[module_name] = nil
    -- todo: would a blanked out G[module_name] just get overwritten by the require?
  end
  return require(module_name)
end
  

--- display available disk space
function sys_util.disk_space()
  -- cribbed from menu.lua
  return util.os_capture("df -hl | grep '/dev/root' | awk '{print $4}'")
end

-- thank you internets
local mem_use_cmd = [==[
echo "CPU `LC_ALL=C top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'`% RAM `free -m | awk '/Mem:/ { printf("%3.1f%%", $3/$2*100) }'` HDD `df -h / | awk '/\// {print $(NF-1)}'`"     
]==]

--- display memory use stats
function sys_util.memory_usage()
  return util.os_capture(mem_use_cmd)
end

--- tail the system log
function sys_util.tail_syslog(n)
  n = n or 10
  -- todo: fix repl console to respect formatting (https://github.com/ngwese/maiden/issues/6)
  return(util.os_capture("tail -n"..n.." /var/log/syslog"))  
end

-- execute a command relative to ~/norns and return its output
function sys_util.exec(cmd)
  return util.os_capture("cd /home/we/norns/; "..cmd)
end

-- turn on wifi (useful during dev)
function sys_util.wifi_on()
  return sys_util.exec("./wifi.sh on")
end

-- turn on wifi hotspot
function sys_util.wifi_hotspot()
  return sys_util.exec("./wifi.sh hotspot")
end

-- select a wifi ssid and pass
function sys_util.wifi_select(ssid, pass)
  return sys_util.exec("./wifi.sh select "..ssid.." "..pass)
end

-- restart norns subsystems (crone, matron, ...)
function sys_util.restart()
  print("not implemented...")
  -- not quite right.
  -- os.execute("sleep 0.5; ~/norns/stop.sh; ~/norns/start.sh")
end

function sys_util.battery()
  return "battery: "..norns.battery_percent.."% "..norns.battery_current.."mA"
end

-- mute audio
function sys_util.mute()
  --todo: save state to pop for an un-mute
  norns.audio.output_level(-100)
end  

-- todo(pq): update formatting once the repl supports it (https://github.com/monome/maiden/issues/6)
local usage = [[
system utilities and conveniences.
------------------------------------------
common commands:
------------------------------------------
  >> sys_util.memory_usage()
    display memory use stats
  
  >> sys_util.disk_space()
    display available disk space

  >> sys_util.tail_syslog([n])
    tail n lines of the system
------------------------------------------
usage: sys_util.<command>([arguments])
------------------------------------------
available commands:
------------------------------------------
]]

-- show help
function sys_util.help()
  print(usage)
  -- todo: sort
  for fname,obj in pairs(sys_util) do
    if type(obj) == "function" then
        print("  "..fname)
    end
  end
  print("------------------------------------------")
end

return sys_util
