menu nicklist {
  Battle Arena
  .Selecter: /run Notepad.exe $mircdir $+ %player_folder $+ $$1.char
  .List: {
    %chk.name = $dir="Choose Character file to open" $mircdir $+ %player_folder $+ *.char
    if (%chk.name == $null) { /halt }
    /run Notepad.exe %chk.name
  }
  -
  Control
  .Op:/mode # +ooo $$1 $2 $3
  .Deop:/mode # -ooo $$1 $2 $3
  .dvoice:/mode # -vvv $$1 $2 $3
  .voice:/mode # +vvv $$1 $2 $3
  .Kick:/kick # $$1
  .Kick (why):/kick # $$1 $$?="Reason for kick:"
  .Ban:/ban $$1 2
  .Ban, Kick:/kick # $$1 | /ban $$1 2
  .Ignore:/ignore $$1 1
  -
  Other
  .DCC
  ..Send:/dcc send $$1
  ..Chat:/dcc chat $$1
  .Whois:/whois $$1
}

menu menubar {
  Battle Arena
  .Setup
  ..Bot Name: /set %bot.name $?="Enter the IRC nick that you wish the bot to use" | writeini system.dat botinfo botname %bot.name
  ..Bot Owner: /set %bot.owner $?="Enter the IRC nick of the bot owner" | writeini system.dat botinfo bot.owner %bot.owner
  ..Channel to Battle in:/set %battlechan $?="what channel, include the #" | writeini system.dat botinfo questchan %battlechan
  ..Bot Password: /var %bot.pass $?="Enter a password the bot will use with nickserv" | writeini system.dat botinfo botpass %bot.pass
  .-
  .Documents
  ..Read Me: /run documentation\README.txt
  ..Versions: /run documentation\versions.txt
  ..Player's Guide: /run "documentation\guide - player's guide.txt"
  ..Creating Stuff Guide: /run "documentation\guide - creating new stuff.txt"
  ..Technical Guide: /run "documentation\guide - technical"
  ..Tech Types: /run "documentation\guide - tech types.txt"
  .-
  .Battle Arena Wiki: /run http://battlearena.heliohost.org/doku.php
}
