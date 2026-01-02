# 🏋️ NvimGym - Muscle Memory Trainer

**NvimGym** is a Neovim plugin designed to gamify your learning experience. heavily inspired by [ThePrimeagen's vim-be-good](https://github.com/ThePrimeagen/vim-be-good), but built to be **config-agnostic** and **customizable**.

It doesn't just teach you standard Vim keys (`hjkl`)—it trains you on **your specific configuration**, including window splits, buffer switching, and LSP actions.

## 🎮 Game Modes

### Module 1: The Basics (Arcade Mode)
*   **The Crawler (Whack-a-Mole)**: Hunt down monsters (👾 👻) using `hjkl` navigation. Targets move dynamically! Includes combos and high scores.
*   **The Sprinter**: Practice horizontal motions (`w`, `b`, `f`, `t`).
*   **The Editor**: Fix typos and edit text using `i`, `a`, `x`, `dd`.

### Module 2: Custom Config (The Special Sauce)
*   **Window Hopper**: A 3x3 grid of windows. Chase the target window using your split navigation keys (e.g., `<C-h/j/k/l>`).
*   **Buffer Surfer**: Train your muscle memory for switching buffers quickly.

### Module 3: Pro Skills
*   **The Navigator**: Practice LSP jumps (`gd`, `gr`, `K`) in a simulated environment.
*   **The Refactorer**: Practice renaming variables and code actions.

## 📦 Installation
Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "EdTosoy/neovimGym",
  cmd = "NvimGym",
  config = function()
    require("nvim-gym").setup()
  end
}
```

## 🚀 How to Play
1.  Open Neovim.
2.  Run the command:
    ```vim
    :NvimGym
    ```
3.  Select a module and start training!

## 🤝 Contributing
Feel free to fork and add your own levels!
