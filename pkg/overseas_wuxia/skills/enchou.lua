local enchou = fk.CreateSkill {
  name = "os__enchou"
}

Fk:loadTranslationTable{
  ['os__enchou'] = '恩仇',
  ['os__enchou_get'] = '获得',
  ['#os__enchou-ask'] = '恩仇：获得 %dest 一张手牌，然后恢复其一个装备栏',
  ['#os__enchou-choice'] = '恩仇：恢复 %dest 一个装备栏',
  [':os__enchou'] = '出牌阶段限一次，你可观看一名有装备栏被废除的其他角色的手牌并获得其中一张牌，然后你恢复其一个装备栏。',
  ['$os__enchou1'] = '江湖快意，恩仇必报！',
  ['$os__enchou2'] = '今日之因，明日之果！'
}

enchou:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(enchou.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and #getSealedEquipSlot(Fk:currentRoom():getPlayerById(to_select)) > 0 and to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cids = target:getCardIds(Player.Hand)
    local cards, _ = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      targets = {target},
      min_target_num = 0,
      max_target_num = 0,
      pattern = ".|.|.",
      prompt = "#os__enchou-ask::" .. target.id,
      skill_name = enchou.name
    })
    room:obtainCard(player, cards[1], false, fk.ReasonPrey, player.id)
    if not target.dead and not player.dead then
      local choices = getSealedEquipSlot(target)
      if #choices > 0 then
        local choice = room:askToChoice(player, {
          choices = choices,
          skill_name = enchou.name,
          prompt = "#os__enchou-choice::" .. target.id,
          cancelable = false
        })
        room:resumePlayerArea(target, {choice})
      end
    end
  end,
})

return enchou
