local extension = Package("overseas_strategizing")
extension.extensionName = "overseas"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["overseas_strategizing"] = "国际服-运筹帷幄",
}

local os__wangcan = General(extension, "os__wangcan", "wei", 3)

local os__dianyi = fk.CreateTriggerSkill{
  name = "os__dianyi",
  anim_type = "negative",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if #room.logic:getActualDamageEvents(1, function(e)
      return e.data[1].from == target
    end, Player.HistoryTurn) > 0 then
      room:notifySkillInvoked(player, self.name)
      player:throwAllCards("h")
    else
      local num = 4 - player:getHandcardNum()
      if num > 0 then
        room:notifySkillInvoked(player, self.name, "drawcard")
        player:drawCards(num, self.name)
      elseif num < 0 then
        room:notifySkillInvoked(player, self.name)
        num = -num
        player.room:askForDiscard(player, num, num, false, self.name, false)
      end
    end
  end,
}

local os__yingji = fk.CreateViewAsSkill{
  name = "os__yingji",
  card_filter = Util.FalseFunc,
  card_num = 0,
  pattern = ".|.|.|.|.|basic,trick",
  interaction = function(self)
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(allCardNames, card.name) and (card.type == Card.TypeBasic or card:isCommonTrick()) and not card.is_derived and ((Fk.currentResponsePattern == nil and Self:canUse(card)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) and not Self:prohibitUse(card) then
        table.insert(allCardNames, card.name)
      end
    end
    return UI.ComboBox { choices = allCardNames }
  end,
  view_as = function(self, player, cards)
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
    return player.phase == Player.NotActive and player:isKongcheng()
  end,
  enabled_at_response = function(self, player)
    return player.phase == Player.NotActive and player:isKongcheng()
  end,
}

local os__shanghe = fk.CreateTriggerSkill{
  name = "os__shanghe",
  anim_type = "support",
  events = {fk.EnterDying},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local not_include = true
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:isNude() then
        local id = room:askForCard(p, 1, 1, true, self.name, false)[1]
        if not_include and Fk:getCardById(id).trueName == "analeptic" then
          not_include = false
        end
        room:moveCardTo(id, Player.Hand, player, fk.ReasonGive, self.name, nil, false)
      end
    end

    if not_include and not player.dead and player.hp < 1 then
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

  ["$os__dianyi1"] = "旧仪废弛，兴造制度。",
  ["$os__dianyi2"] = "礼仪卒度，笑语卒获。",
  ["$os__yingji1"] = "辩适于世，论合于时。",
  ["$os__yingji2"] = "辩言出于口，不失思忖心。",
  ["$os__shanghe1"] = "今使海内回心，望风而愿治，皆明公之功也。",
  ["$os__shanghe2"] = "明公平定兵乱，使百姓可安，粲当奉觞以贺之。",
  ["~os__wangcan"] = "虽无铅刀用，庶几奋薄身。",
}

local os__dongzhao = General(extension, "os__dongzhao", "wei", 3)
local os__miaolue = fk.CreateTriggerSkill{
  name = "os__miaolue",
  events = {fk.GameStart, fk.Damaged},
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    return event == fk.GameStart or (target == player and not player.dead)
  end,
  on_trigger = function(self, event, target, player, data)
    if event == fk.Damaged then
      self.cancel_cost = false
      for i = 1, data.damage do
        if self.cancel_cost then break end
        self:doCost(event, target, player, data)
      end
    else
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    else
      local choice = player.room:askForChoice(player, {"os__miaolue_underhanding", "os__miaolue_zhinang", "Cancel"}, self.name)
      if choice ~= "Cancel" then
        self.cost_data = choice
        return true
      end
      self.cancel_cost = true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local miaolue_derivecards = { {"underhanding", Card.Spade, 5}, {"underhanding", Card.Club, 5},
      {"underhanding", Card.Heart, 5}, {"underhanding", Card.Diamond, 5} }
    if event == fk.GameStart then
      local cids = table.filter(U.prepareDeriveCards(room, miaolue_derivecards, "os__miaolue_derivecards"), function (id)
        return room:getCardArea(id) == Card.Void
      end)
      if #cids > 0 then
        room:obtainCard(player, table.random(cids, 2), false, fk.ReasonPrey, player.id, self.name, MarkEnum.DestructIntoDiscard)
      end
    else
      if self.cost_data == "os__miaolue_underhanding" then
        local id
        local cids = U.prepareDeriveCards(room, miaolue_derivecards, "os__miaolue_derivecards")
        for _, cid in ipairs(cids) do
          if room:getCardArea(cid) == Card.Void then --优先拿游戏外的
            id = cid
            break
          end
        end
        if not id then
          for _, cid in ipairs(cids) do
            if room:getCardArea(cid) == Card.DrawPile then --再拿牌堆里的
              id = cid
              break
            end
          end
        end
        if id then
          room:obtainCard(player, id, false, fk.ReasonPrey, player.id, self.name, MarkEnum.DestructIntoDiscard)
        end
        player:drawCards(1, self.name)
      else
        local choice = room:askForChoice(player, {"dismantlement", "nullification", "ex_nihilo"}, self.name, "#os__miaolue-ask")
        local id = room:getCardsFromPileByRule(choice, 1, "allPiles")
        if #id > 0 then
          room:obtainCard(player, id[1], false, fk.ReasonPrey)
        end
      end
    end
  end,
}
local os__yingjia = fk.CreateTriggerSkill{
  name = "os__yingjia",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e)
      local use = e.data[1]
      return use.from == player.id and use.card.type == Card.TypeTrick
    end, Player.HistoryTurn)
    if #events > 0 then
      local usedCardNames = {}
      table.forEach(events, function(e)
        table.insertIfNeed(usedCardNames, e.data[1].card.name)
      end)
      return #events > #usedCardNames
    end
  end,
  on_cost = function(self, event, target, player, data)
    local plist, cid = player.room:askForChooseCardAndPlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, 1, ".|.|.|hand", "#os__yingjia-target", self.name, true) --但是没判断可不可以弃置
    if #plist > 0 then
      self.cost_data = {plist[1], cid}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = self.cost_data[1]
    room:throwCard(self.cost_data[2], self.name, player)
    room:getPlayerById(to):gainAnExtraTurn()
  end
}
os__dongzhao:addSkill(os__miaolue)
os__dongzhao:addSkill(os__yingjia)

Fk:loadTranslationTable{
  ["os__dongzhao"] = "董昭",
  ["os__miaolue"] = "妙略",
  [":os__miaolue"] = "游戏开始时，你获得两张<a href='underhanding_href'>【瞒天过海】</a>；当你受到1点伤害后，你可选择：" ..
  "1. 获得一张<a href='underhanding_href'>【瞒天过海】</a>并摸一张牌；2. 从牌堆或弃牌堆获得一张你指定的<a href='bag_of_tricks'>智囊</a>。",
  ["os__yingjia"] = "迎驾",
  [":os__yingjia"] = "一名角色的回合结束时，若你于此回合内使用过至少两张同名锦囊牌，你可弃置一张手牌并选择一名角色，其获得一个额外的回合。",

  ["bag_of_tricks"] = "#\"<b>智囊</b>\" ：即【过河拆桥】【无懈可击】【无中生有】。",
  ["underhanding_href"]  = "【<b>瞒天过海</b>】（<font color='#C04040'>♥</font>5/<font color='#C04040'>♦</font>5/♠5/♣5） 锦囊牌 <br/>" ..
  "出牌阶段，对一至两名区域内有牌的其他角色使用。你依次获得目标角色区域内的一张牌，然后依次交给目标角色一张牌。<br/>【瞒天过海】不计入你的手牌上限。",

  ["os__miaolue_underhanding"] = "获得一张【瞒天过海】并摸一张牌",
  ["os__miaolue_zhinang"] = "从牌堆或弃牌堆获得一张你指定的智囊",
  ["#os__miaolue-ask"] = "妙略：选择一种“智囊”，从牌堆或弃牌堆获得一张",
  ["#os__yingjia-target"] = "迎驾：你可弃置一张手牌并选择一名角色，其获得一个额外的回合",

  ["$os__miaolue1"] = "智者通权达变，以解临近之难。",
  ["$os__miaolue2"] = "依吾计而行，此患乃除耳。",
  ["$os__yingjia1"] = "行非常之事，乃有非常之功，愿将军三思。",
  ["$os__yingjia2"] = "将军今留匡弼，事势不便，惟移驾幸许耳。",
  ["~os__dongzhao"] = "为曹公助书方略，实昭之幸也……",
}

local os__feiyi = General(extension, "os__feiyi", "shu", 3)

local os__shengxi = fk.CreateTriggerSkill{
  name = "os__shengxi",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player == target and player:hasSkill(self) then
      if player.phase == Player.Start then return true end
      if player.phase == Player.Finish then
        return #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          return e.data[1].from == player.id
        end, Player.HistoryTurn) > 0 and
        #player.room.logic:getActualDamageEvents(1, function(e) return e.data[1].from == player end) == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.phase == Player.Start then
      return player.room:askForSkillInvoke(player, self.name, data)
    else
      local choice = player.room:askForChoice(player, {"dismantlement", "nullification", "ex_nihilo", "Cancel"}, self.name, "#os__shengxi-ask")
      if choice ~= "Cancel" then
        self.cost_data = choice
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      local get = nil
      local shengxi_derivecards = { {"redistribute", Card.Spade, 6}, {"redistribute", Card.Club, 6}, {"redistribute", Card.Heart, 6}, {"redistribute", Card.Diamond, 6} }
      local cards = table.filter(U.prepareDeriveCards(room, shengxi_derivecards, "shengxi_derivecards"), function (id)
        return room:getCardArea(id) == Card.Void
      end)
      if #cards > 0 then
        get = table.random(cards)
      else
        local cids = room:getCardsFromPileByRule("redistribute")
        if #cids > 0 then get = cids[1] end
      end
      if get then
        room:obtainCard(player, get, true, fk.ReasonPrey, player.id, self.name, MarkEnum.DestructIntoDiscard)
      end
    else
      local id = room:getCardsFromPileByRule(self.cost_data)
      if #id > 0 then
        room:obtainCard(player, id[1], false, fk.ReasonPrey, player.id, self.name)
      end
      if not player.dead then player:drawCards(1, self.name) end
    end
  end,
}

local os__kuanji = fk.CreateTriggerSkill{
  name = "os__kuanji",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player:usedSkillTimes(self.name) > 0 then return false end
    for _, move in ipairs(data) do
      if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
        return table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    target = room:askForChoosePlayers(
      player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1, "#os__kuanji-ask", self.name, true)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target = self.cost_data
    local cards = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
        table.forEach(move.moveInfo, function(info)
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insert(cards, info.cardId)
          end
        end)
      end
    end
    --[[local cids = room:askForCardsChosen(player, player, 0, #cards, {
      card_data = {
        { "pile_discard", cards }
      }
    }, self.name, "#os__kuanji-cards::" .. target)]]
    local cids
    local choice = "os__kuanji_all"
    if #cards > 1 then
      cids, choice = U.askforChooseCardsAndChoice(player, cards, {"os__kuanji_selected"}, self.name,
      "#os__kuanji-cards::" .. target, {"os__kuanji_all"}, 1, #cards)
    end
    if choice == "os__kuanji_all" then
      cids = cards
    end
    if #cids > 0 then
      room:obtainCard(target, cids, true, fk.ReasonJustMove, player.id)
    end
  end,
}

os__feiyi:addSkill(os__shengxi)
os__feiyi:addSkill(os__kuanji)

Fk:loadTranslationTable{
  ["os__feiyi"] = "费祎",
  ["#os__feiyi"] = "蜀汉名相",
  ["designer:os__feiyi"] = "Loun老萌",
  ["illustrator:os__feiyi"] = "凝聚永恒",
  ["os__shengxi"] = "生息",
  [":os__shengxi"] = "①准备阶段开始时，你可获得一张<a href='redistribute_href'>【调剂盐梅】</a>。②结束阶段开始时，若你于此回合内使用过牌且没有造成过伤害，你可从牌堆中获得一张你指定的<a href='bag_of_tricks'>智囊</a>并摸一张牌。",
  ["os__kuanji"] = "宽济",
  [":os__kuanji"] = "每回合限一次，当你的牌非因使用而置入弃牌堆后，你可令一名其他角色获得其中的任意张牌。",

  ["redistribute_href"] = "【<b>调剂盐梅</b>】（<font color='#C04040'>♥</font>6/<font color='#C04040'>♦</font>6/♠6/♣6） 锦囊牌<br/>" ..
  "出牌阶段，对两名手牌数不同的角色使用。若所有目标角色的手牌数不均相同，为这些角色中手牌数最小的目标角色摸一张牌，不为的弃置一张手牌。然后若所有目标角色手牌数相同，你可将以此法弃置的牌交给一名角色。<br/>重铸：出牌阶段，你可将此牌置入弃牌堆，然后摸一张牌。",

  ["#os__shengxi-ask"] = "生息：你可选择一种智囊，从牌堆中获得之并摸一张牌",
  ["#os__kuanji-ask"] = "宽济：你可令一名其他角色获得其中的任意张牌",
  ["#os__kuanji-cards"] = "宽济：令 %dest 获得其中任意张牌",
  ["os__kuanji_all"] = "令其获得全部",
  ["os__kuanji_selected"] = "令其获得选择的牌",

  ["$os__shengxi1"] = "利治小之宜，秉居静之理。",
  ["$os__shengxi2"] = "外却骆谷之师，内保宁缉之实。",
  ["$os__kuanji1"] = "功以才成，业由才广，弃才不用，非长计也。",
  ["$os__kuanji2"] = "舍此不任而防后患，是备风波而废舟楫也。",
  ["~os__feiyi"] = "臣请告陛下，宦权日盛，必乱社稷也。",
}

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
      if not table.contains(allCardNames, card.trueName) and (card.type == Card.TypeBasic or card:isCommonTrick()) and not card.is_derived then
        table.insert(allCardNames, card.trueName)
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
    local id = room:getCardsFromPileByRule(name)
    if #id > 0 then
      room:obtainCard(target, id[1], false, fk.ReasonPrey)
    end
  end,
}

local os__chayi = fk.CreateTriggerSkill{
  name = "os__chayi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    target = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1, "#os__chayi-ask", self.name, true)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target = room:getPlayerById(self.cost_data)
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

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("_os__chayi") > 0
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
  on_cost = Util.TrueFunc,
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
  ["#os__chenzhen"] = "歃盟使节",
  ["illustrator:os__chenzhen"] = "君桓文化",
  ["designer:os__chenzhen"] = "Loun老萌",

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

  ["$os__muyue1"] = "歃血盟誓，以告神明。",
  ["$os__chayi1"] = "戮力一心，同讨魏贼。",
  ["~os__chenzhen"] = "震不负丞相所托……",
}

local os__xunchen = General(extension, "os__xunchen", "qun", 3)

local os__weipo = fk.CreateActiveSkill{
  name = "os__weipo",
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  card_num = 0,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  target_num = 1,
  interaction = UI.ComboBox{choices = {"enemy_at_the_gates", "dismantlement", "nullification", "ex_nihilo"} },
  on_use = function(self, room, effect)
    local choice = self.interaction.data
    if not choice then choice = "enemy_at_the_gates" end
    local target = room:getPlayerById(effect.tos[1])
    room:askForDiscard(target, 1, 1, true, self.name, false, nil)
    local id
    if choice == "enemy_at_the_gates" then
      local weipo_derivecards = { {"enemy_at_the_gates", Card.Spade, 7}, {"enemy_at_the_gates", Card.Club, 7},
      {"enemy_at_the_gates", Card.Club, 13} }
      local cids = U.prepareDeriveCards(room, weipo_derivecards, "os__weipo_derivecards")
      for _, cid in ipairs(cids) do
        if room:getCardArea(cid) == Card.Void then
          id = cid
          break
        end
      end
      if not id then
        for _, cid in ipairs(cids) do
          if room:getCardArea(cid) == Card.DrawPile then
            id = cid
            break
          end
        end
      end
    else
      for _, cid in ipairs(Fk:getAllCardIds()) do --在这里
        if Fk:getCardById(cid).name == choice and room:getCardArea(cid) == Card.Void then --优先拿游戏外的
          id = cid
          break
        end
      end
      if not id then
        local cids = room:getCardsFromPileByRule(choice, 1) --？
        if #cids > 0 then id = cids[1] end
      end
    end
    if id then
      room:obtainCard(target, id, false, fk.ReasonPrey, effect.from, self.name, choice == "enemy_at_the_gates" and MarkEnum.DestructIntoDiscard or nil )
    end
  end,
}

local os__chenshi = fk.CreateTriggerSkill{
  name = "os__chenshi",
  anim_type = "control",
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.name == "enemy_at_the_gates" and player ~= target
  end,
  on_cost = function(self, event, target, player, data)
    local id = player.room:askForCard(target, 1, 1, true, self.name, true, nil, event == fk.TargetSpecified and "#os__chenshi-give1:" .. player.id or "#os__chenshi-give2:" .. player.id)
    if #id > 0 then
      self.cost_data = id[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(self.cost_data, Player.Hand, player, fk.ReasonGive, self.name, nil, false)
    local cids = {}
    for i = 1, math.min(3, #room.draw_pile), 1 do
      table.insert(cids, room.draw_pile[i])
    end
    local throw = {}
    for i, id in ipairs(cids) do
      if (event == fk.TargetSpecified and Fk:getCardById(id).trueName ~= "slash") or (event == fk.TargetConfirmed and Fk:getCardById(id).trueName == "slash") then
        table.insert(throw, id)
      end
    end
    if #throw > 0 then
      room:moveCards({
        ids = throw,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
      })
    end
    room:delay(1000)
  end,
}

local os__moushi = fk.CreateTriggerSkill{
  name = "os__moushi",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and data.card and data.card.color == player:getMark("_os__moushi")
  end,
  on_use = Util.TrueFunc,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(self, true) and data.card and data.card.color ~= Card.NoColor
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "_os__moushi", data.card.color)
    if player:hasSkill(self, true) then room:setPlayerMark(player, "@os__moushi", data.card:getColorString()) end
  end,
}

os__xunchen:addSkill(os__weipo)
os__xunchen:addSkill(os__chenshi)
os__xunchen:addSkill(os__moushi)

Fk:loadTranslationTable{
  ["os__xunchen"] = "荀谌",
  ["#os__xunchen"] = "谋刃略锋",
  ["illustrator:os__xunchen"] = "君桓文化",
  ["designer:os__xunchen"] = "Loun老萌",

  ["os__weipo"] = "危迫",
  [":os__weipo"] = "出牌阶段限一次，你可令一名角色弃置一张牌，然后令其获得一张<a href='enemy_at_the_gates_href'>【兵临城下】</a>或由你指定的一种<a href='bag_of_tricks'>智囊</a>。",
  ["os__chenshi"] = "陈势",
  [":os__chenshi"] = "当其他角色使用<a href='enemy_at_the_gates_href'>【兵临城下】</a>指定目标后，可交给你一张牌，然后将牌堆顶三张牌中不为【杀】的牌置入弃牌堆；" ..
  "当其他角色成为<a href='enemy_at_the_gates_href'>【兵临城下】</a>的目标后，可交给你一张牌，然后将牌堆顶三张牌中的【杀】置入弃牌堆。",
  ["os__moushi"] = "谋识",
  [":os__moushi"] = "锁定技，当你受到伤害时，若造成伤害的牌与上次对你造成伤害的牌颜色相同，则你防止此伤害。",

  ["enemy_at_the_gates_href"] = "【<b>兵临城下</b>】（♠7/♣7/♣K） 锦囊牌<br/>出牌阶段，对一名其他角色使用。你依次展示牌堆顶四张牌，若为【杀】，你对目标使用之；若不为【杀】，将此牌置入弃牌堆。",

  ["#os__chenshi-give1"] = "陈势：你可交给 %src 一张牌，将牌堆顶三张牌中不为【杀】的牌置入弃牌堆",
  ["#os__chenshi-give2"] = "陈势：你可交给 %src 一张牌，将牌堆顶三张牌中的【杀】置入弃牌堆",
  ["@os__moushi"] = "谋识",

  ["$os__weipo1"] = "想必……将军心中已有所计较。",
  ["$os__weipo2"] = "谌言尽于此，采纳与否还凭将军。",
  ["$os__chenshi1"] = "将军已为此二者所围，形势实不容乐观。",
  ["$os__chenshi2"] = "此二人若合力攻之，则将军危矣。",
  ["$os__moushi1"] = "潜谋于无形，胜于不争不费。",
  ["$os__moushi2"] = "欲思其成，必虑其败也。",
  ["~os__xunchen"] = "袁公不济，吾自当以死继之……",
}

local os__wangling = General(extension, "os__wangling", "wei", 4)

local os__mibei = fk.CreateTriggerSkill{
  name = "os__mibei",
  frequency = Skill.Quest,
  refresh_events = {fk.AfterCardUseDeclared, fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getQuestSkillState(self.name) ~= "succeed" and (event == fk.AfterCardUseDeclared or (player.phase == Player.Play and player:getMark("_os__mibei_use-turn") == 0)) --and player:getMark("@@os__mibei_done") == 0 
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      local typesRecorded = player:getMark("@os__mibei") ~= 0 and string.split(player:getMark("@os__mibei"), "-") or {0, 0, 0}
      typesRecorded[data.card.type] = tonumber(typesRecorded[data.card.type]) + 1
      room:setPlayerMark(player, "@os__mibei", table.concat(typesRecorded, "-"))
      if tonumber(typesRecorded[1]) > 1 and tonumber(typesRecorded[2]) > 1 and tonumber(typesRecorded[3]) > 1 then
        room:updateQuestSkillState(player, self.name, true) -- 为了有那个白底……
        room:updateQuestSkillState(player, self.name, false)
        room:handleAddLoseSkills(player, "os__mouli", nil)
        room:setPlayerMark(player, "@os__mibei", 0)
      end
      room:addPlayerMark(player, "_os__mibei_use-turn")
    else
      room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 1)
      room:setPlayerMark(player, "@os__mibei", "0-0-0")
      room:updateQuestSkillState(player, self.name, true)
    end
  end,
}

local os__xingqi = fk.CreateTriggerSkill{
  name = "os__xingqi",
  events = {fk.EventPhaseStart},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local num = 0
    for _, p in ipairs(player.room.alive_players) do
      num = num + #p:getCardIds({Player.Equip, Player.Judge})
    end
    return num > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name,
    })
    if player:getQuestSkillState("os__mibei") ~= "succeed" then
      local cards = {}
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|basic"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|trick"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|equip"))
      room:obtainCard(player, cards, false, fk.ReasonPrey)
    else
      room:setPlayerMark(player, "@@os__xingqi_nodistance", 1)
    end
  end,
}
local os__xingqi_nodistance = fk.CreateTargetModSkill{
  name = "#os__xingqi_nodistance",
  bypass_distances = function(self, player, skill)
    return player:getMark("@@os__xingqi_nodistance") > 0
  end,
}
os__xingqi:addRelatedSkill(os__xingqi_nodistance)

local os__mouli = fk.CreateViewAsSkill{
  name = "os__mouli",
  card_filter = Util.FalseFunc,
  card_num = 0,
  pattern = ".|.|.|.|.|basic",
  interaction = function(self)
    local allCardNames, cardNames = {}, {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      local name = card.name
      if not table.contains(allCardNames, name) and card.type == Card.TypeBasic and not card.is_derived then
        table.insert(allCardNames, name)
        local card = Fk:cloneCard(name)
        if not Self:prohibitUse(card) and ((Fk.currentResponsePattern == nil and Self:canUse(card)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
          table.insert(cardNames, name)
        end
      end
    end
    return UI.ComboBox { choices = cardNames , all_choices = allCardNames }
  end,
  view_as = function(self)
    local choice = self.interaction.data
    if not choice then return end
    local c = Fk:cloneCard(choice)
    c.skillName = self.name
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  enabled_at_response = function(self, player, cardResponsing)
    return player:usedSkillTimes(self.name) == 0 and not cardResponsing
  end,
  before_use = function(self, player, use)
    local cids = player.room:getCardsFromPileByRule(".|.|.|.|" .. use.card.name)
    if #cids > 0 then
      use.card:addSubcards(cids)
    else
      player.room:doBroadcastNotify("ShowToast", Fk:translate("os__mouliFailed"))
      return self.name
    end
  end,
}

os__wangling:addSkill(os__mibei)
os__wangling:addSkill(os__xingqi)
os__wangling:addRelatedSkill(os__mouli)

Fk:loadTranslationTable{
  ["os__wangling"] = "王凌",
  ["os__mibei"] = "秘备",
  [":os__mibei"] = "<a href='os__quest'>使命技</a>，使用每种类别的牌各至少两张。成功：你获得〖谋立〗。完成前：出牌阶段结束时，若你本回合未使用过牌，则你此回合手牌上限-1并重置〖秘备〗。" .. 
  "<br/><font color='grey'>◆<b>重置〖秘备〗</b>，即清空〖秘备〗所记录的所使用过的牌的类别和数量。",
  ["os__xingqi"] = "星启",
  [":os__xingqi"] = "觉醒技，准备阶段开始时，若场上的牌数大于你的体力值，则你回复1点体力，然后若〖秘备〗未完成，你从牌堆中获得每种类别的牌各一张；若〖秘备〗已完成，本局游戏你使用牌无距离限制。",
  ["os__mouli"] = "谋立",
  [":os__mouli"] = "每回合限一次，当你需要使用基本牌时，你可使用牌堆中（系统选择）的基本牌。",

  ["os__quest"] = "#\"<b>使命技(国际服)</b>\"：在成功后失效，完成前有一定的惩罚。",

  ["@os__mibei"] = "秘备",
  ["@@os__xingqi_nodistance"] = "星启无距离限制",
  ["os__mouliFailed"] = "谋立失败，牌堆中没有该基本牌",

  ["$os__mibei1"] = "密为之备，不可有失。",
  ["$os__mibei2"] = "事以密成，语以泄败！",
  ["$os__xingqi1"] = "司马氏虽权尊势重，吾等徐图亦无不可！",
  ["$os__xingqi2"] = "先谋后事者昌，先事后谋者亡！",
  ["$os__mouli1"] = "僣孽为害，吾岂可谋而不行？",
  ["$os__mouli2"] = "澄汰王室，迎立宗子。",
  ["~os__wangling"] = "一生尽忠事魏，不料，今日晚节尽毁啊！",
}

local os__huojun = General(extension, "os__huojun", "shu", 4)

local os__sidai = fk.CreateViewAsSkill{
  name = "os__sidai",
  anim_type = "offensive",
  --pattern = "slash",
  frequency = Skill.Limited,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
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
    use.extraUse = true
    use.extra_data = use.extra_data or {}
    use.extra_data.os__sidaiBuff = included_basic_cards
    use.card.extra_data = use.card.extra_data or {} --闪用的是这里……
    use.card.extra_data.os__sidaiBuff = included_basic_cards
  end,
  enabled_at_play = function(self, player) --权宜
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and not table.every(player.player_cards[Player.Hand], function(cid)
      return Fk:getCardById(cid).type ~= Card.TypeBasic
    end)
  end,
  enabled_at_response = Util.FalseFunc,
}
local os__sidai_tm = fk.CreateTargetModSkill{
  name = "#os__sidai_tm",
  bypass_times = function (self, player, skill, scope, card, to)
    return (player:hasSkill(os__sidai) and card and table.contains(card.skillNames, os__sidai.name))
  end,
  bypass_distances = function (self, player, skill, card, to)
    return (player:hasSkill(os__sidai) and card and table.contains(card.skillNames, os__sidai.name))
  end
}

local os__sidai_buff = fk.CreateTriggerSkill{
  name = "#os__sidai_buff",
  mute = true,
  refresh_events = {fk.DamageCaused, fk.Damage, fk.TargetConfirmed},
  can_refresh = function(self, event, target, player, data)
    if target ~= player or not data.card or not table.contains(data.card.skillNames, os__sidai.name) then return false end
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
    if target ~= player or not player:hasSkill(self) or player:usedSkillTimes(self.name, Player.HistoryRound) > 0 or player:isKongcheng() then return false end
    if event == fk.EventPhaseStart then
      return player.phase == Player.Finish
    else
      local events = player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function(e) 
        return e.data[1].to == player
      end, Player.HistoryRound)
      return #events == 1 and events[1].id == player.room.logic:getCurrentEvent().id
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
    local cards = {}
    table.forEach(allCardNames, function(name)
      table.insert(cards, room:getCardsFromPileByRule(name, 1, "discardPile"))
    end)
    room:obtainCard(player, cards, false, fk.ReasonPrey)
  end,
}

os__huojun:addSkill(os__sidai)
os__huojun:addSkill(os__jieyu)

Fk:loadTranslationTable{
  ["os__huojun"] = "霍峻",
  ["#os__huojun"] = "葭萌铁狮",
  ["illustrator:os__huojun"] = "枭瞳",
  ["designer:os__huojun"] = "步穗",

  ["os__sidai"] = "伺怠",
  [":os__sidai"] = "限定技，出牌阶段，你可将所有基本牌当【杀】使用（无次数和距离限制、不计入使用次数）。若这些牌中有：【酒】，此【杀】造成伤害时，伤害翻倍；【桃】，此【杀】造成伤害后，受到伤害角色减1点体力上限；【闪】，此【杀】的目标需弃置一张基本牌，否则不能响应。",
  ["os__jieyu"] = "竭御",
  [":os__jieyu"] = "每轮限一次，结束阶段开始时或每轮第一次受到伤害后，你可弃置所有手牌，然后从弃牌堆中获得不同牌名的基本牌各一张。",

  ["#os__sidai_buff"] = "伺怠",
  ["#os__sidai_nojink"] = "伺怠：弃置一张基本牌，否则不能响应此【杀】",

  ["$os__sidai1"] = "敌军疲乏，正是战机，随我杀！",
  ["$os__sidai2"] = "敌军无备，随我冲锋！",
  ["$os__jieyu1"] = "葭萌，蜀之咽喉，峻必竭力守之。",
  ["$os__jieyu2"] = "吾头可得，城不可得。",
  ["~os__huojun"] = "恨，不能与使君共成霸业……",
}

local function isHandOrHpBiggest(player, room)
  local num = player.hp
  if table.every(room.alive_players, function(p) return p.hp <= num end) then
    return true
  end
  num = player:getHandcardNum()
  if table.every(room.alive_players, function(p) return p:getHandcardNum() <= num end) then
    return true
  end
  return false
end

local os__zhouchu = General(extension, "os__zhouchu", "wu", 4)

local os__guoyi = fk.CreateTriggerSkill{
  name = "os__guoyi",
  events = {fk.TargetSpecified},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card:isCommonTrick())
    and data.to ~= player.id and #AimGroup:getAllTargets(data.tos) == 1 then
      return (player:getHandcardNum() <= player:getLostHp() + 1) or isHandOrHpBiggest(player.room:getPlayerById(data.to), player.room)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#os__guoyi-ask::" .. data.to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = player:getLostHp() + 1
    target = room:getPlayerById(data.to)
    local ret = isHandOrHpBiggest(target, room) and player:getHandcardNum() <= player:getLostHp() + 1
    local all_choices = {"os__guoyi_prohibit", "os__guoyi_discard:::" .. num}
    local choices = table.clone(all_choices)
    if target:isNude() then table.remove(choices) end
    local mark = target:getTableMark("_os__guoyi-turn")
    if table.contains(mark, 1) then table.remove(choices, 1) end
    if #choices > 0 then
      local choice = table.indexOf(all_choices, room:askForChoice(target, choices, self.name, "os__guoyi-ask:" .. player.id, false, all_choices))
      table.insertIfNeed(mark, choice)
      room:setPlayerMark(target, "_os__guoyi-turn", mark)
      if choice == 1 then
        room:addPlayerMark(target, "@@os__guoyi_prohibit-turn")
      else
        room:askForDiscard(target, num, num, true, self.name, false)
      end
    end
    if ret or #mark == 2 then
      data.additionalEffect = 1
    end
  end,
}
local os__guoyi_prohibit = fk.CreateProhibitSkill{
  name = "#os__guoyi_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@@os__guoyi_prohibit-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player.player_cards[Player.Hand], id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@@os__guoyi_prohibit-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player.player_cards[Player.Hand], id)
      end)
    end
  end,
}
os__guoyi:addRelatedSkill(os__guoyi_prohibit)

local os__chuhai = fk.CreateTriggerSkill{
  name = "os__chuhai",
  frequency = Skill.Quest,
  mute = true,
  events = {fk.TurnEnd, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TurnEnd then
      return player:getQuestSkillState(self.name) == "succeed" and player:getMark("@os__chuhai") >= 2
    elseif player:hasSkill(self) and player:getQuestSkillState(self.name) ~= "succeed" then
      for _, move in ipairs(data) do
        if move.to == player.id and move.moveReason == fk.ReasonGive then
          return true
        end
      end
      return false
    end
  end,
  on_trigger = function(self, event, target, player, data)
    if event == fk.TurnEnd then
      self:doCost(event, target, player, data)
    else
      for _, move in ipairs(data) do
        if move.to == player.id and move.moveReason == fk.ReasonGive then
          self:doCost(event, target, player, move)
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnEnd then
      room:notifySkillInvoked(player, self.name, "control")
      player:broadcastSkillInvoke(self.name, math.random(3, 4))
      room:abortPlayerArea(player, {Player.JudgeSlot})
      local targets = room:getOtherPlayers(player)
      local prompt = "#os__chuhai-ask:" .. player.id
      for _, p in ipairs(targets) do
        if player.dead then return end
        if not p.dead and not p:isNude() then
          local card = room:askForCard(p, 1, 1, true, self.name, false, nil, prompt)
          if #card > 0 then
            room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, false, player.id)
          end
        end
      end
      room:setPlayerMark(player, "@os__chuhai", 0)
    else
      room:notifySkillInvoked(player, self.name, "negative")
      player:broadcastSkillInvoke(self.name, 5)
      room:updateQuestSkillState(player, self.name, true)
      local cards = table.filter(table.map(data, function(info) return info.cardId end), function(id) return room:getCardArea(id) == Card.PlayerHand end)
      if #cards > 0 then
        local c = room:askForCard(player, 1, 1, true, self.name, false, ".|.|.|.|.|.|" .. table.concat(cards, ","), "#os__chuhai-discard")
        room:moveCardTo(c, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
      end
    end
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and data.damage and data.damage.from == player and
      player:getQuestSkillState(self.name) ~= "succeed" and target ~= player and not table.contains(player:getTableMark("_os__chuhai"), target.id)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "offensive")
    player:broadcastSkillInvoke(self.name, math.random(2))
    room:addTableMark(player, "_os__chuhai", target.id)
    room:addPlayerMark(player, "@os__chuhai")
    if player:getMark("@os__chuhai") > 1 then
      room:updateQuestSkillState(player, self.name, true) -- ……
      room:updateQuestSkillState(player, self.name, false)
    end
  end,
}

os__zhouchu:addSkill(os__guoyi)
os__zhouchu:addSkill(os__chuhai)

Fk:loadTranslationTable{
  ["os__zhouchu"] = "周处",
  ["#os__zhouchu"] = "英情天逸",
  ["illustrator:os__zhouchu"] = "MUMU",
  ["designer:os__zhouchu"] = "梦魇狂朝",
  ["os__guoyi"] = "果毅",
  [":os__guoyi"] = "当你使用【杀】或普通锦囊牌指定仅一名其他角色为目标后，若其体力值或手牌数为全场最高，" ..
  "或你的手牌数不大于X（X为你已损失体力值+1），你可令其选择一项：1. 本回合不能使用或打出手牌；2. 弃置X张牌。" ..
  "若条件均满足，或其本回合两个选项均已选择，则此牌结算两次。",
  ["os__chuhai"] = "除害",
  [":os__chuhai"] = "<a href='os__quest'>使命技</a>，令两名其他角色进入濒死状态。成功：当前回合结束时，废除你的判定区，"..
  "然后每名其他角色依次交给你一张牌。完成前：其他角色交给你牌后，你将其中一张置入弃牌堆。",

  ["#os__guoyi-ask"] = "果毅：是否对 %dest 发动“果毅”？",
  ["os__guoyi_prohibit"] = "本回合不能使用或打出手牌",
  ["os__guoyi_discard"] = "弃置%arg张牌",
  ["os__guoyi-ask"] = "果毅：%src 对你发动“果毅”，请选择一项",
  ["@@os__guoyi_prohibit-turn"] = "果毅封牌",
  ["@os__chuhai"] = "除害",
  ["#os__chuhai-ask"] = "除害：交给 %src 一张牌",
  ["#os__chuhai-discard"] = "除害：将一张交给你的牌置入弃牌堆",

  ["$os__guoyi1"] = "心怀远志，何愁声名不彰！",
  ["$os__guoyi2"] = "从今始学，成为有用之才！",
  ["$os__chuhai1"] = "快快闪开，伤到你们可就不好了，哈哈哈！", -- 令其他角色进入濒死
  ["$os__chuhai2"] = "你自己撞上来的，这可怪不得小爷我！",
  ["$os__chuhai3"] = "小小孽畜，还不伏诛？", -- 成功
  ["$os__chuhai4"] = "有我在此，安敢为害！",
  ["$os__chuhai5"] = "此番不成，明日再战！", -- 完成前
  ["~os__zhouchu"] = "改励自砥，誓除三害……",
}

local os__wujing = General(extension, "os__wujing", "wu", 4)

local os__fenghan = fk.CreateTriggerSkill{
  name = "os__fenghan",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return 
      target == player and
      player:hasSkill(self) and
      data.firstTarget and player:usedSkillTimes(self.name) < 1 and data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local num = #AimGroup:getAllTargets(data.tos)
    local result = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, num, "#os__fenghan-ask:::" .. num, self.name, true)
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
    if player.phase == Player.NotActive and player:hasSkill(self) then
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
    target = room:askForChoosePlayers(
      player,
      table.map(room:getOtherPlayers(player, false), Util.IdMapper),
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
    local room = player.room
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
    room:moveCardTo(cids, Player.Hand, room:getPlayerById(self.cost_data), fk.ReasonGive, self.name, nil, false)
  end,
}

os__wujing:addSkill(os__fenghan)
os__wujing:addSkill(os__congji)

Fk:loadTranslationTable{
  ["os__wujing"] = "吴景",
  ["designer:os__wujing"] = "韩旭",
  ["os__fenghan"] = "锋悍",
  [":os__fenghan"] = "每回合限一次，当你使用【杀】或伤害锦囊牌指定第一个目标后，你可令至多X名角色摸一张牌（X为目标数）。",
  ["os__congji"] = "从击",
  [":os__congji"] = "当你于回合外弃置牌后，你可将其中的所有红色牌交给一名其他角色。",

  ["#os__fenghan-ask"] = "锋悍：你可令至多 %arg 名角色各摸一张牌",
  ["#os__congji-ask"] = "从击：你可将弃置的牌中所有的红色牌交给一名其他角色",

  ["~os__wujing"] = "贼寇未除，奈何……吾身先丧……",
}

local os__xujing = General(extension, "os__xujing", "shu", 3)

local os__boming = fk.CreateActiveSkill{
  name = "os__boming",
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.TrueFunc,
  card_num = 1,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    room:moveCardTo(effect.cards, Player.Hand, room:getPlayerById(effect.tos[1]), fk.ReasonGive, self.name, nil, false)
  end,
}
local os__boming_draw = fk.CreateTriggerSkill{
  name = "#os__boming_draw",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and player:getMark("_os__boming_card-turn") > 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player.phase == Player.NotActive then return false end
    for _, move in ipairs(data) do
      local target = move.to and player.room:getPlayerById(move.to) or nil
      if target and move.to ~= player.id and move.toArea == Card.PlayerHand then
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local num = 0
    for _, move in ipairs(data) do
      local target = move.to and player.room:getPlayerById(move.to) or nil
      if target and move.to ~= player.id and move.toArea == Card.PlayerHand then
        num = num + #move.moveInfo
      end
    end
    player.room:addPlayerMark(player, "_os__boming_card-turn", num)
  end,
}
os__boming:addRelatedSkill(os__boming_draw)

local os__ejian = fk.CreateTriggerSkill{
  name = "os__ejian",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    for _, move in ipairs(data) do
      local target = move.to and player.room:getPlayerById(move.to) or nil
      local from = move.from and player.room:getPlayerById(move.from) or nil
      if from and from == player and target and move.to ~= player.id and move.toArea == Card.PlayerHand then
        local cardType = {}
        local fromCard = {}
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            local id = info.cardId
            table.insertIfNeed(cardType, Fk:getCardById(id):getTypeString())
            table.insert(fromCard, id)
          end
        end
        local cids = target:getCardIds{Player.Hand, Player.Equip}
        for _, id in ipairs(cids) do
          if table.contains(cardType, Fk:getCardById(id):getTypeString()) and not table.contains(fromCard, id) then
            return true
          end
        end
      end
    end
    return false
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, move in ipairs(data) do
      local target = move.to and player.room:getPlayerById(move.to) or nil
      local from = move.from and player.room:getPlayerById(move.from) or nil
      if from and from == player and target and move.to ~= player.id and move.toArea == Card.PlayerHand then
        local cardType = {}
        local fromCard = {}
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            local id = info.cardId
            table.insertIfNeed(cardType, Fk:getCardById(id):getTypeString())
            table.insert(fromCard, id)
          end
        end
        local cids = target:getCardIds{Player.Hand, Player.Equip}
        for _, id in ipairs(cids) do
          if table.contains(cardType, Fk:getCardById(id):getTypeString()) and not table.contains(fromCard, id) then
            table.insertIfNeed(targets, move.to)
            break
          end
        end
      end
    end
    room:sortPlayersByAction(targets)
    for _, target_id in ipairs(targets) do
      if not player:hasSkill(self) then break end
      local skill_target = room:getPlayerById(target_id)
      if skill_target and not skill_target.dead then
        self:doCost(event, skill_target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#os__ejian-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local cards = {}
    for _, move in ipairs(data) do
      local to = move.to and player.room:getPlayerById(move.to) or nil
      local from = move.from and player.room:getPlayerById(move.from) or nil
      if from and from == player and from:hasSkill(self) and to == target and move.toArea == Card.PlayerHand then
        local cardType = {}
        local fromCard = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          table.insertIfNeed(cardType, Fk:getCardById(id):getTypeString())
          table.insert(fromCard, id)
        end
        local cids = target:getCardIds{Player.Hand, Player.Equip}
        for _, id in ipairs(cids) do
          if table.contains(cardType, Fk:getCardById(id):getTypeString()) and not table.contains(fromCard, id) then
            table.insert(cards, id)
          end
        end
        if #cards > 0 then
          break
        end
      end
    end
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
  ["#os__xujing"] = "篡贤取良",
  ["illustrator:os__xujing"] = "凝聚永恒",

  ["os__boming"] = "博名",
  [":os__boming"] = "出牌阶段限两次，你可以将一张牌交给一名其他角色。结束阶段开始时，若其他角色于此回合内获得的牌数大于1，你摸两张牌。",
  ["os__ejian"] = "恶荐",
  [":os__ejian"] = "当其他角色获得你的牌后，若其有除此牌以外的牌与此牌类别相同的牌，你可令其选择：1. 弃置这些牌；2. 受到你造成的1点伤害。",

  ["#os__boming_draw"] = "博名",
  ["#os__ejian-invoke"] = "你想对 %dest 发动技能“恶荐”吗？",
  ["os__ejian_discard"] = "弃置除获得的牌外和获得的牌类别相同的牌",
  ["os__ejian_damage"] = "受到1点伤害",

  ["$os__boming1"] = "先载附从，吾后行即可。",
  ["$os__boming2"] = "诸位速速上船，靖随后便至。",
  ["$os__ejian1"] = "为政者当沙汰秽浊，显拔幽滞，以顺民心。",
  ["$os__ejian2"] = "此所谓寡助之至，天下叛之矣。",
  ["~os__xujing"] = "恨，不能与使君共成霸业……",
}

Fk:loadTranslationTable{
  ["os__qiaogong"] = "桥公",
  ["os__weizhu"] = "遗珠",
  [":os__weizhu"] = "结束阶段，你摸两张牌，然后选择两张牌，称为“遗珠”，随机洗入牌堆顶前2X张牌中（X场上角色数)，并记录；其他角色使用“遗珠”牌指定唯一目标后，你可以修改或增加一个目标，然后你将此牌从“遗珠”记录中移除并摸一张牌。",
  ["os__luanchou"] = "鸾俦",
  [":os__luanchou"] = "出牌阶段限一次，你可以选择两名角色视为拥有〖共患〗直到你下次发动此技能。",
  ["os__gonghuan"] = "共患",
  [":os__gonghuan"] = "每回合限一次，当体力值不大于你且有〖共患〗的角色受到伤害时，你可以将此伤害转移给自己。",
}

local os__zongyu = General(extension, "os__zongyu", "shu", 3)

local os__zhibian = fk.CreateTriggerSkill{
  name = "os__zhibian",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Play and not player:isKongcheng() and table.find(player.room:getOtherPlayers(player, false), function(p)
      return player:canPindian(p) end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local availableTargets = table.map(
      table.filter(room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end),
      Util.IdMapper
    )
    if #availableTargets == 0 then return false end
    local target = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__zhibian-ask", self.name, true)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(self.cost_data)
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      local choiceList = {}
      if not target:isAllNude() then table.insert(choiceList, "os__zhibian_extract:::" .. target.general) end
      if player:isWounded() then table.insert(choiceList, "recover") end
      if table.find(player:getCardIds({Player.Hand, Player.Equip}), function(id) return Fk:getCardById(id).type ~= Card.TypeBasic end) then
        table.insert(choiceList, "beishui_os__zhibian")
      end
      table.insert(choiceList, "Cancel")
      local choice = room:askForChoice(player, choiceList, self.name)
      if choice == "Cancel" then return false end
      if choice == "beishui_os__zhibian" then
        room:askForDiscard(player, 1, 1, true, self.name, false, ".|.|.|.|.|^basic")
      end
      if choice ~= "recover" and not target:isAllNude() then
        choiceList = {"os__zhibian_get:::" .. target.general}
        if target:canMoveCardsInBoardTo(player, nil) then table.insert(choiceList, 1, "os__zhibian_move:::" .. target.general) end
        if room:askForChoice(player, choiceList, self.name):startsWith("os__zhibian_move") then
          room:askForMoveCardInBoard(player, target, player, self.name, nil, target)
        else
          local cid = room:askForCardChosen(player, target, "hej", self.name)
          room:moveCardTo(cid, Player.Hand, player, fk.ReasonJustMove, self.name, nil, false)
        end
      end
      if choice == "recover" or choice == "beishui_os__zhibian" then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        })
      end
    else
      room:loseHp(player, 1, self.name)
    end
  end,
}

local os__yuyan = fk.CreateTriggerSkill{
  name = "os__yuyan",
  events = {fk.TargetConfirming},
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and player.room:getPlayerById(data.from).hp > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pattern
    local prompt
    if data.card.number < 1 then 
      pattern = ".|.|.|.|.|^basic"
      prompt = "#os__yuyan-card1:" .. player.id
    else
      pattern = ".|" .. data.card.number + 1  .. "~K"
      prompt = "#os__yuyan-card2:" .. player.id .. "::" .. data.card.number
    end
    local c = room:askForCard(room:getPlayerById(data.from), 1, 1, true, self.name, true, pattern, prompt)
    if #c > 0 then
      room:moveCardTo(c[1], Player.Hand, player, fk.ReasonGive, self.name, nil, false)
    else
      AimGroup:cancelTarget(data, data.to)
    end
  end,
}

os__zongyu:addSkill(os__zhibian)
os__zongyu:addSkill(os__yuyan)

Fk:loadTranslationTable{
  ["os__zongyu"] = "宗预",
  ["#os__zongyu"] = "御严无惧",
  ["illustrator:os__zongyu"] = "凝聚永恒",

  ["os__zhibian"] = "直辩",
  [":os__zhibian"] = "出牌阶段开始时，你可与一名角色拼点，若你赢，则你可选择一项：1. 将其场上的一张牌移动到你的对应区域，或将其区域内的一张牌置于你的手牌中；2. 回复1点体力；背水：弃置一张非基本牌；若你没赢，你失去1点体力。",
  ["os__yuyan"] = "御严",
  [":os__yuyan"] = "锁定技，当你成为体力值大于你的角色【杀】的目标时，其须交给你一张点数大于此【杀】点数的牌（若此【杀】无点数则改为非基本牌），否则取消此目标。",

  ["#os__zhibian-ask"] = "直辩：你可与一名角色拼点",
  ["os__zhibian_extract"] = "将%arg场上的一张牌移动到你的对应区域，或将其区域内的一张牌置于你的手牌中",
  ["beishui_os__zhibian"] = "背水：弃置一张非基本牌",
  ["os__zhibian_move"] = "将%arg场上的一张牌移动到你的对应区域",
  ["os__zhibian_get"] = "将%arg区域内的一张牌置于你的手牌中",
  ["#os__yuyan-card1"] = "御严：交给 %src 一张非基本牌，否则取消此目标",
  ["#os__yuyan-card2"] = "御严：交给 %src 一张点数大于 %arg 的牌，否则取消此目标",

  ["$os__zhibian1"] = "两国各增守将，皆事势宜然，何足相问。",
  ["$os__zhibian2"] = "固边大计，乃立国之本，岂有不设之理。",
  ["$os__yuyan1"] = "正直敢言，不惧圣怒。",
  ["$os__yuyan2"] = "威武不能屈，方为大丈夫。",
  ["~os__zongyu"] = "恨，不能与使君共成霸业……",
}

local os__chenwudongxi = General(extension, "os__chenwudongxi", "wu", 4)
local os__yilie = fk.CreateTriggerSkill{
  name = "os__yilie",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"os__yilie_times", "os__yilie_draw", "beishui_os__yilie" ,"Cancel"}
    local choice = player.room:askForChoice(player, choices, self.name)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data
    if choice == "beishui_os__yilie" then
      room:setPlayerMark(player, "@os__yilie-phase", "yl_times_draw")
      room:loseHp(player, 1, self.name)
    elseif choice == "os__yilie_times" then
      room:setPlayerMark(player, "@os__yilie-phase", "yl_times")
    elseif choice == "os__yilie_draw" then
      room:setPlayerMark(player, "@os__yilie-phase", "yl_draw")
    end
  end,
}
local os__yilie_do = fk.CreateTriggerSkill{
  name = "#os__yilie_do",
  anim_type = "drawcard",
  events = {fk.CardEffectCancelledOut, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardEffectCancelledOut then
      return target == player and player:getMark("@os__yilie-phase") ~= 0 and string.find(player:getMark("@os__yilie-phase"), "draw") and data.card.trueName == "slash"
    else
      if target == player and player:hasSkill(self) and
      data.card.trueName == "slash" and
      player:getMark("@os__yilie-phase") ~= 0 and string.find(player:getMark("@os__yilie-phase"), "draw") and data.to then
        local to = player.room:getPlayerById(data.to)
        return to.chained
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local os__yilieBuff = fk.CreateTargetModSkill{
  name = "#os__yilieBuff",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return (player:getMark("@os__yilie-phase") ~= 0 and string.find(player:getMark("@os__yilie-phase"), "times")) and 1 or 0
    end
  end,
}
os__yilie:addRelatedSkill(os__yilieBuff)
os__yilie:addRelatedSkill(os__yilie_do)

local os__fenming = fk.CreateTriggerSkill{
  name = "os__fenming",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and
      player.phase == Player.Start and not table.every(player.room.alive_players, function(p)
        return (p:isNude() and p.chained)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#os__fenming-ask", self.name, true)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target = room:getPlayerById(self.cost_data)
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

os__chenwudongxi:addSkill(os__yilie)
os__chenwudongxi:addSkill(os__fenming)

Fk:loadTranslationTable{
  ["os__chenwudongxi"] = "陈武董袭",
  ["#os__chenwudongxi"] = "殒身不惧",
  ["illustrator:os__chenwudongxi"] = "彭宇",

  ["os__yilie"] = "毅烈",
  [":os__yilie"] = "出牌阶段开始时，你可选择此阶段内：1.使用【杀】的次数上限+1；2.当你使用的【杀】指定处于连环状态的角色为目标后，或被【闪】抵消后，摸一张牌；背水：你失去1点体力。",
  ["os__fenming"] = "奋命",
  [":os__fenming"] = "准备阶段开始时，你可选择一名角色并选择一项：1.你弃置其一张牌；2. 其进入连环状态；背水：你进入连环状态。",

  ["os__yilie_times"] = "使用【杀】的次数上限+1",
  ["os__yilie_draw"] = "当你使用的【杀】指定处于连环状态的角色为目标后，或被【闪】抵消后，摸一张牌",
  ["@os__yilie-phase"] = "毅烈",
  ["yl_times_draw"] = "摸牌 多出杀",
  ["yl_times"] = "多出杀",
  ["yl_draw"] = "摸牌",
  ["#os__yilie_do"] = "毅烈",
  ["beishui_os__yilie"] = "背水：你失去1点体力",
  ["#os__fenming-ask"] = "你可对一名角色发动〖奋命〗",
  ["beishui_os__fenming"] = "背水：你进入连环状态",
  ["os__fenming_discard"] = "你弃置其牌",
  ["os__fenming_chained"] = "其进入连环状态",

  ["$os__yilie1"] = "区区绳索，就想挡住吾等去路？！",
  ["$os__yilie2"] = "以身索敌，何惧同伤！",
  ["$os__fenming1"] = "东吴男儿，岂是贪生怕死之辈。",
  ["$os__fenming2"] = "不惜性命，也要保主公周全。",
  ["~os__chenwudongxi"] = "杀身为主，死而无憾。",
}

local os__jiangqin = General(extension, "os__jiangqin", "wu", 4)

local os__shangyi = fk.CreateActiveSkill{
  name = "os__shangyi",
  prompt = "#os__shangyi-active",
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and not Self:prohibitDiscard(to_select)
  end,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id and #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    if not player:isKongcheng() then
      U.viewCards(target, player:getCardIds(Player.Hand), self.name, "#os__shangyi_view:" .. player.id)
    end
    local choiceList = {"os__shangyi_discard"}
    if not player:isKongcheng() then table.insert(choiceList, "os__shangyi_exchange") end
    local cards, choice = U.askforChooseCardsAndChoice(player, target:getCardIds(Player.Hand), choiceList, self.name, "#os__shangyi-ask::" .. target.id)
    local card = Fk:getCardById(cards[1])
    if choice == "os__shangyi_discard" then
      room:throwCard(cards, self.name, target, player)
      if card.color == Card.Black and not player.dead then player:drawCards(1, self.name) end
    else
      local cids = room:askForCard(player, 1, 1, false, self.name, false, nil, "#os__shangyi-exchange:" .. target.id .. "::" .. card:toLogString())
      U.swapCards(room, player, player, target, cids, {card.id}, self.name)
      if card.color == Card.Red and Fk:getCardById(cids[1]).color == Card.Red and not player.dead then player:drawCards(1, self.name) end
    end
  end,
}

local os__xiangyu = fk.CreateTriggerSkill{
  name = "os__xiangyu",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and player:distanceTo(player.room:getPlayerById(data.to)) < player:getAttackRange()
  end,
  on_use = function(self, event, target, player, data)
    data.fixedResponseTimes = data.fixedResponseTimes or {}
    data.fixedResponseTimes["jink"] = 2
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player.phase == Player.NotActive then return false end
    local room = player.room
    for _, move in ipairs(data) do
      if move.from and room:getPlayerById(move.from):getMark("_os__xiangyu-turn") == 0 and
        table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end) then
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local target = {}
    for _, move in ipairs(data) do
      if move.from and room:getPlayerById(move.from):getMark("_os__xiangyu-turn") == 0 and
        table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end) then
        table.insertIfNeed(target, move.from)
      end
    end
    table.forEach(target, function(pid)
      room:addPlayerMark(room:getPlayerById(pid), "_os__xiangyu-turn")
    end)
    local num = math.min(5, player:getMark("_os__xiangyu_num-turn") + #target)
    room:setPlayerMark(player, "_os__xiangyu_num-turn", num)
    if player:hasSkill(self, true) then room:setPlayerMark(player, "@os__xiangyu-turn", num) end
  end,
}
local os__xiangyuAR = fk.CreateAttackRangeSkill{
  name = "#os__xiangyuAR",
  correct_func = function(self, from, to)
    return from:hasSkill(self) and from:getMark("_os__xiangyu_num-turn") or 0
  end,
}
os__xiangyu:addRelatedSkill(os__xiangyuAR)

os__jiangqin:addSkill(os__shangyi)
os__jiangqin:addSkill(os__xiangyu)

Fk:loadTranslationTable{
  ["os__jiangqin"] = "蒋钦",
  ["#os__jiangqin"] = "折节尚义",
  ["illustrator:os__jiangqin"] = "铁杵文化",

  ["os__shangyi"] = "尚义",
  [":os__shangyi"] = "出牌阶段限一次，你可弃置一张牌并令一名有手牌的其他角色观看你的手牌，然后你观看其手牌并选择一项：1. 弃置其中一张牌；2. 与其交换一张手牌。若弃置的为黑色牌或交换的两张均为红色牌，则你摸一张牌。",
  ["os__xiangyu"] = "翔羽",
  [":os__xiangyu"] = "锁定技，①你的回合内，每有一名角色失去过牌，本回合你的攻击范围便+1（至多+5）。②你使用【杀】指定一名角色为目标时，若你与其距离小于你的攻击范围，则其需依次使用两张【闪】才能抵消此【杀】。",

  ["os__shangyi_discard"] = "弃置此牌",
  ["os__shangyi_exchange"] = "与其交换此牌",
  ["#os__shangyi-exchange"] = "尚义：选择一张手牌，与 %src 交换其%arg",
  ["#os__shangyi_view"] = "尚义：观看 %src 的手牌",
  ["#os__shangyi-ask"] = "尚义：观看 %dest 的手牌，选择一张牌并选择一项",
  ["#os__shangyi-active"] = "发动 尚义，弃置一张牌，与一名有手牌的其他角色互相观看手牌",
  ["@os__xiangyu-turn"] = "翔羽",

  ["$os__shangyi1"] = "国士，当以义为先！",
  ["$os__shangyi2"] = "豪侠尚义，何拘俗礼！",
  ["$os__xiangyu1"] = "此战必是有死无生！",
  ["$os__xiangyu2"] = "抢占先机，占尽优势！",
  ["~os__jiangqin"] = "奋敌护主，成吾忠名……",
}

local sunyi = General(extension, "os__sunyi", "wu", 4)
local zaoli = fk.CreateTriggerSkill{
  name = "os__zaoli",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local subTypes = {}
    local cards = table.filter(player:getCardIds("he"), function (id)
      return Fk:getCardById(id).type == Card.TypeEquip
    end)
    for _, id in ipairs(cards) do
      local card = Fk:getCardById(id)
      table.insertIfNeed(subTypes, card:getSubtypeString())
    end
    table.insertTable(cards, room:askForDiscard(player, 1, 9999, false, self.name, true, ".|.|.|.|.|^equip", "#os__zaoli-discard", true))
    room:throwCard(cards, self.name, player, player)
    player:drawCards(#cards, self.name)
    if player.dead then return end
    local cids = {}
    for _, subType in ipairs(subTypes) do
      local equips = room:getCardsFromPileByRule(".|.|.|.|.|" .. subType)
      if #equips > 0 and player:canMoveCardIntoEquip(equips[1], false) then
        table.insert(cids, equips[1])
      end
    end
    if #cids > 0 then
      room:moveCardIntoEquip(player, cids, self.name, false, player)
      if #cids > 2 and not player.dead then
        room:loseHp(player, 1, self.name)
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(self, true) or player.phase == Player.NotActive or player:isKongcheng() then return false end
    if event == fk.AfterCardsMove then
      local room = player.room
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand then
          return true
        end
      end
    else
      return target == player and data == self
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local record_data = {}
    if event == fk.AfterCardsMove then
      record_data = {data}
    else
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        table.insert(record_data, e.data)
      end, Player.HistoryTurn)
    end
    local handcards = player.player_cards[Player.Hand]
    local to_mark = {}
    for _, _data in ipairs(record_data) do
      for _, move in ipairs(_data) do
        if move.to == player.id and move.toArea == Player.Hand then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(handcards, info.cardId) then
              table.insertIfNeed(to_mark, info.cardId)
            end
          end
        end
      end
    end
    for _, cid in ipairs(to_mark) do
      room:setCardMark(Fk:getCardById(cid), "@@os__zaoli-turn-inhand", 1)
    end
  end,
}
local zaoli_prohibit = fk.CreateProhibitSkill{
  name = "#os__zaoli_prohibit",
  prohibit_use = function(self, from, card)
    if from:hasSkill(zaoli) and from.phase == Player.Play then
      local cardIds = Card:getIdList(card)
      return table.find(cardIds, function(id)
        return Fk:getCardById(id):getMark("@@os__zaoli-turn-inhand") == 0 and table.contains(from.player_cards[Player.Hand], id)
      end)
    end
  end,
  prohibit_response = function(self, from, card)
    if from:hasSkill(zaoli) and from.phase == Player.Play then
      local cardIds = Card:getIdList(card)
      return table.find(cardIds, function(id)
        return Fk:getCardById(id):getMark("@@os__zaoli-turn-inhand") == 0 and table.contains(from.player_cards[Player.Hand], id)
      end)
    end
  end,
}
zaoli:addRelatedSkill(zaoli_prohibit)
sunyi:addSkill(zaoli)

Fk:loadTranslationTable{
  ["os__sunyi"] = "孙翊",
  ["#os__sunyi"] = "骁悍激躁",
  ["illustrator:os__sunyi"] = "凡果",

  ["os__zaoli"] = "躁厉",
  [":os__zaoli"] = "锁定技，出牌阶段，你只能使用或打出本回合获得的手牌。出牌阶段开始时，你弃置你所有装备牌和任意张非装备牌，然后摸X张牌，并从牌堆中将你弃置牌中相同子类别的装备牌置入装备区，若你以此法置入装备区的牌数大于2，你失去1点体力。（X为你以此法弃置的牌的总数）",

  ["@@os__zaoli-turn-inhand"] = "躁厉",
  ["#os__zaoli-discard"] = "躁厉：选择任意张手牌，你须弃置这些牌和所有装备牌，摸等量张牌",

  ["$os__zaoli1"] = "喜怒不形于色，诈伪要明之徒。",
  ["$os__zaoli2"] = "摇舌鼓唇，竖子是之也！",
  ["~os__sunyi"] = "叛我贼子，虽死亦不饶之……",
}

return extension
