local extension = Package("overseas_sp2")
extension.extensionName = "overseas"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["overseas_sp2"] = "国际服专属2",
  ["os_xing"] = "国际星",
}

--抄自心变佬
local function getUseExtraTargets(room, data, bypass_distances, remove)
  if not (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) then return {} end
  if data.card.skill:getMinTargetNum() > 1 then return {} end --stupid collateral
  local tos = {}
  local current_targets = TargetGroup:getRealTargets(data.tos)
  if remove then tos = current_targets end
  for _, p in ipairs(room.alive_players) do
    if not table.contains(current_targets, p.id) and not room:getPlayerById(data.from):isProhibited(p, data.card) then
      if data.card.skill:modTargetFilter(p.id, {}, data.from, data.card, bypass_distances) then
        table.insert(tos, p.id)
      end
    end
  end
  return tos
end

local os__godguanyu = General(extension, "os__godguanyu", "god", 4)

local os__wushen = fk.CreateFilterSkill{
  name = "os__wushen",
  anim_type = "offensive",
  card_filter = function(self, to_select, player)
    return player:hasSkill(self) and to_select.suit == Card.Heart and table.contains(player.player_cards[Player.Hand], to_select.id)
  end,
  view_as = function(self, to_select)
    local card = Fk:cloneCard("slash", Card.Heart, to_select.number)
    card.skillName = "os__wushen"
    return card
  end,
}
local os__wushen_buff = fk.CreateTargetModSkill{
  name = "#os__wushen_buff",
  bypass_times = function(self, player, skill, scope, card)
    return player:hasSkill(os__wushen) and card and card.trueName == "slash" and card.suit == Card.Heart and scope == Player.HistoryPhase
  end,
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill(os__wushen) and card and card.trueName == "slash" and card.suit == Card.Heart
  end,
}
local os__wushen_trg = fk.CreateTriggerSkill{
  name = "#os__wushen_trg",
  anim_type = "offensive",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card.trueName == "slash" then
      if event == fk.CardUsing then
        local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data[1]
          return use.from == player.id and use.card.trueName == "slash"
        end, Player.HistoryPhase)
        return #events == 1 and events[1].id == player.room.logic:getCurrentEvent().id
      elseif data.card.suit == Card.Heart then
        local targets = {}
        local availableTargets = U.getUseExtraTargets(player.room, data, true, false)
        for _, p in ipairs(player.room:getOtherPlayers(player)) do
          if p:getMark("@os__nightmare") > 0 and not table.contains(TargetGroup:getRealTargets(data.tos), p.id) and table.contains(availableTargets, p.id) then
            table.insert(targets, p.id)
          end
        end
        if #targets > 0 then
          self.cost_data = targets
          return true
        end
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(player.room.alive_players) do
        table.insertIfNeed(data.disresponsiveList, p.id)
      end
    else
      room:notifySkillInvoked(player, "os__wushen", "offensive")
      local targets = self.cost_data
      room:doIndicate(player.id, targets)
      for _, pid in ipairs(targets) do
        table.insert(data.tos, {pid})
      end
      room:sendLog{
        type = "#AddTargetsBySkill",
        from = player.id,
        to = targets,
        arg = "os__wushen",
        arg2 = data.card:toLogString()
      }
    end
  end,
}
os__wushen:addRelatedSkill(os__wushen_buff)
os__wushen:addRelatedSkill(os__wushen_trg)

local os__wuhun = fk.CreateTriggerSkill{
  name = "os__wuhun",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.Damage, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name, false, true) then
      if event == fk.Damaged then
        return data.from and not data.from.dead and not player.dead
      elseif event == fk.Damage then
        return data.to and data.to:getMark("@os__nightmare") > 0 and not data.to.dead and not player.dead
      else
        local availableTargets = table.map(player.room:getOtherPlayers(player), function(p)
          return p:getMark("@os__nightmare") > 0
        end)
        if #availableTargets > 0 then
          return true
        end
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      room:addPlayerMark(data.from, "@os__nightmare", data.damage)
    elseif event == fk.Damage then
      room:addPlayerMark(data.to, "@os__nightmare", 1)
    elseif room:askForChoice(player, {"os__wuhun_judge", "Cancel"}, self.name) == "os__wuhun_judge" then
      local judge = {
        who = player,
        reason = self.name,
        pattern = "peach,god_salvation|.",
      }
      room:judge(judge)
      if judge.card.name == "peach" or judge.card.name == "god_salvation" then return false end
      local availableTargets = table.map(
        table.filter(player.room:getOtherPlayers(player), function(p)
          return (p:getMark("@os__nightmare") > 0)
        end),
        Util.IdMapper
      )
      if #availableTargets == 0 then return false end
      local targets = room:askForChoosePlayers(player, availableTargets, 1, 99, "#os__wuhun-targets", self.name, false)
      if #targets > 0 then
        room:sortPlayersByAction(targets)
        for _, id in ipairs(targets) do
          local p = room:getPlayerById(id)
          room:loseHp(p, p:getMark("@os__nightmare"), self.name)
        end
      end
    end
  end,
}

os__godguanyu:addSkill(os__wushen)
os__godguanyu:addSkill(os__wuhun)


Fk:loadTranslationTable{
  ["os__godguanyu"] = "神关羽",
  ["#os__godguanyu"] = "鬼神再临",
  ["illustrator:os__godguanyu"] = "DH", -- 史诗皮 链狱鬼神

  ["os__wushen"] = "武神",
  [":os__wushen"] = "锁定技，①你的红桃手牌视为【杀】。②你使用红桃【杀】无距离和次数限制且额外选择所有有“梦魇”的角色为目标。③你于每个阶段内使用的第一张【杀】不能被响应。",
  ["#os__wushen_trg"] = "武神",
  ["os__wuhun"] = "武魂",
  [":os__wuhun"] = "锁定技，①当你受到1点伤害后，伤害来源获得1枚“梦魇”。②当你对有“梦魇”的角色造成伤害后，其获得1枚“梦魇”。③当你死亡时，你可判定：若结果不为【桃】或【桃园结义】，你选择至少一名有“梦魇”的角色，这些角色失去X点体力（X为其“梦魇”数）。",

  ["@os__nightmare"] = "梦魇",
  ["os__wuhun_judge"] = "判定，若结果不为【桃】或【桃园结义】，你选择至少一名有“梦魇”的角色失去X点体力（X为其“梦魇”数）",
  ["#os__wuhun-targets"] = "武魂：选择至少一名有“梦魇”的角色，各失去X点体力（X为其“梦魇”数）",

  ["$os__wushen1"] = "生当啖汝之肉！",
  ["$os__wushen2"] = "死当追汝之魂！",
  ["$os__wuhun1"] = "追你到天涯海角！",
  ["$os__wuhun2"] = "我看你怎么跑！",
  ["~os__godguanyu"] = "我还会回来的……",
}

local os__godlvmeng = General(extension, "os__godlvmeng", "god", 3)

local os__shelie = fk.CreateTriggerSkill{
  name = "os__shelie",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card_ids = room:getNCards(5)
    local get, throw = {}, {}
    room:moveCards({
      ids = card_ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonPut,
    })
    table.forEach(room.players, function(p)
      room:fillAG(p, card_ids)
    end)
    while true do
      local card_suits = {}
      table.forEach(get, function(id)
        table.insert(card_suits, Fk:getCardById(id).suit)
      end)
      for i = #card_ids, 1, -1 do
        local id = card_ids[i]
        if table.contains(card_suits, Fk:getCardById(id).suit) then
          room:takeAG(player, id) --?
          table.insert(throw, id)
          table.removeOne(card_ids, id)
        end
      end
      if #card_ids == 0 then break end
      local card_id = room:askForAG(player, card_ids, false, self.name)
      room:takeAG(player, card_id)
      table.insert(get, card_id)
      table.removeOne(card_ids, card_id)
      if #card_ids == 0 then break end
    end
    room:closeAG()
    if #get > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      room:obtainCard(player.id, dummy, true, fk.ReasonPrey)
    end
    if #throw > 0 then
      room:moveCards({
        ids = throw,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
    end
    return true
  end,
}
local os__shelie_extra = fk.CreateTriggerSkill{
  name = "#os__shelie_extra",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__shelie.name) and player.phase == Player.Finish and type(player:getMark("@os__shelie-turn")) == "table" and #player:getMark("@os__shelie-turn") == 4 and player:usedSkillTimes(self.name, Player.HistoryRound) < 1
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"phase_draw", "phase_play"}
    if player:getMark("_os__shelie") ~= 0 then
      table.removeOne(choices, player:getMark("_os__shelie"))
    end
    self.cost_data = player.room:askForChoice(player, choices, self.name, "#os__shelie_extra-ask")
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:sendLog{
      type = "#os__shelie_extra_log",
      from = player.id,
      arg = self.name,
      arg2 = self.cost_data,
    }
    room:setPlayerMark(player, "_os__shelie", self.cost_data)
    player:gainAnExtraPhase(self.cost_data == "phase_draw" and Player.Draw or Player.Play)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and player.phase ~= Player.NotActive and data.card.suit ~= Card.NoSuit
  end,
  on_refresh = function(self, event, target, player, data)
    local suitsRecorded = type(player:getMark("@os__shelie-turn")) == "table" and player:getMark("@os__shelie-turn") or {}
    table.insertIfNeed(suitsRecorded, data.card:getSuitString(true))
    player.room:setPlayerMark(player, "@os__shelie-turn", suitsRecorded)
  end,
}
os__shelie:addRelatedSkill(os__shelie_extra)

local os__gongxin = fk.CreateActiveSkill{
  name = "os__gongxin",
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cids = target:getCardIds(Player.Hand)
    local card_suits = {}
    table.forEach(cids, function(id)
      table.insertIfNeed(card_suits, Fk:getCardById(id).suit)
    end)
    local num = #card_suits
    local cards, choice = U.askforChooseCardsAndChoice(player, cids, {"os__gongxin_discard", "os__gongxin_put"}, self.name, "#os__gongxin-ask::" .. target.id, {"Cancel"})
    if #cards == 0 then return end
    target:showCards(cards)
    if choice == "os__gongxin_discard" then
      room:throwCard(cards, self.name, target, player)
    else
      room:moveCardTo(cards, Card.DrawPile, nil, fk.ReasonPut, self.name, nil, false)
    end
    card_suits = {}
    cids = target:getCardIds(Player.Hand)
    table.forEach(cids, function(id)
      table.insertIfNeed(card_suits, Fk:getCardById(id).suit)
    end)
    local num2 = #card_suits
    if num > num2 and not player.dead and not target.dead then
      room:setPlayerMark(target, "@@os__gongxin_dr-turn", 1)
      room:setPlayerMark(player, "_os__gongxin-turn", 1)
    end
  end,
}
local os__gongxin_dr = fk.CreateTriggerSkill{
  name = "#os__gongxin_dr",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("_os__gongxin-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    local room = player.room
    for _, target in ipairs(room.alive_players) do
      if target:getMark("@@os__gongxin_dr-turn") > 0 then
        table.insertIfNeed(data.disresponsiveList, target.id)
        room:setPlayerMark(target, "@@os__gongxin_dr-turn", 0)
      end
    end
    room:setPlayerMark(player, "_os__gongxin-turn", 0)
  end,
}
os__gongxin:addRelatedSkill(os__gongxin_dr)

os__godlvmeng:addSkill(os__shelie)
os__godlvmeng:addSkill(os__gongxin)

Fk:loadTranslationTable{
  ["os__godlvmeng"] = "神吕蒙",
  ["os__shelie"] = "涉猎",
  [":os__shelie"] = "①摸牌阶段，你可改为亮出牌堆顶的五张牌，然后获得其中每种花色的牌各一张。②每轮限一次，结束阶段开始时，若你本回合使用过四种花色的牌，你选择执行一个额外的摸牌阶段或出牌阶段且不能与上次选择相同。",
  ["os__gongxin"] = "攻心",
  [":os__gongxin"] = "出牌阶段限一次，你可观看一名其他角色的手牌，然后你可展示其中一张牌并选择一项：1. 你弃置其此牌；2. 将此牌置于牌堆顶，然后若其手牌中花色数因此减少，其不能响应你本回合使用的下一张牌。",

  ["@os__shelie-turn"] = "涉猎",
  ["#os__shelie_extra"] = "涉猎",
  ["#os__shelie_extra-ask"] = "涉猎：选择执行一个额外的阶段",
  ["#os__shelie_extra_log"] = "%from 发动“%arg”，执行一个额外的 %arg2",
  ["os__gongxin_discard"] = "弃置所选牌",
  ["os__gongxin_put"] = "将所选牌置于牌堆顶",
  ["#os__gongxin-ask"] = "攻心：观看%dest的手牌，可展示其中一张牌并选择一项",
  ["@@os__gongxin_dr-turn"] = "攻心",
  ["#os__gongxin_dr"] = "攻心",

  ["$os__shelie1"] = "尘世之间，岂有吾所未闻之事？",
  ["$os__shelie2"] = "往事皆知，未来尽料。",
  ["$os__gongxin1"] = "敌将虽有破军之勇，然未必有弑神之心。",
  ["$os__gongxin2"] = "知敌所欲为，则此战已尽在掌握。",
  ["~os__godlvmeng"] = "吾能已通神，却难逆天命啊……",
}

local os__gundameng = General(extension, "os__gundameng", "god", 3)
--os__gundameng.hidden = true

local gundam__shelie = fk.CreateTriggerSkill{
  name = "gundam__shelie",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card_ids = room:getNCards(5)
    local get, throw = {}, {}
    room:moveCards({
      ids = card_ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonPut,
    })
    table.forEach(room.players, function(p)
      room:fillAG(p, card_ids)
    end)
    while true do
      local card_suits = {}
      table.forEach(get, function(id)
        table.insert(card_suits, Fk:getCardById(id).suit)
      end)
      for i = #card_ids, 1, -1 do
        local id = card_ids[i]
        if table.contains(card_suits, Fk:getCardById(id).suit) then
          room:takeAG(player, id)
          table.insert(throw, id)
          table.removeOne(card_ids, id)
        end
      end
      if #card_ids == 0 then break end
      local card_id = room:askForAG(player, card_ids, false, self.name)
      room:takeAG(player, card_id)
      table.insert(get, card_id)
      table.removeOne(card_ids, card_id)
      if #card_ids == 0 then break end
    end
    room:closeAG()
    if #get > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      room:obtainCard(player.id, dummy, true, fk.ReasonPrey)
    end
    if #throw > 0 then
      room:moveCards({
        ids = throw,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
    end
    return true
  end,
}
local gundam__shelie_extra = fk.CreateTriggerSkill{
  name = "#gundam__shelie_extra",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gundam__shelie.name) and player.phase == Player.Finish and player:getMark("@gundam__shelie-turn") ~= 0 and #player:getMark("@gundam__shelie-turn") >= player.hp and player:usedSkillTimes(self.name, Player.HistoryRound) < 1
  end,
  on_cost = function(self, event, target, player, data)
    self.cost_data = player.room:askForChoice(player, {"phase_draw", "phase_play"}, self.name, "#gundam__shelie_extra-ask")
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:sendLog{
      type = "#gundam__shelie_extra_log",
      from = player.id,
      arg = self.name,
      arg2 = self.cost_data,
    }
    player:gainAnExtraPhase(self.cost_data == "phase_draw" and Player.Draw or Player.Play)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and player.phase ~= Player.NotActive and data.card.suit ~= Card.NoSuit
  end,
  on_refresh = function(self, event, target, player, data)
    local suitsRecorded = type(player:getMark("@gundam__shelie-turn")) == "table" and player:getMark("@gundam__shelie-turn") or {}
    table.insertIfNeed(suitsRecorded, data.card:getSuitString(true))
    player.room:setPlayerMark(player, "@gundam__shelie-turn", suitsRecorded)
  end,
}
gundam__shelie:addRelatedSkill(gundam__shelie_extra)

local gundam__gongxin = fk.CreateActiveSkill{
  name = "gundam__gongxin",
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cids = target:getCardIds(Player.Hand)
    local card_suits = {}
    table.forEach(cids, function(id)
      table.insertIfNeed(card_suits, Fk:getCardById(id).suit)
    end)
    local num = #card_suits
    local cards, choice = U.askforChooseCardsAndChoice(player, cids, {"gundam__gongxin_discard", "gundam__gongxin_put"}, self.name, "#gundam__gongxin-ask::" .. target.id, {"Cancel"})
    if #cards == 0 then return end
    target:showCards(cards)
    if choice == "gundam__gongxin_discard" then
      room:throwCard(cards, self.name, target, player)
    else
      room:moveCardTo(cards, Card.DrawPile, nil, fk.ReasonPut, self.name, nil, false)
    end
    card_suits = {}
    cids = target:getCardIds(Player.Hand)
    table.forEach(cids, function(id)
      table.insertIfNeed(card_suits, Fk:getCardById(id).suit)
    end)
    local num2 = #card_suits
    if num > num2 and not player.dead and not target.dead then
      local choice = room:askForChoice(player, {"red", "black", "Cancel"}, self.name, "#gundam__gongxin-dis::" .. target.id)
      if choice ~= "Cancel" then
        local pattern = type(target:getMark("@gundam__gongxin-turn")) == "table" and target:getMark("@gundam__gongxin-turn") or {}
        table.insertIfNeed(pattern, choice)
        room:setPlayerMark(target, "@gundam__gongxin-turn", pattern)
      end
    end
  end,
}
local gundam__gongxin_prohibit = fk.CreateProhibitSkill{
  name = "#gundam__gongxin_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@gundam__gongxin-turn") ~= 0 then
      return table.contains(player:getMark("@gundam__gongxin-turn"), card:getColorString())
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@gundam__gongxin-turn") ~= 0 then
      return table.contains(player:getMark("@gundam__gongxin-turn"), card:getColorString())
    end
  end,
}
gundam__gongxin:addRelatedSkill(gundam__gongxin_prohibit)

os__gundameng:addSkill(gundam__shelie)
os__gundameng:addSkill(gundam__gongxin)

Fk:loadTranslationTable{
  ["os__gundameng"] = "高达二号",
  ["gundam__shelie"] = "涉猎",
  [":gundam__shelie"] = "摸牌阶段，你可改为亮出牌堆顶的五张牌，然后获得其中每种花色的牌各一张。每轮限一次，结束阶段开始时，若你本回合使用牌花色数不小于你的体力值，你选择执行一个额外的摸牌阶段或出牌阶段。",
  ["gundam__gongxin"] = "攻心",
  [":gundam__gongxin"] = "出牌阶段限一次，你可观看一名其他角色的手牌，然后你可展示其中一张牌并选择一项：1. 你弃置其此牌；2. 将此牌置于牌堆顶。然后若其手牌中花色数因此减少，你可令其本回合无法使用或打出一种颜色的牌。",

  ["@gundam__shelie-turn"] = "涉猎",
  ["#gundam__shelie_extra"] = "涉猎",
  ["#gundam__shelie_extra-ask"] = "涉猎：选择执行一个额外的阶段",
  ["#gundam__shelie_extra_log"] = "%from 发动“%arg”，执行一个额外的 %arg2",
  ["gundam__gongxin_discard"] = "弃置所选牌",
  ["gundam__gongxin_put"] = "将所选牌置于牌堆顶",
  ["#gundam__gongxin-ask"] = "攻心：观看%dest的手牌，可展示其中一张牌并选择一项",
  ["#gundam__gongxin-dis"] = "攻心：你可令 %dest 本回合无法使用或打出一种颜色的牌",
  ["@gundam__gongxin-turn"] = "攻心",

  ["$gundam__shelie1"] = "尘世之间，岂有吾所未闻之事？",
  ["$gundam__shelie2"] = "往事皆知，未来尽料。",
  ["$gundam__gongxin1"] = "敌将虽有破军之勇，然未必有弑神之心。",
  ["$gundam__gongxin2"] = "知敌所欲为，则此战已尽在掌握。",
  ["~os__gundameng"] = "吾能已通神，却难逆天命啊……",
}

local os__gexuan = General(extension, "os__gexuan", "qun", 3)

local os__danfa = fk.CreateTriggerSkill{
  name = "os__danfa",
  events = {fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if (target ~= player or not player:hasSkill(self)) then return false end
    if event == fk.EventPhaseStart then return (player.phase == Player.Start or player.phase == Player.Finish) and not player:isNude()
    else
      local suitsRecorded = type(player:getMark("@os__danfa-turn")) == "table" and player:getMark("@os__danfa-turn") or {}
      local os__cinnabar = table.map(player:getPile("os__cinnabar"), function(cid) return Fk:getCardById(cid):getSuitString() end)
      local suit = data.card:getSuitString()
      return not table.contains(suitsRecorded, "log_" .. suit) and table.contains(os__cinnabar, suit)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local id = player.room:askForCard(player, 1, 1, true, self.name, true, nil, "#os__danfa-put")
      if #id > 0 then
        self.cost_data = id[1]
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      player:addToPile("os__cinnabar", self.cost_data, true, self.name)
    else
      player:drawCards(1, self.name)
      local suitsRecorded = type(player:getMark("@os__danfa-turn")) == "table" and player:getMark("@os__danfa-turn") or {}
      table.insert(suitsRecorded, "log_" .. data.card:getSuitString())
      player.room:setPlayerMark(player, "@os__danfa-turn", suitsRecorded)
    end
  end,
}

local os__lingbao = fk.CreateActiveSkill{
  name = "os__lingbao",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and #Self:getPile("os__cinnabar") > 1
  end,
  card_num = 2,
  expand_pile = "os__cinnabar",
  card_filter = function(self, to_select, selected)
    return (#selected == 0 or (#selected == 1 and Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(selected[1]), true))) and Self:getPileNameOfId(to_select) == "os__cinnabar"
  end,
  target_num = 0,
  on_use = function(self, room, use)
    if #use.cards ~= 2 then return end
    local player = room:getPlayerById(use.from)
    room:moveCardTo(use.cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name)
    local color = table.map(use.cards, function(id) return Fk:getCardById(id).color end)
    if color[1] == color[2] then
      if color[1] == Card.Red then
        local availableTargets = table.map(
        table.filter(room.alive_players, function(p)
          return p:isWounded()
        end),
        Util.IdMapper
        )
        if #availableTargets == 0 then return false end
        local target = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__lingbao-red", self.name, false)
        if #target > 0 then
          room:recover({ who = room:getPlayerById(target[1]), num = 1, recoverBy = player, skillName = self.name})
        end
      else
        local availableTargets = table.map(
        table.filter(room.alive_players, function(p)
          return not p:isAllNude()
        end),
        Util.IdMapper
        )
        if #availableTargets == 0 then return false end
        local target = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__lingbao-black", self.name, false)
        if #target > 0 then
          target = room:getPlayerById(target[1])
          local card_data = {}
          if target:getHandcardNum() > 0 then
            local handcards = {}
            for i = 1, target:getHandcardNum(), 1 do
              table.insert(handcards, -1) -- 手牌不可见
            end
            table.insert(card_data, {"$Hand", handcards})
          end
          local areas = {["$Equip"] = Player.Equip, ["$Judge"] = Player.Judge}
          for k, v in pairs(areas) do
            if #target.player_cards[v] > 0 then
              table.insert(card_data, {k, target:getCardIds(v)})
            end
          end
          local ret = room:askForPoxi(player, "os__lingbao_discard", card_data, nil, false)
          local new_ret = table.filter(ret, function(id) return id ~= -1 end)
          local hand_num = #ret - #new_ret
          if hand_num > 0 then
            table.insertTable(new_ret, table.random(target:getCardIds(Player.Hand), hand_num))
          end
          room:throwCard(new_ret, self.name, target, player)
        end
      end
    else
      local targets = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 2, 2, "#os__lingbao-black_red", self.name, false)
      if #targets > 0 then
        room:getPlayerById(targets[1]):drawCards(1, self.name)
        targets = room:getPlayerById(targets[2])
        if not targets:isNude() then
          room:askForDiscard(targets, 1, 1, true, self.name, false)
        end
      end
    end
  end,
}
Fk:addPoxiMethod{
  name = "os__lingbao_discard",
  card_filter = Util.TrueFunc,
  feasible = function(selected, data)
    if #selected < 1 or #selected > 2 then return false end
    local areas = {}
    for _, id in ipairs(selected) do
      for _, v in ipairs(data) do
        if table.contains(v[2], id) then
          table.insertIfNeed(areas, v[2])
          break
        end
      end
    end
    return #areas == #selected
  end,
  prompt = "#os__lingbao-discard",
  default_choice = function(data)
    if not data then return {} end
    local cids = table.map(data, function(v) return v[2][1] end)
    return table.random(cids, 1)
  end,
}
local sidao_derivecards = {{"celestial_calabash", Card.Heart, 1}, {"horsetail_whisk", Card.Heart, 1}, {"talisman", Card.Heart, 1}}
local os__sidao = fk.CreateTriggerSkill{
  name = "os__sidao",
  events = {fk.GameStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.GameStart then
      return true
    else
      return player.phase == Player.Start and player:getMark("_os__sidao") ~= 0
      and table.contains({Card.DiscardPile, Card.DrawPile, Card.Void}, player.room:getCardArea(player:getMark("_os__sidao")))
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local cards = {}
      for _, name in ipairs({"celestial_calabash", "horsetail_whisk", "talisman"}) do
        local card = Fk:cloneCard(name, Card.Heart, 1)
        if U.canUseCardTo(room, player, player, card) then
          table.insert(cards, room:printCard(name, Card.Heart, 1).id)
        end
      end
      if #cards == 0 then return false end
      player.special_cards["os__sidao"] = table.simpleClone(cards)
      player:doNotify("ChangeSelf", json.encode {
        id = player.id,
        handcards = player:getCardIds("h"),
        special_cards = player.special_cards,
      })
      local chosen = room:askForCard(player, 1, 1, false, self.name, false, ".|.|.|os__sidao", "#os__sidao-ask", "os__sidao")
      player.special_cards["os__sidao"] = {}
      player:doNotify("ChangeSelf", json.encode {
        id = player.id,
        handcards = player:getCardIds("h"),
        special_cards = player.special_cards,
      })
      local cardId = #chosen > 0 and chosen[1] or table.random(cards)
      room:setPlayerMark(player, "_os__sidao", cardId)
      room:useCard({ from = player.id, tos = { {player.id} }, card = Fk:getCardById(cardId) })
    else
      local cardId = player:getMark("_os__sidao")
      room:obtainCard(player, cardId, true, fk.ReasonPrey)
      if table.contains(player:getCardIds("he"), cardId) and U.canUseCardTo(room, player, player, Fk:getCardById(cardId)) then
        room:useCard({ from = player.id, tos = { {player.id} }, card = Fk:getCardById(cardId) })
      end
    end
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local hold_areas = {Card.PlayerEquip, Card.Processing, Card.Void, Card.PlayerHand, Card.PlayerSpecial}
    local card_names = {"celestial_calabash", "horsetail_whisk", "talisman"}
    local mirror_moves = {}
    local ids = {}
    for _, move in ipairs(data) do
      if not table.contains(hold_areas, move.toArea) then
        local move_info = {}
        local mirror_info = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if table.contains(card_names, Fk:getCardById(id).name) then
            table.insert(mirror_info, info)
            table.insert(ids, id)
          else
            table.insert(move_info, info)
          end
        end
        if #mirror_info > 0 then
          move.moveInfo = move_info
          local mirror_move = table.clone(move)
          mirror_move.to = nil
          mirror_move.toArea = Card.Void
          mirror_move.moveInfo = mirror_info
          table.insert(mirror_moves, mirror_move)
        end
      end
    end
    if #ids > 0 then
      player.room:sendLog{
        type = "#destructDerivedCards",
        card = ids,
      }
    end
    table.insertTable(data, mirror_moves)
  end,
}

os__gexuan:addSkill(os__danfa)
os__gexuan:addSkill(os__lingbao)
os__gexuan:addSkill(os__sidao)

Fk:loadTranslationTable{
  ["os__gexuan"] = "葛玄", --胜利台词……
  ["os__danfa"] = "丹法",
  [":os__danfa"] = "①准备阶段或结束阶段开始时，你可将一张牌置于你的武将牌上，称为“丹”。②每回合每种花色限一次，当你使用与一张“丹”相同花色的牌时，你摸一张牌。", 
  ["os__lingbao"] = "灵宝",
  [":os__lingbao"] = "出牌阶段限一次，你可将两张花色不同的“丹”置入弃牌堆，若：均为红色，你令一名角色回复1点体力；均为黑色，你弃置一名角色至多两个不同区域的各一张牌；颜色不同，你令一名角色摸一张牌，另一名角色弃置一张牌。",
  ["os__sidao"] = "司道",
  [":os__sidao"] = "①游戏开始时，你选择一件法宝并使用之：【灵宝仙葫】、【太极拂尘】、【冲应神符】。②准备阶段开始时，若你选择过的法宝不在游戏内或在牌堆或弃牌堆中，则你获得并使用之。<br/>" .. 
  "<font color='grey'>【<b>灵宝仙葫</b>】<font color='#C04040'>♥</font>A  装备牌·武器 攻击范围：3  锁定技，当你造成大于1点的伤害时或一名角色死亡时，你增加1点体力上限并回复1点体力。<br/>" ..
  "【<b>太极拂尘</b>】<font color='#C04040'>♥</font>A  装备牌·武器 攻击范围：5  当你使用的【杀】指定目标后，目标角色需弃置一张牌，否则不可响应此【杀】；若其弃置的牌与此【杀】花色相同，你获得之。<br/>" ..
  "【<b>冲应神符</b>】<font color='#C04040'>♥</font>A  装备牌·防具  锁定技，当你受到一种牌名的牌造成的伤害后，本局游戏同牌名的牌对你造成的伤害-1。</font>",

  ["os__cinnabar"] = "丹",
  ["#os__danfa-put"] = "丹法：你可将一张牌置于你的武将牌上，称为“丹”",
  ["@os__danfa-turn"] = "丹法",
  ["#os__lingbao-red"] = "灵宝：选择一名角色，令其回复1点体力",
  ["#os__lingbao-black"] = "灵宝：选择一名角色，弃置其至多两个不同区域的各一张牌",
  ["os__lingbao_discard"] = "灵宝",
  ["#os__lingbao-discard"] = "弃置其至多两个不同区域的各一张牌",
  ["#os__lingbao-black_red"] = "灵宝：选择两名角色，先选的摸一张牌，后选的弃置一张牌",
  ["#os__sidao-ask"] = "司道：选择一件法宝并使用之",

  ["$os__danfa1"] = "取五灵三使之药，炼九光七曜之丹。",
  ["$os__danfa2"] = "云液踊跃成雪霜，流珠之英能延年。",
  ["$os__lingbao1"] = "洞明于至道，俯弘于世教。",
  ["$os__lingbao2"] = "凝神太虚镜，北冥探玄珠。",
  ["$os__sidao1"] = "执吾法器，以司正道。",
  ["$os__sidao2"] = "内修道法，外需宝器。",
  ["~os__gexuan"] = "金丹难成，大道难修……",
  ["$os__gexuan_win_audio"] = "科有天禁不可抑，华精庵蔼化仙人。",
}

local os__himiko = General(extension, "os__himiko", "qun", 3, 3, General.Female)

local os__zongkui = fk.CreateTriggerSkill{
  name = "os__zongkui",
  anim_type = "control",
  events = {fk.RoundStart, fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or (event == fk.TurnStart and target ~= player) then return false end
    local targets = table.filter(player.room.alive_players, function(p)
      return p:getMark("@@os__puppet") == 0 and p ~= player
    end)
    if #targets > 0 then
      return true
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local target = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function(p)
        return p:getMark("@@os__puppet") == 0 and p ~= player
      end), Util.IdMapper), 1, 1, "#os__zongkui-ask", self.name,true)
      if #target > 0 then
        self.cost_data = target[1]
        return true
      end
    else
      local n = 999
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if p.hp < n then
          n = p.hp
        end
      end
      local availableTargets = table.map(table.filter(room.alive_players, function(p)
        return p:getMark("@@os__puppet") == 0 and p.hp == n and p ~= player
      end), Util.IdMapper)
      if #availableTargets == 0 then return false end
      local target = room:askForChoosePlayers(
        player,
        availableTargets,
        1,
        1,
        "#os__zongkui-ask",
        self.name,
        false
      )
      self.cost_data = #target > 0 and target[1] or table.random(availableTargets) --权宜
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), "@@os__puppet")
  end,
}

local os__guju = fk.CreateTriggerSkill{
  name = "os__guju",
  anim_type = "drawcard",
  events = {fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@@os__puppet") > 0 and player:hasSkill(self) and not target.dead
  end,
  on_use = function(self, event, target, player, data)
    local num = 1
    local room = player.room
    if target.kingdom == player:getMark("@os__bingzhao") and player:hasSkill("os__bingzhao") then
      if room:askForChoice(target, {"os__bingzhao_draw", "Cancel"}, self.name, "#os__bingzhao-ask:" .. player.id) ~= "Cancel" then
        num = 2
      end
    end
    player:drawCards(num, self.name)
    room:addPlayerMark(player, "@" .. self.name, num)
  end,
}

local os__baijia = fk.CreateTriggerSkill{
  name = "os__baijia",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("@os__guju") > 6
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@os__guju", 0)
    room:changeMaxHp(player, 1)
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name,
    })
    table.forEach(table.filter(room:getOtherPlayers(player), function(p)
      return p:getMark("@@os__puppet") == 0
    end), function(p)
      room:addPlayerMark(p, "@@os__puppet")
    end)
    room:handleAddLoseSkills(player, "os__canshi|-os__guju", nil)
  end,
}

local os__bingzhao = fk.CreateTriggerSkill{
  name = "os__bingzhao$",
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and table.find(player.room.alive_players, function(p) return p.kingdom ~= player.kingdom end)
  end,
  on_cost = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    table.removeOne(kingdoms, player.kingdom)
    local choice = player.room:askForChoice(player, kingdoms, self.name, "#os__bingzhao-choose")
    self.cost_data = choice
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@" .. self.name, self.cost_data)
  end,
}

local os__canshi = fk.CreateTriggerSkill{
  name = "os__canshi",
  mute = true,
  events = {fk.TargetConfirming, fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and ((event == fk.TargetConfirming and #AimGroup:getAllTargets(data.tos) == 1 and player.room:getPlayerById(data.from):getMark("@@os__puppet") > 0)
    or (event == fk.AfterCardTargetDeclared and data.tos and #data.tos == 1)) 
    and (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetConfirming then
      return player.room:askForSkillInvoke(player, self.name, data, "#os__canshi::" .. data.from .. ":" .. data.card.name)
    else
      local targets = table.filter(player.room.alive_players, function(p)
        return p:getMark("@@os__puppet") > 0 and not table.contains(TargetGroup:getRealTargets(data.tos), p.id)
        and not player:isProhibited(p, data.card)
      end)
      if #targets == 0 then return false end
      local tos = player.room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, #targets, "#os__canshi-targets", self.name, true)
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirming then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "defensive")
      AimGroup:cancelTarget(data, data.to)
      room:removePlayerMark(room:getPlayerById(data.from), "@@os__puppet")
    else
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "special")
      local tos = self.cost_data
      room:doIndicate(player.id, tos)
      for _, pid in ipairs(tos) do
        table.insert(data.tos, {pid})
        room:removePlayerMark(room:getPlayerById(pid), "@@os__puppet")
      end
      room:sendLog{
        type = "#AddTargetsBySkill",
        from = player.id,
        to = tos,
        arg = self.name,
        arg2 = data.card:toLogString()
      }
    end
  end,
}

os__himiko:addSkill(os__zongkui)
os__himiko:addSkill(os__guju)
os__himiko:addSkill(os__baijia)
os__himiko:addSkill(os__bingzhao)
os__himiko:addRelatedSkill(os__canshi)

Fk:loadTranslationTable{
  ["os__himiko"] = "卑弥呼",
  ["os__zongkui"] = "纵傀",
  [":os__zongkui"] = "回合开始后，你可指定一名没有“傀”的其他角色，令其获得1枚“傀”。每轮开始时，体力值最小且没有“傀”的一名其他角色获得1枚“傀”。", --关于轮次开始的问题……
  ["os__guju"] = "骨疽",
  [":os__guju"] = "锁定技，当有“傀”的角色受到伤害后，你摸一张牌。",
  ["os__baijia"] = "拜假",
  [":os__baijia"] = "觉醒技，准备阶段开始时，若你因〖骨疽〗获得牌不小于7张，则你加1点体力上限，回复1点体力，然后令所有未拥有“傀”的其他角色获得一枚“傀”，最后失去〖骨疽〗，并获得〖蚕食〗。",
  ["os__bingzhao"] = "秉诏",
  [":os__bingzhao"] = "主公技，游戏开始时，你选择一个其他势力，该势力有“傀”的角色受到伤害后，可令你因〖骨疽〗额外摸一张牌。",
  ["os__canshi"] = "蚕食",
  [":os__canshi"] = "①当一名角色使用基本牌或普通锦囊牌指定你为唯一目标时，若其有“傀”，你可取消之，然后其弃1枚“傀”。②你使用基本牌或普通锦囊牌仅选择一名角色为目标时，你可令任意名带有“傀”的角色也成为目标，然后这些角色弃1枚“傀”。",

  ["@@os__puppet"] = "傀",
  ["#os__zongkui-ask"] = "纵傀：选择一名其他角色，令其获得一枚“傀”",
  ["os__bingzhao_draw"] = "令其额外摸一张牌",
  ["@os__guju"] = "骨疽",
  ["#os__bingzhao-choose"] = "秉诏：选择一个其他势力，该势力有“傀”的角色受到伤害后，可令你因〖骨疽〗额外摸一张牌",
  ["@os__bingzhao"] = "秉诏",
  ["#os__canshi"] = "蚕食：你可取消【%arg】的目标，然后 %dest 弃“傀”",
  ["#os__canshi-targets"] = "蚕食：你可令任意名有“傀”的角色也成为目标，然后这些角色弃“傀”",
  ["#AddTargetsBySkill"] = "用于 %arg 的效果，%from 使用的 %arg2 增加了目标 %to",

  ["$os__zongkui1"] = "不要抵抗，接受我的操纵吧。",
  ["$os__zongkui2"] = "当我的傀儡，你将受益良多。",
  ["$os__guju1"] = "你还没有见过真正的恐惧。",
  ["$os__guju2"] = "这些，你就感到害怕了吗？",
  ["$os__baijia1"] = "没有人能阻止我的觉醒。",
  ["$os__baijia2"] = "哼哼哼……这才是我的真面目。",
  ["$os__canshi1"] = "此患不足为惧，可蚕食而尽。",
  ["$os__canshi2"] = "小则蚕食，大则溃坝。",
  ["~os__himiko"] = "鬼道破灭，我有何寄托？",
}

local nashime = General(extension, "nashime", "qun", 3)

local os__chijie = fk.CreateTriggerSkill{
  name = "os__chijie",
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    table.insert(kingdoms, "Cancel")
    local choice = player.room:askForChoice(player, kingdoms, self.name, "#os__chijie-choose")
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    player.kingdom = self.cost_data
    player.room:broadcastProperty(player, "kingdom")
  end,
}

local os__waishi = fk.CreateActiveSkill{
  name = "os__waishi",
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < player:getMark("@os__waishi_times") + 1
  end,
  card_filter = function(self, to_select, selected)
    local kingdoms = {}
    table.insertIfNeed(kingdoms, Self.kingdom)
    local player = Self.next
    while player.id ~= Self.id do --getAliveSiblings
      if not player.dead then table.insertIfNeed(kingdoms, player.kingdom) end
      player = player.next
    end
    return #selected < #kingdoms 
  end,
  min_card_num = 1,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getHandcardNum() >= #selected_cards
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    
    local n = #effect.cards
    local cids = room:askForCardsChosen(player, target, n, n, "h", self.name)
    local cards1 = effect.cards
    local cards2 = cids
    local move1 = {
      from = player.id,
      ids = cards1,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,  --FIXME: this is still visible! same problem with dimeng!
    }
    local move2 = {
      from = target.id,
      ids = cards2,
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    room:moveCards(move1, move2)
    local move3 = {
      ids = cards1,
      fromArea = Card.Processing,
      to = target.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    local move4 = {
      ids = cards2,
      fromArea = Card.Processing,
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
      moveVisible = false,
    }
    room:moveCards(move3, move4)
    if target.kingdom == player.kingdom or target:getHandcardNum() > player:getHandcardNum() then
      player:drawCards(1, self.name)
    end
  end,
}

local os__renshe = fk.CreateTriggerSkill{
  name = "os__renshe",
  events = {fk.Damaged},
  anim_type = "masochism",
  on_cost = function(self, event, target, player, data)
    local choices = {"os__waishi_times"}
    local room = player.room
    if table.find(room.alive_players, function(p)
      return p.kingdom ~= player.kingdom
    end) then
      table.insert(choices, 1, "os__renshe_change")
    end
    if table.find(room.alive_players, function(p)
      return p ~= data.from and p ~= player
    end) then
      table.insert(choices, "os__renshe_draw")
    end
    table.insert(choices, "Cancel")
    local choice = room:askForChoice(player, choices, self.name)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data
    if choice == "os__waishi_times" then
      room:addPlayerMark(player, "@os__waishi_times", 1)
    elseif choice == "os__renshe_change" then
        local kingdoms = {}
        for _, p in ipairs(room.alive_players) do
          table.insertIfNeed(kingdoms, p.kingdom)
        end
        table.removeOne(kingdoms, player.kingdom)
        player.kingdom = room:askForChoice(player, kingdoms, self.name, "#os__chijie-choose")
        room:broadcastProperty(player, "kingdom")
    else
      local tos = room:askForChoosePlayers(player, table.map(
        table.filter(room.alive_players, function(p)
          return (p ~= data.from and p ~= player)
        end), Util.IdMapper
      ), 1, 1, "#os__renshe-target", self.name, false)
      if #tos > 0 then
        for _, p in ipairs(room:getAlivePlayers()) do --顺序
          if not p.dead and (p.id == tos[1] or p == player) then
            p:drawCards(1, self.name)
          end
        end
      end
    end
  end,

  refresh_events = {fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("@os__waishi_times") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@os__waishi_times", 0)
  end,
}

nashime:addSkill(os__chijie)
nashime:addSkill(os__waishi)
nashime:addSkill(os__renshe)

Fk:loadTranslationTable{
  ["nashime"] = "难升米",
  ["os__chijie"] = "持节",
  [":os__chijie"] = "游戏开始时，你可将你的势力改为现存的一个势力。",
  ["os__waishi"] = "外使",
  [":os__waishi"] = "出牌阶段限一次，你可选择至多X张牌（X为现存势力数），并选择一名其他角色的等量手牌，你与其交换这些牌，然后若其与你势力相同或手牌多于你，你摸一张牌。",
  ["os__renshe"] = "忍涉",
  [":os__renshe"] = "当你受到伤害后，你可选择一项：1.将势力改为现存的另一个势力；2.令〖外使〗的发动次数上限于你的出牌阶段结束前+1；3.与一名除伤害来源之外的其他角色各摸一张牌。",

  ["#os__chijie-choose"] = "持节：你可更改你的势力",
  ["os__renshe_change"] = "将势力改为现存的另一个势力",
  ["os__waishi_times"] = "令〖外使〗的发动次数上限于你的出牌阶段结束前+1",
  ["@os__waishi_times"] = "外使次数+",
  ["os__renshe_draw"] = "与一名除伤害来源之外的其他角色各摸一张牌",
  ["#os__renshe-target"] = "忍涉：选择一名除伤害来源之外的其他角色，与其各摸一张牌",

  ["$os__chijie1"] = "按照女王的命令，选择目标吧！",
  ["$os__waishi1"] = "贵国的繁荣，在下都看到了。",
  ["$os__waishi2"] = "希望我们两国，可以世代修好。",
  ["$os__renshe1"] = "无论风雨再大，都无法阻挡我的脚步。",
  ["$os__renshe2"] = "一定不能辜负女王的期望！",
  ["~nashime"] = "请把这身残躯，带回我的家乡……",
}

local jianshuo = General(extension, "jianshuo", "qun", 6)

local os__kunsi = fk.CreateViewAsSkill{
  name = "os__kunsi",
  anim_type = "offensive",
  card_num = 0,
  view_as = function(self)
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, useData)
    useData.extra_data = useData.extra_data or {}
    useData.extra_data.os__kunsiUser = player.id
    useData.extraUse = true
    local targets = TargetGroup:getRealTargets(useData.tos)
    useData.extra_data.os__kunsiTarget = targets
    local room = player.room
    table.forEach(targets, function(pid)
      room:addPlayerMark(room:getPlayerById(pid), "_os__kunsi")
    end)
  end,
  enabled_at_response = function(self, player, cardResponsing) return false end,
}
local os__kunsi_buff = fk.CreateTargetModSkill{
  name = "#os__kunsi_buff",
  residue_func = function(self, player, skill, scope, card)
    return scope == Player.HistoryPhase and card and table.contains(card.skillNames, "kunsi") and 999 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return card and table.contains(card.skillNames, "os__kunsi") and 999 or 0
  end,
}
local os__kunsi_prohibit = fk.CreateProhibitSkill{
  name = "#os__kunsi_prohibit",
  is_prohibited = function(self, from, to, card)
    return to:getMark("_os__kunsi") > 0 and card and card.name == "slash" and table.contains(card.skillNames, "os__kunsi")
  end,
}
local os__kunsi_trig = fk.CreateTriggerSkill{
  name = "#os__kunsi_trig",
  mute = true,
  refresh_events = {fk.Damaged, fk.CardUseFinished, fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return target == player and (data.extra_data or {}).os__kunsiUser == player.id
    elseif event == fk.Damaged then
      local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      return parentUseData and (parentUseData.data[1].extra_data or {}).os__kunsiUser == player.id
    else
      return target == player and player:getMark("_os__linglu") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      local targets = (data.extra_data or {}).os__kunsiTarget
      local os__linglu = player:getMark("_os__linglu") ~= 0 and player:getMark("_os__linglu") or {}
      table.insertTable(os__linglu, targets)
      room:setPlayerMark(player, "_os__linglu", os__linglu)
      for _, pid in ipairs(targets) do
        local target = room:getPlayerById(pid)
        if not target:hasSkill("os__linglu") then
          room:handleAddLoseSkills(target, "os__linglu")
          room:setPlayerMark(target, "_os__linglu_jianshuo", player.id)
        end
      end
    elseif event == fk.Damaged then
      local parentUseData = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      table.removeOne(parentUseData.data[1].extra_data.os__kunsiTarget, data.to.id)
    else
      table.forEach(player:getMark("_os__linglu"), function(pid)
        room:handleAddLoseSkills(room:getPlayerById(pid), "-os__linglu")
      end)
    end
  end,
}
os__kunsi:addRelatedSkill(os__kunsi_buff)
os__kunsi:addRelatedSkill(os__kunsi_prohibit)
os__kunsi:addRelatedSkill(os__kunsi_trig)

local os__linglu = fk.CreateTriggerSkill{
  name = "os__linglu",
  events = {fk.EventPhaseStart},
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#os__linglu-ask", self.name, true)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark_name = player:getMark("_os__linglu_jianshuo") == self.cost_data and room:askForChoice(player, {"os__linglu_twice", "Cancel"}, self.name, "#os__linglu_twice-ask:" .. self.cost_data) ~= "Cancel" and "@os__linglu_twice" or "@os__linglu"
    local target = room:getPlayerById(self.cost_data)
    local mark = type(target:getMark(mark_name)) == "table" and target:getMark(mark_name) or {}
    --table.insertTable(mark, {player.general, 0})
    table.insert(mark, player.general)
    table.insert(mark, 0)
    room:setPlayerMark(target, mark_name, mark)
    mark_name = string.sub(mark_name, 2)
    mark = type(target:getMark(mark_name)) == "table" and target:getMark(mark_name) or {}
    table.insert(mark, player.id)
    room:setPlayerMark(target, mark_name, mark)
  end
}
local os__linglu_do = fk.CreateTriggerSkill{
  name = "#os__linglu_do",
  refresh_events = {fk.Damage, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and (player:getMark("@os__linglu") ~= 0 or player:getMark("@os__linglu_twice") ~=0)
  end,
  on_refresh = function(self, event, target, player, data)
    local mark_names = {"@os__linglu", "@os__linglu_twice"}
    local room = player.room
    if event == fk.Damage then
      for _, mark_name in ipairs(mark_names) do
        local mark = type(player:getMark(mark_name)) == "table" and player:getMark(mark_name) or {}
        for i = 2, #mark, 2 do
          mark[i] = mark[i] + data.damage
        end
        room:setPlayerMark(player, mark_name, mark)
      end
    else
      for _, mark_name in ipairs(mark_names) do
        if player.dead then break end
        local mark = type(player:getMark(mark_name)) == "table" and player:getMark(mark_name) or {}
        for i = 2, #mark, 2 do
          if player.dead then break end
          room:doIndicate(player:getMark(string.sub(mark_name, 2))[i/2], {player.id})
          if mark[i] < 2 then
            room:loseHp(player, 1, self.name)
            if mark_name == "@os__linglu_twice" then room:loseHp(player, 1, self.name) end
          else
            player:drawCards(2, self.name)
          end
        end
        room:setPlayerMark(player, mark_name, 0)
        room:setPlayerMark(player, string.sub(mark_name, 2), 0)
      end
    end
  end
}
os__linglu:addRelatedSkill(os__linglu_do)

jianshuo:addSkill(os__kunsi)
jianshuo:addRelatedSkill(os__linglu)

Fk:loadTranslationTable{
  ["jianshuo"] = "蹇硕",
  ["os__kunsi"] = "困兕",
  [":os__kunsi"] = "出牌阶段，你可视为对一名未以此法指定过的角色使用【杀】（无次数和距离限制）。若此【杀】未造成伤害，则其拥有〖令戮〗直到你的下个回合开始后。其指定你为〖令戮〗的目标时，可令〖令戮〗的失败结算进行两次。",
  ["os__linglu"] = "令戮",
  [":os__linglu"] = "出牌阶段开始时，你可强令一名其他角色在其下回合结束前造成2点伤害。成功：其摸两张牌；失败：其失去1点体力。<br/><font color='grey'>#\"<b>强令</b>\"<br/>向一名角色颁布一项任务，在任务结束时点执行奖惩。",

  ["#os__linglu-ask"] = "令戮：你可强令一名其他角色在其下回合结束前造成2点伤害",
  ["os__linglu_twice"] = "令其〖令戮〗的失败结算进行两次",
  ["#os__linglu_twice-ask"] = "令戮：你可令 %src 〖令戮〗的失败结算进行两次",
  ["@os__linglu"] = "令戮",
  ["@os__linglu_twice"] = "令戮2",

  ["$os__kunsi1"] = "豺狼虎兕雄壮，西园将校威风！",
  ["$os__kunsi2"] = "灵帝遗命，岂容尔等放肆？",
  ["~jianshuo"] = "郭胜，汝竟下此狠手！",
}

local caozhao = General(extension, "caozhao", "wei", 4)

local os__fuzuan = fk.CreateActiveSkill{
  name = "os__fuzuan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected ~= 0 then return false end
    for _, skill in ipairs(Fk:currentRoom():getPlayerById(to_select).player_skills) do
      if skill:isSwitchSkill() then
        return true
      end
    end
    return false
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local skills = table.filter(target.player_skills, function(s)
      return s:isSwitchSkill()
    end)
    local skillNames = table.map(skills, function(s)
      return s.name
    end)
    local skill = skills[table.indexOf(skillNames, room:askForChoice(player, skillNames, self.name, "#os__fuzuan-ask:" .. target.id))]
    local switchSkillName = skill.switchSkillName
    room:setPlayerMark(
      target,
      MarkEnum.SwithSkillPreName .. switchSkillName,
      target:getSwitchSkillState(switchSkillName, true)
    )
    target:addSkillUseHistory(skill.name) --……
  end,
}
local os__fuzuan_trg = fk.CreateTriggerSkill{
  name = "#os__fuzuan_trg",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) then return false end
    return event == fk.Damaged or data.to ~= player
  end,
  on_cost = function(self, event, target, player, data)
    local _, ret = player.room:askForUseActiveSkill(player, "os__fuzuan", "#os__fuzuan-trg", true)
    if ret then
      local target = ret.targets[1]
      player.room:doIndicate(player.id, {target})
      return true
    end 
  end,
  on_use = Util.FalseFunc,
}
os__fuzuan:addRelatedSkill(os__fuzuan_trg)

local os__chongqi = fk.CreateTriggerSkill{
  name = "os__chongqi",
  anim_type = "support",
  events = {fk.GameStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(
      table.filter(room:getOtherPlayers(player), function(p)
        return (not p:hasSkill("os__fuzuan"))
      end),
      Util.IdMapper
    )
    if #targets == 0 then return false end
    local target = room:askForChoosePlayers(player, targets, 1, 1, "#os__chongqi-ask", self.name, true)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(room:getPlayerById(self.cost_data), "os__fuzuan", nil)
  end,

  refresh_events = {fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and data == self  
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:handleAddLoseSkills(p, "os__feifu", nil, false, true)
    end
  end,
}

local os__feifu = fk.CreateTriggerSkill{
  name = "os__feifu",
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  anim_type = "switch",
  frequency = Skill.Compulsory,
  switch_skill_name = "os__feifu",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) then return false end
    return data.card.trueName == "slash" and #AimGroup:getAllTargets(data.tos) == 1 and ((event == fk.TargetSpecified and player:getSwitchSkillState(self.name) == 0) or (event == fk.TargetConfirmed and player:getSwitchSkillState(self.name) == 1)) and not player.room:getPlayerById(data.to):isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "switch")
    if event == fk.TargetSpecified then
      player:broadcastSkillInvoke(self.name, math.random(1, 2))
    else
      player:broadcastSkillInvoke(self.name, math.random(3, 4))
    end
    local user = room:getPlayerById(data.from)
    local target = room:getPlayerById(data.to)
    room:doIndicate(player.id, {player == user and data.to or data.from})
    local cids = room:askForCard(target, 1, 1, true, self.name, false, nil, "#os__feifu-give:" .. data.from)
    if #cids > 0 then
      room:moveCardTo(cids, Player.Hand, user, fk.ReasonGive, self.name, nil, false)
      local card = Fk:getCardById(cids[1])
      if card.type == Card.TypeEquip and room:getCardOwner(card) == user and room:getCardArea(card) == Card.PlayerHand then
        local cardName = card.name
        local use = room:askForUseCard(user, cardName, cardName .. "|.|.|.|.|.|" .. cids[1], "#os__feifu-use:::" .. card:toLogString(), true)
        if use then room:useCard(use) end
      end
    end
  end,
}

caozhao:addSkill(os__fuzuan)
caozhao:addSkill(os__chongqi)
caozhao:addRelatedSkill(os__feifu)

Fk:loadTranslationTable{
  ["caozhao"] = "曹肇",
  ["os__fuzuan"] = "复纂",
  [":os__fuzuan"] = "你可于以下时机点选择一名有转换技的角色，调整其一个转换技的阴阳状态：出牌阶段限一次，你对其他角色造成伤害后，受到伤害后。",
  ["os__chongqi"] = "宠齐",
  [":os__chongqi"] = "锁定技，①当你获得此技能后，所有角色获得〖非服〗。②游戏开始时，你可减1点体力上限，令一名其他角色获得〖复纂〗。",
  ["os__feifu"] = "非服",
  [":os__feifu"] = "锁定技，转换技，阳：当你使用【杀】指定唯一目标后；阴：当你成为【杀】的唯一目标后；目标角色A须交给此【杀】的使用者B一张牌，若此牌为装备牌，B可使用此牌。",

  ["#os__fuzuan-ask"] = "复纂：你可选择 %src 的一个转换技，调整其阴阳状态",
  ["#os__fuzuan_trg"] = "复纂",
  ["#os__fuzuan-trg"] = "你可对一名有转换技的角色发动“复纂”",
  ["#os__chongqi-ask"] = "宠齐：你可减1点体力上限，令一名其他角色获得〖复纂〗",
  ["#os__feifu-give"] = "非服：请交给 %src 一张牌",
  ["#os__feifu-use"] = "非服：你可使用%arg",

  ["$os__fuzuan1"] = "望陛下听臣忠言，勿信资等无知之论。",
  ["$os__fuzuan2"] = "前朝王莽之乱，可为今事之鉴。",
  ["$os__chongqi1"] = "吾既身承宠遇，敢不为君分忧？",
  ["$os__chongqi2"] = "臣得君上垂青，已是此生之幸。",
  ["$os__feifu1"] = "此亦久矣，其能复几！",
  ["$os__feifu2"] = "君既赌输，理当再脱一件。",
  ["$os__feifu3"] = "以侯归第？终败于其！",
  ["$os__feifu4"] = "君若如此，让我如何见人？",
  ["~caozhao"] = "虽极荣宠，亦有尽时。",
}

local os__hucheer = General(extension, "os__hucheer", "qun", 4)

local os__shenxing = fk.CreateDistanceSkill{
  name = "os__shenxing",
  correct_func = function(self, from, to)
    if from:hasSkill(self) and from:getEquipment(Card.SubtypeOffensiveRide) == nil and from:getEquipment(Card.SubtypeDefensiveRide) == nil then
      return -1
    end
  end,
}
local os__shenxing_maxcard = fk.CreateMaxCardsSkill{
  name = "#os__shenxing_maxcard",
  correct_func = function(self, player)
    if player:hasSkill(self) and player:getEquipment(Card.SubtypeOffensiveRide) == nil and player:getEquipment(Card.SubtypeDefensiveRide) == nil then
      return 1
    end
    return 0
  end,
}
os__shenxing:addRelatedSkill(os__shenxing_maxcard)

local os__daoji = fk.CreateActiveSkill{
  name = "os__daoji",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Self:inMyAttackRange(Fk:currentRoom():getPlayerById(to_select)) and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, use)
    if #use.cards ~= 1 then return end
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    room:throwCard(use.cards, self.name, player, player)
    local id = room:askForCardChosen(player, target, "he", self.name)
    room:obtainCard(player, id)
    local cardType = Fk:getCardById(id).type
    if cardType == Card.TypeBasic then
      player:drawCards(1, self.name)
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
        skillName = self.name,
      }
    end
  end,
}

os__hucheer:addSkill(os__shenxing)
os__hucheer:addSkill(os__daoji)

Fk:loadTranslationTable{
  ["os__hucheer"] = "胡车儿",
  ["os__shenxing"] = "神行",
  [":os__shenxing"] = "锁定技，若你的坐骑区没有牌，你与其他角色的距离-1，你的手牌上限+1。",
  ["os__daoji"] = "盗戟",
  [":os__daoji"] = "出牌阶段限一次，你可弃置一张非基本牌并选择一名攻击范围内的其他角色，你获得其一张牌。若你以此法获得的牌为：基本牌，你摸一张牌；装备牌，则你使用此牌，对其造成1点伤害。",

  ["$os__daoji1"] = "八十斤双戟？于我如探囊取物！",
  ["$os__daoji2"] = "以汝之矛，攻汝之盾！",
  ["~os__hucheer"] = "未料一伸手，便被……敌酋捉……",
}

local os__luzhik = General(extension, "os__luzhik", "qun", 3)

local os__mingren = fk.CreateTriggerSkill{
  name = "os__mingren",
  events = {fk.GameStart, fk.EventPhaseStart, fk.EventPhaseEnd},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    return (event == fk.GameStart or (target == player and player.phase == Player.Play and not player:isKongcheng() and #player:getPile("os__duty") > 0))
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    else
      local cids = player.room:askForCard(player, 1, 1, false, self.name, true, nil, "#os__mingren-exchange")
      if #cids > 0 then
        self.cost_data = cids[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      player:drawCards(1, self.name)
      if not player:isKongcheng() then
        local cids = room:askForCard(player, 1, 1, false, self.name, true, nil, "#os__mingren-put")
        if #cids > 0 then
          player:addToPile("os__duty", cids[1], true, self.name)
        end
      end
    else
      player:addToPile("os__duty", self.cost_data, true, self.name)
      room:moveCardTo(player:getPile("os__duty")[1], Player.Hand, player, fk.ReasonJustMove, self.name, "os__duty")
    end
  end,
}

local os__zhenliang = fk.CreateActiveSkill{
  name = "os__zhenliang",
  anim_type = "switch",
  switch_skill_name = "os__zhenliang",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and player:getSwitchSkillState(self.name) == fk.SwitchYang
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected < 1
  end,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Self:inMyAttackRange(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    if #effect.cards ~= 1 then return end
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = self.name,
    }
    if #player:getPile("os__duty") > 0 and Fk:getCardById(effect.cards[1]):compareColorWith(Fk:getCardById(player:getPile("os__duty")[1])) then
      player:drawCards(1, self.name)
    end
  end,
}
local os__zhenliang_defend = fk.CreateTriggerSkill{
  name = "#os__zhenliang_defend",
  anim_type = "switch",
  switch_skill_name = "os__zhenliang",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill("os__zhenliang") then return false end
    return player:getSwitchSkillState("os__zhenliang") == fk.SwitchYin and (target == player or player:inMyAttackRange(target)) and not player:isNude() and player.phase == Player.NotActive
  end,
  on_cost = function(self, event, target, player, data)
    local cids = player.room:askForDiscard(player, 1, 1, true, self.name, true, nil, "#os__zhenliang-discard:" .. target.id, true)
    if #cids > 0 then
      self.cost_data = cids
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("os__zhenliang")
    player:addSkillUseHistory("os__zhenliang")
    room:throwCard(self.cost_data, self.name, player, player)
    data.damage = data.damage - 1
    if #player:getPile("os__duty") > 0 and Fk:getCardById(self.cost_data[1]):compareColorWith(Fk:getCardById(player:getPile("os__duty")[1])) then
      player:drawCards(1, self.name)
    end
  end,
}
os__zhenliang:addRelatedSkill(os__zhenliang_defend)

os__luzhik:addSkill(os__mingren)
os__luzhik:addSkill(os__zhenliang)

Fk:loadTranslationTable{
  ["os__luzhik"] = "卢植",
  ["os__mingren"] = "明任",
  [":os__mingren"] = "①游戏开始时，你摸一张牌，将一张手牌置于武将牌上，称为“任”。②出牌阶段开始或结束时，你可用一张手牌替换“任”。",
  ["os__zhenliang"] = "贞良",
  [":os__zhenliang"] = "转换技，阳：出牌阶段限一次，你可弃置一张牌并选择你攻击范围内的一名其他角色，对其造成1点伤害；阴：你的回合外，当你或你攻击范围内的一名角色受到伤害时，你可弃置一张牌，令此伤害-1。若你以此法弃置的牌与“任”颜色相同，你摸一张牌。",

  ["os__duty"] = "任",
  ["#os__mingren-put"] = "明任：请将一张手牌置于武将牌上",
  ["#os__mingren-exchange"] = "明任：你可用一张手牌替换“任”",
  ["#os__zhenliang-discard"] = "贞良：你可弃置一张牌，令 %src 受到的伤害-1",
  ["#os__zhenliang_defend"] = "贞良",

  ["$os__mingren1"] = "吾之任，君之明举！",
  ["$os__mingren2"] = "得义真所救，吾任之必尽瘁以报。",
  ["$os__zhenliang1"] = "贞洁贤良，吾之本心。",
  ["$os__zhenliang2"] = "风霜以别草木之性，危乱而见贞良之节。",
  ["~os__luzhik"] = "泓泓眸子宿渊亭，不见蛾眉只见经。",
}

local os__yangyi = General(extension, "os__yangyi", "shu", 3)

local os__duoduan = fk.CreateTriggerSkill{
  name = "os__duoduan",
  events = {fk.TargetConfirmed},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local cids = player.room:askForCard(player, 1, 1, true, self.name, true, nil, "#os__duoduan-ask")
    if #cids > 0 then
      self.cost_data = cids
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recastCard(self.cost_data, player, self.name)
    local from = room:getPlayerById(data.from)
    if #room:askForDiscard(from, 1, 1, true, self.name, true, nil, "#os__duoduan-discard") > 0 then
      local parentUseData = room.logic:getCurrentEvent():findParent(GameEvent.UseCard) -- AimStruct 没有 disresponsiveList
      parentUseData.data[1].disresponsiveList = parentUseData.data[1].disresponsiveList or {}
      table.forEach(room.alive_players, function(p)
        table.insertIfNeed(parentUseData.data[1].disresponsiveList, p.id)
      end)
    else
      from:drawCards(2, self.name)
      table.forEach(room.alive_players, function(p)
        table.insertIfNeed(data.nullifiedTargets, p.id)
      end)
    end
  end,
}

local os__gongsun = fk.CreateTriggerSkill{
  name = "os__gongsun",
  events = {fk.EventPhaseStart},
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local availableTargets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:inMyAttackRange(p)
    end), Util.IdMapper)
    if #availableTargets == 0 then return false end
    local target = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__gongsun-target", self.name, false)
    if #target > 0 then
      local choice = room:askForChoice(player, {"log_spade", "log_club", "log_heart", "log_diamond"}, self.name, "#os__gongsun-suit:" .. target[1])
      self.cost_data = {target[1], choice}
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(self.cost_data[1])
    local targets = U.getMark(player, "_os__gongsun")
    table.insertIfNeed(targets, target.id)
    room:setPlayerMark(player, "_os__gongsun", targets)
    for _, p in ipairs({player, target}) do
      local suitsRecorded = U.getMark(p, "@os__gongsun")
      table.insert(suitsRecorded, self.cost_data[2])
      room:setPlayerMark(p, "@os__gongsun", suitsRecorded)
    end
  end,

  refresh_events = {fk.TurnStart, fk.Death},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os__gongsun") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@os__gongsun", 0)
    table.forEach(table.map(player:getMark("_os__gongsun"), function(pid)
      return room:getPlayerById(pid)
    end), function(p)
      room:setPlayerMark(p, "@os__gongsun", 0)
    end)
  end,
}
local os__gongsun_prohibit = fk.CreateProhibitSkill{
  name = "#os__gongsun_prohibit",
  prohibit_use = function(self, player, card)
    return type(player:getMark("@os__gongsun")) == "table" and table.contains(player:getMark("@os__gongsun"), card:getSuitString(true)) and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  prohibit_response = function(self, player, card)
    return type(player:getMark("@os__gongsun")) == "table" and table.contains(player:getMark("@os__gongsun"), card:getSuitString(true)) and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  prohibit_discard = function(self, player, card)
    return type(player:getMark("@os__gongsun")) == "table" and table.contains(player:getMark("@os__gongsun"), card:getSuitString(true)) and table.contains(player.player_cards[Player.Hand], card.id)
  end,
}

os__gongsun:addRelatedSkill(os__gongsun_prohibit)

os__yangyi:addSkill(os__duoduan)
os__yangyi:addSkill(os__gongsun)

Fk:loadTranslationTable{
  ["os__yangyi"] = "杨仪",
  ["os__duoduan"] = "度断",
  [":os__duoduan"] = "每回合限一次，当你成为【杀】的目标后，你可重铸一张牌，然后你令此【杀】的使用者须弃置一张牌令此【杀】不可被响应，否则其摸两张牌令此【杀】无效。",
  ["os__gongsun"] = "共损",
  [":os__gongsun"] = "锁定技，出牌阶段开始时，你选择攻击范围内的一名角色并选择一种花色，直至你的下个回合开始前，你与其无法使用、打出或弃置该花色的手牌。",

  ["#os__duoduan-ask"] = "度断：你可重铸一张牌",
  ["#os__duoduan-discard"] = "度断：弃置一张牌令此【杀】不可被响应，否则你摸两张牌令此【杀】无效",
  ["#os__gongsun-target"] = "共损：请选择攻击范围内的一名角色",
  ["#os__gongsun-suit"] = "共损：请选择一种花色，直至你的下个回合开始前，你和 %src 无法使用、打出或弃置该花色的手牌。",
  ["@os__gongsun"] = "共损",

  ["$os__duoduan1"] = "北伐之事，丞相亦听我定夺。",
  ["$os__duoduan2"] = "筹定规画，片刻既定！",
  ["$os__gongsun1"] = "我岂能与魏延这种莽夫共事！",
  ["$os__gongsun2"] = "早知如此，投靠魏国又如何！",
  ["~os__yangyi"] = "我功勋卓著，只为昏君奸臣所害，哼！",
}

local os__xuezong =  General(extension, "os__xuezong", "wu", 3)

local os__funan = fk.CreateTriggerSkill{
  name = "os__funan",
  anim_type = "control",
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.responseToEvent and data.responseToEvent.from == player.id and target ~= player and
    ((event == fk.CardUseFinished and data.toCard) or
    (event == fk.CardRespondFinished)) and ((player:getMark("@@os__funan_update") == 0 and data.responseToEvent.card and player.room:getCardArea(data.responseToEvent.card) == Card.Processing) or (player:getMark("@@os__funan_update") > 0 and data.card))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@@os__funan_update") == 0 then
      local card = data.responseToEvent.card
      room:obtainCard(target, card, false, fk.ReasonPrey)
      local cidsRecorded = type(target:getMark("_os__funan-turn")) == "table" and target:getMark("_os__funan-turn") or {}
      table.insertTable(cidsRecorded, card:isVirtual() and card.subcards or {card.id})
      room:setPlayerMark(target, "_os__funan-turn", cidsRecorded)
    end
    if data.card and player:isAlive() then
      room:obtainCard(player, data.card, false, fk.ReasonPrey)
    end
  end,
}
local os__funan_prohibit = fk.CreateProhibitSkill{
  name = "#os__funan_prohibit",
  prohibit_use = function(self, player, card)
    if type(player:getMark("_os__funan-turn")) == "table" then return table.contains(player:getMark("_os__funan-turn"), card.id) end
  end,
  prohibit_response = function(self, player, card)
    if type(player:getMark("_os__funan-turn")) == "table" then return table.contains(player:getMark("_os__funan-turn"), card.id) end
  end,
}
os__funan:addRelatedSkill(os__funan_prohibit)

local os__jiexun = fk.CreateTriggerSkill{
  name = "os__jiexun",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#os__jiexun-target", self.name, true)
    if #target > 0 then
      local card_suits = {"log_spade", "log_club", "log_heart", "log_diamond"}
      local num = player:getMark("@os__jiexun_update") == 0 and player:getMark("@os__jiexun") or player:getMark("@os__jiexun_update")
      local choice = room:askForChoice(player, card_suits, self.name, "#os__jiexun-suit:" .. target[1] .. "::" .. tostring(num))
      self.cost_data = {target[1], table.indexOf(card_suits, choice)}
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(self.cost_data[1])
    local suit = self.cost_data[2]
    local num = 0
    for _, p in ipairs(player.room.alive_players) do
      num = num + #table.filter(p:getCardIds{ Player.Equip, Player.Judge }, function(id) 
        return Fk:getCardById(id).suit == suit
      end)
    end
    if num > 0 then
      room:drawCards(target, num, self.name)
    end
    num = player:getMark("@os__jiexun_update") == 0 and player:getMark("@os__jiexun") or player:getMark("@os__jiexun_update")
    if num > 0 then
      room:askForDiscard(target, num, num, true, self.name, false)
    end
    if player:getMark("@os__jiexun_update") == 0 then
      room:addPlayerMark(player, "@os__jiexun")
      if num > 0 and target:isNude() then
        if room:askForChoice(player, {"os__jiexun_draw:::" .. num, "os__jiexun_update"}, self.name) == "os__jiexun_update" then
          room:setPlayerMark(player, "@@os__funan_update", 1)
          room:setPlayerMark(player, "@os__jiexun_update", num)
          room:setPlayerMark(player, "@os__jiexun", 0)
        else
          player:drawCards(num, self.name)
          room:setPlayerMark(player, "@os__jiexun", 0)
        end
      end
    end
  end,
}

os__xuezong:addSkill(os__funan)
os__xuezong:addSkill(os__jiexun)

Fk:loadTranslationTable{
  ["os__xuezong"] = "薛综",
  ["os__funan"] = "复难",
  [":os__funan"] = "1级：其他角色响应你使用的牌时，你可令其获得你使用的牌，其本回合不能使用或打出之，然后你获得其使用或打出的牌。<br/>2级：其他角色响应你使用的牌时，你可获得其使用或打出的牌。",
  ["os__jiexun"] = "诫训",
  [":os__jiexun"] = "1级：结束阶段开始时，你可选择一名其他角色并选择一种花色，令其摸场上此花色牌数张牌，然后其弃置X张牌（X为此技能发动过的次数）。若其以此法弃置了所有牌，你选择一项：1. 摸X张牌，然后重置X为0；2. 升级〖复难〗和〖诫训〗。<br/>2级：结束阶段开始时，你可选择一种花色，令一名其他角色摸场上此花色牌数张牌，然后其弃置X张牌（X为此技能升级前的X）。",

  ["@@os__funan_update"] = "复难2级",
  ["@os__jiexun_update"] = "诫训2级",
  ["#os__jiexun-target"] = "你可对一名其他角色发动“诫训”",
  ["#os__jiexun-suit"] = "诫训：选择一种花色，令 %src 摸场上此花色牌数张牌，然后其弃置%arg张牌",
  ["@os__jiexun"] = "诫训",
  ["os__jiexun_draw"] = "摸%arg张牌，重置〖诫训〗次数",
  ["os__jiexun_update"] = "升级〖复难〗和〖诫训〗",

  ["$os__funan1"] = "礼尚往来，乃君子风范。",
  ["$os__funan2"] = "以子之矛，攻子之盾。",
  ["$os__jiexun1"] = "帝王应以社稷为重，以大观为主。",
  ["$os__jiexun2"] = "吾冒昧进谏，只求陛下思虑。",
  ["~os__xuezong"] = "尔等，竟做如此有辱斯文之事。",
}

local os__zhugeguo =  General(extension, "os__zhugeguo", "shu", 3, 3, General.Female)

local os__qirang = fk.CreateTriggerSkill{
  name = "os__qirang",
  events = {fk.AfterCardsMove},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    for _, move in ipairs(data) do
      if move.to and move.to == player.id and move.toArea == Player.Equip then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cids = room:getCardsFromPileByRule(".|.|.|.|.|trick")
    if #cids > 0 then
      local cid = cids[1]
      local cidsRecorded = type(player:getMark("_os__qirangTrick-phase")) == "table" and player:getMark("_os__qirangTrick-phase") or {}
      table.insert(cidsRecorded, cid)
      room:setPlayerMark(player, "_os__qirangTrick-phase", cidsRecorded)
      room:obtainCard(player, cid, false, fk.ReasonPrey)
    end
  end,
}

local os__qirang_trick = fk.CreateTriggerSkill{
  name = "#os__qirang_trick",
  events = {fk.TargetSpecifying, fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and type(player:getMark("_os__qirangTrick-phase")) == "table" and data.card.type == Card.TypeTrick and table.contains(player:getMark("_os__qirangTrick-phase"), data.card.id) 
    and (event == fk.CardUsing or (data.firstTarget and data.card.sub_type ~= Card.SubtypeDelayedTrick))
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetSpecifying then
      local room = player.room
      local targets = getUseExtraTargets(room, data, false, true)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#os__qirang-target:::"..data.card:toLogString(), self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.TargetSpecifying then
      local room = player.room
      room:notifySkillInvoked(player, "os__yuhua", "special")
      player:broadcastSkillInvoke("os__yuhua")
      if table.contains(AimGroup:getAllTargets(data.tos), self.cost_data) then
        TargetGroup:removeTarget(data.targetGroup, self.cost_data)
      else
        TargetGroup:pushTargets(data.targetGroup, self.cost_data)
      end
    else
      data.disresponsiveList = data.disresponsiveList or {}
      for _, target in ipairs(player.room.alive_players) do
        table.insertIfNeed(data.disresponsiveList, target.id)
      end
    end
  end,
}
local os__qirang_buff = fk.CreateTargetModSkill{
  name = "#os__qirang_buff",
  anim_type = "offensive",
  distance_limit_func = function(self, player, skill, card)
    return (type(player:getMark("_os__qirangTrick-phase")) == "table" and table.contains(player:getMark("_os__qirangTrick-phase"), card.id)) and 999 or 0
  end,
}
os__qirang:addRelatedSkill(os__qirang_buff)
os__qirang:addRelatedSkill(os__qirang_trick)

local os__yuhua = fk.CreateTriggerSkill{
  name = "os__yuhua",
  events = {fk.AfterCardsMove},
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player.phase ~= Player.NotActive then return false end
    for _, move in ipairs(data) do
      if move.from == player.id then
        if table.find(move.moveInfo, function(info)
          return (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and Fk:getCardById(info.cardId).type ~= Card.TypeBasic
        end) then return true end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data)
  end,
  on_use = function(self, event, target, player, data)
    local num = 0
    for _, move in ipairs(data) do
      if move.from == player.id then
        num = num + #table.filter(move.moveInfo, function(info)
          return (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip)
        end)
      end
    end
    num = math.min(5, num)
    local room = player.room
    room:askForGuanxing(player, room:getNCards(num))
    if room:askForChoice(player, {"os__yuhuaDraw:::" .. num, "Cancel"}, self.name) ~= "Cancel" then
      player:drawCards(num, self.name)
    end
  end,
}
local os__yuhuaMax = fk.CreateMaxCardsSkill{
  name = "#os__yuhuaMax",
  exclude_from = function(self, player, card)
    return player:hasSkill(os__yuhua.name) and card.type ~= Card.TypeBasic
  end,
}
local os__yuhua_maxcards_audio = fk.CreateTriggerSkill{
  name = "#os__yuhua_maxcards_audio",
  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(os__yuhua.name) and player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    player:broadcastSkillInvoke(os__yuhua.name)
    player.room:notifySkillInvoked(player, os__yuhua.name, "special")
  end,
}
os__yuhua:addRelatedSkill(os__yuhuaMax)
os__yuhua:addRelatedSkill(os__yuhua_maxcards_audio)

os__zhugeguo:addSkill(os__qirang)
os__zhugeguo:addSkill(os__yuhua)

Fk:loadTranslationTable{
  ["os__zhugeguo"] = "诸葛果",
  ["os__qirang"] = "祈禳",
  [":os__qirang"] = "当装备牌移至你的装备区后，你可获得牌堆里的一张锦囊牌，然后你此阶段使用此牌无距离限制、不可被响应且可增加或减少一个目标。",
  ["os__yuhua"] = "羽化",
  [":os__yuhua"] = "锁定技，弃牌阶段，你的非基本牌不计入手牌上限。当你于回合外失去非基本牌后，你可观看牌堆顶的X张牌并将其置于牌堆顶或牌堆底，然后你可摸X张牌（X为你此次失去牌的数量且至多为5）。",

  ["#os__qirang-target"] = "祈禳：你可为 %arg 增加或减少一个目标",
  ["os__yuhuaDraw"] = "摸%arg张牌",
  ["#os__qirang_trick"] = "祈禳",

  ["$os__qirang1"] = "仙甲既来，岂无仙术乎。",
  ["$os__qirang2"] = "集母亲之智，效父亲之法，祈以七星。",
  ["$os__yuhua1"] = "凤羽飞烟，乘化仙尘。",
  ["$os__yuhua2"] = "此乃仙人之物，不可轻弃。",
  ["~os__zhugeguo"] = "方生方死，方死方生。",
}

local zhangmancheng = General(extension, "zhangmancheng", "qun", 4)

local os__fengji = fk.CreateTriggerSkill{
  name = "os__fengji",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Play and not player:isNude() and #player:getPile("os__revelation") == 0 and player:getMark("@os__fengji") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local cids = player.room:askForCard(player, 1, 1, true, self.name, true, nil, "#os__fengji-ask")
    if #cids > 0 then
      self.cost_data = cids[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("os__revelation", self.cost_data, true, self.name)
    local num = player.room:askForChoice(player, {"1", "2", "3"}, self.name, "#os__fengji-conjure")
    player.room:setPlayerMark(player, "@os__fengji", num .. "-" .. num)
  end,
}
local os__fengji_conjure = fk.CreateTriggerSkill{
  name = "#os__fengji_conjure",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__fengji") ~= 0 and string.sub(player:getMark("@os__fengji"), -1) == "0"
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__fengji"), "-")
    local num = tonumber(nums[1])
    if #player:getPile("os__revelation") > 0 then
      room:notifySkillInvoked(player, "os__fengji")
      player:broadcastSkillInvoke("os__fengji")
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(room:getCardsFromPileByRule(Fk:getCardById(player:getPile("os__revelation")[1]).trueName, num))
      if #dummy.subcards > 0 then
        room:obtainCard(player, dummy, false, fk.ReasonPrey)
      end
      room:moveCardTo(Fk:getCardById(player:getPile("os__revelation")[1]), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, "os__revelation")
    end
    room:setPlayerMark(player, "@os__fengji", 0)
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@os__fengji") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__fengji"), "-")
    local num = tonumber(nums[1])
    local num2 = tonumber(nums[2]) - 1
    room:setPlayerMark(player, "@os__fengji", num .. "-" .. num2)
  end,
}
os__fengji:addRelatedSkill(os__fengji_conjure)

local os__yijuTargetMod = fk.CreateTargetModSkill{
  name = "#os__yijuTargetMod",
  residue_func = function(self, player, skill, scope)
    return (player:hasSkill(self) and #player:getPile("os__revelation") > 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase) and player.hp - 1 or 0
  end,
}
local os__yijuAR = fk.CreateAttackRangeSkill{
  name = "#os__yijuAR",
  correct_func = function(self, from, to)
    return (from:hasSkill(self) and #from:getPile("os__revelation") > 0) and from.hp or 0
  end,
}
local os__yiju = fk.CreateTriggerSkill{
  name = "os__yiju",
  events = {fk.DamageInflicted},
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and #player:getPile("os__revelation") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return data.damage > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(Fk:getCardById(player:getPile("os__revelation")[1]), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, "os__revelation")
    data.damage = data.damage + 1
  end,
}
os__yiju:addRelatedSkill(os__yijuTargetMod)
os__yiju:addRelatedSkill(os__yijuAR)

local os__budao = fk.CreateTriggerSkill{
  name = "os__budao",
  events = {fk.EventPhaseStart},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:recover({ who = player, num = 1, recoverBy = player, skillName = self.name})
    local os__budaoSkills = table.random({"os__zhouhu", "os__zuhuo", "os__fengqi", "os__huangjin", "os__zhouzu", "os__didao"}, 3) --
    local skillName = room:askForChoice(player, os__budaoSkills, self.name, "#os__budao-ask", true)
    room:handleAddLoseSkills(player, skillName, nil, true, false)
    local pid = room:askForChoosePlayers(player, table.map(
      table.filter(room:getOtherPlayers(player), function(p)
        return (not p:isNude())
      end),
      Util.IdMapper
    ), 1, 1, "#os__budao-target:::" .. skillName, self.name, true)
    if #pid > 0 then
      local target = room:getPlayerById(pid[1])
      room:handleAddLoseSkills(target, skillName, nil, true, false)
      if not target:isNude() then
        local c = room:askForCard(target, 1, 1, true, self.name, false, nil, "#os__budao-card:" .. player.id)[1]
        room:moveCardTo(c, Player.Hand, player, fk.ReasonGive, self.name, nil, false)
      end
    end
  end,
}

local os__zhouhu = fk.CreateTriggerSkill{
  name = "os__zhouhu",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player.phase == Player.Play and not player:isNude() and player:getMark("@os__zhouhu") == 0
  end,
  on_cost = function(self, event, target, player, data) 
    local room = player.room
    local cids = room:askForDiscard(player, 1, 1, false, self.name, true, ".|.|heart,diamond", "#os__zhouhu-ask", true)
    if #cids > 0 then
      local target = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#os__zhouhu-target", self.name, false)
      self.cost_data = {cids, target[1]}
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data[1], self.name, player)
    local num = room:askForChoice(player, {"1", "2", "3"}, self.name, "#os__zhouhu-conjure")
    local target = self.cost_data[2]
    room:setPlayerMark(player, "@os__zhouhu", {room:getPlayerById(target).general, num .. "-" .. num})
    room:setPlayerMark(player, "_os__zhouhu", target)
  end,
}
local os__zhouhu_conjure = fk.CreateTriggerSkill{
  name = "#os__zhouhu_conjure",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__zhouhu") ~= 0 and string.sub(player:getMark("@os__zhouhu")[2], -1) == "0"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__zhouhu")[2], "-")
    local num = tonumber(nums[1])
    local target = room:getPlayerById(player:getMark("_os__zhouhu"))
    room:notifySkillInvoked(player, "os__zhouhu")
    player:broadcastSkillInvoke("os__zhouhu")
    if target:isWounded() then room:recover({ who = target, num = num, recoverBy = player, skillName = self.name}) end
    room:setPlayerMark(player, "@os__zhouhu", 0)
    room:setPlayerMark(player, "_os__zhouhu", 0)
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@os__zhouhu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__zhouhu")[2], "-")
    room:setPlayerMark(player, "@os__zhouhu", {player:getMark("@os__zhouhu")[1], nums[1] .. "-" .. tonumber(nums[2]) - 1})
  end,
}
os__zhouhu:addRelatedSkill(os__zhouhu_conjure)

local os__zuhuo = fk.CreateTriggerSkill{
  name = "os__zuhuo",
  anim_type = "defensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player.phase == Player.Play and not player:isNude() and player:getMark("@os__zuhuo") == 0
  end,
  on_cost = function(self, event, target, player, data) 
    local room = player.room
    local cids = room:askForDiscard(player, 1, 1, true, self.name, true,  ".|.|.|.|.|^basic", "#os__zuhuo-ask", true)
    if #cids > 0 then
      self.cost_data = cids
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player)
    local num = room:askForChoice(player, {"1", "2", "3"}, self.name, "#os__zuhuo-conjure")
    room:setPlayerMark(player, "@os__zuhuo", num .. "-" .. num)
  end,
}
local os__zuhuo_conjure = fk.CreateTriggerSkill{
  name = "#os__zuhuo_conjure",
  mute = true,
  events = {fk.TurnEnd, fk.DamageInflicted},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if event == fk.TurnEnd then
      return player:getMark("@os__zuhuo") ~= 0 and string.sub(player:getMark("@os__zuhuo"), -1) == "0"
    else
      return target == player and player:getMark("@os__zuhuo_defend") ~= 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnEnd then
      local nums = string.split(player:getMark("@os__zuhuo"), "-")
      local num = tonumber(nums[1])
      room:notifySkillInvoked(player, "os__zuhuo")
      player:broadcastSkillInvoke("os__zuhuo")
      room:addPlayerMark(player, "@os__zuhuo_defend", num)
      room:setPlayerMark(player, "@os__zuhuo", 0)
    else
      room:notifySkillInvoked(player, "os__zuhuo")
      player:broadcastSkillInvoke("os__zuhuo")
      room:removePlayerMark(player, "@os__zuhuo_defend")
      return true
    end
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@os__zuhuo") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__zuhuo"), "-")
    room:setPlayerMark(player, "@os__zuhuo", nums[1] .. "-" .. tonumber(nums[2]) - 1)
  end,
}
os__zuhuo:addRelatedSkill(os__zuhuo_conjure)

local os__fengqi = fk.CreateTriggerSkill{
  name = "os__fengqi",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player.phase == Player.Play and not player:isNude() and player:getMark("@os__fengqi") == 0
  end,
  on_cost = function(self, event, target, player, data) 
    local room = player.room
    local cids = room:askForDiscard(player, 1, 1, false, self.name, true, ".|.|spade,club", "#os__fengqi-ask", true)
    if #cids > 0 then
      local target = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#os__fengqi-target", self.name, false)
      self.cost_data = {cids, target[1]}
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data[1], self.name, player)
    local num = room:askForChoice(player, {"1", "2", "3"}, self.name, "#os__fengqi-conjure")
    local target = self.cost_data[2]
    room:setPlayerMark(player, "@os__fengqi", {room:getPlayerById(target).general, num .. "-" .. num})
    room:setPlayerMark(player, "_os__fengqi", target)
  end,
}
local os__fengqi_conjure = fk.CreateTriggerSkill{
  name = "#os__fengqi_conjure",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__fengqi") ~= 0 and string.sub(player:getMark("@os__fengqi")[2], -1) == "0"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__fengqi")[2], "-")
    local num = tonumber(nums[1])
    local target = room:getPlayerById(player:getMark("_os__fengqi"))
    room:notifySkillInvoked(player, "os__fengqi")
    player:broadcastSkillInvoke("os__fengqi")
    target:drawCards(2 * num, self.name)
    room:setPlayerMark(player, "@os__fengqi", 0)
    room:setPlayerMark(player, "_os__fengqi", 0)
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@os__fengqi") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__fengqi")[2], "-")
    room:setPlayerMark(player, "@os__fengqi", {player:getMark("@os__fengqi")[1], nums[1] .. "-" .. tonumber(nums[2]) - 1})
  end,
}
os__fengqi:addRelatedSkill(os__fengqi_conjure)

local os__huangjin = fk.CreateTriggerSkill{
  name = "os__huangjin",
  events = {fk.TargetConfirming},
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = data.card.number
    local judge = {
      who = player,
      reason = self.name,
      pattern = num > 0 and (".|" .. num-1 .. "~" .. num+1 ) or nil,
    }
    room:judge(judge)
    if num > 0 and judge.card.number - num < 2 and judge.card.number - num > -2 then
      table.insertIfNeed(data.nullifiedTargets, player.id)
    end
  end,
}

--[[local os__guimen = fk.CreateTriggerSkill{ --有毛病的东西
  name = "os__guimen",
  anim_type = "offensive",
  events = {fk.AfterCardsMove},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).suit == Card.Spade then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cids = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).suit == Card.Spade then
            table.insertIfNeed(cids, Fk:getCardById(info.cardId).number)
          end
        end
      end
    end
    
    local judge = {
      who = player,
      reason = self.name,
      pattern = num > 0 and (".|" .. num-1 .. "~" .. num+1 ) or nil,
    }
    room:judge(judge)
    if num > 0 and judge.card.number - num < 2 and judge.card.number - num > -2 then
      local pid = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#os__guimen-target", self.name, false)
      if #pid > 0 then
        room:damage{
          from = player,
          to = room:getPlayerById(pid[1]),
          damage = 2,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        }
      end
    end
  end,
}]]

local os__zhouzu = fk.CreateActiveSkill{
  name = "os__zhouzu",
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and player:getMark("@os__zhouzu") == 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  interaction = UI.Spin {
    from = 1, to = 3,
  },
  on_use = function(self, room, effect)
    local num = self.interaction.data
    if not num then return false end
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, "@os__zhouzu", {target.general, num .. "-" .. num})
    room:setPlayerMark(player, "_os__zhouzu", target.id)
  end,
}
local os__zhouzu_conjure = fk.CreateTriggerSkill{
  name = "#os__zhouzu_conjure",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__zhouzu") ~= 0 and string.sub(player:getMark("@os__zhouzu")[2], -1) == "0"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__zhouzu")[2], "-")
    local num = tonumber(nums[1])
    room:notifySkillInvoked(player, "os__zhouzu")
    player:broadcastSkillInvoke("os__zhouzu")
    local target = room:getPlayerById(player:getMark("_os__zhouzu"))
    if #target:getCardIds{Player.Equip, Player.Hand} < num then
      target:throwAllCards("he")
      room:damage{
        from = player,
        to = target,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    else
      room:askForDiscard(target, num, num, true, self.name, false)
    end
    room:setPlayerMark(player, "@os__zhouzu", 0)
    room:setPlayerMark(player, "_os__zhouzu", 0)
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@os__zhouzu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__zhouzu")[2], "-")
    room:setPlayerMark(player, "@os__zhouzu", {player:getMark("@os__zhouzu")[1], nums[1] .. "-" .. tonumber(nums[2]) - 1})
  end,
}
os__zhouzu:addRelatedSkill(os__zhouzu_conjure)

local os__didao = fk.CreateTriggerSkill{
  name = "os__didao",
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForResponse(player, self.name, ".|.|.|hand,equip", "#os__didao-ask:" .. target.id, true)
    if card ~= nil then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local invoke = false
    if self.cost_data:compareColorWith(data.card) then invoke = true end
    player.room:retrial(self.cost_data, player, data, self.name, true)
    if invoke and not player.dead then
      player:drawCards(1, self.name)
    end
  end,
}

zhangmancheng:addSkill(os__fengji)
zhangmancheng:addSkill(os__yiju)
zhangmancheng:addSkill(os__budao)
zhangmancheng:addRelatedSkill(os__zhouhu) --
zhangmancheng:addRelatedSkill(os__zuhuo)
zhangmancheng:addRelatedSkill(os__fengqi)
zhangmancheng:addRelatedSkill(os__huangjin)
--zhangmancheng:addRelatedSkill(os__guimen)
zhangmancheng:addRelatedSkill(os__zhouzu)
zhangmancheng:addRelatedSkill(os__didao)

Fk:loadTranslationTable{
  ["zhangmancheng"] = "张曼成",
  ["#zhangmancheng"] = "南阳渠帅",
  ["os__fengji"] = "蜂集",
  [":os__fengji"] = "出牌阶段开始时，若你没有“示”，你可将一张牌置于武将牌上，称为“示”并施法X=1~3回合：{从牌堆中获得X张与“示”同名的牌，然后将“示”置入弃牌堆。}" .. 
  "<br/><font color='grey'>#\"<b>施法</b>\"<br/>一名角色的回合结束前，施法标记-1，减至0时执行施法效果。施法期间不能重复施法同一技能。",
  ["os__yiju"] = "蚁聚",
  [":os__yiju"] = "若你有“示”，①你于出牌阶段使用【杀】的次数上限和攻击范围均为你的体力值。②当你受到伤害时，你将“示”置入弃牌堆，令此伤害+1。",
  ["os__budao"] = "布道",
  [":os__budao"] = "限定技，准备阶段开始时，你可减1点体力上限，回复1点体力，从布道技能库的随机三个技能中选择一个获得，然后你可令一名其他角色获得相同技能并交给你一张牌。<br/>" .. 
  "<font color='grey'>#\"<b>布道技能库</b>\"<br/><b>咒护</b>: 出牌阶段结束时，你可弃置一张红色手牌并施法：回复X点体力。<br/>" .. 
  "<b>咒护</b>: 出牌阶段结束时，你可弃置一张红色手牌，选择一名角色并施法：令其回复X点体力。<br/>" ..
  "<b>阻祸</b>: 出牌阶段结束时，你可弃置一张非基本牌并施法：防止你受到的下X次伤害。<br/>" ..
  "<b>丰祈</b>: 出牌阶段结束时，你可弃置一张黑色手牌，选择一名角色并施法：其摸2X张牌。<br/>" ..
  "<b>黄巾</b>: 锁定技，当你成为【杀】的目标时，你判定：若结果点数与此【杀】点数差值不大于1，则此【杀】对你无效。<br/>" ..
  "（暂无）<b>鬼门</b>: 锁定技，当你因弃置而失去黑桃牌后，你判定：若结果点数与你弃置的其中一张黑桃牌点数差值不大于1，则对一名其他角色造成2点雷电伤害。<br/>" ..
  "<b>咒诅</b>: 出牌阶段限一次，你可选择一名其他角色并施法：令其弃置X张牌，若牌数不足则全部弃置并对其造成1点雷电伤害。<br/>" ..
  "<b>地道</b>: 当一名角色的判定牌生效前，你可打出一张牌替换之，若与原判定牌颜色相同，你摸一张牌。</font>",
  
  ["os__zhouhu"] = "咒护",
  [":os__zhouhu"] = "出牌阶段结束时，你可弃置一张红色手牌，选择一名角色并施法：令其回复X点体力。",
  ["os__zuhuo"] = "阻祸",
  [":os__zuhuo"] = "出牌阶段结束时，你可弃置一张非基本牌并施法：防止你受到的下X次伤害。",
  ["os__fengqi"] = "丰祈",
  [":os__fengqi"] = "出牌阶段结束时，你可弃置一张黑色手牌，选择一名角色并施法：其摸2X张牌。",
  ["os__huangjin"] = "黄巾",
  [":os__huangjin"] = "锁定技，当你成为【杀】的目标时，你判定：若结果点数与此【杀】点数差值不大于1，则此【杀】对你无效。",
  ["os__guimen"] = "鬼门",
  [":os__guimen"] = "锁定技，当你因弃置而失去黑桃牌后，你判定：若结果点数与你弃置的其中一张黑桃牌点数差值不大于1，则对一名其他角色造成2点雷电伤害。",
  ["os__zhouzu"] = "咒诅",
  [":os__zhouzu"] = "出牌阶段限一次，你可选择一名其他角色并施法：令其弃置X张牌，若牌数不足则全部弃置并对其造成1点雷电伤害。",
  ["os__didao"] = "地道",
  [":os__didao"] = "当一名角色的判定牌生效前，你可打出一张牌替换之，若与原判定牌颜色相同，你摸一张牌。",

  ["os__revelation"] = "示",
  ["@os__fengji"] = "蜂集",
  ["#os__fengji-ask"] = "蜂集：你可将一张牌置于武将牌上，称为“示”并施法",
  ["#os__fengji-conjure"] = "蜂集：施法，第X个回合结束前，从牌堆中获得X张与“示”同名的牌，然后将“示”置入弃牌堆",
  ["#os__fengji_conjure"] = "蜂集",
  ["#os__budao-ask"] = "布道：选择一个技能获得，然后你可令一名其他角色获得相同技能并交给你一张牌",
  ["#os__budao-target"] = "布道：你可令一名其他角色获得〖%arg〗并交给你一张牌",
  ["#os__budao-card"] = "布道：交给 %src 一张牌",
  ["@os__zhouhu"] = "咒护",
  ["#os__zhouhu-ask"] = "咒护：你可弃置一张红色手牌，点击“确定”后选择一名角色并施法：令其回复X点体力",
  ["#os__zhouhu-target"] = "咒护：选择一名角色，点击“确定”后施法：令其回复X点体力",
  ["#os__zhouhu-conjure"] = "咒护：施法：令其回复X点体力",
  ["#os__zhouhu_conjure"] = "咒护",
  ["@os__zuhuo"] = "阻祸",
  ["#os__zuhuo-ask"] = "阻祸：你可弃置一张非基本牌并施法：防止你受到的下X次伤害",
  ["#os__zuhuo-conjure"] = "阻祸：施法：防止你受到的下X次伤害",
  ["#os__zuhuo_conjure"] = "阻祸",
  ["@os__zuhuo_defend"] = "阻祸防伤",
  ["@os__fengqi"] = "丰祈",
  ["#os__fengqi-ask"] = "丰祈：你可弃置一张黑色手牌，点击“确定”后选择一名角色并施法：其摸2X张牌",
  ["#os__fengqi-target"] = "丰祈：选择一名角色，点击“确定”后施法：其摸2X张牌",
  ["#os__fengqi-conjure"] = "丰祈：施法：摸2X张牌",
  ["#os__fengqi_conjure"] = "丰祈",
  ["#os__guimen-target"] = "鬼门：对一名其他角色造成2点雷电伤害",
  ["@os__zhouzu"] = "咒诅",
  ["#os__zhouzu_conjure"] = "咒诅",
  ["#os__didao-ask"] = "地道：你可打出一张牌替换 %src 的判定，若与原判定牌颜色相同，你摸一张牌",
  
  ["$os__fengji1"] = "蜂趋蚁附，皆为道来。",
  ["$os__fengji2"] = "蜂攒蚁集，皆为道往！",
  ["$os__yiju1"] = "鸱张蚁聚，为从天道！",
  ["$os__yiju2"] = "黄天之道，苍天之示。",
  ["$os__budao1"] = "得天之力，从天之道。",
  ["$os__budao2"] = "黄天大道，泽及苍生。",
  ["~zhangmancheng"] = "天师，曼成尽力了。",
}

local zhanghe = General(extension, "os_xing__zhanghe", "qun", 4)
local zhilue = fk.CreateTriggerSkill{
  name = "os_xing__zhilue",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"os_xing__zhilue_draw", "Cancel"}
    local room = player.room
    if #room:canMoveCardInBoard() > 0 then
      table.insert(choices, 1, "os_xing__zhilue_move")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data
    if choice == "os_xing__zhilue_move" then
      local targets = room:askForChooseToMoveCardInBoard(player, "#os_xing__zhilue-movecard", self.name, false)
      local card = room:askForMoveCardInBoard(player, room:getPlayerById(targets[1]), room:getPlayerById(targets[2]), self.name).card
      if player.dead then return end
      if card.type == Card.TypeEquip then
        room:loseHp(player, 1, self.name)
      elseif card.sub_type == Card.SubtypeDelayedTrick then
        room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 1)
      end
    else
      room:addPlayerMark(player, "@@os_xing__zhilue-turn")
    end
  end,
}
local zhilue_draw = fk.CreateTriggerSkill{
  name = "#os_xing__zhilue_draw",
  events = {fk.DrawNCards},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@os_xing__zhilue-turn") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@@os_xing__zhilue-turn")
  end,
}
local zhilue_buff = fk.CreateTargetModSkill{
  name = "#os_xing__zhilue_buff",
  residue_func = function(self, player, skill, scope, card)
    return (player:hasSkill(zhilue.name) and skill.trueName == "slash_skill") and 1 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return (player:hasSkill(zhilue.name) and skill.trueName == "slash_skill" and player:usedCardTimes("slash", Player.HistoryTurn) == 0) and 998 or 0
  end,
}
zhilue:addRelatedSkill(zhilue_draw)
zhilue:addRelatedSkill(zhilue_buff)

local zhanghe_win = fk.CreateActiveSkill{ name = "os_xing__zhanghe_win_audio" }
zhanghe_win.package = extension
Fk:addSkill(zhanghe_win)

zhanghe:addSkill(zhilue)

Fk:loadTranslationTable{
  ["os_xing__zhanghe"] = "星张郃",
  ["os_xing__zhilue"] = "知略",
  [":os_xing__zhilue"] = "准备阶段开始时，你可选择一项：1. 移动场上的一张牌，若此牌为：装备牌，你失去1点体力；延时锦囊牌，你此回合手牌上限-1；2. 此回合你摸牌阶段额定摸牌数+1，使用的第一张【杀】不计入次数且无距离限制。",

  ["os_xing__zhilue_move"] = "移动场上的一张牌，若此牌为：装备牌，你失去1点体力；延时锦囊牌，你此回合手牌上限-1",
  ["os_xing__zhilue_draw"] = "此回合你摸牌阶段额定摸牌数+1，使用的第一张【杀】不计入次数且无距离限制",
  ["#os_xing__zhilue-movecard"] = "知略：移动场上的一张牌，若此牌为：装备牌，你失去1点体力；延时锦囊牌，你此回合手牌上限-1",
  ["@@os_xing__zhilue-turn"] = "知略",

  ["$os_xing__zhilue1"] = "时以进而取之，无则磨锋以待。",
  ["$os_xing__zhilue2"] = "知敌之薄弱，略我之计谋。",
  ["~os_xing__zhanghe"] = "吾筹划而思，奈何还是慢了一步。",
  ["os_xing__zhanghe_win_audio"] = "胜利语音",
  ["$os_xing__zhanghe_win_audio"] = "天易之理可胜，知略更甚以往。",
}

local xiahouen = General(extension, "xiahouen", "wei", 5)
local os__fujian = fk.CreateTriggerSkill{
  name = "os__fujian",
  events = {fk.GameStart, fk.EventPhaseStart, fk.AfterCardsMove},
  mute = true,
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.AfterCardsMove then
      if player.phase ~= Player.NotActive then return false end
      for _, move in ipairs(data) do
        if move.from == player.id and (move.to ~= player.id or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).sub_type == Card.SubtypeWeapon and (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
              return true
            end
          end
        end
      end
    else
      return ((event == fk.GameStart or (player == target and target.phase == Player.Start))) and not player:getEquipment(Card.SubtypeWeapon)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, self.name, "negative")
      player:broadcastSkillInvoke(self.name, 2)
      room:loseHp(player, 1, self.name)
    else
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name, 1)
      local id = room:getCardsFromPileByRule(".|.|.|.|.|weapon")
      if #id > 0 then
        room:obtainCard(player, id[1], false, fk.ReasonPrey)
        if not player:getEquipment(Card.SubtypeWeapon) then
          player.room:moveCardTo(id, Card.PlayerEquip, player, fk.ReasonJustMove, self.name)
        end
      end
    end
  end,
}

local os__jianwei = fk.CreateTriggerSkill{
  name = "os__jianwei",
  anim_type = "offensive",
  events = {fk.TargetSpecified, fk.PindianCardsDisplayed},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or not player:getEquipment(Card.SubtypeWeapon) then return false end
    if event == fk.TargetSpecified then
      return target == player and data.card and data.card.trueName == "slash"
    else
      return data.from == player or table.contains(data.tos, player)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)
      data.extra_data = data.extra_data or {}
      data.extra_data.os__jianweiNullified = data.extra_data.os__jianweiNullified or {}
      data.extra_data.os__jianweiNullified[tostring(data.to)] = (data.extra_data.os__jianweiNullified[tostring(data.to)] or 0) + 1
    else
      local num = player:getAttackRange()
      if data.from == player then
        data.fromCard.number = math.min(data.fromCard.number + num, 13)
      else
        data.results[player.id].toCard.number = math.min(data.results[player.id].toCard.number + num, 13)
      end
    end
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.os__jianweiNullified
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.os__jianweiNullified) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark(fk.MarkArmorNullified) > 0 then
        room:removePlayerMark(p, fk.MarkArmorNullified, num)
      end
    end
    data.os__jianweiNullified = nil
  end,
}

local os__jianwei_pd = fk.CreateTriggerSkill{
  name = "#os__jianwei_pd",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(os__jianwei.name) or target.phase ~= Player.Start or target:isKongcheng() or not player:getEquipment(Card.SubtypeWeapon) then return false end
    if target == player then
      return table.find(player.room.alive_players, function(p)
        return not p:isKongcheng() and player:inMyAttackRange(p)
      end)
    else
      return not player:isKongcheng()
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = target.room
    if target == player then
      local availableTargets = table.map(
        table.filter(room.alive_players, function(p)
          return not p:isKongcheng() and player:inMyAttackRange(p)
        end),
        Util.IdMapper
      )
      if #availableTargets == 0 then return false end
      local targets = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__jianwei-target", self.name, true)
      if #targets > 0 then
        self.cost_data = targets[1]
        return true
      end
    else
      return room:askForSkillInvoke(target, self.name, data, "#os__jianwei-ask:" .. player.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = target.room
    room:notifySkillInvoked(player, os__jianwei.name, "special")
    player:broadcastSkillInvoke(os__jianwei.name)
    local to, pd, pd_target
    if target == player then
      to = room:getPlayerById(self.cost_data)
      pd_target = to
      pd = player:pindian({pd_target}, self.name)
    else
      to = target
      pd_target = player
      pd = target:pindian({pd_target}, self.name)
    end
    if pd.results[pd_target.id].winner == player then
      if to:isAllNude() then return end
      local dummy = Fk:cloneCard("dilu")
      local card_data = {}
      if to:getHandcardNum() > 0 then
        local handcards = {}
        for i = 1, to:getHandcardNum(), 1 do
          table.insert(handcards, -1) -- 手牌不可见
        end
        table.insert(card_data, {"$Hand", handcards})
      end
      local areas = {["$Equip"] = Player.Equip, ["$Judge"] = Player.Judge}
      for k, v in pairs(areas) do
        if #to.player_cards[v] > 0 then
          table.insert(card_data, {k, to:getCardIds(v)})
        end
      end
      local ret = room:askForPoxi(player, "os__jianwei_get", card_data, nil, false)
      local new_ret = table.filter(ret, function(id) return id ~= -1 end)
      local hand_num = #ret - #new_ret
      if hand_num > 0 then
        table.insertTable(new_ret, table.random(to:getCardIds(Player.Hand), hand_num))
      end
      dummy:addSubcards(new_ret)
      room:obtainCard(player, dummy, false, fk.ReasonPrey)
    else
      if player:getEquipment(Card.SubtypeWeapon) then room:obtainCard(to, player:getEquipment(Card.SubtypeWeapon), false, fk.ReasonPrey) end
    end
  end,
}
Fk:addPoxiMethod{
  name = "os__jianwei_get",
  card_filter = Util.TrueFunc,
  feasible = function(selected, data)
    return data and #data == #selected
  end,
  prompt = function ()
    return "剑威：获得其每个区域各一张牌"
  end,
  default_choice = function(data)
    if not data then return false end
    local cids = table.map(data, function(v) return v[2][1] end)
    return cids
  end,
}
os__jianwei:addRelatedSkill(os__jianwei_pd)

xiahouen:addSkill(os__fujian)
xiahouen:addSkill(os__jianwei)

Fk:loadTranslationTable{
  ["xiahouen"] = "夏侯恩",
  ["#xiahouen"] = "长坂剑灵",
  ["designer:xiahouen"] = "会玩的许劭",
  ["illustrator:xiahouen"] = "蚂蚁君",

  ["os__fujian"] = "负剑",
  [":os__fujian"] = "锁定技，①游戏开始时或准备阶段开始时，若你的装备区里没有武器牌，则你从牌堆中随机获得一张武器牌并将其置入装备区。②当你于回合外失去武器牌后，你失去1点体力。",
  ["os__jianwei"] = "剑威",
  [":os__jianwei"] = "若你装备区里有武器牌，你的【杀】无视防具，你拼点的点数+X（X为你的攻击范围），其他角色的准备阶段开始时，其可与你拼点；你的准备阶段开始时，你可与攻击范围内的一名角色拼点：若你赢，你获得其每个区域各一张牌；若你没赢，其获得你装备区里的武器牌。",

  ["#os__jianwei_pd"] = "剑威",
  ["#os__jianwei-target"] = "剑威：你可与一名攻击范围内的角色拼点：若你赢，你获得其每个区域各一张牌；若你没赢，其获得你装备区里的武器牌",
  ["#os__jianwei-ask"] = "剑威：你可与 %src 拼点：若其没赢，你获得其装备区里的武器牌；若其赢，其获得你每个区域各一张牌",
  ["os__jianwei_get"] = "剑威",

  ["$os__fujian1"] = "得此宝剑，如虎添翼！",
  ["$os__fujian2"] = "丞相至宝，汝岂配用之？啊！……",
  ["$os__jianwei1"] = "小小匹夫，可否闻长坂剑神之名号？",
  ["$os__jianwei2"] = "此剑吹毛得过，削铁如泥。",
  ["~xiahouen"] = "长坂剑神，也陨落了……",
}

local liuhong = General(extension, "os__liuhong", "qun", 4)
local os__yujue = fk.CreateTriggerSkill{
  name = "os__yujue",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player.phase ~= Player.NotActive then return false end
    for _, move in ipairs(data) do
      local from = move.from and player.room:getPlayerById(move.from) or nil
      if move.to == player.id and from and move.toArea == Card.PlayerHand then
        if from:getMark("_os__yujue-turn") < 3 then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, move in ipairs(data) do
      if not table.contains(targets, move.from) and move.from then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insert(targets, move.from)
          end
        end
      end
    end
    room:sortPlayersByAction(targets)
    for _, target_id in ipairs(targets) do
      if not player:hasSkill(self) then break end
      local skill_target = room:getPlayerById(target_id)
      if skill_target and not skill_target.dead and skill_target:getMark("_os__yujue-turn") < 3 and (skill_target:getMark("_os__yujue-turn") < 2 or table.find(room.alive_players, function(p)
          return not p:isNude() and skill_target:inMyAttackRange(p)
        end)) then
        self:doCost(event, skill_target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#os__yujue-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    --local choices = {"os__yujue_discard", "os__yujue_obtain"}
    local choices = {}
    local mark = target:getMark("_os__yujue-turn")
    local availableTargets
    if mark == 3 then return false end
    if mark ~= 1 then
      availableTargets = table.map(
        table.filter(room.alive_players, function(p)
          return not p:isNude() and target:inMyAttackRange(p)
        end),
        Util.IdMapper
      )
      if #availableTargets > 0 then table.insert(choices, "os__yujue_discard") end
    end
    if mark ~= 2 then table.insert(choices, "os__yujue_obtain") end
    if #choices == 0 then return false end
    local choice = room:askForChoice(target, choices, self.name)
    if choice == "os__yujue_discard" then
      local to = room:askForChoosePlayers(target, availableTargets, 1, 1, "#os__yujue-target", self.name, false)
      to = room:getPlayerById(to[1])
      local card = room:askForCardChosen(target, to, "he", self.name)
      room:throwCard(card, self.name, to, target)
      room:addPlayerMark(target, "_os__yujue-turn")
    else
      room:addPlayerMark(target, "@@os__yujue_obtain") --还没做！
      room:addPlayerMark(target, "_os__yujue-turn", 2)
    end
  end,
}
local os__yujue_do_obtain = fk.CreateTriggerSkill{
  name = "#os__yujue_do_obtain",
  events = {fk.CardUsing},
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@os__yujue_obtain") > 0 
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@@os__yujue_obtain")
    local cids = room:getCardsFromPileByRule(".|.|.|.|.|" .. data.card:getTypeString())
    if #cids > 0 then
      room:obtainCard(player, cids[1], false, fk.ReasonPrey)
    end
  end,
}
os__yujue:addRelatedSkill(os__yujue_do_obtain)
local os__yujue_skill = fk.CreateTriggerSkill{
  name = "#os__yujue_skill",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(os__yujue.name, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == os__yujue and player == target
    else
      return target == player and player:hasSkill(os__yujue.name, true, true)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(os__yujue.name, true) then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          room:handleAddLoseSkills(p, "os__yujue_others&", nil, false, true)
        end
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        room:handleAddLoseSkills(p, "-os__yujue_others&", nil, false, true)
      end
    end
  end,
}
os__yujue:addRelatedSkill(os__yujue_skill)
local os__yujue_others = fk.CreateActiveSkill{
  name = "os__yujue_others&",
  prompt = "#os__yujue_others",
  anim_type = "support",
  min_card_num = 1,
  max_card_num = function(self)
    local room = Fk:currentRoom()
    local num = 0
    local max_num = (Self.kingdom == "qun" and table.find(room.alive_players, function(p)
      return p:hasSkill("os__fengqix")
    end)) and 4 or 2
    for _, p in ipairs(room.alive_players) do
      if p:hasSkill("os__yujue") and p:getMark("_os__yujue-phase") < 2 and p ~= Self then
        num = math.max(num, max_num - p:getMark("_os__yujue-phase"))
      end
    end
    return num
  end,
  target_num = 0,
  can_use = function(self, player)
    local room = Fk:currentRoom()
    local max_num = (player.kingdom == "qun" and table.find(room.alive_players, function(p)
      return p:hasSkill("os__fengqix")
    end)) and 4 or 2
    for _, p in ipairs(room.alive_players) do
      if p:hasSkill("os__yujue") and p:getMark("_os__yujue-phase") < max_num and p ~= Self then
        return true
      end
    end
    return false
  end,
  card_filter = function(self, to_select, selected)
    local room = Fk:currentRoom()
    local num = 0
    local max_num = (Self.kingdom == "qun" and table.find(room.alive_players, function(p)
      return p:hasSkill("os__fengqix")
    end)) and 4 or 2
    for _, p in ipairs(room.alive_players) do
      if p:hasSkill("os__yujue") and p:getMark("_os__yujue-phase") < 2 and p ~= Self then
        num = math.max(num, max_num - p:getMark("_os__yujue-phase"))
      end
    end
    return #selected < num
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cards = effect.cards
    if #cards == 0 then return false end
    local max_num = (player.kingdom == "qun" and table.find(room.alive_players, function(p)
      return p:hasSkill("os__fengqix")
    end)) and 4 or 2 --还是错的
    local targets = table.filter(room:getOtherPlayers(player), function(p) return p:hasSkill("os__yujue") and max_num - p:getMark("_os__yujue-phase") >= #cards end)
    if #targets == 0 then return false end
    local to
    if #targets == 1 then
      to = targets[1]
    else
      to = room:getPlayerById(room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, nil, self.name, false)[1])
    end
    room:doIndicate(player.id, {to.id})
    --room:notifySkillInvoked(to, "os__yujue", "support")
    player:broadcastSkillInvoke("os__yujue")
    room:addPlayerMark(to, "_os__yujue-phase", #cards)
    room:moveCardTo(cards, Player.Hand, to, fk.ReasonGive, self.name, nil, false)
  end,
}
Fk:addSkill(os__yujue_others)

local os__gezhi = fk.CreateTriggerSkill{
  name = "os__gezhi",
  events = {fk.CardUsing, fk.EventPhaseEnd},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player.phase ~= Player.Play then return false end
    if event == fk.CardUsing then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e) 
        local use = e.data[1]
        return use.from == player.id and use.card.type == data.card.type
      end, Player.HistoryTurn)
      return #events == 1 and events[1].id == player.room.logic:getCurrentEvent().id
    else
      if player:usedSkillTimes(self.name, Player.HistoryPhase) < 2 then return false end
      for _, p in ipairs(player.room.alive_players) do
        if p:getMark("_os__gezhi") == 0 then return true end
        local num = 3
        if player:hasSkill("os__fengqix") then
          for _, skill_name in ipairs(Fk.generals[p.general]:getSkillNameList(true)) do
            if Fk.skills[skill_name].lordSkill and not p:hasSkill(skill_name) then
              num = 4
              break
            end
          end
          if target.deputyGeneral and target.deputyGeneral ~= "" then
            for _, skill_name in ipairs(Fk.generals[p.deputyGeneral]:getSkillNameList(true)) do
              if Fk.skills[skill_name].lordSkill and not p:hasSkill(skill_name) then
                num = 4
                break
              end
            end
          end
        end
        return #p:getMark("_os__gezhi") < num
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUsing then
      local id = player.room:askForCard(player, 1, 1, false, self.name, true, nil, "#os__gezhi-ask")
      if #id > 0 then
        self.cost_data = id[1]
        return true
      end
    else
      local availableTargets = {}
      for _, p in ipairs(player.room.alive_players) do
        if p:getMark("_os__gezhi") == 0 then
          table.insert(availableTargets, p.id)
        elseif #p:getMark("_os__gezhi") < 3 then
          table.insert(availableTargets, p.id)
        elseif #p:getMark("_os__gezhi") == 3 then
          if player:hasSkill("os__fengqix") then
            for _, skill_name in ipairs(Fk.generals[p.general]:getSkillNameList(true)) do
              if Fk.skills[skill_name].lordSkill and not p:hasSkill(skill_name) then
                table.insert(availableTargets, p.id)
                break
              end
            end
            if target.deputyGeneral and target.deputyGeneral ~= "" then
              for _, skill_name in ipairs(Fk.generals[p.deputyGeneral]:getSkillNameList(true)) do
                if Fk.skills[skill_name].lordSkill and not p:hasSkill(skill_name) then
                  table.insertIfNeed(availableTargets, p.id)
                  break
                end
              end
            end
          end
        end
      end
      if #availableTargets == 0 then return false end
      local target = player.room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__gezhi-target", self.name, true)
      if #target > 0 then
        self.cost_data = target[1]
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:recastCard(self.cost_data, player, self.name)
    else
      local target = room:getPlayerById(self.cost_data)
      local allChoices = {"os__gezhi_ar", "os__gezhi_maxcard", "os__gezhi_maxhp"}
      if player:hasSkill("os__fengqix") then
        for _, skill_name in ipairs(Fk.generals[target.general]:getSkillNameList(true)) do
          if Fk.skills[skill_name].lordSkill and not target:hasSkill(skill_name) then
            table.insert(allChoices, "os__gezhi_lordskill")
            break
          end
        end
        if target.deputyGeneral and target.deputyGeneral ~= "" then
          for _, skill_name in ipairs(Fk.generals[target.deputyGeneral]:getSkillNameList(true)) do
            if Fk.skills[skill_name].lordSkill and not target:hasSkill(skill_name) then
              table.insertIfNeed(allChoices, "os__gezhi_lordskill")
              break
            end
          end
        end
      end
      local choices = {}
      if target:getMark("_os__gezhi") ~= 0 then
        for i = 1, #allChoices do
          if not table.contains(target:getMark("_os__gezhi"), i) then
            table.insert(choices, allChoices[i])
          end
        end
      else
        choices = allChoices
      end
      local record = U.getMark(target, "_os__gezhi")
      local choice = room:askForChoice(target, choices, self.name)
      if choice == "os__gezhi_lordskill" then
        local skills = {}
        for _, skill_name in ipairs(Fk.generals[target.general]:getSkillNameList(true)) do
          if Fk.skills[skill_name].lordSkill and not target:hasSkill(skill_name) then
            table.insertIfNeed(skills, skill_name)
          end
        end
        if target.deputyGeneral and target.deputyGeneral ~= "" then
          for _, skill_name in ipairs(Fk.generals[target.deputyGeneral]:getSkillNameList(true)) do
            if Fk.skills[skill_name].lordSkill and not target:hasSkill(skill_name) then
              table.insertIfNeed(skills, skill_name)
            end
          end
        end
        if #skills > 0 then
          room:handleAddLoseSkills(target, table.concat(skills, "|"), nil, true, false)
        end
        table.insert(record, 4)
      elseif choice == "os__gezhi_ar" then
        room:addPlayerMark(target, "@@os__gezhi_ar")
        table.insert(record, 1)
      elseif choice == "os__gezhi_maxcard" then
        room:addPlayerMark(target, MarkEnum.AddMaxCards, 2)
        table.insert(record, 2)
      else
        room:changeMaxHp(target, 1)
        table.insert(record, 3)
      end
      room:setPlayerMark(target, "_os__gezhi", record)
    end
  end,
}
local os__gezhi_ar = fk.CreateAttackRangeSkill{
  name = "#os__gezhi_ar",
  correct_func = function(self, from, to)
    return (from:getMark("@@os__gezhi_ar") ~= 0) and from:getMark("@@os__gezhi_ar") * 2 or 0
  end,
}
os__gezhi:addRelatedSkill(os__gezhi_ar)

local os__fengqix = fk.CreateTriggerSkill{
  name = "os__fengqix$",
  frequency = Skill.Compulsory,
}

liuhong:addSkill(os__yujue)
liuhong:addSkill(os__gezhi)
liuhong:addSkill(os__fengqix)

Fk:loadTranslationTable{
  ["os__liuhong"] = "刘宏",
  ["os__yujue"] = "鬻爵",
  [":os__yujue"] = "①其他角色的出牌阶段，其可交给你任意张牌（每阶段至多两张）。②你的回合外，你每获得其他角色的一张牌，你可令其选择一项：1. 弃置攻击范围内的一名其他角色的一张牌；2. 使用下一张牌时获得一张同类型的牌。（每名角色每回合每项限一次）",
  ["os__gezhi"] = "革制",
  [":os__gezhi"] = "①当你于你的出牌阶段使用牌时，若为你此阶段首次使用此类型的牌，你可重铸一张手牌。②出牌阶段结束时，若本阶段你以此法重铸了至少两张牌，你可令一名角色选择一项：1. 攻击范围+2；2. 手牌上限+2；3. 体力上限+1。（每名角色每项限一次）",
  ["os__fengqix"] = "烽起", -- 上声用x，去声用h（s），入声用-p/t/k
  [":os__fengqix"] = "主公技，锁定技，群雄角色出牌阶段可因〖鬻爵〗交给你牌数量修改为4；武将牌上有主公技的角色成为〖革制〗指定的角色时，其选项增加一项：获得其武将牌上的主公技。",

  ["#os__yujue-invoke"] = "你想对 %dest 发动技能“鬻爵”吗？",
  ["os__yujue_discard"] = "弃置攻击范围内的一名角色的一张牌",
  ["os__yujue_obtain"] = "使用下一张牌时获得一张同类型的牌",
  ["#os__yujue_do_obtain"] = "鬻爵",
  ["#os__yujue-target"] = "鬻爵：选择攻击范围内的一名角色，弃置其一张牌",
  ["@@os__yujue_obtain"] = "鬻爵拿牌",
  ["os__yujue_others&"] = "鬻爵",
  [":os__yujue_others&"] = "出牌阶段，你可交给刘宏任意张牌（每阶段至多两张）。若其有〖烽起〗且你为群雄角色，“两”修改为“四”。",
  ["#os__yujue_others"] = "鬻爵：你可交给汉孝灵皇帝刘宏一些牌，他可能会给你加官进爵",
  ["#os__gezhi-ask"] = "革制：你可重铸一张手牌",
  ["#os__gezhi-target"] = "你可选择一名角色，对其发动“革制”",
  ["os__gezhi_ar"] = "攻击范围+2",
  ["os__gezhi_maxcard"] = "手牌上限+2",
  ["os__gezhi_maxhp"] = "体力上限+1",
  ["os__gezhi_lordskill"] = "获得你武将牌上的主公技",
  ["@@os__gezhi_ar"] = "革制攻击范围+2",

  ["$os__yujue1"] = "财物交足，官位任取。",
  ["$os__yujue2"] = "卖官鬻爵，取财之道。",
  ["$os__gezhi1"] = "改革旧制，保我汉室长存！",
  ["$os__gezhi2"] = "革除旧弊，方乃中兴！",
  ["~os__liuhong"] = "汉室中兴，还需尔等忠良。",
}

local os__mayunlu = General(extension, "os__mayunlu", "shu", 4, 4, General.Female)
local os__fengpo = fk.CreateTriggerSkill{
  name = "os__fengpo",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card.name == "duel") and #AimGroup:getAllTargets(data.tos) == 1 and not player.room:getPlayerById(data.to):isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local cids = to:getCardIds(Player.Hand)

    local update = player:getMark("@@os__fengpo_update") > 0
    if not update then
      if #room.logic:getEventsOfScope(GameEvent.Death, 1, function(e) 
        local death = e.data[1]
        return death.damage and death.damage.from == player
      end, Player.HistoryGame) == 1 then
        update = true
        room:setPlayerMark(player, "@@os__fengpo_update", 1)
      end
    end
    local n = update and #table.filter(cids, function(id) 
      return Fk:getCardById(id).color == Card.Red
    end) or #table.filter(cids, function(id) 
      return Fk:getCardById(id).suit == Card.Diamond
    end)

    local choice = "os__fengpo_draw:::" .. n -- default
    local result = room:askForCustomDialog(player, self.name,
      "packages/utility/qml/ChooseCardsAndChoiceBox.qml", {
        cids,
        {"os__fengpo_draw:::" .. n, "os__fengpo_damage:::" .. n},
        "#os__fengpo-choose::" .. data.to,
        {}, 0, 0,
      })
    if result ~= "" then
      local reply = json.decode(result)
      choice = reply.choice
    end

    if choice:startsWith("os__fengpo_draw") then
      player:drawCards(n, self.name)
    else
      data.additionalDamage = (data.additionalDamage or 0) + n
    end
  end,

  refresh_events = {fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and data.damage and data.damage.from == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@os__fengpo_update", 1)
  end,
}
os__mayunlu:addSkill("mashu")
os__mayunlu:addSkill(os__fengpo)

Fk:loadTranslationTable{
  ["os__mayunlu"] = "马云騄",
  ["os__fengpo"] = "凤魄",
  [":os__fengpo"] = "当你使用【杀】或【决斗】仅指定一名角色为目标后，你可观看其手牌然后选择一项：1. 摸X张牌；2. 令此牌的伤害值基数+X（X为其<font color='red'>♦</font>手牌数，若你于本局游戏内杀死过角色，则修改为“其红色手牌数”）。",

  ["#os__fengpo-choose"] = "凤魄：观看%dest的手牌并选择",
  ["os__fengpo_draw"] = "摸%arg张牌",
  ["os__fengpo_damage"] = "令此牌的伤害值基数+%arg",
  ["@@os__fengpo_update"] = "凤魄2级",

  ["$os__fengpo1"] = "看我不好好杀杀你的威风。",
  ["$os__fengpo2"] = "贼人是不是被本姑娘吓破胆了呀？",
  ["~os__mayunlu"] = "子龙哥哥，救我……",
}

local os__haomeng = General(extension, "os__haomeng", "qun", 4)

local function getTrueSkills(player)
  local skills = {}
  for _, s in ipairs(player.player_skills) do
    if not (s.attached_equip or s.name[#s.name] == "&" or s.name == "m_feiyang" or s.name == "m_bahu") then
      table.insertIfNeed(skills, s.name)
    end
  end
  return skills
end

local os__gongge = fk.CreateTriggerSkill{
  name = "os__gongge",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name) < 1 and data.card.is_damage_card and data.to
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(data.to)
    local x = #getTrueSkills(target)
    local choices = {"os__gongge_draw:::" .. x + 1, "os__gongge_damage:" .. data.to ..  "::" .. x, "Cancel"}
    if #target:getCardIds{Player.Equip, Player.Hand} > x then table.insert(choices, 2, "os__gongge_discard:" .. data.to .. "::" .. x + 1) end
    local choice = room:askForChoice(player, choices, self.name, "#os__gongge-choice::" .. data.to)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "offensive")
    data.card.extra_data = data.card.extra_data or {}
    data.card.extra_data.os__gonggeTarget = data.to
    data.card.extra_data.os__gonggeUser = player.id
    local target = room:getPlayerById(data.to)
    room:doIndicate(player.id, {target.id})
    local choice = self.cost_data
    local x = #getTrueSkills(target)
    if choice:startsWith("os__gongge_draw") then
      player:broadcastSkillInvoke(self.name, 1)
      player:drawCards(x+1, self.name)
      room:setPlayerMark(player, "@os__gongge", "os__gonggeDraw")
    elseif choice:startsWith("os__gongge_discard") then
      player:broadcastSkillInvoke(self.name, 2)
      local cards = room:askForCardsChosen(player, target, x+1, x+1, "he", self.name)
      room:throwCard(cards, self.name, target, player)
      room:setPlayerMark(player, "@os__gongge", "os__gonggeDiscard")
    elseif choice:startsWith("os__gongge_damage") then
      player:broadcastSkillInvoke(self.name, 3)
      data.additionalDamage = (data.additionalDamage or 0) + x
      room:setPlayerMark(player, "@os__gongge", "os__gonggeDamage")
    end
  end,
}
local os__gongge_judge = fk.CreateTriggerSkill{
  name = "#os__gongge_judge",
  mute = true,
  events = {fk.CardUseFinished, fk.EventPhaseChanging},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return false end
    if event == fk.EventPhaseChanging then
      return data.to == Player.Draw and player:getMark("@@os__gongge_skip") ~= 0
    else
      return (data.card.extra_data or {}).os__gonggeUser == player.id and player:getMark("@os__gongge") ~= 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseChanging then
      room:setPlayerMark(player, "@@os__gongge_skip", 0)
      return true
    else
      local target = room:getPlayerById(data.card.extra_data.os__gonggeTarget)
      if target.dead then
        room:setPlayerMark(player, "@os__gongge", 0)
      end
      local x = #getTrueSkills(target)
      if player:getMark("@os__gongge") == "os__gonggeDiscard" then
        if target.hp >= player.hp then
          local cids
          if #player:getCardIds{Player.Equip, Player.Hand}> x then
            cids = room:askForCard(player, x, x, true, self.name, false, "", "#os__gongge-cards::" .. target.id .. ":" .. x)
          else
            cids = player:getCardIds{Player.Equip, Player.Hand}
          end
          if #cids > 0 then
            room:moveCardTo(cids, Player.Hand, target, fk.ReasonGive, self.name, nil, false)
          end
        end
      elseif player:getMark("@os__gongge") == "os__gonggeDamage" then
        room:recover({
          who = target,
          num = math.min(x, target.maxHp - target.hp),
          recoverBy = player,
          skillName = self.name,
        })
      end
      room:setPlayerMark(player, "@os__gongge", 0)
    end
  end,

  refresh_events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@os__gongge") == "os__gonggeDraw" and ((event == fk.CardUseFinished and data.toCard and (data.toCard.extra_data or {}).os__gonggeTarget == target.id) or (event == fk.CardRespondFinished and (data.responseToEvent.card.extra_data or {}).os__gonggeTarget == target.id)) and
      data.responseToEvent and data.responseToEvent.from == player.id 
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@os__gongge_skip", 1)
  end,
}

os__gongge:addRelatedSkill(os__gongge_judge)
os__haomeng:addSkill(os__gongge)

Fk:loadTranslationTable{
  ["os__haomeng"] = "郝萌",
  ["os__gongge"] = "攻阁",
  [":os__gongge"] = "每回合限一次，当你使用伤害类的牌指定目标后，你可选择一项：1. 摸X+1张牌，若此牌被其响应，你跳过下次摸牌阶段；" .. 
  "2. 弃置其X+1张牌，此牌结算后，若其体力值不小于你，你交给其X张牌；3. 此牌对其伤害值基数+X，此牌结算后其回复X点体力。（X为其武将技能数）",

  ["#os__gongge-choice"] = "你想对 %dest 发动技能“攻阁”吗？",
  ["os__gongge_draw"] = "摸%arg张牌",
  ["os__gongge_discard"] = "弃置%src%arg张牌",
  ["os__gongge_damage"] = "对%src伤害+%arg",
  ["@os__gongge"] = "攻阁",
  ["os__gonggeDraw"] = "摸牌",
  ["os__gonggeDiscard"] = "弃牌",
  ["os__gonggeDamage"] = "加伤",
  ["#os__gongge-cards"] = "攻阁：交给 %dest %arg张牌",
  ["@@os__gongge_skip"] = "攻阁跳摸牌",
  ["#os__gongge_judge"] = "攻阁",

  ["$os__gongge1"] = "弓弩并射难近其身，若退又恐难安己命！",
  ["$os__gongge2"] = "既已决心反之，当速擒吕布以溃其兵士！",
  ["$os__gongge3"] = "今行至如此，唯殊死一搏！",
  ["~os__haomeng"] = "反复小儿！汝竟临阵倒戈……",
}

local jiangji = General(extension, "jiangji", "wei", 3)

--[[
local os__jichou = fk.CreateActiveSkill{
  name = "os__jichou",
  can_use = function(self, player)
    return player:usedSkillTimes("os__jichou_give", Player.HistoryPhase) == 0 or player:usedSkillTimes("os__jichou_vs", Player.HistoryTurn) == 0
  end,
  card_filter = Util.FalseFunc,
  target_num = 0,
  interaction = function(self)
    local choiceList = {}
    if Self:usedSkillTimes("os__jichou_give", Player.HistoryPhase) == 0 then table.insert(choiceList, "os__jichou_give") end
    if Self:usedSkillTimes("os__jichou_vs", Player.HistoryTurn) == 0 then table.insert(choiceList, "os__jichou_vs") end
    return UI.ComboBox { choices = choiceList }
  end,
  on_use = function(self, room, effect)
    local choice = self.interaction.data
    if not choice then return false end
    local player = room:getPlayerById(effect.from)
    if choice == "os__jichou_give" then
      player:addSkillUseHistory(choice) --呃
      room:askForUseActiveSkill(player, choice, "#os__jichou-give", true)
    else
      local success, dat = room:askForUseViewAsSkill(player, choice, "#os__jichou-vs", true)
      if success then
        player:addSkillUseHistory(choice) --呃
        local card = Fk.skills["os__jichou_vs"]:viewAs(dat.cards)
        local use = {
          from = effect.from,
          tos = table.map(dat.targets, function(e) return {e} end),
          card = card,
        } 
        Fk.skills["os__jichou_vs"]:beforeUse(player, use)
        room:useCard(use)
      end
    end
  end,
}
--]]
local os__jichou = fk.CreateViewAsSkill{
  name = "os__jichou",
  card_filter = Util.FalseFunc,
  card_num = 0,
  prompt = "#os__jichou",
  pattern = ".|.|.|.|.|trick",
  interaction = function(self)
    local allCardNames, cardNames = {}, {}
    local os__jichouRecord = type(Self:getMark("@$os__jichou")) == "table" and Self:getMark("@$os__jichou") or {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:cloneCard(Fk:getCardById(id).name)
      if card:isCommonTrick() and not table.contains(allCardNames, card.name) and not table.contains(os__jichouRecord, card.name) and not card.is_derived then
        table.insert(allCardNames, card.name)
        if not Self:prohibitUse(card) and ((Fk.currentResponsePattern == nil and Self:canUse(card)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
          table.insert(cardNames, card.name)
        end
      end
    end
    return UI.ComboBox { choices = cardNames, all_choices = allCardNames }
  end,
  view_as = function(self, cards)
    local choice = self.interaction.data
    if not choice then return end
    local c = Fk:cloneCard(choice)
    c.skillName = self.name
    return c
  end,
  before_use = function(self, player, use)
    if player:hasSkill("os__jilun") then
      local record = type(player:getMark("@$os__jilun")) == "table" and player:getMark("@$os__jilun") or {}
      table.insert(record, use.card.name)
      player.room:setPlayerMark(player, "@$os__jilun", record)
    end
  end,
  enabled_at_play = function(self, player)
    local os__jichouRecord = type(player:getMark("@$os__jichou")) == "table" and player:getMark("@$os__jichou") or {}
    if player:usedSkillTimes(self.name) > 0 then return false end
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:cloneCard(Fk:getCardById(id).name)
      if card:isCommonTrick() and not table.contains(os__jichouRecord, card.name) and not card.is_derived and not player:prohibitUse(card) and ((Fk.currentResponsePattern == nil and player:canUse(card)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        return true
      end
    end
    return false
  end,
  enabled_at_response = function(self, player)
    local os__jichouRecord = type(player:getMark("@$os__jichou")) == "table" and player:getMark("@$os__jichou") or {}
    if player:usedSkillTimes(self.name) > 0 then return false end
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:cloneCard(Fk:getCardById(id).name)
      if card:isCommonTrick() and not table.contains(os__jichouRecord, card.name) and not card.is_derived and not player:prohibitUse(card) and ((Fk.currentResponsePattern == nil and player:canUse(card)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        return true
      end
    end
    return false
  end,
}
local os__jichou_prohibit = fk.CreateProhibitSkill{
  name = "#os__jichou_prohibit",
  prohibit_use = function(self, player, card)
    if not table.contains(player:getCardIds(Player.Hand), card.id) then return false end
    return type(player:getMark("@$os__jichou")) == "table" and table.contains(player:getMark("@$os__jichou"), card.name)
  end,
}
local os__jichou_dr = fk.CreateTriggerSkill{
  name = "#os__jichou_dr",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return type(player:getMark("@$os__jichou")) == "table" and table.contains(player:getMark("@$os__jichou"), data.card.name)
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insertIfNeed(data.disresponsiveList, player.id)
  end,

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return player == target and table.contains(data.card.skillNames, "os__jichou")
    else
      return data == os__jichou and player == target
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      local record = type(player:getMark("@$os__jichou")) == "table" and player:getMark("@$os__jichou") or {}
      table.insert(record, data.card.name)
      player.room:setPlayerMark(player, "@$os__jichou", record)
    else
      player.room:handleAddLoseSkills(player, event == fk.EventAcquireSkill and "os__jichou_give&" or "-os__jichou_give&", nil, false, true)
    end
  end,
}
local os__jichou_give = fk.CreateActiveSkill{
  name = "os__jichou_give&", --乐
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return table.contains(type(Self:getMark("@$os__jichou")) == "table" and Self:getMark("@$os__jichou") or {}, Fk:getCardById(to_select).name) and #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    room:moveCardTo(effect.cards, Player.Hand, room:getPlayerById(effect.tos[1]), fk.ReasonGive, self.name, nil, false)
  end,
}
os__jichou:addRelatedSkill(os__jichou_prohibit)
os__jichou:addRelatedSkill(os__jichou_dr)
Fk:addSkill(os__jichou_give)

local os__jilun = fk.CreateTriggerSkill{ --机论的获得技能
  name = "os__jilun",
  events = {fk.Damaged},
  anim_type = "masochism",
  on_cost = function(self, event, target, player, data)
    local num = type(player:getMark("@$os__jichou")) == "table" and #player:getMark("@$os__jichou") or 0
    local choices = {"os__jilun_draw:::" .. math.min(math.max(num, 1), 5), "Cancel"}
    local os__jilunRecord = type(player:getMark("@$os__jilun")) == "table" and player:getMark("@$os__jilun") or {}
    for _, name in ipairs(os__jilunRecord) do
      local card = Fk:cloneCard(name)
      if not player:prohibitUse(card) and player:canUse(card) then
        table.insert(choices, 2, "os__jilun_use")
        break
      end
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#os__jilun-ask")
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data
    if choice == "os__jilun_use" then
      local success, dat = room:askForUseViewAsSkill(player, "os__jilun_vs", "#os__jilun-vs", false)
      if success then
        local card = Fk.skills["os__jilun_vs"]:viewAs(dat.cards)
        local use = {
          from = player.id,
          tos = table.map(dat.targets, function(e) return {e} end),
          card = card,
        } 
        Fk.skills["os__jilun_vs"]:beforeUse(player, use)
        room:useCard(use)
      end
    else
      local num = type(player:getMark("@$os__jichou")) == "table" and #player:getMark("@$os__jichou") or 0
      player:drawCards(math.min(math.max(num, 1), 5), self.name)
    end
  end,
}
local os__jilun_vs = fk.CreateViewAsSkill{
  name = "os__jilun_vs",
  card_filter = Util.FalseFunc,
  card_num = 0,
  pattern = "nullification",
  interaction = function(self)
    local allCardNames = {}
    local os__jilunRecord = type(Self:getMark("@$os__jilun")) == "table" and Self:getMark("@$os__jilun") or {}
    for _, name in ipairs(os__jilunRecord) do
      local card = Fk:cloneCard(name)
      card.skillName = self.name
      if not Self:prohibitUse(card) and Self:canUse(card) then
        table.insert(allCardNames, name)
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
    local os__jilunRecord = type(player:getMark("@$os__jilun")) == "table" and player:getMark("@$os__jilun") or {}
    table.removeOne(os__jilunRecord, use.card.name)
    player.room:setPlayerMark(player, "@$os__jilun", os__jilunRecord)
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = Util.FalseFunc,
}
Fk:addSkill(os__jilun_vs)

jiangji:addSkill(os__jichou)
jiangji:addSkill(os__jilun)

Fk:loadTranslationTable{
  ["jiangji"] = "蒋济",
  ["#jiangji"] = "盛魏昌杰",
  ["designer:jiangji"] = "Loun老萌",
  ["os__jichou"] = "急筹",
  [":os__jichou"] = "①每回合限一次，你可视为使用一种普通锦囊牌，然后本局游戏你无法以此法或自手牌中使用此牌名的牌，且不可响应此牌名的牌。②出牌阶段限一次，你可将手牌中“急筹”使用过的其牌名的一张牌交给一名角色。",
  ["os__jilun"] = "机论",
  [":os__jilun"] = "当你受到伤害后，你可选择一项：1. 摸X张牌（X为以“急筹”使用过的锦囊牌数，至少为1至多为5）；2. 视为使用一种以“急筹”使用过的牌（每牌名限一次）。",

  --["os__jichou_vs"] = "急筹[印牌]",
  ["#os__jichou"] = "急筹：你可视为使用一种普通锦囊牌，然后本局游戏你无法以此法或自手牌中使用此牌名的牌，且不可响应此牌名的牌",
  ["#os__jichou_dr"] = "急筹",
  ["os__jichou_give&"] = "<font color='grey'>急筹[给牌]</font>",
  [":os__jichou_give&"] = "<font color='grey'>出牌阶段限一次，你可将手牌中“急筹”使用过的其牌名的一张牌交给一名角色。</font>",
  ["#os__jichou-give"] = "急筹：可将手牌中“急筹”使用过的其牌名的牌交给一名角色",
  ["@$os__jichou"] = "急筹",
  ["@$os__jilun"] = "机论",
  ["#os__jilun-ask"] = "机论：请选择一项",
  ["os__jilun_draw"] = "摸%arg张牌",
  ["os__jilun_use"] = "视为使用一种以“急筹”使用过的牌（每牌名限一次）",
  ["#os__jilun-vs"] = "视为使用一种以“急筹”使用过的牌（每牌名限一次）",
  ["os__jilun_vs"] = "机论",
  
  ["$os__jichou1"] = "此危亡之时，当出此急谋。",
  ["$os__jichou2"] = "急筹布画，运策捭阖。",
  ["$os__jilun1"] = "时移不移，违天之祥也。",
  ["$os__jilun2"] = "民望不因，违人之咎也。",
  ["~jiangji"] = "洛水之誓，言犹在耳……咳咳咳",
}

local yangang = General(extension, "yangang", "qun", 4)

local os__zhiqu = fk.CreateTriggerSkill{
  name = "os__zhiqu",
  events = {fk.EventPhaseStart},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local num = #table.filter(room.alive_players, function(p) return player:distanceTo(p) <= 1 end)
    local target = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#os__zhiqu-ask:::" .. num, self.name, true)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = #table.filter(room.alive_players, function(p) return player:distanceTo(p) <= 1 end)
    local to = room:getPlayerById(self.cost_data)
    local wrestle = player:inMyAttackRange(to) and to:inMyAttackRange(player)
    room:setPlayerMark(player, MarkEnum.BypassTimesLimit, 1)
    room:setPlayerMark(player, MarkEnum.BypassDistancesLimit, 1)
    --num = 50
    for i = 1, num, 1 do
      local id = room:getNCards(1)[1]
      room:moveCardTo(id, Card.Processing, nil, fk.ReasonJustMove, self.name)
      local card = Fk:getCardById(id)
      if (card.trueName == "slash" or card.name == "n_brick") and not player:prohibitUse(card) and not player:isProhibited(to, card) and not to.dead then --彩蛋
        room:useCard({
          card = card,
          from = player.id,
          tos = { {to.id} },
          skillName = self.name,
          extraUse = true,
        })
      end
      if wrestle and card.type == Card.TypeTrick and player:canUse(card) and not player:prohibitUse(card) then --大有问题
        local targets = {}
        if (table.contains({"savage_assault", "archery_attack", "duel", "enemy_at_the_gates", "drowning", "unexpectation", "raid_and_frontal_attack"}, card.name) or
          (table.contains({"snatch", "dismantlement", "chasing_near"}, card.name) and not to:isAllNude()) or 
          (card.name == "indulgence" and not to:hasDelayedTrick("indulgence")) or
          (card.name == "supply_shortage" and not to:hasDelayedTrick("supply_shortage"))) and not player:isProhibited(to, card) then
          table.insert(targets, to.id)
        end
        if table.contains({"amazing_grace", "god_salvation", "iron_chain", "redistribute", "underhanding", "fire_attack"}, card.name)
          and not (player:isProhibited(player, card) and player:isProhibited(to, card)) then
          targets = {player.id, to.id}
        end
        if table.contains({"ex_nihilo", "foresight"}, card.name) and not player:isProhibited(player, card) then
          table.insert(targets, player.id)
        end
        --[[
          if card.skill:targetFilter(to.id, {}, {}, card) and not player:isProhibited(to, card) then
          table.insertIfNeed(targets, to.id)
        end
        if card.skill:targetFilter(player.id, {}, {}, card) and not player:isProhibited(player, card) then
          table.insertIfNeed(targets, player.id)
        end
        --]]
        local use = {
          from = player.id,
          card = card,
          skillName = self.name,
        } 
        if #targets == 1 then
          use.tos = { targets }
          room:useCard(use)
        elseif #targets > 1 then
          if table.contains({"amazing_grace", "god_salvation"}, card.name) then
            use.tos = { {player.id}, {to.id} }
            room:useCard(use)
          elseif card.skill:getMaxTargetNum(player, card) == 1 then
            local tar = room:askForChoosePlayers(player, targets, 1, 1, "#os__zhiqu-targets::" .. to.id .. ":" .. card:toLogString(), self.name, false, true)
            use.tos = { tar }
            room:useCard(use)
          elseif card.skill:getMaxTargetNum(player, card) > 1 then
            if table.contains({"iron_chain", "underhanding"}, card.name) then
              local tar = room:askForChoosePlayers(player, targets, 1, 2, "#os__zhiqu-targets::" .. to.id .. ":" .. card:toLogString(), self.name, false, true)
              use.tos = table.map(tar, function(pid) return { pid } end)
              room:useCard(use)
            else
              use.tos = {targets}
              room:useCard(use)
            end
          end
        end
        --local use = room:askForUseCard(player, card.name, ".|.|.|.|.|.|" .. id, "#os__zhiqu-use::" .. to.id .. ":" .. card.name, false, {bypass_distances = true, bypass_times = true})
      end
    end
    room:setPlayerMark(player, MarkEnum.BypassTimesLimit, 0)
    room:setPlayerMark(player, MarkEnum.BypassDistancesLimit, 0)
  end,
}

local os__xianfeng = fk.CreateTriggerSkill{
  name = "os__xianfeng",
  events = {fk.Damage},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.to ~= player and data.card and data.card.is_damage_card and not player.dead and not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#os__xianfeng::" .. data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = data.to
    local choice = room:askForChoice(target, {"os__xianfeng_self", "os__xianfeng_yg"}, self.name, "#os__xianfeng-ask:" .. player.id)
    if choice == "os__xianfeng_self" then
      target:drawCards(1, self.name)
      room:addPlayerMark(player, "@os__xianfeng")
    else
      player:drawCards(1, self.name)
      local record = type(player:getMark("_os__xianfeng_others")) == "table" and player:getMark("_os__xianfeng_others") or {}
      table.insert(record, target.id)
      room:setPlayerMark(player, "_os__xianfeng_others", record)
      record = type(target:getMark("@os__xianfeng_others")) == "table" and target:getMark("@os__xianfeng_others") or {player.general, 0}
      record[2] = record[2] - 1
      room:setPlayerMark(target, "@os__xianfeng_others", record)
    end
  end,
}
local os__xianfeng_distance = fk.CreateDistanceSkill{
  name = "#os__xianfeng_distance",
  correct_func = function(self, from, to)
    if from:getMark("@os__xianfeng") > 0 then
      return -from:getMark("@os__xianfeng")
    end
  end,
}
local os__xianfeng_others_distance = fk.CreateDistanceSkill{
  name = "#os__xianfeng_others_distance",
  correct_func = function(self, from, to)
    if to:getMark("_os__xianfeng_others") ~= 0 then
      return -#table.filter(to:getMark("_os__xianfeng_others"), function(pid) return from.id == pid end)
    end
  end,
}
local os__xianfeng_cleaner = fk.CreateTriggerSkill{
  name = "#os__xianfeng_cleaner",
  refresh_events = {fk.TurnStart, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if target ~= player then return false end
    if event == fk.TurnStart then
      return player:getMark("@os__xianfeng") ~= 0 or player:getMark("_os__xianfeng_others") ~= 0
    else
      return player:getMark("_os__xianfeng_others") ~= 0
    end
    return false
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@os__xianfeng", 0)
    room:setPlayerMark(player, "_os__xianfeng_others", 0)
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@os__xianfeng_others", 0) --摆烂
    end
  end,
}
os__xianfeng:addRelatedSkill(os__xianfeng_distance)
os__xianfeng:addRelatedSkill(os__xianfeng_others_distance)
os__xianfeng:addRelatedSkill(os__xianfeng_cleaner)

yangang:addSkill(os__zhiqu)
yangang:addSkill(os__xianfeng)

Fk:loadTranslationTable{
  ["yangang"] = "严纲",
  ["os__zhiqu"] = "直取",
  [":os__zhiqu"] = "结束阶段开始时，你可选择一名其他角色并依次亮出牌堆顶X张牌，对其使用其中的【杀】。（X为你至其距离1以内的角色数）若搏击：改为使用其中的【杀】和锦囊牌，这些牌只能指定你或其为目标。" ..
  "<br/><font color='grey'>#\"<b>搏击</b>\"：你与其在彼此的攻击范围内",
  ["os__xianfeng"] = "先锋",
  [":os__xianfeng"] = "当你于出牌阶段使用伤害牌对其他角色造成伤害后，你可令其选择一项：1. 其摸一张牌，直到你的下回合开始，你至其他角色距离-1；2. 你摸一张牌，直到你的下回合开始，其至你距离-1。",

  ["#os__zhiqu-ask"] = "你可对一名其他角色发动“直取”，依次亮出牌堆顶的 %arg 张牌，使用其中的一些牌",
  ["#os__zhiqu-targets"] = "直取：选择 你或/和%dest 成为 %arg 的目标",
  ["#os__xianfeng"] = "你想对 %dest 发动技能“先锋”吗？",
  ["#os__xianfeng-ask"] = "先锋：对 %src 选择一项",
  ["os__xianfeng_self"] = "你摸一张牌，直到其下回合开始，其至你距离-1",
  ["os__xianfeng_yg"] = "其摸一张牌，直到其下回合开始，你至其距离-1",
  ["@os__xianfeng"] = "先锋",
  ["@os__xianfeng_others"] = "先锋",

  ["$os__zhiqu1"] = "八百之众，哼，须臾可灭！",
  ["$os__zhiqu2"] = "此战首功，当由我取之！",
  ["$os__xianfeng1"] = "吾领万余白马，可堪此战先锋！",
  ["$os__xianfeng2"] = "白马先发，敌不攻而散！",
  ["~yangang"] = "诸将，冲锋！呃啊……",
}

local gongsunfan = General(extension, "gongsunfan", "qun", 4)
local os__huiyuan = fk.CreateTriggerSkill{
  name = "os__huiyuan",
  anim_type = "control",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play and table.find(player.room.alive_players, function(p) return not p:isKongcheng() end) then
      return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        local cardType = data.card.type
        for _, move in ipairs(e.data) do
          if move.toArea == Card.PlayerHand and move.to == player.id then
            for _, info in ipairs(move.moveInfo) do
              local id = info.cardId
              if Fk:getCardById(id).type == cardType then
                return true
              end
            end
          end
        end
      end, Player.HistoryPhase) == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local availableTargets = table.map(table.filter(room.alive_players, function(p) return not p:isKongcheng() end), Util.IdMapper)
    local targets = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__huiyuan-ask:::" .. data.card:getTypeString(), self.name, true)
    if #targets > 0 then
      self.cost_data = targets[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(self.cost_data)
    local id = room:askForCardChosen(player, target, "h", self.name)
    if Fk:getCardById(id).type == data.card.type then
      if target ~= player then
        room:obtainCard(player, id, true, fk.ReasonPrey)
      end
    else
      room:throwCard({id}, self.name, target, player)
      target:drawCards(1, self.name)
    end
    if player:inMyAttackRange(target) and not target:inMyAttackRange(player) then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}

local os__shoushou = fk.CreateTriggerSkill{
  name = "os__shoushou",
  events = {fk.AfterCardsMove, fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.AfterCardsMove then
      local invoke = false
      for _, move in ipairs(data) do
        local from = move.from and player.room:getPlayerById(move.from) or nil
        if move.to == player.id and from and from ~= player and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              invoke = true
              break
            end
          end
          if invoke then break end
        end
      end
      if invoke and table.find(player.room.alive_players, function(p)
        return p:inMyAttackRange(player)
      end) then
        return true
      end
    else
      return target == player and table.find(player.room.alive_players, function(p)
        return not p:inMyAttackRange(player)
      end) and not player.dead
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local num = tonumber(player:getMark("@os__shoushou"))
    if event == fk.AfterCardsMove then
      num = num + 1
    else
      num = num - 1
    end
    player.room:setPlayerMark(player, "@os__shoushou", num > 0 and "+" .. tostring(num) or tostring(num))
  end,
}
local os__shoushou_distance = fk.CreateDistanceSkill{
  name = "#os__shoushou_distance",
  correct_func = function(self, from, to)
    if to:getMark("@os__shoushou") ~= 0 and from ~= to then
      return tonumber(to:getMark("@os__shoushou"))
    end
  end,
}
os__shoushou:addRelatedSkill(os__shoushou_distance)

gongsunfan:addSkill(os__huiyuan)
gongsunfan:addSkill(os__shoushou)

Fk:loadTranslationTable{
  ["gongsunfan"] = "公孙范",
  ["os__huiyuan"] = "回援",
  [":os__huiyuan"] = "当你于出牌阶段使用牌结算结束后，若此阶段你未获得过此类型的牌，你可选择一名角色并展示其一张手牌，若与你使用的牌类型：相同，你获得此牌，不同：你弃置其此牌，其摸一张牌。若游击：你对其造成1点伤害。" ..
  "<br/><font color='grey'>#\"<b>游击</b>\"：其在你攻击范围内，你不在其攻击范围内",
  ["os__shoushou"] = "收绶",
  [":os__shoushou"] = "①当你获得其他角色的牌后，若你在一名角色的攻击范围内，其他角色至你距离+1。②当你造成或受到伤害后，若你不在一名角色的攻击范围内，其他角色至你距离-1。",

  ["#os__huiyuan-ask"] = "回援：你可展示一名角色的一张手牌，若为 %arg：你获得此牌，不为：你弃置其此牌，其摸一张牌",
  ["@os__shoushou"] = "收绶 至",

  ["$os__huiyuan1"] = "起渤海之兵，襄吾兄成事！",
  ["$os__huiyuan2"] = "发一州之力，随手足之势！",
  ["$os__shoushou1"] = "此印既授，吾自当收之！",
  ["$os__shoushou2"] = "本初虽已示弱，此仇亦不能饶！",
  ["~gongsunfan"] = "公孙氏之业，终付之一炬……",
}

local qiaorui = General(extension, "qiaorui", "qun", 5)

local os__xiawei = fk.CreateTriggerSkill{
  name = "os__xiawei",
  events = {fk.GameStart, fk.TurnStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.GameStart then
      return true
    elseif event == fk.TurnStart then
      return target == player and #player:getPile("os__pomp&") > 0
    else
      return target == player and player.phase == Player.Start
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local ret = "os__xiawei_ask:::"
      local choices = {}
      for i = 2, 5 do
        table.insert(choices, ret .. i)
      end
      table.insert(choices, "Cancel")
      local num = player.room:askForChoice(player, choices, self.name, "#os__xiawei-invoke")
      if num ~= "Cancel" then
        self.cost_data = table.indexOf(choices, num)
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      player:setMark("_os__pomp", 0)
      room:moveCardTo(player:getPile("os__pomp&"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, "os__pomp&")
    else
      local cids
      if event == fk.GameStart then
        cids = room:getCardsFromPileByRule(".|.|.|.|.|basic", 2)
      else
        local num = self.cost_data
        cids = room:getNCards(num + 1)
        room:setPlayerMark(player, "@os__xiawei_presume-turn", num)
      end
      if #cids > 0 then
        local dummy = Fk:cloneCard("jink")
        dummy:addSubcards(cids)
        player:addToPile("os__pomp&", dummy, true, self.name)
        player:setMark("_os__pomp", cids)
      end
    end
  end
}
local os__xiawei_presume = fk.CreateTriggerSkill{
  name = "#os__xiawei_presume",
  events = {fk.EventPhaseStart},
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.Finish and player:getMark("@os__xiawei_presume-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = player:getMark("@os__xiawei_presume-turn")
    if #room:askForDiscard(player, num, num, true, self.name, true, ".", "#os__xiawei_presume-discard:::" .. num) == 0 then
      room:changeMaxHp(player, -1)
    end
  end,
}
os__xiawei:addRelatedSkill(os__xiawei_presume)

local os__qiongji = fk.CreateTriggerSkill{
  name = "os__qiongji",
  events = {fk.DamageInflicted, fk.CardUsing, fk.CardResponding},
  anim_type = "negative",
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) then return false end
    if event == fk.DamageInflicted then
      return #player:getPile("os__pomp&") == 0
    else
      return player:usedSkillTimes("os__qiongji_draw") == 0 and player:getMark("_os__pomp") ~= 0 and table.find(data.card:isVirtual() and data.card.subcards or {data.card.id}, function(id)
    return table.contains(player:getMark("_os__pomp"), id)
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.DamageInflicted then
      room:notifySkillInvoked(player, self.name, "negative")
      data.damage = data.damage + 1
    else
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:addSkillUseHistory("os__qiongji_draw")
      player:drawCards(1, self.name)
    end
  end,
}

qiaorui:addSkill(os__xiawei)
qiaorui:addSkill(os__qiongji)

Fk:loadTranslationTable{
  ["qiaorui"] = "桥蕤",
  ["os__xiawei"] = "狭威",
  [":os__xiawei"] = "游戏开始时，你将牌堆中两张基本牌置于你的武将牌上，称为“威”；你可将“威”如手牌般使用或打出；回合开始时，你将所有“威”置入弃牌堆。妄行：准备阶段，你可将牌堆顶的X+1张牌置于你的武将牌上，称为“威”。" ..
    "<br/><font color='grey'>#\"<b>妄行</b>\"：选择X的值（1至4）执行相应效果，然后结束阶段开始时，你需弃置X张牌，否则减1点体力上限。", --回合结束时
  ["os__qiongji"] = "穷技",
  [":os__qiongji"] = "锁定技，当你受到伤害时，若你没有“威”，伤害值+1；每回合限一次，当你使用或打出“威”时，你摸一张牌。",

  ["os__pomp&"] = "威",
  ["os__xiawei_ask"] = "将牌堆顶的%arg张牌作为“威”",
  ["#os__xiawei-invoke"] = "狭威：你可将牌堆顶若干张牌置于你的武将牌上，称为“威”；你可将“威”如手牌般使用或打出",
  ["@os__xiawei_presume-turn"] = "狭威妄行",
  ["#os__xiawei_presume"] = "狭威",
  ["#os__xiawei_presume-discard"] = "狭威：弃置 %arg 张牌，否则减1点体力上限",

  ["$os__xiawei1"] = "既闻仲帝威名，还不速速归降！",
  ["$os__xiawei2"] = "仲朝国土，岂容贼军放肆！",
  ["$os__qiongji1"] = "吾计虽穷，势不可衰！",
  ["$os__qiongji2"] = "战在其势，何妨技穷？",
  ["~qiaorui"] = "曹贼……安敢犯仲国之威……",
}

local os__zhuling = General(extension, "os__zhuling", "wei", 4)

local os__zhanyi = fk.CreateActiveSkill{
  name = "os__zhanyi",
  anim_type = "drawcard",
  prompt = "#os__zhanyi-prompt",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected < 1 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cardType = Fk:getCardById(effect.cards[1]):getTypeString()
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    room:loseHp(player, 1, self.name)
    if player.dead then return end
    room:setPlayerMark(player, "@os__zhanyi-phase", cardType)
    if cardType == "basic" then
      room:handleAddLoseSkills(player, "os__zhanyi_basic&", nil, false, true)
      room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
        room:handleAddLoseSkills(player, "-os__zhanyi_basic&", nil, false, true)
      end)
    elseif cardType == "trick" then
      player:drawCards(3, self.name)
    end
  end,
}
local os__zhanyi_basic = fk.CreateViewAsSkill{
  name = "os__zhanyi_basic&",
  card_num = 1,
  prompt = "#os__zhanyi_basic-prompt",
  card_filter = function(self, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).type == Card.TypeBasic
  end,
  pattern = ".|.|.|.|.|basic",
  interaction = function(self)
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, "os__zhanyi", all_names)
    if #names > 0 then
      return UI.ComboBox { choices = names, all_choices = all_names }
    end
  end,
  view_as = function(self, cards)
    local choice = self.interaction.data
    if not choice or #cards ~= 1 then return end
    local c = Fk:cloneCard(choice)
    c:addSubcards(cards)
    c.skillName = self.name
    return c
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@os__zhanyi-phase") == "basic"
  end,
  enabled_at_response = function(self, player, resp)
    return player:getMark("@os__zhanyi-phase") == "basic" and not resp
  end,
}
local os__zhanyi_buff = fk.CreateTriggerSkill{
  name = "#os__zhanyi_buff",
  anim_type = "offensive",
  events = {fk.CardUsing, fk.TargetSpecified},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player ~= target or player:getMark("@os__zhanyi-phase") == 0 then return false end
    if event == fk.CardUsing then
      if player:getMark("@os__zhanyi-phase") == "basic" then
        return data.card.type == Card.TypeBasic and player:getMark("_os__zhanyi_additional-phase") == 0
      elseif player:getMark("@os__zhanyi-phase") == "trick" then
        return data.card.type == Card.TypeTrick
      end
    else
      return data.card.trueName == "slash" and player:getMark("@os__zhanyi-phase") == "equip"
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      if player:getMark("@os__zhanyi-phase") == "basic" then
        data.additionalDamage = (data.additionalDamage or 0) + 1
        data.additionalRecover = (data.additionalRecover or 0) + 1
        room:addPlayerMark(player, "_os__zhanyi_additional-phase")
      else
        data.unoffsetableList = table.map(player.room.alive_players, Util.IdMapper)
      end
    else
      local to = room:getPlayerById(data.to)
      local cids = room:askForDiscard(to, 2, 2, true, self.name, false, ".")
      cids = table.filter(cids, function(id) return room:getCardArea(id) == Card.DiscardPile end)
      if #cids > 0 then
        local cards = room:askForCardChosen(player, target, {
          card_data = {
            { "pile_discard", cids }
          }
        }, self.name, "#os__zhanyi-get::" .. data.to)
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonJustMove, "os__zhanyi", nil, true)
      end
    end
  end,
}
os__zhanyi:addRelatedSkill(os__zhanyi_buff)

os__zhuling:addSkill(os__zhanyi)
Fk:addSkill(os__zhanyi_basic)

Fk:loadTranslationTable{
  ["os__zhuling"] = "朱灵",
  ["#os__zhuling"] = "良将之亚",
  ["cv:os__zhuling"] = "秦且歌",
  ["os__zhanyi"] = "战意",
  [":os__zhanyi"] = "出牌阶段限一次，你可弃置一张牌并失去1点体力，根据牌的种类获得以下效果直到出牌阶段结束，基本牌：你可将一张基本牌当成任意基本牌使用，你使用的第一张基本牌的伤害值或回复值基数+1；锦囊牌：你摸三张牌，你使用的锦囊牌不能被抵消；装备牌：当你使用【杀】指定一名角色为目标后，其弃置两张牌，你选择其中一张获得之。<br /><font color='red'>（注：【酒】不享受伤害值+1效果）</font>",
  ["#os__zhanyi-prompt"] = "战意:弃置一张牌并失去1点体力，根据弃置牌的种类获得效果",

  ["@os__zhanyi-phase"] = "战意",
  ["#os__zhanyi_buff"] = "战意",

  ["os__zhanyi_basic&"] = "战意",
  [":os__zhanyi_basic&"] = "你可将一张基本牌当成任意基本牌使用",
  ["#os__zhanyi_basic-prompt"] = "你可将一张基本牌当成任意基本牌使用",
  ["#os__zhanyi-get"] = "战意：获得%dest弃置的一张牌",

  ["$os__zhanyi1"] = "以战养战，视敌而战。",
  ["$os__zhanyi2"] = "战，可以破敌。意，可以守御。",
  ["~os__zhuling"] = "此生得遇曹公，再无他求。",
}

local os__simashi = General(extension, "os__simashi", "wei", 4)

local os__baiyi = fk.CreateActiveSkill{
  name = "os__baiyi",
  anim_type = "control",
  card_num = 0,
  target_num = 2,
  frequency = Skill.Limited,
  target_filter = function(self, to_select, selected)
    return #selected < 2 and to_select ~= Self.id
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:isWounded()
  end,
  on_use = function(self, room, effect)
    local from, to = room:getPlayerById(effect.tos[1]), room:getPlayerById(effect.tos[2])
    room:swapSeat(from, to)
  end,
}

local os__jinglue = fk.CreateActiveSkill{
  name = "os__jinglue",
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and table.every(Fk:currentRoom().alive_players, function(p)
      return table.every(p:getCardIds("ej"), function(id)
        return Fk:getCardById(id):getMark("_os__sishi") == 0
      end)
    end)
  end,
  card_num = 0,
  card_filter = function() return false end,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected < 1 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local record
    local cid = room:askForCardChosen(player, target, {
      card_data = {
        { "$Hand", target:getCardIds(Player.Hand) }
      }
    }, self.name)
    room:setCardMark(Fk:getCardById(cid), "_os__sishi", {target.id, player.id})
    local mark_name = "_os__jinglue_now-" .. tostring(player.id)
    record = type(target:getMark(mark_name)) == "table" and target:getMark(mark_name) or {}
    table.insertIfNeed(record, cid)
    room:setPlayerMark(target, mark_name, record)
    record = type(player:getMark("_os__jinglue")) == "table" and player:getMark("_os__jinglue") or {}
    table.insertIfNeed(record, target.id)
    room:setPlayerMark(player, "_os__jinglue", record)
  end,
}
local os__jinglue_do = fk.CreateTriggerSkill{
  name = "#os__jinglue_do",
  anim_type = "control",
  events = {fk.CardUsing, fk.TurnEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    local mark
    if event == fk.CardUsing then
      for _, id in ipairs(data.card:isVirtual() and data.card.subcards or {data.card.id}) do
        if Fk:getCardById(id):getMark("_os__sishi") ~= 0 then
          if not mark then
            mark = Fk:getCardById(id):getMark("_os__sishi")
          elseif mark ~= Fk:getCardById(id):getMark("_os__sishi") then
            return false
          end
        else
          return false
        end
      end
      return mark and mark[1] == target.id and mark[2] == player.id
    elseif target:getMark("_os__jinglue_now-" .. player.id) ~= 0 and not player.dead then
      for _, id in ipairs(target:getMark("_os__jinglue_now-" .. player.id)) do
        if table.contains({Card.DrawPile, Card.DiscardPile, Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge}, player.room:getCardArea(id)) then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:doIndicate(player.id, {target.id})
      data.tos = {}
      room:sendLog{ type = "#CardNullifiedBySkill", from = target.id, arg = self.name, arg2 = data.card:toLogString() }
    else
      local dummy = Fk:cloneCard("dilu")
      local mark = target:getMark("_os__jinglue_now-" .. player.id)
      for i = #mark, 1, -1 do
        local id = mark[i]
        if table.contains({Card.DrawPile, Card.DiscardPile, Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge}, room:getCardArea(id)) then
          table.remove(mark, i)
          room:setCardMark(Fk:getCardById(id), "_os__sishi", 0)
          dummy:addSubcard(id)
        end
      end
      room:setPlayerMark(target, "_os__jinglue_now-" .. player.id, mark)
      room:obtainCard(player, dummy, true, fk.ReasonPrey)
    end
  end,
}
os__jinglue:addRelatedSkill(os__jinglue_do)

local os__shanli = fk.CreateTriggerSkill{
  name = "os__shanli",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return player:usedSkillTimes(os__baiyi.name, Player.HistoryGame) > 0 and type(player:getMark("_os__jinglue")) == "table" and #player:getMark("_os__jinglue") > 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    local target = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#os__shanli-ask", self.name, false)[1]
    local skills = {}
    for _, general in ipairs(Fk:getAllGenerals()) do
      for _, skill in ipairs(general.skills) do
        if skill.lordSkill then
          table.insertIfNeed(skills, skill.name)
        end
      end
    end
    if #skills > 0 then
      skills = table.random(skills, 3)
      local skillName = room:askForChoice(player, skills, self.name, "#os__shanli-skill:" .. target, true)
      room:handleAddLoseSkills(room:getPlayerById(target), skillName, nil, true, false)
    end
  end,
}

os__simashi:addSkill(os__baiyi)
os__simashi:addSkill(os__jinglue)
os__simashi:addSkill(os__shanli)

Fk:loadTranslationTable{
  ["os__simashi"] = "司马师",
  ["os__baiyi"] = "败移",
  [":os__baiyi"] = "限定技，出牌阶段，若你已受伤，你可选择其他两名角色，令这两名角色交换座次。",
  ["os__jinglue"] = "景略",
  [":os__jinglue"] = "出牌阶段限一次，若场上没有“死士”牌，你可观看一名其他角色的手牌，将其中一张牌标记为“死士”。当“死士”牌被其使用时，你令此牌无效；其回合结束时，若“死士”牌在牌堆、弃牌堆或任意角色的区域内，你获得之。",
  ["os__shanli"] = "擅立",
  [":os__shanli"] = "觉醒技，准备阶段，若你对至少两名角色发动过〖景略〗，并且〖败移〗已发动，你减1点体力上限并选择一名角色，你从随机三个主公技中选择一个令其获得。",

  ["os__jinglueDo"] = "“死士”",
  ["#os__jinglue_do"] = "景略",
  ["#os__shanli-ask"] = "擅立：选择一名角色，令其获得一个主公技",
  ["#os__shanli-skill"] = "擅立：选择一个主公技令 %src 获得",

  ["$os__baiyi1"] = "吾不听公休之言，以致须行此策。",
  ["$os__baiyi2"] = "诸将无过，且按吾之略再图破敌。",
  ["$os__jinglue1"] = "安待良机，自有舍身报吾之士。",
  ["$os__jinglue2"] = "察局备间，保诸事不虞。",
  ["$os__shanli1"] = "荡尘涤污，重整河山，便在今日！",
  ["$os__shanli2"] = "效伊尹霍光，以返天下清明。",
  ["~os__simashi"] = "吾家夙愿，得偿与否，尽看子上……",	
}

local zhangjih = General(extension, "zhangjih", "wei", 3)
local os__dingzhen = fk.CreateTriggerSkill{
  name = "os__dingzhen",
  anim_type = "defensive",
  events = {fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    local num = player.hp
    return table.find(player.room.alive_players, function(p)
      return (p:distanceTo(player) <= num)
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local num = player.hp
    local available_targets = table.map(
      table.filter(player.room.alive_players, function(p)
        return (p:distanceTo(player) <= num)
      end),
      Util.IdMapper
    )
    local targets = player.room:askForChoosePlayers(player, available_targets, 1, 99, "#os__dingzhen-ask:::" .. tostring(player.hp), self.name, true)
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = self.cost_data
    room:sortPlayersByAction(targets)
    for _, pid in ipairs(targets) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        local discard = room:askForDiscard(p, 1, 1, true, self.name, true, "slash", "#os__dingzhen-discard::" .. player.id)
        if #discard == 0 then
          room:setPlayerMark(p, "@@os__dingzhen-round", 1)
          local record = U.getMark(p, "_os__dingzhen_to-round")
          table.insert(record, player.id)
          room:setPlayerMark(p, "_os__dingzhen_to-round", record)
        end
      end
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@os__dingzhen-round") > 0 and player.phase ~= Player.NotActive and player:getMark("_os__dingzhen_use-turn") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "_os__dingzhen_use-turn", 1)
  end,
}
local os__dingzhen_prohibit = fk.CreateProhibitSkill{
  name = "#os__dingzhen_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:getMark("@@os__dingzhen-round") > 0 and table.contains(U.getMark(from, "_os__dingzhen_to-round"), to.id)
    and from:getMark("_os__dingzhen_use-turn") == 0
  end,
}
os__dingzhen:addRelatedSkill(os__dingzhen_prohibit)
zhangjih:addSkill(os__dingzhen)
local os__youye = fk.CreateTriggerSkill{
  name = "os__youye",
  mute = true,
  events = {fk.EventPhaseEnd, fk.Damage, fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      return target.phase == Player.Finish and player:hasSkill(self) and target ~= player and #player:getPile("os__poise") < 5
      and #U.getActualDamageEvents(player.room, 1, function(e) return e.data[1].to == player end) == 0
    else
      return player == target and player:hasSkill(self) and #player:getPile("os__poise") > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.EventPhaseEnd then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:addToPile("os__poise", room:getNCards(1)[1], true, self.name)
    else
      room:notifySkillInvoked(player, self.name, "support")
      local cards = player:getPile("os__poise")
      local current = room.current
      local toCurrent = {}
      if not current.dead then
        if #cards == 1 then
          toCurrent = cards
        else
          toCurrent = room:askForCard(player, 1, #cards, false, self.name, false, ".|.|.|os__poise", "#os__youye-give::" ..current.id, "os__poise")
        end
      end
      local residue = table.filter(cards, function(id) return not table.contains(toCurrent, id) end)
      if #residue == 0 then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(toCurrent)
        room:obtainCard(current, dummy, true, fk.ReasonGive)
      else
        local move = U.askForDistribution(player, residue, room.alive_players, self.name, #residue, #residue, "#os__youye-give2", "os__poise", true)
        local str = string.format("%.0f", current.id)
        move[str] = move[str] or {}
        table.insertTable(move[str], toCurrent)
        U.doDistribution(room, move, player.id, self.name)
      end
    end
  end,
}
zhangjih:addSkill(os__youye)
Fk:loadTranslationTable{
  ["zhangjih"] = "张既",
  ["#zhangjih"] = "边安人宁",
  ["illustrator:zhangjih"] = "depp",
  ["designer:zhangjih"] = "Loun老萌",

  ["os__dingzhen"] = "定镇",
  [":os__dingzhen"] = "每轮开始时，你可选择至你距离为X以内的任意名角色（X为你当前体力值），令这些角色弃置一张【杀】，否则本轮中其回合内使用的第一张牌不能指定你为目标。",
  ["os__youye"] = "攸业",
  [":os__youye"] = "锁定技，其他角色的结束阶段开始时，若其本回合没有对你造成过伤害，则你将牌堆顶的一张牌置于你的武将牌上，称为“蓄”（至多5张）。当你造成或受到伤害后，你将所有“蓄”分配给任意角色，若当前回合角色存活，其至少须获得一张。",
  ["#os__dingzhen-ask"] = "你可对任意名至你距离 %arg 以内的角色发动“定镇”",
  ["#os__dingzhen-discard"] = "定镇：弃置一张【杀】，否则本轮中回合内使用的第一张牌不能指定 %dest 为目标",
  ["@@os__dingzhen-round"] = "定镇",
  ["os__poise"] = "蓄",
  ["#os__youye-give"] = "定镇：将至少一张“蓄”分配给 %dest，点击“确定”后再将剩余牌分配给任意角色",
  ["#os__youye-give2"] = "定镇：分配任意张“蓄”给任意角色，直到所有“蓄”分配完毕",

  ["$os__dingzhen1"] = "招抚流民，兴复县邑。",
  ["$os__dingzhen2"] = "容民畜众，群羌归土。",
  ["$os__youye1"] = "筑城西疆，开万代太平。",
  ["$os__youye2"] = "镇边戍卫，许万民攸业。",
  ["~zhangjih"] = "恨不见四海肃眘，羌胡徕服。",
}

local os__fanchou = General(extension, "os__fanchou", "qun", 4)
local os__xingluan = fk.CreateTriggerSkill{
  name = "os__xingluan",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cids = room:getNCards(6)
    room:moveCards({
      ids = cids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id,
    })
    if player.dead then return end
    local choices = {}
    local cardsMap = {}
    for _, cid in ipairs(cids) do
      local cardType = Fk:getCardById(cid):getTypeString()
      table.insertIfNeed(choices, cardType)
      cardsMap[cardType] = cardsMap[cardType] or {}
      table.insert(cardsMap[cardType], cid)
    end
    local choice = room:askForChoice(player, choices, self.name, "#os__xingluan-ask", false, {"basic", "trick", "equip"})
    local cards = cardsMap[choice]
    player.special_cards["os__xingluan"] = table.simpleClone(cards)
    player:doNotify("ChangeSelf", json.encode {
      id = player.id,
      handcards = player:getCardIds("h"),
      special_cards = player.special_cards,
    })
    local move = U.askForDistribution(player, cards, room:getAlivePlayers(), self.name, #cards, #cards, "#os__xingluan-give", self.name, true, 3)
    player.special_cards["os__xingluan"] = {}
    player:doNotify("ChangeSelf", json.encode {
      id = player.id,
      handcards = player:getCardIds("h"),
      special_cards = player.special_cards,
    })
    local num = #move[string.format("%.0f", player.id)] or 0
    local victims = {}
    for p, c in pairs(move) do
      if #c >= num and #c > 0 then
        table.insert(victims, tonumber(p))
      end
    end
    U.doDistribution(room, move, player.id, self.name)
    room:sortPlayersByAction(victims)
    for _, pid in ipairs(victims) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        room:loseHp(p, 1, self.name)
      end
    end
    cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.Processing end)
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        proposer = player.id,
      })
    end
  end,
}
os__fanchou:addSkill(os__xingluan)
Fk:loadTranslationTable{
  ["os__fanchou"] = "樊稠",
  ["os__xingluan"] = "兴乱",
  [":os__xingluan"] = "结束阶段开始时，你可亮出牌堆顶的六张牌，然后将其中一种类别的牌分配给任意名角色（每名角色至多三张），以此法获得牌数大于0且不小于你的角色依次失去1点体力。",
  ["#os__xingluan-ask"] = "兴乱：选择其中一种类别的牌并分配",
  ["#os__xingluan-give"] = "兴乱：将 %arg 分配给任意名角色（每名角色至多三张）",
  ["distribute_active"] = "分配牌",
  ["$os__xingluan1"] = "既朝廷不赦，何不反击一搏？",
  ["$os__xingluan2"] = "反扑长安，势要天翻地覆！",
  ["~os__fanchou"] = "我无谋反之心！啊……",
}

local caohong = General(extension, "os__caohong", "wei", 4)

local os__yuanhu = fk.CreateActiveSkill{
  name = "os__yuanhu",
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  target_num = 1,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and #cards == 1 and Fk:currentRoom():getPlayerById(to_select):hasEmptyEquipSlot(Fk:getCardById(cards[1]).sub_type)
  end,
  on_use = function(self, room, use)
    if #use.cards ~= 1 then return end
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    room:moveCardTo(use.cards, Card.PlayerEquip, target, fk.ReasonPut, self.name, nil, true, player.id)
    if not target.dead then
      local cardType = Fk:getCardById(use.cards[1]).sub_type
      if cardType == Card.SubtypeWeapon then
        local targets = table.map(table.filter(room.alive_players, function(p)
          return target:distanceTo(p) <= 1 and not p:isAllNude() end), Util.IdMapper)
        if #targets > 0 then
          local to = room:askForChoosePlayers(player, targets, 1, 1, "#os__yuanhu-discard:" .. target.id, self.name, false)[1]
          to = room:getPlayerById(to)
          local cid = room:askForCardChosen(player, to, "hej", self.name)
          room:throwCard({cid}, self.name, to, player)
        end
      elseif cardType == Card.SubtypeArmor then
        target:drawCards(1, self.name)
      else
        room:recover({
          who = target,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
      if player.phase == Player.Play and (target.hp <= player.hp or target:getHandcardNum() <= player:getHandcardNum()) and not player.dead then
        player:drawCards(1, self.name)
        room:setPlayerMark(player, "_os__yuanhu-turn", 1)
      end
    end
  end,
}
local os__yuanhu_finish = fk.CreateTriggerSkill{
  name = "#os__yuanhu_finish",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and player:getMark("_os__yuanhu-turn") > 0
  end,
  on_cost = function(self, event, target, player, data)
    player.room:askForUseActiveSkill(player, "os__yuanhu", "#os__yuanhu-trg", true)
  end,
  on_use = function(self, event, target, player, data)
    return false
  end,
}
os__yuanhu:addRelatedSkill(os__yuanhu_finish)

local os__juezhu = fk.CreateActiveSkill{
  name = "os__juezhu",
  anim_type = "support",
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) < 1 and (#player:getAvailableEquipSlots(Card.SubtypeOffensiveRide) > 0 or #player:getAvailableEquipSlots(Card.SubtypeDefensiveRide) > 0 )
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  interaction = function()
    local all_choices = {"DefensiveRideSlot", "OffensiveRideSlot"}
    local choices = table.clone(all_choices)
    if #Self:getAvailableEquipSlots(Card.SubtypeOffensiveRide) == 0 then
      table.remove(choices)
    end
    if #Self:getAvailableEquipSlots(Card.SubtypeDefensiveRide) == 0 then
      table.remove(choices, 1)
    end
    return UI.ComboBox{ choices = choices, all_choices = all_choices}
  end,
  on_use = function(self, room, use)
    local choice = self.interaction.data
    if not choice then return false end
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    local slot = choice == "OffensiveRideSlot" and Player.OffensiveRideSlot or Player.DefensiveRideSlot
    room:abortPlayerArea(player, {slot})
    room:handleAddLoseSkills(target, "feiying")
    room:abortPlayerArea(target, {Player.JudgeSlot})
    room:setPlayerMark(player, "@os__juezhu", target.general)
    room:setPlayerMark(player, "_os__juezhu", {target.id, slot})
  end
}
local os__juezhu_re = fk.CreateTriggerSkill{
  name = "#os__juezhu_re",
  mute = true,
  events = {fk.Deathed},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("_os__juezhu") ~= 0 and player:getMark("_os__juezhu")[1] == target.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:resumePlayerArea(player, player:getMark("_os__juezhu")[2])
    room:setPlayerMark(player, "_os__juezhu", 0)
  end,
}
os__juezhu:addRelatedSkill(os__juezhu_re)

caohong:addSkill(os__yuanhu)
caohong:addSkill(os__juezhu)
caohong:addRelatedSkill("feiying")

Fk:loadTranslationTable{
  ["os__caohong"] = "曹洪",
  ["os__yuanhu"] = "援护",
  [":os__yuanhu"] = "出牌阶段限一次，你可将一张装备牌置入一名角色的装备区，若此牌是：武器牌，你弃置其距离不大于1的一名角色区域里的一张牌；"..
  "防具牌，其摸一张牌；坐骑牌或宝物牌，其回复1点体力。若其体力值或手牌数不大于你且此时为你的出牌阶段，你摸一张牌，且可于本回合结束阶段开始时再发动此技能。",
  ["os__juezhu"] = "决助",
  [":os__juezhu"] = "限定技，出牌阶段，你可废除一个坐骑栏，令一名角色获得〖飞影〗并废除其判定区。其死亡后，你恢复以此法废除的坐骑栏。",

  ["#os__yuanhu-trg"] = "援护：你可以将一张装备牌置入一名角色的装备区",
  ["#os__yuanhu-discard"] = "援护：你可以弃置 %src 距离不大于1的一名角色区域内一张牌",
  ["@os__juezhu"] = "决助",

  ["$os__yuanhu1"] = "将军，这件兵器可还趁手？",
  ["$os__yuanhu2"] = "刀剑无眼，须得小心防护。",
  ["$os__yuanhu3"] = "宝马配英雄！哈哈哈哈……",
  ["$os__juezhu1"] = "曹君速上马，洪自断后。",
  ["$os__juezhu2"] = "天下可无洪，不可无君。",
  ["~os__caohong"] = "福兮祸所伏……",	
}

local weixu = General(extension, "weixu", "qun", 4)

local os__suizheng = fk.CreateTriggerSkill{
  name = "os__suizheng",
  anim_type = "support",
  mute = true,
  events = {fk.GameStart, fk.Damage, fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    return event == fk.GameStart or (target and player:getMark("_os__suizheng") == target.id and not player.dead)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "support")
      local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#os__suizheng-ask", self.name, false)
      if #tos > 0 then
        local to = room:getPlayerById(tos[1])
        room:setPlayerMark(player, "_os__suizheng", to.id)
        room:setPlayerMark(player, "@os__suizheng", to.general)
      end
    elseif event == fk.Damage then
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
    else
      player:broadcastSkillInvoke(self.name, 3)
      room:notifySkillInvoked(player, self.name, "support")
      local cards = room:askForDiscard(player, 2, 2, true, self.name, player.hp > 0, ".|.|.|.|.|basic", "#os__suizheng-discard::" .. target.id)
      if #cards == 2 then
        if not target.dead then
          room:recover({ who = target, num = 1, recoverBy = player, skillName = self.name})
        end
      else
        room:loseHp(player, 1, self.name)
        if not target.dead then
          local cids = room:getCardsFromPileByRule("slash,duel", 1, "allPiles")
          if #cids > 0 then
            room:obtainCard(target, cids[1], false, fk.ReasonPrey)
          end
        end
      end
    end
  end,
}
local os__tuidao = fk.CreateTriggerSkill{
  name = "os__tuidao",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) or player:getMark("_os__suizheng") == 0 or player.phase ~= Player.Start then return false end 
    local to = player.room:getPlayerById(player:getMark("_os__suizheng"))
    if not (to.hp <= 2 or to.dead) then return false end
    return (#player:getAvailableEquipSlots(Card.SubtypeOffensiveRide) > 0 and #to:getAvailableEquipSlots(Card.SubtypeOffensiveRide) > 0)
    or (#player:getAvailableEquipSlots(Card.SubtypeDefensiveRide) > 0 and #to:getAvailableEquipSlots(Card.SubtypeDefensiveRide) > 0)
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"DefensiveRideSlot", "OffensiveRideSlot", "Cancel"}
    local choices = {"DefensiveRideSlot", "OffensiveRideSlot"}
    local to = player.room:getPlayerById(player:getMark("_os__suizheng"))
    local dead = to.dead
    if #player:getAvailableEquipSlots(Card.SubtypeOffensiveRide) == 0 or (not dead and #to:getAvailableEquipSlots(Card.SubtypeOffensiveRide) == 0) then
      table.remove(choices)
    end
    if #player:getAvailableEquipSlots(Card.SubtypeDefensiveRide) == 0 or (not dead and #to:getAvailableEquipSlots(Card.SubtypeDefensiveRide) == 0) then
      table.remove(choices, 1)
    end
    table.insert(choices, "Cancel")
    local choice = player.room:askForChoice(player, choices, self.name, dead and "#os__tuidao-ask2" or "#os__tuidao-ask::" .. to.id, false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local choice = self.cost_data
    local room = player.room
    local to = room:getPlayerById(player:getMark("_os__suizheng"))
    local slot = choice == "OffensiveRideSlot" and Player.OffensiveRideSlot or Player.DefensiveRideSlot
    room:abortPlayerArea(player, {slot})
    local dead = to.dead
    if not dead then room:abortPlayerArea(to, {slot}) end
    local choices = {"basic", "trick", "equip"}
    choice = room:askForChoice(player, choices, self.name, dead and "#os__tuidao-card2" or "#os__tuidao-card::" .. to.id)
    local cards = dead and room:getCardsFromPileByRule(".|.|.|.|.|" .. choice, 2) or
      table.filter(to:getCardIds{Player.Hand, Player.Equip}, function(id) return Fk:getCardById(id):getTypeString() == choice end)
    if #cards > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(cards)
      room:obtainCard(player, dummy, false, fk.ReasonPrey)
    end
    local targets = table.map(table.filter(room.alive_players, function(p) return p ~= player and p ~= to end), Util.IdMapper)
    if #targets == 0 then return false end
    local target = room:askForChoosePlayers(player, targets, 1, 1, "#os__tuidao-new", self.name, false)[1]
    room:setPlayerMark(player, "_os__suizheng", target)
    target = room:getPlayerById(target)
    room:setPlayerMark(player, "@os__suizheng", target.general)
    if #cards > 0 then
      cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player end)
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonPrey, self.name, nil, false, player.id)
      end
    end
  end,
}
weixu:addSkill(os__suizheng)
weixu:addSkill(os__tuidao)

Fk:loadTranslationTable{
  ["weixu"] = "魏续",
  ["os__suizheng"] = "随征",
  [":os__suizheng"] = "锁定技，游戏开始时，你选择一名其他角色。当其造成伤害后，你摸一张牌；当其受到伤害后，你须选择一项：1. 失去1点体力，令其从牌堆或弃牌堆中获得一张【杀】或【决斗】；2. 弃置两张基本牌，令其回复1点体力。",
  ["os__tuidao"] = "颓盗",
  [":os__tuidao"] = "限定技，准备阶段开始时，若“随征”角色体力值不大于2或已死亡，你可废除你与其的一个坐骑栏位，然后选择一个类别的牌，获得其所有该类别的牌（若其已死亡，则改为从牌堆中获得两张指定类别的牌），然后选择另一名其他角色作为新的“随征”角色，并令其获得这些牌。",

  ["#os__suizheng-ask"] = "随征：选择一名其他角色，作为“随征”角色",
  ["@os__suizheng"] = "随征",
  ["#os__suizheng-discard"] = "随征：你可弃置两张基本牌，令 %dest 回复1点体力；或点“取消”，失去1点体力，令其从牌堆或弃牌堆中获得一张【杀】或【决斗】",
  ["#os__tuidao-ask"] = "颓盗：你可废除你与 %dest 的一个坐骑栏，获得其所有指定类别的牌，选择另一名角色作为新的“随征”角色",
  ["#os__tuidao-ask2"] = "颓盗：你可废除你的一个坐骑栏，从牌堆中获得两张指定类别的牌，选择另一名角色作为新的“随征”角色",
  ["#os__tuidao-card"] = "颓盗：选择一个牌的类别，获得 %dest 所有该类别的牌",
  ["#os__tuidao-card2"] = "颓盗：选择一个牌的类别，从牌堆中获得两张该类别的牌",
  ["#os__tuidao-new"] = "颓盗：选择一个新的“随征”角色，令其获得刚刚撸到的牌",

  ["$os__suizheng1"] = "续得将军器重，愿随将军出征！",
  ["$os__suizheng2"] = "吾与将军有亲，哼！尔等岂可与我相比！",
  ["$os__suizheng3"] = "将军莫慌，万事有吾！",
  ["$os__tuidao1"] = "将军大势已去，续无可奈何啊。",
  ["$os__tuidao2"] = "续投明主，还望将军勿怪才是。",
  ["~os__weixu"] = "颜良小儿，竟敢杀我同伴，看我为其……啊！",	
}

local os__zhanglu = General(extension, "os__zhanglu", "qun", 3)
local os__shijun = fk.CreateTriggerSkill{
  name = "os__shijun$",
  mute = true,
  frequency = Skill.Compulsory,
  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self.name, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self and target == player
    else
      return target == player and player:hasSkill(self.name, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    --[[local targets = table.filter(room:getOtherPlayers(player), function(p)
      return p.kingdom == "qun"
    end)]]
    local targets = room:getOtherPlayers(player)
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self.name, true) then
        table.forEach(targets, function(p)
          room:handleAddLoseSkills(p, "os__shijun_other&", nil, false, true)
        end)
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      table.forEach(targets, function(p)
        room:handleAddLoseSkills(p, "-os__shijun_other&", nil, false, true)
      end)
    end
  end,
}
local os__shijun_other = fk.CreateActiveSkill{
  name = "os__shijun_other&",
  anim_type = "support",
  mute = true,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and player.kingdom == "qun" then
      return table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill("os__shijun") and p ~= player and #p:getPile("zhanglu_mi") == 0 end)
    end
    return false
  end,
  card_num = 0,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.filter(room.alive_players, function(p) return p:hasSkill("os__shijun") and p ~= player and #p:getPile("zhanglu_mi") == 0 end)
    local target
    if #targets == 1 then
      target = targets[1]
    else
      target = room:getPlayerById(room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, nil, self.name, false)[1])
    end
    if not target then return false end
    room:notifySkillInvoked(player, "os__shijun", "support")
    player:broadcastSkillInvoke("os__shijun")
    room:doIndicate(effect.from, { target.id })
    player:drawCards(1, self.name)
    if not (player:isNude() or player.dead) then
      local card = room:askForCard(player, 1, 1, true, self.name, false, nil, "#os__shijun-put:" .. target.id)
      target:addToPile("zhanglu_mi", card, true, self.name)
    end
  end,
}
Fk:addSkill(os__shijun_other)

os__zhanglu:addSkill("yishe")
os__zhanglu:addSkill("bushi")
os__zhanglu:addSkill("midao")
os__zhanglu:addSkill(os__shijun)

Fk:loadTranslationTable{
  ["os__zhanglu"] = "张鲁",
  ["os__shijun"] = "师君",
  [":os__shijun"] = "主公技，其他群势力角色出牌阶段限一次，若你没有“米”，其可以摸一张牌，然后将一张牌置于你的武将牌上，称为“米”。",

  ["#os__shijun-put"] = "师君：将一张牌置于 %src 的武将牌上",
  ["os__shijun_other&"] = "师君",
  [":os__shijun_other&"] = "出牌阶段限一次，若张鲁没有“米”，你可以摸一张牌，然后将一张牌置于其武将牌上，称为“米”。",
}

local liuyao = General(extension, "os__liuyao", "qun", 4)
local os__niju = fk.CreateTriggerSkill{
  name = "os__niju$",
  anim_type = "special",
  events = {fk.PindianCardsDisplayed},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    return (player == data.from or data.results[player.id]) and table.find(player.room.alive_players, function(p) return p ~= player and p.kingdom == "qun" end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local num = #table.filter(room.alive_players, function(p) return p ~= player and p.kingdom == "qun" end)
    local choices = {"os__niju_plus::" .. data.from.id .. ":" .. num, "os__niju_minus::" .. data.from.id .. ":" .. num}
    for p, _ in pairs(data.results) do
      table.insert(choices, "os__niju_plus::" .. p .. ":" .. num)
      table.insert(choices, "os__niju_minus::" .. p .. ":" .. num)
    end
    table.insert(choices, "Cancel")
    local choice = room:askForChoice(player, choices, self.name)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local choice = self.cost_data:split(":")
    local num = tonumber(choice[4])
    if choice[1] == "os__niju_minus" then num = - num end
    local target = tonumber(choice[3])
    if target == data.from.id then
      data.fromCard.number = math.max(math.min(data.fromCard.number + num, 13), 1)
    elseif data.results[target] then
      data.results[target].toCard.number = math.max(math.min(data.results[target].toCard.number + num, 13), 1)
    end
    local from = data.fromCard.number
    for _, r in pairs(data.results) do
      if r.toCard.number ~= from then
        return false
      end
    end
    player:drawCards(num, self.name)
  end,
}
liuyao:addSkill("kannan")
liuyao:addSkill(os__niju)
Fk:loadTranslationTable{
  ["os__liuyao"] = "刘繇",
  ["os__niju"] = "逆拒",
  [":os__niju"] = "主公技，当你的拼点牌亮出后，可以令任一张拼点牌的点数+X或-X，然后若两张拼点牌点数相同，你摸X张牌（X为其他群势力角色数）。",

  ["os__niju_plus"] = "%dest拼点牌点数+%arg",
  ["os__niju_minus"] = "%dest拼点牌点数-%arg",
}

local zhangxiu = General(extension, "os__zhangxiu", "qun", 4)

local os__juxiang = fk.CreateTriggerSkill{
  name = "os__juxiang$",
  mute = true,
  frequency = Skill.Compulsory,
  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self and target == player
    else
      return target == player and player:hasSkill(self, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    --[[local targets = table.filter(room:getOtherPlayers(player), function(p)
      return p.kingdom == "qun"
    end)]]
    local targets = room:getOtherPlayers(player)
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self, true) then
        table.forEach(targets, function(p)
          room:handleAddLoseSkills(p, "os__juxiang_other&", nil, false, true)
        end)
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      table.forEach(targets, function(p)
        room:handleAddLoseSkills(p, "-os__juxiang_other&", nil, false, true)
      end)
    end
  end,
}
local os__juxiang_other = fk.CreateActiveSkill{
  name = "os__juxiang_other&",
  anim_type = "support",
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and player.kingdom == "qun" then
      return table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill("os__juxiang") and p ~= player end)
    end
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    if #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Equip then
      local subtype = Fk:getCardById(to_select).sub_type
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p:hasSkill("os__juxiang") and p ~= Self and (p:hasEmptyEquipSlot(subtype) or #p:getAvailableEquipSlots(subtype) == 0) then
          return true
        end
      end
    end
    return 
  end,
  target_num = 0,
  on_use = function(self, room, use)
    if #use.cards ~= 1 then return end
    local player = room:getPlayerById(use.from)
    local subtype = Fk:getCardById(use.cards[1]).sub_type
    local targets = table.filter(room.alive_players, function(p) return p:hasSkill("os__juxiang") and p ~= player and (p:hasEmptyEquipSlot(subtype) or #p:getAvailableEquipSlots(subtype) == 0) end)
    local target
    if #targets == 1 then
      target = targets[1]
    else
      target = room:getPlayerById(room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, nil, self.name, false)[1])
    end
    if not target then return false end
    room:notifySkillInvoked(player, "os__juxiang", "support")
    player:broadcastSkillInvoke("os__juxiang")
    room:doIndicate(use.from, { target.id })
    if #target:getAvailableEquipSlots(subtype) > 0 then
      room:moveCardTo(use.cards, Card.PlayerEquip, target, fk.ReasonPut, self.name, nil, true, player.id)
    else
      room:moveCardTo(use.cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, true, player.id)
      room:resumePlayerArea(target, Util.convertSubtypeAndEquipSlot(subtype))
    end
  end,
}
Fk:addSkill(os__juxiang_other)

zhangxiu:addSkill("xiongluan")
zhangxiu:addSkill("congjian")
zhangxiu:addSkill(os__juxiang)


Fk:loadTranslationTable{
  ["os__zhangxiu"] = "张绣",
  ["os__juxiang"] = "踞襄",
  [":os__juxiang"] = "主公技，其他群势力角色出牌阶段限一次，其可以选择其装备区的一张牌置于你的装备区中，若你对应的装备栏已被废除，则改为交给你此装备牌，然后恢复你的对应装备栏。",

  ["os__juxiang_other&"] = "踞襄",
  [":os__juxiang_other&"] = "出牌阶段限一次，你可以选择装备区的一张牌置于张绣的装备区中，若其对应的装备栏已被废除，则改为交给其此装备牌，然后恢复其对应装备栏。",
}

local zhangzhao = General(extension, "zhangzhao", "wu", 3)
local lijians = fk.CreateTriggerSkill{
  name = "os__lijians",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or target.phase ~= Player.Discard or target == player or player:getMark("@os__lijians") ~= 0 then return false end
    local room = player.room
    return #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if room:getCardArea(info.cardId) == Card.DiscardPile then
              return true
            end
          end
        end
      end
      return false
    end, Player.HistoryPhase) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.DiscardPile then
              table.insertIfNeed(cards, id)
            end
          end
        end
      end
      return false
    end, Player.HistoryPhase)
    if #cards == 0 then return end
    if room:askForSkillInvoke(player, self.name, nil, "#os__lijians-invoke::" .. target.id) then
      room:doIndicate(player.id, {target.id})
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data
    room:setPlayerMark(player, "@os__lijians", 8)
    local result = room:askForCardsChosen(player, target, 0, #cards, {
      card_data = {
        { "pile_discard", cards }
      }
    }, self.name)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(result)
    room:obtainCard(player, dummy, true, fk.ReasonJustMove)
    for _, c in ipairs(result) do
      table.removeOne(cards, c)
    end
    if #cards > 0 and not target.dead then
      room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, true, player.id)
    end
    if target.dead then return end
    if #cards > #result then -- and room:askForChoice(player, {"os__lijians_damage::" .. target.id, "Cancel"}, self.name) ~= "Cancel" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and player:getMark("@os__lijians") > 0 and table.find(data, function(move) return move.toArea == Card.DiscardPile end)
  end,
  on_refresh = function(self, event, target, player, data)
    local num = player:getMark("@os__lijians")
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        num = num - #move.moveInfo
      end
      if num <= 0 then
        player.room:setPlayerMark(player, "@os__lijians", 0)
        return false
      end
    end
    player.room:setPlayerMark(player, "@os__lijians", num)
  end,
}
local chungang = fk.CreateTriggerSkill{
  name = "os__chungang",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    local room = player.room
    local guzheng_pairs = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.PlayerHand and move.to and move.to ~= player.id and room:getPlayerById(move.to).phase ~= Player.Draw then
        guzheng_pairs[move.to] = (guzheng_pairs[move.to] or 0) + #move.moveInfo
      end
    end
    for key, value in pairs(guzheng_pairs) do
      if not player.room:getPlayerById(key):isNude() and value > 1 then
        return true
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    local guzheng_pairs = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.PlayerHand and move.to and move.to ~= player.id and room:getPlayerById(move.to).phase ~= Player.Draw then
        guzheng_pairs[move.to] = (guzheng_pairs[move.to] or 0) + #move.moveInfo
      end
    end
    for key, value in pairs(guzheng_pairs) do
      if not player.room:getPlayerById(key):isNude() and value > 1 then
        table.insertIfNeed(targets, key)
      end
    end
    room:sortPlayersByAction(targets)
    for _, target_id in ipairs(targets) do
      if not player:hasSkill(self) then break end
      local skill_target = room:getPlayerById(target_id)
      self:doCost(event, skill_target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:askForDiscard(target, 1, 1, true, self.name, false, nil, "#os__chungang-discard:" .. player.id)
  end,
}
zhangzhao:addSkill(lijians)
zhangzhao:addSkill(chungang)

Fk:loadTranslationTable{
  ["zhangzhao"] = "张昭",
  ["os__lijians"] = "力谏",
  [":os__lijians"] = "昂扬技，其他角色的弃牌阶段结束时，你可获得任意张此阶段因弃置而移至弃牌堆里的牌，然后将其余牌交给其，若其获得的牌数大于你，则你对其造成1点伤害。<u>激昂</u>：八张牌进入弃牌堆。" .. 
  "<br/><font color='grey'>#\"<b>昂扬技</b>\"：昂扬技发动后，技能失效直到满足<b>激昂</b>条件。",
  ["os__chungang"] = "纯刚",
  [":os__chungang"] = "锁定技，当其他角色于其摸牌阶段外获得不少于两张牌后，你令其弃置一张牌。",

  ["#os__lijians-invoke"] = "力谏：你可获得任意张此阶段因弃置而移至弃牌堆里的牌，然后将其余牌交给 %dest",
  ["os__lijiansReturn"] = "交还",
  ["@os__lijians"] = "力谏",
  ["os__lijians_damage"] = "对%dest造成1点伤害",
  ["#os__chungang-discard"] = "受到 %src “纯刚” 的影响，请弃置一张牌",

  ["$os__lijians1"] = "陛下欲复昔日桓公之事乎？",
  ["$os__lijians2"] = "君者当御贤于后，安可校勇于猛兽！",
  ["$os__chungang1"] = "陛下若此，天下何以观之！",
  ["$os__chungang2"] = "偏听谄谀之言，此为万民所仰之君乎？",
  ["~zhangzhao"] = "哼哼！此皆老臣罪责，陛下岂会有过……",	
}

local zhanghong = General(extension, "zhanghong", "wu", 3)
local quanqian = fk.CreateActiveSkill{
  name = "os__quanqian",
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player:getMark("@os__quanqian") == 0
  end,
  target_num = 1,
  min_card_num = 1,
  max_card_num = 4,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return table.every(selected, function (id) return card:compareSuitWith(Fk:getCardById(id), true) end)
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "@os__quanqian", 6)
    local cards = effect.cards
    room:moveCardTo(cards, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id)
    if player.dead then return false end
    if #cards > 1 then
      local cids = room:getCardsFromPileByRule(".|.|.|.|.|equip")
      if #cids > 0 then
        room:obtainCard(player, cids[1], false, fk.ReasonPrey)
        if player.dead then return false end
      end
    end
    local choices = {"os__quanqian_draw:::" .. target:getHandcardNum(), "os__quanqian_get::" .. target.id}
    if target:isKongcheng() then table.remove(choices) end
    local choice = room:askForChoice(player, choices, self.name)
    if choice:startsWith("os__quanqian_draw") then
      local num = target:getHandcardNum() - player:getHandcardNum()
      if num > 0 then player:drawCards(num, self.name) end
    else
      cards = target:getCardIds(Player.Hand)
      local suit = "log_spade" -- default
      local result = room:askForCustomDialog(player, self.name,
        "packages/utility/qml/ChooseCardsAndChoiceBox.qml", {
          cards,
          {"log_spade", "log_club", "log_heart", "log_diamond"},
          "#os__quanqian-choose::" .. target.id,
          {}, 0, 0,
        })
      if result ~= "" then
        local reply = json.decode(result)
        suit = reply.choice
      end
      local dummy = Fk:cloneCard("dilu")
      for _, cid in ipairs(cards) do
        if Fk:getCardById(cid):getSuitString(true) == suit then dummy:addSubcard(cid) end
      end
      if #dummy.subcards > 0 then
        room:obtainCard(player, dummy, false, fk.ReasonPrey)
      end
    end
  end
}
local quanqian_trig = fk.CreateTriggerSkill{
  name = "#os__quanqian_trig",
  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@os__quanqian") > 0 and table.find(data, function(move) return move.from == player.id and move.toArea == Card.DiscardPile end)
  end,
  on_refresh = function(self, event, target, player, data)
    local num = player:getMark("@os__quanqian")
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            num = num - 1
          end
        end
      end
      if num <= 0 then
        player.room:setPlayerMark(player, "@os__quanqian", 0)
        return false
      end
    end
    player.room:setPlayerMark(player, "@os__quanqian", num)
  end,
}
quanqian:addRelatedSkill(quanqian_trig)
local rouke = fk.CreateTriggerSkill{
  name = "os__rouke",
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase ~= Player.Draw then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand and #move.moveInfo > 1 then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
zhanghong:addSkill(quanqian)
zhanghong:addSkill(rouke)
Fk:loadTranslationTable{
  ["zhanghong"] = "张纮",
  ["os__quanqian"] = "劝迁",
  [":os__quanqian"] = "昂扬技，出牌阶段限一次，你可以将至多四张花色不同的手牌交给一名其他角色，若你以此法给出了不少于两张牌，你从牌堆中获得一张装备牌。然后你选择一项：1.将手牌摸至与其手牌数相同；2.观看其手牌并选择一种花色，然后获得其手牌中所有此花色的牌。<u>激昂</u>：你弃置六张手牌。" .. 
  "<br/><font color='grey'>#\"<b>昂扬技</b>\"：昂扬技发动后，技能失效直到满足<b>激昂</b>条件。",
  ["os__rouke"] = "柔克",
  [":os__rouke"] = "锁定技，当你在摸牌阶段外获得不少于两张牌时，你摸一张牌。",

  ["@os__quanqian"] = "劝迁",
  ["os__quanqian_draw"] = "手牌摸至%arg张",
  ["os__quanqian_get"] = "观看%dest手牌并选择一种花色，获得其中所有此花色的牌",
  ["#os__quanqian-choose"] = "劝迁：选择一种花色，获得%dest手牌中所有此花色的牌",

  ["$os__quanqian1"] = "欲承奕世之基，当迁龙兴之地。",
  ["$os__quanqian2"] = "吴郡僻远，宜迁都秣陵，以承王业。",
  ["$os__rouke1"] = "宽以待人，柔能克刚，则英雄莫敌。",
  ["$os__rouke2"] = "务崇宽惠，顺天命以行诛。",
  ["~zhanghong"] = "惟愿主公从善如流，老臣去矣……",	
}

local wenchou = General(extension, "wenchou", "qun", 4)
local juexing = fk.CreateViewAsSkill{
  name = "os__juexing",
  prompt = "#os__juexing",
  pattern = "duel",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local c = Fk:cloneCard("duel")
    c.skillName = self.name
    return c
  end,
  before_use = function(self, player, use)
    use.extra_data = use.extra_data or {}
    use.extra_data.os__juexingEffect = 1
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
}

local juexing_delay = fk.CreateTriggerSkill{
  name = "#os__juexing_delay",
  mute = true,
  events = {fk.CardEffecting, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.trueName == "duel" and (data.extra_data or {}).os__juexingEffect == (event == fk.CardEffecting and 1 or 2)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = TargetGroup:getRealTargets(data.tos)
    table.insert(targets, data.from)
    room:sortPlayersByAction(targets)
    if event == fk.CardEffecting then
      for _, pid in ipairs(targets) do
        local p = room:getPlayerById(pid)
        if not p.dead then
          p:addToPile("os__juexing", p:getCardIds(Player.Hand), false, self.name)
          if not p.dead then
            local cards = p:drawCards(p.hp + p:getMark("@os__juexing"), self.name)
            table.forEach(cards, function(id) room:setCardMark(Fk:getCardById(id), "@@os__juexing-inhand", 1) end)
          end
        end
      end
    else
      for _, pid in ipairs(targets) do
        local p = room:getPlayerById(pid)
        if not p.dead then
          local cards = table.filter(p:getCardIds(Player.Hand), function(id) return
            Fk:getCardById(id):getMark("@@os__juexing-inhand") > 0 and not p:prohibitDiscard(Fk:getCardById(id))
          end)
          if #cards > 0 then
            room:throwCard(cards, self.name, p)
          end
          if not p.dead then
            local dummy = Fk:cloneCard("zixing")
            dummy:addSubcards(p:getPile("os__juexing"))
            room:obtainCard(pid, dummy, false)
          end
        end
      end
    end
    data.extra_data.os__juexingEffect = data.extra_data.os__juexingEffect + 1
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:usedSkillTimes(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@os__juexing")
  end
}
juexing:addRelatedSkill(juexing_delay)

local xiayong = fk.CreateTriggerSkill{
  name = "os__xiayong",
  events = {fk.DamageCaused},
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(self) and data.card and data.card.trueName == "duel") then return end
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, false)
    if use_event == nil then return false end
    return (table.contains(TargetGroup:getRealTargets(use_event.data[1].tos), player.id) or use_event.data[1].from == player.id) and U.damageByCardEffect(player.room, false) and (data.to ~= player or not player:isKongcheng())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.to == player then
      room:notifySkillInvoked(player, self.name, "negative")
      player:broadcastSkillInvoke(self.name, 1)
      local cards = table.filter(player:getCardIds(Player.Hand), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end)
      if #cards > 0 then
        room:throwCard(table.random(cards), self.name, player)
      end
    else
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name, 2)
      room:doIndicate(player.id, {data.to.id})
      data.damage = data.damage + 1
    end
  end,
}
wenchou:addSkill(juexing)
wenchou:addSkill(xiayong)
Fk:loadTranslationTable{
  ["wenchou"] = "文丑",
  ["#wenchou"] = "有去无回",
  ["illustrator:wenchou"] = "Mr_Sleeping",

  ["os__juexing"] = "绝行",
  [":os__juexing"] = "出牌阶段限一次，你可视为对一名其他角色使用一张【决斗】，该【决斗】生效时，你与其将所有手牌扣置于各自武将牌上，然后摸等同于当前体力值的牌；该【决斗】结算结束后，你与其弃置以此法摸的牌，然后获得扣置于武将牌上的牌。<u>历战</u>：你以此法摸牌时，摸牌数+1。" ..
  "<br/><font color='grey'>#\"<b>历战</b>\"：发动过本技能的回合结束后，对本技能进行升级或修改，可叠加。",
  ["os__xiayong"] = "狭勇",
  [":os__xiayong"] = "锁定技，你为目标角色或使用者的【决斗】造成伤害时，若受到此牌伤害的角色：为你，你随机弃置一张手牌；不为你，此伤害+1。",

  ["#os__juexing"] = "绝行：你可视为对一名其他角色使用一张【决斗】",
  ["@os__juexing"] = "绝行 历战",
  ["@@os__juexing-inhand"] = "绝行",

  ["$os__juexing1"] = "阿瞒且寄汝首，待吾一骑取之！",
  ["$os__juexing2"] = "杀！尽歼贼败军之众！",
  ["$os__xiayong1"] = "一招之差，不足决此战胜负！",
  ["$os__xiayong2"] = "这般身手，也敢来战我？",
  ["~wenchou"] = "黄泉路上，你我兄弟亦不可独行……",	
}

local yuantan = General(extension, "yuantan", "qun", 4)
local qiaosih = fk.CreateTriggerSkill{
  name = "os__qiaosih",
  events = {fk.EventPhaseStart},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not (player == target and player:hasSkill(self) and player.phase == Player.Finish) then return end
    local room = player.room
    local ids = table.filter(U.getMark(player, "_os__qiaosih-turn"), function(id) return room:getCardArea(id) == Card.DiscardPile end)
    if #ids > 0 then 
      self.cost_data = ids
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = self.cost_data
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(ids)
    room:obtainCard(player, dummy, true, fk.ReasonPrey, player.id)
    if #ids < player.hp and not player.dead then
      room:loseHp(player, 1, self.name)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player.room.current == player
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local record = U.getMark(player, "_os__qiaosih-turn")
    for _, move in ipairs(data) do
      if move.from and move.from ~= player.id and move.to ~= move.from then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insertIfNeed(record, id)
          end
        end
      end
    end
    room:setPlayerMark(player, "_os__qiaosih-turn", record)
  end
}

local baizu = fk.CreateTriggerSkill{
  name = "os__baizu",
  events = {fk.EventPhaseStart},
  anim_type = "control",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player == target and target:hasSkill(self) and player.phase == Player.Finish and
      player:isWounded() and not player:isKongcheng() and (player.hp + player:getMark("@os__baizu")) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = player.hp + player:getMark("@os__baizu")
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng()
    end), Util.IdMapper)
    self.cost_data = #targets <= x and targets or room:askForChoosePlayers(player, targets, x, x, "#os__baizu-ask:::" .. x, self.name, false)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = self.cost_data
    table.insert(targets, player.id)
    room:doIndicate(player.id, targets)
    room:sortPlayersByAction(targets)
    targets = table.map(targets, Util.Id2PlayerMapper)
    local cardType
    local victims = {}
    local cardsMap = {}
    for _, p in ipairs(targets) do
      cardsMap[p.id] = table.filter(p:getCardIds("he"), function(id)
        return not p:prohibitDiscard(Fk:getCardById(id))
      end)
    end
    local extra_data = {
      num = 1,
      min_num = 1, -- 不加会报错
      include_equip = false,
      skillName = self.name,
      pattern = ".",
      reason = self.name,
    }
    local toAsk = {}
    for _, p in ipairs(targets) do
      if #cardsMap[p.id] > 0 then
        table.insert(toAsk, p)
        p.request_data = json.encode({ "discard_skill", "#os__baizu-discard", false, extra_data })
      end
    end
    if #toAsk > 0 then
      room:notifyMoveFocus(targets, self.name)
      room:doBroadcastRequest("AskForUseActiveSkill", toAsk)
      local moveInfos = {}
      for _, p in ipairs(toAsk) do
        local throw
        if p.reply_ready then
          local replyCard = json.decode(p.client_reply).card
          throw = json.decode(replyCard).subcards
        else
          throw = table.random(cardsMap[p.id], 1)
        end
        if p == player then
          cardType = Fk:getCardById(throw[1]).type
        elseif cardType == Fk:getCardById(throw[1]).type then
          table.insert(victims, p.id)
        end
        table.insert(moveInfos, {
          ids = throw,
          from = p.id,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard,
          proposer = p.id,
          skillName = self.name,
        })
      end
      room:moveCards(table.unpack(moveInfos))
      room:delay(100 * #targets)
    end
    room:sortPlayersByAction(victims)
    for _, pid in ipairs(victims) do
      if player.dead then break end
      local p = room:getPlayerById(pid)
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:usedSkillTimes(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@os__baizu")
  end
}

yuantan:addSkill(qiaosih)
yuantan:addSkill(baizu)

Fk:loadTranslationTable{
  ["yuantan"] = "袁谭",
  ["#yuantan"] = "兄弟阋墙",

  ["os__qiaosih"] = "峭嗣",
  [":os__qiaosih"] = "结束阶段，你可获得其他角色本回合进入弃牌堆的牌，然后若你以此法获得牌的数量小于X，你失去1点体力（X为你的体力值）。",
  ["os__baizu"] = "败族",
  [":os__baizu"] = "锁定技，结束阶段，若你已受伤且有手牌，你须选择X名其他角色，令你与这些角色同时弃置一张手牌，然后你对弃置与你相同类型牌的其他角色造成1点伤害（X为你的体力值）。<u>历战</u>：X+1。" ..
  "<br/><font color='grey'>#\"<b>历战</b>\"：发动过本技能的回合结束后，对本技能进行升级或修改，可叠加。",

  ["@os__baizu"] = "败族",
  ["#os__baizu-ask"] = "败族：选择 %arg 名其他角色，你和这些角色各弃置一张手牌",
  ["#os__baizu-discard"] = "败族：请弃置一张手牌",
}

return extension
