local os__mibei = fk.CreateSkill {
  name = "os__mibei"
}

Fk:loadTranslationTable{
  ['os__mibei'] = '秘备',
  ['@os__mibei'] = '秘备',
  ['os__mouli'] = '谋立',
  [':os__mibei'] = '<a href=>使命技</a>，使用每种类别的牌各至少两张。成功：你获得〖谋立〗。完成前：出牌阶段结束时，若你本回合未使用过牌，则你此回合手牌上限-1并重置〖秘备〗。<br/><font color=>◆<b>重置〖秘备〗</b>，即清空〖秘备〗所记录的所使用过的牌的类别和数量。',
  ['$os__mibei1'] = '密为之备，不可有失。',
  ['$os__mibei2'] = '事以密成，语以泄败！',
}

os__mibei:addEffect(fk.AfterCardUseDeclared, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player:getQuestSkillState(os__mibei.name) ~= "succeed"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local typesRecorded = player:getMark("@os__mibei") ~= 0 and string.split(player:getMark("@os__mibei"), "-") or {0, 0, 0}
    typesRecorded[data.card.type] = tonumber(typesRecorded[data.card.type]) + 1
    room:setPlayerMark(player, "@os__mibei", table.concat(typesRecorded, "-"))
    if tonumber(typesRecorded[1]) > 1 and tonumber(typesRecorded[2]) > 1 and tonumber(typesRecorded[3]) > 1 then
      room:updateQuestSkillState(player, os__mibei.name, true) -- 为了有那个白底……
      room:updateQuestSkillState(player, os__mibei.name, false)
      room:handleAddLoseSkills(player, "os__mouli", nil)
      room:setPlayerMark(player, "@os__mibei", 0)
    end
    room:addPlayerMark(player, "_os__mibei_use-turn")
  end,
})

os__mibei:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return player.phase == Player.Play and player:getMark("_os__mibei_use-turn") == 0
      and player:hasSkill(skill.name) and player:getQuestSkillState(os__mibei.name) ~= "succeed"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 1)
    room:setPlayerMark(player, "@os__mibei", "0-0-0")
    room:updateQuestSkillState(player, os__mibei.name, true)
  end,
})

return os__mibei
