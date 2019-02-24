-- twinkle


steps = {}


function init()
    for i=1,16 do
        for j=1,8 do
            table.insert(steps[i],1)
        end
    end
    --grid_redraw()
    redraw()
end
--
-- grid functions
--
g = grid.connect()

g.event = function(x,y,z)
    if z == 1 then
        if steps[x] == y then
            steps[x] = 0
        else
            steps[x] = y
        end
    end
    grid_redraw()
    redraw()
end

function grid_redraw()
    g.all(0)
    for i=1,16 do
        g.led(i,steps[i],8)
        g.led(i-1,steps[i],3)
        g.led(i,steps[i]-1,3)
        g.led(i+1,steps[i],3)
        g.led(i,steps[i]+1,3)
    end
    g.refresh()
end

function redraw()
    screen.clear()
    screen.move(64,60)
    screen.level(2)
    screen.text(":: carvingcode ::")
    screen.update()
end
