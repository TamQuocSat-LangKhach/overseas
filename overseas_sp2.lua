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

return extension