local os__daoji = fk.CreateSkill {
  name = "os__daoji"
}

Fk:loadTranslationTable{
  ['os__daoji'] = '盗戟',
  [':os__daoji'] = '出牌阶段限一次，你可弃置一张非基本牌并选择一名攻击范围内的其他角色，你获得其一张牌。若你以此法获得的牌为：基本牌，你摸一张牌；装备牌，则你使用此牌，对其造成1点伤害。',
  ['$os__daoji1'] = '八十斤双戟？于我如探囊取物！',
  ['$os__daoji2'] = '以汝之矛，攻汝之盾！',
}

os__daoji:addEffect('active', {
  can_use = function(self, player)
    return player:usedSkillTimes(os__daoji.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:inMyAttackRange(Fk:currentRoom():getPlayerById(to_select)) and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, use)
    if #use.cards ~= 1 then return end
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    room:throwCard(use.cards, os__daoji.name, player, player)
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "he",
      skill_name = os__daoji.name
    })
    room:obtainCard(player, id)
    local cardType = Fk:getCardById(id).type
    if cardType == Card.TypeBasic then
      player:drawCards(1, os__daoji.name)
    elseif cardType == Card.TypeEquip then
      room:useCard({
        from = player.id,
        tos = { {player.id} },
        card = Fk:getCardById(id),
      })
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = os__daoji.name,
      }
    end
  end,
})

return os__daoji
