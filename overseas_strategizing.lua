local extension = Package("overseas_strategizing")
extension.extensionName = "overseas"

Fk:loadTranslationTable{
  ["overseas_strategizing"] = "国际服运筹帷幄",
}

local os__wangcan = General(extension, "os__wangcan", "wei", 3)

local os__dianyi = fk.CreateTriggerSkill{
  name = "os__dianyi",
  anim_type = "negative",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and data.to == Player.NotActive
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke(self.name)
    if player:getMark("_os__dianyi-turn") > 0 then
      room:notifySkillInvoked(player, self.name)
      player:throwAllCards("h")
    else
      local num = 4 - player:getHandcardNum()
      if num > 0 then
        room:notifySkillInvoked(player, self.name, "drawcard")
        player:drawCards(num, self.name)
      elseif num < 0 then
        room:notifySkillInvoked(player, self.name)
        player.room:askForDiscard(player, num, num, false, self.name, false)
      end
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase ~= Player.NotActive and player:getMark("_os__dianyi-turn") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__dianyi-turn")
  end,
}

local os__yingji = fk.CreateViewAsSkill{
  name = "os__yingji",
  card_filter = function() return false end,
  card_num = 0,
  pattern = ".|.|.|.|.|basic,trick",
  interaction = function(self)
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(allCardNames, card.name) and (card.type == Card.TypeBasic or (card.type == Card.TypeTrick and card.sub_type ~= Card.SubtypeDelayedTrick)) and ((Fk.currentResponsePattern == nil and card.skill:canUse(Self)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) and not Self:prohibitUse(card) then
        table.insert(allCardNames, card.name)
      end
    end
    return UI.ComboBox { choices = allCardNames }
  end,
  view_as = function(self, cards)
    local choice = self.interaction.data
    if not choice then return end
    local c = Fk:cloneCard(choice)
    c.skillName = self.name
    return c
  end,
  before_use = function(self, player, use)
    player:drawCards(1, self.name)
  end,
  enabled_at_play = function(self, player)
    return player.phase == Player.NotActive and player:isKongcheng() --回合外出牌阶段……会有吗@废案曹睿
  end,
  enabled_at_response = function(self, player)
    return player.phase == Player.NotActive and player:isKongcheng()
  end,
}

local os__shanghe = fk.CreateTriggerSkill{
  name = "os__shanghe",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local not_include = true
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:isNude() then
        local id = room:askForCard(p, 1, 1, true, self.name, false)[1]
        if not_include and Fk:getCardById(id).name == "analeptic" then
          not_include = false
        end
        room:obtainCard(player, id, false, fk.ReasonGive)
      end
    end

    if not_include then
      room:recover({
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = self.name,
      })
    end
  end,
}

os__wangcan:addSkill(os__dianyi)
os__wangcan:addSkill(os__yingji)
os__wangcan:addSkill(os__shanghe)

Fk:loadTranslationTable{
  ["os__wangcan"] = "王粲",
  ["os__dianyi"] = "典仪",
  [":os__dianyi"] = "锁定技，回合结束前，若你本回合：造成过伤害，你须弃置所有手牌；未造成过伤害，你将手牌摸至或弃置至四张。",
  ["os__yingji"] = "应机",
  [":os__yingji"] = "当你于回合外需要使用/打出一张基本牌或普通锦囊牌时，若你没有手牌，你可摸一张牌并视为使用/打出此牌。",
  ["os__shanghe"] = "觞贺",
  [":os__shanghe"] = "限定技，当你进入濒死状态时，你可令所有其他角色各交给你一张牌，若其中没有【酒】，你将体力回复至1点。",
}


--[[local os__feiyi = General(extension, "os__feiyi", "shu", 3)

local os__shengxi = fk.CreateTriggerSkill{
  name = "os__shengxi",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and (player.phase == Player.Start or (player.phase == Player.Finish and player:getMark("_os__shengxi_use-turn") > 0 and player:getMark("_os__shengxi_damage-turn") == 0))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      local pile = table.clone(Card.DrawPile)
      table.insertTable(Card.DiscardPile)
      table.insertTable(Card.Void)
      local cids = {getCardByPattern(room, "redistribute", pile)}
      if #cids > 0 then
        room:moveCards({
          ids = cids,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
        })
      end
    else
      local dummy = Fk:cloneCard("slash")
      dummy:addSubcards(room:getCardsFromPileByRule("dismantlement,nullification,ex_nihilo"))
      if #dummy.subcards > 0 then
        room:obtainCard(player, dummy, false, fk.ReasonPrey)
      end
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.GameStart, fk.PreCardUse, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.GameStart then
      return table.every(player.room:getAlivePlayers(), function(p)
        return p:usedSkillTimes(self.name, Player.HistoryGame) == 0
      end)
    else return player.phase ~= Player.NotActive end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      local cids = table.filter(Fk:getAllCardIds(), function(cid)
        return Fk:getCardById(cid).name == "redistribute" 
      end)
      player.room:moveCards({
        ids = cids,
        toArea = Card.Void,
        proposer = player.id,
      })
    elseif event == fk.PreCardUse then
      player.room:addPlayerMark(player, "_os__shengxi_use-turn", 1)
    else
      player.room:addPlayerMark(player, "_os__shengxi_damage-turn", 1)
    end
  end,
}

local redistributeCardSkill = fk.CreateActiveSkill{
  name = "redistribute_skill",
  min_target_num = 1,
  max_target_num = 2,
  target_filter = function() return true end,
  on_effect = function(self, room, cardEffectEvent)
    local to = room:getPlayerById(cardEffectEvent.to)
    
  end,
}

local redistribute = fk.CreateTrickCard{
  name = "redistribute",
  skill = redistributeCardSkill,
  special_skills = { "recast" },
}

extension_cards:addCards{
  redistribute:clone(Card.Spade, 6),
  redistribute:clone(Card.Club, 6),
  redistribute:clone(Card.Heart, 6),
  redistribute:clone(Card.Diamond, 6),
}

local os__kuanji = fk.CreateTriggerSkill{
  name = "os__kuanji",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player.phase == Player.NotActive and player:hasSkill(self.name) and player:usedSkillTimes(self.name) == 0 then
      local cids = {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.toArea == Card.DiscardPile then
          cids = table.insertTable(table.map(move.moveInfo, function(info)
          return info.cardId end))
        end
      end
      if #cids > 0 then
        self.cost_data = cids
        return true
      end
    end 
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askForChoosePlayers(
      player, table.map(room:getOtherPlayers(player), function(p)
        return p.id
      end), 1, 1, "#os__kuanji-ask", self.name, true)
    if #target > 0 then
      room:fillAG(player, self.cost_data)
      --Not yet
      room:closeAG(player)
      self.cost_data = {target[1], self.cost_data}
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local dummy = Fk:cloneCard'slash'
    dummy:addSubcards(self.cost_data[2])
    player.room:obtainCard(self.cost_data[1], dummy, false, fk.ReasonGive)
  end,
}

os__feiyi:addSkill(os__shengxi)
os__feiyi:addSkill(os__kuanji)

Fk:loadTranslationTable{
  ["os__feiyi"] = "费祎",
  ["os__shengxi"] = "生息",
  [":os__shengxi"] = "准备阶段开始时，你可从游戏外、牌堆或弃牌堆中获得一张【调剂盐梅】。结束阶段开始时，若你于此回合内使用过牌且没有造成过伤害，你可从牌堆中获得一张智囊并摸一张牌。" ..
  "<br></br><font color=\"grey\">#【<b>调剂盐梅</b>】（♠6/♣6/♥6/♦6）<br></br>出牌阶段，对两名手牌数不同的角色使用。手牌较多的目标角色弃置一张牌，手牌较少的目标角色摸一张牌。然后若这两名角色手牌数相同，你可将以此法弃置的牌交给一名角色。<br></br>重铸：出牌阶段，你可将此牌置入弃牌堆，摸一张牌。" ..
  "<br></br>#\"<b>智囊</b>\"<br></br>过河拆桥、无懈可击、无中生有（线下可由面杀玩家自行约定选取三种锦囊）</font>",
  ["os__kuanji"] = "宽济",
  [":os__kuanji"] = "每回合限一次，当你的牌非因使用而置入弃牌堆后，你可令一名其他角色获得其中的任意张牌。",

  ["#os__kuanji-ask"] = "宽济：你可令一名其他角色获得其中的任意张牌。",
}]]

local os__chenzhen = General(extension, "os__chenzhen", "shu", 3)

local os__muyue = fk.CreateActiveSkill{
  name = "os__muyue",
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = function() return Self:getMark("os__muyue_status") + 1 end,
  card_filter = function(self, to_select, selected)
    return #selected < Self:getMark("os__muyue_status") + 1
  end,
  interaction = function(self)
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(allCardNames, card.name) and (card.type == Card.TypeBasic or (card.type == Card.TypeTrick and card.sub_type ~= Card.SubtypeDelayedTrick)) then
        table.insert(allCardNames, card.name)
      end
    end
    return UI.ComboBox { choices = allCardNames }
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and self.interaction.data
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local name = self.interaction.data
    if not name then return false end
    if #effect.cards > 0 and Fk:getCardById(effect.cards[1]).trueName == name then 
      room:setPlayerMark(player, "os__muyue_status", -1)
    else
      room:setPlayerMark(player, "os__muyue_status", 0)
    end
    room:throwCard(effect.cards, self.name, player)
    local dummy = Fk:cloneCard("slash")
    dummy:addSubcards(room:getCardsFromPileByRule(name))
    if #dummy.subcards > 0 then
      room:obtainCard(target, dummy, false, fk.ReasonPrey)
    end
  end,
}

local os__chayi = fk.CreateTriggerSkill{
  name = "os__chayi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askForChoosePlayers(
      player,
      table.map(room:getOtherPlayers(player), function(p)
        return p.id
      end),
      1,
      1,
      "#os__chayi-ask",
      self.name,
      true
    )

    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(self.cost_data)
    local choices = {"os__chayi_discard"}
    if target:getHandcardNum() > 0 then table.insert(choices, 1, "os__chayi_show") end
    local choice = room:askForChoice(target, choices, self.name, "#os__chayi-choice")
    local cids = target:getCardIds(Player.Hand)
    room:addPlayerMark(target, "_os__chayi", 1)
    if choice == "os__chayi_show" then
      target:showCards(cids)
      room:setPlayerMark(target, "@os__chayi_show", tostring(#cids)) --如果为0，所以要用string
    else
      room:setPlayerMark(target, "@os__chayi_discard", tostring(#cids))
      room:setPlayerMark(target, "_os__chayi_discarded", 0)
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("_os__chayi") > 0 and data.from == Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "_os__chayi", 0)
    if player:getMark("@os__chayi_show") ~= 0 then
      if player:getHandcardNum() ~= tonumber(player:getMark("@os__chayi_show")) then
        room:setPlayerMark(player, "@@os__chayi_discard", 1)
        room:setPlayerMark(target, "_os__chayi_discarded", 0)
      end
      room:setPlayerMark(player, "@os__chayi_show", 0)
    end
    if player:getMark("@os__chayi_discard") ~= 0 then
      if player:getHandcardNum() ~= tonumber(player:getMark("@os__chayi_discard")) then
        player:showCards(player:getCardIds(Player.Hand))
      end
      room:setPlayerMark(player, "@@os__chayi_discard", 1)
      --room:setPlayerMark(player, "@os__chayi_discard", 0)
    end
  end,
}

local os__chayi_using = fk.CreateTriggerSkill{
  name = "#os__chayi_using",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("_os__chayi") > 0 and (player:getMark("@os__chayi_discard") ~= 0 or player:getMark("@@os__chayi_discard") > 0) and player:getMark("_os__chayi_discarded") < 1
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "_os__chayi_discarded", 1)
    local cids = table.clone(player:getCardIds(Player.Hand))
    table.insertTable(cids, player:getCardIds(Player.Equip))
    if table.find(cids, function(id)
      return not player:prohibitDiscard(Fk:getCardById(id))
    end) then
      room:askForDiscard(player, 1, 1, true, self.name, false, nil, "#os__chayi-discard")
    end
    room:setPlayerMark(player, "@@os__chayi_discard", 0)
  end,
}
os__chayi:addRelatedSkill(os__chayi_using)

os__chenzhen:addSkill(os__muyue)
os__chenzhen:addSkill(os__chayi)

Fk:loadTranslationTable{
  ["os__chenzhen"] = "陈震",
  ["os__muyue"] = "睦约",
  [":os__muyue"] = "出牌阶段限一次，你选择一个基本牌或普通锦囊牌的牌名，弃置一张牌并选择一名角色，令其从牌堆中获得该牌名的牌。若你弃置的牌的牌名与该牌名相同，你下次发动此技能无需弃牌。",
  ["os__chayi"] = "察异",
  [":os__chayi"] = "结束阶段开始时，你可令一名其他角色选择一项：1. 展示其手牌；2. 其下一次使用牌时弃置一张牌。其下回合开始后，若其手牌数与你选择其时不同，则其执行另一项。",

  ["#os__chayi-ask"] = "你可对一名其他角色发动“察异”",
  ["#os__chayi-choice"] = "察异：你的下回合结束前，若你的手牌数与此时不同，你执行此时选择的另一项",
  ["os__chayi_show"] = "展示手牌",
  ["os__chayi_discard"] = "下一次使用牌时弃置一张牌",
  ["@os__chayi_show"] = "察异 展示",
  ["@os__chayi_discard"] = "察异 弃牌",
  ["#os__chayi-discard"] = "察异：你使用了一张牌，须弃置一张牌",
  ["@@os__chayi_discard"] = "察异 弃牌",
  ["#os__chayi_using"] = "察异",
}

local os__huojun = General(extension, "os__huojun", "shu", 4)

local os__sidai = fk.CreateViewAsSkill{
  name = "os__sidai",
  anim_type = "offensive",
  pattern = "slash",
  frequency = Skill.Limited,
  can_use = function(self, player) --没有考虑装备区里的
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and not table.every(player.player_cards[Player.Hand], function(cid)
      return Fk:getCardById(cid).type ~= Card.TypeBasic
    end)
  end,
  card_filter = function() return false end,
  view_as = function(self, cards)
    local c = Fk:cloneCard("slash")
    c:addSubcards(table.filter(Self.player_cards[Player.Hand], function(cid)
      return Fk:getCardById(cid).type == Card.TypeBasic
    end))
    c.skillName = self.name
    return c
  end,
  before_use = function(self, player, use)
    local included_basic_cards = {}
    for _, id in ipairs(use.card.subcards) do
      table.insertIfNeed(included_basic_cards, Fk:getCardById(id).name)
    end
    use.extra_data = use.extra_data or {}
    use.extra_data.os__sidaiBuff = included_basic_cards
    use.card.extra_data = use.card.extra_data or {} --闪用的是这里……为什么
    use.card.extra_data.os__sidaiBuff = included_basic_cards
  end,
  enabled_at_play = function(self, player) --权宜
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and not table.every(player.player_cards[Player.Hand], function(cid)
      return Fk:getCardById(cid).type ~= Card.TypeBasic
    end)
  end,
  enabled_at_response = function(self, player) return false end,
}
local os__sidai_tm = fk.CreateTargetModSkill{
  name = "#os__sidai_tm",
  residue_func = function(self, player, skill, scope, card)
    return skill.trueName == "slash_skill" and card and table.contains(card.skillNames, "os__sidai") and 999 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return card and table.contains(card.skillNames, "os__sidai") and 999 or 0
  end,
}
local os__sidai_buff = fk.CreateTriggerSkill{
  name = "#os__sidai_buff",
  mute = true,
  refresh_events = {fk.DamageCaused, fk.Damage, fk.TargetConfirmed},
  can_refresh = function(self, event, target, player, data)
    if target ~= player or not data.card or not table.contains(data.card.skillNames, "os__sidai") then return false end
    if event == fk.TargetConfirmed then
      return table.contains((data.card.extra_data or {}).os__sidaiBuff, "jink")
    else
      local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      local os__sidaiBuff = parentUseData and (parentUseData.data[1].extra_data or {}).os__sidaiBuff or {}
      if event == fk.DamageCaused then
        return table.contains(os__sidaiBuff, "analeptic") 
      else
        return table.contains(os__sidaiBuff, "peach") and not data.to.dead
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      data.damage = data.damage * 2
    elseif event == fk.Damage then
      player.room:changeMaxHp(data.to, -1)
    elseif #player.room:askForDiscard(player, 1, 1, true, self.name, true, ".|.|.|.|.|basic", "#os__sidai_nojink") == 0 then
      data.disresponsive = true
    end
  end,
}
os__sidai:addRelatedSkill(os__sidai_tm)
os__sidai:addRelatedSkill(os__sidai_buff)

local os__jieyu = fk.CreateTriggerSkill{
  name = "os__jieyu",
  events = {fk.EventPhaseStart, fk.Damaged},
  anim_type = "defensive", --?
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self.name) or player:usedSkillTimes(self.name, Player.HistoryRound) > 0 or player:isKongcheng() then return false end
    if event == fk.EventPhaseStart then
      return player.phase == Player.Finish
    else
      return player:getMark("_os__jieyu_dmg-round") == 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:throwAllCards("h")
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(allCardNames, card.name) and card.type == Card.TypeBasic then
        table.insert(allCardNames, card.name)
      end
    end
    if #allCardNames == 0 then return false end
    local dummy = Fk:cloneCard("slash")
    table.forEach(allCardNames, function(name)
      dummy:addSubcards(room:getCardsFromPileByRule(name, 1, "discardPile"))
    end)
    if #dummy.subcards > 0 then
      room:obtainCard(player, dummy, false, fk.ReasonPrey)
    end
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os__jieyu_dmg-round") < 2
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__jieyu_dmg-round")
  end,
}

os__huojun:addSkill(os__sidai)
os__huojun:addSkill(os__jieyu)

Fk:loadTranslationTable{
  ["os__huojun"] = "霍峻",
  ["os__sidai"] = "伺怠",
  [":os__sidai"] = "限定技，出牌阶段，你可将所有基本牌当【杀】使用（无次数和距离限制）。若这些牌中有：【酒】，此【杀】造成伤害时，伤害翻倍；【桃】，此【杀】造成伤害后，受到伤害角色减1点体力上限；【闪】，此【杀】的目标需弃置一张基本牌，否则不能响应。",
  ["os__jieyu"] = "竭御",
  [":os__jieyu"] = "每轮限一次，结束阶段开始时或每轮第一次受到伤害后，你可弃置所有手牌，然后从弃牌堆中获得不同牌名的基本牌各一张。",

  ["#os__sidai_buff"] = "伺怠",
  ["#os__sidai_nojink"] = "伺怠：弃置一张基本牌，否则不能响应此【杀】",
}


local os__xujing = General(extension, "os__xujing", "shu", 3)

local os__boming = fk.CreateActiveSkill{
  name = "os__boming",
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = function() return true end,
  card_num = 1,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    room:moveCards({
      ids = effect.cards,
      from = effect.from,
      to = effect.tos[1],
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonGive,
      proposer = effect.from,
      skillName = self.name,
    })
  end,
}
local os__boming_draw = fk.CreateTriggerSkill{
  name = "#os__boming_draw",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and player:getMark("_os__boming_card-turn") > 1
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player.phase ~= Player.NotActive then
      local num = 0
      for _, move in ipairs(data) do
        local target = move.to and player.room:getPlayerById(move.to) or nil
        if target and move.to ~= player.id and move.toArea == Card.PlayerHand then
          num = num + #move.moveInfo
        end
      end
      if num > 0 then
        self.cost_data = num
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__boming_card-turn", self.cost_data)
  end,
}
os__boming:addRelatedSkill(os__boming_draw)

local os__ejian = fk.CreateTriggerSkill{
  name = "os__ejian",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      local target = move.to and player.room:getPlayerById(move.to) or nil
      local from = move.from and player.room:getPlayerById(move.from) or nil
      if from and from == player and from:hasSkill(self.name) and target and move.to ~= player.id and move.toArea == Card.PlayerHand then
        local cardType = {}
        local fromCard = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          table.insertIfNeed(cardType, Fk:getCardById(id):getTypeString())
          table.insert(fromCard, id)
        end
        local cids = target:getCardIds(Player.Hand)
        table.insertTable(cids, target:getCardIds(Player.Equip))
        local cards = {}
        for _, id in ipairs(cids) do
          if table.contains(cardType, Fk:getCardById(id):getTypeString()) and not table.contains(fromCard, id) then
            table.insert(cards, id)
          end
        end
        if #cards > 0 then
          self.cost_data = {move.to, cards}
          return true --同时移动牌中同时给两名其他角色就有问题，怎么解决
        end
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(self.cost_data[1])
    local cards = self.cost_data[2]
    if room:askForChoice(target, {"os__ejian_discard", "os__ejian_damage"}, self.name) == "os__ejian_damage" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    else
      room:throwCard(cards, self.name, target)
    end
  end,
}

os__xujing:addSkill(os__boming)
os__xujing:addSkill(os__ejian)

Fk:loadTranslationTable{
  ["os__xujing"] = "许靖",
  ["os__boming"] = "博名",
  [":os__boming"] = "出牌阶段限两次，你可以将一张牌交给一名其他角色。结束阶段开始时，若其他角色于此回合内获得的牌数大于1，你摸两张牌。",
  ["os__ejian"] = "恶荐",
  [":os__ejian"] = "当其他角色获得你的牌后，若其有除此牌以外的牌与此牌类别相同的牌，你可令其选择：1. 弃置这些牌；2. 受到你造成的1点伤害。",

  ["#os__boming_draw"] = "博名",
  ["os__ejian_discard"] = "弃置除获得的牌外和获得的牌类别相同的牌",
  ["os__ejian_damage"] = "受到1点伤害",
}

local os__wujing = General(extension, "os__wujing", "wu", 4)

local os__fenghan = fk.CreateTriggerSkill{
  name = "os__fenghan",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return 
      target == player and
      player:hasSkill(self.name) and
      data.firstTarget and player:usedSkillTimes(self.name) < 1 and data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local num = #AimGroup:getAllTargets(data.tos)
    
    local result = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), function(p)
        return p.id
      end), 1, num, "#os__fenghan-ask:::" .. num, self.name, true)
    if #result > 0 then
      self.cost_data = result
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = self.cost_data
    for _, id in ipairs(targets) do
      room:getPlayerById(id):drawCards(1, self.name)
    end
  end,
}

local os__congji = fk.CreateTriggerSkill{
  name = "os__congji",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player.phase == Player.NotActive and player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Red then
              return true
            end
          end
        end
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askForChoosePlayers(
      player,
      table.map(room:getOtherPlayers(player), function(p)
        return p.id
      end),
      1,
      1,
      "#os__congji-ask",
      self.name,
      true
    )

    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local dummy = Fk:cloneCard'slash'
    local cids = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).color == Card.Red then
            table.insert(cids, info.cardId)
          end
        end
      end
    end
    dummy:addSubcards(cids)
    player.room:obtainCard(self.cost_data, dummy, false, fk.ReasonGive)
  end,
}

os__wujing:addSkill(os__fenghan)
os__wujing:addSkill(os__congji)

Fk:loadTranslationTable{
  ["os__wujing"] = "吴景",
  ["os__fenghan"] = "锋悍",
  [":os__fenghan"] = "每回合限一次，当你使用【杀】或伤害锦囊牌指定第一个目标后，你可令至多X名角色摸一张牌（X为目标数）。",
  ["os__congji"] = "从击",
  [":os__congji"] = "当你于回合外弃置牌后，你可将其中的所有红色牌交给一名其他角色。",

  ["#os__fenghan-ask"] = "锋悍：你可令至多 %arg 名角色各摸一张牌",
  ["#os__congji-ask"] = "从击：你可将弃置的牌中所有的红色牌交给一名其他角色",
}

local os__chenwudongxi = General(extension, "os__chenwudongxi", "wu", 4)
local os__yilie = fk.CreateTriggerSkill{
  name = "os__yilie",
  anim_type = "offensive",
  events = {fk.EventPhaseStart, fk.CardUseFinished, fk.TargetSpecified},    
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player == target and player:hasSkill(self.name) and player.phase == Player.Play
    elseif event == fk.CardUseFinished then --失去技能有问题!
      local use = data
      if use.card.name == "jink" and use.toCard and use.toCard.trueName == "slash" and 
      player:getMark("@os__yilie") ~= 0 and string.find(player:getMark("@os__yilie"), "draw") then
        local effect = use.responseToEvent
        return effect.from == player.id
      end
    else
      if target == player and player:hasSkill(self.name) and
      data.card.trueName == "slash" and 
      player:getMark("@os__yilie") ~= 0 and string.find(player:getMark("@os__yilie"), "draw") and data.to then
        local to = player.room:getPlayerById(data.to)
        return to.chained
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local choices = {"os__yilie_times", "os__yilie_draw", "beishui_os__yilie" ,"Cancel"}
      local choice = player.room:askForChoice(player, choices, self.name)
      if choice ~= "Cancel" then
        self.cost_data = choice
        return true
      end
      return false
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      local choice = self.cost_data
      if choice == "beishui_os__yilie" then
        room:setPlayerMark(player, "@os__yilie", "yl_times_draw")
        room:loseHp(player, 1, self.name)
      elseif choice == "os__yilie_times" then
        room:setPlayerMark(player, "@os__yilie", "yl_times")
      elseif choice == "os__yilie_draw" then
        room:setPlayerMark(player, "@os__yilie", "yl_draw")
      end
    else
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("@os__yilie") ~= 0 and data.from == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@os__yilie", 0)
  end,
}
local os__yilieBuff = fk.CreateTargetModSkill{
  name = "#os__yilieBuff",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return (player:getMark("@os__yilie") ~= 0 and string.find(player:getMark("@os__yilie"), "times")) and 1 or 0
    end
  end,
}

local os__fenming = fk.CreateTriggerSkill{
  name = "os__fenming",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and
      player.phase == Player.Start and not table.every(player.room:getAlivePlayers(), function(p)
        return (p:isNude() and p.chained)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askForChoosePlayers(
      player,
      table.map(
        table.filter(room:getAlivePlayers(), function(p)
          return (not p:isNude() or not p.chained)
        end),
        function(p)
          return p.id
        end
      ),
      1,
      1,
      "#os__fenming-ask",
      self.name
    )

    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(self.cost_data)
    local choices = {"os__fenming_chained", "beishui_os__fenming"}
    if not target:isNude() then table.insert(choices, 1, "os__fenming_discard") end
    local choice = room:askForChoice(player, choices, self.name)
    
    if choice == "beishui_os__fenming" then
      if not player.chained then player:setChainState(true) end
    end
    if choice ~= "os__fenming_chained" and not target:isNude() then
      local card = room:askForCardChosen(player, target, "he", self.name)
      room:throwCard(card, self.name, target, player)
    end
    if choice ~= "os__fenming_discard" and not target.chained then
      target:setChainState(true)
    end
  end,
}
os__yilie:addRelatedSkill(os__yilieBuff)

os__chenwudongxi:addSkill(os__yilie)
os__chenwudongxi:addSkill(os__fenming)

Fk:loadTranslationTable{
  ["os__chenwudongxi"] = "陈武董袭",
  ["os__yilie"] = "毅烈",
  [":os__yilie"] = "出牌阶段开始时，你可选择此阶段内：1.使用【杀】的次数上限+1；2.当你使用的【杀】指定处于连环状态的角色为目标后，或被【闪】抵消后，摸一张牌；背水：你失去1点体力。",
  ["os__fenming"] = "奋命",
  [":os__fenming"] = "准备阶段，你可选择一名角色并选择一项：1.你弃置其一张牌；2. 其进入连环状态；背水：你进入连环状态。",

  ["os__yilie_times"] = "使用【杀】的次数上限+1", 
  ["os__yilie_draw"] = "当你使用的【杀】指定处于连环状态的角色为目标后，或被【闪】抵消后，摸一张牌", 
  ["@os__yilie"] = "毅烈",
  ["yl_times_draw"] = "摸牌 多出杀",
  ["yl_times"] = "多出杀",
  ["yl_draw"] = "摸牌",

  ["beishui_os__yilie"] = "背水：你失去1点体力",
  ["#os__fenming-ask"] = "你可对一名角色发动“奋命”",
  ["beishui_os__fenming"] = "背水：你进入连环状态",
  ["os__fenming_discard"] = "你弃置其牌",
  ["os__fenming_chained"] = "其进入连环状态",
}

Fk:loadTranslationTable{
  ["os__sunyi"] = "孙翊",
  ["os__zaoli"] = "躁厉",
  [":os__zaoli"] = "锁定技，出牌阶段，你只能使用或打出本回合获得的手牌。出牌阶段开始时，你弃置区域内所有装备牌并弃置任意张手牌，然后摸X张牌，并从牌堆中将你弃置牌中相同子类别的装备牌置入装备区，若你以此法置入装备区的牌大于两张，你失去1点体力。（X为你以此法弃置的牌的总数）",
}

return extension
