local query = require("vim.treesitter.query")

local M = {}

local default_config = {
  rdbg = {
    initialize_timeout_sec = 20,
    port = "${port}",
  },
  rails = {
    initialize_timeout_sec = 20,
  },
  bundle = {
    initialize_timeout_sec = 20,
  },
  readapt = {
    initialize_timeout_sec = 20,
  },
  rackup = {
    initialize_timeout_sec = 20,
  },
  rspec = {
    initialize_timeout_sec = 20,
  },
  rake = {
    initialize_timeout_sec = 20,
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
      args = {'-n', '--open', '--port', config.port, '-c', '--', 'bundle', 'exec', config.command, script}
    elseif config.request == 'launch' and config.bundle == 'bundle' then
      args = {'-n', '--open', '--port', config.port, '-c', '--', 'bundle', 'exec', 'readapt', 'stdio'}
    else
      args = {'--open', '--port', config.port, '-c', '--', config.command, script}
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
      rails = 'rails.bat'
      bundle = 'bundle.bat'
      readapt = 'readapt.bat'
      rackup = 'rackup.bat'
      rspec = 'rspec.bat'
      rake = 'rake.bat'
    elseif vim.fn.has('osxdarwin') == 1 or vim.fn.has('osx') == 1 then
      -- MacOS
      home = os.getenv("HOME")
      if vim.fn.isdirectory(home .. '/.rbenv') == 1 then
        rdbg = home .. '/.rbenv/shims/rdbg'
        rails = home .. '/.rbenv/shims/rails'
        bundle = home .. '/.rbenv/shims/bundle'
        readapt = home .. '/.rbenv/shims/readapt'
        rackup = home .. '/.rbenv/shims/rackup'
        rspec = home .. '/.rbenv/shims/rspec'
        rake = home .. '/.rbenv/shims/rake'
      elseif vim.fn.isdirectory(home .. '/.anyenv') == 1 then
        rdbg = home .. '/.anyenv/envs/rbenv/shims/rdbg'
        rails = home .. '/.anyenv/envs/rbenv/shims/rails'
        bundle = home .. '/.anyenv/envs/rbenv/shims/bundle'
        readapt = home .. '/.anyenv/envs/rbenv/shims/readapt'
        rackup = home .. '/.anyenv/envs/rbenv/shims/rackup'
        rspec = home .. '/.anyenv/envs/rbenv/shims/rspec'
        rake = home .. '/.anyenv/envs/rbenv/shims/rake'
      elseif vim.fn.isdirectory('/usr/local/bin') == 1 then
        rdbg = '/usr/local/bin/rdbg'
        rails = '/usr/local/bin/rails'
        bundle = '/usr/local/bin/bundle'
        readapt = '/usr/local/bin/readapt'
        rackup = '/usr/local/bin/rackup'
        rspec = '/usr/local/bin/rspec'
        rake = '/usr/local/bin/rake'
      else
        -- Here for other PATH.
        rdbg = 'rdbg'
        rails = 'rails'
        bundle = 'bundle'
        readapt = 'readapt'
        rackup = 'rackup'
        rspec = 'rspec'
        rake = 'rake'
      end
    elseif vim.fn.has('linux') == 1 then
      -- Linux Kernel
      home = os.getenv("HOME")
      if vim.fn.isdirectory(home .. '/.rbenv') == 1 then
        rdbg = home .. '/.rbenv/shims/rdbg'
        rails = home .. '/.rbenv/shims/rails'
        bundle = home .. '/.rbenv/shims/bundle'
        readapt = home .. '/.rbenv/shims/readapt'
        rackup = home .. '/.rbenv/shims/rackup'
        rspec = home .. '/.rbenv/shims/rspec'
        rake = home .. '/.rbenv/shims/rake'
      elseif vim.fn.isdirectory(home .. '/.anyenv') == 1 then
        rdbg = home .. '/.anyenv/envs/rbenv/shims/rdbg'
        rails = home .. '/.anyenv/envs/rbenv/shims/rails'
        bundle = home .. '/.anyenv/envs/rbenv/shims/bundle'
        readapt = home .. '/.anyenv/envs/rbenv/shims/readapt'
        rackup = home .. '/.anyenv/envs/rbenv/shims/rackup'
        rspec = home .. '/.anyenv/envs/rbenv/shims/rspec'
        rake = home .. '/.anyenv/envs/rbenv/shims/rake'
      elseif vim.fn.isdirectory('/usr/local/bin') == 1 then
        rdbg = '/usr/local/bin/rdbg'
        rails = '/usr/local/bin/rails'
        bundle = '/usr/local/bin/bundle'
        readapt = '/usr/local/bin/readapt'
        rackup = '/usr/local/bin/rackup'
        rspec = '/usr/local/bin/rspec'
        rake = '/usr/local/bin/rake'
      else
        -- Here for other PATH.
        rdbg = 'rdbg'
        rails = 'rails'
        bundle = 'bundle'
        readapt = 'readapt'
        rackup = 'rackup'
        rspec = 'rspec'
        rake = 'rake'
      end
    else
      -- For other OS, change this PATH.
      rdbg = 'rdbg'
      rails = 'rails'
      bundle = 'bundle'
      readapt = 'readapt'
      rackup = 'rackup'
      rspec = 'rspec'
      rake = 'rake'
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
    name = 'run rails',
    bundle = 'bundle',
    request = 'attach',
    command = 'rails',
    script = "s",
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

