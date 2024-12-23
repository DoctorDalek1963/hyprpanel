_default:
	@just --list

alias r := run
alias b := build

# run the bar
run:
	ags run app.ts

# build the default bar
build:
	nom build {{justfile_directory()}}
