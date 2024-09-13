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
    return Fk:cloneCard("slash", card.suit, card.number)
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

---@param room Room
---@param player ServerPlayer
---@param target ServerPlayer
---@param num integer
local function addXianyuanMark(room, player, target, num)
  local n = target:getMark("@os__xianyuan")
  n = math.min(3, num + n)
  room:setPlayerMark(target, "@os__xianyuan", n)
  if player ~= target then
    local mark = U.getMark(player, "_os__xianyuan")
    table.insertIfNeed(mark, target.id)
    room:setPlayerMark(player, "_os__xianyuan", mark)
  end
end

local zhugeguo = General(extension, "os_if__zhugeguo", "shu", 3, 3, General.Female)
local xianyuan = fk.CreateActiveSkill{
  name = "os__xianyuan",
  anim_type = "support",
  prompt = "#os__xianyuan-active",
  target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return player:getMark("@os__xianyuan") ~= 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  interaction = function()
    return UI.Spin {
      from = 1,
      to = Self:getMark("@os__xianyuan"),
    }
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local num = self.interaction.data or 1
    room:removePlayerMark(player, "@os__xianyuan", num)
    addXianyuanMark(room, player, target, num)
  end,
}
local xianyuan_trigger = fk.CreateTriggerSkill{
  name = "#os__xianyuan_trigger",
  events = {fk.RoundStart, fk.EventPhaseStart},
  mute = true,
  main_skill = xianyuan,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(xianyuan) then return false end
    return event == fk.RoundStart or (target.phase == Player.Play and target:getMark("@os__xianyuan") > 0)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("os__xianyuan")
    if event == fk.RoundStart then
      room:notifySkillInvoked(player, "os__xianyuan", "support")
      addXianyuanMark(room, player, player, 2)
    else
      local x = target:getMark("@os__xianyuan")
      room:doIndicate(player.id, {target.id})
      local choices = {"os__xianyuan_draw::" .. target.id .. ":" .. x}
      if not target:isKongcheng() then
        table.insert(choices, 1, "os__xianyuan_put::" .. target.id .. ":" .. x)
      end
      if room:askForChoice(player, choices, self.name):startsWith("os__xianyuan_put") then
        room:notifySkillInvoked(player, "os__xianyuan", "control")
        local handcards = target:getCardIds(Player.Hand)
        local top = room:askForArrangeCards(player, "os__xianyuan", {handcards, "$Hand", "Top"},
        "#os__xianyuan-put::" .. target.id .. ":" .. tostring(x), true, 7, {0, x})[2]
        top = table.reverse(top)
        room:moveCards({
          ids = top,
          from = target.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = "os__xianyuan",
          proposer = player.id,
          moveVisible = false,
          visiblePlayers = player.id,
        })
      else
        room:notifySkillInvoked(player, "os__xianyuan", "drawcard")
        target:drawCards(x, self.name)
      end
      if target ~= player then
        room:setPlayerMark(target, "@os__xianyuan", 0)
        local mark
        for _, p in ipairs(room.alive_players) do
          mark = U.getMark(p, "_os__xianyuan")
          if table.removeOne(mark, target.id) then
            if #mark == 0 then mark = 0 end
            room:setPlayerMark(p, "_os__xianyuan", mark)
          end
        end
      end
    end
  end,

  refresh_events = {fk.BuryVictim, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and (event ~= fk.EventLoseSkill or data == xianyuan)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("_os__xianyuan") ~= 0 then
      for _, p in ipairs(room.alive_players) do
        if p:getMark("@os__xianyuan") > 0 and not table.find(room.alive_players, function (p2)
          return table.contains(U.getMark(p2, "_os__xianyuan"), p.id)
        end) then
          room:setPlayerMark(p, "@os__xianyuan", 0)
        end
      end
      room:setPlayerMark(player, "_os__xianyuan", 0)
    end
  end,
}
local lingyin = fk.CreateTriggerSkill{
  name = "os__lingyin",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card:isCommonTrick()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(1)
    local card = Fk:getCardById(cards[1])
    room:moveCardTo(card, Card.Processing, nil, fk.ReasonJustMove, self.name, nil, true, player.id)
    --理论上牌堆里的牌不会没有花色、颜色的，故不做无色判定
    if data.card.color == card.color then
      room:setCardEmotion(card.id, "judgegood")
      room:delay(1000)
      room:obtainCard(player, card, true, fk.ReasonJustMove, player.id, self.name)
      if data.card.suit == card.suit then
        table.insertIfNeed(data.nullifiedTargets, player.id)
      end
    else
      room:setCardEmotion(card.id, "judgebad")
      U.clearRemainCards(room, cards, self.name)
    end
  end,
}
xianyuan:addRelatedSkill(xianyuan_trigger)
zhugeguo:addSkill(xianyuan)
zhugeguo:addSkill(lingyin)

Fk:loadTranslationTable{
  ["os_if__zhugeguo"] = "幻诸葛果",
  ["#os_if__zhugeguo"] = "悠游清汉",
  ["os__xianyuan"] = "仙援",
  [":os__xianyuan"] = "①每轮开始时，你获得2枚“仙援”。（一名角色至多有3枚“仙缘”）②出牌阶段，你可以将任意枚“仙援”" ..
  "分配给其他角色。③有“仙援”的角色出牌阶段开始时，你选择一项：1. 观看其手牌，将其中至多X张牌" ..
  "以任意顺序置于牌堆顶；2. 其摸X张牌。（X为其“仙援”数）然后若此时不是你的回合，你移除其所有“仙援”。",
  ["os__lingyin"] = "灵隐",
  [":os__lingyin"] = "当你成为普通锦囊牌的目标后，你可以亮出牌堆顶的一张牌，若此牌与此普通锦囊牌颜色相同，你获得亮出的牌，若花色也相同，此普通锦囊牌对此目标无效。",

  ["#os__xianyuan-active"] = "发动 仙援，令一名其他角色获得任意枚“仙援”标记",
  ["@os__xianyuan"] = "仙援",
  ["#os__xianyuan_trigger"] = "仙援",
  ["os__xianyuan_draw"] = "%dest摸%arg张牌",
  ["os__xianyuan_put"] = "观看%dest的手牌，将其中至多%arg张牌置于牌堆顶",
  ["#os__xianyuan-put"] = "仙援：观看%dest的手牌，并且可以将其中至多%arg张牌置于牌堆顶",

  ["$os__xianyuan1"] = "顺天者，天助之。",
  ["$os__xianyuan2"] = "所思所寻，皆得天应。",
  ["$os__lingyin1"] = "我自逍遥天地，何拘凡尘俗法？",
  ["$os__lingyin2"] = "朝沐露霞寤，夜枕溪潺眠。",
  ["~os_if__zhugeguo"] = "仙缘已了，魂入轮回。",
}

local jiangwei = General(extension, "os_if__jiangwei", "shu", 4)
local os__qinghan = fk.CreateActiveSkill{
  name = "os__qinghan",
  prompt = "#os__qinghan-active",
  anim_type = "control",
  can_use = function (self, player, card, extra_data)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_num = 1,
  card_filter = function (self, to_select, selected, selected_targets)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  target_num = 1,
  target_filter = function (self, to_select, selected, selected_cards, card, extra_data)
    return #selected_cards == 1 and Self:canPindian(Fk:currentRoom():getPlayerById(to_select), true)
  end,
  on_use = function (self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pd = player:pindian({target}, self.name, Fk:getCardById(effect.cards[1]))
    if pd.results[target.id].winner == player then
      local all_names = U.getAllCardNames("t")
      for i = #all_names, 1, -1 do
        local card = Fk:cloneCard(all_names[i])
        card.skillName = self.name
        if not U.canUseCardTo(room, player, target, card, false, false) then
          table.remove(all_names, i)
        end
      end
      local names = U.getViewAsCardNames(Self, self.name, all_names, nil)
      if #names > 0 then
        local _names = U.askForChooseCardNames(room, player, names, 1, 1, self.name, "#os__qinghan-trick::" .. target.id, all_names, true)
        if #_names > 0 then
          room:useVirtualCard(_names[1], nil, player, target, self.name)
        end
      end
    end
    if pd.results[target.id].toCard:compareColorWith(pd.fromCard) then
      local moveInfos = {}
      if room:getCardArea(pd.results[target.id].toCard) == Card.DiscardPile then
        table.insert(moveInfos, {
          to = player.id,
          ids = Card:getIdList(pd.results[target.id].toCard),
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonExchange,
          proposer = player.id,
          skillName = self.name,
        })
      end
      if room:getCardArea(pd.fromCard) == Card.DiscardPile then
        table.insert(moveInfos, {
          to = target.id,
          ids = Card:getIdList(pd.fromCard),
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonExchange,
          proposer = player.id,
          skillName = self.name,
        })
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
      end
    end
  end,
}
local os__qinghan_pindian = fk.CreateTriggerSkill{
  name = "#os__qinghan_pindian",
  mute = true,
  main_skill = os__qinghan,
  events = {fk.PindianCardsDisplayed},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(os__qinghan) and (player == data.from or data.results[player.id])
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local num = 2 * #player:getCardIds(Player.Equip)
    if target == data.from.id then
      data.fromCard.number = math.min(data.fromCard.number + num, 13)
    elseif data.results[target] then
      data.results[target].toCard.number = math.min(data.results[target].toCard.number + num, 13)
    end
  end,
}
os__qinghan:addRelatedSkill(os__qinghan_pindian)

local os__zhihuan = fk.CreateTriggerSkill{
  name = "os__zhihuan",
  anim_type = "control",
  events = {fk.DamageCaused},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash"
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#os__zhihuan-invoke::" .. data.to.id)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    target = data.to
    local choices
    if #target:getCardIds(Player.Equip) > 0 then
      choices = {"os__zhihuan_target", "os__zhihuan_pile"}
    else
      choices = {"os__zhihuan_pile"}
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "os__zhihuan_target" then
      local card = room:askForCardChosen(player, target, "e", self.name)
      room:obtainCard(player.id, card, true, fk.ReasonPrey, player.id, self.name)
    else
      local subtype_string_table = {
        [Card.SubtypeArmor] = "armor",
        [Card.SubtypeWeapon] = "weapon",
        [Card.SubtypeTreasure] = "treasure",
        [Card.SubtypeDelayedTrick] = "delayed_trick",
        [Card.SubtypeDefensiveRide] = "defensive_ride",
        [Card.SubtypeOffensiveRide] = "offensive_ride",
      }
      local slots = table.simpleClone(player:getAvailableEquipSlots())
      table.shuffle(slots)
      for _, slot in ipairs(slots) do
        if player.dead then return end
        local type = Util.convertSubtypeAndEquipSlot(slot)
        if #player:getEquipments(type) < #player:getAvailableEquipSlots(type) then
          local ids = room:getCardsFromPileByRule(".|.|.|.|.|"..subtype_string_table[type], 1, "allPiles")
          if #ids > 0 then
            room:obtainCard(player, ids[1], true, fk.ReasonPrey, player.id, self.name)
            if not player.dead then
              room:useCard{
                from = player.id,
                tos = {{player.id}},
                card = Fk:getCardById(ids[1]),
              }
              break
            end
          end
        end
      end
    end
    room:setPlayerMark(target, "@@os__zhihuan_discard", 1)
    return true
  end
}
local os__zhihuan_delay = fk.CreateTriggerSkill{
  name = "#os__zhihuan_delay",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function (self, event, target, player, data)
    return player == target and data.card.trueName == "jink" and player:getMark("@@os__zhihuan_discard") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local cards = player:getCardIds(Player.Hand)
    local room = player.room
    room:setPlayerMark(player, "@@os__zhihuan_discard", 0)
    if #cards > 0 then
      room:throwCard(table.random(cards, 2), self.name, player, player)
    end
  end
}
os__zhihuan:addRelatedSkill(os__zhihuan_delay)

jiangwei:addSkill(os__qinghan)
jiangwei:addSkill(os__zhihuan)

Fk:loadTranslationTable{
  ["os_if__jiangwei"] = "幻姜维",
  ["#os_if__jiangwei"] = "麒麟擎汉",
  ["os__qinghan"] = "擎汉",
  [":os__qinghan"] = "①出牌阶段限一次，你可用一张装备牌与一名角色拼点：若你赢，你可视为对其使用一张以其为唯一目标的普通锦囊牌；" ..
  "若两张拼点牌颜色相同，你与其获得对方的拼点牌。②你的拼点牌点数+X（X为你装备区牌数的两倍）。",
  ["os__zhihuan"] = "治宦",
  [":os__zhihuan"] = "当你使用【杀】造成伤害时，你可防止此伤害并选择一项：1. 获得其装备区里的一张牌；" ..
  "2. 获得并使用一张牌堆或弃牌堆中与你空置的装备栏对应类型的装备牌。若如此做，其下次使用【闪】时随机弃置两张手牌。",

  ["#os__qinghan-active"] = "你可发动 擎汉，选择一张装备牌与一名角色拼点",
  ["#os__qinghan-trick"] = "擎汉：你可视为对%dest使用一张以其为唯一目标的普通锦囊牌",
  ["#os__qinghan_pindian"] = "擎汉",
  ["#os__zhihuan-invoke"] = "你可发动〖治宦〗，防止对 %dest 的伤害",
  ["os__zhihuan_target"] = "获得其装备区里的一张牌",
  ["os__zhihuan_pile"] = "获得并使用一张牌堆或弃牌堆中与你空置的装备栏对应类型的装备牌",
  ["@@os__zhihuan_discard"] = "被治宦",
  ["#os__zhihuan_delay"] = "治宦",

  ["$os__qinghan1"] = "二十四代终未竟，今以一隅誓还天！",
  ["$os__qinghan2"] = "维继丞相遗托，当负擎汉之重。",
  ["$os__zhihuan1"] = "贪行祸国，谗言媚主，汝罪不容诛！",
  ["$os__zhihuan2"] = "阉宦小人，何以蔽天！",
  ["~os_if__jiangwei"] = "九州未定，维有负丞相遗托。",
}

local simayi = General(extension, "os_if__simayi", "wei", 3)
local os__zongquan = fk.CreateTriggerSkill{
  name = "os__zongquan",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_cost = function (self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper),
      1, 1, "#os__zongquan-invoke", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|heart,diamond",
    }
    room:judge(judge)
    local card = judge.card
    if not to.dead then
      local record = player:getTableMark("_os__zongquan")
      local num = (record[1] == to.id and record[2] ~= card.color and
        card.color ~= Card.NoColor and record[2] ~= Card.NoColor) and 3 or 1
      record = {to.id, card.color}
      room:setPlayerMark(player, "_os__zongquan", record)
      if card.color == Card.Red then
        to:drawCards(num)
      elseif card.color == Card.Black and not to:isNude() then
        room:askForDiscard(to, num, num, true, self.name, false, nil, "#os__zongquan-discard:::" .. num)
      end
    end
    if room:getCardArea(card) == Card.Processing and not player.dead then
      local tar = room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper),
        1, 1, "#os__zongquan-obtain:::" .. card:toLogString(), self.name, false)[1]
      room:obtainCard(tar, card, true, fk.ReasonPrey, player.id, self.name)
    end
  end,
}

local os__guimou = fk.CreateTriggerSkill{
  name = "os__guimou",
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name) < 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(4, "bottom")
    local result = room:askForArrangeCards(player, self.name, {cards, "Bottom", {}, "Retrial", {}, "Top"},
      "#os__guimou-retrial::" .. target.id .. ":" .. data.reason, true, 4, {0, 1, 3}, {0, 1, 3})
    local card = result[2][1]
    player.room:retrial(Fk:getCardById(card), player, data, self.name)
    if player.dead then return end
    local top = table.reverse(result[3])
    room:moveCards({
      ids = top,
      from = target.id,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = self.name,
      proposer = player.id,
      moveVisible = false,
      visiblePlayers = player.id,
    })
  end,
}

simayi:addSkill(os__zongquan)
simayi:addSkill(os__guimou)

Fk:loadTranslationTable{
  ["os_if__simayi"] = "幻司马懿",
  ["#os_if__simayi"] = "权谋并施",
  ["os__zongquan"] = "纵权",
  [":os__zongquan"] = "准备阶段或结束阶段，你可以选择一名角色，然后你进行判定：若结果为红色，你令其摸一张牌；" ..
  "若结果为黑色，你令其弃置一张牌；若你本次与上一次发动〖纵权〗所选择的目标角色相同但结果颜色不同，则改为摸/弃置三张牌。若如此做，你令一名角色获得判定牌。",
  ["os__guimou"] = "鬼谋",
  [":os__guimou"] = "每回合限两次，当一名角色的判定牌生效前，你可观看牌堆底的四张牌，选择其中一张牌代替之，然后将其余牌以任意顺序置于牌堆顶。",

  ["#os__zongquan-invoke"] = "你可对一名角色发动〖纵权〗",
  ["#os__zongquan-discard"] = "纵权：请弃置 %arg 张牌",
  ["#os__zongquan-obtain"] = "纵权：你令一名角色获得%arg",
  ["#os__guimou-retrial"] = "鬼谋：选择一张牌改判%dest的%arg，其余置于牌堆顶",

  ["$os__zongquan1"] = "大权不可旁落，且由老夫暂领。",
  ["$os__zongquan2"] = "再立大魏新政，诏天下怀魏之人。",
  ["$os__guimou1"] = "将在外而君死社稷，自不受他人之治。",
  ["$os__guimou2"] = "诸葛贼计已穷，且看老夫此番谋略何如。",
  ["~os_if__simayi"] = "天命已定，汝竟能逆之……",
}

return extension
