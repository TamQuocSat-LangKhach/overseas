local extension = Package("overseas_wuxia")
extension.extensionName = "overseas"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["overseas_wuxia"] = "国际服-武侠篇",
}

local os__tongyuan = General(extension, "os__tongyuan", "qun", 4)

local os__chaofeng = fk.CreateViewAsSkill{
  name = "os__chaofeng",
  pattern = "slash,jink",
  card_num = 1,
  prompt = "#os__chaofeng-prompt",
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    local _c = Fk:getCardById(to_select)
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    else
      return false
    end
    return (Fk.currentResponsePattern == nil and Self:canUse(c)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
  end,
  interaction = function(self)
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(allCardNames, card.name) and (card.trueName == "slash" or card.name == "jink") and ((Fk.currentResponsePattern == nil and Self:canUse(card)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) and not Self:prohibitUse(card) then
        table.insert(allCardNames, card.name)
      end
    end
    return UI.ComboBox { choices = allCardNames }
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
    return player:canUse(Fk:cloneCard("slash"))
  end,
  enabled_at_response = function(self, player)
    return Fk.currentResponsePattern and table.find({"slash", "jink"}, function(name)
      return Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard(name))
    end)
  end,
}
local os__chaofeng_pd = fk.CreateTriggerSkill{
  name = "#os__chaofeng_pd",
  events = {fk.EventPhaseStart},
  mute = true,
  main_skill = os__chaofeng,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local availableTargets = table.map(
      table.filter(player.room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end),
      Util.IdMapper
    )
    if #availableTargets == 0 then return false end
    local targets = player.room:askForChoosePlayers(player, availableTargets, 1, 3, "#os__chaofeng-ask", self.name, true)
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "os__chaofeng", "offensive")
    player:broadcastSkillInvoke("os__chaofeng")
    local targets = table.map(self.cost_data, Util.Id2PlayerMapper)
    local pd = U.jointPindian(player, targets, self.name)
    if pd.winner then
      table.insert(targets, player)
      table.removeOne(targets, pd.winner)
      room:useVirtualCard("fire__slash", nil, pd.winner, targets, self.name, true)
    end
  end,
}
os__chaofeng:addRelatedSkill(os__chaofeng_pd)

local os__chuanshu = fk.CreateTriggerSkill{
  name = "os__chuanshu",
  events = {fk.EventPhaseStart},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
    and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, 1, "#os__chuanshu-ask", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos = tos}
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    room:addTableMark(to, "@os__chuanshu", player.general)
    room:addTableMark(to, "_os__chuanshu_slash", player.id)
    room:addTableMark(player, "_os__chuanshu", {to.id, player.general})
  end,
}

local os__chuanshu_delay = fk.CreateTriggerSkill{
  name = "#os__chuanshu_delay",
  events = {fk.DamageCaused, fk.PindianCardsDisplayed},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      if player:getMark("@os__chuanshu") == 0 then return false end
      local parentUseEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if parentUseEvent then
        local parentUseData = parentUseEvent.data[1]
        if parentUseData.card == data.card and (parentUseData.extra_data or {}).os__chuanshuUser == player.id then
          local froms = (parentUseData.extra_data or {}).os__chuanshuSource
          return #froms > 1 or froms[1] ~= data.to.id
        end
      end
    else
      return player:getMark("@os__chuanshu") ~= 0 and (data.from == player or table.contains(data.tos, player))
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke("os__chuanshu")
      local parentUseData = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if parentUseData == nil then return end
      local invoker = {}
      local froms = (parentUseData.data[1].extra_data or {}).os__chuanshuSource
      table.removeOne(froms, data.to.id)
      data.damage = data.damage + #froms
      for _, pid in ipairs(froms) do
        local p = room:getPlayerById(pid)
        if not p.dead and pid ~= player.id then
          p:drawCards(data.damage, "os__chuanshu")
        end
      end
    else
      room:notifySkillInvoked(player, self.name, "special")
      player:broadcastSkillInvoke("os__chuanshu")
      local num = 3 * #player:getMark("@os__chuanshu")
      room:changePindianNumber(data, player, num, self.name)
    end
  end,

  refresh_events = {fk.TurnStart, fk.PreCardUse, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    if target ~= player then return false end
    if event == fk.TurnStart or event == fk.BuryVictim then
      return player:getMark("_os__chuanshu") ~= 0
    elseif event == fk.PreCardUse then
      return player:getMark("_os__chuanshu_slash") ~= 0 and data.card.trueName == "slash"
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart or event == fk.BuryVictim then
      for _, dat in ipairs(player:getMark("_os__chuanshu")) do
        room:removeTableMark(room:getPlayerById(dat[1]), "@os__chuanshu", dat[2])
      end
      room:setPlayerMark(player, "_os__chuanshu", 0)
    elseif event == fk.PreCardUse then
      data.extra_data = data.extra_data or {}
      data.extra_data.os__chuanshuUser = player.id
      data.extra_data.os__chuanshuSource = player:getMark("_os__chuanshu_slash")
      room:setPlayerMark(player, "_os__chuanshu_slash", 0)
    end
  end,
}
os__chuanshu:addRelatedSkill(os__chuanshu_delay)

os__tongyuan:addSkill(os__chaofeng)
os__tongyuan:addSkill(os__chuanshu)

Fk:loadTranslationTable{
  ["os__tongyuan"] = "童渊",
  ["#os__tongyuan"] = "凤鸣麟出",
  ["illustrator:os__tongyuan"] = "M云涯",

  ["os__chaofeng"] = "朝凤",
  [":os__chaofeng"] = "①你可将【杀】当【闪】、【闪】当任意【杀】使用或打出。②出牌阶段开始时，你可与至多三名角色共同拼点：赢的角色视为对所有没赢的角色使用一张火【杀】。" ..
  "<br/><font color='grey'>#\"<b>共同拼点</b>\"<br/>所有角色一起比大小（而非“同时拼点”：发起者和其余角色两两各比大小）。",
  ["os__chuanshu"] = "传术",
  [":os__chuanshu"] = "限定技，准备阶段开始时，你可选择一名角色：直到你下回合开始，其拼点牌点数+3，且其使用下一张【杀】对你以外的角色造成伤害+1，且此【杀】造成伤害时，若其不为你，你摸等同伤害值的牌。",

  ["#os__chaofeng_pd"] = "朝凤",
  ["#os__chaofeng-ask"] = "朝凤：你可与至多三名角色共同拼点，赢的角色视为对没赢的角色使用火【杀】",
  ["#os__chaofeng-prompt"] = "朝凤：你可将【杀】当【闪】、【闪】当任意【杀】使用或打出",
  ["#os__chuanshu-ask"] = "传术：选择一名角色：其拼点牌点数+3且下一张【杀】伤害+1直到你下回合开始",
  ["@os__chuanshu"] = "传术",
  ["#os__chuanshu_delay"] = "传术",

  ["$os__chaofeng1"] = "枪出惊百鸟，技现震诸雄。",
  ["$os__chaofeng2"] = "出如鸾凤高翱，收若百鸟归林。",
  ["$os__chuanshu1"] = "此术集百家之法，当传万世。",
  ["$os__chuanshu2"] = "某虽无名于世，此术可传之万年。",
  ["~os__tongyuan"] = "隐居山水，空老病榻。",
}

local wangyue = General(extension, "wangyue", "qun", 4)

local os__yulong = fk.CreateTriggerSkill{
  name = "os__yulong",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.firstTarget and data.card.trueName == "slash" and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local availableTargets = {}
    for _, p in ipairs(room.alive_players) do
      if table.contains(AimGroup:getAllTargets(data.tos), p.id) and player:canPindian(p) then
        table.insert(availableTargets, p.id)
      end
    end

    if #availableTargets == 0 then
      return false
    end
    if #availableTargets == 1 then
      self.cost_data = availableTargets[1]
      return room:askForSkillInvoke(player, self.name)
    else
      local result = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__yulong-ask", self.name, true)
      if #result > 0 then
        self.cost_data = result[1]
        return true
      else
        return false
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(self.cost_data)
    local pd = player:pindian({target}, self.name, nil)
    if pd.results[self.cost_data].winner == player then
      data.card.extra_data = data.card.extra_data or {}
      data.card.extra_data.os__yulong = true
      if pd.fromCard.color == Card.Black then
        data.card.extra_data.os__yulongBlack = true
      elseif pd.fromCard.color == Card.Red then
        --data.disresponsive = true
        data.card.extra_data.os__yulongRed = true
      end
    end
  end,

  refresh_events = {fk.Damage, fk.DamageCaused, fk.TargetConfirmed},
  can_refresh = function(self, event, target, player, data)
    if not (target == player and data.card and data.card.trueName == "slash") then return false end
    if event == fk.TargetConfirmed then
      return (data.card.extra_data or {}).os__yulongRed == true
    else
      local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      local invoke = parentUseData and (parentUseData.data[1].card.extra_data or {}).os__yulong == true
      if not invoke then return false end
      if event == fk.DamageCaused then
        return (parentUseData.data[1].card.extra_data or {}).os__yulongBlack == true
      else
        return (parentUseData.data[1].card.extra_data or {}).os__yulongAddHistory == nil
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      player:addCardUseHistory("slash", -1)
      player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard).data[1].card.extra_data.os__yulongAddHistory = true
    elseif event == fk.DamageCaused then
      data.damage = data.damage + 1
    else
      data.disresponsive = true
    end
  end,
}

local os__jianming = fk.CreateTriggerSkill{
  name = "os__jianming",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardUseDeclared, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card.trueName == "slash" and data.card.suit ~= Card.NoSuit then
      local suitsRecorded = player:getTableMark("@os__jianming-turn")
      return not table.contains(suitsRecorded, "log_" .. data.card:getSuitString())
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    local suitsRecorded = player:getTableMark("@os__jianming-turn")
    table.insert(suitsRecorded, "log_" .. data.card:getSuitString())
    player.room:setPlayerMark(player, "@os__jianming-turn", suitsRecorded)
  end,
}

wangyue:addSkill(os__yulong)
wangyue:addSkill(os__jianming)

Fk:loadTranslationTable{
  ["wangyue"] = "王越",
  ["#wangyue"] = "驭龙在天",
  ["illustrator:wangyue"] = "鱼仔",

  ["os__yulong"] = "驭龙",
  [":os__yulong"] = "当你使用【杀】指定第一个目标后，你可与其中一名目标拼点。若你：赢，若此【杀】造成伤害则不计入次数，且你此次的拼点牌为：黑色，此【杀】的伤害+1；红色，此【杀】不可被响应。",
  ["os__jianming"] = "剑鸣",
  [":os__jianming"] = "锁定技，每回合每花色限一次，当你使用或打出一种花色的【杀】时，你摸一张牌。",

  ["#os__yulong-ask"] = "驭龙：你可与一名目标拼点",
  ["@os__jianming-turn"] = "剑鸣",

  ["$os__yulong1"] = "三尺青锋，为君驭六龙，定九州！",
  ["$os__yulong2"] = "十年砺剑，当率千军之众，堪万夫之雄！",
  ["$os__jianming1"] = "弹剑作谱，鸣之铮铮。",
  ["$os__jianming2"] = "剑鸣凄凄，穿心刺骨。",
  ["~wangyue"] = "汉室中兴，不系于吾一人……",
}

local os__xia__xushu = General(extension, "os__xia__xushu", "qun", 4)

local os__jiange = fk.CreateViewAsSkill{
  name = "os__jiange",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    c:addSubcards(cards)
    c.skillName = self.name
    return c
  end,
  before_use = function(self, player, use)
    if player.phase == Player.NotActive then player:drawCards(1, self.name) end
    use.extraUse = true
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  enabled_at_response = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
}
local os__jiange_buff = fk.CreateTargetModSkill{
  name = "#os__jiange_buff",
  residue_func = function(self, player, skill, scope, card)
    return (player:hasSkill(self) and card and table.contains(card.skillNames, os__jiange.name)) and 999 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return (player:hasSkill(self) and card and table.contains(card.skillNames, os__jiange.name)) and 999 or 0
  end,
}
os__jiange:addRelatedSkill(os__jiange_buff)

local os__xiawang = fk.CreateTriggerSkill{
  name = "os__xiawang",
  events = {fk.Damaged},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target:distanceTo(player) < 2 and data.card and data.card.color == Card.Black and not (target.dead or player.dead) and data.from and not (data.from.dead or data.from == player)
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askForUseCard(player, "slash", nil, "#os__xiawang-ask:" .. data.from.id, true, { exclusive_targets = {data.from.id}, bypass_distances = true })
    if use then
      self.cost_data = use
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = self.cost_data
    use.extra_data = use.extra_data or {}
    use.extra_data.os__xiawangUser = player.id
    room:useCard(use)
    if player:getMark("_os__xiawang-phase") > 0 then
      data.os__xiawang = true
    end
  end,

  refresh_events = {fk.Damage, fk.DamageFinished},
  can_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      return parentUseData and (parentUseData.data[1].extra_data or {}).os__xiawangUser == player.id
    else
      return data.os__xiawang == true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      player.room:addPlayerMark(player, "_os__xiawang-phase")
    else
      local current = player.room.logic:getCurrentEvent()
      local use_event = current:findParent(GameEvent.UseCard)
      if not use_event then return end
      local phase_event = use_event:findParent(GameEvent.Phase)
      if not phase_event then return end
      use_event:addExitFunc(function()
        phase_event:shutdown()
      end)
    end
  end,
}

os__xia__xushu:addSkill(os__jiange)
os__xia__xushu:addSkill(os__xiawang)

Fk:loadTranslationTable{
  ["os__xia__xushu"] = "侠徐庶",
  ["#os__xia__xushu"] = "仗剑为侠",
  ["illustrator:os__xia__xushu"] = "zoo",

  ["os__jiange"] = "剑歌",
  [":os__jiange"] = "每回合限一次，你可将一张非基本牌当【杀】使用或打出（无距离与次数限制且不计入次数）。若此时为你的回合外，你摸一张牌。",
  ["os__xiawang"] = "侠望",
  [":os__xiawang"] = "当至你距离不大于1的角色受到黑色牌造成的伤害后，你可对伤害来源使用【杀】。若此【杀】造成了伤害，则在当前伤害结束结算后结束当前阶段。",

  ["#os__xiawang-ask"] = "你可对 %src 使用【杀】。若此【杀】造成了伤害，则在当前伤害事件结束结算后结束当前阶段",

  ["$os__jiange1"] = "纵剑为舞，击缶而歌！",
  ["$os__jiange2"] = "辞亲历山野，仗剑唱大风！",
  ["$os__xiawang1"] = "天下兴亡，侠客当为之己任。",
  ["$os__xiawang2"] = "隐居江湖之远，敢争天下之先！",
  ["~os__xia__xushu"] = "天下为公……",
}

local liyan = General(extension, "liyan", "qun", 4)

local os__zhenhu = fk.CreateTriggerSkill{
  name = "os__zhenhu",
  events = {fk.TargetSpecifying},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and data.card.is_damage_card and
      data.firstTarget and table.find(player.room:getOtherPlayers(player, false), function(p) return player:canPindian(p) end)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    local room = player.room
    local availableTargets = table.map(
      table.filter(room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end),
      Util.IdMapper
    )
    if #availableTargets == 0 then return false end
    local targets = room:askForChoosePlayers(player, availableTargets, 1, 3, "#os__chaofeng-ask", self.name, false)
    if #targets == 0 then return false end
    local pd = U.jointPindian(player, table.map(targets, Util.Id2PlayerMapper), self.name)
    if pd.winner == player then
      data.extra_data = data.extra_data or {}
      data.extra_data.os__zhenhu = targets
    else
      room:loseHp(player, 1, self.name)
    end
  end,

  refresh_events = {fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    if target ~= player then return false end
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    return parentUseData and type((parentUseData.data[1].extra_data or {}).os__zhenhu) == "table" and table.contains((parentUseData.data[1].extra_data or {}).os__zhenhu, data.to.id)
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}

local os__lvren = fk.CreateTriggerSkill{
  name = "os__lvren",
  anim_type = "offensive",
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    local availableTargets = table.map(table.filter(player.room.alive_players, function(p)
      return p:getMark("@@os__blade") > 0 and not table.contains(TargetGroup:getRealTargets(data.tos), p.id)
    end), Util.IdMapper)
    if #availableTargets == 0 then return false end
    local targets = player.room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__lvren-targets", self.name, true)
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, self.cost_data)
    table.insert(data.tos, self.cost_data)
    room:removePlayerMark(room:getPlayerById(self.cost_data[1]), "@@os__blade")
  end,

  refresh_events = {fk.DamageCaused, fk.PindianCardsDisplayed}, --要改
  can_refresh = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      return target == player and player:hasSkill(self) and data.to:getMark("@@os__blade") == 0 and data.to ~= player
    else
      return player:hasSkill(self) and (data.from == player or table.contains(data.tos, player))
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(self.name)
    if event == fk.DamageCaused then
      room:addPlayerMark(data.to, "@@os__blade")
    else
      room:changePindianNumber(data, player, 2 * (#data.tos + 1), self.name)
    end
  end,
}

liyan:addSkill(os__zhenhu)
liyan:addSkill(os__lvren)

Fk:loadTranslationTable{
  ["liyan"] = "李彦",
  ["#liyan"] = "暴虎冯河",

  ["os__zhenhu"] = "震虎",
  [":os__zhenhu"] = "当你使用伤害牌指定第一个目标时，你可摸一张牌并与至多三名其他角色共同拼点：若你赢，此牌对没赢的角色造成伤害+1。若你没赢，你失去1点体力。" ..
  "<br/><font color='grey'>#\"<b>共同拼点</b>\"<br/>所有角色一起比大小（而非“同时拼点”：发起者和其余角色两两各比大小）。",
  ["os__lvren"] = "履刃",
  [":os__lvren"] = "①当你对其他角色造成伤害时，若其没有“刃”，你令其获得1枚“刃”。②当你使用伤害牌选择目标后，可令一名有“刃”的角色也成为目标，然后其弃1枚“刃”。③你拼点时，每有一名角色，你的拼点牌点数+2。",

  ["@@os__blade"] = "刃",
  ["#os__lvren-targets"] = "履刃：你可令一有“刃”的角色也成为目标，然后其弃“刃”",

  ["$os__zhenhu1"] = "戟出势如虎，百兽尽皆服！",
  ["$os__zhenhu2"] = "横戟冲阵，敌纵为猛虎凶豺，亦不敢前！",
  ["$os__lvren1"] = "坚甲利刃，破之如鲁缟！",
  ["$os__lvren2"] = "攻城破阵，如履平地！",
  ["~liyan"] = "戾气入髓，不可再起杀心……",
}

local xiahouzie = General(extension, "xiahouzie", "qun", 3, 4, General.Female)

local os__xuechang = fk.CreateActiveSkill{
  name = "os__xuechang",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Self:canPindian(Fk:currentRoom():getPlayerById(to_select)) and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      if target:isNude() then return false end
      local cid = room:askForCardChosen(player, target, "he", self.name)
      room:obtainCard(player, cid, false)
      if Fk:getCardById(cid).type == Card.TypeEquip then
        room:useVirtualCard("slash", nil, player, target, self.name, true)
      end
    else
      room:damage{
        from = target,
        to = player,
        damage = 1,
        skillName = self.name,
      }
      room:addPlayerMark(player, "_os__xuechang+" .. target.id, 1)
    end
  end,
}
local os__xuechang_damage = fk.CreateTriggerSkill{
  name = "#os__xuechang_damage",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("_os__xuechang+" .. data.to.id) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("_os__xuechang+" .. data.to.id)
    player.room:setPlayerMark(player, "_os__xuechang+" .. data.to.id, 0)
  end,
}
os__xuechang:addRelatedSkill(os__xuechang_damage)

local os__duoren = fk.CreateTriggerSkill{
  name = "os__duoren",
  events = {fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.damage and data.damage.from == player 
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    local skills = table.map(table.filter(target.player_skills, function(s)
        return s:isPlayerSkill(target) and not s.lordSkill
      end), Util.NameMapper) or {}
    local names = table.concat(skills, "|")
    room:handleAddLoseSkills(player, names, nil)
    room:setPlayerMark(player, "@os__duoren", target.general)
    room:setPlayerMark(player, "_os__duoren", names)
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return data.damage and data.damage.from and player:hasSkill(self) and data.damage.from == player and player:getMark("_os__duoren") ~= 0 and target ~= player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skills = string.split(player:getMark("_os__duoren"), "|")
    local names = table.map(skills, function(s)
      return "-" .. s
    end)
    room:handleAddLoseSkills(player, names, nil)
    room:setPlayerMark(player, "@os__duoren", 0)
    room:setPlayerMark(player, "_os__duoren", 0)
  end,
}

xiahouzie:addSkill(os__xuechang)
xiahouzie:addSkill(os__duoren)

Fk:loadTranslationTable{
  ["xiahouzie"] = "夏侯紫萼",
  ["#xiahouzie"] = "孤草飘零",
  ["illustrator:xiahouzie"] = "M云涯",

  ["os__xuechang"] = "血偿",
  [":os__xuechang"] = "出牌阶段限一次，你可与一名角色拼点，若你赢，你获得其一张牌，若此牌为装备牌，则你视为对其使用一张【杀】；若你没赢，你受到其造成的1点伤害，你下次对其造成的伤害+1。",
  ["os__duoren"] = "夺刃",
  [":os__duoren"] = "当你杀死一名角色后，你可减1点体力上限，获得其除主公技以外的所有技能。当你对其他角色造成伤害令其进入濒死状态时，你失去以此法获得的技能。",

  ["#os__xuechang_damage"] = "血偿",
  ["@os__duoren"] = "夺刃",

  ["$os__xuechang1"] = "风尘难掩忠魂血，杀尽宦祸不得偿！",
  ["$os__xuechang2"] = "霜刃绚练，血舞婆娑。",
  ["$os__duoren1"] = "便以汝血，封汝之刀！",
  ["$os__duoren2"] = "血婆娑之剑，从不会沾无辜之血。",
  ["~xiahouzie"] = "祖父，紫萼不能为您昭雪了……",
}

local zhaoe = General(extension, "zhaoe", "qun", 3, 3, General.Female)

local os__yanshi = fk.CreateTriggerSkill{
  name = "os__yanshi",
  mute = true,
  events = {fk.GameStart, fk.Damaged, fk.Damage, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.GameStart then
      return true
    elseif event == fk.Damaged then
      return (target == player or player:getMark("_os__yanshi") == target.id) and not target.dead and data.from and not data.from.dead and data.from:getMark("@@os__oath") == 0 and data.from ~= player and data.from ~= player.room:getPlayerById(player:getMark("_os__yanshi"))
    elseif event == fk.Damage then
      return target == player and not data.to.dead and data.to:getMark("@@os__oath") > 0
    else
      return target == player and data.to:getMark("@@os__oath") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#os__yanshi-choose", self.name, false)
      local to
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "special")
      room:setPlayerMark(player, "@os__yanshi", to.general)
      room:setPlayerMark(player, "_os__yanshi", to.id)
    elseif event == fk.Damaged then
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "masochism")
      room:addPlayerMark(data.from, "@@os__oath")
    elseif event == fk.Damage then
      player:drawCards(data.damage, self.name)
      room:removePlayerMark(data.to, "@@os__oath")
    else
      player:broadcastSkillInvoke(self.name, 3)
      room:notifySkillInvoked(player, self.name, "offensive")
      data.damage = data.damage + 1
    end
  end,
}
local os__yanshi_distance = fk.CreateTargetModSkill{
  name = "#os__yanshi_distance",
  bypass_distances = function(self, from, _, _, to)
    if from and from:hasSkill(self) and to then
      return to:getMark("@@os__oath") > 0
    end
  end,
}
os__yanshi:addRelatedSkill(os__yanshi_distance)

local os__renchou = fk.CreateTriggerSkill{
  name = "os__renchou",
  frequency = Skill.Compulsory,
  events = {fk.Death},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self, false, true) or (target ~= player and player:getMark("_os__yanshi") ~= target.id) then return false end 
    local from = player.dead and player.room:getPlayerById(player:getMark("_os__yanshi")) or player
    return from and not from.dead and data.damage and data.damage.from and not data.damage.from.dead and data.damage.from ~= from
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = player.dead and room:getPlayerById(player:getMark("_os__yanshi")) or player 
    room:damage{
      from = from,
      to = data.damage.from,
      damage = from.hp,
      skillName = self.name,
    }
  end,
}

zhaoe:addSkill(os__yanshi)
zhaoe:addSkill(os__renchou)

Fk:loadTranslationTable{
  ["zhaoe"] = "赵娥",
  ["#zhaoe"] = "烈女誓仇",
  ["illustrator:zhaoe"] = "充电JUJU",

  ["os__yanshi"] = "言誓",
  [":os__yanshi"] = "①游戏开始时，你选择一名其他角色。②当你或“言誓”角色受到除你与其以外的角色造成的伤害后，若伤害来源没有“誓”，伤害来源获得1枚“誓”。③你对有“誓”的角色使用牌无距离限制且对其造成的伤害+1。④当你对有“誓”的角色造成伤害后，你摸等同于伤害数的牌并弃其1枚“誓”。",
  ["os__renchou"] = "刃仇",
  [":os__renchou"] = "锁定技，当你或“言誓”角色死亡时，若另一名角色A存活，且来源B不是A，则A对B造成X点伤害（X为A的体力值）。",

  ["#os__yanshi-choose"] = "言誓：请选择一名其他角色",
  ["@os__yanshi"] = "言誓",
  ["@@os__oath"] = "誓",

  ["$os__yanshi1"] = "骨肉至亲，血脉相连。",
  ["$os__yanshi2"] = "挟长持短，昼夜哀酸！",
  ["$os__yanshi3"] = "当以贼血，污此白刃！",
  ["$os__renchou1"] = "塞亡父之冤魂，血三弟之永恨！",
  ["$os__renchou2"] = "禄福夜雪白，都亭朝霞红！",
  ["~zhaoe"] = "乞就刑戮，肃明王法……",
}

local os__xia__lusu = General(extension, "os__xia__lusu", "qun", 4)

local os__kaizeng = fk.CreateTriggerSkill{
  name = "os__kaizeng",
  attached_skill_name = "os__kaizeng_others&",
}
local os__kaizeng_others = fk.CreateActiveSkill{
  name = "os__kaizeng_others&",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  interaction = function(self)
    local choiceList = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(choiceList, card.trueName) and card.type == Card.TypeBasic and not card.is_derived then
        table.insert(choiceList, card.trueName)
      end
    end
    table.insertTable(choiceList, {"trick", "equip"})
    return UI.ComboBox { choices = choiceList }
  end,
  on_use = function(self, room, effect)
    local choice = self.interaction.data
    if not choice then choice = "slash" end--return false end
    local player = room:getPlayerById(effect.from)
    local targets = table.filter(room:getOtherPlayers(player, false), function(p) return p:hasSkill("os__kaizeng") and p:usedSkillTimes("os__kaizeng", Player.HistoryPhase) == 0 end)
    if #targets == 0 then return false end
    local to
    if #targets == 1 then
      to = targets[1]
    else
      to = room:getPlayerById(room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, nil, self.name, false)[1])
    end
    room:doIndicate(player.id, {to.id})
    local cids = room:askForCard(to, 1, 999, false, "os__kaizeng", true, nil, "#os__kaizeng-give:" .. player.id)-- .. "::" .. choice)
    if #cids > 0 then
      to:addSkillUseHistory("os__kaizeng")
      room:notifySkillInvoked(to, "os__kaizeng", "support")
      to:broadcastSkillInvoke("os__kaizeng")
      room:moveCardTo(cids, Player.Hand, player, fk.ReasonGive, self.name, nil, true)
      if #cids > 1 then
        to:drawCards(1, "os__kaizeng")
      end
      local CardType = (choice == "trick" or choice == "equip")
      if table.find(table.map(cids, Util.Id2CardMapper), function(card)
        return (CardType and card:getTypeString() == choice or card.trueName == choice)
      end) then
        local id = room:getCardsFromPileByRule(CardType and ".|.|.|.|.|^" .. choice or "^" .. choice .. "|.|.|.|.|basic")
        if #id > 0 then
          room:obtainCard(to, id[1], false, fk.ReasonPrey)
        end
      end
    end
  end,
}
Fk:addSkill(os__kaizeng_others)

local os__yangming = fk.CreateTriggerSkill{
  name = "os__yangming",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and player:getMark("@os__yangming-phase") ~= 0 
  end,
  on_use = function(self, event, target, player, data)
    local num = #player:getMark("@os__yangming-phase")
    player:drawCards(num, self.name)
    player.room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, num)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and
      player:hasSkill(self, true) and player.phase == Player.Play and
      (type(player:getMark("@os__yangming-phase")) ~= "table" or
      not table.contains(player:getMark("@os__yangming-phase"), data.card:getTypeString() .. "_char"))
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local typesRecorded = player:getTableMark("@os__yangming-phase")
    table.insert(typesRecorded, data.card:getTypeString() .. "_char")
    room:setPlayerMark(player, "@os__yangming-phase", typesRecorded)
  end,
}

os__xia__lusu:addSkill(os__kaizeng)
os__xia__lusu:addSkill(os__yangming)

Fk:loadTranslationTable{
  ["os__xia__lusu"] = "侠鲁肃",
  ["#os__xia__lusu"] = "性善好施",
  ["illustrator:os__xia__lusu"] = "zoo",

  ["os__kaizeng"] = "慨赠",
  [":os__kaizeng"] = "其他角色的出牌阶段限一次，其可秘密指定一种基本牌牌名或非基本牌类别，令你选择是否交给其任意张手牌。若你交给其多于一张牌，你摸一张牌；若其中包含其指定的牌名/类别的牌，你从牌堆中获得一张不同牌名/类别的牌。",
  ["os__yangming"] = "扬名",
  [":os__yangming"] = "出牌阶段结束时，你可摸X张牌，且此回合手牌上限+X（X为你此阶段使用牌的类别数）。",

  ["os__kaizeng_others&"] = "慨赠",
  [":os__kaizeng_others&"] = "出牌阶段限一次，你可指定一种基本牌牌名或非基本牌类别，令侠鲁肃选择是否交给你任意张手牌。若其交给你多于一张牌，其摸一张牌；若其中包含你指定的牌名/类别的牌，其从牌堆中获得一张不同牌名/类别的牌。",
  ["#os__kaizeng-give"] = "慨赠：你可交给 %src 任意张手牌",--，其指定了 %arg",
  ["@os__yangming-phase"] = "扬名",

  ["$os__kaizeng1"] = "此心唯念天下之士，不较细软锱铢！",
  ["$os__kaizeng2"] = "千金散尽何须虑，但求天下俱欢颜！",
  ["$os__yangming1"] = "善名高布凌霄阙，仁德始铸黄金台！",
  ["$os__yangming2"] = "失千金之利，得万人之心！",
  ["~os__xia__lusu"] = "人心不足，巴蛇吞象……",
}

local os__xia__dianwei = General(extension, "os__xia__dianwei", "qun", 4)

local os__liexi = fk.CreateTriggerSkill{
  name = "os__liexi",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = room:askForDiscard(player, 1, #player:getCardIds(Player.Hand) + #player:getCardIds(Player.Equip), true, self.name, true, nil, "#os__liexi-ask", true)
    if #ids > 0 then
      local victim = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1, "#os__liexi-target", self.name, true)
      if #victim > 0 then
        self.cost_data = {victim[1], ids}
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = self.cost_data[2]
    local target = room:getPlayerById(self.cost_data[1])
    room:throwCard(ids, self.name, player)
    if #ids > target.hp then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    else
      room:damage{
        from = target,
        to = player,
        damage = 1,
        skillName = self.name,
      }
    end
    if target.dead then return false end
    if not table.every(ids, function(id)
      return Fk:getCardById(id).sub_type ~= Card.SubtypeWeapon
    end) then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}

local os__shezhong = fk.CreateTriggerSkill{
  name = "os__shezhong",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) or player.phase ~= Player.Finish then return false end
    local room = player.room
    if table.find(room.alive_players, function(p)
      return p:getMark("_os__shezhong_damaged-turn") > 0
    end) then
      return true
    end
    if player:getMark("_os__shezhong_damage_others-turn") > 0 then return true end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("_os__shezhong_damage_others-turn") > 0 then
      local num = player:getMark("_os__shezhong_damage-turn")
      local victims = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, num, "#os__shezhong1-target:::" .. tostring(num), self.name, true)
      if #victims > 0 then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          if table.contains(victims, p.id) then
            room:addPlayerMark(p, "@os__shezhong")
          end
        end
      end
    end
    local availableTargets = table.map(table.filter(room.alive_players, function(p)
      return p:getMark("_os__shezhong_damaged-turn") > 0
    end), Util.IdMapper)
    if #availableTargets > 0 then
      local target = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__shezhong2-target", self.name, true)
      if #target > 0 then
        local to = room:getPlayerById(target[1])
        local num = math.min(to.hp, 5) - player:getHandcardNum()
        if num > 0 then player:drawCards(num, self.name) end
      end
    end
  end,

  refresh_events = {fk.Damage, fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    if target ~= player or player.phase == Player.NotActive then return false end
    if event == fk.Damaged then return data.from ~= nil and not data.from.dead else return true end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      player.room:addPlayerMark(player, "_os__shezhong_damage-turn", data.damage)
      if data.to ~= player then player.room:setPlayerMark(player, "_os__shezhong_damage_others-turn", 1) end
    else
      player.room:setPlayerMark(data.from, "_os__shezhong_damaged-turn", 1)
    end
  end,
}
local os__shezhong_draw = fk.CreateTriggerSkill{
  name = "#os__shezhong_draw",
  mute = true,
  anim_type = "negative",
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@os__shezhong") > 0 and data.n > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = math.max(data.n - player:getMark("@os__shezhong"), 0)
    player.room:setPlayerMark(player, "@os__shezhong", 0)
  end,
}
os__shezhong:addRelatedSkill(os__shezhong_draw)

os__xia__dianwei:addSkill(os__liexi)
os__xia__dianwei:addSkill(os__shezhong)

Fk:loadTranslationTable{
  ["os__xia__dianwei"] = "侠典韦",
  ["#os__xia__dianwei"] = "任侠报怨",
  ["illustrator:os__xia__dianwei"] = "鱼仔",

  ["os__liexi"] = "烈袭",
  [":os__liexi"] = "准备阶段开始时，你可弃置任意张牌并选择一名其他角色，若你弃置的牌数大于其体力值，则你对其造成1点伤害；否则其对你造成1点伤害；若你弃置的牌中包含武器牌，你对其造成1点伤害。",
  ["os__shezhong"] = "慑众",
  [":os__shezhong"] = "结束阶段开始时，你可依次选择执行以下效果：1. 若你本回合对其他角色造成过伤害，则令至多X名其他角色下个摸牌阶段的额定摸牌数-1（X为你本回合造成的伤害值）；2. 若你本回合受到过伤害，则将手牌摸至与其中一名伤害来源的体力值相同（最多摸至5张）。",

  ["#os__liexi-ask"] = "烈袭：你可弃置任意张牌，点击“确定”后选择一名其他角色",
  ["#os__liexi-target"] = "烈袭：你可选择一名其他角色",
  ["@os__shezhong"] = "慑众",
  ["#os__shezhong1-target"] = "慑众：你可令至多 %arg 名其他角色下个摸牌阶段的摸牌数-1",
  ["#os__shezhong2-target"] = "慑众：你可将手牌摸至与其中一名伤害来源的体力值相同（最多摸至5张）",
  ["#os__shezhong_draw"] = "慑众",

  ["$os__liexi1"] = "短兵强击，贯汝心扉！",
  ["$os__liexi2"] = "性刚情烈，目不容奸！",
  ["$os__shezhong1"] = "此乃吾之私怨，与汝等何干？！",
  ["$os__shezhong2"] = "拦吾去路者，下场有如此贼！",
  ["~os__xia__dianwei"] = "少智无谋，空负此身勇武……",
}

local liubei = General(extension, "os__xia__liubei", "shu", 4)

local shenyi = fk.CreateTriggerSkill{
  name = "os__shenyi",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(self) and (player:inMyAttackRange(target) or player == target) and
      player.room.logic:getActualDamageEvents(1, function(e) return e.data[1].to == target and e.data[1].from and e.data[1].from ~= player end)[1].data[1] == data and
      player:usedSkillTimes(self.name) == 0) then return false end
    local all_names = U.getAllCardNames("bdt")
    return #player:getTableMark("@$os__shenyi") < #all_names
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, target == player and "#os__shenyi-ask_own" or "#os__shenyi-ask_other::" .. target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_names = U.getAllCardNames("bdt")
    local record = player:getTableMark("@$os__shenyi")
    local choices = table.filter(all_names, function(name) return not table.contains(record, name) end)
    local choice = room:askForChoice(player, choices, self.name, "#os__shenyi-choose", false, all_names)
    table.insert(record, choice)
    room:setPlayerMark(player, "@$os__shenyi", record)
    local card = room:getCardsFromPileByRule(choice)
    if #card == 0 then
      card = room:getCardsFromPileByRule(".|.|.|.|.|" .. Fk:cloneCard(choice):getTypeString())
    end
    if #card > 0 then
      player:addToPile("os__chivalry&", card[1], true, self.name)
    end
    if target ~= player and not target.dead and not player:isKongcheng() then
      local cards = room:askForCard(player, 1, player:getHandcardNum(), false, self.name, true, nil, "#os__shenyi-give::" .. target.id)
      if #cards == 0 then return end
      room:moveCardTo(cards, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id)
      for _, id in ipairs(cards) do
        if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == target then
          room:setCardMark(Fk:getCardById(id), "@@os__shenyi", player.id)
        end
      end
    end
  end,
}
local shenyi_delay = fk.CreateTriggerSkill{
  name = "#os__shenyi_delay",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    local cards = {}
    for _, move in ipairs(data) do
      local from = player.room:getPlayerById(move.from)
      if from and (move.to ~= from.id or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId):getMark("@@os__shenyi") == player.id then
            table.insertIfNeed(cards, info.cardId)
          end
        end
      end
    end
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, cid in ipairs(self.cost_data) do
      room:setCardMark(Fk:getCardById(cid), "@@os__shenyi", 0)
    end
    if player.dead then return end
    player:broadcastSkillInvoke(shenyi.name)
    room:notifySkillInvoked(player, shenyi.name, "drawcard")
    player:drawCards(#self.cost_data, shenyi.name)
  end,
}
shenyi:addRelatedSkill(shenyi_delay)
local shenyi_prohibit = fk.CreateProhibitSkill{
  name = "#os__shenyi_prohibit",
  prohibit_use = function (self, player, card)
    return player:hasSkill(shenyi) and not player:hasSkill("os__xinghan") and player:getPileNameOfId(card.id) == "os__chivalry&"
  end,
  prohibit_response = function(self, player, card)
    return player:hasSkill(shenyi) and not player:hasSkill("os__xinghan") and player:getPileNameOfId(card.id) == "os__chivalry&"
  end,
}
shenyi:addRelatedSkill(shenyi_prohibit)

local xinghan_vs = fk.CreateViewAsSkill{
  name = "os__xinghan_viewas",
  expand_pile = "os__chivalry&",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      return Self:getMark("os__xinghan_card") == to_select
    end
  end,
  view_as = function(self, cards)
    if #cards == 1 then
      return Fk:getCardById(cards[1])
    end
  end,
}
Fk:addSkill(xinghan_vs)
local xinghan = fk.CreateTriggerSkill{
  name = "os__xinghan",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and #player:getPile("os__chivalry&") > #player.room.alive_players
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#os__xinghan-ask")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getPile("os__chivalry&")
    for i = #cards, 1, -1 do
      local cid = cards[i]
      if player:getPileNameOfId(cid) == "os__chivalry&" and room:getCardOwner(cid) == player then
        local card = Fk:getCardById(cid)
        room:setPlayerMark(player, "os__xinghan_card", cid)
        if player:canUse(card) then
          room:delay(100)
          local success, dat = room:askForUseActiveSkill(player, "os__xinghan_viewas", "#os__xinghan-use:::" .. card:toLogString(), true, Util.DummyTable, true)
          room:setPlayerMark(player, "os__xinghan_card", 0)
          if success then
            room:useCard{
              from = player.id,
              tos = table.map(dat.targets, function(id) return {id} end),
              card = card,
            }
          end
        else
          room:setPlayerMark(player, "os__xinghan_card", 0)
        end
      end
    end
  end,
}
local xinghan_delay = fk.CreateTriggerSkill{
  name = "#os__xinghan_delay",
  anim_type = "negative",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(xinghan.name) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, xinghan.name, "negative")
    player:throwAllCards("h")
    if not player.dead then
      room:loseHp(player, math.max(1, player.hp - 1), xinghan.name)
    end
  end,
}
local xinghan_prohibit = fk.CreateProhibitSkill{
  name = "#os__xinghan_prohibit",
  prohibit_use = function (self, player, card)
    return (not player:hasSkill(xinghan) or (player.phase ~= Player.NotActive and not player.dying and player:getMark("os__xinghan_card") == 0)) and player:getPileNameOfId(card.id) == "os__chivalry&"
  end,
  prohibit_response = function(self, player, card)
    return (not player:hasSkill(xinghan) or (player.phase ~= Player.NotActive and not player.dying)) and player:getPileNameOfId(card.id) == "os__chivalry&"
  end,
}
xinghan:addRelatedSkill(xinghan_delay)
xinghan:addRelatedSkill(xinghan_prohibit)

liubei:addSkill(shenyi)
liubei:addSkill(xinghan)

Fk:loadTranslationTable{
  ["os__xia__liubei"] = "侠刘备",
  ["#os__xia__liubei"] = "为国为民",
  ["illustrator:os__xia__liubei"] = "特特肉",

  ["os__shenyi"] = "伸义",
  [":os__shenyi"] = "每回合限一次，当你或你攻击范围内的角色此回合首次受到其他角色造成的伤害后，你可选择一种基本牌或锦囊牌的牌名（每种限一次），然后将牌堆中一张此牌名的牌置于你的武将牌上（没有则改为该类别的一张牌），称为“侠义”，然后你可以将任意张手牌交给其，当其失去一张你以此法交给其的牌时，你摸一张牌。",
  ["os__xinghan"] = "兴汉",
  [":os__xinghan"] = "你的回合外或当你处于濒死状态时，你可如手牌般使用或打出“侠义”牌。准备阶段开始时，若“侠义”牌的数量大于存活角色数，你可依次使用“侠义”牌，然后此回合结束时，你弃置所有手牌并失去X点体力（X为你的体力值-1且至少为1）。",

  ["#os__shenyi-ask_own"] = "伸义：你可选择一种基本牌或锦囊牌的牌名（每种限一次）",
  ["#os__shenyi-ask_other"] = "伸义：你可选择一种基本牌或锦囊牌的牌名（每种限一次），然后可将任意张手牌交给 %dest",
  ["#os__shenyi-give"] = "伸义：你可将任意张手牌交给 %dest",
  ["os__chivalry&"] = "侠义",
  ["@@os__shenyi"] = "伸义",
  ["#os__shenyi_delay"] = "伸义",
  ["@$os__shenyi"] = "伸义",
  ["#os__xinghan-ask"] = "兴汉：你可依次使用“侠义”牌，然后此回合结束时，你弃置所有手牌并失去X点体力（X为你的体力值-1且至少为1）",
  ["#os__xinghan-use"] = "兴汉：使用“侠义”牌 %arg",
  ["os__xinghan_viewas"] = "兴汉",

  ["$os__shenyi1"] = "施仁德于天下，伸大义于四海！",
  ["$os__shenyi2"] = "汉道虽衰，亦不容汝等奸祟放肆！",
  ["$os__xinghan1"] = "继先汉之荣，开万世泰平！",
  ["$os__xinghan2"] = "立此兴汉之志，终不可渝！",
  ["~os__xia__liubei"] = "楼桑羽葆，终是一梦……",
}

local xiahoudun = General(extension, "os__xia__xiahoudun", "qun", 4)

local danlie = fk.CreateActiveSkill{
  name = "os__danlie",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  min_target_num = 1,
  max_target_num = 3,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return to_select ~= Self.id and Self:canPindian(target) and #selected < 3
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.map(effect.tos, Util.Id2PlayerMapper)
    -- local pd = player:pindian(table.map(targets, Util.Id2PlayerMapper), self.name)
    local pd = U.jointPindian(player, targets, self.name)
    if pd.winner == player then
      for _, p in ipairs(targets) do
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = self.name,
          }
        end
      end
    elseif not player.dead then
      room:loseHp(player, 1, self.name)
    end
  end,
}
local danlie_pd = fk.CreateTriggerSkill{
  name = "#danlie_pd",
  mute = true,
  main_skill = danlie,
  events = {fk.PindianCardsDisplayed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (data.from == player or table.contains(data.tos, player)) and player:isWounded()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, danlie.name)
    player:broadcastSkillInvoke(danlie.name)
    room:changePindianNumber(data, player, player:getLostHp(), danlie.name)
  end,
}

danlie:addRelatedSkill(danlie_pd)
xiahoudun:addSkill(danlie)

Fk:loadTranslationTable{
  ["os__xia__xiahoudun"] = "侠夏侯惇",
  ["#os__xia__xiahoudun"] = "刚烈勇猛",
  ["illustrator:os__xia__xiahoudun"] = "鬼画府",

  ["os__danlie"] = "胆烈",
  [":os__danlie"] = "出牌阶段限一次，你可以与至多三名角色共同拼点，若你：赢，你对没赢的角色造成1点伤害；没赢，你失去1点体力。你的拼点牌点数+X（X为你已损失的体力值）。" ..
  "<br/><font color='grey'>#\"<b>共同拼点</b>\"<br/>所有角色一起比大小（而非“同时拼点”：发起者和其余角色两两各比大小）。",
  ["#danlie_pd"] = "胆烈",

  ["$os__danlie1"] = "师者如父，辱师之仇亦如辱父！",
  ["$os__danlie2"] = "壮士自怀豪烈胆，初生幼虎敢搏龙！",
  ["~os__xia__xiahoudun"] = "英雄烈胆，何惧泉台一战……",
}

local zhangwei = General(extension, "zhangwei", "qun", 3, 3, General.Female)

local huzhong = fk.CreateTriggerSkill{
  name = "os__huzhong",
  anim_type = "offensive",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.firstTarget and data.card.name == "slash" and U.isOnlyTarget(player.room:getPlayerById(data.to), data, event) and
    ((#player.room:getUseExtraTargets(data, true, true) > 0 and table.find(player:getCardIds("h"), function(c) return not player:prohibitDiscard(Fk:getCardById(c)) end)) or not player.room:getPlayerById(data.to):isKongcheng())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    if player.dead then return end
    local all_choices = {"os__huzhong_own", "os__huzhong_other::" .. data.to}
    local choices = table.simpleClone(all_choices)
    local targets = room:getUseExtraTargets(data, true, true)
    if #targets == 0 then
      table.remove(choices, 1)
    end
    local to = room:getPlayerById(data.to)
    if to:isKongcheng() then
      table.remove(choices)
    end
    if #choices == 0 then return end
    local choice = room:askForChoice(player, choices, self.name, nil, false, all_choices)
    if choice == "os__huzhong_own" then
      local victims = room:askForChoosePlayers(player, targets, 1, 1, "#os__huzhong-extra", self.name, true)
      if #victims > 0 then
        local victim = victims[1]
        AimGroup:addTargets(room, data, victim)
      end
    else
      local cid = room:askForCardChosen(player, to, "h", self.name)
      room:throwCard({cid}, self.name, to, player)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.os__huzhong = true
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and (data.extra_data or {}).os__huzhong and data.damageDealt
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    room:notifySkillInvoked(player, self.name, "offensive")
    room:addPlayerMark(player, "@os__huzhong-phase")
  end,

  on_lose = function (self, player, is_death)
    player.room:setPlayerMark(player, "@os__huzhong-phase", 0)
  end
}
local huzhong_buff = fk.CreateTargetModSkill{
  name = "#os__huzhong_buff",
  residue_func = function(self, player, skill, scope)
    if player:getMark("@os__huzhong-phase") ~= 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@os__huzhong-phase")
    end
  end,
}
huzhong:addRelatedSkill(huzhong_buff)

local fenwang = fk.CreateTriggerSkill{
  name = "os__fenwang",
  mute = true,
  events = {fk.DamageInflicted, fk.DamageCaused},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) then return end
    if event == fk.DamageInflicted then
      return data.damageType ~= fk.NormalDamage
    else
      return data.damageType == fk.NormalDamage and player:getHandcardNum() > data.to:getHandcardNum()
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.DamageInflicted then
      local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, nil, "#os__fenwang-discard", true)
      self.cost_data = card
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      room:notifySkillInvoked(player, self.name, "negative")
      player:broadcastSkillInvoke(self.name, 1)
      if #self.cost_data > 0 then
        room:throwCard(self.cost_data, self.name, player)
      else
        data.damage = data.damage + 1
      end
    else
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name, 2)
      data.damage = data.damage + 1
    end
  end,
}

zhangwei:addSkill(huzhong)
zhangwei:addSkill(fenwang)

Fk:loadTranslationTable{
  ["zhangwei"] = "张葳",
  ["#zhangwei"] = "舍生取义",
  ["illustrator:zhangwei"] = "腥鱼仔",

  ["os__huzhong"] = "护众",
  [":os__huzhong"] = "当你使用普【杀】于出牌阶段指定其他角色为唯一目标时，你可摸一张牌并选择一项：1.此【杀】可额外选择一个目标；2.你弃置其一张手牌。然后若此【杀】造成伤害，你本阶段使用【杀】次数+1。",
  ["os__fenwang"] = "焚亡",
  [":os__fenwang"] = "锁定技，①当你受到属性伤害时，你须弃置一张手牌，否则此伤害+1。②当你对其他角色造成普通伤害时，若你的手牌数大于其手牌数，此伤害+1。",

  ["os__huzhong_own"] = "此【杀】可额外选择一个目标",
  ["os__huzhong_other"] = "弃置%dest一张手牌",
  ["#os__huzhong-extra"] = "护众：此【杀】可额外选择一个目标",
  ["#os__huzhong_delay"] = "护众",
  ["@os__huzhong-phase"] = "护众",
  ["#os__fenwang-discard"] = "焚亡：弃置一张手牌，否则此伤害+1",

  ["$os__huzhong1"] = "此难当头，吾誓保百姓无恙！",
  ["$os__huzhong2"] = "天崩于前，吾必先众人而死！",
  ["$os__fenwang1"] = "洛阳逢此大难，吾，亦难脱身。",
  ["$os__fenwang2"] = "大火之下，黑影，已无所遁形！",
  ["~zhangwei"] = "百姓……安否……",
}

local xiahouzieh = General(extension, "xiahouzieh", "qun", 3, 3, General.Female)

local chengxi = fk.CreateActiveSkill{
  name = "os__chengxi",
  can_use = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p.id ~= player.id and player:canPindian(p, true) and not table.contains(player:getTableMark("_os__chengxi-turn"), p.id)
    end)
  end,
  target_num = 1,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return to_select ~= Self.id and Self:canPindian(target, true) and not table.contains(Self:getTableMark("_os__chengxi-turn"), to_select) and #selected == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addTableMark(player, "_os__chengxi-turn", target.id)
    player:drawCards(1, self.name)
    if not player:canPindian(target) then return end
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      room:addPlayerMark(player, "@os__chengxi")
    else
      local slash = Fk:cloneCard("slash")
      if target:canUseTo(slash, player, { bypass_times = true, bypass_distances = true }) then
        room:useVirtualCard("slash", nil, target, player, self.name, true)
      end
    end
  end,
}
local chengxi_do = fk.CreateTriggerSkill{
  name = "#os__chengxi_do",
  events = {fk.CardUseFinished},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@os__chengxi") > 0 and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and #TargetGroup:getRealTargets(data.tos) > 0 and not (data.extra_data or {}).os__chengxiUse
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = TargetGroup:getRealTargets(data.tos) -- bye-bye, collateral
    local num = player:getMark("@os__chengxi")
    for _ = 1, num do
      if player.dead then break end
      room:removePlayerMark(player, "@os__chengxi")
      player:broadcastSkillInvoke(chengxi.name)
      local anim_type = (data.card.is_damage_card or table.contains({"dismantlement", "snatch", "chasing_near"}, data.card.name) or data.card.is_derived) and "offensive" or "support"
      room:notifySkillInvoked(player, chengxi.name, anim_type)
      local card = Fk:cloneCard(data.card.name)
      local _targets = table.filter(table.map(targets, Util.Id2PlayerMapper), function(p) return player:canUseTo(card, p, { bypass_times = true, bypass_distances = true }) end)
      local use = {} ---@type CardUseStruct
      use.from = player.id
      use.tos = table.map(_targets, function(p) return { p.id } end)
      use.card = card
      use.extraUse = true
      use.extra_data = use.extra_data or {}
      use.extra_data.os__chengxiUse = true
      room:useCard(use)
    end
  end,
}
chengxi:addRelatedSkill(chengxi_do)

xiahouzieh:addSkill(chengxi)

Fk:loadTranslationTable{
  ["xiahouzieh"] = "夏侯子萼",
  ["#xiahouzieh"] = "承继婆娑",
  ["illustrator:xiahouzieh"] = "错落宇宙",

  ["os__chengxi"] = "承袭",
  [":os__chengxi"] = "出牌阶段对每名角色限一次，你可摸一张牌并与一名角色拼点，若你：赢，你使用的下一张基本牌或普通锦囊牌结算结束后，你视为对相同目标使用一张无次数限制的同名牌；没赢，其视为对你使用一张无距离限制的【杀】。",

  ["@os__chengxi"] = "承袭",
  ["#chengxi_do"] = "承袭",

  ["$os__chengxi1"] = "从今日始，血婆娑由我继之。",
  ["$os__chengxi2"] = "夏侯之名，吾师之愿，子萼定不相负！",
  ["~xiahouzieh"] = "蔷薇凋零，永沉血海……",
}

local guanyu = General(extension, "os__xia__guanyu", "qun", 4)
local os__chue = fk.CreateTriggerSkill{
  name = "os__chue",
  anim_type = "offensive",
  events = {fk.TargetSpecifying, fk.Damaged, fk.HpLost, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.TurnEnd then
      return player:getMark("@os__bravery") >= player.hp and player:canUse(Fk:cloneCard("slash"), { bypass_times = true, bypass_distances = true })
    end
    if target ~= player then return false end
    return event ~= fk.TargetSpecifying or (data.card.trueName == "slash" and player.hp > 0 and #AimGroup:getAllTargets(data.tos) == 1 and
      #player.room:getUseExtraTargets(data, true, true) > 0)
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetSpecifying then
      return player.room:askForSkillInvoke(player, self.name, data, "#os__chue-loseHp")
    elseif event == fk.TurnEnd then
      return player.room:askForSkillInvoke(player, self.name, data, "#os__chue-use:::" .. player.hp)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecifying then
      room:loseHp(player, 1, self.name)
      if player.dead then return end
      local availableTargets = room:getUseExtraTargets(data, true, true)
      local num = player.hp
      if #availableTargets > 0 and num > 0 then
        local targets = room:askForChoosePlayers(player, availableTargets, 1, num,
        "#os__chue-choose:::"..data.card:toLogString() .. ":" .. num, self.name, true)
        if #targets > 0 then
          table.forEach(targets, function(pid) AimGroup:addTargets(room, data, pid) end)
        end
      end
    elseif event == fk.TurnEnd then
      room:removePlayerMark(player, "@os__bravery", player.hp)
      local card = Fk:cloneCard("slash")
      card.skillName = self.name
      local availableTargets = table.map(table.filter(room:getOtherPlayers(player, false), function(p) return player:canUseTo(card, p, { bypass_times = true, bypass_distances = true }) end), Util.IdMapper) -- 还原神必操作
      local num = card.skill:getMaxTargetNum(player, card) + player.hp
      if #availableTargets > 0 and num > 0 then
        local targets = room:askForChoosePlayers(player, availableTargets, 1, num, "#os__chue-slash:::" .. num, self.name, false)
        local use = { ---@class CardUseStruct
          from = player.id,
          tos = table.map(targets, function(p) return {p} end),
          card = card,
          extraUse = true,
        }
        use.additionalDamage = (use.additionalDamage or 0) + 1
        room:useCard(use)
      end
    else
      room:addPlayerMark(player, "@os__bravery")
    end
  end,
}

local os__zhongyi = fk.CreateTriggerSkill{
  name = "os__zhongyi",
  events = {fk.CardUseFinished},
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and data.card.trueName == "slash" and data.damageDealt
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = 0
    for _, n in pairs(data.damageDealt) do
      num = num + n
    end
    local x = player:getMark("@os__zhongyi") + 1
    local all_choices = {"os__zhongyi_draw:::" .. num, "os__zhongyi_recover:::" .. num, "beishui_os__zhongyi:::" .. x}
    local choices = table.clone(all_choices)
    if not player:isWounded() then table.remove(choices, 2) end
    local choice = room:askForChoice(player, choices, self.name, nil, false, all_choices)
    if choice:startsWith("beishui") then
      room:addPlayerMark(player, "@os__zhongyi")
      room:loseHp(player, x)
      if player.dead then return end
    end
    if not choice:startsWith("os__zhongyi_recover") then
      player:drawCards(num, self.name)
    end
    if not choice:startsWith("os__zhongyi_draw") and not player.dead then
      room:recover{
        who = player,
        num = math.min(num, player.maxHp - player.hp),
        recoverBy = player,
        skillName = self.name,
      }
    end
  end,
}
local os__zhongyi_buff = fk.CreateTargetModSkill{
  name = "#os__zhongyi_buff",
  frequency = Skill.Compulsory,
  bypass_distances = function(self, player, skill, scope)
    return player:hasSkill(os__zhongyi) and skill.trueName == "slash_skill"
  end,
}
os__zhongyi:addRelatedSkill(os__zhongyi_buff)

guanyu:addSkill(os__chue)
guanyu:addSkill(os__zhongyi)

Fk:loadTranslationTable{
  ["os__xia__guanyu"] = "侠关羽",
  ["#os__xia__guanyu"] = "义薄云天",
  ["illustrator:os__xia__guanyu"] = "zoo",

  ["os__chue"] = "除恶",
  [":os__chue"] = "①当你使用【杀】指定唯一目标时，若存在能成为此【杀】目标的一名角色，你可失去1点体力，额外指定至多X个目标。②当你受到伤害或失去体力后，你获得1枚“勇”。③每个回合结束时，你可弃X枚“勇”，视为使用一张【杀】，此【杀】的伤害值基数+1且额外选择X个目标。（X为你的体力值）",
  ["os__zhongyi"] = "忠义",
  [":os__zhongyi"] = "锁定技，①你使用【杀】无距离限制。②当你使用【杀】结算结束后，你选择一项：1.摸等同于此【杀】造成伤害值数牌；2.回复等同于此【杀】造成伤害值数体力；背水：你失去X点体力（X为本局你选择此技能背水的次数+1）。",

  ["#os__chue-loseHp"] = "除恶：你可失去1点体力，然后此【杀】额外指定至多你的体力值个目标",
  ["#os__chue-choose"] = "除恶：为此%arg额外指定至多%arg2个目标",
  ["#os__chue-use"] = "除恶：你可弃%arg枚“勇”，视为使用一张伤害值基数+1且额外选择%arg个目标的【杀】",
  ["#os__chue-slash"] = "除恶：视为使用一张伤害值基数+1的【杀】，目标至多%arg个",
  ["@os__bravery"] = "勇",
  ["os__zhongyi_draw"] = "摸%arg张牌",
  ["os__zhongyi_recover"] = "回复%arg点体力",
  ["beishui_os__zhongyi"] = "背水：失去%arg点体力",
  ["@os__zhongyi"] = "忠义",

  ["$os__chue1"] = "关某此生，誓斩天下恶徒！",
  ["$os__chue2"] = "政法不行，羽当替天行之！",
  ["$os__zhongyi1"] = "忠照白日，义贯长虹！",
  ["$os__zhongyi2"] = "忠铸吾骨，义全吾身！",
  ["~os__xia__guanyu"] = "丈夫终有一死，唯恨壮志难酬。",
}

-- local yuzhenzi = General(extension, "yuzhenzi", "qun", 3)


Fk:loadTranslationTable{
  ["yuzhenzi"] = "玉真子",
  ["#yuzhenzi"] = "神功天授",
  ["illustrator:yuzhenzi"] = "铁杵",

  ["os__huajing"] = "化境",
  [":os__huajing"] = "①游戏开始时，你获得6个（未生效的）“武”标记。②有“武”的角色攻击范围+X（X为其有的“武”数）。②出牌阶段限一次，你可展示至多四张手牌，随机获得其中花色数个“武”的效果直到回合结束。③若一名角色有“武”且有对应的效果，其装备区里武器牌的技能失效。<br/ ><font color='grey'>" ..
    "<b>6个“武”</b>分别为：<br /><b>剑</b>：你使用【杀】指定目标后，随机弃置其两张手牌<br/ >" ..
    "<b>刀</b>：你使用【杀】对目标角色造成伤害时，若其没有手牌，此伤害+1<br/ >" ..
    "<b>斧</b>：你使用【杀】被【闪】抵消时，对目标角色造成1点伤害<br/ >" ..
    "<b>枪</b>：你使用的黑色【杀】结算结束后，从牌堆或弃牌堆中获得一张【闪】<br/ >" ..
    "<b>戟</b>：你使用【杀】造成伤害时，摸一张牌<br/ >" ..
    "<b>弓</b>：你使用【杀】对一名角色造成伤害后，随机弃置其装备区里的一张牌",
  ["os__tianshou"] = "天授",
  [":os__tianshou"] = "锁定技，回合结束时，若你此回合使用【杀】造成过伤害，你须选择1个生效的“武”交给一名其他角色并令其获得对应效果，然后摸两张牌。其下回合结束后移除此“武”。",

  ["$os__huajing1"] = "瞬息之间，已蕴森罗万象之法！",
  ["$os__huajing2"] = "万般兵器，皆由吾心所化！",
  ["$os__tianshou1"] = "既怀远志，此武可助汝成之！",
  ["$os__tianshou2"] = "汝得此术，当勤为善行，勿动恶念！",
  ["~yuzhenzi"] = "吾身归去，如化大道。",
}

local shitao = General(extension, "shitao", "qun", 4)

--- 获取被废除的装备栏
---@param player Player
local function getSealedEquipSlot(player)
  local all_slots = {"WeaponSlot", "ArmorSlot", "DefensiveRideSlot", "OffensiveRideSlot", "TreasureSlot"}
  return table.filter(all_slots, function(slot) return table.contains(player.sealedSlots, slot) end)
end

local jieqiu = fk.CreateActiveSkill{
  name = "os__jieqiu",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and #getSealedEquipSlot(Fk:currentRoom():getPlayerById(to_select)) == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local num = #target:getCardIds(Player.Equip)
    room:abortPlayerArea(target, target.equipSlots)
    if not target.dead then
      room:setPlayerMark(target, "@os__jieqiu", player.general)
      room:setPlayerMark(target, "_os__jieqiu", player.id)
      target:drawCards(num, self.name)
    end
  end,
}

local jieqiu_delay = fk.CreateTriggerSkill{
  name = "#os__jieqiu_delay",
  events = {fk.EventPhaseEnd, fk.TurnEnd},
  anim_type = "control",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target:getMark("_os__jieqiu") == 0 or target.dead then return end
    if event == fk.EventPhaseEnd then
      if target == player and target.phase == Player.Discard then
        local num = 0
        player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
          for _, move in ipairs(e.data) do
            if move.from == target.id and move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  num = num + 1
                end
              end
            end
          end
          return false
        end, Player.HistoryPhase)
        if num > 0 then
          self.cost_data = num
          return true
        end
      end
    elseif target:getMark("_os__jieqiu") == player.id and not player.dead then
      return player:usedSkillTimes(self.name, Player.HistoryRound) == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    return event == fk.EventPhaseEnd or player.room:askForSkillInvoke(player, self.name, data, "#os__jieqiu-ask")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      local num = self.cost_data
      local all_choices = getSealedEquipSlot(player)
      if #all_choices > 0 then
        local choices = room:askForChoices(player, all_choices, num, num, self.name, "#os__jieqiu-choice:::" .. num, false)
        room:resumePlayerArea(player, choices)
      end
    else
      room:doIndicate(player.id, {target.id})
      room:notifySkillInvoked(player, self.name, "control")
      player:broadcastSkillInvoke("os__jieqiu")
      player:gainAnExtraTurn()
    end
  end,

  refresh_events = {fk.AreaResumed},
  can_refresh = function(self, event, target, player, data)
    return player == target and #getSealedEquipSlot(player) == 0 and player:getMark("_os__jieqiu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@os__jieqiu", 0)
    room:setPlayerMark(player, "_os__jieqiu", 0)
  end,
}
jieqiu:addRelatedSkill(jieqiu_delay)

local enchou = fk.CreateActiveSkill{
  name = "os__enchou",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and #getSealedEquipSlot(Fk:currentRoom():getPlayerById(to_select)) > 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cids = target:getCardIds(Player.Hand)
    local cards, _ = U.askforChooseCardsAndChoice(player, cids, {"os__enchou_get"}, self.name, "#os__enchou-ask::" .. target.id)
    room:obtainCard(player, cards[1], false, fk.ReasonPrey, player.id)
    if not target.dead and not player.dead then
      local choices = getSealedEquipSlot(target)
      if #choices > 0 then
        local choice = room:askForChoice(player, choices, self.name, "#os__enchou-choice::" .. target.id, false)
        room:resumePlayerArea(target, {choice})
      end
    end
  end,
}

shitao:addSkill(jieqiu)
shitao:addSkill(enchou)

Fk:loadTranslationTable{
  ["shitao"] = "石韬",
  ["#shitao"] = "快意恩仇",
  ["illustrator:shitao"] = "鱼仔",

  ["os__jieqiu"] = "劫囚",
  [":os__jieqiu"] = "出牌阶段限一次，你可选择一名所有装备栏均未被废除的其他角色，废除其所有装备栏，然后其摸X张牌（X为废除前其装备区里的牌数）。其弃牌阶段结束时，其恢复等同于此阶段弃置手牌数量的装备栏。其回合结束时，若仍有装备栏被废除，则你可执行一个额外回合（每轮限一次）。",
  ["os__enchou"] = "恩仇",
  [":os__enchou"] = "出牌阶段限一次，你可观看一名有装备栏被废除的其他角色的手牌并获得其中一张牌，然后你恢复其一个装备栏。",

  ["@os__jieqiu"] = "被劫囚",
  ["#os__jieqiu_delay"] = "劫囚",
  ["#os__jieqiu-choice"] = "劫囚：恢复 %arg 个装备栏",
  ["#os__jieqiu-ask"] = "劫囚：你可执行一个额外回合",
  ["os__enchou_get"] = "获得",
  ["#os__enchou-ask"] = "恩仇：获得 %dest 一张手牌，然后恢复其一个装备栏",
  ["#os__enchou-choice"] = "恩仇：恢复 %dest 一个装备栏",

  ["$os__jieqiu1"] = "元直莫慌，石韬来也！",
  ["$os__jieqiu2"] = "一群鼠辈，焉能挡我等去路！",
  ["$os__enchou1"] = "江湖快意，恩仇必报！",
  ["$os__enchou2"] = "今日之因，明日之果！",
  ["~shitao"] = "想不到竟中了官府的埋伏……",
}

local shie = General(extension, "shie", "wei", 4)
local os__dengjian = fk.CreateTriggerSkill{
  name = "os__dengjian",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function (self, event, target, player, data)
    if not (target.phase == Player.Discard and player:hasSkill(self) and player ~= target) then return end
    local cards = {}
    local record = player:getTableMark("_os__dengjian-round")
    player.room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data[1]
      if damage.from == target and damage.card then
        local c = damage.card ---@class Card
        if c.trueName == "slash" and U.isPureCard(c) and not table.contains(record, c.color) and player.room:getCardArea(c) == Card.DiscardPile then
          table.insertTableIfNeed(cards, Card:getIdList(c))
        end
      end
      return false
    end)
    if #cards > 0 then
      self.cost_data = {cards = cards}
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data.cards
    local card = table.random(cards) ---@type integer
    room:obtainCard(player, card, true, fk.ReasonPrey, player.id, self.name, "@@os__fencing-inhand")
    room:addTableMark(player, "_os__dengjian-round", Fk:getCardById(card, true).color)
  end
}
local os__dengjian_buff = fk.CreateTargetModSkill{
  name = "#os__dengjian_buff",
  bypass_times = function (self, player, skill, scope, card, to)
    return card and card:getMark("@@os__fencing-inhand") > 0
  end
}
os__dengjian:addRelatedSkill(os__dengjian_buff)

local os__xinshou = fk.CreateTriggerSkill{
  name = "os__xinshou",
  anim_type = "support",
  events = {fk.CardUsing},
  can_trigger = function (self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) or data.card.trueName ~= "slash" then return end
    local record = player:getTableMark("_os__xinshou_choice-turn")
    if #record == 2 then
      return player:hasSkill("os__dengjian")
    elseif player.phase == Player.Play then
      if #record == 1 and record[1] == "draw1" and player:isNude() then return end
      local room = player.room
      local current_event_id = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true).id
      local use
      if #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        use = e.data[1]
        if use.from == player.id and use.card.trueName == "slash" then
          return data.card:compareColorWith(use.card) and e.id ~= current_event_id
        end
        return false
      end, Player.HistoryTurn) == 0 then
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local record = player:getTableMark("_os__xinshou_choice-turn")
    if #record == 2 then
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper), 1, 1, "#os__xinshou-invoke2", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      local all_choices = {"draw1", "os__xinshou_give", "Cancel"}
      local choices = table.clone(all_choices)
      table.forEach(record, function(c) table.removeOne(choices, c) end)
      if player:isNude() then table.removeOne(choices, "os__xinshou_give") end
      local choice = player.room:askForChoice(player, choices, self.name, "#os__xinshou-invoke1", false, all_choices)
      if choice ~= "Cancel" then
        self.cost_data = choice
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local record = player:getTableMark("_os__xinshou_choice-turn")
    if #record == 2 then
      local to = room:getPlayerById(self.cost_data)
      room:setPlayerMark(player, "_os__xinshou_target", to.id)
      room:setPlayerMark(player, "@os__xinshou_target", to.general)
      room:invalidateSkill(player, "os__dengjian")
      room:handleAddLoseSkills(to, "os__dengjian", nil)
    else
      local choice = self.cost_data
      table.insert(record, choice)
      room:setPlayerMark(player, "_os__xinshou_choice-turn", record)
      if choice == "draw1" then
        room:drawCards(player, 1)
      else
        local plist, card = room:askForChooseCardAndPlayers(target, table.map(room:getOtherPlayers(target), Util.IdMapper), 1, 1, nil, "#os__xinshou-give", self.name, false)
        room:moveCardTo(card, Player.Hand, room:getPlayerById(plist[1]), fk.ReasonGive, self.name, nil, false)
      end
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function (self, event, target, player, data)
    return target and target:hasSkill("os__dengjian") and player:getMark("_os__xinshou_target") == target.id
    and data.card and data.card.trueName == "slash" and player:getMark("_os__xinshou_validate") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "_os__xinshou_validate", 1)
  end
}

local os__xinshou_detach = fk.CreateTriggerSkill{
  name = "#os__xinshou_detach",
  mute = true,
  events = {fk.TurnStart},
  can_trigger = function (self, event, target, player, data)
    return player == target and player:getMark("_os__xinshou_target") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("_os__xinshou_target"))
    if player:getMark("_os__xinshou_validate") ~= 0 then
      room:validateSkill(player, "os__dengjian")
      room:setPlayerMark(player, "_os__xinshou_validate", 0)
    end
    room:setPlayerMark(player, "_os__xinshou_target", 0)
    room:setPlayerMark(player, "@os__xinshou_target", 0)
    room:handleAddLoseSkills(to, "-os__dengjian", nil)
  end
}
os__xinshou:addRelatedSkill(os__xinshou_detach)

shie:addSkill(os__dengjian)
shie:addSkill(os__xinshou)

Fk:loadTranslationTable{
  ["shie"] = "史阿",
  ["#shie"] = "剑术登峰",
  ["illustrator:shie"] = "凝聚永恒",

  ["os__dengjian"] = "登剑",
  [":os__dengjian"] = "其他角色的弃牌阶段结束时，你可从弃牌堆随机获得一张其本回合使用造成过伤害的非转化的【杀】（每轮每种颜色限一次），此【杀】标记为“剑法”（“剑法”：无次数限制）。",
  ["os__xinshou"] = "心授",
  [":os__xinshou"] = "当你于出牌阶段内使用【杀】时，若此【杀】颜色与你本回合使用过的【杀】颜色均不同，你可选择一项本回合未执行过的效果：1.摸一张牌；2.交给一名其他角色一张牌。" ..
    "当你使用【杀】时，若你本回合执行过〖心授〗的所有效果，你可令〖登剑〗失效并选择一名其他角色，其视为拥有〖登剑〗直到你的下回合开始。若其拥有〖登剑〗时使用【杀】造成过伤害，则你的下回合开始时，你的〖登剑〗生效。",

  ["@@os__fencing-inhand"] = "剑法",
  ["#os__xinshou-invoke1"] = "你可发动〖心授〗，选择一项本回合未执行过的效果",
  ["#os__xinshou-invoke2"] = "你可发动〖心授〗，令〖登剑〗失效并选择一名其他角色，其视为拥有〖登剑〗直到你的下回合开始",
  ["os__xinshou_give"] = "交给一名其他角色一张牌",
  ["#os__xinshou-give"] = "心授：交给一名其他角色一张牌",
  ["#os__xinshou_detach"] = "心授",
  ["@os__xinshou_target"] = "心授",

  ["$os__dengjian1"] = "百家剑法之长，皆凝于此剑！",
  ["$os__dengjian2"] = "君剑法超群，观之似有所得！",
  ["$os__xinshou1"] = "传汝于心，授汝以要！",
  ["$os__xinshou2"] = "公子少怀大志，可承吾剑！",
  ["~shie"] = "江湖路远，吾等终会有再见之时。",
}

return extension
