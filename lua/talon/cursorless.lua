local M = {}

-- this triggers loading the node process as well as calling one function
-- in both the cursorless-neovim and command-server extensions in order to initialize them
local function load_extensions()
  vim.api.nvim_call_function('CursorlessLoadExtension', {})
  vim.api.nvim_call_function('CommandServerLoadExtension', {})
end

-- Cursorless command-server shortcut: CTRL+q
-- https://stackoverflow.com/questions/40504408/can-i-map-a-key-binding-to-a-function-in-vimrc
-- https://stackoverflow.com/questions/7642746/is-there-any-way-to-view-the-currently-mapped-keys-in-vim
-- luacheck:ignore 631
-- https://stackoverflow.com/questions/3776117/what-is-the-difference-between-the-remap-noremap-nnoremap-and-vnoremap-mapping
local function configure_command_server_shortcut()
  -- these mappings don't change the current mode
  -- https://neovim.io/doc/user/api.html#nvim_set_keymap()
  -- https://www.reddit.com/r/neovim/comments/pt92qn/mapping_cd_in_terminal_mode/
  vim.api.nvim_set_keymap(
    'i',
    '<c-q>',
    '<cmd>lua vim.fn.CommandServerRunCommand()<CR>',
    { noremap = true }
  )
  vim.api.nvim_set_keymap(
    'n',
    '<c-q>',
    '<cmd>lua vim.fn.CommandServerRunCommand()<CR>',
    { noremap = true }
  )
  vim.api.nvim_set_keymap(
    'c',
    '<c-q>',
    '<cmd>lua vim.fn.CommandServerRunCommand()<CR>',
    { noremap = true }
  )
  vim.api.nvim_set_keymap(
    'v',
    '<c-q>',
    '<cmd>lua vim.fn.CommandServerRunCommand()<CR>',
    { noremap = true }
  )
  vim.api.nvim_set_keymap(
    't',
    '<c-q>',
    '<cmd>lua vim.fn.CommandServerRunCommand()<CR>',
    { noremap = true }
  )
  -- from insert mode, go into normal mode before executing the command
  -- https://stackoverflow.com/questions/4416512/why-use-esc-in-vim
  -- https://vim.fandom.com/wiki/Use_Ctrl-O_instead_of_Esc_in_insert_mode_mappings
  -- vim.cmd([[
  --   inoremap <c-q> <c-o>:call CommandServerRunCommand("i")<CR>
  -- ]])
  -- vim.cmd([[
  -- nnoremap <c-q> :call CommandServerRunCommand("n")<CR>
  -- cnoremap <c-q> :call CommandServerRunCommand("c")<CR>
  -- vnoremap <c-q> :call CommandServerRunCommand("v")<CR>
  -- ]])
  -- -- https://vi.stackexchange.com/questions/4919/exit-from-terminal-mode-in-neovim-vim-8
  -- vim.cmd([[
  --   tnoremap <c-q> <c-\><c-n>:call CommandServerRunCommand("t")<CR><CR>
  -- ]])
end

function M.setup()
  -- these prints are useful as it takes a few seconds to load the node process
  print('Setting up cursorless...')
  load_extensions()
  configure_command_server_shortcut()
  print('Setting up cursorless done')
end

-- Get the first and last visible line of the current window/buffer
-- @see https://vi.stackexchange.com/questions/28471/get-first-and-last-visible-line-from-other-buffer-than-current
-- w0/w$ are indexed from 1, similarly to what is shown in neovim
-- e.g. :lua print(dump_table(require('talon.cursorless').window_get_visible_lines()))"
--   window_get_visible_lines
--  { [1] = 28, [2] = 74 }
function M.window_get_visible_lines()
  print('window_get_visible_lines()')
  return { vim.fn.line('w0'), vim.fn.line('w$') }
end

-- https://www.reddit.com/r/neovim/comments/p4u4zy/how_to_pass_visual_selection_range_to_lua_function/
-- https://neovim.io/doc/user/api.html#nvim_win_get_cursor()
--
-- e.g. run in command mode :vmap <c-a> <Cmd>lua print(vim.inspect(require('talon.cursorless').buffer_get_selection()))<Cr>
-- then go in visual mode with "v" and select "hello" on the first line and continue selection with "air"
-- on the second line.
-- Then hit ctrl+b and it will show the selection
-- cline=2, ccol=2, vline=1, vcol=1
-- sline=1, scol=1, eline=2, ecol=3, reverse=false
-- { 1, 1, 2, 3, false }
--
-- if instead you select from the end of the "air" word on the second line
-- and select up to the beginning of "hello" on the first line
-- cline=1, ccol=0, vline=3, vcol=3
-- sline=1, scol=1, eline=2, ecol=3, reverse=true
-- { 1, 1, 2, 3, true }
--
-- if you want to directly see how it is parsed in the node extension, you can use the below:
-- e.g. run in command mode :vmap <c-a> <Cmd>:call CursorlessLoadExtension()<Cr>
-- and again use ctrl+a after selecting the text
function M.buffer_get_selection()
  print('buffer_get_selection()')
  local modeInfo = vim.api.nvim_get_mode()
  local mode = modeInfo.mode

  local cursor = vim.api.nvim_win_get_cursor(0)
  local cline, ccol = cursor[1], cursor[2]
  local vline, vcol = vim.fn.line('v'), vim.fn.col('v')
  print(('cline=%d, ccol=%d, vline=%d, vcol=%d'):format(cline, ccol, vcol, vcol))

  local sline, scol
  local eline, ecol
  local reverse
  if cline == vline then
    --   if ccol <= vcol then
    if ccol < vcol then
      sline, scol = cline, ccol
      eline, ecol = vline, vcol
      scol = scol + 1
      reverse = true
    else
      sline, scol = vline, vcol
      eline, ecol = cline, ccol
      ecol = ecol + 1
      reverse = false
    end
  elseif cline < vline then
    sline, scol = cline, ccol
    eline, ecol = vline, vcol
    scol = scol + 1
    reverse = true
  else
    sline, scol = vline, vcol
    eline, ecol = cline, ccol
    ecol = ecol + 1
    reverse = false
  end

  if mode == 'V' or mode == 'CTRL-V' or mode == '\22' then
    scol = 1
    ecol = nil
  end

  print(
    ('sline=%d, scol=%d, eline=%d, ecol=%d, reverse=%s'):format(
      sline,
      scol,
      eline,
      ecol,
      tostring(reverse)
    )
  )
  return { sline, scol, eline, ecol, reverse }
end

-- https://www.reddit.com/r/neovim/comments/p4u4zy/how_to_pass_visual_selection_range_to_lua_function/
-- e.g. run in command mode :vmap <c-b> <Cmd>lua print(vim.inspect(require('talon.cursorless').buffer_get_selection_text()))<Cr>
-- then go in visual mode with "v" and select "hello" on the first line and continue selection with "air"
-- on the second line.
-- Then hit ctrl+b and it will show the selection
-- { "hello", "air" }
function M.buffer_get_selection_text()
  print('buffer_get_selection_text()')
  local sline, scol, eline, ecol, _ = unpack(require('talon.cursorless').buffer_get_selection())

  local lines = vim.api.nvim_buf_get_lines(0, sline - 1, eline, 0)
  if #lines == 0 then
    return
  end

  local startText, endText
  if #lines == 1 then
    startText = string.sub(lines[1], scol, ecol)
  else
    startText = string.sub(lines[1], scol)
    endText = string.sub(lines[#lines], 1, ecol)
  end

  local selection = { startText }
  if #lines > 2 then
    vim.list_extend(selection, vim.list_slice(lines, 2, #lines - 1))
  end
  table.insert(selection, endText)

  return selection
end

-- https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/ts_utils.lua#L278
-- luacheck:ignore 631
-- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/blob/master/lua/nvim-treesitter/textobjects/select.lua#L114
-- as an example if you put that in a vim buffer and do the following you can do a selection:
-- :w c:\work\tmp\test.lua
-- :so %
-- :lua select_range(5, 12, 5, 30)
-- for example it will highlight the last function name (nvim_win_set_cursor).
function M.select_range(start_x, start_y, end_x, end_y)
  vim.cmd([[normal! :noh]])
  vim.api.nvim_win_set_cursor(0, { start_x, start_y })
  vim.cmd([[normal v]])
  vim.api.nvim_win_set_cursor(0, { end_x, end_y })
end

-- https://vimdoc.sourceforge.net/htmldoc/eval.html#setreg()
-- https://stackoverflow.com/questions/11489428/how-can-i-make-vim-paste-from-and-copy-to-the-systems-clipboard?page=1&tab=scoredesc#tab-top
-- https://stackoverflow.com/questions/30691466/what-is-difference-between-vims-clipboard-unnamed-and-unnamedplus-settings
-- Save the data string into the operating system clipboard
-- eg :lua require('talon.cursorless').put_to_clipboard('hello')
--    :lua require('talon.cursorless').put_to_clipboard("01 345 789abcdef\r\naaaa bbbb cccc")
-- TODO: we can't really use that with muti line string that potentially also contain ending square brackets
-- but we don't really need it because we can call the vim api directly from typescript
-- function M.put_to_clipboard(data)
--   print('put_to_clipboard()')
--   vim.fn.setreg('*', data)
-- end

-- https://vimdoc.sourceforge.net/htmldoc/eval.html#getreg()
-- Return the string from the operating system clipboard
-- TODO: this hasn't been tested yet. This will be needed for a command like "paste to row one"
function M.get_from_clipboard()
  print('get_from_clipboard()')
  return vim.fn.getreg('*')
end

return M
