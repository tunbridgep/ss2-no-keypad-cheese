@echo off
::DO NOT USE ! OR % IN YOUR FOLDER NAMES!!!!
::IT WILL BREAK THE SCRIPT!
::Don't forget quotes when specifying paths!
::Use -f for feature mode, -v for version mode
::Pass additional parameters to add DML headers as specified in the headers folder (feature mode only for now)
call build/makedml.cmd -f "%~dp0\src" "%~dp0\out" "vanilla" "scp" "secmod"
@del "No Keypad Cheese.7z"
7z a "No Keypad Cheese.zip" "%~dp0\out\*"