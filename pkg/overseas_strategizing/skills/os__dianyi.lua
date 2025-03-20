local os__dianyi = fk.CreateSkill {
  name = "os__dianyi"
}

Fk:loadTranslationTable{
  ['os__dianyi'] = '典仪',
  [':os__dianyi'] = '锁定技，回合结束前，若你本回合：造成过伤害，你须弃置所有手牌；未造成过伤害，你将手牌摸至或弃置至四张。',
  ['$os__dianyi1'] = '旧仪废弛，兴造制度。',
  ['$os__dianyi2'] = '礼仪卒度，笑语卒获。',
}

os__dianyi:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  mute = true,
  frequency = Skill.Compulsory,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(os__dianyi.name)
    if #room.logic:getActualDamageEvents(1, function(e)
      return e.data[1].from == target
    end, Player.HistoryTurn) > 0 then
      room:notifySkillInvoked(player, os__dianyi.name)
      player:throwAllCards("h")
    else
      local num = 4 - player:getHandcardNum()
      if num > 0 then
        room:notifySkillInvoked(player, os__dianyi.name, "drawcard")
        player:drawCards(num, os__dianyi.name)
      elseif num < 0 then
        room:notifySkillInvoked(player, os__dianyi.name)
        num = -num
        player.room:askToDiscard(player, {
          min_num = num,
          max_num = num,
          include_equip = false,
          skill_name = os__dianyi.name,
          cancelable = false,
        })
      end
    end
  end,
})

return os__dianyi
