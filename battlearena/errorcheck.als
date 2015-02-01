; A Battle Arena error checking script
; version 1.2 (Friday 10 October 2014)
; by Andrio Celos
;
; Changelog:
;   Version 1.2:
;     Updated for Battle Arena 2.6 beta 10/07/14.
;     Expressions in character files containing references to $char or battle txt files are no longer checked fully.
;     Removed messages about major issues, as I don't know of any that get that rating.
;     Other message changes.

check {
  ; The main command for the script. To prevent abuse, this alias cannot be used as a function.
  ;   $1 : What to check: techs, items or monsters
  ;   $2 : Set to 'ignoreversion' to skip the Arena version check.

  if ($isid) return
  if (($version < 7) && (!$isalias(noop))) {
    if ($?!="You seem to be using an old version of mIRC. An alias for /noop must be created. $crlf This *will* modify your alias script files. $crlf Do you want to continue?") alias /noop return
    else halt
  }
  if ($2 != ignoreversion) {
    ; Do a quick check on the Arena version.
    if ($regex($battle.version(), ^(\d\.\d)$) > 0) {
      if ($regml(1) > 2.5) { echo 4 This script appears to be out of date. Use /check $1 ignoreversion to ignore this. | halt }
    }
    else if ($regex($battle.version(), ^(\d\.\d)beta_(\d\d)(\d\d)(\d\d)$) > 0) {
      if ($regml(1) > 2.6) { echo 4 This script appears to be out of date. Use /check $1 ignoreversion to ignore this. | halt }
      if ($regml(4) > 14) { echo 4 This script appears to be out of date. Use /check $1 ignoreversion to ignore this. | halt }
      if (($regml(4) = 14) && ($regml(2) > 11)) { echo 4 This script appears to be out of date. Use /check $1 ignoreversion to ignore this. | halt }
    }
    else {
      echo 4 Could not parse the Arena version ($battle.version).
    }
  }

  if ($0 < 1) { echo 2 Usage: /check <category> [ignoreversion] | echo 2 The following can be checked: techs, items, NPCs. | halt }

  set %issues_total 0
  set %issues_major 0
  if ($window(@issues) != $null) aline @issues ----------------
  :error

  if (($1 = techs) || ($1 = techniques)) {
    check_techs new_chr DoublePunch new_chr
    ; Those parameters are there in case of techniques like Asura Strike that need to reference a character.
  }
  else if ($1 = items) check_items
  else if (($1 = monsters) || ($1 = npcs)) check_monsters
  else { echo 2 Usage: /check <category> [ignoreversion] | echo 2 The following can be checked: techs, items, NPCs. | halt }

  titlebar Battle Arena version $battle.version written by James  "Iyouboushi" 
}

check_techs {
  ; Checks techniques
  ;   No parameters

  window @issues

  set %total_techniques $ini($dbfile(techniques.db), 0)
  var %current_technique = 0

  while (%current_technique < %total_techniques) {
    inc %current_technique

    var %technique_name = $ini($dbfile(techniques.db), %current_technique)
    if (%technique_name = techs) continue
    if (%technique_name = ExampleTech) continue
    titlebar Battle Arena $battle.version – Checking technique %current_technique / %total_techniques : %technique_name ...

    ; Spaces and = can't be in technique names.
    if (($chr(32) isin %technique_name) || (= isin %technique_name)) /log_issue Moderate Technique %technique_name has an invalid name: technique will be unusable.

    ; Either a TP or mech energy cost must be specified.
    var %tp.needed = $readini($dbfile(techniques.db), p, %technique_name, TP)
    var %energydrain = $readini($dbfile(techniques.db), $2, energyCost)
    if (%tp.needed != $null) {
      if (%tp.needed !isnum) /log_issue Moderate Technique %technique_name $+ 's TP cost ( $+ %tp.needed $+ ) is not a number: technique will cost 0 TP.
    }
    if (%energydrain != $null) {
      if (%energydrain !isnum) /log_issue Minor Technique %technique_name $+ 's energy cost ( $+ %tp.needed $+ ) is not a number: technique will cost 100 energy.
    }
    if ((%tp.needed = $null) && (%energydrain = $null)) /log_issue Moderate Technique %technique_name has no TP or energy cost; the technique may be unusable.

    var %tech.type = $readini($dbfile(techniques.db), %technique_name, Type)

    if (%tech.type = boost) { 
      ; Check that the base power is a number.
      var %tech.base = $readini($dbfile(techniques.db), p, %technique_name, BasePower)
      if (%tech.base !isnum) /log_issue Moderate Technique %technique_name $+ 's power is not a number: power will be zeroed.
      continue
    } 

    if (%tech.type = finalgetsuga) {
      ; Check that the base power is a number.
      var %tech.base = $readini($dbfile(techniques.db), p, %technique_name, BasePower)
      if (%tech.base !isnum) /log_issue Moderate Technique %technique_name $+ 's power is not a number: power will be zeroed.
      continue
    } 

    if (%tech.type = buff) {
      ; Not really much to check for here. We either have a resist buff, or a status effect.
      var %buff.type = $readini($dbfile(techniques.db), $2, status)
      if (%buff.type = en-spell) {
        var %enspell.element = $readini($dbfile(techniques.db), $2, element)
        if (%enspell.element !isin Earth.Fire.Wind.Water.Ice.Lightning.Light.Dark.HandToHand.Whip.Sword.Gun.Rifle.Katana.Wand.Stave.Spear.Scythe.Glyph.GreatSword.Bow) /log_issue Moderate Technique %technique_name uses an invalid modifier: technique will have no effect.
      }
      else {
        var %modifier.type = $readini($dbfile(techniques.db), %technique_name, modifier)
        if (%modifier.type != $null) {
          if (%modifier.type !isin Earth.Fire.Wind.Water.Ice.Lightning.Light.Dark.HandToHand.Whip.Sword.Gun.Rifle.Katana.Wand.Stave.Spear.Scythe.Glyph.GreatSword.Bow) /log_issue Moderate Technique %technique_name uses an invalid modifier: technique will have no effect.
        }
      }
      continue
    }

    if (%tech.type = ClearStatusPositive) continue
    if (%tech.type = ClearStatusNegative) continue

    if (%tech.type = heal) { 
      goto damage_checks
    }

    if (%tech.type = heal-aoe) { 
      goto damage_checks
    }

    if (%tech.type = single || %tech.type = status) {  
      ; Check the absorb setting.
      if ($readini($dbfile(techniques.db), %technique_name, absorb) != $null && $readini($dbfile(techniques.db), %technique_name, absorb) != yes && $readini($dbfile(techniques.db), %technique_name, absorb) != no) /log_issue Minor Technique %technique_name $+ 's absorb field is specified, but not as 'yes': field will be ignored.
      goto damage_checks
    }

    if (%tech.type = suicide) { 
      goto damage_checks
    }

    if (%tech.type = suicide-AOE) { 
      goto damage_checks
    }

    if (%tech.type = stealPower) { 
      ; Check that the base power is a number.
      goto damage_checks
    }

    if (%tech.type = AOE) { 
      ; Check the absorb setting.
      if ($readini($dbfile(techniques.db), %technique_name, absorb) != $null && $readini($dbfile(techniques.db), %technique_name, absorb) != yes && $readini($dbfile(techniques.db), %technique_name, absorb) != no) /log_issue Minor Technique %technique_name $+ 's absorb field is specified, but not as 'yes': field will be ignored.
      goto damage_checks
    }

    /log_issue Moderate Technique %technique_name has an unrecognised type ( $+ %tech.type $+ ).
    continue

    :damage_checks
    ; The base stat needed must actually exist.
    var %base.stat.needed = $readini($dbfile(techniques.db), %technique_name, stat)
    if (%base.stat.needed = $null) { var %base.stat.needed int }
    if (%base.stat.needed !isin STR.DEF.INT.SPD.HP.TP.IgnitionGauge) /log_issue Moderate Technique %technique_name uses an invalid attribute: technique will do very little damage.

    ; Check that the base power is a number.
    var %tech.base = $readini($dbfile(techniques.db), p, %technique_name, BasePower)
    if (%tech.base !isnum) /log_issue Moderate Technique %technique_name $+ 's power is not a number: power will be zeroed.

    ; Check the magic setting.
    if ($readini($dbfile(techniques.db), %technique_name, magic) != $null && $readini($dbfile(techniques.db), %technique_name, magic) != yes && $readini($dbfile(techniques.db), %technique_name, magic) != no) /log_issue Minor Technique %technique_name $+ 's magic field is specified, but not as 'yes': field will be ignored.

    ; Check the element.
    var %tech.element = $readini($dbfile(techniques.db), %technique_name, element)
    if ((%tech.element) && (. isin %tech.element || %tech.element !isin none.fire.water.ice.lightning.wind.earth.light.dark)) /log_issue Minor Technique %technique_name uses an unknown element ( $+ %tech.element $+ ): it will be unaffected by weather.

    ; Check that the ignore defense percent is a number and not a decimal.
    var %ignore.defense.percent = $readini($dbfile(techniques.db), %technique_name, IgnoreDefense)
    if ((%ignore.defense.percent) && (%ignore.defense.percent !isnum)) /log_issue Moderate Technique %technique_name $+ 's ignore defense is not a number: it will be zeroed.
    else if (%ignore.defense.percent > 0 && %ignore.defense.percent < 1) /log_issue Minor Technique %technique_name $+ 's ignore defense is a decimal where a percentage (0-100) is expected.

    ; Check that the status types are valid.
    var %status.type.list = $readini($dbfile(techniques.db), %technique_name, StatusType)
    if (%status.type.list != $null) { 
      var %number.of.statuseffects = $numtok(%status.type.list, 46) 

      if (%number.of.statuseffects >= 1) {
        var %status.value = 1
        while (%status.value <= %number.of.statuseffects) { 
          var %current.status.effect = $gettok(%status.type.list, %status.value, 46)
          if (%current.status.effect !isin stop.poison.silence.blind.virus.amnesia.paralysis.zombie.slow.stun.curse.charm.intimidate.defensedown.strengthdown.intdown.petrify.bored.confuse.random) /log_issue Critical Technique %technique_name uses an invalid status type! Use one of: stop, poison, silence, blind, virus, amnesia, paralysis, zombie, slow, stun, curse, charm, intimidate, defensedown, strengthdown, intdown, petrify, bored, confuse, random
          inc %status.value 1
        }  
      }
    }

    ; Check the number of hits.
    var %tech.howmany.hits = $readini($dbfile(techniques.db), %technique_name, hits)
    if ((%tech.howmany.hits) && (%tech.howmany.hits !isnum)) /log_issue Minor Technique %technique_name $+ 's number of hits is not a number: it will be zeroed.

  }

  echo -a 12Checked $calc(%current_technique - 1) techniques and found %issues_total  $+ $iif(%issues_total = 1, issue, issues) $+ .
}

check_items {
  ; Checks items
  ;    No parameters

  window @issues
  titlebar Battle Arena $battle.version – Checking item lists...

  ; Read in the lists at the top of the database, and make sure there are no broken references there.
  check_db_item_lists Gems gem
  check_db_item_lists Keys key
  check_db_item_lists Runes rune

  ; Read in the item list files, and make sure there are no broken references there.
  check_item_lists items_accessories.lst accessory
  check_item_lists items_battle.lst status.damage.snatch
  check_item_lists items_consumable.lst consume
  check_item_lists items_food.lst food
  check_item_lists items_gems.lst gem
  check_item_lists items_healing.lst heal.tp.revive.ignitiongauge.curestatus
  check_item_lists items_misc.lst misc.trade
  check_item_lists items_portal.lst portal
  check_item_lists items_random.lst random
  check_item_lists items_reset.lst shopreset
  check_item_lists items_summons.lst summon

  ; Now go through the database checking for errors in each item.
  set %total_items $ini($dbfile(items.db), 0)
  var %current_item = 0
  while (%current_item < %total_items) {
    inc %current_item

    var %item_name = $ini($dbfile(items.db), %current_item)
    if (%item_name = Items) continue
    titlebar Battle Arena $battle.version – Checking item %current_item / %total_items : %item_name ...

    check_item new_chr %item_name on new_chr
  }

  echo -a 12Checked $calc(%current_item - 1) items and found %issues_total  $+ $iif(%issues_total = 1, issue, issues) $+ .
}
check_db_item_lists {
  ; Ensures that all of the items in an items.db list are the correct type.
  ;  $1 : The header of the list in items.db
  ;  $2 : The type of item that is considered valid.

  var %db_list = $readini($dbfile(items.db), Items, $1)
  set %total_items $numtok(%db_list, 46)
  var %current_item = 0
  while (%current_item < %total_items) {
    inc %current_item

    var %item_name = $gettok(%db_list, %current_item, 46)
    var %item_type = $readini($dbfile(items.db), %item_name, Type)

    if (%item_type) {
      if (%item_type != $2) /log_issue Moderate Item %item_name is listed under ' $+ $1 $+ ' but isn't a $2 $+ .
    }
    else /log_issue Moderate Missing item %item_name is listed under ' $+ $1 $+ '.
  }
}
check_item_lists {
  ; Checks an item .lst file to ensure all items listed are of the correct type.
  ;  $1 : The filename to check, relative to the /lsts folder.
  ;  $2 : One of more types of items that are considered valid. Can be a single type or a period-delimited list.

  var %total_items = $lines($lstfile($1))
  var %current_item = 0

  while (%current_item < %total_items) {
    inc %current_item

    set %item_name $read($lstfile($1), %current_item)
    var %item_type = $readini($dbfile(items.db), %item_name, Type)

    if (%item_type) {
      if ((. isin %item_type) || (%item_type !isin $2)) /log_issue Moderate Item %item_name is listed in $1 but isn't a $+ $iif($left($2, 1) isin aeiou,n,$null) $2 $+ .
    }
    else /log_issue Moderate Missing item %item_name is listed in $1 $+ .

  } 
}
check_item {
  ; Checks an individual item definition for errors.
  ;   $1 : A character name. new_chr is recommended as all bots should have it.
  ;   $2 : The item to check.
  ;   $3 : 'on'
  ;   $4 : A character name. new_chr is recommended as all bots should have it.

  var %item_type = $readini($dbfile(items.db), $2, Type)

  ; Check for the exclusive tag.
  var %exclusive = $readini($dbfile(items.db), $2, exclusive)
  if ((%exclusive != $null) && (%exclusive != yes) && (%exclusive != no)) /log_issue Minor Item %item_name $+ 's exclusive field is specified, but not as 'yes': field will be ignored.

  if (%item_type = food) {
    ; Food items must define a valid attribute and amount. The amount MAY be negative.
    var %food.type = $readini($dbfile(items.db), $2, target)
    var %food.bonus = $readini($dbfile(items.db), $2, amount)

    if ($istok(HP.TP.STR.DEF.INT.SPD.IgnitionGauge.style.redorbs.blackorbs, %food.type, 46) = $false) /log_issue Moderate Item $2 $+ 's attribute is invalid; it will have no effect. Use one of: HP, TP, STR, DEF, INT, SPD, IgnitionGauge, style, redorbs, blackorbs.
    if (%food.bonus !isnum) /log_issue Moderate Item $2 $+ 's bonus amount is not a number; it will have no effect.

    return
  }

  if (%item_type = portal) {
    ; Portal items must define existing monsters.
    var %monster.to.spawn = $readini($dbfile(items.db), $2, Monster)
    var %battlefield = $readini($dbfile(items.db), $2, Battlefield)
    var %weather = $readini($dbfile(items.db), $2, weather)
    var %allied.notes = $readini($dbfile(items.db), $2, alliednotes)

    var %value = 1 | var %number.of.monsters $numtok(%monster.to.spawn,46)
    while (%value <= %number.of.monsters) {
      set %current.monster.to.spawn $gettok(%monster.to.spawn,%value,46)

      var %isboss = $isfile($boss(%current.monster.to.spawn))
      var %ismonster = $isfile($mon(%current.monster.to.spawn))

      if ((%isboss != $true) && (%ismonster != $true)) /log_issue Moderate Item $2 $+  references missing monster %current.monster.to.spawn  $+ ; it will be skipped.
      inc %value
    }

    ; Portal items must define an existing battlefield.
    var %battlefield = $readini($dbfile(items.db), $2, Battlefield)
    if ($ini($dbfile(battlefields.db), %battlefield) = $null) /log_issue Moderate Item $2 $+  references missing battlefield %battlefield  $+ .

    return
  }

  if (%item_type = key) {
    var %unlocks = $readini($dbfile(items.db), $2, Unlocks)
    ; Keys must define a valid chest colour.
    if ($istok(red.orange.green.brown.blue.silver.gold.purple.black, %unlocks, 46) = $false) /log_issue Moderate Item $2 $+  references a non-existent colour of treasure chest; it will be useless.
    return
  }

  if (%item_type = consume) {
    ; Skill items should reference an existing skill.
    var %skill = $readini($dbfile(items.db), $2, Skill)
    var %total_active_skills = 
    if (!$read($lstfile(skills_active.lst), w, %skill) && !$read($lstfile(skills_active2.lst), w, %skill)) /log_issue Minor Item $2 $+  references a non-existent skill; its !view-info entry will be invalid.
    return
  }

  if (%item_type = gem || %item_type = misc || %item_type = trade) {
    return
  }

  if (%item_type = rune) {
    var %augment.name = $readini($dbfile(items.db), $2, augment)
    if (!%augment.name) /log_issue Moderate Item $2  is missing an augment.
    return
  }

  if (%item_type = accessory) {
    ; Accessories must be of a valid type.
    var %i = 1
    var %types = $readini($dbfile(items.db), $2, accessoryType)
    var %total_types = $numtok(%types, 46)
    while (%i <= %total_types) {
      var %type = $gettok(%types, %i, 46)
      if (%type isin IncreaseMeleeAddPoison.IncreaseH2HDamage.IncreaseSpearDamage.IncreaseSwordDamage.IncreaseGreatSwordDamage.IncreaseWhipDamage.IncreaseGunDamage.IncreaseBowDamage.IncreaseGlyphDamage.IncreaseKatanaDamage.IncreaseWandDamage.IncreaseStaffDamage.IncreaseScytheDamage.IncreaseAxeDamage.IncreaseDaggerDamage.IncreaseHealing.ElementalDefense.IncreaseRedOrbs.IncreaseSpellDamage.IncreaseMeleeDamage.IncreaseMagic, %i, 46) {
        var %amount = $readini($dbfile(items.db), $2, %type $+ .amount)
        if (%amount = $null) /log_issue Moderate Accessory $2 has no %type amount; it will have no effect.
        else if (%amount !isnum) /log_issue Moderate Accessory $2 $+ 's %type amount is not a number; it will have no effect.
        else if (%amount >= 10) /log_issue Moderate Accessory $2 $+ 's %type amount is very high. It should be a fractional factor instead of a percentage.
      }
      else if (%type isin IncreaseCriticalHits.BlockAllStatus.IncreaseSteal.IncreaseTreasureOdds.IncreaseMimicOdds.EnhanceBlocking, %i, 46) {
        var %amount = $readini($dbfile(items.db), $2, %type $+ .amount)
        if (%amount = $null) /log_issue Moderate Accessory $2 has no %type amount; it will have no effect.
        else if (%amount !isnum) /log_issue Moderate Accessory $2 $+ 's %type amount is not a number; it will have no effect.
        else if ((%amount > -0.5) && (%amount < 0.5)) /log_issue Moderate Accessory $2 $+ 's %type amount is very low. It should be a percentage instead of a fraction.
      }
      else if (%type isin IncreaseMechEngineLevel.ReduceShopLevel, %i, 46) {
        var %amount = $readini($dbfile(items.db), $2, %type $+ .amount)
        if (%amount = $null) /log_issue Moderate Accessory $2 has no %type amount; it will have no effect.
        else if (%amount !isnum) /log_issue Moderate Accessory $2 $+ 's %type amount is not a number; it will have no effect.
        else if ((%amount > -0.5) && (%amount < 0.5)) /log_issue Moderate Accessory $2 $+ 's %type amount is very low. It should be a number to add directly instead of a fraction.
      }
      else if (%type !isin CurseAddDrain.Mug.Stylish.IgnoreQuicksilver) /log_issue Moderate Accessory $2 has unrecognised type %type $+ .
      inc %i
    }
    return
  }

  if (%item_type = random) {
    return
  }

  if (%item_type = shopreset) {
    ; Discount items must define a valid amount.
    var %shop.reset.amount = $readini($dbfile(items.db), $2, amount)
    if (%shop.reset.amount !isnum) /log_issue Moderate Item $2 $+ 's discount amount is not a number; it will have no effect.
    return
  }

  if (%item_type = damage) {
    var %fullbring_item.base = $readini($dbfile(items.db), $2, FullbringAmount)
    var %item.base = $readini($dbfile(items.db), $2, Amount)
    if (%item.base !isnum) /log_issue Moderate Item $2 $+ 's damage amount is not a number; its power will be zeroed.

    var %current.element = $readini($dbfile(items.db), $2, element)
    if ((%current.element) && (. isin %current.element || %current.element !isin none.fire.water.ice.lightning.wind.earth.light.dark)) /log_issue Minor Item $2 uses an unknown element ( $+ %tech.element $+ ).

    return
  }

  if (%item_type = snatch) {
    return
  }

  if (%item_type = heal) {
    ; Healing items must define a valid amount.
    var %item.base = $readini($dbfile(items.db), $2, Amount)
    if (%item.base !isnum) /log_issue Moderate Item $2 $+ 's healing amount is not a number; its power will be zeroed.
    return
  }

  if (%item_type = curestatus) {
    return
  }

  if (%item_type = tp) {
    ; TP items must define a valid amount.
    var %tp.amount = $readini($dbfile(items.db), $2, amount)
    if (%tp.amount !isnum) /log_issue Moderate Item $2 $+ 's TP amount is not a number; it will have no effect.
    return
  }

  if (%item_type = ignitiongauge) {
    ; Ignition charge items must define a valid amount.
    var %IG.amount = $readini($dbfile(items.db), $2, amount)
    if (%IG.amount !isnum) /log_issue Moderate Item $2 $+ 's charge amount is not a number; it will have no effect.
    return
  }

  if (%item_type = status) {
    var %status.type.list = $readini($dbfile(items.db), $3, StatusType) 

    if (%status.type.list != $null) { 
      var %number.of.statuseffects = $numtok(%status.type.list, 46) 

      var %status.value = 1
      while (%status.value <= %number.of.statuseffects) { 
        set %current.status.effect $gettok(%status.type.list, %status.value, 46)
        if (%current.status.effect !isin stop.poison.silence.blind.virus.amnesia.paralysis.zombie.slow.stun.curse.charm.intimidate.defensedown.strengthdown.intdown.petrify.bored.confuse.random) /log_issue Moderate Item $2 uses an invalid status type. Use one of: stop, poison, silence, blind, virus, amnesia, paralysis, zombie, slow, stun, curse, charm, intimidate, defensedown, strengthdown, intdown, petrify, bored, confuse, random
        inc %status.value 1
      }  
      unset %number.of.statuseffects | unset %current.status.effect
    }

    var %fullbring_item.base = $readini($dbfile(items.db), $2, FullbringAmount)
    var %item.base = $readini($dbfile(items.db), $2, Amount)
    if (%item.base !isnum) /log_issue Moderate Item $2 $+ 's damage amount is not a number; its power will be zeroed.

    var %current.element = $readini($dbfile(items.db), $2, element)
    if ((%current.element) && (. isin %current.element || %current.element !isin none.fire.water.ice.lightning.wind.earth.light.dark)) /log_issue Minor Item $2 uses an unknown element ( $+ %tech.element $+ ).

    return
  }

  if (%item_type = revive) {
    return
  }

  if (%item_type = summon) {
    ; Summon items must define an existing summon.
    var %summon.name = $readini($dbfile(items.db), $2, summon)
    if (!$isfile($summon(%summon.name))) /log_issue Moderate Item $2 $+  references missing summon %summon.name $+ ; it will have no effect.
    return
  }

  if (%item_type = mechCore) {
    ; Mech cores must define an energy cost and augments.
    var %energy.cost = $readini($dbfile(items.db), $2, energyCost)
    if (%energy.cost = $null) /log_issue Moderate Item $2 $+  has no energy cost; it will cost 100 energy.
    else if (%energy.cost !isnum) /log_issue Moderate Item $2 $+ 's energy cost is not a number.

    ;var %augments $readini($dbfile(items.db), $2, augment)
    ;var %total_augments $numtok(%augments, 46)
    ;var %augment 1
    ;while (%augment <= %total_augments) {
    ;  var %current_augment $gettok(%augments, %augment, 46)
    ;}
    return
  }

  if (%item_type = instrument) {
    return
  }

  if (%item_type = special) {
    var %special_type = $readini($dbfile(items.db), $2, SpecialType)

    if (%special_type = GainWeapon) {
      var %weapon =  $readini($dbfile(items.db), $2, Weapon)
      if (!$ini($dbfile(weapons.db), %weapon)) /log_issue Moderate Item $2 references missing weapon ( $+ %weapon $+ ).
      return
    }

    if (%special_type = GainSong) {
      var %song =  $readini($dbfile(items.db), $2, Song)
      if (!$ini($dbfile(songs.db), %song)) /log_issue Moderate Item $2 references missing song ( $+ %song $+ ).
      return
    }

    /log_issue Moderate Item $2 $+  has an unrecognised special type ( $+ %special_type $+ ). If it's a mod, this script will need to be edited. Otherwise, the item will have no effect.
  }

  /log_issue Moderate Item $2 $+  has an unrecognised type ( $+ %item_type $+ ). If it's a mod, this script will need to be edited. Otherwise, the item will have no effect.
}

check_monsters {
  ; Checks monsters (including bosses and NPCs)
  ;    No parameters

  window @issues
  set %monster_count 0

  set -u0 %category Monster
  noop $findfile($mon_path, *, 0, 0, check_monster_file $1-)
  set -u0 %category Boss
  noop $findfile($boss_path, *, 0, 0, check_monster_file $1-)
  set -u0 %category NPC
  noop $findfile($npc_path, *, 0, 0, check_monster_file $1-)

  ; Make sure that the orb fountain is present.
  if (!$isfile($mon(orb_fountain))) /log_issue Critical The Red Orb Fountain (monsters\orb_fountain.char) is missing!

  echo -a 12Checked %monster_count characters and found %issues_total  $+ $iif(%issues_total = 1, issue, issues) $+ .
}
check_monster_file {
  ; Ensures that all files in the /monsters and /bosses folders have a .char extension.
  ;   $1-: The file path to check, relative to the working directory.

  inc %monster_count
  set -u0 %file_path $1-
  var %file = $nopath($1-)
  if (%file = Note.txt) return
  titlebar Battle Arena $battle.version – Checking $lower(%category) %file ...

  ; Check the file extension.
  noop $regex(%file, ^.*\.([^.]+)$)
  if ($regml(1) != char) { /log_issue Minor Found file %file in the monsters folder without a .char extension; it will be ignored. | return }

  var %name = $remove(%file, .char)
  if ((%name = new_mon) || (%name = new_boss) || (%name = $null) || (%name = orb_fountain)) return

  check_monster %name
}
check_monster {
  ; Checks a monster's character file for errors.
  ;   $1 : The monster's name.
  ;   %file.path : The path to their character file.

  ; Check the monster's attributes.
  set %hp $readini(%file_path, BaseStats, HP)
  noop $monster_get_hp($1, $null, 1)
  set %tp $readini(%file_path, BaseStats, TP)
  if (!$validate_expression($readini(%file_path, n, BaseStats, TP))) set %tp 0
  set %str $readini(%file_path, BaseStats, Str)
  set %def $readini(%file_path, BaseStats, Def)
  set %int $readini(%file_path, BaseStats, Int)
  set %spd $readini(%file_path, BaseStats, Spd)
  noop $monster_get_attributes($1, 1, $null)

  if (%hp !isnum) /log_issue Moderate %category $+  $1 $+ 's base HP is not a number; their HP will be zeroed.
  if (%tp !isnum) /log_issue $iif($readini(%file_path, info, BattleStats) = ignore, Moderate, Minor) %category $+  $1 $+ 's base TP is not a number; their TP will be zeroed.
  if (%str !isnum) /log_issue Moderate %category $+  $1 $+ 's base STR is not a number; their HP will be zeroed.
  if (%def !isnum) /log_issue Moderate %category $+  $1 $+ 's base DEF is not a number; their HP will be zeroed.
  if (%int !isnum) /log_issue Moderate %category $+  $1 $+ 's base INT is not a number; their HP will be zeroed.
  if (%spd !isnum) /log_issue Moderate %category $+  $1 $+ 's base SPD is not a number; their HP will be zeroed.

  unset %hp %tp %str %def %int %spd

  if ((%category != NPC) && ($readini(%file_path, Info, Flag) != monster)) /log_issue Moderate %category $+  $1 $+ 's info flag is not set as 'monster'.
  if ((%category == NPC) && ($readini(%file_path, Info, Flag) != npc)) /log_issue Moderate %category $+  $1 $+ 's info flag is not set as 'npc'.

  if (($readini(%file_path, Info, Streak) != $null) && ($readini(%file_path, Info, Streak) !isnum)) /log_issue Moderate %category $+  $1 $+ 's Streak field is not a number; the value will be zeroed.
  if (($readini(%file_path, Info, StreakMax) != $null) && ($readini(%file_path, Info, StreakMax) !isnum)) /log_issue Moderate %category $+  $1 $+ 's StreakMax field is not a number; the value will be zeroed.
  if (($readini(%file_path, Info, BossLevel) != $null) && ($readini(%file_path, Info, BossLevel) !isnum)) /log_issue Moderate %category $+  $1 $+ 's BossLevel field is not a number; the value will be zeroed.
  if ($readini(%file_path, Info, Month) != $null) {
    if ($readini(%file_path, Info, Month) !isnum) /log_issue Moderate %category $+  $1 $+ 's Month field is not a number.
    else if ($readini(%file_path, Info, Month) < 1 || $readini(%file_path, Info, Month) > 12) /log_issue Moderate %category $+  $1 $+ 's Month field is not within the valid range (01-12).
  }
  if ($readini(%file_path, Info, AI-Type) != $null) {
    if ((. isin $readini(%file_path, Info, AI-Type)) || ($readini(%file_path, Info, AI-Type) !isin Berserker.Defender)) /log_issue Minor %category $+  $1 $+ 's AI-Type field is invalid. Use one of: Berserker, Defender
  }
  if (($readini(%file_path, Info, OrbBonus) != $null) && ($readini(%file_path, Info, OrbBonus) !isin yes.no.false)) /log_issue Minor %category $+  $1 $+ 's OrbBonus field is specified, but not as 'yes'; the field will be ignored.
  if (($readini(%file_path, Info, CanFlee) != $null) && ($readini(%file_path, Info, CanFlee) !isin true.no.false)) /log_issue Minor %category $+  $1 $+ 's CanFlee field is specified, but not as 'yes'; it will not flee.
  if (($readini(%file_path, Info, MetalDefense) != $null) && ($readini(%file_path, Info, MetalDefense) !isin true.no.false)) /log_issue Moderate %category $+  $1 $+ 's MetalDefense field is specified, but not as 'true'; it will not take effect.

  ; Check the biome.
  var %biome.list = $readini(%file_path, Info, Biome)
  if (%biome.list != $null) {
    var %number.of.biomes = $numtok(%biome.list, 46) 
    var %i = 1
    while (%i <= %number.of.statuseffects) { 
      var %current.biome = $gettok(%biome.list, %i, 46)
      if (!$read($lstfile(battlefields.lst), w, %current.biome)) var %bad_biomes $addtok(%bad_biomes, %current.biome, 46)
      inc %i
    }  
  }
  if (%bad_biomes) /log_issue Moderate %category $+  $1 $+ 's Biome list includes unlisted battlefield(s) $replace(%bad_biomes, ., $chr(44) $+ $chr(32)) $+ .

  ; Check the weapons.
  if ($readini(%file_path, n, weapons, $readini(%file_path, weapons, equipped)) = $null) /log_issue Minor %category $+  $1 is missing $readini(%file_path, Info, Gender) equipped weapon ( $+ $readini(%file_path, weapons, equipped) $+ ); its power will be zeroed.
  if (($readini(%file_path, weapons, equippedleft) != $null) && ($readini(%file_path, n, weapons, $readini(%file_path, weapons, equippedleft)) = $null)) {
    if ($readini($dbfile(weapons.db), $readini(%file_path, weapons, equippedleft), type) != shield) /log_issue Minor %category $+  $1 is missing $readini(%file_path, Info, Gender) equipped weapon ( $+ $readini(%file_path, weapons, equippedleft) $+ ); its power will be zeroed.
  }
  var %ai_type = $readini(%file_path, info, ai_type) 

  var %i = 0
  var %count = $ini(%file_path, weapons, 0)
  while (%i < %count) {
    inc %i
    var %weapon = $ini(%file_path, weapons, %i)
    if (;* iswm %weapon) continue
    if ((. !isin %weapon) && (%weapon isin Equipped.EquippedLeft.Weakness.Strong)) continue
    if ((%weapon = none) && (%ai_type = defender)) continue
    if (!$ini($dbfile(weapons.db), %weapon)) /log_issue Minor %category $+  $1 uses missing weapon ( $+ %weapon $+ ).
    if (!$validate_expression($readini(%file_path, n, weapons, %weapon))) continue
    if ($readini(%file_path, weapons, %weapon) !isnum) /log_issue Minor %category $+  $1 $+ 's weapon level for %weapon is not a number; it will be zeroed.
  }

  ; Check the skills.
  var %i = 0
  var %count = $ini(%file_path, skills, 0)
  while (%i < %count) {
    inc %i
    var %skill = $ini(%file_path, skills, %i)
    if (;* iswm %skill) continue
    if ((. isin %skill) || (%skill isin CoverTarget.shadowcopy_name.Summon.resist-weaponlock.Singing)) continue
    if (%skill isin CocoonEvolve.MonsterConsume.Snatch.MagicShift.DemonPortal.MonsterSummon.RepairNaturalArmor.ChangeBattlefield.Quicksilver) noop
    else if (%skill = Resist-Paralyze) continue
    else if (%skill = Wizardy) continue
    else if (Resist- isin %skill) {
      var %status_resisted = $gettok(%skill, 2-, 45)
      if (%status_resisted !isin stop.poison.silence.blind.drunk.virus.amnesia.paralysis.zombie.slow.stun.curse.charm.intimidate.defensedown.strengthdown.intdown.petrify.bored.confuse) var %missing_resists $addtok(%missing_resists, Resist- $+ %status_resisted, 46)
    }
    else if (-killer isin %skill) continue
    else if ((!$read($lstfile(skills_passive.lst), w, %skill)) && (!$read($lstfile(skills_active.lst), w, %skill)) && (!$read($lstfile(skills_killertraits.lst), w, %skill))) var %missing_skills $addtok(%missing_skills, %skill, 46)
    if (!$validate_expression($readini(%file_path, n, skills, %weapon))) continue
    if ($readini(%file_path, skills, %skill) !isnum) /log_issue Minor %category $+  $1 $+ 's skill level for %skill is not a number; it will be zeroed.
  }
  if (%missing_skills) /log_issue Moderate %category $+  $1 uses missing skill(s) $replace(%missing_skills, ., $chr(44) $+ $chr(32)) $+ ; it might not work.
  if (%missing_resists) /log_issue Moderate %category $+  $1 uses invalid resistance(s) $replace(%missing_resists, ., $chr(44) $+ $chr(32)) $+ ; it will not work.
  unset %missing_skills | unset %missing_resists
  if ($readini(%file_path, skills, CoverTarget)) /log_issue Moderate %category $+  $1 has an initial Cover target. This is inadvisable.
  if ($readini(%file_path, skills, provoke.target)) /log_issue Moderate %category $+  $1 has an initial Provoke target. This is inadvisable.
  if ($readini(%file_path, skills, royalguard.on)) if ($readini(%file_path, skills, royalguard.on) !isin on.off) /log_issue Minor %category $+  $1  has an initial royalguard.on field, but it isn't 'on'; it will be ignored.
  if ($readini(%file_path, skills, manawall.on)) if ($readini(%file_path, skills, manawall.on) !isin on.off) /log_issue Minor %category $+  $1  has an initial manawall.on field, but it isn't 'on'; it will be ignored.
  if ($readini(%file_path, skills, doubleturn.on)) if ($readini(%file_path, skills, doubleturn.on) !isin on.off) /log_issue Minor %category $+  $1  has an initial doubleturn.on field, but it isn't 'on'; it will be ignored.
  if ($readini(%file_path, skills, mightystrike.on)) if ($readini(%file_path, skills, mightystrike.on) !isin on.off) /log_issue Minor %category $+  $1  has an initial mightystrike.on field, but it isn't 'on'; it will be ignored.
  if ($readini(%file_path, skills, konzen-ittai.on)) if ($readini(%file_path, skills, konzen-ittai.on) !isin on.off) /log_issue Minor %category $+  $1  has an initial konzen-ittai.on field, but it isn't 'on'; it will be ignored.
  if ($readini(%file_path, skills, elementalseal.on)) if ($readini(%file_path, skills, elementalseal.on) !isin on.off) /log_issue Minor %category $+  $1  has an initial elementalseal.on field, but it isn't 'on'; it will be ignored.
  if ($readini(%file_path, skills, utsusemi.on)) if ($readini(%file_path, skills, utsusemi.on) !isin on.off) /log_issue Minor %category $+  $1  has an initial utsusemi.on field, but it isn't 'on'; it will be ignored.
  ; Make sure its Monster Summon data is valid.
  if ($readini(%file_path, skills, monstersummon)) {
    if (!$readini(%file_path, skills, monstersummon.chance)) /log_issue Moderate %category $+  $1 has no monstersummon.chance field; it won't use the skill.
    if (!$readini(%file_path, skills, monstersummon.numberspawn)) /log_issue Moderate %category $+  $1 has no monstersummon.numberspawn field; it won't use the skill.
    if (!$readini(%file_path, skills, monstersummon.monster)) /log_issue Moderate %category $+  $1 has no monstersummon.monster field; it won't use the skill.
  }
  if ($readini(%file_path, skills, monstersummon.chance)) {
    if ($!char !isin $readini(%file_path, n, skills, monstersummon.chance)) {
      if ($readini(%file_path, skills, monstersummon.chance) !isnum) /log_issue Moderate %category $+  $1 $+ 's monstersummon.chance field is not a number; it won't use the skill.
      else if ($readini(%file_path, skills, monstersummon.chance) < 1) /log_issue Moderate %category $+  $1 $+ 's monstersummon.chance field is not within the valid range (1-100); it won't use the skill.
      else if ($readini(%file_path, skills, monstersummon.chance) > 100) /log_issue Minor %category $+  $1 $+ 's monstersummon.chance field is not within the valid range (1-100).
    }
    if ($readini(%file_path, n, skills, monstersummon) = $null) /log_issue Moderate %category $+  $1 has a monstersummon.chance field, but does not know the Monster Summon skill.
  }
  if ($readini(%file_path, skills, monstersummon.numberspawn)) {
    if ($!char !isin $readini(%file_path, n, skills, monstersummon.numberspawn)) {
      if ($readini(%file_path, skills, monstersummon.numberspawn) !isnum) /log_issue Moderate %category $+  $1 $+ 's monstersummon.numberspawn field is not a number; it won't use the skill.
    }
    if ($readini(%file_path, n, skills, monstersummon) = $null) /log_issue Moderate %category $+  $1 has a monstersummon.numberspawn field, but does not know the Monster Summon skill.
  }
  if ($readini(%file_path, skills, monstersummon.monster)) if (!$isfile($mon($readini(%file_path, skills, monstersummon.monster)))) /log_issue Moderate %category $+  $1 's monstersummon.monster field references missing monster $readini(%file_path, skills, monstersummon.monster) $+ ; the skill won't work.
  ; Make sure the Change Battlefield data is valid.
  if ($readini(%file_path, skills, ChangeBattlefield.chance)) {
    if ($!char !isin $readini(%file_path, n, skills, ChangeBattlefield.chance)) {
      if ($readini(%file_path, skills, ChangeBattlefield.chance) !isnum) /log_issue Moderate %category $+  $1 $+ 's ChangeBattlefield.chance field is not a number; it won't use the skill.
      else if ($readini(%file_path, skills, ChangeBattlefield.chance) < 1) /log_issue Moderate %category $+  $1 $+ 's ChangeBattlefield.chance field is not within the valid range (1-100); it won't use the skill.
      else if ($readini(%file_path, skills, ChangeBattlefield.chance) > 100) /log_issue Minor %category $+  $1 $+ 's ChangeBattlefield.chance field is not within the valid range (1-100).
    }
    if ($readini(%file_path, n, skills, ChangeBattlefield) = $null) /log_issue Moderate %category $+  $1 has a ChangeBattlefield.chance field, but does not know the Chaneg Battlefield skill.
  }
  if ($readini(%file_path, skills, ChangeBattlefield.battlefields)) {
    var %battlefields = $readini(%file_path, skills, ChangeBattlefield.battlefields)
    var %total_battlefields = $numtok(%battlefields,46)
    var %battlefield = 1
    while (%battlefield <= %total_battlefields) {
      var %battlefield_name = $gettok(%battlefields, %battlefield, 46)
      if (!$ini($dbfile(battlefields.db), %battlefield_name)) /log_issue Moderate %category $+  $1 $+ 's ChangeBattlefield.battlefields field includes undefined battlefield %battlefield_name $+ .
      inc %battlefield
    }
  }
  else if ($readini(%file_path, n, Skills, ChangeBattlefield) != $null) /log_issue Moderate %category $+  $1 has the Change Battlefield skill, but no ChangeBattlefield.battlefields list.
  if ($readini(%file_path, n, Skills, RepairNaturalArmor) != $null) {
    if (!$ini(%file_path, NaturalArmor)) /log_issue Moderate %category $+  $1 has the Repair Natural Armor skill, but no natural armor.
  }

  ; Check the techniques.
  var %i = 0
  var %count = $ini(%file_path, Techniques, 0)
  while (%i < %count) {
    inc %i
    var %technique = $ini(%file_path, Techniques, %i)
    if (;* iswm %technique) continue
    if (!$ini($dbfile(techniques.db), %technique)) /log_issue Minor %category $+  $1 has missing technique %technique $+ .
    if (!$validate_expression($readini(%file_path, n, Techniques, %technique))) continue
    if ($readini(%file_path, Techniques, %technique) !isnum) /log_issue Minor %category $+  $1 $+ 's technique level for %technique is not a number; it won't use the technique.
  }

  ; Check the modifiers.
  var %absorb = $readini(%file_path, Modifiers, Heal)
  if ((%absorb != $null) && (%absorb != none)) {
    var %i = 0
    var %count = $numtok(%absorb, 46)
    while (%i < %count) {
      inc %i
      var %modifier = $gettok(%absorb, %i, 46)
      if ((. isin %modifier) || (%modifier !isin fire.ice.earth.wind.lightning.water.light.dark)) var %bad_absorbs $addtok(%bad_absorbs, %modifier, 46)
    }
  }
  var %weakness = $readini(%file_path, Weapons, Weakness)
  if ((%weakness != $null) && (%weakness != none)) {
    var %i = 0
    var %count = $numtok(%weakness, 46)
    while (%i < %count) {
      inc %i
      var %modifier = $gettok(%weakness, %i, 46)
      if (. isin %modifier) noop
      else if (%modifier isin fire.ice.earth.wind.lightning.water.light.dark.HandToHand.Whip.Sword.Gun.Rifle.Katana.Wand.Stave.Spear.Scythe.Glyph.Greatsword.Bow.Axe.Dagger) continue
      else if ($ini($dbfile(weapons.db), %modifier)) continue
      else if ($ini($dbfile(techniques.db), %modifier)) continue
      else if ($ini($dbfile(items.db), %modifier)) continue
      var %bad_weaknesses = $addtok(%bad_weaknesses, %modifier, 46)
    }
  }
  var %strong = $readini(%file_path, Weapons, Strong)
  if ((%strong != $null) && (%strong != none)) {
    var %i = 0
    var %count = $numtok(%strong, 46)
    while (%i < %count) {
      inc %i
      var %modifier = $gettok(%strong, %i, 46)
      if (. isin %modifier) noop
      else if (%modifier isin fire.ice.earth.wind.lightning.water.light.dark.HandToHand.Whip.Sword.Gun.Rifle.Katana.Wand.Stave.Spear.Scythe.Glyph.Greatsword.Bow.Axe.Dagger) continue
      else if ($ini($dbfile(weapons.db), %modifier)) continue
      else if ($ini($dbfile(techniques.db), %modifier)) continue
      else if ($ini($dbfile(items.db), %modifier)) continue
      var %bad_strengths = $addtok(%bad_strengths, %modifier, 46)
    }
  }
  if (%bad_absorbs) /log_issue Minor %category $+  $1 $+ 's absorb list includes unrecognised element(s) $replace(%bad_absorbs, ., $chr(44) $+ $chr(32)) $+ . (Only elements can be used here.)
  if (%bad_weaknesses) /log_issue Minor %category $+  $1 $+ 's weakness list includes unrecognised modifier(s) $replace(%bad_weaknesses, ., $chr(44) $+ $chr(32)) $+ .
  if (%bad_strengths) /log_issue Minor %category $+  $1 $+ 's strength list includes unrecognised modifier(s) $replace(%bad_strengths, ., $chr(44) $+ $chr(32)) $+ .
  unset %bad_*

  var %i = 0
  var %count = $ini(%file_path, Modifiers, 0)
  while (%i < %count) {
    inc %i
    var %modifier = $ini(%file_path, Modifiers, %i)
    if (;* iswm %modifier) continue
    if (%modifier = Heal) continue

    if ($validate_expression($readini(%file_path, n, Modifiers, %modifier))) {
      var %modifier_value = $readini(%file_path, Modifiers, %modifier)
      if (%modifier_value !isnum) /log_issue Minor %category $+  $1 $+ 's %modifier modifier value is not a number; these attacks will have no effect.
      else if (%modifier_value < 0) /log_issue Minor %category $+  $1 $+ 's %modifier modifier value is less than 0; these attacks will have no effect.
    }

    if (. !isin %modifier && %modifier isin fire.ice.earth.wind.lightning.water.light.dark.HandToHand.Whip.Sword.Gun.Rifle.Katana.Wand.Stave.Spear.Scythe.Glyph.Greatsword.Bow.Axe.Dagger) continue
    if ($ini($dbfile(techniques.db), %modifier)) continue
    if ($ini($dbfile(weapons.db), %modifier)) continue
    if ($ini($dbfile(items.db), %modifier)) continue
    /log_issue Minor %category $+  $1 references unrecognised modifier %modifier $+ . Use an element, weapon type or technique name.
  }  
}
monster_get_hp {
  ; Retrieves a monster's HP.
  ;   $1 : The monster's name.
  ;   $2 : $null
  ;   $3 : 1
  ; Output to %hp : The monster's base HP.

  ; Check the BattleStats flag.
  if ($readini(%file_path, info, BattleStats) = ignoreHP) return
  ; Further checking will be done in $monster_get_attributes
  set %hp $readini(%file_path, BaseStats, HP)
  if (!$validate_expression($readini(%file_path, n, BaseStats, HP))) set %hp 0
}
monster_get_attributes {
  ; Retrieves a monster's attributes (STR, DEF, INT, SPD).
  ;   $1 : The monster's name.
  ;   $2 : 1
  ;   $3 : $null
  ; Output to %str, %def, %int, %spd : The attributes.

  ; Check the BattleStats flag.
  if ($readini(%file_path, info, BattleStats) = ignore) return
  if ($readini(%file_path, info, BattleStats) != $null && $readini(%file_path, info, BattleStats) != ignoreHP) /log_issue Moderate %category $+  $1 $+ 's Info-BattleStats field is specified, but not as 'ignore'; the monster will be boosted as normal.

  ; We ignore the check if the value contains $char
  set %str $readini(%file_path, BaseStats, Str)
  if (!$validate_expression($readini(%file_path, n, BaseStats, Str))) set %str 0
  set %def $readini(%file_path, BaseStats, Def)
  if (!$validate_expression($readini(%file_path, n, BaseStats, Def))) set %def 0
  set %int $readini(%file_path, BaseStats, Int)
  if (!$validate_expression($readini(%file_path, n, BaseStats, Int))) set %int 0
  set %spd $readini(%file_path, BaseStats, Spd)
  if (!$validate_expression($readini(%file_path, n, BaseStats, Spd))) set %spd 0
}
validate_expression {
  ; Checks whether an expression can be checked. If the expression contains the $char function
  ;   or references any battle txt files, it will not be checked fully.
  ;   $1-: The expression to check.

  if ($!char isin $1-) return $false
  if (battle isin $1-) return $false
  return $true
}

check_weapons {
  ; Check the weapon lists and make sure there's nothing missing.
  var %i = 0
  var %lcount = $ini(weapons.db, weapons, 0)
  while (%i < %lcount) {
    inc %i
    var %list = $ini(weapons.db, weapons, %i)
    var %j = 0
    var %count = $numtok($readini(weapons.db, weapons, %list),46)
    while (%j < %count) {
      inc %j
      var %weapon = $gettok($readini(weapons.db, weapons, %list), %j, 46)
      if (!$ini(weapons.db, $weapon)) var %missing_weapons $addtok(%missing_weapons, %weapon, 46)
    }
    if (%missing_weapons) log_issue Moderate Weapon list %list references missing weapon(s) %missing_weapons $+ .
    unset %missing_weapons
  }
}

log_issue {
  ; Records an issue message to the window @issues.
  ;   $1 : The severity of the issue: 'Minor', 'Moderate', 'Major' or 'Critical'.
  ;        'Minor': Something might be missing, but it shouldn't have any significant consequences.
  ;        'Moderate': Something that will impact players, or that can be exploited.
  ;        'Major': Something that could potentially have serious side effects, or create a security hole.
  ;        'Critical': Something that could hang, freeze or crash the bot, or worse. I don't know of anything that gets this, since the issue where StatusTypes could hang the bot was fixed.
  ;   $2-: A user-friendly description of the problem.

  inc %issues_total
  if ($1 = minor   ) { aline -p 8 @issues [Minor]    $2- }
  if ($1 = moderate) { aline -p 7 @issues [Moderate] $2- }
  if ($1 = major   ) { aline -p 4 @issues [Major]    $2- | inc %issues_major }
  if ($1 = critical) { aline -p 5 @issues [Critical] $2- | inc %issues_major }
}
