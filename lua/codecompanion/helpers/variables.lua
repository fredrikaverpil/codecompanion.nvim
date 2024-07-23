local actions = require("codecompanion.helpers.actions")
local buf_utils = require("codecompanion.utils.buffers")
local log = require("codecompanion.utils.log")

local M = {}

---Return the contents of the current buffer that the chat was initiated from
---@param chat CodeCompanion.Chat
---@return string
M.buffer = function(chat)
  local output = buf_utils.format_by_id(chat.context.bufnr)
  log:trace("Buffer Variable:\n---\n%s", output)

  return output
end

---Return the open buffers that match the current filetype
---@param chat CodeCompanion.Chat
---@return string
M.buffers = function(chat)
  local output = ""

  local buffers = buf_utils.get_open(chat.context.filetype)

  for _, buffer in ipairs(buffers) do
    output = output .. "\n\n" .. buf_utils.format_by_id(buffer.id)
  end

  log:trace("Buffers Variable:\n---\n%s", output)

  return output
end

---Return all of the visible lines in the editor's viewport
---@param chat CodeCompanion.Chat
---@return string
M.editor = function(chat)
  local buf_lines = buf_utils.get_visible_lines()

  -- Replace the line numbers with content
  local formatted = {}
  for bufnr, range in pairs(buf_lines) do
    range = range[1]
    table.insert(formatted, buf_utils.format_by_id(bufnr, range))
  end

  return table.concat(formatted, "\n\n")
end

---Return all of the LSP information and code for the current buffer
---@param chat CodeCompanion.Chat
---@return string
M.lsp = function(chat)
  local severity = {
    [1] = "ERROR",
    [2] = "WARNING",
    [3] = "INFORMATION",
    [4] = "HINT",
  }

  local bufnr = chat.context.bufnr

  local diagnostics = vim.diagnostic.get(bufnr, {
    severity = { min = vim.diagnostic.severity.HINT },
  })

  -- Add code to the diagnostics
  for _, diagnostic in ipairs(diagnostics) do
    for i = diagnostic.lnum, diagnostic.end_lnum do
      if not diagnostic.lines then
        diagnostic.lines = {}
      end
      table.insert(
        diagnostic.lines,
        string.format("%d: %s", i + 1, vim.trim(buf_utils.get_content(bufnr, { i, i + 1 })))
      )
    end
  end

  local formatted = {}
  for _, diagnostic in ipairs(diagnostics) do
    table.insert(
      formatted,
      string.format(
        [[
Severity: %s
LSP Message: %s
Code:
```%s
%s
```
]],
        severity[diagnostic.severity],
        diagnostic.message,
        chat.context.filetype,
        table.concat(diagnostic.lines, "\n")
      )
    )
  end

  return table.concat(formatted, "\n\n")
end

return M
