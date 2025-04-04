local osChanggui = fk.CreateSkill {
  name = "os__changgui"
}

Fk:loadTranslationTable{
  ['os__changgui'] = '怅归',
  ['os_if_huan__zhugeliang'] = '幻诸葛亮',
  ['os_if__zhugeliang'] = '幻诸葛亮',
  [':os__changgui'] = '锁定技，结束阶段开始时，若你的体力值为全场最低，则你<a href=>“退幻”</a>并将体力上限调整至体力值。',
  ['$os__changgui1'] = '隆中鱼水，永安星落，数载恍然隔世。',
  ['$os__changgui2'] = '铁马冰河，金台临望，倏醒方叹无功。',
}

osChanggui:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function (self, event, target, player)
    return
      target == player and
      player.phase == Player.Finish and
      player:hasSkill(osChanggui.name) and
      table.every(player.room.alive_players, function(p) return p.hp >= player.hp end)
  end,
  on_use = function (self, event, target, player)
    local room = player.room
    room:handleAddLoseSkills(player, "-os_huan__beiding|-os_huan__jielv|-os__huanji|".. osChanggui.name .."|os__beiding|os__jielv|os__hunyou", nil, true, false)
    if player.general == "os_if_huan__zhugeliang" then
      room:setPlayerProperty(player, "general", "os_if__zhugeliang")
    end
    if player.deputyGeneral == "os_if_huan__zhugeliang" then
      room:setPlayerProperty(player, "deputyGeneral", "os_if__zhugeliang")
    end
    room:changeMaxHp(player, player.hp - player.maxHp)
  end,
})

return osChanggui
