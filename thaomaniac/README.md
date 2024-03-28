# Prezto — ThaoManiac Customization

## Installation

1. Launch Zsh:

   ```console
   zsh
   ```

2. Clone the repository:

   ```console
   git clone --recursive git@gitlab.com:thaomaniac/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
   ```

3. Create a new Zsh configuration by copying/linking the Zsh configuration files provided:

   ```console
   ln -s "${ZDOTDIR:-$HOME}"/.zprezto/thaomaniac/zshrc "${ZDOTDIR:-$HOME}/.zshrc"
   ```

4. Download and install fonts.
    - Powerline fonts
        ```bash
        sudo apt-get install powerline fonts-powerline
        ```
    - [Nerd Fonts](https://www.nerdfonts.com/)

      Recommend using _Overpass Nerd Font, Regular_

### External

1. Using [Color LS](https://gitlab.com/thaomaniac/colorls)
