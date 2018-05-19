-- Euclidean rythm (http://en.wikipedia.org/wiki/Euclidean_Rhythm)
function er(k,n)
    local r = {}
    for i = 1,n do
        r[i] = {i <= k}
    end
    
    local function cat(i,k)
        for _,v in ipairs(r[k]) do
            r[i][#r[i]+1] = v
        end
        r[k] = nil
    end
    
    while #r > k do
        for i = 1,math.min(k, #r-k) do
            cat(i, #r)
        end
    end

    while #r > 1 do
       cat(#r-1, #r) 
    end

    return r[1]
end
