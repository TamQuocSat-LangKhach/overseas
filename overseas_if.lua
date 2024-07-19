local extension = Package("overseas_if")
extension.extensionName = "overseas"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["overseas_if"] = "国际服-IF篇",
  ["os_if"] = "国际幻",
}

local ifzhugeliang = General(extension, "os_if__zhugeliang", "shu", 3, 4)
local ifzhugeliangwin = fk.CreateActiveSkill{ name = "os_if__zhugeliang_win_audio" }
ifzhugeliangwin.package = extension
Fk:addSkill(ifzhugeliangwin)
Fk:loadTranslationTable{
  ["os_if__zhugeliang"] = "幻诸葛亮",
  ["#os_if__zhugeliang"] = "天意可叹",
  ["$os_if__zhugeliang_win_audio"] = "卧龙腾于九天，炎汉之火长明。",
  ["~os_if__zhugeliang"] = "先帝遗志未竟，吾怎可终于半途。",
}

local osBeiding = fk.CreateTriggerSkill{
  name = "os__beiding",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return target.phase == Player.Start and player:hasSkill(self) and player.hp > 0
  end,
  on_cost = function (self, event, target, player, data)
    local cardNames = U.getAllCardNames("bt")
    cardNames = table.filter(
      cardNames,
      function(name) return not table.contains(U.getMark(player, "@$os__beiding_names"), name) end
    )

    local realNameMapper = {}
    for _, cardName in ipairs(cardNames) do
      local realNames = table.filter(cardNames, function(name) return name:endsWith("__" .. cardName) end)
      if #realNames > 0 then
        realNameMapper[cardName] = realNames
      end
    end
    cardNames = table.filter(cardNames, function(name) return #name:split("__") == 1 end)

    if #cardNames == 0 then
      return false
    end

    local room = player.room
    local namesChosen = room:askForChoices(player, cardNames, 1, player.hp, self.name, "#os__beiding-choose:::" .. player.hp)
    if #namesChosen == 0 then
      return false
    end

    for _, cardName in ipairs(namesChosen) do
      local realNames = realNameMapper[cardName]
      if realNames then
        table.insert(realNames, 1, cardName)
        local name = room:askForChoice(player, realNames, self.name, "#os__beiding-replace:::" .. cardName)
        local index = table.indexOf(namesChosen, cardName)
        table.remove(namesChosen, index)
        table.insert(namesChosen, index, name)
      end
    end

    self.cost_data = namesChosen
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local namesChosen = self.cost_data

    local namesChosenThisTurn = U.getMark(player, "os__beiding_names-turn")
    table.insert(namesChosenThisTurn, namesChosen)
    room:setPlayerMark(player, "os__beiding_names-turn", namesChosen)

    namesChosen = table.map(namesChosen, function(name)
      local realName = name:split("__")
      return realName[#realName]
    end)
    local beidingNames = U.getMark(player, "@$os__beiding_names")
    table.insertTable(beidingNames, namesChosen)
    room:setPlayerMark(player, "@$os__beiding_names", beidingNames)

    if player:hasSkill("os_huan__beiding", true) then
      for _, id in ipairs(player:getCardIds("h")) do
        local card = Fk:getCardById(id)
        if table.contains(beidingNames, card.trueName) and card:getMark("@@os__beiding_card-inhand") ~= 1 then
          room:setCardMark(card, "@@os__beiding_card-inhand", 1)
        end
      end
    end
  end
}
local osBeidingUse = fk.CreateTriggerSkill{
  name = "#os__beiding_use",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function (self, event, target, player, data)
    return target.phase == Player.Discard and player:getMark("os__beiding_names-turn") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local namesChosenThisTurn = U.getMark(player, "os__beiding_names-turn")
    for _, name in ipairs(namesChosenThisTurn) do
      if not player:isAlive() then
        break
      end

      local use = U.askForUseVirtualCard(room, player, name, nil, self.name, "#os__beiding-use:::" .. name, false, true, true)
      if use and not table.contains(TargetGroup:getRealTargets(use.tos), target.id) then
        target:drawCards(1, self.name)
      end
    end
  end
}
Fk:loadTranslationTable{
  ["os__beiding"] = "北定",
  [":os__beiding"] = "一名角色的准备阶段开始时，你可以声明并记录至多X种未被“北定”记录过的基本牌或普通锦囊牌牌名。" .. 
  "若如此做，此回合的弃牌阶段结束时，你视为依次使用本回合记录的牌（无距离限制），若此牌的目标不包含当前回合角色，" ..
  "其摸一张牌（X为你的体力值）。",
  ["#os__beiding_use"] = "北定",
  ["@$os__beiding_names"] = "北定",
  ["#os__beiding-choose"] = "北定：请选择至多%arg种牌名记录，你于此回合弃牌阶段结束时按顺序依次使用",
  ["#os__beiding-replace"] = "北定：请为牌名【%arg】替换具体牌名",
  ["#os__beiding-use"] = "北定：请视为使用【%arg】",

  ["$os__beiding1"] = "众将同心扶汉，北伐或可功成。",
  ["$os__beiding2"] = "虽失天时地利，亦有三分胜机！",
}

osBeiding:addRelatedSkill(osBeidingUse)
ifzhugeliang:addSkill(osBeiding)

local osJielv = fk.CreateTriggerSkill{
  name = "os__jielv",
  anim_type = "support",
  events = {fk.TurnEnd, fk.Damaged, fk.HpLost},
  frequency = Skill.Compulsory,
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(self) then
      return false
    end

    if event == fk.TurnEnd then
      return
        #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data[1]
          return use.from == player.id and table.contains(TargetGroup:getRealTargets(use.tos), target.id)
        end, Player.HistoryTurn) == 0
    end

    return target == player and player.maxHp < 7
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.TurnEnd then
      room:loseHp(player, 1, self.name)
    else
      room:changeMaxHp(player, math.min(event == fk.Damaged and data.damage or data.num, 7 - player.maxHp))
    end
  end
}
Fk:loadTranslationTable{
  ["os__jielv"] = "竭虑",
  [":os__jielv"] = "锁定技，一名角色的回合结束时，若你于本回合内未对其使用过牌，则你失去1点体力；当你受到1点伤害或失去1点体力后，" ..
  "若你的体力上限小于7，则你加1点体力上限。",

  ["$os__jielv1"] = "竭一国之材，尽万人之力！",
  ["$os__jielv2"] = "穷力尽心，亮定以血补天！",
}

ifzhugeliang:addSkill(osJielv)

local osHunyou = fk.CreateTriggerSkill{
  name = "os__hunyou",
  anim_type = "defensive",
  events = {fk.AskForPeaches},
  frequency = Skill.Limited,
  can_trigger = function (self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      player.hp < 1 and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player.hp < 1 then
      room:recover{
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = self.name,
      }
    end

    room:setPlayerMark(player, "@@os__hunyou_prevent-turn", 1)
  end
}
local osHunyouBuff = fk.CreateTriggerSkill{
  name = "#os__hunyou_buff",
  anim_type = "defensive",
  events = {fk.DamageInflicted, fk.PreHpLost, fk.TurnEnd},
  can_trigger = function (self, event, target, player, data)
    return player:getMark("@@os__hunyou_prevent-turn") > 0 and (event == fk.TurnEnd or target == player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.TurnEnd then
      room:changeHero(
        player,
        "os_if_huan__zhugeliang",
        false,
        player.deputyGeneral == "os_if__zhugeliang",
        false,
        false
      )
      player:gainAnExtraTurn(true)
    else
      return true
    end
  end
}
Fk:loadTranslationTable{
  ["os__hunyou"] = "魂游",
  [":os__hunyou"] = "限定技，当你处于濒死状态时，你可以将体力回复至1点，本回合防止你受到的伤害和体力流失。" ..
  "此回合结束时，你入幻并获得一个额外的回合。",
  ["#os__hunyou_buff"] = "魂游",
  ["@@os__hunyou_prevent-turn"] = "魂游",

  ["$os__hunyou1"] = "扶汉兴刘，夙夜沥血，忽入草堂梦中。",
  ["$os__hunyou2"] = "一整河山，以明己志，昔日言犹记否？",
}

osHunyou:addRelatedSkill(osHunyouBuff)
ifzhugeliang:addSkill(osHunyou)

local huanzhugeliang = General(extension, "os_if_huan__zhugeliang", "shu", 3, 4)
huanzhugeliang.hidden = true
local huanzhugeliangwin = fk.CreateActiveSkill{ name = "os_if_huan__zhugeliang_win_audio" }
huanzhugeliangwin.package = extension
Fk:addSkill(huanzhugeliangwin)
Fk:loadTranslationTable{
  ["os_if_huan"] = "入幻",
  ["os_if_huan__zhugeliang"] = "幻诸葛亮",
  ["#os_if_huan__zhugeliang"] = "天意可叹",
  ["$os_if_huan__zhugeliang_win_audio"] = "卧龙腾于九天，炎汉之火长明。",
  ["~os_if_huan__zhugeliang"] = "一人之愿，终难逆天命……",
}

local osHuanBeiding = fk.CreateTriggerSkill{
  name = "os_huan__beiding",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function (self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      table.contains(U.getMark(player, "@$os__beiding_names"), data.card.trueName)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, self.name)
    local beidingNames = U.getMark(player, "@$os__beiding_names")
    table.removeOne(beidingNames, data.card.trueName)
    if #beidingNames == 0 then
      beidingNames = 0
    end

    local room = player.room
    room:setPlayerMark(player, "@$os__beiding_names", beidingNames)
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if card.trueName == data.card.trueName and card:getMark("@@os__beiding_card-inhand") == 1 then
        room:setCardMark(card, "@@os__beiding_card-inhand", 0)
      end
    end
  end,

  refresh_events = {fk.PreCardUse, fk.AfterCardsMove, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function (self, event, target, player, data)
    if event == fk.PreCardUse then
      return
        target == player and
        player:hasSkill(self) and
        table.contains(U.getMark(player, "@$os__beiding_names"), data.card.trueName)
    elseif event == fk.AfterCardsMove then
      return table.find(data, function(move)
        if move.to == player.id and move.toArea == Card.PlayerHand then
          return
            table.find(
              move.moveInfo,
              function(moveInfo)
                return table.contains(U.getMark(player, "@$os__beiding_names"), Fk:getCardById(moveInfo.cardId).trueName)
              end
            )
        end
      end)
    end

    return target == player and data == self
  end,
  on_refresh = function (self, event, target, player, data)
    if event == fk.PreCardUse then
      data.extraUse = true
    elseif event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand then
          for _, moveInfo in ipairs(move.moveInfo) do
            local card = Fk:getCardById(moveInfo.cardId)
            if table.contains(U.getMark(player, "@$os__beiding_names"), card.trueName) then
              player.room:setCardMark(card, "@@os__beiding_card-inhand", 1)
            end
          end
        end
      end
    elseif event == fk.EventAcquireSkill then
      for _, id in ipairs(player:getCardIds("h")) do
        local card = Fk:getCardById(id)
        if table.contains(U.getMark(player, "@$os__beiding_names"), card.trueName) then
          player.room:setCardMark(card, "@@os__beiding_card-inhand", 1)
        end
      end
    else
      for _, id in ipairs(player:getCardIds("h")) do
        local card = Fk:getCardById(id)
        if card:getMark("@@os__beiding_card-inhand") ~= 0 then
          player.room:setCardMark(card, "@@os__beiding_card-inhand", 0)
        end
      end
    end
  end,
}
local osHuanBeidingBuff = fk.CreateTargetModSkill{
  name = "#os_huan__beiding_buff",
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(osHuanBeiding) and card:getMark("@@os__beiding_card-inhand") == 1
  end,
}
Fk:loadTranslationTable{
  ["os_huan__beiding"] = "北定",
  [":os_huan__beiding"] = "你使用“北定”记录的牌无距离限制且不计入次数；当你使用“北定”记录牌名的牌结算结束后，" ..
  "你摸一张牌，然后移除“北定”记录中的此牌名。",
  ["@@os__beiding_card-inhand"] = "北定",

  ["$os_huan__beiding1"] = "内外不懈如斯，长安不日可下！",
  ["$os_huan__beiding2"] = "先帝英灵冥鉴，此番定成夙愿！",
}

osHuanBeiding:addRelatedSkill(osHuanBeidingBuff)
huanzhugeliang:addSkill(osHuanBeiding)

local osHuanJielv = fk.CreateTriggerSkill{
  name = "os_huan__jielv",
  anim_type = "defensive",
  events = {fk.MaxHpChanged},
  frequency = Skill.Compulsory,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.num < 0 and player:isWounded()
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:recover{
      who = player,
      num = -data.num,
      recoverBy = player,
      skillName = self.name,
    }
  end
}
Fk:loadTranslationTable{
  ["os_huan__jielv"] = "竭虑",
  [":os_huan__jielv"] = "锁定技，当你减少1点体力上限后，你回复1点体力。",

  ["$os_huan__jielv1"] = "出箕谷，饮河洛，所至长安！",
  ["$os_huan__jielv2"] = "破司马，废伪政，誓还帝都！",
}

huanzhugeliang:addSkill(osHuanJielv)

local osHuanji = fk.CreateActiveSkill{
  name = "os__huanji",
  prompt = "#os__huanji-active",
  anim_type = "support",
  target_num = 0,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    room:changeMaxHp(from, -1)
    if not from:isAlive() or from.hp < 1 then
      return
    end

    local cardNames = U.getAllCardNames("bt")
    cardNames = table.filter(
      cardNames,
      function(name) return not table.contains(U.getMark(from, "@$os__beiding_names"), name) end
    )

    if #cardNames == 0 then
      return false
    end
    cardNames = table.filter(cardNames, function(name) return #name:split("__") == 1 end)

    local namesChosen = room:askForChoices(from, cardNames, from.hp, from.hp, self.name, "#os__beiding-choose:::" .. from.hp, false)
    local beidingNames = U.getMark(from, "@$os__beiding_names")
    table.insertTable(beidingNames, namesChosen)
    room:setPlayerMark(from, "@$os__beiding_names", beidingNames)

    for _, id in ipairs(from:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if table.contains(beidingNames, card.trueName) and card:getMark("@@os__beiding_card-inhand") ~= 1 then
        room:setCardMark(card, "@@os__beiding_card-inhand", 1)
      end
    end
  end
}
Fk:loadTranslationTable{
  ["os__huanji"] = "幻计",
  [":os__huanji"] = "出牌阶段限一次，你可以减1点体力上限，在“北定”记录中增加X种牌名（X为你的体力值）。",
  ["#os__huanji-active"] = "幻计：你可减1点体力上限为“北定”增加体力值数量的牌名记录",

  ["$os__huanji1"] = "以计中之计，调雍凉戴甲，天下备鞍！",
  ["$os__huanji2"] = "借计代兵，以一隅抗九州！",
}

huanzhugeliang:addSkill(osHuanji)

local osChanggui = fk.CreateTriggerSkill{
  name = "os__changgui",
  anim_type = "negative",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function (self, event, target, player, data)
    return
      target == player and
      player.phase == Player.Finish and
      player:hasSkill(self) and
      table.every(player.room.alive_players, function(p) return p.hp >= player.hp end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:changeHero(
      player,
      "os_if__zhugeliang",
      false,
      player.deputyGeneral == "os_if_huan__zhugeliang",
      false,
      false
    )
    room:changeMaxHp(player, player.hp - player.maxHp)
  end
}
Fk:loadTranslationTable{
  ["os__changgui"] = "怅归",
  [":os__changgui"] = "锁定技，结束阶段开始时，若你的体力值为全场最低，则你退幻并将体力上限调整至体力值。",

  ["$os__changgui1"] = "隆中鱼水，永安星落，数载恍然隔世。",
  ["$os__changgui2"] = "铁马冰河，金台临望，倏醒方叹无功。",
}

huanzhugeliang:addSkill(osChanggui)

local zhaoyun = General(extension, "os_if__zhaoyun", "shu", 4)

local os__jiezhan = fk.CreateTriggerSkill{
  name = "os__jiezhan",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Play and player ~= target and player:inMyAttackRange(target)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#os__jiezhan-invoke::" .. target.id)
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, self.name)
    if not (player.dead or target.dead) then
      player.room:useVirtualCard("slash", nil, target, player, self.name, false)
    end
  end
}

local os__longjin = fk.CreateTriggerSkill{
  name = "os__longjin",
  frequency = Skill.Wake,
  events = {fk.EnterDying},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function (self, event, target, player, data)
    return player.hp < 1
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:recover{num = 2 - player.hp, who = player, recoverBy = player, skillName = self.name}
    if not player.dead then
      room:setPlayerMark(player, "_os__longjin", 6)
      room:handleAddLoseSkills(player, "longdan|chongzhen", nil, false, true)
    end
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function (self, event, target, player, data)
    return player:getMark("_os__longjin") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("_os__longjin")
    room:setPlayerMark(player, "_os__longjin", mark - 1)
    if mark == 1 then
      room:handleAddLoseSkills(player, "-longdan|-chongzhen", nil, false, true)
    end
  end
}
local os__longjin_distance = fk.CreateDistanceSkill{
  name = "#os__longjin_distance",
  fixed_func = function (self, from, to)
    return (from:getMark("_os__longjin") > 0 and to ~= from) and 1 or nil
  end
}
os__longjin:addRelatedSkill(os__longjin_distance)

zhaoyun:addSkill(os__jiezhan)
zhaoyun:addSkill(os__longjin)
zhaoyun:addRelatedSkill("longdan")
zhaoyun:addRelatedSkill("chongzhen")

Fk:loadTranslationTable{
  ["os_if__zhaoyun"] = "幻赵云",
  ["#os_if__zhaoyun"] = "天武耆龙",
  ["os__jiezhan"] = "竭战",
  [":os__jiezhan"] = "其他角色的出牌阶段开始时，若其在你攻击范围内，你可摸一张牌，然后其视为对你使用一张无距离限制且计入次数限制的【杀】。",
  ["os__longjin"] = "龙烬",
  [":os__longjin"] = "觉醒技，当你进入濒死状态时，你将体力回复至2点，然后于此回合与之后的五个回合内，你视为拥有〖龙胆〗和〖冲阵〗，且你至其他角色的距离视为1。",

  ["#os__jiezhan-invoke"] = "你可发动〖竭战〗，摸一张牌，然后%dest视为对你使用一张无距离限制且计入次数限制的【杀】",

  ["$os__jiezhan1"] = "血尽鳞碎，不改匡汉之志！",
  ["$os__jiezhan2"] = "龙胆虎威，百险千难誓相随！",
  ["$os__longjin1"] = "龙烬沙场，以全大汉荣光！",
  ["$os__longjin2"] = "长坂龙魂犹在，咆哮万里长安！",
  ["$longdan_os_if__zhaoyun1"] = "进退有度，百战无伤！",
  ["$longdan_os_if__zhaoyun2"] = "龙魂缠身，虎威犹在！",
  ["$chongzhen_os_if__zhaoyun1"] = "众将士，且随老夫再战一场！",
  ["$chongzhen_os_if__zhaoyun2"] = "出入千军万马，经年横战八方！",
  ["~os_if__zhaoyun"] = "转战一生，终得见兴汉之日。",
}

local zhanghe = General(extension, "os_if__zhanghe", "wei", 4)

local os__kuiduan = fk.CreateTriggerSkill{
  name = "os__kuiduan",
  frequency = Skill.Compulsory,
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and player == target and data.card.trueName == "slash"
      and #TargetGroup:getRealTargets(data.tos) > 0 and U.isOnlyTarget(player.room:getPlayerById(data.to), data, event)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    for _, p in ipairs{player, to} do
      local cards = table.filter(p:getCardIds("h"), function (id) return Fk:getCardById(id):getMark("@@os__kuiduan_rout-inhand") == 0 end)
      cards = table.random(cards, math.min(2, #cards)) ---@type integer[]
      if #cards > 0 then
        table.forEach(cards, function(id) room:addCardMark(Fk:getCardById(id), "@@os__kuiduan_rout-inhand") end)
      end
    end
  end
}

---@param player ServerPlayer
local function getRoutNum(player)
  return #table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@os__kuiduan_rout-inhand") > 0 end)
end

local os__kuiduan_dmg = fk.CreateTriggerSkill{
  name = "#os__kuiduan_dmg",
  events = {fk.DamageCaused},
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if target ~= player or data.card == nil or data.chain then return false end
    local c_event = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect, false)
    if c_event == nil then return false end
    local use_data = c_event.data[1]
    return (use_data.extra_data or {}).os__kuiduan and data.card == use_data.card and player.id == use_data.from and getRoutNum(player) > getRoutNum(data.to)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:notifySkillInvoked(player, "os__kuiduan")
    data.damage = data.damage + 1
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    if player ~= target then return end
    local cards = Card:getIdList(data.card)
    return #cards == 1 and Fk:getCardById(cards[1]):getMark("@@os__kuiduan_rout-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.os__kuiduan = true
  end,
}

local os__kuiduan_slash = fk.CreateFilterSkill{
  name = "#os__kuiduan_slash",
  card_filter = function(self, card, player)
    return card:getMark("@@os__kuiduan_rout-inhand") > 0
  end,
  view_as = function(self, card)
    return Fk:cloneCard('slash', card.suit, card.number)
  end,
}

zhanghe:addSkill(os__kuiduan)
os__kuiduan:addRelatedSkill(os__kuiduan_dmg)
os__kuiduan:addRelatedSkill(os__kuiduan_slash)

Fk:loadTranslationTable{
  ["os_if__zhanghe"] = "幻张郃",
  ["#os_if__zhanghe"] = "追敌入彀",
  ["os__kuiduan"] = "溃端",
  [":os__kuiduan"] = "锁定技，当你使用【杀】指定唯一目标后，你与其各将随机两张手牌标记为“溃端”牌（只能当【杀】使用或打出）。当“溃端”牌造成伤害时，若伤害来源拥有的“溃端”牌数大于受到伤害的角色，则此伤害+1。<font color='grey'>“溃端”牌暂实现为锁定视为技</font>",

  ["@@os__kuiduan_rout-inhand"] = "溃端",
  ["#os__kuiduan_dmg"] = "溃端",
  ["#os__kuiduan_slash"] = "溃端",

  ["$os__kuiduan1"] = "蜀军大败，吾等岂能失此战机！",
  ["$os__kuiduan2"] = "求胜心切，竟轻中敌计。",
  ["~os_if__zhanghe"] = "老卒迟暮，恨不能再报于国……",
}

return extension
