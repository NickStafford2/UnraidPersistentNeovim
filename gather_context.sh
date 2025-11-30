#!/bin/bash
# gather_context.sh
# Concatenate all important project files into LLMContext.txt

set -e

OUT="LLMContext.txt"

# List the important files here (edit as needed)
FILES=(
	"README.md"
	"install.sh"
	"custom_nvim_install.sh"
	"nvim-wrapper.sh"
	# "minimal_init.lua"
	# "unraid_config.lua"
)

# Create/clear output file
echo "Generating $OUT..."
: >"$OUT"

cat >>"$OUT" <<'EOF'
Act as a professional Bash developer specializing in unraid and neovim. Evaluate the following repo. search for bugs. suggest improvements. This needs to work on unraid buzybox. the license file is not included for brevity. custom_nvim_install.sh is the most important file. read all files thoroughly. Notice that license and uninstall are not include. All files are in the project root. https://github.com/NickStafford2/UnraidPersistentNeovim 

The change I am trying to make is that custom_nvim_install.sh should install to usb. but if run later, it should run on cache. I am considering making two separate files. one that installs to usb on boot. and a second one that moves files to mnt/cache after it is mounted and the unraid array starts. tell me if that is a better way to do this.
if you update files at my request. do minimal changes necessary to do the change. only change the logic of the program. do not change variable names. do not add useless comments showing what you changed. do no delete my comments. do not rename files. 
EOF
# Directory listing
{
	printf "\n\n==============================================\n"
	printf "DIRECTORY LISTING \n"
	printf "==============================================\n\n"
	find . -type d -name ".git" -prune -o -print
} >>"$OUT"

for f in "${FILES[@]}"; do
	if [ -f "$f" ]; then
		{
			printf "\n\n==============================================\n"
			printf "FILE: %s\n" "$f"
			printf "==============================================\n\n"
			cat "$f"
			printf "\n"
		} >>"$OUT"
	else
		{
			printf "\n\n==============================================\n"
			printf "FILE: %s (NOT FOUND)\n" "$f"
			printf "==============================================\n\n"
		} >>"$OUT"
	fi
done

echo "Done! All content saved to $OUT"
