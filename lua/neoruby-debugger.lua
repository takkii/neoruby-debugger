local query = require("vim.treesitter.query")

local M = {}

local default_config = {
  rdbg = {
    initialize_timeout_sec = 20,
    port = "${port}",
    args = {},
    build_flags = "",
    detached = true,
    cwd = nil,
  },
  rails = {
    home = os.getenv("HOME"),
    path = home .. '/.anyenv/envs/rbenv/shims/rails',
    initialize_timeout_sec = 20,
    args = {},
    build_flags = "",
    cwd = nil,
  },
  bundle = {
    home = os.getenv("HOME"),
    path = home .. '/.anyenv/envs/rbenv/shims/bundle',
    initialize_timeout_sec = 20,
    args = {},
    build_flags = "",
    cwd = nil,
  },
  readapt = {
    home = os.getenv("HOME"),
    path = home .. '/.anyenv/envs/rbenv/shims/readapt',
    initialize_timeout_sec = 20,
    args = {},
    build_flags = "",
    cwd = nil,
  },
  rackup = {
    home = os.getenv("HOME"),
    path = home .. '/.anyenv/envs/rbenv/shims/rackup',
    initialize_timeout_sec = 20,
    args = {},
    build_flags = "",
    cwd = nil,
  },
  rspec = {
    home = os.getenv("HOME"),
    path = home .. '/.anyenv/envs/rbenv/shims/rspec',
    initialize_timeout_sec = 20,
    args = {},
    build_flags = "",
    cwd = nil,
  },
  rake = {
    home = os.getenv("HOME"),
    path = home .. '/.anyenv/envs/rbenv/shims/rake',
    initialize_timeout_sec = 20,
    args = {},
    build_flags = "",
    cwd = nil,
  },
}

local function load_module(module_name)
  local ok, module = pcall(require, module_name)
  assert(ok, string.format('neoruby-debugger dependency error: %s not installed', module_name))
  return module
end

local function get_arguments()
  local co = coroutine.running()
  if co then
    return coroutine.create(function()
      local args = {}
      vim.ui.input({ prompt = "Args: " }, function(input)
        args = vim.split(input or "", " ")
      end)
      coroutine.resume(co, args)
    end)
  else
    local args = {}
    vim.ui.input({ prompt = "Args: " }, function(input)
      args = vim.split(input or "", " ")
    end)
    return args
  end
end

local function setup_rdbg_adapter(dap)
  dap.adapters.ruby = function(callback, config)
    local handle
    local stdout = vim.loop.new_pipe(false)
    local pid_or_err
    local waiting = config.waiting or 500
    local args
    local script
    local rdbg
    local dap = require('dap')
    local type = 'executable'

    if config.current_line then
      script = config.script .. ':' .. vim.fn.line('.')
    else
      script = config.script
    end

    if config.request == 'attach' and config.bundle == 'bundle' then
      args = {'-n', '--open', '--port', config.port, '-c', '--', 'bundle', 'exec', config.command, config.script}
    elseif config.request == 'launch' and config.bundle == 'bundle' then
      args = {'-n', '--open', '--port', config.port, '-c', '--', 'bundle', 'exec', 'readapt', 'stdio'}
    elseif config.request == 'attach' and config.bundle == 'bundle' and config.rdbg == true then
      args = {'bundle', 'exec', 'rdbg', '-n', '--open', '--port', config.port, '-c', '--', 'bundle', 'exec', config.command, config.script}
    elseif config.request == 'launch' and config.bundle == 'bundle' and config.rdbg == true then
      args = {'bundle', 'exec', 'rdbg', '-n', '--open', '--port', config.port, '-c', '--', 'bundle', 'exec', 'readapt', 'stdio'}
    else
      args = {'--open', '--port', config.port, '-c', '--', config.command, config.script}
    end

    local opts = {
      stdio = {nil, stdout},
      args = args,
      detached = false
    }

    -- Settings for each environment with a different OS.
    if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
      -- Windows
      rdbg = 'rdbg.bat'
    elseif vim.fn.has('osxdarwin') == 1 or vim.fn.has('osx') == 1 then
      -- MacOS
      home = os.getenv("HOME")
      if vim.fn.isdirectory(home .. '/.rbenv') == 1 then
        rdbg = home .. '/.rbenv/shims/rdbg'
      elseif vim.fn.isdirectory(home .. '/.anyenv') == 1 then
        rdbg = home .. '/.anyenv/envs/rbenv/shims/rdbg'
      elseif vim.fn.isdirectory('/usr/local/bin') == 1 then
        rdbg = '/usr/local/bin/rdbg'
      else
        -- This is no such file directory.
        rdbg = vim.fn.system('echo -n $(which rdbg)')
      end
    elseif vim.fn.has('linux') == 1 then
      -- Linux Kernel
      home = os.getenv("HOME")
      if vim.fn.isdirectory(home .. '/.rbenv') == 1 then
        rdbg = home .. '/.rbenv/shims/rdbg'
      elseif vim.fn.isdirectory(home .. '/.anyenv') == 1 then
        rdbg = home .. '/.anyenv/envs/rbenv/shims/rdbg'
      elseif vim.fn.isdirectory('/usr/local/bin') == 1 then
        rdbg = '/usr/local/bin/rdbg'
      else
        -- This is no such file directory.
        rdbg = vim.fn.system({"echo","-n","$(which rdbg)"})
      end
    else
      -- For other OS, change this PATH.
      rdbg = 'rdbg'
    end

    handle, pid_or_err = vim.loop.spawn(rdbg, opts, function(code)
      handle:close()
      if code ~= 0 then
        assert(handle, 'rdbg exited with code: ' .. tostring(code))
        print('rdbg exited with code', code)
      end
    end)

    assert(handle, 'Error running rdbg: ' .. tostring(pid_or_err))

    stdout:read_start(function(err, chunk)
      assert(not err, err)
      if chunk then
        vim.schedule(function()
          require('dap.repl').append(chunk)
        end)
      end
    end)

    -- Wait for rdbg to start
    vim.defer_fn(
      function()
        callback({type = 'server', host = config.server, port = config.port})
      end,
    waiting)
  end
end

local function setup_rdbg_configuration(dap)
 dap.configurations.ruby = {
  {
    type = 'ruby',
    name = 'run current file',
    request = 'attach',
    command = 'ruby',
    script = "${file}",
    port = 38698,
    server = '127.0.0.1',
    options = {
     source_filetype = 'ruby';
    },
    localfs = true,
    waiting = 1000,
  },
  {
    type = 'ruby',
    name = 'run current file:use rdbg',
    request = 'attach',
    program = 'bundle';
    programArgs = {'exec', 'rdbg'};
    useBundler = true;
    command = 'ruby',
    script = "${file}",
    port = 38698,
    server = '127.0.0.1',
    options = {
     source_filetype = 'ruby';
    },
    localfs = true,
    waiting = 1000,
  },
  {
    type = 'ruby',
    name = 'run rake',
    bundle = 'bundle',
    request = 'attach',
    command = 'rake',
    script = "default",
    port = 38698,
    server = '127.0.0.1',
    options = {
      source_filetype = 'ruby';
    };
    localfs = true,
    waiting = 1000,
  },
  {
    type = 'ruby',
    name = 'run current rspec file',
    bundle = 'bundle',
    request = 'attach',
    command = 'rspec',
    script = "${file}",
    port = 38698,
    server = '127.0.0.1',
    options = {
      source_filetype = 'ruby';
    },
    localfs = true,
    waiting = 1000,
  },
  {
    type = 'ruby',
    name = 'run current rspec file:current line',
    bundle = 'bundle',
    request = 'attach',
    command = 'rspec',
    script = "${file}",
    port = 38698,
    server = '127.0.0.1',
    options = {
     source_filetype = 'ruby';
    };
    localfs = true,
    waiting = 1000,
    current_line = true,
  },
  {
    type = 'ruby',
    name = 'run rspec',
    bundle = 'bundle',
    request = 'attach',
    command = 'rspec',
    script = "./spec",
    port = 38698,
    server = '127.0.0.1',
    options = {
      source_filetype = 'ruby';
    };
    localfs = true,
    waiting = 1000,
  },
  {
    type = 'ruby',
    name = 'run rails:use readapt',
    bundle = 'bundle',
    request = 'launch';
    program = 'bundle';
    programArgs = {'exec', 'rails', 's'};
    useBundler = true;
    port = 38698,
    server = "127.0.0.1",
    options = {
      source_filetype = 'ruby';
    },
    localfs = true,
    waiting = 1000,
  },
  {
    type = 'ruby',
    rdbg = true,
    name = 'run rails:use rdbg',
    bundle = 'bundle',
    request = 'launch';
    program = 'bundle';
    programArgs = {'exec', 'rails', 's'};
    useBundler = true;
    port = 38698,
    server = "127.0.0.1",
    options = {
      source_filetype = 'ruby';
    },
    localfs = true,
    waiting = 1000,
  },
  {
    type = 'ruby',
    name = 'run sinatra',
    bundle = 'bundle',
    request = 'attach',
    command = 'rackup',
    script = "",
    port = 38698,
    server = "127.0.0.1",
    options = {
      source_filetype = 'ruby';
    },
    localfs = true,
    waiting = 1000,
  },
  {
    type = 'ruby',
    rdbg = true,
    name = 'run sinatra:use rdbg',
    bundle = 'bundle',
    request = 'attach',
    command = 'rackup',
    script = "",
    port = 38698,
    server = "127.0.0.1",
    options = {
      source_filetype = 'ruby';
    },
    localfs = true,
    waiting = 1000,
  },
  {
    type = 'ruby',
    name = 'run sinatra:use readapt',
    bundle = 'bundle',
    request = 'launch';
    program = 'bundle';
    programArgs = {'exec', 'rackup'};
    useBundler = true;
    port = 38698,
    server = "127.0.0.1",
    options = {
      source_filetype = 'ruby';
    },
    localfs = true,
    waiting = 1000,
  },
  {
    type = 'ruby',
    rdbg = true,
    name = 'run sinatra:use readapt and rdbg',
    bundle = 'bundle',
    request = 'launch';
    program = 'bundle';
    programArgs = {'exec', 'rackup'};
    useBundler = true;
    port = 38698,
    server = "127.0.0.1",
    options = {
      source_filetype = 'ruby';
    },
    localfs = true,
    waiting = 1000,
  },
}

  if configs == nil or configs.dap_configurations == nil then
    return
  end

  for _, config in ipairs(configs.dap_configurations) do
    if config.type == "ruby" then
      table.insert(dap.configurations.ruby, config)
    end
  end
end

function M.setup(opts)
  local config = vim.tbl_deep_extend("force", default_config, opts or {})
  local dap = load_module("dap")
  setup_rdbg_adapter(dap, config)
  setup_rdbg_configuration(dap, config)
end

return M

