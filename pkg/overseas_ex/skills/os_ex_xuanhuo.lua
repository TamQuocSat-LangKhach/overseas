local osExXuanhuo = fk.CreateSkill {
  name = "os_ex__xuanhuo"
}

Fk:loadTranslationTable{
  ["os_ex__xuanhuo"] = "眩惑",
  [":os_ex__xuanhuo"] = "摸牌阶段结束时，你可交给一名其他角色A两张牌并选择另一名角色B，然后A选择一项：1. 视为对B使用一张【杀】或【决斗】；2. 你获得其两张牌。",

  ["#os_ex__xuanhuo-target"] = "眩惑：你可交给第一名角色两张牌，并令其需视为对第二名角色使用杀或决斗，否则你获得其两张牌",
  ["#os_ex__xuanhuo-use"] = "眩惑：视为对 %dest 使用【杀】或【决斗】，或点“取消”令 %src 获得你的两张牌",

  ["$os_ex__xuanhuo1"] = "收人钱财，替人消灾。",
  ["$os_ex__xuanhuo2"] = "哼，叫你十倍奉还！",
}

local U = require "packages/utility/utility"

osExXuanhuo:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(osExXuanhuo.name) and player.phase == Player.Draw and #player:getCardIds("he") > 1
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askToUseActiveSkill(
      player,
      {
        skill_name = "os_ex__xuanhuo_active",
        prompt = "#os_ex__xuanhuo-target",
      }
    )
    if success and dat then
      event:setCostData(self, { cards = dat.cards, tos = dat.targets })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osExXuanhuo.name
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, to, fk.ReasonGive, skillName, nil, false, player)
    if not to:isAlive() then
      return false
    end

    local victim = event:getCostData(self).tos[2]
    if not victim:isAlive() then
      if player:isAlive() and not to:isKongcheng() then
        room:obtainCard(player, room:askToChooseCards(
          player,
          {
            min = 2,
            max = 2,
            target = to,
            flag = "he",
            skill_name = skillName,
          }
        ), false, fk.ReasonPrey, player, skillName)
        return false
      end
    end
    if player:getMark(skillName) == 0 then
      local cards = table.filter(U.prepareUniversalCards(room), function (id)
        return Fk:getCardById(id).name == "slash" or Fk:getCardById(id).name == "duel"
      end)
      room:setPlayerMark(player, skillName, cards)
    end

    local cards = player:getMark(skillName)
    local use = room:askToUseRealCard(
      to,
      {
        pattern = cards,
        skill_name = skillName,
        prompt = "#os_ex__xuanhuo-use:" .. player.id .. ":" .. victim.id,
        extra_data = {
          bypass_distances = true,
          expand_pile = cards,
          exclusive_targets = { victim.id },
        },
        skip = true,
      }
    )
    if use then
      local card = Fk:cloneCard(use.card.name)
      card.skillName = skillName
      room:useCard{
        from = to,
        tos = use.tos,
        card = card,
        extraUse = true,
      }
    elseif not to:isKongcheng() then
      room:obtainCard(player, room:askToChooseCards(
        player,
        {
          min = 2,
          max = 2,
          target = to,
          flag = "he",
          skill_name = skillName,
        }
      ), false, fk.ReasonPrey, player, skillName)
    end
  end,
})

return osExXuanhuo
