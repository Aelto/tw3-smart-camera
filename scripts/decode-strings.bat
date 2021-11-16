:: encode the strings from the csv file in /strings and creates all the
:: w3strings files

call variables.cmd

@echo off
cd "D:\programs\steam\steamapps\common\The Witcher 3\content\content4"

%modkitpath%\w3strings --decode en.w3strings
cd %modpath%/scripts
