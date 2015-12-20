;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; ATTACKS COMMAND
;;;; Last updated: 10/25/15
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ON 3:ACTION:attacks *:#:{ 
  $no.turn.check($nick)
  $set_chr_name($nick) 
  $partial.name.match($nick, $2)
  covercheck %attack.target
  $attack_cmd($nick , %attack.target) 
} 
on 3:TEXT:!attack *:#:{ 
  $no.turn.check($nick)
  $set_chr_name($nick)
  $partial.name.match($nick, $2)
  covercheck %attack.target
  $attack_cmd($nick , %attack.target) 
} 

ON 50:TEXT:*attacks *:*:{ 
  if ($2 != attacks) { halt } 
  else { 
    $no.turn.check($1,admin)
    if ($readini($char($1), Battle, HP) = $null) { halt }
    $set_chr_name($1) 
    $partial.name.match($1, $3)
    covercheck %attack.target
    $attack_cmd($1 , %attack.target) 
  }
}

ON 3:TEXT:*attacks *:*:{ 
  if ($2 != attacks) { halt } 
  if ($readini($char($1), info, flag) = monster) { halt }
  if ($readini($char($1), stuff, redorbs) = $null) { halt }
  $controlcommand.check($nick, $1)
  if ($return.systemsetting(AllowPlayerAccessCmds) = false) { $display.message($readini(translation.dat, errors, PlayerAccessCmdsOff), private) | halt }
  if ($char.seeninaweek($1) = false) { $display.message($readini(translation.dat, errors, PlayerAccessOffDueToLogin), private) | halt }
  $no.turn.check($1)
  unset %real.name 
  if ($readini($char($1), Battle, HP) = $null) { halt }
  $set_chr_name($1) 
  $partial.name.match($1, $3)
  covercheck %attack.target
  $attack_cmd($1 , %attack.target) 
}

alias attack_cmd { 
  set %debug.location alias attack_cmd
  $check_for_battle($1) | $person_in_battle($2) | $checkchar($2) | var %user.flag $readini($char($1), info, flag) | var %target.flag $readini($char($2), info, flag)
  var %ai.type $readini($char($1), info, ai_type)

  if ((%ai.type != berserker) && (%covering.someone != on)) {
    if (%mode.pvp != on) {
      if ($2 = $1) {
        if (($is_confused($1) = false) && ($is_charmed($1) = false))  { $display.message($readini(translation.dat, errors, Can'tAttackYourself), private) | unset %real.name | halt  }
      }
    }
  }

  if ($is_charmed($1) = true) { var %user.flag monster }
  if ($is_confused($1) = true) { var %user.flag monster } 
  if (%tech.type = heal) { var %user.flag monster }
  if (%tech.type = heal-aoe) { var %user.flag monster }
  if (%mode.pvp = on) { var %user.flag monster }
  if (%ai.type = berserker) { var %user.flag monster }
  if (%covering.someone = on) { var %user.flag monster }

  if ((%user.flag != monster) && (%target.flag != monster)) { $set_chr_name($1) | $display.message($readini(translation.dat, errors, CanOnlyAttackMonsters),private)  | halt }
  if ($readini($char($1), Battle, Status) = dead) { $set_chr_name($1) | $display.message($readini(translation.dat, errors, CanNotAttackWhileUnconcious),private)  | unset %real.name | halt }
  if ($readini($char($2), Battle, Status) = dead) { $set_chr_name($1) | $display.message($readini(translation.dat, errors, CanNotAttackSomeoneWhoIsDead),private) | unset %real.name | halt }
  if ($readini($char($2), Battle, Status) = RunAway) { $set_chr_name($1) | $display.message($readini(translation.dat, errors, CanNotAttackSomeoneWhoFled),private) | unset %real.name | halt } 

  ; Make sure the old attack damages have been cleared, and clear a few variables.
  unset %attack.damage |  unset %attack.damage1 | unset %attack.damage2 | unset %attack.damage3 | unset %attack.damage4 | unset %attack.damage5 | unset %attack.damage6 | unset %attack.damage7 | unset %attack.damage8 | unset %attack.damage.total
  unset %drainsamba.on | unset %absorb |  unset %element.desc | unset %spell.element | unset %real.name  |  unset %target.flag | unset %trickster.dodged | unset %covering.someone
  unset %techincrease.check |  unset %double.attack | unset %triple.attack | unset %fourhit.attack | unset %fivehit.attack | unset %sixhit.attack | unset %sevenhit.attack | unset %eighthit.attack
  unset %multihit.message.on | unset %critical.hit.chance | unset %drainsamba.on | unset %absorb | unset %counterattack
  unset %shield.block.line | unset %inflict.meleewpn

  ; Get the weapon equipped
  if ($person_in_mech($1) = false) {  $weapon_equipped($1) }
  if ($person_in_mech($1) = true) { set %weapon.equipped $readini($char($1), mech, equippedweapon) }

  ; If it's an AOE attack, perform that here.  Else, do a single hit.

  if ($readini($dbfile(weapons.db), %weapon.equipped, target) != aoe) {

    ; Calculate, deal, and display the damage..
    var %power = $attack_power_standard($1, %weapon.equipped, $2)
    set %attack.target $2

    if ($person_in_mech($1) = true) { $mech.energydrain($1, melee) }

    set %wpn.element $readini($dbfile(weapons.db), %weapon.equipped, element)
    if ((%wpn.element != none) && (%wpn.element != $null)) { 
      var %target.element.heal $readini($char($2), modifiers, heal)
      if ($istok(%target.element.heal,%wpn.element,46) = $true) { 
        unset %wpn.element
        unset %counterattack
        $heal_damage($1, $2, %weapon.equipped)
        $display_heal($1, $2, weapon, %weapon.equipped)
        if (%battleis = on)  { $check_for_double_turn($1) | halt } 
      }
    }

    var %intercepted = $covercheck($2, %weapon.equipped)

    if ((%intercepted) && (%wpn.element != none)) {
      ; The attack was intercepted; check again for elemental absorbs on the new target.
      var %absorbs = $readini($char(%who.battle), modifiers, heal)
      if ((%absorbs != none) && (%absorbs != $null)) {
        if ($istok(%absorbs, %element, 46) = $true) { 
          unset %wpn.element
          unset %counterattack
          $heal_damage($1, $2, %weapon.equipped)
          $display_heal($1, $2, weapon, %weapon.equipped)
          if (%battleis = on)  { $check_for_double_turn($1) | halt } 
        }
      }
    }

    unset %wpn.element

    if ((%counterattack != on) && (%counterattack != shield)) { 
      $drain_samba_check($1)

      ; Determine the number of strikes.
      set %strikes $readini($dbfile(weapons.db), %weapon.equipped, hits)
      if (%strikes == $null) %strikes = 1

      if ($augment.check($1, AdditionalHit) = true) { inc %strikes %augment.strength }

      ; Are we dual-wielding?  If so, increase the hits by the # of hits of the second weapon.
      if ($readini($char($1), weapons, equippedLeft) != $null) {
        var %left.hits $readini($dbfile(weapons.db), $readini($char($1), weapons, equippedLeft), hits)
        if (%left.hits = $null) { var %left.hits 1 }
        inc %strikes %left.hits
      }

      ; Now strike the opponent.
      var %strike = 1
      while (%strike <= %strikes) {
        strike_standard $1 %weapon.equipped %attack.target %power %strikes %strike
        inc %strike
      }
      multi_strike_check %strikes

      ; Turn off the True Strike skill
      writeini $char($1) skills truestrike.on off

      $deal_damage($1, %attack.target, %weapon.equipped)
      $display_damage($1, %attack.target, weapon, %weapon.equipped)
    }

    if (%counterattack = on) { 
      $deal_damage(%attack.target, $1, %weapon.equipped)
      $display_damage($1, %attack.target, weapon, %weapon.equipped)
    }

    if (%counterattack = shield) { 
      $deal_damage(%attack.target, $1, $readini($char(%attack.target), weapons, equippedLeft))
      $display_damage($1, %attack.target, weapon, $readini($char(%attack.target), weapons, equippedLeft))
    }
  }

  if ($readini($dbfile(weapons.db), %weapon.equipped, target) = aoe) {
    ; Show the description.
    $set_chr_name($1) | set %user %real.name
    if ($person_in_mech($1) = true) { set %user %real.name $+ 's $readini($char($1), mech, name) } 
    var %enemy all targets
    var %weapon.type $readini($dbfile(weapons.db), %weapon.equipped, type) |  var %attack.file $txtfile(attack_ $+ %weapon.type $+ .txt) 

    $display.message(3 $+ %user $+  $read(%attack.file) $+ 3., battle)
    set %showed.melee.desc true

    var %power = $attack_power_standard($1, %weapon.equipped, $2)
    strike_standard_aoe $1 %weapon.equipped $2 %power
  }

  unset %attack.damage |  unset %attack.damage1 | unset %attack.damage2 | unset %attack.damage3 | unset %attack.damage4 | unset %attack.damage5 | unset %attack.damage6 | unset %attack.damage7 | unset %attack.damage8 | unset %attack.damage.total
  unset %drainsamba.on | unset %absorb |  unset %element.desc | unset %spell.element | unset %real.name  |  unset %user.flag | unset %target.flag | unset %trickster.dodged | unset %covering.someone
  unset %techincrease.check |  unset %double.attack | unset %triple.attack | unset %fourhit.attack | unset %fivehit.attack | unset %sixhit.attack | unset %sevenhit.attack | unset %eighthit.attack
  unset %multihit.message.on | unset %critical.hit.chance

  $formless_strike_check($1)

  ; Time to go to the next turn
  if (%battleis = on)  { $check_for_double_turn($1) | halt }
}

; MOD: Alternate damage mechanics
alias attack_power_standard {
  ; $1 = attacker
  ; $2 = weapon equipped
  ; $3 = target
  ; $4 = a special flag for mugger's belt.

  var %weapon_power

  ; Set a defalut modifier to nerf multi-hit attacks.
  if (%modifiers == $null) {
    set %tech_hits $readini($dbfile(weapons.db), $2, Hits)
    ; Multipliers: 1.00 1.50 1.80 2.00 2.20 2.34 2.45 2.56
    if      (%tech_hits == 2) var %modifiers = 0.75
    else if (%tech_hits == 3) var %modifiers = 0.60
    else if (%tech_hits == 4) var %modifiers = 0.50
    else if (%tech_hits == 5) var %modifiers = 0.44
    else if (%tech_hits == 6) var %modifiers = 0.39
    else if (%tech_hits == 7) var %modifiers = 0.35
    else if (%tech_hits >= 8) var %modifiers = 0.32
    else var %modifiers = 1
  }

  if ($4 == mugger's-belt) { %weapon_power = 5 | %modifiers = 0.5 }
  else %weapon_power = $calc($readini($dbfile(weapons.db), $2, basepower) + $readini($char($1), weapons, $2))

  var %strength = $readini($char($1), battle, str)
  strength_down_check $1

  ; If the weapon is a hand-to-hand weapon, it will now receive a bonus based on your fists level.
  if ($readini($dbfile(weapons.db), $2, Type) == HandToHand) inc %weapon_power $calc($readini($char($1), weapons, Fists) / 2)

  ; Add mastery bonuses.
  mastery_check $1 $2
  inc %weapon_power %mastery.bonus

  if ($person_in_mech($1) == false) { 
    ; Let's check for some offensive style enhancements.
    offensive.style.check $1 $2 melee

    ; And Mighty Strike.
    if ($mighty_strike_check($1) = true) %modifiers = $calc(%modifiers * 2)

    ; And Desperate Blows.
    if ($desperate_blows_check($1) = true) {
      var %health_ratio = $calc(($readini($char($1), Battle, HP) / $readini($char($1), BaseStats, HP)))
      if      ((%health_ratio <= 0.02)) %modifiers = $calc(%modifiers * 2.5)
      else if ((%health_ratio <= 0.10)) %modifiers = $calc(%modifiers * 2.0)
      else if ((%health_ratio <= 0.25)) %modifiers = $calc(%modifiers * 1.5)
    }
  }

  ; Check to see if we have an accessory or augment that enhances the weapon type
  melee.weapontype.enhancements $1
  unset %weapon.type

  ; Check for Killer Traits
  killer.trait.check $1 $3

  unset %current.playerstyle | unset %current.playerstyle.level

  if ($person_in_mech($1) = false) { 
    ; Check for the miser ring accessory
    if ($accessory.check($1, IncreaseMeleeDamage) = true) {
      var %redorb.amount $readini($char($1), stuff, redorbs)
      var %miser-ring.increase $round($calc(%redorb.amount * %accessory.amount),0)

      if (%miser-ring.increase <= 0) { var %miser-ring.increase 1 }
      if (%miser-ring.increase > 1000) { var %miser-ring.increase 1000 }
      inc %strength %miser-ring.increase
      unset %accessory.amount
    }

    ; Check for the fool's tablet accessory
    if ($accessory.check($1, IncreaseMeleeAddPoison) = true) {
      inc %modifiers $calc(%modifiers * %accessory.amount)
      unset %accessory.amount
    }
  }
  unset %current.accessory.type

  ; Add the Melee Bonus augment modifier.
  if ($augment.check($1, MeleeBonus) = true) { 
    inc %modifiers $calc(%modifiers * %augment.strength * 0.25)
    unset %melee.bonus.augment
  }

  ; Check for a battle condition modifier
  if (enhance-melee isin %battleconditions) %modifiers = $calc(%modifiers * 0.1)

  ; Calculate the total power.
  set %attack_power $calc((%strength + %weapon_power) * 2 * %modifiers)
  set %attack.damage %attack_power

  ; Adjust the total damage.
  cap.damage $1 $3 melee

  ; If a player is using a monster weapon, which is considered cheating, set the damage to 0.
  if (($readini($dbfile(weapons.db), $2, cost) = 0) && ($readini($dbfile(weapons.db), $2, SpecialWeapon) != true)) {
    if ($readini($char($1), info, flag) == $null) set %attack.damage 0
  }

  ; Calculate the to-hit chance.
  set %hit $readini($dbfile(weapons.db), $2, Hit)
  if (%hit == $null) {
    if ($readini($char($1), info, flag) == monster) %hit = 95
    else %hit = 100
  }

  if ($accessory.check($1, CurseAddDrain) = true) { unset %accessory.amount | set %absorb 0.25 }
  if ($augment.check($1, Drain) = true) {  set %absorb 0.25 }

  unset %current.accessory | unset %current.accessory.type 

  ; Show the attack power.
  ; If the power was capped, it will be shown in magenta.
  if (%attack_power == %attack.damage) debugshow 1 4Strength:12 %strength 4 Weapon power:12 %weapon_power 4 Modifiers:12 %modifiers 4 Attack power:12 %attack.damage 4 Hit rate:12 %hit $iif(%absorb, 4 Life steal:12 %absorb)
  else                                 debugshow 1 4Strength:12 %strength 4 Weapon power:12 %weapon_power 4 Modifiers:12 %modifiers 4 Attack power:13 %attack.damage 4 Hit rate:12 %hit $iif(%absorb, 4 Life steal:12 %absorb)

  return %attack.damage
}

alias strike_standard {
  ; $1 = attacker
  ; $2 = weapon equipped
  ; $3 = target
  ; $4 = attack power
  ; $5 = number of hits
  ; $6 = hit number

  var %modifiers = 1

  ; Does the attack hit?
  unset %guard.message
  hit_check $1 basic $3
  if (%guard.message == $null) melee.ethereal.check $1 $2 $3
  if (%guard.message == $null) invincible.check $1 $2 $3
  if (%guard.message == $null) trickster_dodge_check $3 $1 physical
  if (%guard.message == $null) weapon_parry_check $3 $1 $2
  if (%guard.message == $null) royalguard.check $1 $2 $3
  if (%guard.message == $null) perfectdefense.check $1 $2 $3
  if (%guard.message == $null) utsusemi.check $1 $2 $3

  if (%guard.message == $null) {
    ; Zombies gain weakness to light and fire.
    set -u0 %element $readini($dbfile(weapons.db), $2, element)
    if (($readini($char($3), status, zombie) == yes) && ((%element == light) || (%element == fire))) %modifiers = 1.15

    ; Check for character modifiers.
    if ((%element != $null) && (%element != none)) {
      set %element_modifier $modifier_adjust($3, %element)
      if (%element_modifier <= 0) { $set_chr_name($3)
        set %guard.message $readini(translation.dat, battle, ImmuneToElement) 
        %modifiers = 0
      }
      else %modifiers = $calc(%modifiers * %element_modifier)
    }

    set -u0 %weapon_type $readini($dbfile(weapons.db), $2, type)
    if (%weapon_type != $null) {
      set %weapon_modifier $modifier_adjust($3, %element)
      if (%weapon_modifier <= 0) { $set_chr_name($3)
        set %guard.message $readini(translation.dat, battle, ImmuneToWeaponType) 
        %modifiers = 0
      }
      else %modifiers = $calc(%modifiers * %weapon_modifier)
    }

    ; Elementals are resistant to standard attacks.
    if ($readini($char($3), monster, type) = elemental) %modifiers = $calc(%modifiers * 0.7)

    ; Now we're ready to calculate the enemy's defense.
    set %defense $readini($char($3), Battle, DEF)
    defense_down_check $3
    defense_up_check $3

    ; Check to see if the weapon has an IgnoreDefense flag. If so, cut the defense down.
    var %piercing $calc($readini($dbfile(weapons.db), $2, IgnoreDefense) / 100)
    if ($augment.check($1, IgnoreDefense) = true) inc %piercing $calc(%augment.strength * 0.05)
    if (%piercing > 1) %defense = 0
    else if (%piercing > 0) %defense = $calc(%defense * (1 - %piercing))

    ; Check for a critical hit.
    var %roll = $rand(1,100), %chance = 4

    ; check for the Impetus Passive Skill
    var %impetus.level = $readini($char($1), skills, Impetus)
    if (%impetus.level) inc %chance %impetus.level

    ; If the user is using a h2h weapon, increase the critical hit chance by 1.
    if ($readini($dbfile(weapons.db), $2, type) = HandToHand) { inc %chance 1 }

    if ($accessory.check($1, IncreaseCriticalHits) = true) {
      if (%accessory.amount = 0) { var %accessory.amount 1 }
      inc %chance %accessory.amount
      unset %accessory.amount
    }


    unset %player.accessory | unset %accessory.type | unset %accessory.amount

    if ($augment.check($1, EnhanceCriticalHits) = true) { inc %chance %augment.strength }

    if      (%modifiers < 1) set %damage.display.color 6
    else if (%modifiers > 1) set %damage.display.color 7
    else                     set %damage.display.color 4

    if (%roll <= %chance) {
      $set_chr_name($1) |  $display.message($readini(translation.dat, battle, LandsACriticalHit), battle)
      %modifiers = $calc(%modifiers * 1.5)
      %defense = 0
    }

    ; Calculate the total damage.
    set %attack.damage $calc(($4 - %defense) * %modifiers * ($rand(90, 110) / 100))
    debugshow 1 4Hit:12 $6 4of12 $5 4 Power:12 $4 4 Defense:12 %defense 4 Modifiers:12 %modifiers

    ; Adjust the damage based on weapon size vs monster size
    $monstersize.adjust($3,$2)


    ; Check for the Guardian style
    guardian_style_check $3

    ; Check for metal defense.  If found, set the damage to 1.
    metal_defense_check $3 $1

    ; Check for a shield block.
    shield_block_check $3 $1 $2

    ; If the target has Protect on, it will cut  melee damage in half.
    if ($readini($char($3), status, protect) = yes) { %attack.damage = $round($calc(%attack.damage / 2),0) }

    ; Check for the En-Spell Buff
    if ($readini($char($1), status, en-spell) != none) { 
      $magic.effect.check($1, $3, nothing, en-spell) 
      modifier_adjust $3 $readini($char($1), status, en-spell)
    }

    if ($person_in_mech($1) = false) { writeini $char($1) skills mightystrike.on off }

    $first_round_dmg_chk($1, $3)

    ; In this bot we don't want the attack to ever be lower than 1 except for rare instances...  
    if ((%guard.message == $null) && (%attack.damage <= 0)) %attack.damage = 1

    if ($5 == 1) {
      ; check for melee counter
      counter_melee $1 $3 $2

      ; Check for countering an attack using a shield
      shield_reflect_melee $1 $3 $2

      ; Check for the weapon bash skill
      weapon_bash_check $1 $3
    }

    guardianmon.check $1 $2 $3

    set -u0 %attack_effect did $+ %damage.display.color $+  $bytes(%attack.damage, b) damage 
  }
  else set %attack.damage 0

  if ($5 > 1) {
    set     %attack.damage [ $+ [ $6 ] ] %attack.damage
    set -u0 %attack_effect [ $+ [ $6 ] ] %attack_effect
  }

  if (%guard.message == $null) {
    unset %statusmessage.display
    set %status.type.list $readini($dbfile(weapons.db), $2, StatusType)

    if (%status.type.list != $null) { 
      set %number.of.statuseffects $numtok(%status.type.list, 46) 

      if (%number.of.statuseffects = 1) { $inflict_status($1, $3, %status.type.list) | unset %number.of.statuseffects | unset %status.type.list }
      if (%number.of.statuseffects > 1) {
        var %status.value 1
        while (%status.value <= %number.of.statuseffects) { 
          set %current.status.effect $gettok(%status.type.list, %status.value, 46)
          $inflict_status($1, $3, %current.status.effect)
        }

        unset %number.of.statuseffects | unset %current.status.effect
      }
    }
    unset %status.type.list
  }
}


alias strike_standard_aoe {
  ; $1 = user
  ; $2 = weapon equipped
  ; $3 = target
  ; $4 = attack power

  var %user_flag = $readini($char($1), info, flag)
  var %targetcount = 0
  ; While confused, the targets will be random.
  if ($is_confused($1) == true) {
    if ($rand(0, 1) == 0) var %targets = allies
    else var %targets = monsters
  } 
  ; While charmed, healing will target monsters, and attacks will target allies.
  else if ($is_charmed($1) == true) {
    if (%user_flag == monster) var %targets = monsters
    else var %targets = allies
  }
  ; While neither, target whatever side the specified character is on.
  else if ($readini($char($3), info, flag) == monster) var %targets = monsters
  else var %targets = allies

  ; Determine the number of strikes. 
  set -u0 %strikes $readini($dbfile(weapons.db), $2, hits)
  if (%strikes == $null) %strikes = 1
  set -u0 %element $readini($dbfile(weapons.db), $2, element)

  var %lines $lines($txtfile(battle.txt)) | var %i 1 | set %aoe.turn 1
  while (%i <= %lines) { 
    set %who.battle $read -l $+ %i $txtfile(battle.txt)
    var %flag = $readini($char(%who.battle), info, flag)
    var %istarget = $false

    var %current.status $readini($char(%who.battle), battle, status)
    if (%current.status == alive) {
      if (%targets == monsters) {
        if (%flag == monster) %istarget = $true
      }
      else {
        if (%flag != monster) %istarget = $true
      }
    }

    if (%istarget) {
      inc %targetcount

      ; Check for elemental absorbs.
      var %absorbs $readini($char(%who.battle), modifiers, heal)
      if ((%absorbs != none) && (%absorbs != $null)) {
        if ($istok(%absorbs, %element, 46) = $true) { 
          $heal_damage($1, %who.battle, %weapon.equipped)
          $display_heal($1, %who.battle, AoE, %weapon.equipped)
          inc %i 1 
          continue
        }
      }

      var %intercepted = $covercheck(%who.battle, $2, AOE)

      if (%intercepted) {
        ; The attack was intercepted; check again for elemental absorbs on the new target.
        var %absorbs $readini($char(%who.battle), modifiers, heal)
        if ((%absorbs != none) && (%absorbs != $null)) {
          if ($istok(%absorbs, %element, 46) = $true) { 
            $heal_damage($1, %who.battle, %weapon.equipped)
            $display_heal($1, %who.battle, AoE, %weapon.equipped)
            inc %i 1 
            continue
          }
        }
      }

      ; Now we can finally process the effect.
      var %strike = 1
      while (%strike <= %strikes) {
        strike_standard $1 $2 %who.battle $4 %strikes %strike
        inc %strike
      }
      multi_strike_check %strikes
      $deal_damage($1, %who.battle, $2, %absorb)
      $display_aoedamage($1, %who.battle, $2, %absorb)        
    }

    ; Make sure that the attacker is still alive before continuing.
    if ($readini($char($1), Battle, HP) <= 0) break
    inc %i
  }
  return %targetcount
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Calculates Melee Damage
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
alias calculate_damage_weapon {
  set %debug.location alias calculate_damage_weapon
  ; $1 = %user
  ; $2 = weapon equipped
  ; $3 = target / %enemy 
  ; $4 = a special flag for mugger's belt.

  if ($readini($char($1), info, flag) = monster) { $formula.meleedmg.monster($1, $2, $3, $4) }
  else { 

    if (%battle.type = dungeon) { $formula.meleedmg.player.formula_3.0($1, $2, $3, $4) }
    if (%battle.type = torment) { $formula.meleedmg.player.formula_2.5($1, $2, $3, $4)  }

    if ((%battle.type != dungeon) && (%battle.type != torment)) { 
      if (($readini(system.dat, system, BattleDamageFormula) = 1) || ($readini(system.dat, system, BattleDamageFormula) = $null)) { $formula.meleedmg.player.formula_3.0($1, $2, $3, $4) }
      if ($readini(system.dat, system, BattleDamageFormula) = 2) { $formula.meleedmg.player.formula_2.5($1, $2, $3, $4) }
      if ($readini(system.dat, system, BattleDamageFormula) = 3) { $formula.meleedmg.player.formula_2.0($1, $2, $3, $4) }
      if ($readini(system.dat, system, BattleDamageFormula) = 4) { $formula.meleedmg.player.formula_1.0($1, $2, $3, $4) }
    }
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Performs a melee AOE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
alias melee.aoe {
  ; $1 = user
  ; $2 = weapon name
  ; $3 = target
  ; $4 = type, either player or monster 

  set %wait.your.turn on

  unset %who.battle | set %number.of.hits 0
  unset %absorb  | unset %element.desc

  ; Display the weapon type description
  $set_chr_name($1) | set %user %real.name
  if ($person_in_mech($1) = true) { set %user %real.name $+ 's $readini($char($1), mech, name) } 

  var %enemy all targets

  var %weapon.type $readini($dbfile(weapons.db), $2, type) |  var %attack.file $txtfile(attack_ $+ %weapon.type $+ .txt) 

  $display.message(3 $+ %user $+  $read %attack.file  $+ 3., battle)
  set %showed.melee.desc true

  if ($readini($dbfile(weapons.db), $2, absorb) = yes) { set %absorb absorb }

  var %melee.element $readini($dbfile(weapons.db), $2, element)

  ; If it's player, search out remaining players that are alive and deal damage and display damage
  if ($4 = player) {
    var %battletxt.lines $lines($txtfile(battle.txt)) | var %battletxt.current.line 1 
    while (%battletxt.current.line <= %battletxt.lines) { 
      set %who.battle $read -l $+ %battletxt.current.line $txtfile(battle.txt)
      if ($readini($char(%who.battle), info, flag) = monster) { inc %battletxt.current.line }
      else { 

        if (($readini($char($1), status, confuse) != yes) && ($1 = %who.battle)) { inc %battletxt.current.line 1 }

        var %current.status $readini($char(%who.battle), battle, status)
        if ((%current.status = dead) || (%current.status = runaway)) { inc %battletxt.current.line 1 }
        else { 

          if ($readini($char($1), battle, hp) > 0) {
            inc %number.of.hits 1
            var %target.element.heal $readini($char(%who.battle), modifiers, heal)
            if ((%melee.element != none) && (%melee.element != $null)) {
              if ($istok(%target.element.heal,%melee.element,46) = $true) { 
                $heal_damage($1, %who.battle, %weapon.equipped)
                inc %battletxt.current.line 1 
              }
            }

            if (($istok(%target.element.heal,%melee.element,46) = $false) || (%melee.element = none)) { 

              covercheck %who.battle $2 AOE

              $calculate_damage_weapon($1, %weapon.equipped, %who.battle)
              $deal_damage($1, %who.battle, %weapon.equipped, melee)

              $display_aoedamage($1, %who.battle, $2, %absorb, melee)
              unset %attack.damage

            }
          }

          unset %attack.damage |  unset %attack.damage1 | unset %attack.damage2 | unset %attack.damage3 | unset %attack.damage4 | unset %attack.damage5 | unset %attack.damage6 | unset %attack.damage7 | unset %attack.damage8 | unset %attack.damage.total
          unset %drainsamba.on | unset %absorb |  unset %element.desc | unset %spell.element | unset %real.name  |  unset %user.flag | unset %target.flag | unset %trickster.dodged | unset %covering.someone
          unset %techincrease.check |  unset %double.attack | unset %triple.attack | unset %fourhit.attack | unset %fivehit.attack | unset %sixhit.attack | unset %sevenhit.attack | unset %eighthit.attack
          unset %multihit.message.on | unset %critical.hit.chance

          inc %battletxt.current.line 1 | inc %aoe.turn 1
        } 
      }
    }
  }


  ; If it's monster, search out remaining monsters that are alive and deal damage and display damage.
  if ($4 = monster) { 
    var %battletxt.lines $lines($txtfile(battle.txt)) | var %battletxt.current.line 1 | set %aoe.turn 1
    while (%battletxt.current.line <= %battletxt.lines) { 
      set %who.battle $read -l $+ %battletxt.current.line $txtfile(battle.txt)
      if ($readini($char(%who.battle), info, flag) != monster) { inc %battletxt.current.line }
      else { 
        inc %number.of.hits 1
        var %current.status $readini($char(%who.battle), battle, status)
        if ((%current.status = dead) || (%current.status = runaway)) { inc %battletxt.current.line 1 }
        else { 
          if ($readini($char($1), battle, hp) > 0) {

            var %target.element.heal $readini($char(%who.battle), modifiers, heal)
            if ((%melee.element != none) && (%melee.element != $null)) {
              if ($istok(%target.element.heal,%melee.element,46) = $true) { 
                $heal_damage($1, %who.battle, %weapon.equipped)
              }
            }

            if (($istok(%target.element.heal,%melee.element,46) = $false) || (%melee.element = none)) { 
              covercheck %who.battle $2 AOE


              $calculate_damage_weapon($1, %weapon.equipped, %who.battle)
              $deal_damage($1, %who.battle, %weapon.equipped, melee)
              $display_aoedamage($1, %who.battle, $2, %absorb, melee)

            }
          }

          unset %attack.damage |  unset %attack.damage1 | unset %attack.damage2 | unset %attack.damage3 | unset %attack.damage4 | unset %attack.damage5 | unset %attack.damage6 | unset %attack.damage7 | unset %attack.damage8 | unset %attack.damage.total
          unset %drainsamba.on | unset %absorb |  unset %element.desc | unset %spell.element | unset %real.name  |  unset %user.flag | unset %target.flag | unset %trickster.dodged | unset %covering.someone
          unset %techincrease.check |  unset %double.attack | unset %triple.attack | unset %fourhit.attack | unset %fivehit.attack | unset %sixhit.attack | unset %sevenhit.attack | unset %eighthit.attack
          unset %multihit.message.on | unset %critical.hit.chance

          inc %battletxt.current.line 1 | inc %aoe.turn 1 | unset %attack.damage
        } 
      }
    }
  }

  unset %element.desc | unset %showed.melee.desc | unset %aoe.turn
  set %timer.time $calc(%number.of.hits * 1.1) 

  if ($readini($dbfile(weapons.db), $2, magic) = yes) {
    ; Clear elemental seal
    if ($readini($char($1), skills, elementalseal.on) = on) { 
      writeini $char($1) skills elementalseal.on off 
    }
  }

  unset %statusmessage.display
  if ($readini($char($1), battle, hp) > 0) {
    set %inflict.user $1 | set %inflict.meleewpn $2 
    $self.inflict_status(%inflict.user, %inflict.meleewpn, melee)
    if (%statusmessage.display != $null) { $display.message(%statusmessage.display, battle) | unset %statusmessage.display }
  }


  ; Turn off the True Strike skill
  writeini $char($1) skills truestrike.on off

  if (%timer.time > 20) { %timer.time = 20 }

  unset %melee.element | $formless_strike_check($1)

  /.timerCheckForDoubleSleep $+ $rand(a,z) $+ $rand(1,1000) 1 %timer.time /check_for_double_turn $1
  halt
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Skill and Mastery checks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
alias mastery_check {
  var %type.of.weapon $readini($dbfile(weapons.db), $2, type)
  set %mastery.type nonexistant 
  if (%type.of.weapon = handtohand) { set %mastery.type MartialArts }
  if (%type.of.weapon = nunchuku) { set %mastery.type MartialArts }
  if (%type.of.weapon = katana) { set %mastery.type Swordmaster }
  if (%type.of.weapon = sword) { set %mastery.type Swordmaster }
  if (%type.of.weapon = greatsword) { set %mastery.type Swordmaster }
  if (%type.of.weapon = gun) { set %mastery.type Gunslinger }
  if (%type.of.weapon = rifle) { set %mastery.type Gunslinger }
  if (%type.of.weapon = wand) { set %mastery.type Wizardry }
  if (%type.of.weapon = stave) { set %mastery.type Wizardry }
  if (%type.of.weapon = glyph) { set %mastery.type Wizardry }
  if (%type.of.weapon = spear) { set %mastery.type Polemaster }
  if (%type.of.weapon = bow) { set %mastery.type Archery }
  if (%type.of.weapon = axe) { set %mastery.type Hatchetman }
  if (%type.of.weapon = scythe) { set %mastery.type Harvester }
  if (%type.of.weapon = dagger) { set %mastery.type SleightOfHand }
  if (%type.of.weapon = whip) { set %mastery.type Whipster }

  set %mastery.bonus $readini($char($1), skills, %mastery.type) 
  if (%mastery.bonus = $null) { set %mastery.bonus 0 }
  unset %mastery.type
}

alias mighty_strike_check {
  var %mightystrike $readini($char($1), skills, mightystrike.on)
  if (%mightystrike = on) { return true }
  else { return false }
}

alias desperate_blows_check {
  if ($readini($char($1), skills, desperateblows) != $null) { return true }
  else { return false }
}

alias weapon_bash_check {
  if (%counterattack = on) { return }
  if (%attack.damage = 0) { return }

  if ($readini($char($1), skills, WeaponBash) > 0) {

    set %resist.skill $readini($char($2), skills, resist-stun)
    $ribbon.accessory.check($2)
    if (%resist.skill >= 100) { return }
    unset %resist.skill

    if (%guard.message != $null) { return }
    if ($readini($char($2), skills, royalguard.on) = on) { return }
    if ($readini($char($2), skills, perfectdefense.on) = on) { return }
    if ($readini($char($2), skills, utsusemi.on) = on) { return }
    if (%trickster.dodged = on) { return }
    if ($readini($char($2), NaturalArmor, Current) > 0) { return }

    var %stun.chance $rand(1,100)
    var %weapon.bash.chance $calc($readini($char($1), skills, weaponbash) * 10)

    if ($augment.check($1, EnhanceWeaponBash) = true) { inc %weapon.bash.chance %augment.strength  } 

    if (%stun.chance <= %weapon.bash.chance) {
      writeini $char($2) status stun yes | $set_chr_name($2) | set %statusmessage.display 4 $+ %real.name has been stunned by the blow!
    }
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Drain Samba check
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
alias drain_samba_check {
  unset %drainsamba.on
  if ($readini($char($1), skills, drainsamba.on) = on) {
    ; Check to see how many turns its been..  
    set %drainsamba.turns $readini($char($1), skills, drainsamba.turn)
    if (%drainsamba.turns = $null) { set %drainsamba.turns 0 }
    set %drainsamba.turn.max $readini($char($1), skills, drainsamba)
    inc %drainsamba.turns 1 
    if (%drainsamba.turns > %drainsamba.turn.max) { $set_chr_name($1) | $display.message($readini(translation.dat, skill, DrainSambaWornOff), battle) | writeini $char($1) skills drainsamba.turn 0 | writeini $char($1) skills drainsamba.on off | return }
    writeini $char($1) skills drainsamba.turn %drainsamba.turns   
    set %drainsamba.on on
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Formless Strike check
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
alias formless_strike_check {
  if ($readini($char($1), skills, formlessstrike.on) = on) {
    ; Check to see how many turns its been..  
    set %fstrike.turns $readini($char($1), skills, formlessstrike.turn)
    if (%fstrike.turns = $null) { set %fstrike.turns 0 }
    set %fstrike.turn.max $readini($char($1), skills, formlessstrike)
    inc %fstrike.turns 1 

    if (%fstrike.turns > %fstrike.turn.max) { $set_chr_name($1) | $display.message($readini(translation.dat, skill, FormlessStrikeWornOff), battle) | writeini $char($1) skills formlessstrike.turn 0 | writeini $char($1) skills formlessstrike.on off | return }
    writeini $char($1) skills formlessstrike.turn %fstrike.turns   
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Check for augments and accessories
; that enhance weapon types.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
alias melee.weapontype.enhancements {

  ; Hand To Hand
  if (%weapon.type = HandToHand) {

    ;  Check for a +h2h damage accessory
    if ($accessory.check($1, IncreaseH2HDamage) = true) {
      inc %attack.damage $round($calc(%attack.damage * %accessory.amount),0)
      unset %accessory.amount
    }

    ; Check for an augment
    if ($augment.check($1, EnhanceHandtoHand) = true) {  inc %attack.damage $round($calc(%attack.damage + (%augment.strength * 50)),0)  } 
  }


  ; Spears
  if (%weapon.type = spear) {

    ;  Check for a +spear damage accessory
    if ($accessory.check($1, IncreaseSpearDamage) = true) {
      inc %attack.damage $round($calc(%attack.damage * %accessory.amount),0)
      unset %accessory.amount
    }

    ; Check for an augment
    if ($augment.check($1, EnhanceSpear) = true) {  inc %attack.damage $calc(%augment.strength * 100)  } 
  }

  ; Swords

  if (%weapon.type = sword) {

    ; Check for a +sword damage accessory
    if ($accessory.check($1, IncreaseSwordDamage) = true) {
      inc %attack.damage $round($calc(%attack.damage * %accessory.amount),0)
      unset %accessory.amount
    }

    ; Check for an augment
    if ($augment.check($1, EnhanceSword) = true) { inc %attack.damage $calc(%augment.strength * 100)  } 
  }

  if (%weapon.type = greatsword) {

    ; Check for a +greatsword damage accessory
    if ($accessory.check($1, IncreaseGreatSwordDamage) = true) {
      inc %attack.damage $round($calc(%attack.damage * %accessory.amount),0)
      unset %accessory.amount
    }

    ; Check for an augment
    if ($augment.check($1, EnhanceSword) = true) { inc %attack.damage $calc(%augment.strength * 100)  } 
  }

  if (%weapon.type = whip) {

    if ($accessory.check($1, IncreaseWhipDamage) = true) {
      inc %attack.damage $round($calc(%attack.damage * %accessory.amount),0)
      unset %accessory.amount
    }

    ; Check for an augment
    if ($augment.check($1, EnhanceWhip) = true) { inc %attack.damage $calc(%augment.strength * 100)  } 
  }

  if (%weapon.type = gun) {
    if ($accessory.check($1, IncreaseGunDamage) = true) {
      inc %attack.damage $round($calc(%attack.damage * %accessory.amount),0)
      unset %accessory.amount
    }

    ; Check for an augment
    if ($augment.check($1, EnhanceRanged) = true) { inc %attack.damage $calc(%augment.strength * 100)  } 
  }

  if (%weapon.type = bow) {
    if ($accessory.check($1, IncreaseBowDamage) = true) {
      inc %attack.damage $round($calc(%attack.damage * %accessory.amount),0)
      unset %accessory.amount
    }

    ; Check for an augment
    if ($augment.check($1, EnhanceRanged) = true) { inc %attack.damage $calc(%augment.strength * 100)  } 
  }

  if (%weapon.type = glyph) {
    if ($accessory.check($1, IncreaseGlyphDamage) = true) {
      inc %attack.damage $round($calc(%attack.damage * %accessory.amount),0)
      unset %accessory.amount
    }

    ; Check for an augment
    if ($augment.check($1, EnhanceGlyph) = true) { inc %attack.damage $calc(%augment.strength * 100)  } 
  }

  if (%weapon.type = Katana) {
    if ($accessory.check($1, IncreaseKatanaDamage) = true) {
      inc %attack.damage $round($calc(%attack.damage * %accessory.amount),0)
      unset %accessory.amount
    }

    ; Check for an augment
    if ($augment.check($1, EnhanceKatana) = true) {  inc %attack.damage $calc(%augment.strength * 100)   } 
  }

  if (%weapon.type = Wand) {
    if ($accessory.check($1, IncreaseWandDamage) = true) {
      inc %attack.damage $round($calc(%attack.damage * %accessory.amount),0)
      unset %accessory.amount
    }

    ; Check for an augment
    if ($augment.check($1, EnhanceWand) = true) { inc %attack.damage $calc(%augment.strength * 100)  } 
  }
  if (%weapon.type = Staff) {
    if ($accessory.check($1, IncreaseStaffDamage) = true) {
      inc %attack.damage $round($calc(%attack.damage * %accessory.amount),0)
      unset %accessory.amount
    }

    ; Check for an augment
    if ($augment.check($1, EnhanceStaff) = true) { inc %attack.damage $calc(%augment.strength * 100)  } 
  }

  if (%weapon.type = Stave) {
    if ($accessory.check($1, IncreaseStaffDamage) = true) {
      inc %attack.damage $round($calc(%attack.damage * %accessory.amount),0)
      unset %accessory.amount
    }

    ; Check for an augment
    if ($augment.check($1, EnhanceStaff) = true) { inc %attack.damage $calc(%augment.strength * 100)  } 
  }

  if (%weapon.type = Scythe) {
    if ($accessory.check($1, IncreaseScytheDamage) = true) {
      inc %attack.damage $round($calc(%attack.damage * %accessory.amount),0)
      unset %accessory.amount
    }

    ; Check for an augment
    if ($augment.check($1, EnhanceScythe) = true) { inc %attack.damage $calc(%augment.strength * 100)  } 
  }

  if (%weapon.type = Axe) {
    if ($accessory.check($1, IncreaseAxeDamage) = true) {
      inc %attack.damage $round($calc(%attack.damage * %accessory.amount),0)
      unset %accessory.amount
    }
    ; Check for an augment
    if ($augment.check($1, EnhanceAxe) = true) { inc %attack.damage $calc(%augment.strength * 100)  } 
  }

  if (%weapon.type = Dagger) {
    if ($accessory.check($1, IncreaseDaggerDamage) = true) {
      inc %attack.damage $round($calc(%attack.damage * %accessory.amount),0)
      unset %accessory.amount
    }
    ; Check for an augment
    if ($augment.check($1, EnhanceDagger) = true) { inc %attack.damage $calc(%augment.strength * 100)  } 
  }

}
