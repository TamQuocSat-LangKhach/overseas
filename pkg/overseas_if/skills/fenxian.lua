local fenxian = fk.CreateSkill {
  name = "os__fenxian",
}

Fk:loadTranslationTable{
  ["os__fenxian"] = "焚险",
  [":os__fenxian"] = "出牌阶段限一次，你可以令一名角色选择一项：1.其将你或其场上的一张牌当【决斗】对一名除你以外的角色使用；"..
  "2.你视为对其使用一张【火攻】。",

  ["#os__fenxian"] = "焚险：令一名角色选择：其将你或其场上的一张牌当【决斗】使用，或你视为对其使用【火攻】",
  ["#os__fenxian-use"] = "焚险：将场上一张牌当【决斗】对除 %src 以外的角色使用，或点“取消”视为其对你使用【火攻】",
}

fenxian:addEffect("active", {
  anim_type = "offensive",
  prompt = "#os__fenxian",
  card_num = 0,
  target_num = 1,
  can_use = function (self, player)
    return player:usedSkillTimes(fenxian.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local all_cards = table.simpleClone(player:getCardIds("ej"))
    if target ~= player then
      table.insertTable(all_cards, target:getCardIds("ej"))
    end
    local yes1 = table.find(all_cards, function (id)
      local card = Fk:cloneCard("duel")
      card.skillName = fenxian.name
      card:addSubcard(id)
      return table.find(room:getOtherPlayers(player, false), function (p)
        return p ~= target and target:canUseTo(card, p)
      end) ~= nil
    end)
    local card = Fk:cloneCard("fire_attack")
    card.skillName = fenxian.name
    local yes2 = player:canUseTo(card, target)
    if not (yes1 or yes2) then
      return
    end
    if yes1 then
      if room:askToUseVirtualCard(target, {
        name = "duel",
        skill_name = fenxian.name,
        prompt = "#os__fenxian-use:"..player.id,
        cancelable = yes2,
        card_filter = {
          n = 1,
          cards = all_cards,
        },
      }) then
        return
      end
    end
    room:useVirtualCard("fire_attack", nil, player, target, fenxian.name)
  end,
})

return fenxian
