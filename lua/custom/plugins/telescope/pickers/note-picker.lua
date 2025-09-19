local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local note_binary_path = '/home/cscopetski/proj/task-manager/target/release/task-manager'
local config_file_name = '.note-maxxer.toml'
local workspace_path = '/home/cscopetski/notes/'
local config_path = workspace_path .. config_file_name

local get_note_name = function()
  local input = vim.fn.input 'Enter note title: '
  return input
  -- return vim.ui.input({ prompt = 'Enter note title: ' }, function(input)
  --   return input
  -- end)
end

local create_new_note = function(template_file_name, note_title)
  if not (note_title or note_title ~= '') then
    print 'No note title provided, cancelling'
    return
  end

  local create_command = { note_binary_path, config_path, 'new', '-t', template_file_name, note_title }
  local obj = vim.system(create_command):wait()

  if obj.code ~= 0 then
    print('Failed to create new note: ' .. obj.stderr)
  else
    local file_path = obj.stdout:gsub('%s+$', '')
    vim.cmd.edit(file_path)
  end
end

local get_template_dir = function(workspace_path)
  local obj = vim.system({ note_binary_path, config_path, 'get-template-dir' }, { text = true }):wait()
  local output = obj.stdout:gsub('%s+$', '')
  return output
end

local file_picker = function(opts, template_dir)
  local find_command = { 'rg', '--files', '--color', 'never' }
  -- add an entry maker to dispaly relative file pathing
  -- https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md#guide-to-your-first-picker:~:text=There%20are%20other,to%20that%20line.
  pickers
    .new(opts, {
      prompt_title = 'Select Template',
      __locations_input = false,
      finder = finders.new_oneshot_job(find_command, opts),
      -- previewer = conf.file_previewer(opts),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          local selected_template_file = selection[1]
          local note_title = get_note_name()

          if note_title ~= nil and note_title ~= '' then
            create_new_note(selected_template_file, note_title)
          else
            print 'No note title provided, cancelling'
          end
        end)
        return true
      end,
    })
    :find()
end
-- -- our picker function: colors
-- local colors = function(opts)
--   opts = opts or {}
--   local selection = pickers
--     .new(opts, {
--       prompt_title = 'colors',
--       finder = finders.new_table {
--         results = {
--           { 'red', '#ff0000' },
--           { 'green', '#00ff00' },
--           { 'blue', '#0000ff' },
--         },
--         entry_maker = function(entry)
--           return {
--             value = entry,
--             display = entry[1],
--             ordinal = entry[1],
--           }
--         end,
--       },
--       sorter = conf.generic_sorter(opts),
--       attach_mappings = function(prompt_bufnr, map)
--         actions.select_default:replace(function()
--           actions.close(prompt_bufnr)
--           local selection = action_state.get_selected_entry()
--           print(vim.inspect(selection))
--           vim.api.nvim_put({ selection[1] }, '', false, true)
--         end)
--         return true
--       end,
--     })
--     :find()
--   print(selection)
-- end
--
-- local template_dir = '/home/cscopetski/proj/task-manager/config/templates'
local new_note_with_prompt = function()
  local template_dir = get_template_dir(workspace_path)
  file_picker(require('telescope.themes').get_dropdown { cwd = template_dir }, template_dir)
end
-- to execute the function
--colors(require('telescope.themes').get_dropdown {})
return new_note_with_prompt
