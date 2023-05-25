local extension = Package("overseas_token", Package.CardPack)
extension.extensionName = "overseas"

Fk:loadTranslationTable{
  ["overseas_token"] = "国际服衍生牌",
}

local celestialCalabashSkill = fk.CreateTriggerSkill{
  name = "#celestial_calabash_skill",
  attached_equip = "celestial_calabash",
  events = {fk.DamageCaused, fk.Death},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.DamageCaused then
      return target == player and data.damage > 1
    else
      return target ~= player
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    --room:setEmotion(player, "./packages/overseas/image/anim/moon_spear")
    room:notifySkillInvoked(player, self.name, "support")
    room:sendLog{
      type = "#CelestialCalabashSkill",
      from = player.id,
      arg = self.attached_equip,
    } --呃
    room:changeMaxHp(player, 1)
    room:recover({ who = player, num = 1, recoverBy = player, skillName = self.name})
  end,
}
Fk:addSkill(celestialCalabashSkill)
local celestialCalabash = fk.CreateWeapon{
  name = "&celestial_calabash",
  suit = Card.Heart,
  number = 1,
  attack_range = 3,
  equip_skill = celestialCalabashSkill,
}
extension:addCard(celestialCalabash)
Fk:loadTranslationTable{
  ["celestial_calabash"] = "灵宝仙葫",
  [":celestial_calabash"] = "装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：锁定技，当你造成大于1点的伤害时或一名角色死亡时，你增加1点体力上限并回复1点体力。",
  ["#celestial_calabash_skill"] = "灵宝仙葫",
  [":#celestial_calabash_skill"] = "锁定技，当你造成大于1点的伤害时或一名角色死亡时，你增加1点体力上限并回复1点体力。",
  ["#CelestialCalabashSkill"] = "%from 发动了“%arg”",
}

local horsetailWhiskSkill = fk.CreateTriggerSkill{
  name = "#horsetail_whisk_skill",
  attached_equip = "horsetail_whisk",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash"
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "offensive")
    local target = room:getPlayerById(data.to)
    local cids = room:askForDiscard(target, 1, 1, true, self.name, true, nil, "#horsetail_whisk-ask:" .. player.id .. "::" .. "log_" .. data.card:getSuitString())
    if #cids == 0 then
      data.disresponsive = true
    elseif data.card.suit == Fk:getCardById(cids[1]).suit then
      room:obtainCard(player, cids[1], true, fk.ReasonJustMove)
    end
  end,
}
Fk:addSkill(horsetailWhiskSkill)
local horsetailWhisk = fk.CreateWeapon{
  name = "&horsetail_whisk",
  suit = Card.Heart,
  number = 1,
  attack_range = 5,
  equip_skill = horsetailWhiskSkill,
}
extension:addCard(horsetailWhisk)
Fk:loadTranslationTable{
  ["horsetail_whisk"] = "太极拂尘",
  [":horsetail_whisk"] = "装备牌·武器<br /><b>攻击范围</b>：５<br /><b>武器技能</b>：当你使用的【杀】指定目标后，目标角色需弃置一张牌，否则不可响应此【杀】；若其弃置的牌与此【杀】花色相同，你获得之。",
  ["#horsetail_whisk_skill"] = "太极拂尘",
  [":#horsetail_whisk_skill"] = "当你使用的【杀】指定目标后，目标角色需弃置一张牌，否则不可响应此【杀】；若其弃置的牌与此【杀】花色相同，你获得之。",
  ["#horsetail_whisk-ask"] = "太极拂尘：弃置一张牌，否则不可响应此【杀】。若弃置的为%arg，%src将获得之",
}

local talismanSkill = fk.CreateTriggerSkill{
  name = "#talisman_skill",
  attached_equip = "talisman",
  events = {fk.DamageInflicted},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and type(player:getMark("@$talisman")) == "table" and table.contains(player:getMark("@$talisman"), data.card.trueName)
  end,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, self.name, "defensive")
    data.damage = data.damage - 1
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card
  end,
  on_refresh = function(self, event, target, player, data)
    local talismanRecorded = type(player:getMark("@$talisman")) == "table" and player:getMark("@$talisman") or {}
    table.insertIfNeed(talismanRecorded, data.card.trueName)
    player.room:setPlayerMark(player, "@$talisman", talismanRecorded)
  end,
}
Fk:addSkill(talismanSkill)
local talisman = fk.CreateArmor{
  name = "&talisman",
  suit = Card.Heart,
  number = 1,
  equip_skill = talismanSkill,
  on_uninstall = function(self, room, player)
    Armor.onUninstall(self, room, player)
    room:setPlayerMark(player, "@$talisman", 0)
  end,
}
extension:addCard(talisman)
Fk:loadTranslationTable{
  ["talisman"] = "冲应神符",
  [":talisman"] = "装备牌·武器<br /><b>武器技能</b>：锁定技，当你受到一种牌名的牌造成的伤害后，本局游戏同牌名的牌对你造成的伤害-1。",
  ["#talisman_skill"] = "冲应神符",
  [":#talisman_skill"] = "锁定技，当你受到一种牌名的牌造成的伤害后，本局游戏同牌名的牌对你造成的伤害-1。",
  ["@$talisman"] = "神符",
}

local moonSpearSkill = fk.CreateTriggerSkill{
  name = "#moon_spear_skill",
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
    local use = player.room:askForUseCard(player, "slash", nil, "#moon_spear_skill-ask", true)
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
    if player.phase ~= Player.NotActive or player:getMark("_moon_spear-turn") > 1 then return false end
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
  ["#moon_spear_skill"] = "银月枪",
  ["#moon_spear_skill-ask"] = "银月枪：你可使用【杀】",
  [":moon_spear_skill"] = "当你于其他角色的回合中第一次失去牌后，你可使用【杀】。",
}

local redistributeSkill = fk.CreateActiveSkill{
  name = "redistribute_skill",
  target_num = 2,
  target_filter = function(self, to_select, selected)
    if #selected == 1 then
      return Fk:currentRoom():getPlayerById(to_select):getHandcardNum() ~= Fk:currentRoom():getPlayerById(selected[1]):getHandcardNum()
    end
    return true
  end,
  on_use = function(self, room, cardUseEvent)
    if cardUseEvent.tos and #TargetGroup:getRealTargets(cardUseEvent.tos) > 0 then
      cardUseEvent.extra_data = cardUseEvent.extra_data or {}
      local num, minPlayer = nil, {}
      for _, p in ipairs(TargetGroup:getRealTargets(cardUseEvent.tos)) do
        local hand_num = room:getPlayerById(p):getHandcardNum()
        if num == nil or num > hand_num then
          num = hand_num
          minPlayer = {p}
        elseif num == hand_num then
          table.insert(minPlayer, p)
        end
      end
      if #TargetGroup:getRealTargets(cardUseEvent.tos) == #minPlayer then minPlayer = {} end
      if #minPlayer > 0 then cardUseEvent.extra_data.redistributeMinPlayer = minPlayer end
    end
  end,
  on_effect = function(self, room, cardEffectEvent)
    local to = room:getPlayerById(cardEffectEvent.to)
    if cardEffectEvent.extra_data and cardEffectEvent.extra_data.redistributeMinPlayer then
      if table.contains(cardEffectEvent.extra_data.redistributeMinPlayer, to.id) then
        to:drawCards(1, self.name)
      elseif not to:isKongcheng() then
        local cids = room:askForDiscard(to, 1, 1, false, self.name, false)
        if #cids > 0 then
          cardEffectEvent.extra_data.redistributeCids = cardEffectEvent.extra_data.redistributeCids or {}
          table.insert(cardEffectEvent.extra_data.redistributeCids, cids[1])
        end
      end
    end
  end,
}
local redistributeAction = fk.CreateTriggerSkill{
  name = "redistribute_action",
  global = true,
  priority = 10,
  events = { fk.CardUseFinished },
  can_trigger = function(self, event, target, player, data)
    return data.card and data.card.name == "redistribute" and data.extra_data and data.extra_data.redistributeCids and target:isAlive()
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local cids = table.filter(data.extra_data.redistributeCids, function(id)
      return room:getCardArea(id) == Card.DiscardPile
    end)
    if #cids == 0 then
      data.extra_data.redistributeCids = nil
      return false
    end
    local target = room:askForChoosePlayers(target, table.map(room.alive_players, function(p) return p.id end), 1, 1, "#redistribute-give", self.name, true)
    if #target > 0 then room:moveCardTo(cids, Player.Hand, room:getPlayerById(target[1]), fk.ReasonGive, self.name) end
    data.extra_data.redistributeCids = nil
  end,
}
Fk:addSkill(redistributeAction)

local redistribute = fk.CreateTrickCard{
  name = "&redistribute",
  skill = redistributeSkill,
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
  [":redistribute"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：两名手牌数不同的角色<br /><b>效果</b>：若所有目标角色的手牌数不均相同，为这些角色中手牌数最小的目标角色摸一张牌，不为的弃置一张手牌。若所有目标角色手牌数相同，你可将以此法弃置的牌交给一名角色。",
  ["redistribute_skill"] = "调剂盐梅",
  ["redistribute_action"] = "调剂盐梅",
  ["#redistribute-give"] = "你可将因【调剂盐梅】弃置的牌交给一名角色",
}

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
          extraUse = true,
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
  is_damage_card = true,
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