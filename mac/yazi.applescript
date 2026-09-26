-- Yazi.app: Yazi in a Ghostty window. install.sh builds it into ~/Applications and makes it the
-- folder handler, so Cmd+Shift+F, Spotlight and folders opened from other apps all land in Yazi.

on run
	openYazi(POSIX path of (path to home folder))
end run

-- A folder opens in it; a file ("Reveal in Finder") opens its folder with the file selected.
on open theItems
	repeat with theItem in theItems
		openYazi(POSIX path of theItem)
	end repeat
end open

on openYazi(thePath)
	-- A login shell puts Homebrew on the PATH, for Yazi and its preview tools.
	set theShellCommand to "exec yazi " & quoted form of thePath
	if application "Ghostty" is running then
		tell application "Ghostty"
			set theConfig to new surface configuration
			set command of theConfig to "/bin/zsh -lc " & quoted form of theShellCommand
			new window with configuration theConfig
			activate
		end tell
	else
		-- Ghostty's -e takes the command as separate arguments, so the shell string stays one of them.
		do shell script "open -a Ghostty --args -e /bin/zsh -lc " & quoted form of theShellCommand
	end if
end openYazi
