vim.o.termguicolors = true
vim.o.background = "dark"
vim.o.syntax = "enable"
require('colorbuddy').setup()
require('neosolarized').setup()
require('lualine').setup{
	options = {
		icons_enabled = true,
    theme = 'solarized_dark',
	}
}
