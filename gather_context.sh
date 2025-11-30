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
	"wrapper.sh"
	"run_custom_nvim_after_array_start.sh"
	"paths.env"
	# "minimal_init.lua"
	# "unraid_config.lua"
)

# Create/clear output file
echo "Generating $OUT..."
: >"$OUT"

cat >>"$OUT" <<'EOF'
Ignore all context from all previous sessions. Act as a professional Bash developer specializing in unraid and neovim. Evaluate the following repo. search for bugs. suggest improvements. This needs to work on unraid buzybox. the license file is not included for brevity. custom_nvim_install.sh is the most important file. read all files thoroughly. Notice that some files such as license and uninstall are not include. All files are in the project root. https://github.com/NickStafford2/UnraidPersistentNeovim 

The program is working on my current unraid installation. I want you to review this project and suggest improvements and refactoring. I think it could be made cleaner. follow better standards and conventions. and be more configurable. tell me what you think.
if you update files at my request. do minimal changes necessary to do the change. only change the logic of the program. do not change variable names. do not add useless comments showing what you changed. do no delete my comments. do not rename files. 
answers should be somewhat brief. 
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
