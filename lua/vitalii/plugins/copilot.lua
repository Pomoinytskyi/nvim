return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim", branch = "master" },
      { "ibhagwan/fzf-lua" },
    },
    build = "make tiktoken",
    config = function()
      local chat = require("CopilotChat")
      local select = require("CopilotChat.select")

      -- Configure fzf-lua as UI select provider
      require("fzf-lua").register_ui_select()

      -- Function to insert file content at cursor position
      local function insert_file_content_at_cursor()
        local fzf = require("fzf-lua")
        fzf.files({
          prompt = "Select file to insert into prompt: ",
          actions = {
            ["default"] = function(selected)
              if selected and #selected > 0 then
                local file = selected[1]
                local full_path = vim.fn.fnamemodify(file, ":p")
                local ok, content = pcall(vim.fn.readfile, full_path)
                if ok and content then
                  local text = table.concat(content, "\n")
                  local insert_text = "\n\nFile: " .. file .. "\n```\n" .. text .. "\n```\n"
                  -- Insert at current cursor position
                  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, vim.split(insert_text, "\n"))
                  -- Move cursor to end of inserted text
                  local lines = vim.split(insert_text, "\n")
                  vim.api.nvim_win_set_cursor(0, { row + #lines - 1, #lines[#lines] })
                else
                  vim.notify("Error reading file: " .. full_path, vim.log.levels.ERROR)
                end
              end
            end,
          },
        })
      end

      -- Function to insert just file reference
      local function insert_file_reference_at_cursor()
        local fzf = require("fzf-lua")
        fzf.files({
          prompt = "Select file to reference in prompt: ",
          actions = {
            ["default"] = function(selected)
              if selected and #selected > 0 then
                local file = selected[1]
                local insert_text = "file:" .. file .. " "
                -- Insert at current cursor position
                local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { insert_text })
                -- Move cursor to end of inserted text
                vim.api.nvim_win_set_cursor(0, { row, col + #insert_text })
              end
            end,
          },
        })
      end

      chat.setup({
        window = {
          layout = "float",
          width = 0.5,
          height = 0.6,
          border = "rounded",
          -- model = "gpt-4", -- or "gpt-3.5-turbo"
          auto_insert_mode = true,
          show_help = true,
        },
        -- Use fzf for file selection in prompts
        selection = select.visual,
        mappings = {
          -- Custom mappings for CopilotChat window
          normal = {
            ["<C-o>"] = insert_file_content_at_cursor,
            ["<C-e>"] = insert_file_reference_at_cursor,
          },
          insert = {
            ["<C-o>"] = insert_file_content_at_cursor,
            ["<C-e>"] = insert_file_reference_at_cursor,
          },
        },
      })
      
      -- Also create global keymaps that work anywhere
      vim.keymap.set("i", "<C-g>f", function()
        vim.cmd("stopinsert")
        insert_file_content_at_cursor()
      end, { desc = "Insert file content with fzf" })
      
      vim.keymap.set("i", "<C-g>r", function()
        vim.cmd("stopinsert")
        insert_file_reference_at_cursor()
      end, { desc = "Insert file reference with fzf" })
    end,
    keys = {
      { "<leader>cc", ":CopilotChat<CR>", mode = "n", desc = "Open Copilot Chat" },
      { "<leader>cc", ":CopilotChat<CR>", mode = "v", desc = "Open Copilot Chat" },
      { "<leader>cr", "<cmd>CopilotChatReset<cr>", mode = "n", desc = "Reset Copilot Chat" },
      { "<leader>ce", "<cmd>CopilotChatExplain<cr>", mode = "v", desc = "Explain code" },
      { "<leader>cv", "<cmd>CopilotChatReview<cr>", mode = "v", desc = "Review code" },
    },
  },
}
