# Aaron's Bash Profile Utilities

I use these utilities with my personal bash profile. Feel free to try them in yours! Please use these utilities only at your own risk, and only with a full understanding of what they do and how they work. They are presented as-is, without warranty.

## To Install

Clone this repo into your home directory (or symlink it) as a folder called **.profile.d**. Then, to your existing ~/.profile, add the following line:

```
# Auto-load bash profile utils.
if [ -x ~/.profile.d/autoload.sh ]; then source ~/.profile.d/autoload.sh; fi
```

This will tell bash to run the [main autoloader script](https://github.com/aaronsenecal/bash-profile-utils/blob/master/autoload.sh), which will load core utilities, and then everything currently in the "autoload" directory at the repo root. You can organize your functions and exports into individual files within this directory without having to worry about sourcing each one.

Note, in order to enable the autoloader behavior, you'll need to ensure that the autoloader script is executable. You can do this with the following command:

```
chmod u+x ~/.profile.d/autoload.sh
```
