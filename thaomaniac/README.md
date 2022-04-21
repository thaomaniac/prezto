# Prezto — ThaoManiac Customization

## Installation

01. Launch Zsh:

    ```console
    zsh
    ```

02. Clone the repository:

    ```console
    git clone --recursive git@gitlab.com:thaomaniac/zprezto.git "${ZDOTDIR:-$HOME}/.zprezto"
    ```

03. Create a new Zsh configuration by copying/linking the Zsh configuration files provided:

    ```console
    ln -s "${ZDOTDIR:-$HOME}"/.zprezto/thaomaniac/zshrc "${ZDOTDIR:-$HOME}/.zshrc"
    ```

04. Download and install fonts.

    - Powerline fonts
        ```bash
        sudo apt-get install powerline fonts-powerline
        ```
    - [Nerd Fonts](https://www.nerdfonts.com/)

        Recommend using _Overpass Regular Nerd Font Complete_:
        [Download](https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Overpass/Non-Mono/Regular/complete/Overpass%20Regular%20Nerd%20Font%20Complete.otf)
