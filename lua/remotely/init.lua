local util = require('remotely.util')
local curl = require('plenary.curl')

local M = {}

M.util = util

M.opts = {
  resultAutoFocus = false,
  handlers = {},
}

function M.handle(name, input)
  local handler = M.opts.handlers[name]
  local width = vim.fn.winwidth(0)
  local height = vim.fn.winheight(0)
  local args = {
    name = name,
    input = input,
  }
  local helpers = {
    json_encode = vim.fn.json_encode,
  }
  local header = util.fill('## {{name}}\n\n{{input}}', args, helpers)
  local update = util.createPopup(
    header,
    {
      width = width - 24,
      height = height - 16,
      autoFocus = M.opts.resultAutoFocus,
    }
  )
  local results = {}
  local loading = 0
  local modelLen = 0
  local render = function()
    local contents = { header }
    for i = 1, modelLen do
      local output = results[i]
      if output ~= nil then
        table.insert(contents, '---')
        table.insert(contents, output)
      end
    end
    if loading > 0 then
      table.insert(contents, '---\n\nLoading...')
    end
    update(util.join(contents, '\n\n'))
  end
  for i, variant in ipairs(handler.variants or { {} }) do
    if modelLen < i then
      modelLen = i
    end
    loading = loading + 1
    variant = util.merge(handler, variant)
    util.assign(variant, variant.preprocess(variant, args))
    curl.post(variant.url, {
      raw = variant.curlOpts,
      body = vim.fn.json_encode(variant.body),
      callback = function(res)
        vim.schedule(function()
          if res.status ~= 200 then
            results[i] = 'Server error'
          else
            local data = vim.fn.json_decode(res.body)
            results[i] = variant.postprocess(variant, data)
          end
          loading = loading - 1
          render()
        end)
      end
    })
  end
  render()
end

function M.setup(opts)
  M.opts = util.assign(M.opts, opts)

  vim.api.nvim_create_user_command('Remotely', function(args)
    local name = args['args']
    local input = util.getSelectedText(true)
    if util.isEmpty(input) then
      input = vim.fn.expand('<cword>')
    end
    -- delayed so the popup won't be closed immediately
    vim.schedule(function()
      M.handle(name, input)
    end)
  end, { range = true, nargs = 1 })
end

vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
  callback = util.closePopupIfNotFocused,
})

return M
