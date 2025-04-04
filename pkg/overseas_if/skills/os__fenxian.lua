local os__fenxian = fk.CreateSkill {
  name = "os__fenxian"
}

Fk:loadTranslationTable{
  ['os__fenxian'] = '焚险',
  ['#os__fenxian-active'] = '焚险：你可令一名角色选择一项：<br>1.其将你或其场上的一张牌当作【决斗】对一名除你以外的角色使用；<br>2.你视为对其使用一张【火攻】。',
  ['os__fenxian_duel_self'] = '将你场上的一张牌当【决斗】对一名其他角色使用',
  ['os__fenxian_duel'] = '将你或%src场上的一张牌当【决斗】对一名除%src以外的角色使用',
  ['os__fenxian_fire_attack_self'] = '你视为对自己使用一张【火攻】',
  ['os__fenxian_fire_attack'] = '%src视为对你使用一张【火攻】',
  ['os__fenxian_vs'] = '焚险',
  ['#os__fenxian_vs_self-use'] = '选择你场上的一张牌当作【决斗】对一名其他角色使用',
  ['#os__fenxian_vs-use'] = '焚险：选择你或%src场上的一张牌当作【决斗】对一名除%src以外的角色使用',
  [':os__fenxian'] = '出牌阶段限一次，你可令一名角色选择一项：1.其将你或其场上的一张牌当作【决斗】对一名除你以外的角色使用；2.你视为对其使用一张【火攻】。',
}

os__fenxian:addEffect('active', {
  anim_type = "offensive",
  prompt = "#os__fenxian-active",
  card_num = 0,
  target_num = 1,
  can_use = function (self, player)
    return player:usedSkillTimes(os__fenxian.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards, card, extra_data)
    if #selected ~= 0 then return false end
    local room = Fk:currentRoom()
    local to = room:getPlayerById(to_select)
    if canFenxianDuel(player, to, room) then return true end
    local c = Fk:cloneCard("fire_attack")
    c.skillName = os__fenxian.name
    return player:canUseTo(c, to)
  end,
  on_use = function (self, room, effect)
    local to = room:getPlayerById(effect.tos[1])
    local from = room:getPlayerById(effect.from)
    local toSelf = from.id == to.id
    local choices = {}
    if canFenxianDuel(from, to, room) then table.insert(choices, toSelf and "os__fenxian_duel_self" or "os__fenxian_duel:" .. effect.from) end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = os__fenxian.name
    if from:canUseTo(card, to) then
      table.insert(choices, toSelf and "os__fenxian_fire_attack_self" or "os__fenxian_fire_attack:" .. effect.from)
    end
    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = os__fenxian.name
    })
    if choice:startsWith("os__fenxian_duel") then
      local cards = to:getCardIds("j")
      if from.id ~= to.id then table.insertTable(cards, from:getCardIds("ej")) end
      local _, dat = room:askToUseViewAsSkill(to, "os__fenxian_vs", {
        prompt = toSelf and "#os__fenxian_vs_self-use" or "#os__fenxian_vs-use:" .. from.id,
        cards = { cards = cards },
        extra_data = { from = effect.from }
      })
      if dat then
        room:useVirtualCard("duel", dat.cards, to, room:getPlayerById(dat.targets[1]), os__fenxian.name, true)
      else
        local targets = table.simpleClone(room.alive_players)
        table.removeOne(targets, to)
        table.removeOne(targets, from)
        room:useVirtualCard("duel", table.random(table.connect(cards, to:getCardIds("e")), 1), to, table.random(targets), os__fenxian.name, true)
      end
    else
      room:useVirtualCard("fire_attack", nil, from, to, os__fenxian.name, true)
    end
  end,
})

return os__fenxian
