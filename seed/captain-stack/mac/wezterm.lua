-- Public template. Copy to private agent-memory captain/mac/ and customize.
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'Catppuccin Mocha'
config.font_size = 11.0

local home = os.getenv('HOME')
config.default_cwd = home .. '/firstmate'

config.set_environment_variables = {
  EDITOR = 'hx',
  VISUAL = 'hx',
  GIT_EDITOR = 'hx',
}

local captain_tmux = 'cd ~/firstmate 2>/dev/null; exec tmux new-session -A -s captain -c ~/firstmate'
config.default_prog = { 'bash', '-lic', captain_tmux }

return config