<div align="center">

# 🔱 Trident.nvim  
**Fast, project-aware file and line bookmarking for Neovim**

</div>

---


## 📚 Table of Contents

- [💻 Preview] (#-preview)
- [❓ Problem](#-problem)
- [✅ Solution](#-solution)
- [⚙️ Installation](#️-installation)
- [🧪 Commands](#-commands)
- [🔧 Configuration](#-configuration)
- [🔑 Default Keybinds](#-default-keybinds)
- [🧱 Lua API](#-lua-api)
- [🧭 Design & Concepts](#️-design-and-concepts)
    - [🔱️ Tridents](#-tridents)
    - [ 𓐬 Pikes](#𓐬-pikes)
    - [🗂️ Persistence](#️-persistence)
- [🤝 Contributing](#-contributing)

---

## 💻 Preview


https://github.com/user-attachments/assets/92f97f6c-9d13-494b-93dc-c91f000b9809


---

## ❓ Problem

Navigating large codebases or multi-file workspaces is painful. You:

- Constantly search for key lines or jump around manually.
- Lose track of TODOs, FIXMEs, and bookmarks.
- Need persistent, project-wide markers.
- Want fast, zero-dependency navigation aids.

---

## ✅ Solution

trident.nvim provides:

- `Tridents` - File-level bookmarks across the project.
- `Pikes` - Trident.nvim's take on how marks should be.
    - Pike "flags" like `todo`, `fix`, `warn`, `note`, etc.
- Persistent state saved per project.
    - Start right where you left off with Tridents and Pikes.
- Fully extensible API with core functionality included
    - Fully configurable and replacable UI for managing Trident.nvim

---

<!-- SCREENSHOT / VIDEO DEMO HERE -->

---

## ⚙️ Installation

Using lazy.nvim:

```lua
{
  "Ninjagor/trident.nvim",
  config = function()
    require("trident").setup({})
  end,
}
```

---

## 🧪 Commands 

| Command               | Description                                |
|-----------------------|--------------------------------------------|
| `TridentAdd`          | Add file mark                              |
| `TridentRemove`       | Remove file mark                           |
| `TridentList`         | List file marks                            |
| `TridentNext`, `Prev` | Navigate between file marks                |
| `PikeAdd`, `Remove`   | Create/remove line-level marks (Pikes)     |
| `PikeSetType`         | Set Pike type (`todo`, `fix`, etc.)        |
| `PikeJump`            | Jump to Pike by letter                     |
| `PikeList`            | List all Pikes in current file             |
| `PikeNext`, `Prev`    | Navigate Pikes in current file             |
| `PikeNextGlobal`      | Navigate Pikes across project              |
| `PikePicker`          | Open UI picker to browse/manage Pikes      |

---

## 🔧 Configuration

```lua
require("trident").setup({
  win = {
    win_type = "float", -- or "buf"
    float = {
      width = 0.6, -- 0-1
      height = 0.4, -- 0-1
      title = "[♆ TRIDENT ♆]", -- Customize trident win. title
    },
    buf_split = "belowright", -- Win. split if win_type is buf
    height = 0.3, -- buf height
  },
})
```

### ⌨️ Custom Keybinds
An example of custom keybinds for trident.nvim is shown below:

```lua
-- Trident keymaps
local keymap = vim.keymap

keymap.set('n', '<leader>tm', function()
  vim.cmd [[TridentAdd]]
end, { desc = 'Trident mark file', silent = true })

keymap.set('n', '<leader>to', function()
  vim.cmd [[TridentList]]
end, { desc = 'Trident menu', silent = true })

keymap.set('n', '<leader>tn', function()
  vim.cmd [[TridentNext]]
end, { desc = 'Next Trident file', silent = true })

keymap.set('n', '<leader>tp', function()
  vim.cmd [[TridentPrev]]
end, { desc = 'Previous Trident file', silent = true })

-- Pike keypress bindings and keymaps
require("trident").generate_keybinds({
  create_label_prefix = "tm", -- tm<pike-letter> | EX: tma
  delete_label_prefix = "td", -- td<pike-letter> | EX: tda
  jump_label_prefix = ";", -- ;<pike-letter> | EX: ;a
  create_typed_prefix = "tt", -- tt<pike-letter><flag> | EX: ttaf
  clear_type_key = "tr", -- tr | EX: tr
})

keymap.set('n', '<leader>pl', function()
  vim.cmd [[PikeList]]
end)

keymap.set('n', '<leader>pn', function()
  vim.cmd [[PikeNext]]
end)

keymap.set('n', '<leader>pp', function()
  vim.cmd [[PikePrev]]
end)

keymap.set('n', '<leader>png', function()
  vim.cmd [[PikeNextGlobal]]
end)

keymap.set('n', '<leader>ppg', function()
  vim.cmd [[PikePrevGlobal]]
end)
```

---

## 🔑 Default Keybinds

## Trident Key Bindings
Trident does not come with any key-bindings for `Tridents` - Instead, it exposes some <a href="#-commands">commands</a> which can be linked to keybinds in your config.

### Pike Letter Bindings

**Fully customizable during setup**

| Key         | Action                           |
|-------------|----------------------------------|
| `tmx`       | Add Pike `x`                     |
| `tdx`       | Remove Pike `x`                  |
| `;x`        | Jump to Pike `x`                 |
| `ttxt`      | Add Pike `x` with type `t`       |
| `tr`        | Clear Pike type at current line  |

### Pike Type Letters

- `t`: todo  
- `f`: fix  
- `e`: error  
- `w`: warn  
- `n`: note  
- `d`: debug  
- `b`: bookmark  
- `p`: perf  
- `h`: hack  

---


## 🧱 Lua API

```lua
-- Pike APIs
require("trident").add_pike({ line = 42, letter = "x", type = "todo" })
require("trident").remove_pike({ letter = "x" })
require("trident").jump_to_pike("x")
require("trident").next_pike()
require("trident").prev_pike()
require("trident").update_pike_type("x", "fix")

-- Trident (file) APIs
require("trident").add("path/to/file")
require("trident").remove("path/to/file")
require("trident").get_project_marks()
```

---

## 🧭 Design & Concepts
Trident.nvim tackles the difficulties with achieving efficient workspace navigation using 3 "tools/methods" - **Tridents**, **Pikes**, and **Persistence**.

### 🔱 Tridents
A `Trident` is a file that has been "marked" by trident.nvim. Marked `Tridents` are grouped by project - meaning, your `Tridents` will be seperated depending on the project you are working on. 

trident.nvim gives you the ability to:
- Mark/Unmark tridents in your project
- Cycle through tridents found in your project
- Re-order and edit tridents
- See a list of tridents (if you want to incoroporate it with tools like `telescope` or `fzf-lua`)

`Tridents` also remember where your cursor was last - this means you don't need to spend forever scrolling back down/up after switching files. Using `Tridents` paired with `Pikes`, you'll be back right where you left off.

These `Tridents` allow you to mark important files that you spend most of your time editing, and it allows you to quickly jump between them or jump back to them after editing other files.

### 𓐬 Pikes
`Pikes` are similar to the native marks found in vim, but it adds on many features and quality-of-life enhancements to it in order to enhance your workflow.

What's special about `Pikes`, and what is its purpose? 
- `Pikes` let you mark lines within a buffer, and it allows you to quickly jump between them.
- `Pikes` can also be "cycled" and "jumped" to globally:
    -   Ex: You can jump to a `Pike` in another file, make some changes, and quickly jump back to a `Pike` you have set in your original working file.
    - This is similar to the global marks provided by vim.
- `Pikes` can be "tagged" with a custom flag, such as `todo`, `fixme`, `warn`, etc. 
    -   These flags allow you to quickly understand the context of a bookmark, and also allows you to filter and jump quickly between `Pikes`
    - You can think of them as descriptive and editable bookmarks within your code.
- `Pikes` UI contains helpful features such as virtual text and signs
- `Pikes` persist between sessions!
    - `Pikes` that you create are persisted between editing sessions until they are deleted or mass-purged by the user, a feature that native marks lack

When combined with `Tridents`, `Pikes` can be extremely powerful and useful for speeding up your workflow. You can think of `Tridents` as marks for your whole workspace (between files), and `Pikes` as persistent and descriptive marks within a file.

#### 🗂️ Persistence

Trident persists `Tridents` and `Pikes`, grouping them by the project directory. This allows you to quickly jump between editing sessions without having to worry about reconfiguring your workflow.

You have the option to purge the persisted data / reset the data at any point. The persisted data is located in neovim's data directory, which depends on your operating system. For Linux/Macos, this directory is:
```~/.local/share/nvim/trident/```

---

## 🤝 Contributing

PRs and suggestions welcome. Built for speed, extensibility, and focused use.

---

