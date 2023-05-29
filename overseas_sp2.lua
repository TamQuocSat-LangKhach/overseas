local extension = Package("overseas_sp2")
extension.extensionName = "overseas"

Fk:loadTranslationTable{
  ["overseas_sp2"] = "国际服专属2",
}

local os__godguanyu = General(extension, "os__godguanyu", "god", 4)

local os__wushen = fk.CreateFilterSkill{
  name = "os__wushen",
  card_filter = function(self, to_select, player)
    return player:hasSkill(self.name) and to_select.suit == Card.Heart and table.contains(player.player_cards[Player.Hand], to_select.id) --不能用getCardArea！
  end,
  view_as = function(self, to_select)
    local card = Fk:cloneCard("slash", Card.Heart, to_select.number)
    card.skillName = "os__wushen"
    return card
  end,
}
local os__wushen_buff = fk.CreateTargetModSkill{
  name = "#os__wushen_buff",
  residue_func = function(self, player, skill, scope, card)
    return (player:hasSkill("os__wushen") and skill.trueName == "slash_skill" and scope == Player.HistoryPhase and card and card.suit == Card.Heart) and 999 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return (player:hasSkill("os__wushen") and skill.trueName == "slash_skill" and card.suit == Card.Heart) and 999 or 0
  end,
}
local os__wushen_trg = fk.CreateTriggerSkill{
  name = "#os__wushen_trg",
  anim_type = "offensive",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.card.trueName == "slash" then
      if event == fk.CardUsing then return player:usedCardTimes("slash", Player.HistoryPhase) == 1
      elseif data.card.suit == Card.Heart then
        local targets = {}
        for _, p in ipairs(player.room:getOtherPlayers(player)) do
          if p:getMark("@os__nightmare") > 0 and not table.contains(TargetGroup:getRealTargets(data.tos), p.id) then
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
    room:broadcastSkillInvoke("os__wushen")
    room:notifySkillInvoked(player, "os__wushen")
    if event == fk.CardUsing then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, target in ipairs(player.room:getAlivePlayers()) do
        table.insertIfNeed(data.disresponsiveList, target.id)
      end
    else
      room:doIndicate(player.id, self.cost_data)
      table.forEach(self.cost_data, function(pid) 
        TargetGroup:pushTargets(data.targetGroup, pid)
      end)
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
        local availableTargets = table.map(
          table.filter(player.room:getOtherPlayers(player), function(p)
            return (p:getMark("@os__nightmare") > 0)
          end),
          function(p)
            return p.id
          end
        )
        if #availableTargets > 0 then
          self.cost_data = availableTargets
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
      local targets = room:askForChoosePlayers(player, self.cost_data, 1, #self.cost_data, "#os__wuhun-targets", self.name, false)
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
  ["os__wushen"] = "武神",
  [":os__wushen"] = "锁定技，①你的红桃手牌视为【杀】。②你使用红桃【杀】无距离和次数限制且额外选择所有有“梦魇”的角色为目标。③你于每个阶段内使用的第一张【杀】不能被响应。",
  ["os__wuhun"] = "武魂",
  [":os__wuhun"] = "锁定技，①当你受到1点伤害后，伤害来源获得1枚“梦魇”。②当你对有“梦魇”的角色造成伤害后，其获得1枚“梦魇”。③当你死亡时，你可判定：若结果不为【桃】或【桃园结义】，你选择至少一名有“梦魇”的角色，这些角色失去X点体力（X为其“梦魇”数）。",

  ["@os__nightmare"] = "梦魇",
  ["os__wuhun_judge"] = "判定，若结果不为【桃】或【桃园结义】，你选择至少一名有“梦魇”的角色失去X点体力（X为其“梦魇”数）",
  ["#os__wuhun-targets"] = "武魂：选择至少一名有“梦魇”的角色，各失去X点体力（X为其“梦魇”数）",

  ["$os__wushen1"] = "还不速速领死！",
  ["$os__wushen2"] = "取汝狗头，犹如探囊取物！",
  ["$os__wuhun1"] = "谁来与我同去？",
  ["$os__wuhun2"] = "拿命来！",
  ["~os__godguanyu"] = "什么，此地名叫麦城？",
}

local os__godlvmeng = General(extension, "os__godlvmeng", "god", 3)

local os__shelie = fk.CreateTriggerSkill{
  name = "os__shelie",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
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
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and type(player:getMark("@os__shelie-turn")) == "table" and #player:getMark("@os__shelie-turn") == 4 and player:usedSkillTimes(self.name, Player.HistoryRound) < 1
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"phase_draw", "phase_play"}
    if player:getMark("_os__shelie") ~= 0 then
      table.remove(choices, player:getMark("_os__shelie"))
    end
    self.cost_data = player.room:askForChoice(player, {"phase_draw", "phase_play"}, self.name, "#os__shelie_extra-ask")
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
    room:setPlayerMark(player, "_os__shelie", self.cost_data == "phase_draw" and 1 or 2)
    player:gainAnExtraPhase(self.cost_data == "phase_draw" and Player.Draw or Player.Play)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and player.phase ~= Player.NotActive and data.card.suit ~= Card.NoSuit
  end,
  on_refresh = function(self, event, target, player, data)
    local suitsRecorded = type(player:getMark("@os__shelie-turn")) == "table" and player:getMark("@os__shelie-turn") or {}
    table.insertIfNeed(suitsRecorded, "log_" .. data.card:getSuitString())
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
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cids = target.player_cards[Player.Hand]
    room:fillAG(player, cids)
    local card_suits = {}
    table.forEach(cids, function(id)
      table.insertIfNeed(card_suits, Fk:getCardById(id).suit)
    end)
    local num = #card_suits
    local id = room:askForAG(player, cids, true, self.name) --AG cancelble
    room:closeAG(player)
    if not id then return false end
    local choice = room:askForChoice(player, {"os__gongxin_discard", "os__gongxin_put", "Cancel"}, self.name, "#os__gongxin-treat:::" .. Fk:getCardById(id).name)
    if choice == "os__gongxin_discard" then
      room:throwCard({id}, self.name, target, player)
    elseif choice == "os__gongxin_put" then
      room:moveCardTo({id}, Card.DrawPile, nil, fk.ReasonPut, self.name, nil, false)
    end
    card_suits = {}
    cids = target.player_cards[Player.Hand]
    table.forEach(cids, function(id)
      table.insertIfNeed(card_suits, Fk:getCardById(id).suit)
    end)
    local num2 = #card_suits
    if num > num2 then
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
    for _, target in ipairs(room:getAlivePlayers()) do
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
  [":os__gongxin"] = "出牌阶段限一次，你可观看一名其他角色的手牌，然后你可展示其中一张牌，选择一项：1. 你弃置其此牌；2. 将此牌置于牌堆顶，然后若其手牌中花色数因此减少，其不能响应你本回合使用的下一张牌。",

  ["@os__shelie-turn"] = "涉猎",
  ["#os__shelie_extra"] = "涉猎",
  ["#os__shelie_extra-ask"] = "涉猎：选择执行一个额外的阶段",
  ["#os__shelie_extra_log"] = "%from 发动“%arg”，执行一个额外的 %arg2",
  ["#os__gongxin-treat"] = "攻心：你可对【%arg】选择一项",
  ["os__gongxin_discard"] = "弃置",
  ["os__gongxin_put"] = "置于牌堆顶",
  ["@@os__gongxin_dr-turn"] = "攻心",
  ["#os__gongxin_dr"] = "攻心",

  ["$os__shelie1"] = "什么都略懂一点，生活更多彩一些。",
  ["$os__shelie2"] = "略懂，略懂。",
  ["$os__gongxin1"] = "攻城为下，攻心为上。",
  ["$os__gongxin2"] = "我替施主把把脉。",
  ["~os__godlvmeng"] = "劫数难逃，我们别无选择……",
}

local os__gexuan = General(extension, "os__gexuan", "qun", 3)

local os__danfa = fk.CreateTriggerSkill{
  name = "os__danfa",
  events = {fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if (target ~= player or not player:hasSkill(self.name)) then return false end
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
    return (#selected == 0 or (#selected == 1 and Fk:getCardById(to_select).suit ~= Fk:getCardById(selected[1]).suit)) and Self:getPileNameOfId(to_select) == "os__cinnabar"
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
        function(p)
          return p.id
        end
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
        function(p)
          return p.id
        end
        )
        if #availableTargets == 0 then return false end
        local target = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__lingbao-black", self.name, false)
        if #target > 0 then
          target = room:getPlayerById(target[1])
          local id = room:askForCardChosen(player, target, "hej", self.name)
          local flagTable = {"h", "e", "j"}
          table.remove(flagTable, room:getCardArea(id))
          room:throwCard({id}, self.name, target, player)
          local areas = {}
          if table.contains(flagTable, "h") then table.insert(areas, Player.Hand) end
          if table.contains(flagTable, "e") then table.insert(areas, Player.Equip) end
          if table.contains(flagTable, "j") then table.insert(areas, Player.Judge) end
          local cards = target:getCardIds(areas)
          if #cards == 0 then return end
          if room:askForChoice(player, {"os__lingbao_black_discard:::" .. target.general, "Cancel"}, self.name) ~= "Cancel" then --%src不行 以及为什么askfor...==0不会截停
            id = room:askForCardChosen(player, target, table.concat(flagTable), self.name)
            if id then room:throwCard({id}, self.name, target, player) end
          end
        end
      end
    else
      local targets = room:askForChoosePlayers(player, table.map(room.alive_players, function(p) return p.id end), 2, 2, "#os__lingbao-black_red", self.name, false)
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

local os__sidao = fk.CreateTriggerSkill{
  name = "os__sidao",
  events = {fk.GameStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.GameStart then
      return true
    elseif player.phase == Player.Start and type(player:getMark("_os__sidao")) == "string" then
      --local id = player.room:getCardsFromPileByRule(player:getMark("_os__sidao"), 1, "allPiles") --为什么不行？
      --if #id > 0 then
      local card
      for _, id in ipairs(Fk:getAllCardIds()) do
        local c = Fk:getCardById(id)
        if c.name == player:getMark("_os__sidao") and table.contains({Card.DiscardPile, Card.DrawPile}, player.room:getCardArea(id)) then
          card = c
          break
        end
      end
      if card then
        self.cost_data = card
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then self.cost_data = player.room:askForChoice(player, {"celestial_calabash", "horsetail_whisk", "talisman"}, self.name, "#os__sidao-ask") end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = nil
    if event == fk.GameStart then 
      room:setPlayerMark(player, "_os__sidao", self.cost_data)
      for _, id in ipairs(Fk:getAllCardIds()) do
        local c = Fk:getCardById(id)
        if c.name == self.cost_data then
          card = c
          break
        end
      end
    else
      --card = Fk:getCardById(self.cost_data)
      card = self.cost_data
      room:obtainCard(player, card, true, fk.ReasonPrey)
    end
    if card then
      room:useCard({
        from = player.id,
        tos = { {player.id} },
        card = card,
      })
    end
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
  [":os__sidao"] = "①游戏开始时，你选择一件法宝并使用之：【灵宝仙葫】、【太极拂尘】、【冲应神符】。②准备阶段开始时，若你选择过的法宝在牌堆或弃牌堆中，则你获得并使用之。<br></br>" .. 
  "<font color='grey'>【<b>灵宝仙葫</b>】♥A  装备牌·武器 攻击范围：3  锁定技，当你造成大于1点的伤害时或一名角色死亡时，你增加1点体力上限并回复1点体力。<br></br>" ..
  "【<b>太极拂尘</b>】♥A  装备牌·武器 攻击范围：5  当你使用的【杀】指定目标后，目标角色需弃置一张牌，否则不可响应此【杀】；若其弃置的牌与此【杀】花色相同，你获得之。<br></br>" ..
  "【<b>冲应神符</b>】♥A  装备牌·防具  锁定技，当你受到一种牌名的牌造成的伤害后，本局游戏同牌名的牌对你造成的伤害-1。</font>",

  ["os__cinnabar"] = "丹",
  ["#os__danfa-put"] = "丹法：你可将一张牌置于你的武将牌上，称为“丹”",
  ["@os__danfa-turn"] = "丹法",
  ["#os__lingbao-red"] = "灵宝：选择一名角色，令其回复1点体力",
  ["#os__lingbao-black"] = "灵宝：选择一名角色，弃置其至多两个不同区域的各一张牌",
  --["#os__lingbao-black_2"] = "灵宝：你可弃置 %src 另一个区域的一张牌",
  ["os__lingbao_black_discard"] = "弃置%arg另一个区域的一张牌",
  ["#os__lingbao-black_red"] = "灵宝：选择两名角色，先选的摸一张牌，后选的弃置一张牌",
  ["#os__sidao-ask"] = "司道：选择一件法宝并使用之",
}

local os__himiko = General(extension, "os__himiko", "qun", 3, 3, General.Female)

local os__zongkui = fk.CreateTriggerSkill{
  name = "os__zongkui",
  anim_type = "control",
  events = {fk.RoundStart, fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.EventPhaseChanging and (target ~= player or data.from ~= Player.NotActive)then return false end
    local targets = table.filter(player.room:getOtherPlayers(player), function(p)
      return p:getMark("@@os__puppet") == 0
    end)
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseChanging then
      local availableTargets = table.map(self.cost_data, function(p)
        return p.id
      end)
      local target = room:askForChoosePlayers(
        player,
        availableTargets,
        1,
        1,
        "#os__zongkui-ask",
        self.name
      )
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
      local availableTargets = table.map(table.filter(self.cost_data, function(p)
        return p:getMark("@@os__puppet") == 0 and p.hp == n
      end), function(p)
        return p.id
      end)
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
    return target:getMark("@@os__puppet") > 0 and player:hasSkill(self.name) and not target.dead
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
    return target == player and player:hasSkill(self.name) and
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
    return player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room:getAlivePlayers()) do
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
  events = {fk.TargetConfirming, fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)  and ((event == fk.TargetConfirming and #AimGroup:getAllTargets(data.tos) == 1 and player.room:getPlayerById(data.from):getMark("@@os__puppet") > 0) or (event == fk.AfterCardTargetDeclared and #data.tos == 1)) 
    and (data.card.type == Card.TypeBasic or (data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick))
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetConfirming then
      return player.room:askForSkillInvoke(player, self.name, data, "#os__canshi::" .. data.from .. ":" .. data.card.name)
    else
      local availableTargets = table.map(table.filter(player.room:getAlivePlayers(), function(p)
        return p:getMark("@@os__puppet") > 0 and not table.contains(TargetGroup:getRealTargets(data.tos), p.id)
      end), function(p)
        return p.id 
      end)
      if #availableTargets == 0 then return false end
      local targets = player.room:askForChoosePlayers(player, availableTargets, 1, #availableTargets, "#os__canshi-targets", self.name, true)
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirming then
      AimGroup:cancelTarget(data, data.to)
      room:removePlayerMark(room:getPlayerById(data.from), "@@os__puppet")
    else
      room:doIndicate(player.id, self.cost_data)
      table.insert(data.tos, self.cost_data)
      table.forEach(self.cost_data, function(pid) 
        room:removePlayerMark(room:getPlayerById(pid), "@@os__puppet")
      end)
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
}

local nashime = General(extension, "nashime", "qun", 3)

local os__chijie = fk.CreateTriggerSkill{
  name = "os__chijie",
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room:getAlivePlayers()) do
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
    room:moveCards(
      {
        ids = effect.cards,
        from = effect.from,
        to = effect.tos[1],
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonExchange,
        proposer = player.id,
        skillName = self.name,
      },
      {
        ids = cids,
        from = effect.tos[1],
        to = effect.from,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonExchange,
        proposer = player.id,
        skillName = self.name,
      }
    )
    if target.kingdom == player.kingdom or target:getHandcardNum() > player:getHandcardNum() then
      player:drawCards(1, self.name)
    end
  end,
}

local os__renshe = fk.CreateTriggerSkill{
  name = "os__renshe",
  events = {fk.Damaged},
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"os__waishi_times"}
    local room = player.room
    if not table.every(room:getOtherPlayers(player), function(p)
      return p.kingdom == player.kingdom
    end) then
      table.insert(choices, 1, "os__renshe_change")
    end
    if not table.every(room:getOtherPlayers(player), function(p)
      return p == data.from
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
    else
      if choice == "os__renshe_change" then
        local kingdoms = {}
        for _, p in ipairs(room:getAlivePlayers()) do
          table.insertIfNeed(kingdoms, p.kingdom)
        end
        table.removeOne(kingdoms, player.kingdom)
        player.kingdom = room:askForChoice(player, kingdoms, self.name, "#os__chijie-choose")
        room:broadcastProperty(player, "kingdom")
      else
        local target = room:askForChoosePlayers(player, table.map(
          table.filter(room:getOtherPlayers(player), function(p)
            return (not p == data.from)
          end),
          function(p)
            return p.id
          end
        ), 1, 1, "#os__renshe-target", self.name, false)
        if #target > 0 then
          local to = room:getPlayerById(target[1])
          for _, p in ipairs(room:getAlivePlayers()) do --为了按照行动顺序
            if p == to or p == player then
              p:drawCards(1, self.name)
            end
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
  ["os__renshe_draw"] = "与一名其他角色各摸一张牌",
  ["#os__renshe-target"] = "忍涉：选择一名其他角色，与其各摸一张牌",
}

local jianshuo = General(extension, "jianshuo", "qun", 6)

local os__kunsi = fk.CreateViewAsSkill{
  name = "os__kunsi",
  anim_type = "offensive",
  pattern = "slash",
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
    return scope == Player.HistoryPhase and card and table.contains(card.skillNames, "os__kunsi") and 999 or 0
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
  refresh_events = {fk.Damaged, fk.CardUseFinished, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return target == player and (data.extra_data or {}).os__kunsiUser == player.id
    elseif event == fk.Damaged then
      local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      return parentUseData and (parentUseData.data[1].extra_data or {}).os__kunsiUser == player.id
    else
      return target == player and player:getMark("_os__linglu") ~= 0 and data.from == Player.NotActive
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
      table.forEach(table.map(player:getMark("_os__linglu"), function(pid)
        return room:getPlayerById(pid)
      end), function(p)
        room:handleAddLoseSkills(p, "-os__linglu")
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
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
        return p.id
      end), 1, 1, "#os__linglu-ask", self.name, true)

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
  refresh_events = {fk.Damage, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and (player:getMark("@os__linglu") ~= 0 or player:getMark("@os__linglu_twice") ~=0) and (event == fk.Damage or data.to == Player.NotActive)
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
  [":os__linglu"] = "出牌阶段开始时，你可强令一名其他角色在其下回合结束前造成2点伤害。成功：其摸两张牌；失败：其失去1点体力。<br></br><font color='grey'>#\"<b>强令</b>\"<br></br>向一名角色颁布一项任务，在任务结束时点执行奖惩。",

  ["#os__linglu-ask"] = "令戮：你可强令一名其他角色在其下回合结束前造成2点伤害",
  ["os__linglu_twice"] = "令其〖令戮〗的失败结算进行两次",
  ["#os__linglu_twice-ask"] = "令戮：你可令 %src 〖令戮〗的失败结算进行两次",
  ["@os__linglu"] = "令戮",
  ["@os__linglu_twice"] = "令戮2",
}

local caozhao = General(extension, "caozhao", "wei", 4)

local os__fuzuan = fk.CreateActiveSkill{
  name = "os__fuzuan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function() return false end,
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
    if target ~= player or not player:hasSkill(self.name) then return false end
    return event == fk.Damaged or data.to ~= player
  end,
  on_trigger = function(self, event, target, player, data)
    return player.room:askForUseActiveSkill(player, "os__fuzuan", "#os__fuzuan-trg", true)
  end,
  on_use = function(self, event, target, player, data)
    return false
  end,
}
os__fuzuan:addRelatedSkill(os__fuzuan_trg)

local os__chongqi = fk.CreateTriggerSkill{
  name = "os__chongqi",
  anim_type = "support",
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(
      table.filter(room:getOtherPlayers(player), function(p)
        return (not p:hasSkill("os__fuzuan"))
      end),
      function(p)
        return p.id
      end
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
    return player:hasSkill(self.name) and data == self  
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
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
    if target ~= player or not player:hasSkill(self.name) then return false end
    return data.card.trueName == "slash" and #AimGroup:getAllTargets(data.tos) == 1 and ((event == fk.TargetSpecified and player:getSwitchSkillState(self.name) == 0) or (event == fk.TargetConfirmed and player:getSwitchSkillState(self.name) == 1)) and not player.room:getPlayerById(data.to):isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "switch")
    if event == fk.TargetSpecified then
      room:broadcastSkillInvoke(self.name, math.random(1, 2))
    else
      room:broadcastSkillInvoke(self.name, math.random(3, 4))
    end
    local user = room:getPlayerById(data.from)
    local target = room:getPlayerById(data.to)
    room:doIndicate(player.id, {player == user and data.to or data.from})
    local cids = room:askForCard(target, 1, 1, true, self.name, false, nil, "#os__feifu-give:" .. data.from)
    if #cids > 0 then
      room:moveCardTo(cids, Player.Hand, user, fk.ReasonGive, self.name, nil, false)
      local card = Fk:getCardById(cids[1])
      if card.type == Card.TypeEquip then
        local cardName = card.name
        local use = room:askForUseCard(user, cardName, cardName .. "|.|.|.|.|.|" .. id[1], "#os__feifu-use:::" .. cardName, true)
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
  [":os__chongqi"] = "①锁定技，当你获得此技能后，所有角色获得〖非服〗。②游戏开始时，你可减1点体力上限，令一名其他角色获得〖复纂〗。",
  ["os__feifu"] = "非服",
  [":os__feifu"] = "锁定技，转换技，阳：当你使用【杀】指定唯一目标后；阴：当你成为【杀】的唯一目标后；目标角色A须交给此【杀】的使用者B一张牌，若此牌为装备牌，B可使用此牌。",

  ["#os__fuzuan-ask"] = "复纂：你可选择 %src 的一个转换技，调整其阴阳状态",
  ["#os__fuzuan_trg"] = "复纂",
  ["#os__fuzuan-trg"] = "你可对一名有转换技的角色发动“复纂”",
  ["#os__chongqi-ask"] = "宠齐：你可减1点体力上限，令一名其他角色获得〖复纂〗",
  ["#os__feifu-give"] = "非服：请交给 %src 一张牌",
  ["#os__feifu-use"] = "非服：你可使用【%arg】",

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

--[[local zhangmancheng = General(extension, "zhangmancheng", "qun", 4)

local os__fengji = fk.CreateTriggerSkill{
  name = "os__fengji",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
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
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__fengji") ~= 0 and data.to == Player.NotActive
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__fengji"), "-")
    local num = tonumber(nums[1])
    local num2 = tonumber(nums[2])
    num2 = num2 - 1
    if num2 > 0 then
      room:setPlayerMark(player, "@os__fengji", num .. "-" .. num2)
    else
      if #player:getPile("os__revelation") > 0 then
        room:notifySkillInvoked(player, "os__fengji")
        room:broadcastSkillInvoke("os__fengji")
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(room:getCardsFromPileByRule(Fk:getCardById(player:getPile("os__revelation")[1]).trueName, num))
        if #dummy.subcards > 0 then
          room:obtainCard(player, dummy, false, fk.ReasonPrey)
        end
        room:moveCardTo(Fk:getCardById(player:getPile("os__revelation")[1]), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, "os__revelation")
      end
      room:setPlayerMark(player, "@os__fengji", 0)
    end
  end,
}
os__fengji:addRelatedSkill(os__fengji_conjure)

local os__yijuTargetMod = fk.CreateTargetModSkill{
  name = "#os__yijuTargetMod",
  residue_func = function(self, player, skill, scope)
    return (player:hasSkill(self.name) and #player:getPile("os__revelation") > 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase) and player.hp - 1 or 0
  end,
}
local os__yijuAR = fk.CreateAttackRangeSkill{
  name = "#os__yijuAR",
  correct_func = function(self, from, to)
    return (from:hasSkill(self.name) and #from:getPile("os__revelation") > 0) and from.hp or 0
  end,
}
local os__yiju = fk.CreateTriggerSkill{
  name = "os__yiju",
  events = {fk.DamageInflicted},
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and #player:getPile("os__revelation") > 0
  end,
  on_cost = function() return true end,
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
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:recover({ who = player, num = 1, recoverBy = player, skillName = self.name})
    local os__budaoSkills = table.random({"os__zhouhu", "os__zuhuo", "os__fengqi", "os__huangjin", "os__guimen", "os__zhouzu", "os__didao"}, 3) --
    local skillName = room:askForChoice(player, os__budaoSkills, self.name, "#os__budao-ask")
    room:handleAddLoseSkills(player, skillName, nil, true, false)
    local pid = room:askForChoosePlayers(player, table.map(
      table.filter(room:getOtherPlayers(player), function(p)
        return (not p:isNude())
      end),
      function(p)
        return p.id
      end
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

local os__zhouhu = fk.CreateActiveSkill{
  name = "os__zhouhu",
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and player:getMark("@os__zhouhu") == 0
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).color == Card.Red and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  target_num = 0,
  interaction = UI.Spin {
    from = 1, to = 3,
  },
  on_use = function(self, room, effect)
    local num = self.interaction.data
    if not num then return false end
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    room:setPlayerMark(player, "@os__zhouhu", num .. "-" .. num)
  end,
}
local os__zhouhu_conjure = fk.CreateTriggerSkill{
  name = "#os__zhouhu_conjure",
  mute = true,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__zhouhu") ~= 0 and data.to == Player.NotActive
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__zhouhu"), "-")
    local num = tonumber(nums[1])
    local num2 = tonumber(nums[2])
    num2 = num2 - 1
    if num2 > 0 then
      room:setPlayerMark(player, "@os__zhouhu", num .. "-" .. num2)
    else
      room:notifySkillInvoked(player, "os__zhouhu")
      room:broadcastSkillInvoke("os__zhouhu")
      room:recover({ who = player, num = num, recoverBy = player, skillName = self.name})
      room:setPlayerMark(player, "@os__zhouhu", 0)
    end
  end,
}
os__zhouhu:addRelatedSkill(os__zhouhu_conjure)

local os__zuhuo = fk.CreateActiveSkill{
  name = "os__zuhuo",
  anim_type = "defensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and player:getMark("@os__zuhuo") == 0
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  target_num = 0,
  interaction = UI.Spin {
    from = 1, to = 3,
  },
  on_use = function(self, room, effect)
    local num = self.interaction.data
    if not num then return false end
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    room:setPlayerMark(player, "@os__zuhuo", num .. "-" .. num)
  end,
}
local os__zuhuo_conjure = fk.CreateTriggerSkill{
  name = "#os__zuhuo_conjure",
  mute = true,
  events = {fk.EventPhaseChanging, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging then
      return player:getMark("@os__zhouhu") ~= 0 and data.to == Player.NotActive
    else
      return target == player and player:getMark("@os__zuhuo_defense") ~= 0
    end
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseChanging then
      local nums = string.split(player:getMark("@os__zuhuo"), "-")
      local num = tonumber(nums[1])
      local num2 = tonumber(nums[2])
      num2 = num2 - 1
      if num2 > 0 then
        room:setPlayerMark(player, "@os__zuhuo", num .. "-" .. num2)
      else
        room:notifySkillInvoked(player, "os__zuhuo")
        room:broadcastSkillInvoke("os__zuhuo")
        room:setPlayerMark(player, "@os__zuhuo_defense", num)
        room:setPlayerMark(player, "@os__zuhuo", 0)
      end
    else
      room:notifySkillInvoked(player, "os__zuhuo")
      room:broadcastSkillInvoke("os__zuhuo")
      room:removePlayerMark(player, "@os__zuhuo_defense")
      return true
    end
  end,
}
os__zuhuo:addRelatedSkill(os__zuhuo_conjure)

local os__fengqi = fk.CreateTriggerSkill{
  name = "os__fengqi",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.phase == Player.Play and not player:isNude() and player:getMark("@os__fengqi") == 0
  end,
  on_cost = function(self, event, target, player, data) 
    local room = player.room
    local cids = room:askForCard(player, 1, 1, false, self.name, true, ".|.|spade,club", "#os__fengqi-ask")
    if #cids > 0 then
      self.cost_data = cids
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player)
    local num = room:askForChoice(player, {"1", "2", "3"}, self.name, "#os__fengqi-conjure")
    room:setPlayerMark(player, "@os__fengqi", num .. "-" .. num)
  end,
}
local os__fengqi_conjure = fk.CreateTriggerSkill{
  name = "#os__fengqi_conjure",
  mute = true,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__fengqi") ~= 0 and data.to == Player.NotActive
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__fengqi"), "-")
    local num = tonumber(nums[1])
    local num2 = tonumber(nums[2])
    num2 = num2 - 1
    if num2 > 0 then
      room:setPlayerMark(player, "@os__fengqi", num .. "-" .. num2)
    else
      room:notifySkillInvoked(player, "os__fengqi")
      room:broadcastSkillInvoke("os__fengqi")
      player:drawCards(2 * num, self.name)
      room:setPlayerMark(player, "@os__fengqi", 0)
    end
  end,
}
os__fengqi:addRelatedSkill(os__fengqi_conjure)

local os__huangjin = fk.CreateTriggerSkill{
  name = "os__huangjin",
  events = {fk.TargetConfirming},
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash"
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

local os__guimen = fk.CreateTriggerSkill{
  name = "os__guimen",
  anim_type = "offensive",
  events = {fk.AfterCardsMove},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    self.cost_data = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).suit == Card.Spade then
            table.insert(self.cost_data, Fk:getCardById(info.cardId).number)
          end
        end
      end
    end
    return #self.cost_data > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, num in ipairs(self.cost_data) do
      local judge = {
        who = player,
        reason = self.name,
        pattern = num > 0 and (".|" .. num-1 .. "~" .. num+1 ) or nil,
      }
      room:judge(judge)
      if num > 0 and judge.card.number - num < 2 and judge.card.number - num > -2 then
        local pid = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p) return p.id end), 1, 1, "#os__guimen-target", self.name, false)
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
    end
  end,
}

local os__zhouzu = fk.CreateActiveSkill{
  name = "os__zhouzu",
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and player:getMark("@os__zhouzu") == 0
  end,
  card_num = 0,
  card_filter = function(self, to_select, selected)
    return false
  end,
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
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__zhouzu") ~= 0 and data.to == Player.NotActive
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__zhouzu")[2], "-")
    local num = tonumber(nums[1])
    local num2 = tonumber(nums[2])
    num2 = num2 - 1
    if num2 > 0 then
      room:setPlayerMark(player, "@os__zhouzu", {player:getMark("@os__zhouzu")[1], num .. "-" .. num2})
    else
      room:notifySkillInvoked(player, "os__zhouzu")
      room:broadcastSkillInvoke("os__zhouzu")
      local target = room:getPlayerById(player:getMark("_os__zhouzu"))
      if #target:getCardIds(Player.Equip) + #target:getCardIds(Player.Hand) < num then
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
    end
  end,
}
os__zhouzu:addRelatedSkill(os__zhouzu_conjure)

local os__didao = fk.CreateTriggerSkill{
  name = "os__didao",
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForResponse(player, self.name, ".", "#os__didao-ask:" .. target.id, true)
    if card ~= nil then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local orig = data.card.color
    player.room:retrial(self.cost_data, player, data, self.name, true)
    if self.cost_data.color == orig then
      player:drawCards(1, self.name)
    end
  end,
}

zhangmancheng:addSkill(os__fengji)
zhangmancheng:addSkill(os__yiju)
zhangmancheng:addSkill(os__budao)
zhangmancheng:addRelatedSkill(os__zhouhu)
zhangmancheng:addRelatedSkill(os__zuhuo)
zhangmancheng:addRelatedSkill(os__fengqi)
zhangmancheng:addRelatedSkill(os__huangjin)
zhangmancheng:addRelatedSkill(os__guimen)
zhangmancheng:addRelatedSkill(os__zhouzu)
zhangmancheng:addRelatedSkill(os__didao)

Fk:loadTranslationTable{
  ["zhangmancheng"] = "张曼成",
  ["os__fengji"] = "蜂集",
  [":os__fengji"] = "出牌阶段开始时，若你没有“示”，你可将一张牌置于武将牌上，称为“示”并施法X=1~3回合：{从牌堆中获得X张与“示”同名的牌，然后将“示”置入弃牌堆。}" .. 
  "<br></br><font color='grey'>#\"<b>施法</b>\"<br></br>一名角色的回合结束前，施法标记-1，减至0时执行施法效果。施法期间不能重复施法同一技能。",
  ["os__yiju"] = "蚁聚",
  [":os__yiju"] = "若你有“示”，①你于出牌阶段使用【杀】的次数上限和攻击范围均为你的体力值。②当你受到伤害时，你将“示”置入弃牌堆，令此伤害+1。",
  ["os__budao"] = "布道",
  [":os__budao"] = "限定技，准备阶段开始时，你可减1点体力上限，回复1点体力，从布道技能库的随机三个技能中选择一个获得，然后你可令一名其他角色获得相同技能并交给你一张牌。",
  
  ["os__zhouhu"] = "咒护",
  [":os__zhouhu"] = "出牌阶段限一次，你可弃置一张红色手牌并施法：回复X点体力。",
  ["os__zuhuo"] = "阻祸",
  [":os__zuhuo"] = "出牌阶段限一次，你可弃置一张非基本牌并施法：防止你受到的下X次伤害。",
  ["os__fengqi"] = "丰祈",
  [":os__fengqi"] = "出牌阶段结束时，你可弃置一张黑色手牌并施法：摸2X张牌。",
  ["os__huangjin"] = "黄巾",
  [":os__huangjin"] = "锁定技，当你成为【杀】的目标时，你判定：若结果点数与此【杀】点数差值不大于1，则此【杀】对你无效。",
  ["os__guimen"] = "鬼门",
  [":os__guimen"] = "锁定技，当你因弃置而失去一张黑桃牌后，你判定：若结果点数与你弃置的黑桃牌点数差值不大于1，则对一名其他角色造成2点雷电伤害。",
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
  ["#os__zhouhu_conjure"] = "咒护",
  ["@os__zuhuo"] = "阻祸",
  ["#os__zuhuo_conjure"] = "阻祸",
  ["@os__zuhuo_defense"] = "阻祸防伤",
  ["@os__fengqi"] = "丰祈",
  ["#os__fengqi-ask"] = "丰祈：你可弃置一张黑色手牌并施法：摸2X张牌",
  ["#os__fengqi-conjure"] = "丰祈：施法：摸2X张牌",
  ["#os__fengqi_conjure"] = "丰祈",
  ["#os__guimen-target"] = "鬼门：对一名其他角色造成2点雷电伤害",
  ["@os__zhouzu"] = "咒诅",
  ["#os__zhouzu_conjure"] = "咒诅",
  ["#os__didao-ask"] = "地道：你可打出一张牌替换 %src 的判定，若与原判定牌颜色相同，你摸一张牌",
}]]

local os__hucheer = General(extension, "os__hucheer", "qun", 4)

local os__shenxing = fk.CreateDistanceSkill{
  name = "os__shenxing",
  correct_func = function(self, from, to)
    if from:hasSkill(self.name) and from:getEquipment(Card.SubtypeOffensiveRide) == nil and from:getEquipment(Card.SubtypeDefensiveRide) == nil then
      return -1
    end
  end,
}
local os__shenxing_maxcard = fk.CreateMaxCardsSkill{
  name = "#os__shenxing_maxcard",
  correct_func = function(self, player)
    if player:hasSkill(self.name) and player:getEquipment(Card.SubtypeOffensiveRide) == nil and player:getEquipment(Card.SubtypeDefensiveRide) == nil then
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
}

Fk:loadTranslationTable{
  ["os__yangyi"] = "杨仪",
  ["os__duoduan"] = "度断",
  [":os__duoduan"] = "每回合限一次，当你成为【杀】的目标后，你可重铸一张牌，然后你令此【杀】的使用者执行一项：1.摸两张牌然后此【杀】无效；2.弃一张牌令此【杀】不可被响应。",
  ["os__gongsun"] = "共损",
  [":os__gongsun"] = "锁定技，出牌阶段开始时，你选择攻击范围内的一名其他角色并选择一种花色，直至你的下个回合开始前或你死亡时，你与其均无法使用、打出或弃置该花色的手牌。",
}

return extension