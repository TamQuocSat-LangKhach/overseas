local extension = Package("overseas_wuxia")
extension.extensionName = "overseas"

Fk:loadTranslationTable{
  ["overseas_wuxia"] = "国际服武侠篇",
}

local os__tongyuan = General(extension, "os__tongyuan", "qun", 4)

local os__chaofeng = fk.CreateViewAsSkill{
  name = "os__chaofeng",
  pattern = "slash,jink",
  card_num = 1,
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
    return (Fk.currentResponsePattern == nil and c.skill:canUse(Self)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
  end,
  interaction = function(self)
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(allCardNames, card.name) and (card.trueName == "slash" or card.name == "jink") and ((Fk.currentResponsePattern == nil and card.skill:canUse(Self)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) and not Self:prohibitUse(card) then
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
    return Fk:cloneCard("slash").skill:canUse(player)
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
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local availableTargets = table.map(
      table.filter(player.room:getOtherPlayers(player), function(p)
        return not p:isKongcheng()
      end),
      function(p)
        return p.id
      end
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
    room:broadcastSkillInvoke("os__chaofeng")
    local targets = table.map(self.cost_data, function(pid)
      return room:getPlayerById(pid)
    end)
    local pd = player:pindian(targets, self.name)
    local pdNum = {}
    pdNum[player.id] = pd.fromCard.number
    table.forEach(self.cost_data, function(pid) pdNum[pid] = pd.results[pid].toCard.number end)
    local winner, num = nil, nil
    for k, v in pairs(pdNum) do
      if num == nil then
        num = v
        winner = k
      elseif num < v then
        num = v
        winner = k
      elseif num == v then
        winner = nil
      end
    end
    if winner then
      winner = room:getPlayerById(winner)
      table.insert(targets, player)
      table.removeOne(targets, winner)
      room:useVirtualCard("fire__slash", nil, winner, targets, self.name, true)
    end
  end,
}
os__chaofeng:addRelatedSkill(os__chaofeng_pd)

local os__chuanshu = fk.CreateTriggerSkill{
  name = "os__chuanshu",
  events = {fk.EventPhaseStart},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local target = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, function(p)
    return p.id end), 1, 1, "#os__chuanshu-ask", self.name, true)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(self.cost_data)
    for _, name in ipairs({"@os__chuanshu", "_os__chuanshu_slash"}) do
      local os__chuanshuRecord = type(target:getMark(name)) == "table" and target:getMark(name) or {}
      table.insert(os__chuanshuRecord, name == "@os__chuanshu" and player.general or player.id)
      room:setPlayerMark(target, name, os__chuanshuRecord)
    end
    room:setPlayerMark(player, "_os__chuanshu", {target.id, player.general})
  end,

  refresh_events = {fk.EventPhaseChanging, fk.PindianCardsDisplayed, fk.PreCardUse, fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging then
      return target == player and data.from == Player.NotActive and player:getMark("_os__chuanshu") ~= 0
    elseif event == fk.PindianCardsDisplayed then
      return player:getMark("@os__chuanshu") ~= 0 and (data.from == player or table.contains(data.tos, player))
    elseif event == fk.PreCardUse then
      return target == player and player:getMark("_os__chuanshu_slash") ~= 0
    else
      if target ~= player or player:getMark("@os__chuanshu") == 0 then return false end
      local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      return parentUseData and (parentUseData.data[1].extra_data or {}).os__chuanshuUser == player.id
    end
    return false
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseChanging then
      local target = room:getPlayerById(player:getMark("_os__chuanshu")[1])
      if target:isAlive() then
        local os__chuanshuRecord = type(target:getMark("@os__chuanshu")) == "table" and target:getMark("@os__chuanshu") or {}
        table.removeOne(os__chuanshuRecord, player:getMark("_os__chuanshu")[2])
        os__chuanshuRecord = os__chuanshuRecord == {} and 0 or os__chuanshuRecord
        room:setPlayerMark(target, "@os__chuanshu", os__chuanshuRecord)
      end
      room:setPlayerMark(player, "_os__chuanshu", 0)
    elseif event == fk.PindianCardsDisplayed then
      room:notifySkillInvoked(player, self.name)
      room:broadcastSkillInvoke(self.name)
      local num = 3 * #player:getMark("@os__chuanshu")
      if data.from == player then
        data.fromCard.number = math.min(data.fromCard.number + num, 13)
      else
        data.results[player.id].toCard.number = math.min(data.results[player.id].toCard.number + num, 13)
      end
    elseif event == fk.PreCardUse then
      data.extra_data = data.extra_data or {}
      data.extra_data.os__chuanshuUser = player.id
      data.extra_data.os__chuanshu = player:getMark("_os__chuanshu_slash")
      room:setPlayerMark(player, "_os__chuanshu_slash", 0)
    else
      room:notifySkillInvoked(player, self.name)
      room:broadcastSkillInvoke(self.name)
      local parentUseData = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      local os__chuanshuRecord = table.clone((parentUseData.data[1].extra_data or {}).os__chuanshu)
      if not table.contains(os__chuanshuRecord, data.to.id) then
        data.damage = data.damage + #os__chuanshuRecord
      end
      table.removeOne(os__chuanshuRecord, player.id)
      table.forEach(os__chuanshuRecord, function(pid) room:getPlayerById(pid):drawCards(data.damage, self.name) end)
    end
  end,
}

os__tongyuan:addSkill(os__chaofeng)
os__tongyuan:addSkill(os__chuanshu)

Fk:loadTranslationTable{
  ["os__tongyuan"] = "童渊",
  ["os__chaofeng"] = "朝凤",
  [":os__chaofeng"] = "①你可将【杀】当【闪】、【闪】当任意【杀】使用或打出。②出牌阶段开始时，你可与至多三名角色共同拼点：赢的角色视为对所有没赢的角色使用一张火【杀】。" ..
  "<br></br><font color='grey'>#\"<b>共同拼点</b>\"<br></br>所有角色一起比大小（而非“同时拼点”：发起者和其余角色两两各比大小）。",
  ["os__chuanshu"] = "传术",
  [":os__chuanshu"] = "限定技，准备阶段开始时，你可选择一名角色：直到你下回合开始，其拼点牌点数+3，且使用下一张【杀】对其他角色造成伤害+1，且此【杀】造成伤害时，若其不为你，你摸等同伤害值的牌。",

  ["#os__chaofeng_pd"] = "朝凤",
  ["#os__chaofeng-ask"] = "朝凤：你可与至多三名角色共同拼点",
  ["#os__chuanshu-ask"] = "你可对一名角色发动“传术”，收其为徒",
  ["@os__chuanshu"] = "传术",

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
    return target == player and player:hasSkill(self.name) and data.firstTarget and data.card.trueName == "slash" and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local alivePlayers = room:getAlivePlayers()
    local availableTargets = {}
    for _, p in ipairs(alivePlayers) do
      if table.contains(AimGroup:getAllTargets(data.tos), p.id) and not p:isKongcheng() then
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
      local result = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__yulong-ask", self.name)
      if #result > 0 then
        self.cost_data = result[1]
        return true
      else
        return false
      end
    end
    
    return true
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
    if target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and data.card.suit ~= Card.NoSuit then
      local suitsRecorded = type(player:getMark("@os__jianming-turn")) == "table" and player:getMark("@os__jianming-turn") or {}
      return not table.contains(suitsRecorded, "log_" .. data.card:getSuitString())
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    local suitsRecorded = type(player:getMark("@os__jianming-turn")) == "table" and player:getMark("@os__jianming-turn") or {}
    table.insert(suitsRecorded, "log_" .. data.card:getSuitString())
    player.room:setPlayerMark(player, "@os__jianming-turn", suitsRecorded)
  end,
}

wangyue:addSkill(os__yulong)
wangyue:addSkill(os__jianming)

Fk:loadTranslationTable{
  ["wangyue"] = "王越",
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
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function(self, player)
    if player.phase == Player.NotActive then player:drawCards(1, self.name) end
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name) == 0 --权宜
  end,
  enabled_at_response = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
}
local os__jiange_buff = fk.CreateTargetModSkill{
  name = "#os__jiange_buff",
  residue_func = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "os__jiange") and 999 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return card and table.contains(card.skillNames, "os__jiange") and 999 or 0
  end,
}
os__jiange:addRelatedSkill(os__jiange_buff)

local os__xiawang = fk.CreateTriggerSkill{
  name = "os__xiawang",
  events = {fk.Damaged},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target:distanceTo(player) < 2 and data.card and data.card.color == Card.Black and not (target.dead or player.dead) and data.from and not (data.from.dead or data.from == player)
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askForUseCard(player, "slash", nil, "#os__xiawang-ask:" .. data.from.id, true, {must_targets = {data.from.id} })
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
      local event = room.logic:getCurrentEvent():findParent(GameEvent.Phase)
      event:shutdown()
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    return parentUseData and (parentUseData.data[1].extra_data or {}).os__xiawangUser == player.id
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__xiawang-phase")
  end,
}

os__xia__xushu:addSkill(os__jiange)
os__xia__xushu:addSkill(os__xiawang)

Fk:loadTranslationTable{
  ["os__xia__xushu"] = "侠徐庶",
  ["os__jiange"] = "剑歌",
  [":os__jiange"] = "每回合限一次，你可将一张非基本牌当【杀】使用或打出（无距离与次数限制且不计入次数）。若此时为你的回合外，你摸一张牌。",
  ["os__xiawang"] = "侠望",
  [":os__xiawang"] = "当至你距离不大于1的角色受到黑色牌造成的伤害后，你可对伤害来源使用【杀】。若此【杀】造成了伤害，则在【杀】结算后结束当前阶段。",

  ["#os__xiawang-ask"] = "你可对 %src 使用【杀】。若此【杀】造成了伤害，则在结算后结束当前阶段",

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
    return player == target and player:hasSkill(self.name) and data.card.is_damage_card and data.firstTarget
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    local room = player.room
    local availableTargets = table.map(
      table.filter(room:getOtherPlayers(player), function(p)
        return not p:isKongcheng()
      end),
      function(p)
        return p.id
      end
    )
    if #availableTargets == 0 then return false end
    local targets = room:askForChoosePlayers(player, availableTargets, 1, 3, "#os__chaofeng-ask", self.name, false)
    if #targets == 0 then return false end
    local pd = player:pindian(table.map(targets, function(pid)
      return room:getPlayerById(pid)
    end), self.name)
    local pdNum = {}
    pdNum[player.id] = pd.fromCard.number
    table.forEach(targets, function(pid) pdNum[pid] = pd.results[pid].toCard.number end)
    local winner, num = nil, nil
    for k, v in pairs(pdNum) do
      if num == nil then
        num = v
        winner = k
      elseif num < v then
        num = v
        winner = k
      elseif num == v then
        winner = nil
      end
    end
    if winner == player.id then
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
    return target == player and player:hasSkill(self.name) and data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    local availableTargets = table.map(table.filter(player.room:getAlivePlayers(), function(p)
      return p:getMark("@@os__blade") > 0 and not table.contains(TargetGroup:getRealTargets(data.tos), p.id)
    end), function(p)
      return p.id 
    end)
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

  refresh_events = {fk.DamageCaused, fk.PindianCardsDisplayed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      return target == player and player:hasSkill(self.name) and data.to:getMark("@@os__blade") == 0 and data.to ~= player
    else
      return player:hasSkill(self.name) and (data.from == player or table.contains(data.tos, player))
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    room:broadcastSkillInvoke(self.name)
    if event == fk.DamageCaused then
      room:addPlayerMark(data.to, "@@os__blade")
    else
      local num = 2 * (#data.tos + 1)
      if data.from == player then
        data.fromCard.number = math.min(data.fromCard.number + num, 13)
      else
        data.results[player.id].toCard.number = math.min(data.results[player.id].toCard.number + num, 13)
      end
    end
  end,
}

liyan:addSkill(os__zhenhu)
liyan:addSkill(os__lvren)

Fk:loadTranslationTable{
  ["liyan"] = "李彦",
  ["os__zhenhu"] = "震虎",
  [":os__zhenhu"] = "当你使用伤害牌指定第一个目标时，你可摸一张牌并与至多三名其他角色共同拼点：若你赢，此牌对没赢的角色造成伤害+1。若你没赢，你失去1点体力。" ..
  "<br></br><font color='grey'>#\"<b>共同拼点</b>\"<br></br>所有角色一起比大小（而非“同时拼点”：发起者和其余角色两两各比大小）。",
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
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
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
  on_cost = function() return true end,
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
    return player:hasSkill(self.name) and data.damage and data.damage.from == player 
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    local skills = table.map(table.filter(target.player_skills, function(s)
        return not (s.attached_equip or s.lordSkill)
      end), function(skill)
        return skill.name 
      end) or {}
    table.insertTable(skills, table.map(table.filter(target.derivative_skills, function(s)
        return not (s.attached_equip or s.lordSkill)
      end)), function(skill)
        return skill.name 
      end)
    local names = table.concat(skills, "|")
    room:handleAddLoseSkills(player, names, nil)
    room:setPlayerMark(player, "@os__duoren", target.general)
    room:setPlayerMark(player, "_os__duoren", names)
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return data.damage and data.damage.from and player:hasSkill(self.name) and data.damage.from == player and player:getMark("_os__duoren") ~= 0 and target ~= player
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
    if not player:hasSkill(self.name) then return false end
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
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#os__yanshi-choose", self.name, false)
      local to
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      room:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "special")
      room:setPlayerMark(player, "@os__yanshi", to.general)
      room:setPlayerMark(player, "_os__yanshi", to.id)
    elseif event == fk.Damaged then
      room:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "masochism")
      room:addPlayerMark(data.from, "@@os__oath")
    elseif event == fk.Damage then
      player:drawCards(data.damage, self.name)
      room:removePlayerMark(data.to, "@@os__oath")
    else
      room:broadcastSkillInvoke(self.name, 3)
      room:notifySkillInvoked(player, self.name, "offensive")
      data.damage = data.damage + 1
    end
  end,
}
local os__yanshi_distance = fk.CreateDistanceSkill{
  name = "#os__yanshi_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(self.name) then
      if to:getMark("@@os__oath") > 0 then
        from:setFixedDistance(to, 1)
      else
        from:removeFixedDistance(to)
      end
    end
    return 0
  end,
}
os__yanshi:addRelatedSkill(os__yanshi_distance)

local os__renchou = fk.CreateTriggerSkill{
  name = "os__renchou",
  frequency = Skill.Compulsory,
  events = {fk.Death},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name, false, true) and (target == player or player:getMark("_os__yanshi") == target.id) and (player:isAlive() or player.room:getPlayerById(player:getMark("_os__yanshi")):isAlive()) and data.damage and data.damage.from and data.damage.from:isAlive()  
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = player:isAlive() and player or room:getPlayerById(player:getMark("_os__yanshi"))
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
  ["os__yanshi"] = "言誓",
  [":os__yanshi"] = "①游戏开始时，你选择一名其他角色。②当你或“言誓”角色受到除你与其以外的角色造成的伤害后，若伤害来源没有“誓”，伤害来源获得1枚“誓”。③你对有“誓”的角色使用牌无距离限制且对其造成的伤害+1。④当你对有“誓”的角色造成伤害后，你摸等同于伤害数的牌并弃其1枚“誓”。",
  ["os__renchou"] = "刃仇",
  [":os__renchou"] = "锁定技，当你或“言誓”角色死亡时，若另一名角色A存活，则A对来源B造成X点伤害（X为A的体力值）。",

  ["#os__yanshi-choose"] = "言誓：请选择一名其他角色",
  ["@os__yanshi"] = "言誓",
  ["@@os__oath"] = "誓",

  ["$os__yanshi1"] = "骨肉至亲，血脉相连。",
  ["$os__yanshi2"] = "挟长持短，昼夜哀酸！",
  ["$os__yanshi3"] = "当以贼血，污此白刃！",
  ["$os__renchou1"] = "塞亡父之冤魂，血三弟之永恨！",
  ["$os__renchou2"] = "禄福夜雪白，都亭朝霞红！	",
  ["~zhaoe"] = "乞就刑戮，肃明王法……",
}

local os__xia__lusu = General(extension, "os__xia__lusu", "qun", 4)

local os__kaizeng = fk.CreateTriggerSkill{
  name = "os__kaizeng",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self.name, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self
    else
      return target == player and player:hasSkill(self.name, true, true)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self.name, true) then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          room:handleAddLoseSkills(p, "&os__kaizeng_others", nil, false, true)
        end
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        room:handleAddLoseSkills(p, "-&os__kaizeng_others", nil, false, true)
      end
    end
  end,
}
local os__kaizeng_others = fk.CreateActiveSkill{
  name = "&os__kaizeng_others",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function() return false end,
  target_filter = function() return false end,
  interaction = function(self)
    local choiceList = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic then
        table.insertIfNeed(choiceList, card.trueName)
      end
    end
    table.insertTable(choiceList, {"trick", "equip"}) --只要三国杀还只有三个类别，就不想写得效率更低但更稳妥……
    return UI.ComboBox { choices = choiceList }
  end,
  on_use = function(self, room, effect)
    local choice = self.interaction.data
    if not choice then choice = "slash" end--return false end
    local player = room:getPlayerById(effect.from)
    local targets = table.filter(room:getOtherPlayers(player), function(p) return p:hasSkill("os__kaizeng") and p:usedSkillTimes("os__kaizeng", Player.HistoryPhase) == 0 end)
    if #targets == 0 then return false end
    local to
    if #targets == 1 then
      to = targets[1]
    else
      to = room:getPlayerById(room:askForChoosePlayers(player, table.map(targets, function(p) return p.id end), 1, 1, nil, self.name, false)[1])
    end
    room:doIndicate(player.id, {to.id})
    local cids = room:askForCard(to, 1, 999, false, "os__kaizeng", true, nil, "#os__kaizeng-give:" .. player.id)-- .. "::" .. choice)
    if #cids > 0 then
      to:addSkillUseHistory("os__kaizeng")
      room:notifySkillInvoked(to, "os__kaizeng", "support")
      room:broadcastSkillInvoke("os__kaizeng")
      room:moveCardTo(cids, Player.Hand, player, fk.ReasonGive, self.name, nil, true)
      if #cids > 1 then
        to:drawCards(1, "os__kaizeng")
      end
      local CardType = (choice == "trick" or choice == "equip")
      if table.find(table.map(cids, function(cid) return Fk:getCardById(cid) end), function(card)
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
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and #player:getMark("@os__yangming-phase") > 0 
  end,
  on_use = function(self, event, target, player, data)
    local num = #player:getMark("@os__yangming-phase")
    player:drawCards(num, self.name)
    player.room:addPlayerMark(player, "AddMaxCards-turn", num)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and
      player:hasSkill(self.name, true) and player.phase == Player.Play and
      (type(player:getMark("@os__yangming-phase")) ~= "table" or
      not table.contains(player:getMark("@os__yangming-phase"), data.card:getTypeString() .. "_char"))
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local typesRecorded = type(player:getMark("@os__yangming-phase")) == "table" and player:getMark("@os__yangming-phase") or {}
    table.insert(typesRecorded, data.card:getTypeString() .. "_char")
    room:setPlayerMark(player, "@os__yangming-phase", typesRecorded)
  end,
}

os__xia__lusu:addSkill(os__kaizeng)
os__xia__lusu:addSkill(os__yangming)

Fk:loadTranslationTable{
  ["os__xia__lusu"] = "侠鲁肃",
  ["os__kaizeng"] = "慨赠",
  [":os__kaizeng"] = "其他角色的出牌阶段限一次，其可指定一种基本牌牌名或非基本牌类别，令你选择是否交给其任意张手牌。若你交给其多于一张牌，你摸一张牌；若其中包含其指定的牌名/类别的牌，你从牌堆中获得一张不同牌名/类别的牌。",
  ["os__yangming"] = "扬名",
  [":os__yangming"] = "出牌阶段结束时，你可摸X张牌，且此回合手牌上限+X（X为你此阶段使用牌的类别数）。",

  ["&os__kaizeng_others"] = "慨赠",
  [":&os__kaizeng_others"] = "出牌阶段限一次，你可指定一种基本牌牌名或非基本牌类别，令侠鲁肃选择是否交给你任意张手牌。若其交给你多于一张牌，其摸一张牌；若其中包含你指定的牌名/类别的牌，其从牌堆中获得一张不同牌名/类别的牌。",
  ["#os__kaizeng-give"] = "慨赠：你可交给 %src 任意张手牌",--，其指定了 %arg",
  ["@os__yangming-phase"] = "扬名",

  ["$os__kaizeng1"] = "此心唯念天下之士，不较细软锱铢！",
  ["$os__kaizeng2"] = "千金散尽何须虑，但求天下俱欢颜！",
  ["$os__yangming1"] = "善名高布凌霄阙，仁德始铸黄金台！",
  ["$os__yangming2"] = "矢千金之利，得万人之心！",
  ["~os__xia__lusu"] = "人心不足，巴蛇吞象……",
}

local os__xia__dianwei = General(extension, "os__xia__dianwei", "qun", 4)

local os__liexi = fk.CreateTriggerSkill{
  name = "os__liexi",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = room:askForCard(player, 1, #player:getCardIds(Player.Hand) + #player:getCardIds(Player.Equip), true, self.name, true, nil, "#os__liexi-ask")
    if #ids > 0 then
      local victim = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
        return p.id
      end), 1, 1, "#os__liexi-target", self.name, true)
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
    if target ~= player or not player:hasSkill(self.name) or player.phase ~= Player.Finish then return false end
    if player:getMark("_os__shezhong_damage_others-turn") > 0 then return true end
    local room = player.room
    local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
      return p:getMark("_os__shezhong_damaged-turn") > 0
    end), function(p)
    return p.id end)
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("_os__shezhong_damage_others-turn") > 0 then
      local num = player:getMark("_os__shezhong_damage-turn")
      local victims = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
        return p.id
      end), 1, num, "#os__shezhong1-target:::" .. tostring(num), self.name, true)
      if #victims > 0 then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          if table.contains(victims, p.id) then
            room:addPlayerMark(p, "@os__shezhong")
          end
        end
      end
    end
    if self.cost_data ~= nil then
      local target = room:askForChoosePlayers(player, self.cost_data, 1, 1, "#os__shezhong2-target", self.name, true)
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
  on_cost = function() return true end,
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
  ["$oos__liexi2"] = "性刚情烈，目不容奸！",
  ["$os__shezhong1"] = "此乃吾之私怨，与汝等何干？！",
  ["$os__shezhong2"] = "拦吾去路者，下场有如此贼！",
  ["~os__xia__dianwei"] = "少智无谋，空负此身勇武……",
}

return extension
