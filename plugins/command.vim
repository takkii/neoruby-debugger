" Vim-Plug
command PLI :PlugInstall
command PLU :PlugUpdate

" Python3
command CH :CheckHealth
command UP :UpdateRemotePlugins

" Defx-Icon
command DefxF :Defx -columns=icons:filename:type

" nvim-dap | UI
command Debug :lua require('dap').continue()
command BreakPoint :lua require('dap').toggle_breakpoint()
command RPOpen :lua require('dap').repl.open()
command UIOpen :lua require('dapui').open()
command UIClose :lua require('dapui').close()
command UIToggle :lua require('dapui').toggle()
