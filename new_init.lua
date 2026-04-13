-----------------------------------------------------------------------
-- Key left of 1 (keyCode = 10) remap
-- Bulgarian – QWERTY → ч / Ч
-- English / others → ` / ~
--
-- Caps Lock behavior:
--   - short tap  -> switch language
--   - long press -> toggle Caps Lock on/off
--
-- Includes: SUPER WATCHDOG FIX + auto restart on layout change
-----------------------------------------------------------------------

local eventtap = require("hs.eventtap")
local event    = eventtap.event
local keycodes = require("hs.keycodes")
local timer    = require("hs.timer")

-----------------------------------------------------------------------
-- Layout names
-- Change ENGLISH_LAYOUT if your English layout is not exactly "ABC"
-----------------------------------------------------------------------
local BULGARIAN_LAYOUT = "Bulgarian – QWERTY"
local ENGLISH_LAYOUT   = "ABC"

-----------------------------------------------------------------------
-- Caps Lock settings
-----------------------------------------------------------------------
local CAPS_KEYCODE        = hs.keycodes.map.capslock -- usually 57
local CAPS_LONG_PRESS_SEC = 0.35

local capsPressTime       = nil
local capsLongPressFired  = false
local ignoreCapsUntil     = 0

-----------------------------------------------------------------------
-- Detect the exact Bulgarian layout (with en-dash)
-----------------------------------------------------------------------
local function isBulgarianLayout(layout)
    return layout == BULGARIAN_LAYOUT
end

-----------------------------------------------------------------------
-- Switch between Bulgarian and English
-----------------------------------------------------------------------
local function toggleLanguage()
    local current = hs.keycodes.currentLayout()

    if isBulgarianLayout(current) then
        hs.keycodes.setLayout(ENGLISH_LAYOUT)
    else
        hs.keycodes.setLayout(BULGARIAN_LAYOUT)
    end
end

-----------------------------------------------------------------------
-- Toggle real Caps Lock state by posting a synthetic CAPS_LOCK event
-----------------------------------------------------------------------
local function toggleCapsLock()
    -- Prevent our own synthetic event from re-triggering the handler
    ignoreCapsUntil = hs.timer.secondsSinceEpoch() + 0.30

    hs.eventtap.event.newSystemKeyEvent("CAPS_LOCK", true):post()
    hs.eventtap.event.newSystemKeyEvent("CAPS_LOCK", false):post()
end

-----------------------------------------------------------------------
-- Main Key Remap (key left of 1)
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

        return true -- suppress system input
    end

    return false
end)

sectionRemap:start()

-----------------------------------------------------------------------
-- Caps Lock handler
-- Caps Lock comes through as flagsChanged, not normal keyDown/keyUp
-----------------------------------------------------------------------
local capsHandler = eventtap.new({ event.types.flagsChanged }, function(ev)
    local keyCode = ev:getKeyCode()

    if keyCode ~= CAPS_KEYCODE then
        return false
    end

    -- Ignore our own synthetic Caps Lock events briefly
    if hs.timer.secondsSinceEpoch() < ignoreCapsUntil then
        return true
    end

    local flags = ev:getFlags()
    local now   = hs.timer.secondsSinceEpoch()

    -- Press
    if flags.capslock then
        capsPressTime      = now
        capsLongPressFired = false

        -- Fire long-press action once after threshold
        hs.timer.doAfter(CAPS_LONG_PRESS_SEC, function()
            if capsPressTime and not capsLongPressFired then
                capsLongPressFired = true
                toggleCapsLock()
            end
        end)

        return true
    end

    -- Release
    if capsPressTime then
        local heldFor = now - capsPressTime

        -- Short tap → switch language
        if not capsLongPressFired and heldFor < CAPS_LONG_PRESS_SEC then
            toggleLanguage()
        end
    end

    capsPressTime      = nil
    capsLongPressFired = false

    return true
end)

capsHandler:start()

-----------------------------------------------------------------------
-- FIX 1: Restart remaps whenever the macOS input layout changes
-----------------------------------------------------------------------
local function restartEventTaps()
    sectionRemap:stop()
    sectionRemap:start()

    capsHandler:stop()
    capsHandler:start()
end

hs.keycodes.inputSourceChanged(restartEventTaps)

-----------------------------------------------------------------------
-- SUPER FIX:
-- Automatically reload config if keys stop generating events
-- (Frequently happens after leaving Windows Remote Desktop)
-----------------------------------------------------------------------

local lastKeyEvent = hs.timer.secondsSinceEpoch()

-- Track key presses to know when eventtap is alive
local watchdog = hs.eventtap.new({ event.types.keyDown, event.types.flagsChanged }, function(ev)
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