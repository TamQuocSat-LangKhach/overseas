local extension = Package("overseas_token", Package.CardPack)
extension.extensionName = "overseas"

Fk:loadTranslationTable{
  ["overseas_token"] = "国际服衍生牌",
}

local moonSpearSkill = fk.CreateTriggerSkill{
  name = "moon_spear_skill",
  attached_equip = "moon_spear",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) or player.phase ~= Player.NotActive or player:getMark("_moon_spear-turn") ~= 1 then return false end
    for _, move in ipairs(data) do
      if move.from == player.id then
        return table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local use =  player.room:askForUseCard(player, "slash", nil, "#moon_spear_skill-ask", true)
    if use then
      self.cost_data = use
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setEmotion(player, "./packages/overseas/image/anim/moon_spear")
    room:useCard(self.cost_data)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(self.name) or player.phase ~= Player.NotActive or player:getMark("_moon_spear-turn") > 1 then return false end
    for _, move in ipairs(data) do
      if move.from == player.id then
        return table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end)
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_moon_spear-turn")
  end,
}
Fk:addSkill(moonSpearSkill)
local moonSpear = fk.CreateWeapon{
  name = "&moon_spear",
  suit = Card.Diamond,
  number = 12,
  attack_range = 3,
  equip_skill = moonSpearSkill,
}
extension:addCard(moonSpear)
Fk:loadTranslationTable{
  ["moon_spear"] = "银月枪",
  [":moon_spear"] = "装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：当你于其他角色的回合中第一次失去牌后，你可使用【杀】。",
  ["moon_spear_skill"] = "银月枪",
  ["#moon_spear_skill-ask"] = "银月枪：你可使用【杀】",
  [":moon_spear_skill"] = "当你于其他角色的回合中第一次失去牌后，你可使用【杀】。",
}

--[[local redistributeCardSkill = fk.CreateActiveSkill{
  name = "redistribute_skill",
  target_num = 2,
  target_filter = function(self, to_select, selected)
    if #selected == 1 then
      return Fk:currentRoom():getPlayerById(to_select):getHandcardNum() ~= Fk:currentRoom():getPlayerById(selected[1]):getHandcardNum()
    end
  end,
  on_use = function(self, room, cardUseEvent)
    cardUseEvent.extra_data = cardUseEvent.extra_data or {}
  end,
  on_effect = function(self, room, cardEffectEvent)
    local to = room:getPlayerById(cardEffectEvent.to)
    TargetGroup:getRealTargets(cardEffectEvent.tos)
  end,
}
local redistribute = fk.CreateTrickCard{
  name = "redistribute",
  skill = redistributeCardSkill,
  suit = Card.Spade,
  number = 6,
  special_skills = { "recast" },
}
extension:addCards{
  redistribute,
  redistribute:clone(Card.Club, 6),
  redistribute:clone(Card.Heart, 6),
  redistribute:clone(Card.Diamond, 6),
}
Fk:loadTranslationTable{
  ["redistribute"] = "调剂盐梅",
  [":redistribute"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：两名手牌数不同的角色<br /><b>效果</b>：若所有目标角色的手牌数不均相同，为/不为{这些角色中手牌数最小}的目标角色摸/弃置一张手牌。若所有目标角色手牌数相同，你可将以此法弃置的牌交给一名角色。",
}]]

local enemyAtTheGatesSkill = fk.CreateActiveSkill{
  name = "enemy_at_the_gates_skill",
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Self.id ~= to_select
  end,
  on_effect = function(self, room, cardEffectEvent)
    local player = room:getPlayerById(cardEffectEvent.from)
    local to = room:getPlayerById(cardEffectEvent.to)
    for i = 1, 4, 1 do
      local id = room:getNCards(1)[1]
      room:moveCardTo(id, Card.Processing, nil, fk.ReasonJustMove, self.name)
      local card = Fk:getCardById(id)
      if card.trueName == "slash" and not player:prohibitUse(card) and not player:isProhibited(to, card) and player:isAlive() and to:isAlive() then
        room:useCard({
          card = card,
          from = player.id,
          tos = { {to.id} },
          skillName = self.name,
        })
      end
    end
  end,
}
local enemyAtTheGates = fk.CreateTrickCard{
  name = "&enemy_at_the_gates",
  suit = Card.Spade,
  number = 7,
  skill = enemyAtTheGatesSkill,
}
extension:addCards{
  enemyAtTheGates,
  enemyAtTheGates:clone(Card.Club, 7),
  enemyAtTheGates:clone(Card.Club, 13),
}
Fk:loadTranslationTable{
  ["enemy_at_the_gates"] = "兵临城下",
  [":enemy_at_the_gates"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名其他角色<br /><b>效果</b>：你依次展示牌堆顶四张牌，若为【杀】，你对目标使用之；若不为【杀】，将此牌置入弃牌堆。",
}

return extension