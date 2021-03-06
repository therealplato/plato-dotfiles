-- Standard awesome library
local gears = require("gears")
local shape = require("gears.shape")
local awful = require("awful")
local wallpaper = require("wallpaper")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
-- require("awful.hotkeys_popup.keys")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

-- Load Debian menu entries
-- local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")

local lain = require("lain")
local markup = lain.util.markup

local pomo = require("pomodoro")
pomo.format = function (t) return "[ <b>" .. t .. "</b> ]" end
local pomos = pomo.init()
local pomowidget = pomos.timer_widget
pomowidget.align="left"
local wibarPomoVisible = true
local wibarCurrentVisible = false
local wibarDetailsVisible = false


local space = wibox.widget.textbox(" ")


-- local power = require("power_widget")
-- power:init()

presentation_mode = false

local powerwidget = awful.widget.watch("bash -c 'cat /sys/class/power_supply/BAT0/capacity'", 60,
  function(widget, stdout, stderr, exitreason, exitcode)
    if exitcode == 0 then
      if stdout == "100\n" then
        widget:set_markup_silently(markup(beautiful.green, stdout))
        return
      else
        widget:set_markup_silently(markup(beautiful.red, stdout))
      end
    else
      widget:set_markup_silently(markup(beautiful.red, "Battery % Unknown"))
    end
  end,
  base
)


local shwidget2 = function(test_env, click_env, text, period_s)
  local cmd1, cmd2
  if not period_s then period_s = 5 end
  cmd1 = os.getenv(test_env)
  if cmd1 == nil or cmd1 == "" then
    -- error("Expected env `" .. env .. "` to be a command")
    cmd1 = "false"
  end
  if click_env ~= nil then
    cmd2 = os.getenv(click_env)
  end
  if not cmd2 then cmd2 = "false" end
  local w = awful.widget.watch("bash -c '" .. cmd1 .. "'", 3,
    function(widget, stdout, stderr, exitreason, exitcode)
      if text == nil then
        text = stdout
      end
      if exitcode == 0 then
        widget:set_markup_silently(markup(beautiful.green, text))
        return
      end
      widget:set_markup_silently(markup(beautiful.red, text))
    end,
    base
  )
  w:buttons(awful.button({}, 1, nil, function ()
    awful.spawn.with_shell(cmd2)
    naughty.notify({ preset = naughty.config.presets.normal,
                     title = "Running command:",
                     text = cmd2
                   })
  end
  ))

  return w
end
vpnwidget = shwidget2("AWESOME_SH_VPN", "AWESOME_SH_VPN_CLICK", "VPN ")
-- podwidget = shwidget2("AWESOME_SH_POD_RESTARTS", "AWESOME_SH_POD_RESTARTS_CLICK", "US PODS ", 60 * 10 )
podwatchwidget = shwidget2("true", "AWESOME_SH_WATCH_PODS", " pods -w ")



-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
-- beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
 beautiful.init(gears.filesystem.get_xdg_config_home()  .. "/awesome/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "cool-retro-term"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.max,
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    -- awful.layout.suit.floating,
    -- awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}


-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

bg_fadeleft= gears.color.create_linear_pattern(
  {
    type="linear",
    from = {0, 0},
    to = {dpi(400), 0},
    stops = {
      {0, beautiful.transparent},
      {0.01, beautiful.shaded},
      {0.6, beautiful.shaded},
      {1.0, beautiful.transparent},
    },
  }
)

-- {{{ Widgets

local myutcclock = wibox.widget.textclock(markup(beautiful.fg_normal, " (%F %RZ) "), 5, "Z")
local mytextclock = wibox.widget.textclock(markup(beautiful.orange, " %a %d %R "), 5)
local wallpapername = wibox.widget.textbox(wallpaper.name())
local wallpaper_name_timer = gears.timer { timeout = 5, autostart=true }
local emptywidget = wibox.widget.textbox("")
wallpaper_name_timer:connect_signal("timeout", function()
  wallpapername:set_markup_silently(markup(beautiful.fg_normal, wallpaper.name()))
end)
todowidget = wibox.widget{
    markup = 'todo',
    align  = 'right',
    valign = 'center',
    widget = wibox.widget.textbox
}
-- local todo_timer = gears.timer { timeout = 5, autostart=true }
-- local todo_head_callback = function(line)
--   todo_item = line
--   todowidget:set_markup_silently(markup(beautiful.fg_normal, todo_item))
-- end
-- todo_timer:connect_signal("timeout", function()
--   awful.spawn.with_line_callback("head -n1 ~/todo" .. wp_path, {stdout=on_line, exit=todo_head_callback})
-- end)
awful.widget.watch('bash -c "head -n1 $HOME/todo"', 15, nil, todowidget)
todowidget:buttons(awful.button({}, 1, nil, function ()
  awful.spawn.with_shell(editor_cmd .. ' $HOME/todo')
end
))

local systray = wibox.widget.systray({opacity=0})

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", wallpaper.start)

awful.screen.disconnect_for_each_screen(function(s)
    wallpaper.stop(s)
end)
awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    wallpaper.start(s)

    -- Each screen has its own tag table.
    -- awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])
    awful.tag({ "1. Term", "2. Web", "3. Slack", "4. Media", "z. Scratch", "x. Kube", "c. Emacs"}, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))

   taglist_filter1 = awful.widget.taglist.filter.selected
   taglist_filter2 = awful.widget.taglist.filter.all
   -- function(t)
   --   return not awful.widget.taglist.filter.selected(t)
   -- end

    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, taglist_filter1, taglist_buttons)
    s.mytaglist2 = awful.widget.taglist(s, taglist_filter2, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s,
      awful.widget.tasklist.filter.currenttags,
      tasklist_buttons,
      {
        tasklist_disable_icon=true,
        align="center",
        bg_focus=bg_fadeleft,
      } )


    -- Let's try the pomodoro wibar at the top
    s.wibarpomo = awful.wibar({
      position = "top",
      screen = s,
      -- visible=false,
      visible=true,
      bg=beautiful.shaded
    })

    -- Create the main wibar
    s.wibarcurrent = awful.wibar({
      position = "top",
      screen = s,
      bg=beautiful.shaded,
    })
    --
    -- Create the secondary wibar
    s.wibardetails = awful.wibar({
      position = "top",
      screen = s,
      visible=false,
      bg=beautiful.shaded
    })

    -- Add widgets to the wibox
    s.wibarcurrent:setup({
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
            space,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            mykeyboardlayout,
            pomowidget,
            clockwidget,
            mytextclock,
            -- power,
        },
    })
    s.wibardetails:setup({
      layout = wibox.layout.align.horizontal,
      s.mytaglist2,
      { layout = wibox.layout.align.horizontal },
      {
        layout = wibox.layout.fixed.horizontal,
        wallpapername,
        space,
        vpnwidget,
        -- podwidget,
        space,
        podwatchwidget,
        systray,
        myutcclock,
      }
    })

    -- wibox.layout.align.expand = 'outside'

    s.wibarpomo:setup({
      layout = wibox.layout.align.horizontal,
      expand = 'none',
      -- nil,
      {
        layout = wibox.layout.align.horizontal,
        todowidget,
      },
      {
        layout = wibox.layout.align.horizontal,
        pomowidget,
      },
      {
        layout = wibox.layout.fixed.horizontal,
        powerwidget,
      },
    })

end)
-- }}}

-- {{{ Mouse bindings
-- root.buttons(gears.table.join(
    -- awful.button({ }, 3, function () mymainmenu:toggle() end),
    -- awful.button({ }, 4, awful.tag.viewnext),
    -- awful.button({ }, 5, awful.tag.viewprev)
-- ))
-- }}}

function beginPomo ()
  naughty.suspend()
  -- wibarCurrentVisible = false;
  -- wibarDetailsVisible = false;
  -- wibarPomoVisible = true;
  -- redrawWibars()
  pomos:start()
end
function endPomo ()
  naughty.resume()
  -- wibarCurrentVisible = true;
  -- wibarDetailsVisible = true;
  -- wibarPomoVisible = false;
  -- redrawWibars()
  pomos:pause()
end

pomos.icon_widget:connect_signal("work_elapsed", endPomo)
pomos.icon_widget:connect_signal("break_elapsed", beginPomo)

function changeWibarVisibility(more)
  if more then
    -- increase visibility (show lowest priority hidden bar)
    if not wibarPomoVisible then
      wibarPomoVisible = true
      return
    end
    if not wibarCurrentVisible then
      wibarCurrentVisible = true
      return
    end
    if not wibarDetailsVisible then
      wibarDetailsVisible  = true
      return
    end
  else
    -- decrease visibility (hide lowest priority visible bar)
    if wibarDetailsVisible then
      wibarDetailsVisible  = false
      return
    end
    if wibarCurrentVisible then
      wibarCurrentVisible = false
      return
    end
    if wibarPomoVisible then
      wibarPomoVisible = false
      return
    end
  end
end

function redrawWibars ()
  if wibarPomoVisible then
  awful.screen.focused().wibarpomo.visible = true
  else
  awful.screen.focused().wibarpomo.visible = false
  end
  if wibarCurrentVisible then
  awful.screen.focused().wibarcurrent.visible = true
  else
  awful.screen.focused().wibarcurrent.visible = false
  end

  if wibarDetailsVisible then
  awful.screen.focused().wibardetails.visible = true
  else
  awful.screen.focused().wibardetails.visible = false
  end
end

-- {{{ Key bindings
globalkeys = gears.table.join(
    -- custom:
    awful.key({                   }, "Print", nil, function () awful.spawn("scrot '%Y-%m-%d-%0k%0M.png' -s -e 'mv $f ~/screenshots/ 2>/dev/null'", false) end),
    -- awful.key({"Control", "Shift" }, "Escape", function () awful.spawn("light-locker-command -l 2>/dev/null", false) end),
   -- awful.key({"Control", "Shift" }, "Escape", function () awful.spawn("systemctl suspend", false) end),
   awful.key({"Control", "Shift" }, "Escape", function () awful.spawn("loginctl lock-session", false) end),
   awful.key({}, "XF86AudioLowerVolume", function ()
     awful.util.spawn("amixer -q -D pulse sset Master 5%-", false)
   end),
   awful.key({}, "XF86AudioRaiseVolume", function ()
     awful.util.spawn("amixer -q -D pulse sset Master 5%+", false)
   end),
   awful.key({}, "XF86AudioMute", function ()
     awful.util.spawn("amixer -D pulse set Master 1+ toggle", false)
     -- awful.util.spawn("amixer -D pulse set Headphone 1+ toggle", false)
   end),

       -- amixer -c 2 cset iface=MIXER,name='Line Playback Volume",index=1 40%

    awful.key({}, "XF86MonBrightnessDown", function ()
      awful.util.spawn("xbacklight -dec 15", false)
    end),
    awful.key({}, "XF86MonBrightnessUp", function ()
      awful.util.spawn("xbacklight -inc 15", false)
    end),
    awful.key({modkey, }, "b", wallpaper.rotate),
    awful.key({modkey, }, "0", function()
      presentation_mode = not presentation_mode
    end),
    awful.key({ modkey, }, "i", beginPomo ),
    awful.key({ modkey, }, "o",  endPomo),
    --
    -- Show more info
    awful.key({modkey }, "Down", function ()
      changeWibarVisibility(true)
      redrawWibars()
      -- awful.screen.focused().wibardetails.visible = true
    end, {description = "show more wibars", group = "extra"}
    ),
    --
    -- Show less info on mod press
    awful.key({modkey }, "Up", function ()
      changeWibarVisibility(false)
      redrawWibars()
      -- awful.screen.focused().wibardetails.visible = false
    end, {description = "show fewer wibars", group = "extra"}
    ),


    --default:
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey, "Shift"   }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),
              --
    -- -- Show more info on mod press
    -- awful.key({ }, "Alt", function ()
    --     awful.screen.focused().wibardetails.visible = true
    --   end, function ()
    --     awful.screen.focused().wibardetails.visible = false
    --   end, {description = "show second wibar (hold)", group = "extra"}
    -- ),

    -- Show more info on mod press
    -- Does not error, does not change bar visibility
    -- awful.key({ modkey }, nil, function ()
    --     error("A")
    --     awful.screen.focused().wibardetails.visible = true
    --   end, function ()
    --     error("B")
    --     awful.screen.focused().wibardetails.visible = false
    --   end, {description = "show second wibar (hold)", group = "extra"}
    -- ),

    -- -- Show more info on mod press
    -- Does not error, does not change bar visibility
    -- awful.key({ modkey }, "", function ()
    --     awful.screen.focused().wibardetails.visible = true
    --   end, function ()
    --     awful.screen.focused().wibardetails.visible = false
    --   end, {description = "show second wibar (hold)", group = "extra"}
    -- ),

    -- Show more info on mod press
    -- Does not error, does not change bar visibility
    -- awful.key({ }, "Super_L", function ()
    --     awful.screen.focused().wibardetails.visible = true
    --   end, function ()
    --     awful.screen.focused().wibardetails.visible = false
    --   end, {description = "show second wibar (hold)", group = "extra"}
    -- ),

    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"})
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey   }, "w",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
)

-- We use keycodes for numbers 1..4
workspacekeys = {
  [1]="#10",
  [2]="#11",
  [3]="#12",
  [4]="#13",
  [5]="z",
  [6]="x",
  [7]="c",
  [8]="v",
}
for k, v in ipairs(workspacekeys) do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, v,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[k]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag ".. v, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, v,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[k]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag " .. v, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, v,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[k]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag ".. v, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, v,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[k]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag " .. v, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = 0,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Hide titlebar
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = false }
    },

    -- Force some windows to specific workspaces:
    -- { rule_any = {
    --   class = { "Firefox" },
    -- },
    --   properties = { tag = "2. Web",
    --                  floating = false,
    -- } },

    { rule = { instance = "slack" },
      properties = { tag = "3. Slack",
                     floating = false,
    } },

    { rule_any = {
      instance = { "soundcloud.com__discover" },
      name = { "Discover on SoundCloud - Mozilla Firefox" },
    },
      properties = { tag = "4. Media",
                     floating = false,
    } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)


-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

-- pattern to help us escape arbitrary strings. outside the function to avoid calls
-- via https://stackoverflow.com/a/20778724/1380669
quotepattern = '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])'
function set_opacity(client, signal)
  local pf = "Firefox"
  local pb = "brave"
  local pc = "chrome"
  local px = "xviewer"
  -- local pt = terminal
  -- cool-retro-term contains special characters when pattern matching:
  -- pt = pt:gsub(quotepattern, "%%%1")

  local s = client.instance .. client.class
  if string.match(s, pf)
  or string.match(s, pb)
  or string.match(s, pc)
  or string.match(s, px)
  -- or string.match(s, pt)
  then
    client.opacity = 1
    return
  end
  if signal == "focus" then
    -- client.opacity = 0.93
    client.opacity = 1
  elseif signal == "unfocus" then
    client.opacity = 0.6
  else
    error("set_opacity for `" .. signal "`?")
  end
end

client.connect_signal("focus", function(c)
  set_opacity(c, "focus")
end)

client.connect_signal("unfocus", function(c)
  set_opacity(c, "unfocus")
end)
-- }}}


-- Startup programs
awful.spawn.with_shell("~/.config/awesome/autorun.sh")
-- Show only pomo bar on startup
redrawWibars()
