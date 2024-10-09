# remotely.nvim

A Neovim plugin to process selected content remotely.

https://github.com/user-attachments/assets/15ceff5c-97ff-4814-b6a4-3b737a19b2d0

## Installation

Using lazy.nvim:

```lua
{
  'gera2ld/remotely.nvim',
  dependencies = 'nvim-lua/plenary.nvim',
  opts = {
    -- auto focus the result popup
    resultAutoFocus = false,
    -- define your handlers
    handlers = {
      rock = {
        url = 'https://example.com/call-my-ai',
        curlOpts = { '-H', 'content-type: application/json' },
        preprocess = function (self, args)
          return {
            body = {
              input = args.input,
              model = self.model,
            },
          }
        end,
        postprocess = function(self, data)
          return data.text
        end,
        -- optionally set different variants
        variants = {
          { model = 'openai' },
          { model = 'gemini' },
        },
      },
    },
  },
  event = 'VeryLazy',
},
```

- `variants` is an array of option list, each of which will be merged into the handler object and used to send a separate request.
- Anything returned by `preprocess` will be merged back to the handler object, and used to send the request.

Then run the command below with the selected text:

```viml
:Remotely rock
```

where `rock` is the name of a handler defined in the config.

### Custom Keymaps

```lua
-- Add a keymap to enter the popup
vim.keymap.set('n', '<enter>', require('remotely.util').enterPopup)
```
