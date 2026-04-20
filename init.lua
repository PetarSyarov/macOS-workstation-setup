-----------------------------------------------------------------------
-- Key left of 1 (keyCode = 10) remap
-- Bulgarian – QWERTY → ч / Ч
-- English / others → ` / ~
-- Includes: SUPER WATCHDOG FIX + auto restart on layout change
-- Only for when keyboard is in ISO layout, but you want "~" placement like ANSI
-----------------------------------------------------------------------


local eventtap = require("hs.eventtap")
local event    = eventtap.event


-----------------------------------------------------------------------
-- Detect the exact Bulgarian layout (with en–dash)
-----------------------------------------------------------------------
local function isBulgarianLayout(layout)
   return layout == "Bulgarian – QWERTY"
end


-----------------------------------------------------------------------
-- Main Key Remap
-----------------------------------------------------------------------
local sectionRemap = eventtap.new({ event.types.keyDown, event.types.keyUp }, function(ev)
   local keyCode = ev:getKeyCode()
   local layout  = hs.keycodes.currentLayout()
   local flags   = ev:getFlags()


   -- Key left of 1 on Mac keyboard = keyCode 10
   if keyCode == 10 then
       if ev:getType() == event.types.keyDown then


           -- Bulgarian mode → ч / Ч
           if isBulgarianLayout(layout) then
               if flags.shift then
                   hs.eventtap.keyStrokes("Ч")
               else
                   hs.eventtap.keyStrokes("ч")
               end


           -- English or any other layout → ` / ~
           else
               if flags.shift then
                   hs.eventtap.keyStrokes("~")
               else
                   hs.eventtap.keyStrokes("`")
               end
           end
       end


       return true  -- suppress system input
   end


   return false
end)


sectionRemap:start()


-----------------------------------------------------------------------
-- FIX 1: Restart remap whenever the macOS input layout changes
-----------------------------------------------------------------------
local function restartSectionRemap()
   sectionRemap:stop()
   sectionRemap:start()
end


hs.keycodes.inputSourceChanged(restartSectionRemap)


-----------------------------------------------------------------------
-- SUPER FIX:
-- Automatically reload config if keys stop generating events
-- (Frequently happens after leaving Windows Remote Desktop)
-----------------------------------------------------------------------


local lastKeyEvent = hs.timer.secondsSinceEpoch()


-- Track key presses to know when eventtap is alive
local watchdog = hs.eventtap.new({ event.types.keyDown }, function(ev)
   lastKeyEvent = hs.timer.secondsSinceEpoch()
   return false
end)


watchdog:start()


-- If eventtap stops receiving events for 10s → reload config
hs.timer.doEvery(5, function()
   if hs.timer.secondsSinceEpoch() - lastKeyEvent > 10 then
       hs.reload()
   end
end)


-----------------------------------------------------------------------
-- End of file
-----------------------------------------------------------------------