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
    if not player:hasSkill(self) then return false end
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
}

local horsetailWhiskSkill = fk.CreateTriggerSkill{
  name = "#horsetail_whisk_skill",
  attached_equip = "horsetail_whisk",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "offensive")
    local target = room:getPlayerById(data.to)
    local cids = room:askForDiscard(target, 1, 1, true, self.name, true, nil, "#horsetail_whisk-ask:" .. player.id .. "::" .. "log_" .. data.card:getSuitString())
    if #cids == 0 then
      data.disresponsive = true
    elseif data.card:compareSuitWith(Fk:getCardById(cids[1])) then
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
    return target == player and player:hasSkill(self) and data.card and type(player:getMark("@$talisman")) == "table" and table.contains(player:getMark("@$talisman"), data.card.trueName)
  end,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, self.name, "defensive")
    data.damage = data.damage - 1
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card
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
  [":talisman"] = "装备牌·防具<br /><b>防具技能</b>：锁定技，①当你受到伤害后，记录造成此伤害的牌的牌名；②当你受到伤害时，若造成此伤害的牌的牌名被记录过，此伤害-1。",
  ["#talisman_skill"] = "冲应神符",
  [":#talisman_skill"] = "锁定技，当你受到一种牌名的牌造成的伤害后，本局游戏同牌名的牌对你造成的伤害-1。",
  ["@$talisman"] = "神符",
}

local moonSpearSkill = fk.CreateTriggerSkill{
  name = "#moon_spear_skill",
  attached_equip = "moon_spear",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player.phase ~= Player.NotActive or player:getMark("_moon_spear-turn") ~= 1 then return false end
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

local underhandingSkill = fk.CreateActiveSkill{
  name = "underhanding_skill",
  prompt = "#underhanding_skill",
  min_target_num = 1,
  max_target_num = 2,
  target_filter = function(self, to_select, selected)
    local p = Fk:currentRoom():getPlayerById(to_select)
    return to_select ~= Self.id and not p:isAllNude()
  end,
  on_effect = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.to)
    if not to:isAllNude() then
      local id = room:askForCardChosen(player, to, "hej", self.name)
      room:obtainCard(player, id, false, fk.ReasonPrey, player.id, self.name)
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        use.extra_data = use.extra_data or {}
        use.extra_data.underhanding_targets = use.extra_data.underhanding_targets or {}
        table.insertIfNeed(use.extra_data.underhanding_targets, to.id)
      end
    end
  end,
  on_action = function (self, room, use, finished)
    if not finished then return end
    local player = room:getPlayerById(use.from)
    if player.dead or player:isNude() then return end
    local targets = (use.extra_data or {}).underhanding_targets or {}
    if #targets == 0 then return end
    room:sortPlayersByAction(targets)
    for _, pid in ipairs(targets) do
      local target = room:getPlayerById(pid)
      if not player:isNude() and not target.dead and not player.dead then
        local c = room:askForCard(player, 1, 1, true, self.name, false, nil, "#underhanding-card::" .. pid)[1]
        room:moveCardTo(c, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id)
      end
    end
  end
}
local underhandingExclude = fk.CreateMaxCardsSkill{
  name = "underhanding_exclude",
  global = true,
  exclude_from = function(self, player, card)
    return card and card.name == "underhanding"
  end,
}
Fk:addSkill(underhandingExclude)
local underhanding = fk.CreateTrickCard{
  name = "&underhanding",
  suit = Card.Heart,
  number = 5,
  skill = underhandingSkill,
  multiple_targets = true,
}
extension:addCards{
  underhanding,
  underhanding:clone(Card.Club, 5),
  underhanding:clone(Card.Spade, 5),
  underhanding:clone(Card.Diamond, 5),
}
Fk:loadTranslationTable{
  ["underhanding"] = "瞒天过海",
  [":underhanding"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一至两名区域内有牌的其他角色。<br /><b>效果</b>：你依次获得目标角色区域内的一张牌，然后依次交给目标角色一张牌。<br />此牌不计入你的手牌上限。",
  ["underhanding_skill"] = "瞒天过海",
  ["underhanding_action"] = "瞒天过海",
  ["#underhanding-card"] = "瞒天过海：交给 %dest 一张牌",
  ["#underhanding_skill"] = "选择一至两名区域内有牌的其他角色，依次获得其区域内的一张牌，然后依次交给其一张牌",
}

local redistributeSkill = fk.CreateActiveSkill{
  name = "redistribute_skill",
  prompt = "#redistribute_skill",
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
  on_action = function (self, room, use, finished)
    if finished and (use.extra_data or {}).redistributeCids and not room:getPlayerById(use.from).dead then
      if use.tos and #TargetGroup:getRealTargets(use.tos) > 0 then
        local num = nil
        for _, p in ipairs(TargetGroup:getRealTargets(use.tos)) do
          local hand_num = room:getPlayerById(p):getHandcardNum()
          if num == nil then
            num = hand_num
          elseif num ~= hand_num then
            use.extra_data.redistributeCids = nil
            return false
          end
        end
      end
      local cids = table.filter(use.extra_data.redistributeCids, function(id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #cids == 0 then
        use.extra_data.redistributeCids = nil
        return false
      end
      local target = room:askForChoosePlayers(room:getPlayerById(use.from), table.map(room.alive_players, Util.IdMapper), 1, 1, "#redistribute-give", self.name, true)
      if #target > 0 then room:moveCardTo(cids, Player.Hand, room:getPlayerById(target[1]), fk.ReasonGive, self.name) end
      use.extra_data.redistributeCids = nil
    end
  end
}
local redistribute = fk.CreateTrickCard{
  name = "&redistribute",
  skill = redistributeSkill,
  suit = Card.Spade,
  number = 6,
  special_skills = { "recast" },
  multiple_targets = true,
}
extension:addCards{
  redistribute,
  redistribute:clone(Card.Club, 6),
  redistribute:clone(Card.Heart, 6),
  redistribute:clone(Card.Diamond, 6),
}
Fk:loadTranslationTable{
  ["redistribute"] = "调剂盐梅",
  [":redistribute"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：两名手牌数不同的角色<br /><b>效果</b>：若所有目标角色的手牌数不均相同，为这些角色中手牌数最小的目标角色摸一张牌，不为的弃置一张手牌。然后若所有目标角色手牌数相同，你可将以此法弃置的牌交给一名角色。",
  ["redistribute_skill"] = "调剂盐梅",
  ["redistribute_action"] = "调剂盐梅",
  ["#redistribute-give"] = "你可将因【调剂盐梅】弃置的牌交给一名角色",
  ["#redistribute_skill"] = "选择两名手牌数不同的角色，手牌数小的目标角色摸一张牌，其余的弃置一张手牌。<br />然后若所有目标角色手牌数相同，你可将以此法弃置的牌交给一名角色",
}

local enemyAtTheGatesSkill = fk.CreateActiveSkill{
  name = "enemy_at_the_gates_skill",
  prompt = "#enemy_at_the_gates_skill",
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Self.id ~= to_select
  end,
  on_effect = function(self, room, cardEffectEvent)
    local player = room:getPlayerById(cardEffectEvent.from)
    local to = room:getPlayerById(cardEffectEvent.to)
    local cards = {}
    for _ = 1, 4, 1 do
      local id = room:getNCards(1)[1]
      table.insert(cards, id)
      room:moveCardTo(id, Card.Processing, nil, fk.ReasonJustMove, self.name)
      local card = Fk:getCardById(id)
      if card.trueName == "slash" and not player:prohibitUse(card) and not player:isProhibited(to, card) and to:isAlive() then
        room:useCard({
          card = card,
          from = player.id,
          tos = { {to.id} },
          skillName = self.name,
          extraUse = true,
        })
      end
    end
    cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.Processing end)
    room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
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
  ["enemy_at_the_gates"] = "兵临城下", -- 根据实际结算修改描述
  [":enemy_at_the_gates"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名其他角色<br /><b>效果</b>：你依次展示牌堆顶四张牌，若为【杀】，你对目标使用之；若不为【杀】，将此牌置入弃牌堆。",
  ["#enemy_at_the_gates_skill"] = "选择一名其他角色，你依次展示牌堆顶四张牌，若为【杀】，你对其使用之；若不为【杀】，将此牌置入弃牌堆",
}

return extension