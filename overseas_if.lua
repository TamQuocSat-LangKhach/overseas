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
  ["illustrator:os_if__zhugeliang"] = "黯荧岛",
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
      function(name) return not table.contains(player:getTableMark("@$os__beiding_names"), name) end
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

    local namesChosenThisTurn = player:getTableMark("os__beiding_names-turn")
    table.insert(namesChosenThisTurn, namesChosen)
    room:setPlayerMark(player, "os__beiding_names-turn", namesChosen)

    namesChosen = table.map(namesChosen, function(name)
      local realName = name:split("__")
      return realName[#realName]
    end)
    local beidingNames = player:getTableMark("@$os__beiding_names")
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
    local namesChosenThisTurn = player:getTableMark("os__beiding_names-turn")
    for _, name in ipairs(namesChosenThisTurn) do
      if not player:isAlive() then
        break
      end

      local use = U.askForUseVirtualCard(room, player, name, nil, self.name, "#os__beiding-use:::" .. name, false, true, true)
      if use and not table.contains(TargetGroup:getRealTargets(use.tos), target.id) and not target.dead then
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
  ["illustrator:os_if_huan__zhugeliang"] = "黯荧岛",
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
      table.contains(player:getTableMark("@$os__beiding_names"), data.card.trueName)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, self.name)
    local beidingNames = player:getTableMark("@$os__beiding_names")
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
        table.contains(player:getTableMark("@$os__beiding_names"), data.card.trueName)
    elseif event == fk.AfterCardsMove then
      return table.find(data, function(move)
        if move.to == player.id and move.toArea == Card.PlayerHand then
          return
            table.find(
              move.moveInfo,
              function(moveInfo)
                return table.contains(player:getTableMark("@$os__beiding_names"), Fk:getCardById(moveInfo.cardId).trueName)
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
            if table.contains(player:getTableMark("@$os__beiding_names"), card.trueName) then
              player.room:setCardMark(card, "@@os__beiding_card-inhand", 1)
            end
          end
        end
      end
    elseif event == fk.EventAcquireSkill then
      for _, id in ipairs(player:getCardIds("h")) do
        local card = Fk:getCardById(id)
        if table.contains(player:getTableMark("@$os__beiding_names"), card.trueName) then
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
      function(name) return not table.contains(from:getTableMark("@$os__beiding_names"), name) end
    )

    if #cardNames == 0 then
      return false
    end
    cardNames = table.filter(cardNames, function(name) return #name:split("__") == 1 end)

    local namesChosen = room:askForChoices(from, cardNames, from.hp, from.hp, self.name, "#os__beiding-choose:::" .. from.hp, false)
    local beidingNames = from:getTableMark("@$os__beiding_names")
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
  ["illustrator:os_if__zhaoyun"] = "铁杵",
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
    local mark = player:getTableMark("_os__xianyuan")
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
          mark = p:getTableMark("_os__xianyuan")
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
          return table.contains(p2:getTableMark("_os__xianyuan"), p.id)
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
  ["illustrator:os_if__zhugeguo"] = "嵘金",

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
  ["illustrator:os_if__jiangwei"] = "刘小狼Syaoran",
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
  ["illustrator:os_if__simayi"] = "凝聚永恒",
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

local weiyan = General(extension, "os_if__weiyan", "shu", 4)
local piankuang = fk.CreateTriggerSkill{
  name = "os__piankuang",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" then
      if event == fk.DamageCaused then
        return player.room.logic:damageByCardEffect() and
          #player.room.logic:getActualDamageEvents(1, function (e)
            local damage = e.data[1]
            return damage.from == player and damage.card and damage.card.trueName == "slash"
          end, Player.HistoryTurn) > 0
      elseif event == fk.CardUseFinished and not data.damageDealt then
        local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
        return turn_event and turn_event.data[1] == player
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.DamageCaused then
      room:notifySkillInvoked(player, self.name, "offensive")
      data.damage = data.damage + 1
    else
      room:notifySkillInvoked(player, self.name, "negative")
      room:addPlayerMark(player, MarkEnum.MinusMaxCards.."-turn", 1)
    end
  end
}
local qiji = fk.CreateTriggerSkill{
  name = "os__qiji",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      not player:isKongcheng() and table.find(player.room:getOtherPlayers(player), function (p)
        return player:canUseTo(Fk:cloneCard("slash"), p, {bypass_distances = true, bypass_times = true})
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local types = {}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(types, Fk:getCardById(id).type)
    end
    local targets = table.filter(room:getOtherPlayers(player), function (p)
      return player:canUseTo(Fk:cloneCard("slash"), p, {bypass_distances = true, bypass_times = true})
    end)
    local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
      "#os__qiji-invoke:::"..#types, self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = {}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(types, Fk:getCardById(id).type)
    end
    local to = room:getPlayerById(self.cost_data.tos[1])
    for i = 1, #types, 1 do
      if to.dead then break end
      room:useVirtualCard("slash", nil, player, to, self.name, true)
    end
  end,
}
local qiji_delay = fk.CreateTriggerSkill{
  name = "#os__qiji_delay",
  mute = true,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target:usedSkillTimes("os__qiji", Player.HistoryPhase) > 0 and data.to == player.id and
      table.contains(data.card.skillNames, "os__qiji") and
      not (data.extra_data and data.extra_data.os__qiji) and
      table.find(player.room:getOtherPlayers(player), function (p)
        return target ~= p and not table.contains(player:getTableMark("os__qiji-turn"), p.id)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function (p)
      return target ~= p and not table.contains(player:getTableMark("os__qiji-turn"), p.id)
    end)
    local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#os__qiji-choose", "os__qiji", true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.extra_data = data.extra_data or {}
    data.extra_data.os__qiji = true
    local to = room:getPlayerById(self.cost_data)
    room:addTableMark(player, "os__qiji-turn", to.id)
    to:drawCards(1, "os__qiji-turn")
    if not to.dead and table.contains(room:getUseExtraTargets(data, true, true), to.id) and
      room:askForSkillInvoke(to, "os__qiji", nil, "#os__qiji-ask:"..player.id) then
      AimGroup:cancelTarget(data, player.id)
      AimGroup:addTargets(room, data, to.id)
    end
  end,
}
qiji:addRelatedSkill(qiji_delay)
weiyan:addSkill(qiji)
weiyan:addSkill(piankuang)
Fk:loadTranslationTable{
  ["os_if__weiyan"] = "幻魏延",
  ["#os_if__weiyan"] = "自矜功伐",
  ["illustrator:os_if__weiyan"] = "凝聚永恒",

  ["os__qiji"] = "奇击",
  [":os__qiji"] = "出牌阶段开始时，你可以视为对一名其他角色使用X张无距离限制且不计入次数的【杀】，此【杀】指定目标时，其可以选择一名本回合"..
  "未以此法选择过的其他角色，被选择的角色摸一张牌，然后其可以将此【杀】的目标转移给自己（X为出牌阶段开始时你手牌的类别数）。",
  ["os__piankuang"] = "偏狂",
  [":os__piankuang"] = "锁定技，当你使用【杀】对目标角色造成伤害时，若你本回合使用【杀】造成过伤害，此伤害+1。你的回合内，当你使用【杀】"..
  "结算后，若此【杀】未造成伤害，本回合你手牌上限-1。",
  ["#os__qiji-invoke"] = "奇击：你可以视为对一名其他角色使用%arg张【杀】！",
  ["#os__qiji_delay"] = "奇击",
  ["#os__qiji-choose"] = "奇击：你可以选择一名角色摸一张牌，其可以将此【杀】转移给其",
  ["#os__qiji-ask"] = "奇击：是否将对 %src 使用的【杀】转移给你？",

  ["$os__qiji1"] = "久攻不克？待吾奇兵灭敌！",
  ["$os__qiji2"] = "依我此计，魏都不日可下！",
  ["$os__piankuang1"] = "有延一人，足为我主克魏吞吴！",
  ["$os__piankuang2"] = "非我居功自傲，实为吴魏之辈不足一提！",
  ["~os_if__weiyan"] = "若无粮草之急，何致有今日此败！",
}

local liushan = General(extension, "os_if__liushan", "shu", 3)
local guihanh = fk.CreateActiveSkill{
  name = "os__guihanh",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 3,
  prompt = "#os__guihanh",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, to_select, selected, selected_cards)
    return #selected < 3 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local c = room:getNCards(1)
    local type = Fk:getCardById(c[1]):getTypeString()
    room:moveCardTo(c, Card.Processing, nil, fk.ReasonJustMove, self.name, nil, true, player.id)
    room:sortPlayersByAction(effect.tos)
    local n = 0
    for _, id in ipairs(effect.tos) do
      local target = room:getPlayerById(id)
      if not target.dead then
        local card = room:askForCard(target, 1, 1, true, self.name, true, ".|.|.|.|.|"..type, "#os__guihanh-ask:::"..type)
        if #card > 0 then
          n = n + 1
          room:moveCards({
            ids = card,
            from = target.id,
            toArea = Card.DrawPile,
            moveReason = fk.ReasonPut,
            skillName = self.name,
            moveVisible = true,
            drawPilePosition = 1,
          })
        else
          room:loseHp(target, 1, self.name)
        end
      end
    end
    U.clearRemainCards(room, c)
    if player.dead then return end
    local choices = {"os__guihanh2:::"..(n + 1)}
    if n > 0 then
      table.insert(choices, 1, "os__guihanh1:::"..n)
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice[11] == "1" then
      player:drawCards(n, self.name)
    else
      local ids = {}
      if #room.draw_pile > n then
        table.insert(ids, room.draw_pile[n + 1])
      end
      if #room.draw_pile > n + 1 then
        table.insert(ids, room.draw_pile[n + 2])
      end
      if #ids == 0 then return end
      room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, false, player.id)
    end
  end,
}
local renxian = fk.CreateActiveSkill{
  name = "os__renxian",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#os__renxian",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).type == Card.TypeBasic and Fk:getCardById(id).trueName ~= "jink"
      end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).type == Card.TypeBasic and Fk:getCardById(id).trueName ~= "jink"
    end)
    room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id, "@@os__renxian-inhand")
    if target.dead then return end
    target:gainAnExtraTurn(true, self.name, {phase_table = {Player.Play}})
  end,
}
local renxian_delay = fk.CreateTriggerSkill{
  name = "#os__renxian_delay",

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if target ~= player or data.reason ~= "os__renxian" then
      for _, id in ipairs(player:getCardIds("h")) do
        room:setCardMark(Fk:getCardById(id), "@@os__renxian-inhand", 0)
      end
    else
      room:setPlayerMark(player, "os__renxian-turn", 1)
    end
  end,
}
local renxian_targetmod = fk.CreateTargetModSkill{
  name = "#os__renxian_targetmod",
  bypass_times = function(self, player, skill, scope)
    return skill.trueName == "slash_skill" and player:getMark("os__renxian-turn") > 0
  end,
}
local renxian_prohibit = fk.CreateProhibitSkill{
  name = "#os__renxian_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("os__renxian-turn") > 0 and card:getMark("@@os__renxian-inhand") == 0
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("os__renxian-turn") > 0 and card:getMark("@@os__renxian-inhand") == 0
  end,
}
local yanzuo = fk.CreateTriggerSkill{
  name = "os__yanzuok$",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self) and target and target.kingdom == "shu" and
      player:usedSkillTimes(self.name, Player.HistoryTurn) < 2 then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      return turn_event and turn_event.data[1] == target and turn_event.data[2].reason == "os__renxian"
    end
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
renxian:addRelatedSkill(renxian_delay)
renxian:addRelatedSkill(renxian_targetmod)
renxian:addRelatedSkill(renxian_prohibit)
liushan:addSkill(guihanh)
liushan:addSkill(renxian)
liushan:addSkill(yanzuo)
Fk:loadTranslationTable{
  ["os_if__liushan"] = "幻刘禅",
  ["#os_if__liushan"] = "汉祚永延",

  ["os__guihanh"] = "归汉",
  [":os__guihanh"] = "出牌阶段限一次，你可以选择至多三名有手牌的其他角色，然后展示牌堆顶牌，这些角色依次选择一项：1.将一张同类别牌置于牌堆顶；"..
  "2.失去1点体力。然后你选择一项：1.摸X张牌；2.获得牌堆第X+1张开始的两张牌。（X为以此法置于牌堆顶的牌数）",
  ["os__renxian"] = "任贤",
  [":os__renxian"] = "出牌阶段限一次，你可以将除【闪】以外的所有基本牌交给一名其他角色，此回合结束后，其执行一个只有出牌阶段的额外回合，"..
  "该回合内其只能使用或打出你以此法交给其的牌且使用【杀】无次数限制。",
  ["os__yanzuok"] = "延祚",
  [":os__yanzuok"] = "主公技，锁定技，每回合限两次，当其他蜀势力角色于“任贤”回合内造成伤害后，你摸两张牌。",
  ["#os__guihanh"] = "归汉：选择至多三名角色，这些角色选择将一张牌置于牌堆顶或失去1点体力",
  ["#os__guihanh-ask"] = "归汉：将一张%arg置于牌堆顶，或点“取消”失去1点体力",
  ["os__guihanh1"] = "摸%arg张牌",
  ["os__guihanh2"] = "获得牌堆第%arg张开始的两张牌",
  ["#os__renxian"] = "任贤：将所有非【闪】基本牌交给一名角色，其执行一个只能使用这些牌的额外回合",
  ["@@os__renxian-inhand"] = "任贤",

  ["$os__guihanh1"] = "天下分合，终不改汉祚之名！",
  ["$os__guihanh2"] = "平安南北，终携百姓致太平！",
  ["$os__renxian1"] = "朕虽驽钝，幸有众爱卿襄助！",
  ["$os__renxian2"] = "知人善用，任人唯贤！",
  ["$os__yanzuok1"] = "若无忠臣良将，焉有今日之功！",
  ["$os__yanzuok2"] = "卿等安国定疆，方有今日之统！",
  ["~os_if__liushan"] = "天下分崩离乱，再难建兴……",
}

local luxun = General(extension, "os_if__luxun", "wu", 3)
local lifengh = fk.CreateActiveSkill{
  name = "os__lifengh",
  anim_type = "offensive",
  card_num = 2,
  target_num = 1,
  prompt = "#os__lifengh",
  can_use = Util.TrueFunc,
  card_filter = function (self, to_select, selected)
    if #selected < 2 and not Self:prohibitDiscard(to_select) then
      if #selected == 0 then
        return true
      else
        return Fk:getCardById(to_select).number ~= Fk:getCardById(selected[1]).number
      end
    end
  end,
  target_filter = function (self, to_select, selected, selected_cards)
    if #selected_cards == 2 then
      return Self:distanceTo(Fk:currentRoom():getPlayerById(to_select)) <=
        math.abs(Fk:getCardById(selected_cards[1]).number - Fk:getCardById(selected_cards[2]).number)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local nums = table.map(effect.cards, function (id)
      return Fk:getCardById(id).number
    end)
    room:throwCard(effect.cards, self.name, player, player)
    if target.dead then return end
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = self.name,
      extra_data = {
        os__lifengh = {player.id, nums},
      }
    }
  end,
}
local lifengh_delay = fk.CreateTriggerSkill{
  name = "#os__lifengh_delay",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.skillName == "os__lifengh"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local src = room:getPlayerById(data.extra_data.os__lifengh[1])
    local nums = data.extra_data.os__lifengh[2]
    table.sort(nums)
    local card = {}
    if player:isKongcheng() and room:askForSkillInvoke(player, "os__lifengh", nil,
      "#os__lifengh-draw:"..src.id..":"..nums[1]..":"..nums[2]) then
      card = player:drawCards(1, "os__lifengh")
    elseif not player:isKongcheng() then
      card = room:askForCard(player, 1, 1, false, "os__lifengh", true, nil,
      "#os__lifengh-recast:"..src.id.."::"..nums[1]..":"..nums[2])
      if #card > 0 then
        room:recastCard(card, player, "os__lifengh")
      end
    end
    if #card > 0 then
      local n = Fk:getCardById(card[1]).number
      if n >= nums[1] and n <= nums[2] then
        room:invalidateSkill(src, "os__lifengh", "-turn")
        return true
      end
    end
  end,
}
local niwo = fk.CreateTriggerSkill{
  name = "os__niwo",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      not player:isKongcheng() and table.find(player.room:getOtherPlayers(player), function(p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng()
    end)
    local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#os__niwo-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local extra_data = {}
    local visible_data = {}
    for _, id in ipairs(player:getCardIds("h")) do
      if not player:cardVisible(id) then
        visible_data[tostring(id)] = false
      end
    end
    for _, id in ipairs(to:getCardIds("h")) do
      if not player:cardVisible(id) then
        visible_data[tostring(id)] = false
      end
    end
    if next(visible_data) == nil then visible_data = nil end
    extra_data.visible_data = visible_data
    local cards = room:askForPoxi(player, "os__niwo", {
      { player.general, player:getCardIds("h") },
      { to.general, to:getCardIds("h") },
    }, extra_data, true)
    if #cards > 0 then
      for _, id in ipairs(cards) do
        room:setCardMark(Fk:getCardById(id), "@@os__niwo-inhand-turn", 1)
      end
    end
  end,
}
local niwo_prohibit = fk.CreateProhibitSkill{
  name = "#os__niwo_prohibit",
  prohibit_use = function(self, player, card)
    return card:getMark("@@os__niwo-inhand-turn") > 0
  end,
  prohibit_response = function(self, player, card)
    return card:getMark("@@os__niwo-inhand-turn") > 0
  end,
}
Fk:addPoxiMethod{
  name = "os__niwo",
  prompt = "#os__niwo",
  card_filter = function(to_select, selected, data)
    return true
  end,
  feasible = function(selected, data)
    if #selected > 0 and #selected % 2 == 0 then
      return #table.filter(selected, function (id)
        return table.contains(data[1][2], id)
      end) == #table.filter(selected, function (id)
        return table.contains(data[2][2], id)
      end)
    end
  end,
}
lifengh:addRelatedSkill(lifengh_delay)
niwo:addRelatedSkill(niwo_prohibit)
luxun:addSkill(lifengh)
luxun:addSkill(niwo)
Fk:loadTranslationTable{
  ["os_if__luxun"] = "幻陆逊",
  ["#os_if__luxun"] = "审机而行",

  ["os__lifengh"] = "砺锋",
  [":os__lifengh"] = "出牌阶段，你可以弃置两张点数不同的牌，对一名距离X以内的角色造成1点伤害（X为这两张牌点数之差），其受到此伤害时，"..
  "可以重铸一张手牌（没有手牌则改为摸一张牌），若此牌点数介于这两张牌点数闭区间，防止此伤害且本回合此技能失效。",
  ["os__niwo"] = "逆涡",
  [":os__niwo"] = "出牌阶段开始时，你可以选择一名其他角色，选择你与其等量的手牌，本回合你与其不能使用或打出这些牌。",
  ["#os__lifengh"] = "砺锋：弃两张牌，对一名距离这两张牌点数之差以内的角色造成1点伤害",
  ["#os__lifengh_delay"] = "砺锋",
  ["#os__lifengh-draw"] = "砺锋：%src 对你造成伤害，是否摸一张牌？若点数介于[%arg, %arg2]则防止伤害且其“砺锋”失效",
  ["#os__lifengh-recast"] = "砺锋：%src 对你造成伤害，是否重铸一张手牌？若点数介于[%arg, %arg2]则防止伤害且其“砺锋”失效",
  ["#os__niwo-choose"] = "逆涡：你可以选择一名角色，选择双方等量的手牌本回合无法使用或打出",
  ["#os__niwo"] = "逆涡：选择双方等量手牌，本回合不能使用或打出",
  ["@@os__niwo-inhand-turn"] = "逆涡",

  ["$os__lifengh1"] = "十载磨一剑，今日欲以贼三军拭锋！",
  ["$os__lifengh2"] = "业火炼锋，江水淬刃，方铸此师！",
  ["$os__niwo1"] = "疲敌而取之以逸，其势易也！",
  ["$os__niwo2"] = "调其心疲其士，则可以静制动，以弱胜强！",
  ["~os_if__luxun"] = "但为大吴万世基业，臣死亦不改匡谏之心！",
}

local ifcaoang = General(extension, "os_if__caoang", "wei", 3, 4)

Fk:loadTranslationTable{
  ["os_if__caoang"] = "幻曹昂",
  ["#os_if__caoang"] = "穿时寻冀",
  ["~os_if__caoang"] = "",
}

local osChihui = fk.CreateTriggerSkill{
  name = "os__chihui",
  anim_type = "control",
  events = {fk.TurnStart},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and not target.dead and #player:getAvailableEquipSlots() > 0
  end,
  on_cost = function (self, event, target, player, data)
    local all_choices = {
      "WeaponSlot",
      "ArmorSlot",
      "DefensiveRideSlot",
      "OffensiveRideSlot",
      "TreasureSlot"
    }
    local subtypes = {
      Card.SubtypeWeapon,
      Card.SubtypeArmor,
      Card.SubtypeDefensiveRide,
      Card.SubtypeOffensiveRide,
      Card.SubtypeTreasure
    }
    local choices = {}
    for i = 1, 5, 1 do
      if #player:getAvailableEquipSlots(subtypes[i]) > 0 then
        table.insert(choices, all_choices[i])
      end
    end
    table.insert(all_choices, "Cancel")
    table.insert(choices, "Cancel")
    local choice = player.room:askForChoice(player, choices, self.name, "#os__chihui-choice::" .. target.id, false, all_choices)
    if choice ~= "Cancel" then
      player.room:doIndicate(player.id, {target.id})
      self.cost_data = choice
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:abortPlayerArea(player, {self.cost_data})
    if player.dead or target.dead then return false end

    local subtype = Util.convertSubtypeAndEquipSlot(self.cost_data)
    local mapper = {
      [Card.SubtypeWeapon] = "weapon",
      [Card.SubtypeArmor] = "armor",
      [Card.SubtypeOffensiveRide] = "offensive_horse",
      [Card.SubtypeDefensiveRide] = "defensive_horse",
      [Card.SubtypeTreasure] = "treasure",
    }
    local all_choices = {
      "os__chihui_discard::" .. target.id,
      "os__chihui_putequip::" .. target.id .. ":" .. mapper[subtype],
    }
    local choices = {}
    if not target:isAllNude() then
      table.insert(choices, all_choices[1])
    end
    if target:hasEmptyEquipSlot(subtype) then
      table.insert(choices, all_choices[2])
    end
    if #choices == 0 then return false end
    local choice = room:askForChoice(player, choices, self.name, nil, false, all_choices)
    if choice == all_choices[1] then
      room:throwCard(room:askForCardChosen(player, target, "hej", self.name), self.name, target, player)
    else
      local cards = table.filter(room.draw_pile, function(id) return Fk:getCardById(id).sub_type == subtype end)
      if #cards > 0 then
        room:moveCardIntoEquip(target, table.random(cards), self.name, false, player)
      end
    end

    if player.dead then return false end
    room:loseHp(player, 1, self.name)
    if player.dead then return false end
    local x = player:getLostHp()
    if x > 0 then
      room:drawCards(player, x, self.name)
    end
  end
}
Fk:loadTranslationTable{
  ["os__chihui"] = "炽灰",
  [":os__chihui"] = "其他角色的回合开始时，你可以废除一个装备栏，选择：1.弃置其区域里的一张牌；"..
    "2.将牌堆里的一张对应副类别的牌置入其装备区。若如此做，你失去1点体力，摸X张牌（X为你已损失的体力值）。",

  ["#os__chihui-choice"] = "是否对%dest发动 炽灰，选择要废除的装备栏",

  ["os__chihui_discard"] = "弃置%dest区域里的一张牌",
  ["os__chihui_putequip"] = "将%arg置入%dest的装备区",

  ["$os__chihui1"] = "",
  ["$os__chihui2"] = "",
}

ifcaoang:addSkill(osChihui)

local osFuxi = fk.CreateTriggerSkill{
  name = "os__fuxi",
  anim_type = "defensive",
  events = {fk.EnterDying, fk.AreaAborted},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) then return false end
    if event == fk.EnterDying then
      return player.dying
    elseif event == fk.AreaAborted then
      return (#data.slots > 0 or data.slots[1] ~= Player.JudgeSlot) and #player:getAvailableEquipSlots() == 0
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local x = math.min(player.maxHp, 5)
    local all_choices = {
      "os__fuxi1",
      "os__fuxi2",
      "os__fuxi3:::" .. tostring(x),
      "os__fuxi4"
    }
    local choices = {"os__fuxi2"}
    if room.logic:getCurrentEvent():findParent(GameEvent.Turn, true) then
      table.insert(choices, all_choices[1])
    end
    if player:getHandcardNum() < x then
      table.insert(choices, all_choices[3])
    end
    if #player:getAvailableEquipSlots() == 0 then
      table.insert(choices, all_choices[4])
    end
    choices = room:askForChoices(player, choices, 1, 2, self.name, "#os__fuxi-choice", true, false, all_choices)
    if #choices > 0 then
      self.cost_data = choices
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = self.cost_data
    if table.contains(choices, "os__fuxi1") then
      player:gainAnExtraTurn()
    end
    if table.find(
      choices,
      function (choice) return choice:startsWith("os__fuxi3")
    end) then
      local x = math.min(5, player.maxHp) - player:getHandcardNum()
      if x > 0 then
        room:drawCards(player,x, self.name)
        if player.dead then return false end
      end
    end
    if table.contains(choices, "os__fuxi4") then
      local slots = table.simpleClone(player.sealedSlots)
      table.removeOne(slots, Player.JudgeSlot)
      local x = #slots
      if x > 0 then
        room:resumePlayerArea(player, slots)
        if player.dead then return false end
      end
    end

    local x = player.maxHp - player.hp
    if x > 0 then
      room:recover({
        who = player,
        num = x,
        recoverBy = player,
        skillName = self.name,
      })
      if player.dead then return false end
    end

    room:setPlayerMark(player, self.name, #choices)

    local skills = table.contains(choices, "os__fuxi2") and "" or "-os__chihui|"
    room:handleAddLoseSkills(player, skills .. "-os__fuxi|os__huangzhu|os__liyuan|os__jifa", nil, true, false)
    if player.general == "os_if__caoang" then
      player.general = "os_if_huan__caoang"
      room:broadcastProperty(player, "general")
    end
    if player.deputyGeneral == "os_if__caoang" then
      player.deputyGeneral = "os_if_huan__caoang"
      room:broadcastProperty(player, "deputyGeneral")
    end

  end,
}
Fk:loadTranslationTable{
  ["os__fuxi"] = "赴曦",
  [":os__fuxi"] = "持恒技，当你进入濒死状态时，或你的装备栏均被废除后，你可以选择一至两项并“入幻”："..
    "1.获得一个额外回合；2.此次“入幻”时保留〖炽灰〗；3.将手牌摸至X张（X为你的体力上限且至多为5）；"..
    "4.恢复所有装备栏（你的装备栏均被废除时方可选择此项）。",

  ["#os__fuxi-choice"] = "是否发动 赴曦，选择1-2项依序执行，然后“入幻”",
  ["os__fuxi1"] = "获得额外回合",
  ["os__fuxi2"] = "保留〖炽灰〗",
  ["os__fuxi3"] = "将手牌摸至%arg张",
  ["os__fuxi4"] = "恢复所有装备栏",

  ["$os__fuxi1"] = "",
  ["$os__fuxi2"] = "",
}

osFuxi.permanent_skill = true
ifcaoang:addSkill(osFuxi)


local huancaoang = General(extension, "os_if_huan__caoang", "wei", 3, 4)
huancaoang.hidden = true

Fk:loadTranslationTable{
  ["os_if_huan__caoang"] = "幻曹昂",
  ["#os_if_huan__caoang"] = "穿时寻冀",
  --["~os_if_huan__caoang"] = "",
}

local osHuangzhu = fk.CreateTriggerSkill{
  name = "os__huangzhu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(self) and target == player then
      if player.phase == Player.Start then
        return table.find(player.equipSlots, function (slot)
          return table.contains(player.sealedSlots, slot)
        end)
      elseif player.phase == Player.Play then
        return #player:getTableMark("@$os__huangzhu") > 0 and table.find(player.equipSlots, function (slot)
          return table.contains(player.sealedSlots, slot)
        end)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if player.phase == Player.Start then
      local all_choices = {
        "WeaponSlot",
        "ArmorSlot",
        "DefensiveRideSlot",
        "OffensiveRideSlot",
        "TreasureSlot"
      }
      local choices = {}
      for i = 1, 5, 1 do
        if table.contains(player.sealedSlots, all_choices[i]) then
          table.insert(choices, all_choices[i])
        end
      end
      table.insert(all_choices, "Cancel")
      table.insert(choices, "Cancel")
      local choice = player.room:askForChoice(player, choices, self.name, "#os__huangzhu-choice", false, all_choices)
      if choice ~= "Cancel" then
        self.cost_data = choice
        return true
      end
    elseif player.phase == Player.Play then
      return player.room:askForSkillInvoke(player, self.name, nil, "#os__huangzhu-invoke")
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      local subtype = Util.convertSubtypeAndEquipSlot(self.cost_data)
      local cards = table.filter(room.discard_pile, function(id) return Fk:getCardById(id).sub_type == subtype end)
      if #cards == 0 then
        cards = table.filter(room.draw_pile, function(id) return Fk:getCardById(id).sub_type == subtype end)
      end
      if #cards == 0 then
        cards = table.filter(room.discard_pile, function(id) return Fk:getCardById(id).type == Card.TypeEquip end)
      end
      if #cards == 0 then
        cards = table.filter(room.draw_pile, function(id) return Fk:getCardById(id).type == Card.TypeEquip end)
      end
      if #cards == 0 then return false end
      local card = Fk:getCardById(table.random(cards))
      local card_names = player:getTableMark("@$os__huangzhu")
      if table.insertIfNeed(card_names, card.name) then
        room:setPlayerMark(player, "@$os__huangzhu", card_names)
      end
      room:obtainCard(player, card, true, fk.ReasonJustMove, player.id, self.name)
    else
      local card_names = player:getTableMark("@$os__huangzhu")
      local names = {}
      local choices = table.filter(card_names, function(name)
        local card = Fk:cloneCard(name)
        return table.contains(player.sealedSlots, Util.convertSubtypeAndEquipSlot(card.sub_type))
      end)
      if #choices == 0 then return false end
      local name1 = room:askForChoice(player, choices, self.name)
      table.insert(names, name1)
      local subtype = Fk:cloneCard(name1).sub_type
      choices = table.filter(choices, function(name)
        local card = Fk:cloneCard(name)
        return card.sub_type ~= subtype and table.contains(player.sealedSlots, Util.convertSubtypeAndEquipSlot(card.sub_type))
      end)
      if #choices > 0 then
        table.insert(choices, "Cancel")
        name1 = room:askForChoice(player, choices, self.name)
        if name1 ~= "Cancel" then
          table.insert(names, name1)
        end
      end
      local all_slots = {
        "WeaponSlot",
        "ArmorSlot",
        "DefensiveRideSlot",
        "OffensiveRideSlot",
        "TreasureSlot"
      }
      for _, slot in ipairs(all_slots) do
        local name = player:getMark("@os__huangzhu_" .. slot)
        if type(name) == "string" then
          room:setPlayerMark(player, "@os__huangzhu_" .. slot, 0)
          local card = Fk:cloneCard(name)
          if card then
            card:onUninstall(room, player)
          end
        end
      end
      for _, name in ipairs(names) do
        local card = Fk:cloneCard(name)
        if card then
          room:setPlayerMark(player, "@os__huangzhu_" .. Util.convertSubtypeAndEquipSlot(card.sub_type), name)
          card:onInstall(room, player)
        end
      end
    end
  end,

  refresh_events = {fk.AreaResumed},
  can_refresh = function(self, event, target, player, data)
    return player == target
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, slot in ipairs(data.slots) do
      local name = player:getMark("@os__huangzhu_" .. slot)
      if type(name) == "string" then
        room:setPlayerMark(player, "@os__huangzhu_" .. slot, 0)
        local card = Fk:cloneCard(name)
        if card then
          card:onUninstall(room, player)
        end
      end
    end
  end,

  on_lose = function (self, player)
    local room = player.room
    room:setPlayerMark(player, "@$os__huangzhu", 0)
    local all_slots = {
      "WeaponSlot",
      "ArmorSlot",
      "DefensiveRideSlot",
      "OffensiveRideSlot",
      "TreasureSlot"
    }
    for _, slot in ipairs(all_slots) do
      local name = player:getMark("@os__huangzhu_" .. slot)
      if type(name) == "string" then
        room:setPlayerMark(player, "@os__huangzhu_" .. slot, 0)
        local card = Fk:cloneCard(name)
        if card then
          card:onUninstall(room, player)
        end
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["os__huangzhu"] = "煌烛",
  [":os__huangzhu"] = "准备阶段，你可以选择一个已被废除的装备栏，从牌堆或弃牌堆中随机获得一张对应副类别的装备牌"..
    "（若无则随机获得一张装备牌），并记录此牌牌名。"..
    "出牌阶段开始时，你可以选择或变更至多两个已记录且对应装备栏已被废除的装备牌牌名（每种副类别限一个），"..
    "视为拥有这些装备牌的技能直到此装备栏被恢复。",

  ["#os__huangzhu-choice"] = "是否发动 煌烛，选择一个已被废除的装备栏",
  ["@$os__huangzhu"] = "煌烛",
  ["#os__huangzhu-invoke"] = "是否发动 煌烛，视为拥有至多2张已记录的装备牌的技能",

  ["@os__huangzhu_WeaponSlot"] = "",
  ["@os__huangzhu_ArmorSlot"] = "",
  ["@os__huangzhu_DefensiveRideSlot"] = "",
  ["@os__huangzhu_OffensiveRideSlot"] = "",
  ["@os__huangzhu_TreasureSlot"] = "",


  ["$os__huangzhu1"] = "",
  ["$os__huangzhu2"] = "",
}

huancaoang:addSkill(osHuangzhu)

local osLiyuan = fk.CreateViewAsSkill{
  name = "os__liyuan",
  anim_type = "offensive",
  prompt = "#os__liyuan-viewas",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    if #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    return card.type == Card.TypeEquip and
      table.contains(Self.sealedSlots, Util.convertSubtypeAndEquipSlot(card.sub_type))
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function(self, player, use)
    use.extraUse = true
  end,
  enabled_at_play = function(self, player)
    return table.find(player.equipSlots, function (slot)
      return table.contains(player.sealedSlots, slot)
    end)
  end,
  enabled_at_response = function(self, player, response)
    return table.find(player.equipSlots, function (slot)
      return table.contains(player.sealedSlots, slot)
    end)
  end
}
local osLiyuanTrigger = fk.CreateTriggerSkill{
  name = "#os__liyuan_trigger",
  events = {fk.CardUsing, fk.CardResponding},
  main_skill = osLiyuan,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(osLiyuan) and table.contains(data.card.skillNames, osLiyuan.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, osLiyuan.name)
  end,
}
local osLiyuanTargetMod = fk.CreateTargetModSkill{
  name = "#os__liyuan_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return table.contains(card.skillNames, osLiyuan.name)
  end,
  bypass_distances = function(self, player, skill, card)
    return table.contains(card.skillNames, osLiyuan.name)
  end,
}
Fk:loadTranslationTable{
  ["os__liyuan"] = "离渊",
  [":os__liyuan"] = "你可以将一张对应装备栏已被废除的装备牌当普【杀】使用或打出（无距离、次数限制，不计次数）。"..
    "当你以此法使用或打出牌时，你摸两张牌。",
  ["#os__liyuan_trigger"] = "离渊",

  ["#os__liyuan-viewas"] = "发动 离渊，将1张对应装备栏已被废除的装备牌当普【杀】使用或打出，然后摸2张牌",

  ["$os__liyuan1"] = "",
  ["$os__liyuan2"] = "",
}

osLiyuan:addRelatedSkill(osLiyuanTrigger)
osLiyuan:addRelatedSkill(osLiyuanTargetMod)
huancaoang:addSkill(osLiyuan)

local osJifa = fk.CreateTriggerSkill{
  name = "os__jifa",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getMark(osFuxi.name)
    if x > 0 then
      room:changeMaxHp(player, -x)
      if player.dead then return false end
    end

    x = player.maxHp - player.hp
    if x > 0 then
      room:recover({
        who = player,
        num = x,
        recoverBy = player,
        skillName = self.name,
      })
      if player.dead then return false end
    end
    local choices = {}
    if player:hasSkill(osHuangzhu, true) then
      table.insert(choices, osHuangzhu.name)
    end
    if player:hasSkill(osLiyuan, true) then
      table.insert(choices, osLiyuan.name)
    end
    local skills = ""
    if #choices == 2 then
      table.removeOne(choices, room:askForChoice(player, choices, self.name, "#os__jifa-choice", true))
      skills = "-" .. choices[1] .. "|"
    end
    room:handleAddLoseSkills(player, skills .. "-os__jifa|os__chihui|os__fuxi", nil, true, false)
    if player.general == "os_if_huan__caoang" then
      player.general = "os_if__caoang"
      room:broadcastProperty(player, "general")
    end
    if player.deputyGeneral == "os_if_huan__caoang" then
      player.deputyGeneral = "os_if__caoang"
      room:broadcastProperty(player, "deputyGeneral")
    end
  end,
}
Fk:loadTranslationTable{
  ["os__jifa"] = "冀筏",
  [":os__jifa"] = "锁定技，当你进入濒死状态时，你减X点体力上限（X为你上次发动〖赴曦〗时选择的项数），"..
    "选择此次“退幻”时保留〖煌烛〗或〖离渊〗，然后“退幻”。",

  ["#os__jifa-choice"] = "冀筏：选择本次“退幻”时保留的技能",
  ["$os__jifa1"] = "",
  ["$os__jifa2"] = "",
}

huancaoang:addSkill(osJifa)








return extension
