local query = require("vim.treesitter.query")

local M = {
  last_testname = "",
  last_testpath = "",
}

local default_config = {
  rdbg = {
    initialize_timeout_sec = 20,
    port = "${port}",
  },
}

local tests_query = [[
(function_declaration
  name: (identifier) @testname
  parameters: (parameter_list
    . (parameter_declaration
      type: (pointer_type) @type) .)
  (#match? @type "*testing.(T|M)")
  (#match? @testname "^Test.+$")) @parent
]]

local subtests_query = [[
(call_expression
  function: (selector_expression
    operand: (identifier)
    field: (field_identifier) @run)
  arguments: (argument_list
    (interpreted_string_literal) @testname
    (func_literal))
  (#eq? @run "Run")) @parent
]]

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

local function debug_test(testname, testpath)
  local dap = load_module("dap")
  dap.run({
    type = "ruby",
    name = testname,
    request = "launch",
    mode = "test",
    program = testpath,
    args = { testname },
  })
end

local function get_closest_above_cursor(test_tree)
  local result
  for _, curr in pairs(test_tree) do
    if not result then
      result = curr
    else
      local node_row1, _, _, _ = curr.node:range()
      local result_row1, _, _, _ = result.node:range()
      if node_row1 > result_row1 then
        result = curr
      end
    end
  end
  if result == nil then
    return ""
  elseif result.parent then
    return string.format("%s/%s", result.parent, result.name)
  else
    return result.name
  end
end

local function is_parent(dest, source)
  if not (dest and source) then
    return false
  end
  if dest == source then
    return false
  end

  local current = source
  while current ~= nil do
    if current == dest then
      return true
    end

    current = current:parent()
  end

  return false
end

local function get_closest_test()
  local stop_row = vim.api.nvim_win_get_cursor(0)[1]
  local ft = vim.api.nvim_buf_get_option(0, "filetype")
  assert(ft == "ruby", "neoruby-debugger error: can only debug ruby files, not " .. ft)
  local parser = vim.treesitter.get_parser(0)
  local root = (parser:parse()[1]):root()

  local test_tree = {}

  local test_query = vim.treesitter.parse_query(ft, tests_query)
  assert(test_query, "neoruby-debugger error: could not parse test query")
  for _, match, _ in test_query:iter_matches(root, 0, 0, stop_row) do
    local test_match = {}
    for id, node in pairs(match) do
      local capture = test_query.captures[id]
      if capture == "testname" then
        local name = query.get_node_text(node, 0)
        test_match.name = name
      end
      if capture == "parent" then
        test_match.node = node
      end
    end
    table.insert(test_tree, test_match)
  end

  local subtest_query = vim.treesitter.parse_query(ft, subtests_query)
  assert(subtest_query, "neoruby-debugger error: could not parse test query")
  for _, match, _ in subtest_query:iter_matches(root, 0, 0, stop_row) do
    local test_match = {}
    for id, node in pairs(match) do
      local capture = subtest_query.captures[id]
      if capture == "testname" then
        local name = query.get_node_text(node, 0)
        test_match.name = string.gsub(string.gsub(name, " ", "_"), '"', "")
      end
      if capture == "parent" then
        test_match.node = node
      end
    end
    table.insert(test_tree, test_match)
  end

  table.sort(test_tree, function(a, b)
    return is_parent(a.node, b.node)
  end)

  for _, parent in ipairs(test_tree) do
    for _, child in ipairs(test_tree) do
      if is_parent(parent.node, child.node) then
        child.parent = parent.name
      end
    end
  end

  return get_closest_above_cursor(test_tree)
end

function M.debug_test()
  local testname = get_closest_test()
  local relativeFileDirname = vim.fn.fnamemodify(vim.fn.expand("%:.:h"), ":r")
  local testpath = string.format("./%s", relativeFileDirname)

  if testname == "" then
    vim.notify("no test found")
    return false
  end

  M.last_testname = testname
  M.last_testpath = testpath

  local msg = string.format("starting debug session '%s : %s'...", testpath, testname)
  vim.notify(msg)
  debug_test(testname, testpath)

  return true
end

function M.debug_last_test()
  local testname = M.last_testname
  local testpath = M.last_testpath

  if testname == "" then
    vim.notify("no last run test found")
    return false
  end

  local msg = string.format("starting debug session '%s : %s'...", testpath, testname)
  vim.notify(msg)
  debug_test(testname, testpath)
  return true
end

return M

