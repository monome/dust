

-- Euclidean rythm (http://en.wikipedia.org/wiki/Euclidean_Rhythm)
-- @param k : number of pulses
-- @param n : total number of steps
function er(k, n)

   -- total number of steps
   local m = k - n
   -- results array, intialliy all zero
   local r = {}
   for i=1,n do r[i] = false end

   -- using the "bucket method"
   -- for each step in the output, add K to the bucket.
   -- if the bucket overflows, this step contains a pulse.
   local b = 0
   for i=1,n do
      b = b + k
      if b >= n then
	 b = b - n
	 -- r[i] = true
	 --- hm, let's rotate left by 1 (or forward by N)
	 --- this means that pulse will always be on first step, instead of last step
	 r[(i+n+1)%n] = true
      end
   end

   return r
   
end
