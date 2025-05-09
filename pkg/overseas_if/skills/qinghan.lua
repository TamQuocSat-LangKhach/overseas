local qinghan = fk.CreateSkill {
  name = "os__qinghan"
}

Fk:loadTranslationTable{
  ["os__qinghan"] = "擎汉",
  [":os__qinghan"] = "出牌阶段限一次，你可以用一张装备牌与一名角色拼点：若你赢，你可视为对其使用一张以其为唯一目标的普通锦囊牌；" ..
  "若两张拼点牌颜色相同，你与其获得对方的拼点牌。你的拼点牌点数+X（X为你装备区牌数的两倍）。",

  ["#os__qinghan"] = "擎汉：你可以用一张装备牌与一名角色拼点，若赢，视为对其使用锦囊牌",
  ["#os__qinghan-use"] = "擎汉：你可以视为对 %dest 使用一张普通锦囊牌",

  ["$os__qinghan1"] = "二十四代终未竟，今以一隅誓还天！",
  ["$os__qinghan2"] = "维继丞相遗托，当负擎汉之重。",
}

local U = require "packages/utility/utility"

qinghan:addEffect("active", {
  anim_type = "control",
  prompt = "#os__qinghan",
  card_num = 1,
  target_num = 1,
  can_use = function (self, player)
    return player:usedSkillTimes(qinghan.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #selected_cards == 1 and player:canPindian(to_select, true)
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, qinghan.name, Fk:getCardById(effect.cards[1]))
    if pindian.results[target].winner == player and not player.dead and not target.dead then
      local all_cards = U.getUniversalCards(room, "t")
      local cards = table.filter(all_cards, function (id)
        return player:canUseTo(Fk:getCardById(id), target, {bypass_distances = true, bypass_times = true})
      end)
      if #cards > 0 then
        local use = room:askToUseRealCard(player, {
          pattern = cards,
          skill_name = qinghan.name,
          prompt = "#os__qinghan-use::"..target.id,
          extra_data = {
            bypass_distances = true,
            bypass_times = true,
            expand_pile = all_cards,
            exclusive_targets = {target.id},
          },
          skip = true,
        })
        if use then
          local card = Fk:cloneCard(use.card.name)
          card.skillName = qinghan.name
          room:useCard{
            card = card,
            from = player,
            tos = #use.tos > 0 and use.tos or {target},
            extraUse = true,
          }
        end
      end
    end
    if pindian.results[target].toCard:compareColorWith(pindian.fromCard) and not player.dead then
      local moveInfos = {}
      if pindian.results[target].toCard and
        room:getCardArea(pindian.results[target].toCard) == Card.DiscardPile then
        table.insert(moveInfos, {
          to = player,
          ids = Card:getIdList(pindian.results[target].toCard),
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonExchange,
          proposer = player,
          skillName = qinghan.name,
        })
      end
      if pindian.fromCard and not target.dead and
        room:getCardArea(pindian.fromCard) == Card.DiscardPile then
        table.insert(moveInfos, {
          to = target,
          ids = Card:getIdList(pindian.fromCard),
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonExchange,
          proposer = player,
          skillName = qinghan.name,
        })
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
      end
    end
  end,
})

qinghan:addEffect(fk.PindianCardsDisplayed, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(qinghan.name) and (player == data.from or data.results[player]) and #player:getCardIds("e") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:changePindianNumber(data, player, 2 * #player:getCardIds("e"), qinghan.name)
  end,
})

return qinghan
