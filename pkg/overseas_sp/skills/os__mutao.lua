local os__mutao = fk.CreateSkill {
  name = "os__mutao"
}

Fk:loadTranslationTable{
  ['os__mutao'] = '募讨',
  [':os__mutao'] = '出牌阶段限一次，你可选择一名角色，令其将手牌中的（系统选择）每一张【杀】依次交给由其下家开始的除其以外的角色，然后其对最后一名角色造成X点伤害（X为最后一名角色手牌中【杀】的数量且至多为3）。',
  ['$os__mutao1'] = '董贼暴乱，天下定当奋节讨之！',
  ['$os__mutao2'] = '募州郡义士，讨祸国逆贼！',
}

os__mutao:addEffect('active', {
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(os__mutao.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  card_num = 0,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return not target:isKongcheng() and target:getNextAlive() ~= target
    end
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local to = target
    while true do
      local cids = table.filter(target:getCardIds(Player.Hand), function(id)
        return Fk:getCardById(id).trueName == "slash"
      end)
      if #cids < 1 then break end
      to = to:getNextAlive()
      if to == target then to = to:getNextAlive() end
      room:moveCardTo(table.random(cids), Player.Hand, to, fk.ReasonGive, os__mutao.name, nil, false)
    end
    local num = math.min(#table.filter(to:getCardIds(Player.Hand), function(id)
      return Fk:getCardById(id).trueName == "slash"
    end), 3)
    if num > 0 then
      room:damage{
        from = target,
        to = to,
        damage = num,
        skill_name = os__mutao.name,
      }
    end
  end,
})

return os__mutao
