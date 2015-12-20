alias msg {
  if (=* iswm $1) {  ; Leave DCC messages alone.
    !msg $1 $2-
    return
  }
  addline PRIVMSG $1 : $+ $2-
}

alias addline {
  set %sendqueue %sendqueue $+ $1- $+ $+ $chr(127)
  if (!$timer(sendqueue)) .timerSendQueue -m 0 600 sendline
}

alias sendline {
  var %space = $pos(%sendqueue, $chr(127), 1)
  raw -q $left(%sendqueue, $calc(%space - 1))
  set %sendqueue $right(%sendqueue, $calc(-%space))
  if (%sendqueue == $null) {
    unset %sendqueue
    .timerSendQueue off
  }
}
