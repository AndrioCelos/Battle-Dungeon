; Installation script
; Loading this script will set up a Battle Arena bot and then unload itself.

on *:LOAD:{
  if ((%battlechan) && ($script(control.mrc))) {
    echo 12 -a Battle Arena seems to already be installed.
    unload -rs " $+ $script $+ "
    halt
  }

  ; Ensure that all the files are present.
  filecheck control.mrc
  filecheck characters.mrc
  filecheck battlecontrol.mrc
  filecheck ai.mrc
  filecheck attacks.mrc
  filecheck techs.mrc
  filecheck items.mrc
  filecheck skills.mrc
  filecheck mechs.mrc
  filecheck shop.mrc
  filecheck style.mrc
  filecheck auctionhouse.mrc
  filecheck achivements.mrc
  filecheck shopnpcs.mrc
  filecheck garden.mrc
  filecheck help.mrc
  filecheck dccchat.mrc

  filecheck systemaliases.als
  filecheck characters.als
  filecheck battlealiases.als
  filecheck bossaliases.als
  filecheck scoreboard.als
  filecheck battleformulas.als
  filecheck dungeons.als
  filecheck errorcheck.als

  filecheck system.dat.default
  filecheck version.ver

  dircheck characters
  dircheck bosses
  dircheck monsters
  dircheck npcs
  dircheck summons
  dircheck help-files
  dircheck dungeons
  dircheck txts

  filecheck characters\new_chr.char
  filecheck monsters\orb_fountain.char

  filecheck dbs\battlefields.db
  filecheck dbs\crafting.db
  filecheck dbs\drops.db
  filecheck dbs\equipment.db
  filecheck dbs\ignitions.db
  filecheck dbs\items.db
  filecheck dbs\playerstyles.db
  filecheck dbs\skills.db
  filecheck dbs\songs.db
  filecheck dbs\spoils.db
  filecheck dbs\steal.db
  filecheck dbs\techniques.db
  filecheck dbs\weapons.db

  filecheck lsts\accessorytypes.lst
  filecheck lsts\achievements.lst
  filecheck lsts\alchemy_armor.lst
  filecheck lsts\alchemy_items.lst
  filecheck lsts\armor_body.lst
  filecheck lsts\armor_feet.lst
  filecheck lsts\armor_hands.lst
  filecheck lsts\armor_legs.lst
  filecheck lsts\augments.lst
  filecheck lsts\battlefields.lst
  filecheck lsts\chest_black.lst
  filecheck lsts\chest_blue.lst
  filecheck lsts\chest_brown.lst
  filecheck lsts\chest_gold.lst
  filecheck lsts\chest_green.lst
  filecheck lsts\chest_orange.lst
  filecheck lsts\chest_purple.lst
  filecheck lsts\chest_silver.lst
  filecheck lsts\chest_mimic.lst
  filecheck lsts\dragonlastnames.lst
  filecheck lsts\dragonnames.lst
  filecheck lsts\elements.lst
  filecheck lsts\ignitions.lst
  filecheck lsts\items_accessories.lst
  filecheck lsts\items_auctionhouse.lst
  filecheck lsts\items_battle.lst
  filecheck lsts\items_consumable.lst
  filecheck lsts\items_dungeonkeys.lst
  filecheck lsts\items_food.lst
  filecheck lsts\items_gems.lst
  filecheck lsts\items_halloween.lst
  filecheck lsts\items_healing.lst
  filecheck lsts\items_instruments.lst
  filecheck lsts\items_mech.lst
  filecheck lsts\items_misc.lst
  filecheck lsts\items_portal.lst
  filecheck lsts\items_potioningredient.lst
  filecheck lsts\items_random.lst
  filecheck lsts\items_reset.lst
  filecheck lsts\items_runes.lst
  filecheck lsts\items_seals.lst
  filecheck lsts\items_special.lst
  filecheck lsts\items_summons.lst
  filecheck lsts\items_tormentreward.lst
  filecheck lsts\items_trust.lst
  filecheck lsts\pokemon.lst
  filecheck lsts\presidentnames.lst
  filecheck lsts\recipes.lst
  filecheck lsts\shieldlists.lst
  filecheck lsts\skills_active.lst
  filecheck lsts\skills_enhancingpoint.lst
  filecheck lsts\skills_killertraits.lst
  filecheck lsts\skills_passive.lst
  filecheck lsts\skills_resists.lst
  filecheck lsts\songs.lst
  filecheck lsts\statuseffects.lst
  filecheck lsts\weaponlists.lst

  if (%missing) {
    echo 4 -a The following files are missing:
    echo 4 -a %missing
    echo 4 -a Installation cannot continue.
    unload -rs " $+ $script $+ "
    return
  }

  ; Confirm that the user is sure.
  if (!$?!"This will install the Battle Arena bot into this mIRC installation. $crlf $&
    You don't need to run a Battle Arena bot to play the game. You can play using a normal IRC client. $crlf $&
    Do you wish to continue?") {
    unload -rs " $+ $script $+ "
    halt
  }
  if ($version < 6.3) {
    if (!$?!"Battle Arena is designed to work with mIRC 6.3. You seem to be running an older version. $crlf $&
      It is recommended you update. $crlf $&
      Continue with the installation anyway?") {
      unload -rs " $+ $script $+ "
      halt
    }
  }

  echo 7 -s Installing Battle Dungeon version $readini(version.ver, versions, Bot) $+ .

  ; Set variables.
  set %player_folder characters\
  set %boss_folder bosses\
  set %monster_folder monsters\
  set %npc_folder npcs\
  set %zapped_folder zapped\
  set %help_folder help-files\
  set %summon_folder summons\
  set %battlechan
  set %bot.owner
  set %bot.name
  set %helper Kibit
  set %battleis off
  set %battleisopen off
  set %_danger --------------------------------------------DO NOT REMOVE VARIABLES ABOVE THIS LINE---------------------------------------------------

  ; Load alias scripts.
  load -a systemaliases.als
  load -a characters.als
  load -a battlealiases.als
  load -a bossaliases.als
  load -a scoreboard.als
  load -a battleformulas.als
  load -a dungeons.als
  load -a errorcheck.als

  ; Load remote scripts.
  load -rs control.mrc
  load -rs characters.mrc
  load -rs battlecontrol.mrc
  load -rs ai.mrc
  load -rs attacks.mrc
  load -rs techs.mrc
  load -rs items.mrc
  load -rs skills.mrc
  load -rs mechs.mrc
  load -rs shop.mrc
  load -rs style.mrc
  load -rs auctionhouse.mrc
  load -rs achivements.mrc
  load -rs shopnpcs.mrc
  load -rs garden.mrc
  load -rs help.mrc
  load -rs dccchat.mrc
  if ($isfile(menus.mrc)) load -rs menus.mrc

  ; Set up basic configuration.
  if (!$isfile(system.dat)) copy system.dat.default system.dat

  echo 12*** The bot will now attempt to help you get things set up.
  echo 12*** Please set your bot's nick/name now.   Normal IRC nick rules apply (no spaces, for example)
  set %bot.name $?="Please enter the nick you wish the bot to use"
  writeini system.dat botinfo botname %bot.name | /nick %bot.name
  echo 12*** Great.  The bot's nick is now set to4 %bot.name

  echo 12*** Please set a bot owner now.
  set %bot.owner $?="Please enter the bot owner's IRC nick $crlf $&
    You can enter multiple nicknames separated by dots."
  writeini system.dat botinfo bot.owner %bot.owner
  echo 12*** Great.  The bot owner has been set to4 %bot.owner

  echo 12*** Now please set the IRC channel you plan to use the bot in
  set %battlechan $?="Enter an IRC channel (include the #)"
  writeini system.dat botinfo questchan %battlechan
  echo 12*** The battles will now take place in4 %battlechan

  echo 12*** Now please set the password you plan to register the bot with
  var %botpass $?*="Enter a password that you will use for the bot on NickServ."
  if (%botpass = $null) { var %botpass none }
  writeini system.dat botinfo botpass %botpass
  echo 12*** OK.  Your password has been set to4 %botpass  -- Don't forget to register the bot with nickserv.

  if ($status == connected) {
    .timerAutomatedBattleTimerCheck 0 300 /system.autobattle.timercheck

    ; Join the channel
    if (!$chan(%battlechan)) .timerJoin 1 2 join %battlechan

    ; Get rid of a ghost, if necessary, and send password
    var %bot.pass = $readini(system.dat, botinfo, botpass)
    if ($me != %bot.name) { .msg NickServ GHOST %bot.name %bot.pass | .timerNick 1 3 nick %bot.name }
    identifytonickserv
  }

  echo 7 -a Installation is complete.
  echo 7 -a Edit system.dat with your text editor of choice to further tailor the bot to your preference.
  unload -rs " $+ $script $+ "
  halt
}

alias -l filecheck if (!$isfile($1-)) set -u0 %missing %missing $1-
alias -l dircheck if (!$isdir($1-)) set -u0 %missing %missing $1-
