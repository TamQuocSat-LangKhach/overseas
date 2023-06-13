local extension = Package("overseas_sp")
extension.extensionName = "overseas"

Fk:loadTranslationTable{
  ["overseas_sp"] = "国际服专属1",
  ["os"] = "国际",
  ["os_sp"] = "国际SP",
}

local fengxi = General(extension, "fengxi", "shu", 4)
local os__qingkou = fk.CreateTriggerSkill{
  name = "os__qingkou",
  anim_type = "offensive",
  events = {fk.EventPhaseStart, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and not player:prohibitUse(Fk:cloneCard("duel"))
    else
      return data.card.skillName == self.name and player:getMark("_os__qingkou_damage") > 0 --不能用 target == player
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      local card = Fk:cloneCard("duel")
      local availableTargets = table.map(
        table.filter(room:getOtherPlayers(player), function(p)
          return not player:isProhibited(p, card)
        end),
        function(p)
          return p.id
        end
      )
      if #availableTargets == 0 then return false end
      local target = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__qingkou-ask", self.name, true)
      if #target > 0 then
        self.cost_data = target[1]
        return true
      end
      return false
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      player.room:useVirtualCard("duel", nil, player, player.room:getPlayerById(self.cost_data), self.name, true)
    else
      player:drawCards(1, self.name)
      player.room:setPlayerMark(player, "_os__qingkou_damage", 0)
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card and 
    data.card.skillName == self.name
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "_os__qingkou_damage", 1)
    if player:hasSkill(self.name) then
      player:skip(Player.Judge)
      player:skip(Player.Discard)
    end
  end,
}
fengxi:addSkill(os__qingkou)

Fk:loadTranslationTable{
  ["fengxi"] = "冯习",
  ["os__qingkou"] = "轻寇",
  [":os__qingkou"] = "准备阶段开始时，你可视为使用一张【决斗】。此【决斗】结算后，造成伤害的角色摸一张牌，若为你，你跳过此回合的判定阶段和弃牌阶段。",

  ["#os__qingkou-ask"] = "轻寇：你可选择一名其他角色，视为对其使用一张【决斗】",

  ["$os__qingkou1"] = "哈哈哈哈，鼠辈岂能当我大汉雄师？",
  ["$os__qingkou2"] = "凛凛汉将，岂畏江东鼠辈？",
  ["~fengxi"] = "陛下，速退白帝……",
}

local zhangnan = General(extension, "zhangnan", "shu", 4)
local os__fenwu = fk.CreateTriggerSkill{
  name = "os__fenwu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return target == player and player:hasSkill(self.name) and
        player.phase == Player.Finish and player.hp > 0 and not player:prohibitUse(Fk:cloneCard("slash"))
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard("slash")
    local availableTargets = table.map(
      table.filter(room:getOtherPlayers(player), function(p)
        return not player:isProhibited(p, card)
      end),
      function(p)
        return p.id
      end
    )
    if #availableTargets == 0 then return false end
    local target = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__fenwu-ask", self.name, true)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    if player.dead then return false end
    local slash = Fk:cloneCard("slash")
    slash.skillName = self.name
    local new_use = {} ---@type CardUseStruct
    new_use.from = player.id
    new_use.tos = { {self.cost_data} }
    new_use.card = slash
    local basic_types = 0
    local basic_cards = {"peach", "slash", "jink", "analeptic"} --...
    for _, b in ipairs(basic_cards) do
      if player:usedCardTimes(b, Player.HistoryTurn) > 0 then
        basic_types = basic_types + 1
      end
    end
    if basic_types > 1 then new_use.additionalDamage = (new_use.additionalDamage or 0) + 1 end
    room:useCard(new_use)
  end,
}
zhangnan:addSkill(os__fenwu)

Fk:loadTranslationTable{
  ["zhangnan"] = "张南",
  ["os__fenwu"] = "奋武",
  [":os__fenwu"] = "结束阶段开始时，你可失去1点体力，视为你对一名其他角色使用一张【杀】。若本回合你使用过超过一种基本牌，此【杀】伤害值基数+1。",
  
  ["#os__fenwu-ask"] = "奋武：你可选择一名其他角色，失去1点体力，视为对其使用一张【杀】",

  ["$os__fenwu1"] = "合围夷道，兵困吴贼！",
  ["$os__fenwu2"] = "纵兵摧城，奋武破敌！",
  ["~zhangnan"] = "骨埋吴地，魂归汉土……",
}

local yuejiu = General(extension, "yuejiu", "qun", 4)
local os__cuijin = fk.CreateTriggerSkill{
  name = "os__cuijin",
  anim_type = "offensive",
  events = {fk.CardUsing, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return (player:inMyAttackRange(target) or target == player) and
        player:hasSkill(self.name) and data.card.trueName == "slash" and not player:isNude()
    else
      return (data.card.extra_data or {}).os__cuijinUser and table.contains((data.card.extra_data or {}).os__cuijinUser, player.id) and not player.dead and not target.dead
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUsing then
      local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, "", "#os__cuijin-ask::" .. target.id, true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:doIndicate(player.id, {target.id})
      room:throwCard(self.cost_data, self.name, player, player)
      data.additionalDamage = (data.additionalDamage or 0) + 1
      data.card.extra_data = data.card.extra_data or {}
      data.card.extra_data.os__cuijinUser = data.card.extra_data.os__cuijinUser or {}
      table.insert(data.card.extra_data.os__cuijinUser, player.id)
    else
      room:doIndicate(player.id, {target.id})
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card and (data.card.extra_data or {}).os__cuijinUser
  end,
  on_refresh = function(self, event, target, player, data)
    data.card.extra_data.os__cuijinUser = nil
  end,
}
yuejiu:addSkill(os__cuijin)

Fk:loadTranslationTable{
  ["yuejiu"] = "乐就",
    ["os__cuijin"] = "催进",
    [":os__cuijin"] = "当你或攻击范围内的角色使用【杀】时，你可弃置一张牌，令此【杀】伤害值基数+1。当此【杀】结算结束后，若此【杀】未造成伤害，你对此【杀】的使用者造成1点伤害。",

  ["#os__cuijin-ask"] = "是否弃置一张牌，对 %dest 发动“催进”",
}

local os__niujin = General(extension, "os__niujin", "wei", 4)
local os__cuorui = fk.CreateTriggerSkill{
  name = "os__cuorui",
  anim_type = "drawcard",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and
      player.phase == Player.Start and 
      player:usedSkillTimes(self.name, Player.HistoryGame) < 1 and
      not table.every(player.room:getOtherPlayers(player), function(p)
        return p:getHandcardNum() <= player:getHandcardNum()
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = player:getHandcardNum()
        for hc, p in ipairs(room:getOtherPlayers(player)) do
            hc = p:getHandcardNum()
            if hc > num then
                num = hc
            end
        end
        num = num - player:getHandcardNum()
        num = num > 5 and 5 or num
    player:drawCards(num, self.name)
    player:skip(Player.Judge)
    if player:getMark("_os__cuorui_invoked") > 0 then
      local victim = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
        return p.id
      end), 1, 1, "#os__cuorui-target", self.name, true)
      if #victim > 0 then victim = room:getPlayerById(victim[1]) end
      room:damage{
        from = player,
        to = victim,
        damage = 1,
        skillName = self.name,
      }
    end
    room:addPlayerMark(player, "_os__cuorui_invoked", 1)
  end,
}

local os__liewei = fk.CreateTriggerSkill{
  name = "os__liewei",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.damage and data.damage.from == player 
  end,
  on_use = function(self, event, target, player, data)
    if player:usedSkillTimes("os__cuorui", Player.HistoryGame) < 1 or 
    player.room:askForChoice(player, {"os__liewei_draw", "os__liewei_cuorui"}, self.name) == "os__liewei_draw" then
      player:drawCards(2, self.name)
    else
      player:addSkillUseHistory("os__cuorui", -1)
    end
  end,
}
os__niujin:addSkill(os__cuorui)
os__niujin:addSkill(os__liewei)

Fk:loadTranslationTable{
  ["os__niujin"] = "牛金",
  ["os__cuorui"] = "挫锐",
  [":os__cuorui"] = "限定技，准备阶段开始时，你可将手牌摸至X张（X为全场最大的手牌数，至多摸五张），跳过此回合的判定阶段。若你发动过〖挫锐〗，你可选择一名其他角色，对其造成1点伤害。", --其实是废除判定区
  ["os__liewei"] = "裂围",
  [":os__liewei"] = "锁定技，当一名角色死亡后，若其是你杀死的，你选择：1.摸两张牌；2.若〖挫锐〗发动过，令〖挫锐〗于此局游戏内的发动次数上限+1。",	

  ["os__liewei_draw"] = "摸两张牌",
  ["os__liewei_cuorui"] = "令〖挫锐〗于此局游戏内的发动次数上限+1",
  ["#os__cuorui-target"] = "挫锐：你可对一名其他角色造成1点伤害",

  ["$os__cuorui1"] = "区区乌合之众，如何困得住我？！",
  ["$os__cuorui2"] = "今日就让你见识见识老牛的厉害！",
  ["$os__liewei1"] = "敌阵已乱，速速突围！",
  ["$os__liewei2"] = "杀你，如同捻死一只蚂蚁！",
  ["~os__niujin"] = "这包围圈太厚，老牛，尽力了……",
}

local liufuren = General(extension, "liufuren", "qun", 3, 3, General.Female)
local os__zhuidu = fk.CreateActiveSkill{
  name = "os__zhuidu",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):isWounded()
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choices = {"os__zhuidu_damage"}
    if #target:getCardIds(Player.Equip) > 0 then table.insert(choices, "os__zhuidu_discard") end
    if target.gender == General.Female and not player:isNude() then table.insert(choices, "beishui_os__zhuidu") end
    local choice = room:askForChoice(player, choices, self.name)
    if choice ~= "os__zhuidu_discard" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
    if choice ~= "os__zhuidu_damage" and #target:getCardIds(Player.Equip) > 0 then
      local card = room:askForCardChosen(player, target, "e", self.name)
      room:throwCard(card, self.name, target, player)
    end
    if choice == "beishui_os__zhuidu" and not player:isNude() then
      room:askForDiscard(player, 1, 1, true, self.name, false)
    end
  end,
}

local os__shigong = fk.CreateTriggerSkill{
  name = "os__shigong",
  anim_type = "support",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and player.phase == Player.NotActive and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local current = room.current
    local choices = {"os__shigong_max"}
    if current:getHandcardNum() >= current.hp then table.insert(choices, "os__shigong_dis") end
    if room:askForChoice(current, choices, self.name) == "os__shigong_max" then
      room:changeMaxHp(current, 1)
      room:recover({
        who = current,
        num = 1,
        recoverBy = current,
        skillName = self.name,
      })
      current:drawCards(1, self.name)
      room:recover({
        who = player,
        num = player.maxHp - player.hp,
        recoverBy = player,
        skillName = self.name,
      })
    else
      room:askForDiscard(current, current.hp, current.hp, false, self.name, false)
      room:recover({
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = self.name,
      })
    end
  end,
}

liufuren:addSkill(os__zhuidu)
liufuren:addSkill(os__shigong)

Fk:loadTranslationTable{
  ["liufuren"] = "刘夫人",
  ["os__zhuidu"] = "追妒",
  [":os__zhuidu"] = "出牌阶段限一次，你可选择一名受伤的其他角色并选择一项：1.你对其造成1点伤害；2.你弃置其装备区的一张牌；若其为女性角色，则你可背水：（在其执行完所有可执行的选项后）弃置一张牌。",
  ["os__shigong"] = "示恭",
  [":os__shigong"] = "限定技，当你回合外进入濒死状态时，你可令当前回合者选择一项：1. 增加1点体力上限，回复1点体力，摸一张牌，令你体力回复至体力上限；2. 弃置X张手牌（X为其当前体力值），令你体力回复至1点。",
  
  ["os__zhuidu_damage"] = "对其造成1点伤害",
  ["os__zhuidu_discard"] = "弃置其装备区的一张牌",
  ["beishui_os__zhuidu"] = "背水：你弃置一张牌",
  ["os__shigong_max"] = "令其体力回复至体力上限",
  ["os__shigong_dis"] = "令其体力回复至1点",
}

local os__dengzhi = General(extension, "os__dengzhi", "shu", 3)
local os__jimeng = fk.CreateActiveSkill{
  name = "os__jimeng",
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isAllNude() --不能用Self
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "hej", self.name)
    room:obtainCard(effect.from, id, false)

    local c = room:askForCard(player, 1, 1, true, self.name, false, "", "#os__jimeng-card::" .. target.id)[1]
    room:moveCardTo(c, Player.Hand, target, fk.ReasonGive, self.name, nil, false)

    if target.hp >= player.hp then
      player:drawCards(1, self.name)
    end
  end,
}

local os__shuaiyan = fk.CreateTriggerSkill{
  name = "os__shuaiyan",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Discard and player:getHandcardNum() > 1 and
      not table.every(player.room:getOtherPlayers(player), function(p)
        return p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askForChoosePlayers(
      player,
      table.map(
        table.filter(room:getOtherPlayers(player), function(p)
          return not p:isNude()
        end),
        function(p)
          return p.id
        end
      ),
      1,
      1,
      "#os__shuaiyan-ask",
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
    player:showCards(player:getCardIds(Player.Hand))
    local target = room:getPlayerById(self.cost_data)
    if not target:isNude() then
      local c = room:askForCard(target, 1, 1, true, self.name, false, "", "#os__shuaiyan-card::" .. player.id)[1]
      room:moveCardTo(c, Player.Hand, player, fk.ReasonGive, self.name, nil, false)
    end
  end,
}
os__dengzhi:addSkill(os__jimeng)
os__dengzhi:addSkill(os__shuaiyan)

Fk:loadTranslationTable{
  ["os__dengzhi"] = "邓芝",
  ["os__jimeng"] = "急盟",
  [":os__jimeng"] = "出牌阶段限一次，你可获得一名其他角色区域内的一张牌，然后交给其一张牌。若其体力值不小于你，你摸一张牌。",
  ["os__shuaiyan"] = "率言",
  [":os__shuaiyan"] = "弃牌阶段开始时，若你的手牌数大于1，你可展示所有手牌，令一名其他角色交给你一张牌。",

  ["#os__jimeng-card"] = "急盟：交给 %dest 一张牌",
  ["#os__shuaiyan-ask"] = "率言：你可展示所有手牌，选择一名其他角色，令其交给你一张牌",
  ["#os__shuaiyan-card"] = "率言：交给 %dest 一张牌",
}

local os__jiachong = General(extension, "os__jiachong", "qun", 3)

local os__beini = fk.CreateActiveSkill{
  name = "os__beini",
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select).hp >= Self.hp
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local drawer = room:askForChoosePlayers(player, {effect.from, effect.tos[1]}, 1, 1, "#os__beini-target::" .. effect.tos[1], self.name, false)
    if #drawer == 0 then drawer = table.random({effect.from, effect.tos[1]}, 1) end --权宜
    if #drawer > 0 then
      local slasher = drawer[1] == effect.tos[1] and player or target
      drawer = room:getPlayerById(drawer[1]) 
      drawer:drawCards(2, self.name)
      room:useVirtualCard("slash", nil, slasher, {drawer}, self.name, true)
    end
  end,
}

local os__dingfa = fk.CreateTriggerSkill{
  name = "os__dingfa",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and player.phase == Player.Discard and player:getMark("@os__dingfa-turn") >= player.hp
  end,
  on_cost = function(self, event, target, player, data) --其实可以改成可选择所有角色，若是别人则造成伤害，自己则回复，但会不会有点奇怪
    local room = player.room
    local choices = {"os__dingfa_damage", "Cancel"}
    if player.hp < player.maxHp then table.insert(choices, 2, "os__dingfa_recover") end
    local choice = room:askForChoice(player, choices, self.name)
    
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "os__dingfa_recover" then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    else
      local victim = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
        return p.id
      end), 1, 1, "#os__dingfa-target", self.name, true)
      if #victim > 0 then
        victim = room:getPlayerById(victim[1]) 
        room:damage{
          from = player,
          to = victim,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(self.name) or player.phase == Player.NotActive then return false end
    local x = 0
    for _, move in ipairs(data) do
      if move.from == player.id then
        if table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end) then return true end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local x = 0
    for _, move in ipairs(data) do
      if move.from == player.id then
        x = x + #table.filter(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end)
      end
    end
    if x > 0 then 
      player.room:addPlayerMark(player, "@os__dingfa-turn", x)
    end
  end,
}

os__jiachong:addSkill(os__beini)
os__jiachong:addSkill(os__dingfa)

Fk:loadTranslationTable{
  ["os__jiachong"] = "贾充",
  ["os__beini"] = "悖逆",
  [":os__beini"] = "出牌阶段限一次，你可以选择一名体力值不小于你的角色，令你或其摸两张牌，然后未摸牌的角色视为对摸牌的角色使用一张【杀】。",
  ["os__dingfa"] = "定法",
  [":os__dingfa"] = "弃牌阶段结束时，若本回合你失去的牌数不小于你的体力值，你可以选择一项：1. 回复1点体力；2. 对一名其他角色造成1点伤害。",

  ["#os__beini-target"] = "悖逆：选择你或 %dest ，令其摸两张牌并被【杀】",
  ["@os__dingfa-turn"] = "定法",
  ["os__dingfa_damage"] = "对一名其他角色造成1点伤害",
  ["os__dingfa_recover"] = "回复1点体力",
  ["#os__dingfa-target"] = "定法：选择一名其他角色，对其造成1点伤害",
}
--[[
local os__haomeng = General(extension, "os__haomeng", "qun", 4)

function getSkillsNum(player)  --判断技能数，装备技能除外，飞扬跋扈手动
  local skills = {}
  for _, s in ipairs(player.player_skills) do
    if not (s.attached_equip or s.name == "m_feiyang" or s.name == "m_bahu") then
      table.insert(skills, s)
    end
  end
  return #skills
end

local os__gongge = fk.CreateTriggerSkill{
  name = "os__gongge",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return 
      target == player and
      player:hasSkill(self.name) and
      data.firstTarget and player:usedSkillTimes(self.name) < 1 and
      data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local alivePlayers = room.alive_players
    local availableTargets = {}
    for _, p in ipairs(alivePlayers) do
      if table.contains(AimGroup:getAllTargets(data.tos), p.id) then
        table.insert(availableTargets, p.id)
      end
    end

    if #availableTargets == 0 then
      return false
    end
    local result
    if #availableTargets == 1 then
      result = availableTargets[1]
    else
      result = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__gongge-ask", self.name)
      if #result > 0 then
        result = result[1]
      else
        return false
      end
    end
    local target = room:getPlayerById(result)
    local x = getSkillsNum(target)
    local choices = {"os__gongge_draw", "os__gongge_damage", "Cancel"}
    if #target:getCardIds(Player.Equip) + #target:getCardIds(Player.Hand) > x then table.insert(choices, 2, "os__gongge_discard") end
    local choice = room:askForChoice(player, choices, self.name, "#os__gongge-choice:::" .. x)
    if choice ~= "Cancel" then
      self.cost_data = {result, choice}
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "_os__gongge", data.card.id)
    local target = room:getPlayerById(self.cost_data[1])
    room:setPlayerMark(player, "_os__gongge_target", self.cost_data[1])
    local choice = self.cost_data[2]
    local x = getSkillsNum(target)
    if choice == "os__gongge_draw" then
      player:drawCards(x+1, self.name)
      room:setPlayerMark(player, "@os__gongge", "gg_draw")
    elseif choice == "os__gongge_discard" then
      local cards = room:askForCardsChosen(player, target, x+1, x+1, "he", self.name)
      room:throwCard(cards, self.name, target, player)
      room:setPlayerMark(player, "@os__gongge", "gg_discard")
    elseif choice == "os__gongge_damage" then
      room:setPlayerMark(player, "@os__gongge", "gg_damage")
      --data.additionalDamage = (data.additionalDamage or 0) + x
    end
  end,

  refresh_events = {fk.CardUseFinished, fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(self.name) or not target == player then return false end
    if event == fk.CardUseFinished then
      if player:getMark("@os__gongge") == "gg_draw" then
        local use = data
        local effect = use.responseToEvent
        if effect and effect.from == player.id and use.toCard and use.toCard.id == player:getMark("_os__gongge") then
          return true end
      end
      if player:getMark("@os__gongge") ~= 0 then
        return (data.card.id and data.card.id == player:getMark("_os__gongge"))
      end
      return false
    else
      if player:getMark("@os__gongge") == "gg_damage" and data.to.id == player:getMark("_os__gongge_target") then
        return true
      end
    end
    return false
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      if data.card.id and data.card.id == player:getMark("_os__gongge") then
        local room = player.room
        local target = room:getPlayerById(player:getMark("_os__gongge_target"))
        if not target:isAlive() then
          room:setPlayerMark(player, "@os__gongge", 0)
        end
        local x = getSkillsNum(target)
        if player:getMark("@os__gongge") == "gg_discard" then
          if target.hp >= player.hp then
            local cids
            if #player:getCardIds(Player.Equip) + #player:getCardIds(Player.Hand) > x then
              cids = room:askForCard(player, x, x, true, self.name, false, "", "#os__gongge-cards::" .. target.id .. ":" .. x)
            else
              cids = player:getCardIds(Player.Hand)
              table.insertTable(cids, player:getCardIds(Player.Equip))
            end
            local cards = table.map(cids, function(p) 
              return Fk:getCardById(p)
            end)
            
            if #cards > 0 then
              local dummy = Fk:cloneCard'slash'
              dummy:addSubcards(cards)
              room:obtainCard(target, dummy, false, fk.ReasonGive)
            end
          end
        elseif player:getMark("@os__gongge") == "gg_damage" then
          room:recover({
            who = target,
            num = x,
            recoverBy = target,
            skillName = self.name,
          })
        end
        room:setPlayerMark(player, "@os__gongge", 0)
      else
        player:skip(Player.Draw)
        player.room:setPlayerMark(player, "@os__gongge", 0)
      end
    else
      data.damage = data.damage + getSkillsNum(data.to)
    end
  end,
}

os__haomeng:addSkill(os__gongge)

Fk:loadTranslationTable{
  ["os__haomeng"] = "郝萌",
  ["os__gongge"] = "攻阁",
  [":os__gongge"] = "当你使用伤害类的牌指定第一个目标后，你可选择其中一个目标并选择：1、摸X+1张牌，若此牌被其响应，你跳过下次摸牌阶段。" .. 
  "2、弃置其X+1张牌，此牌结算后，若其体力值不小于你，你交给其X张牌。3、此牌对其伤害值基数+X，此牌结算后其回复X点体力。（X为其武将技能数）",
  ["#os__gongge-ask"] = "攻阁：你可对一名目标发动“攻阁”",

  ["#os__gongge-choice"] = "攻阁：请选择一项（X=%arg）",
  ["os__gongge_draw"] = "摸 X+1 张牌",
  ["os__gongge_discard"] = "弃置其 X+1 张牌",
  ["os__gongge_damage"] = "伤害 +X",
  ["@os__gongge"] = "攻阁",
  ["gg_draw"] = "摸牌",
  ["gg_discard"] = "弃牌",
  ["gg_damage"] = "加伤",
  ["#os__gongge-cards"] = "攻阁：交给 %dest %arg张牌",
}
]]--

local os_sp__yujin = General(extension, "os_sp__yujin", "qun", 4)
local os__zhenjun = fk.CreateTriggerSkill{
  name = "os__zhenjun",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local plist, cid = player.room:askForChooseCardAndPlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id
    end), 1, 1, nil, "#os__zhenjun-target", self.name, true)
    if #plist > 0 then
      self.cost_data = {plist[1], cid}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = self.cost_data[1]
    room:doIndicate(player.id, { to })
    local target = room:getPlayerById(to)
    room:moveCardTo(self.cost_data[2], Player.Hand, target, fk.ReasonGive, self.name, nil, false)
    local use = room:askForUseCard(target, "slash", "slash|.|heart,diamond,nosuit", "#os__zhenjun_slash", true)
    if use then
      use.extra_data = use.extra_data or {}
      use.extra_data.os__zhenjunUser = player.id
      room:useCard(use)
      player:drawCards(player:getMark("_os__zhenjun_damage-phase") + 1, self.name)
    else
      room:setPlayerMark(target, "_os__zhenjun_target", 0)
      local victim = room:askForChoosePlayers(
        player,
        table.map(
          table.filter(room.alive_players, function(p)
            return (p == target or target:inMyAttackRange(p)  )
          end),
          function(p)
            return p.id
          end
        ),
        1,
        1,
        "#os__zhenjun-damage::" .. to,
        self.name,
        true
      )
      if #victim > 0 then 
        victim = room:getPlayerById(victim[1]) 
        room:damage{
        from = player,
        to = victim,
        damage = 1,
        skillName = self.name,
        }
      end
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    return parentUseData and (parentUseData.data[1].extra_data or {}).os__zhenjunUser == player.id
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__zhenjun_damage-phase", data.damage)
  end,
}
os_sp__yujin:addSkill(os__zhenjun)

Fk:loadTranslationTable{
  ["os_sp__yujin"] = "于禁",
  ["os__zhenjun"] = "镇军",
  [":os__zhenjun"] = "出牌阶段开始时，你可交给一名其他角色一张牌，令其使用一张非黑色的【杀】：若其执行，则此【杀】结算后你摸一张牌，若此【杀】造成过伤害，你额外摸伤害值数张牌；若其不执行，则你可对其或其攻击范围内的一名角色造成1点伤害。",

  ["#os__zhenjun-target"] = "你可选择一张牌，交给一名其他角色，对其发动“镇军”",
  ["#os__zhenjun_slash"] = "镇军：请使用一张非黑色的【杀】",
  ["#os__zhenjun-damage"] = "镇军：你可对 %dest 或其攻击范围内的一名角色造成1点伤害",
}

local os__tianyu = General(extension, "os__tianyu", "wei", 4) --但，国际服测试服先上线，十周年测试服后上线

local os__zhenxi = fk.CreateTriggerSkill{
  name = "os__zhenxi",
  anim_type = "control",
  events = {fk.TargetSpecified},    
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and
      data.card.trueName == "slash" and player:usedSkillTimes(self.name) < 1 and data.to then
      local to = player.room:getPlayerById(data.to)
      if to:getHandcardNum() >= player:distanceTo(to) then return true end
      return table.find(player.room.alive_players, function(p) return to:canMoveCardsInBoardTo(p, nil) end)
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    local room = player.room
    local target = room:getPlayerById(data.to)
    if target:getHandcardNum() >= player:distanceTo(target) then
      table.insert(choices, "os__zhenxi_discard:::" .. player:distanceTo(target))
    end
    if table.find(player.room.alive_players, function(p)
      return target:canMoveCardsInBoardTo(p, nil)
    end) then
      table.insert(choices, "os__zhenxi_move")
    end
    if (target.hp > player.hp or table.every(room:getOtherPlayers(target), function(p)
      return target.hp >= p.hp
    end)) then
      table.insert(choices, "beishui_os__zhenxi")
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
    local target = room:getPlayerById(data.to)
    local choice = self.cost_data
    local n = player:distanceTo(target)
    if choice ~= "os__zhenxi_move" and target:getHandcardNum() >= player:distanceTo(target) then
      local cards = room:askForCardsChosen(player, target, n, n, "h", self.name)
      room:throwCard(cards, self.name, target, player)
    end
    if choice == "os__zhenxi_move" or choice == "beishui_os__zhenxi" then
      local targets = table.map(table.filter(player.room.alive_players, function(p)
        return target:canMoveCardsInBoardTo(p, nil)
      end), function(p) return p.id end)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#os__zhenxi-ask:" .. target.id, self.name, false)
        if #to > 0 then
          room:askForMoveCardInBoard(player, target, room:getPlayerById(to[1]), self.name, nil, target)
        end
      end
    end
  end,
}

local os__yangshi = fk.CreateTriggerSkill{
  name = "os__yangshi",
  anim_type = "masochism",
  events = {fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and not player.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.every(room:getOtherPlayers(player), function(p)
      return player:inMyAttackRange(p)
    end) then
      local cids = room:getCardsFromPileByRule("slash")
      if #cids > 0 then
        room:obtainCard(player, cids[1], false, fk.ReasonPrey)
      end
    else
      room:addPlayerMark(player, "@" .. self.name, 1)
    end
  end,
}
local os__yangshiAR = fk.CreateAttackRangeSkill{
  name = "#os__yangshiAR",
  correct_func = function(self, from, to)
    return from:getMark("@os__yangshi")
  end,
}
os__yangshi:addRelatedSkill(os__yangshiAR)

os__tianyu:addSkill(os__zhenxi)
os__tianyu:addSkill(os__yangshi)

Fk:loadTranslationTable{
  ["os__tianyu"] = "田豫",
  ["os__zhenxi"] = "震袭",
  [":os__zhenxi"] = "每回合限一次，当你使用【杀】指定目标后，你可选择一项：1.弃置其X张手牌（X为你至其的距离）；2.移动其场上的一张牌。若其体力值大于你或为全场最高，则你可背水。",
  ["os__yangshi"] = "扬师",
  [":os__yangshi"] = "锁定技，当你受到伤害后，你的攻击范围+1，若所有其他角色均在你的攻击范围内，则改为从牌堆获得一张【杀】。",

  ["os__zhenxi_discard"] = "弃置其%arg张手牌",
  ["os__zhenxi_move"] = "移动其场上的一张牌",
  ["beishui_os__zhenxi"] = "背水",
  ["#os__zhenxi-ask"] = "震袭：选择要将 %src 场上的牌移动给的角色",
  ["@os__yangshi"] = "扬师",
}

local os__fuwan = General(extension, "os__fuwan", "qun", 4)
local os__moukui = fk.CreateTriggerSkill{
  name = "os__moukui",
  anim_type = "control",
  events = {fk.TargetSpecified},    
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
    data.card.trueName == "slash" and data.to
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"os__moukui_draw", "beishui_os__moukui", "Cancel"}
    local target = room:getPlayerById(data.to)
    if not target:isNude() then
      table.insert(choices, 2, "os__moukui_discard")
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
    local target = room:getPlayerById(data.to)
    if choice ~= "os__moukui_discard" then
      player:drawCards(1, self.name)
    end
    if choice ~= "os__moukui_draw" then
      if not target:isNude() then
        local card = room:askForCardChosen(player, target, "h", self.name)
        room:throwCard(card, self.name, target, player)
      end
      if choice == "beishui_os__moukui" then
        data.card.extra_data = data.card.extra_data or {}
        data.card.extra_data.os__moukuiUser = player.id
        data.card.extra_data.os__moukuiTargets = data.card.extra_data.os__moukuiTargets or {}
        table.insert(data.card.extra_data.os__moukuiTargets, target.id)
      end
    end
  end,

  refresh_events = {fk.CardUseFinished, fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EnterDying then
      return data.damage and data.damage.card and (data.damage.card.extra_data or {}).os__moukuiUser == player.id and (data.damage.card.extra_data or {}).os__moukuiTargets and table.contains((data.damage.card.extra_data or {}).os__moukuiTargets, target.id)
    else
      return player == target and (data.card.extra_data or {}).os__moukuiUser == player.id and (data.card.extra_data or {}).os__moukuiTargets
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EnterDying then
      table.removeOne((data.damage.card.extra_data or {}).os__moukuiTargets, target.id)
    else
      local room = player.room
      for _, pid in ipairs((data.card.extra_data or {}).os__moukuiTargets) do
        local target = room:getPlayerById(pid)
        if not player:isNude() then
          room:throwCard(room:askForCardChosen(target, player, "he", self.name), self.name, player, target)
        end
      end
    end
  end,
}

os__fuwan:addSkill(os__moukui)

Fk:loadTranslationTable{
  ["os__fuwan"] = "付完",
  ["os__moukui"] = "谋溃",
  [":os__moukui"] = "当你使用【杀】指定目标后，你可选择一项：1.摸一张牌；2.弃置其一张手牌；背水：此【杀】结算后，若此【杀】未令其进入濒死状态，其弃置你一张牌。",

  ["os__moukui_draw"] = "摸一张牌",
  ["os__moukui_discard"] = "弃置其一张手牌",
  ["beishui_os__moukui"] = "背水：若此【杀】未令其进入濒死状态，其弃置你一张牌",
}


local os__furong = General(extension, "os__furong", "shu", 4)

local os__xuewei = fk.CreateTriggerSkill{
  name = "os__xuewei",
  events = {fk.EventPhaseStart},
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self.name) and target.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryRound) < 1 and #player.room.alive_players > 2
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(
      player,
      table.map(
        table.filter(room:getOtherPlayers(target), function(p)
          return (p ~= player)
        end),
        function(p)
          return p.id
        end
      ),
      1,
      1,
      "#os__xuewei-ask::" .. target.id,
      self.name,
      true
    )

    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if room:askForChoice(target, {"os__xuewei_defence", "os__xuewei_duel"}, self.name, "#os__xuewei-target::" .. to.id) == "os__xuewei_defence" then
      room:addPlayerMark(target, "_os__xuewei_defence_from-turn", 1)
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, 2)
      room:addPlayerMark(to, "_os__xuewei_defence_to-turn", 1)
      room:sendLog{
        type = "#os__xuewei_defence",
        from = target.id,
        to = {to.id},
        arg = self.name
      }
    else
      local duel = Fk:cloneCard("duel")
      duel.skillName = self.name
      local new_use = {} ---@type CardUseStruct
      new_use.from = player.id
      new_use.tos = { {target.id} }
      new_use.card = duel
      room:useCard(new_use)
    end
  end,
}

local os__xuewei_prohibit = fk.CreateProhibitSkill{
  name = "#os__xuewei_prohibit",
  is_prohibited = function(self, from, to, card)
    if from:getMark("_os__xuewei_defence_from-turn") > 0 and to:getMark("_os__xuewei_defence_to-turn") > 0 then
      return card.trueName == "slash"
    end
  end,
}

local os__liechi = fk.CreateTriggerSkill{
  name = "os__liechi",
  events = {fk.Damaged},
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and not player.dead and data.from ~= nil and data.from.hp >= player.hp and not data.from.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = data.from
    local choices = {}
    if from:getHandcardNum() > player:getHandcardNum() then table.insert(choices, "os__liechi_same") end
    if not from:isNude() then table.insert(choices, "os__liechi_one") end
    if player:getMark("_os__liechi_dying-turn") > 0 then
      local cids = player:getCardIds(Player.Equip)
      table.insertTable(cids, player:getCardIds(Player.Hand))
      for _, id in ipairs(cids) do
        if Fk:getCardById(id).type == Card.TypeEquip then
          table.insert(choices, "beishui_os__liechi")
          break
        end
      end
    end
    if #choices == 0 then return false end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "beishui_os__liechi" then
      room:askForDiscard(player, 1, 1, true, self.name, false, ".|.|.|.|.|equip")
    end
    if choice ~= "os__liechi_one" then
      local n = from:getHandcardNum() - player:getHandcardNum()
      if n > 0 then
        room:askForDiscard(from, n, n, false, self.name, false)
      end
    end
    if choice ~= "os__liechi_same" then
      if not from:isNude() then
        local card = room:askForCardChosen(player, from, "he", self.name)
        room:throwCard(card, self.name, from, player)
      end
    end
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__liechi_dying-turn", 1)
  end,
}
os__xuewei:addRelatedSkill(os__xuewei_prohibit)

os__furong:addSkill(os__xuewei)
os__furong:addSkill(os__liechi)

Fk:loadTranslationTable{
  ["os__furong"] = "傅肜",
  ["os__xuewei"] = "血卫",
  [":os__xuewei"] = "每轮限一次，其他角色A的出牌阶段开始时，你可选择另一名其他角色B并令A选择一项：1. 直到本回合结束，其不能对B使用【杀】且手牌上限-2；2. 视为你对其使用一张【决斗】。",
  ["os__liechi"] = "烈斥",
  [":os__liechi"] = "锁定技，当你受到伤害后，若你的体力值不大于伤害来源，你选择一项：1.令其将手牌弃至与你手牌数相同；2.弃置其一张牌；若本回合你进入过濒死状态，则你可背水：弃置一张装备牌。",

  ["#os__xuewei-ask"] = "你可选择一名除 %dest 以外的其他角色，发动“血卫”",
  ["#os__xuewei-target"] = "血卫：请选择一项（傅肜指定的角色为 %dest）",
  ["os__xuewei_defence"] = "直到本回合结束，你不能对 傅肜 指定的角色使用【杀】且手牌上限-2",
  ["os__xuewei_duel"] = "视为 傅肜 对你使用一张【决斗】",
  ["#os__xuewei_defence"] = "%from 由于“%arg”，不能对 %to 使用【杀】且手牌上限-2",
  ["os__liechi_same"] = "令其将手牌弃至与你手牌数相同",
  ["os__liechi_one"] = "你弃置其一张牌",
  ["beishui_os__liechi"] = "背水：你弃置一张装备牌",

  ["$os__xuewei1"] = "吾主之尊，岂容尔等贼寇近前？",
  ["$os__xuewei2"] = "血佑忠魂，身卫英主。",
  ["$os__liechi1"] = "吾受汉帝恩，岂容吴贼辱？",
  ["$os__liechi2"] = "汉将有死无降，怎会如吴狗一般？",
  ["~os__furong"] = "吾主既然得返，此番已是功成……",
}

local liwei = General(extension, "liwei", "shu", 4)

local os__jiaohua = fk.CreateTriggerSkill{
  name = "os__jiaohua",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    for _, move in ipairs(data) do
      local target = move.to and player.room:getPlayerById(move.to) or nil --moveData没有target
      if target and (move.to == player.id or table.every(player.room.alive_players, function(p)
          return p.hp >= target.hp
        end)) and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
        local cardType = {"basic", "trick", "equip"}
        if type(player:getMark("_os__jiaohua-turn")) == "table" then
          table.forEach(player:getMark("_os__jiaohua-turn"), function(name)
            table.removeOne(cardType, name)
          end)
        end
        if #cardType == 0 then return false end
        for _, info in ipairs(move.moveInfo) do
          table.removeOne(cardType, Fk:getCardById(info.cardId):getTypeString())
        end
        if #cardType > 0 then
          return true
        end
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      local target = move.to and player.room:getPlayerById(move.to) or nil --moveData没有target
      if target and (move.to == player.id or table.every(player.room.alive_players, function(p)
          return p.hp >= target.hp
        end)) and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
        local cardType = {"basic", "trick", "equip"}
        if type(player:getMark("_os__jiaohua-turn")) == "table" then
          table.forEach(player:getMark("_os__jiaohua-turn"), function(name)
            table.removeOne(cardType, name)
          end)
        end
        if #cardType == 0 then return false end
        for _, info in ipairs(move.moveInfo) do
          table.removeOne(cardType, Fk:getCardById(info.cardId):getTypeString())
        end
        if #cardType > 0 then
          self.cost_data = {target.id, table.concat(cardType, ",")}
          return player.room:askForSkillInvoke(player, self.name, data, "#os__jiaohua::" .. target.id)
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = string.split(self.cost_data[2], ",")
    local choice = room:askForChoice(player, types, self.name, "#os__jiaohua-ask::" .. self.cost_data[1])
    local id = room:getCardsFromPileByRule(".|.|.|.|.|" .. choice, 1, "allPiles")
    if #id > 0 then
      room:obtainCard(self.cost_data[1], id[1], false, fk.ReasonPrey)
      local mark = type(player:getMark("_os__jiaohua-turn")) == "table" and player:getMark("_os__jiaohua-turn") or {}
      table.insert(mark, Fk:getCardById(id[1]):getTypeString())
      room:setPlayerMark(player, "_os__jiaohua-turn", mark)
    end
  end,
}

liwei:addSkill(os__jiaohua)

Fk:loadTranslationTable{
  ["liwei"] = "李遗",
  ["os__jiaohua"] = "教化",
  [":os__jiaohua"] = "当你或体力值最小的角色摸牌后，你可选择一种其本次摸牌未获得的类别（每种类别每回合限一次），令其从牌堆中或弃牌堆中获得一张该类别的牌。",

  ["#os__jiaohua"] = "你想对 %dest 发动技能“教化”吗？",
  ["#os__jiaohua-ask"] = "教化：选择一种类别，令 %dest 从牌堆中或弃牌堆中获得一张该类别的牌",
  ["basic"] = "基本牌",
  ["trick"] = "锦囊牌",
  ["equip"] = "装备牌", --这好吗
}

local niufudongxie = General(extension, "niufudongxie", "qun", 4, 4, General.Bigender)

local os__juntun = fk.CreateTriggerSkill{
  name = "os__juntun",
  anim_type = "offensive",
  events = {fk.GameStart, fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(
      table.filter(room.alive_players, function(p)
        return (not p:hasSkill("os__xiongjun"))
      end),
      function(p)
        return p.id
      end
    )
    if #targets == 0 then return false end
    local target = room:askForChoosePlayers(player, targets, 1, 1, "#os__juntun-ask", self.name, true)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(room:getPlayerById(self.cost_data), "os__xiongjun", nil)
  end,

  refresh_events = {fk.Damage, fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target  and player:hasSkill(self.name) and not target.dead and (target == player or (event == fk.Damage and target:hasSkill("os__xiongjun"))) and player:getMark("@os__baonue") < 5 and not player.dead
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@os__baonue", 1)
  end,
}

local os__xiongxi = fk.CreateActiveSkill{
  name = "os__xiongxi",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = function() return 5 - Self:getMark("@os__baonue") end,
  card_filter = function(self, to_select, selected)
    return #selected < 5 - Self:getMark("@os__baonue")
  end,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = self.name,
    }
  end,
}

local os__xiafeng = fk.CreateTriggerSkill{
  name = "os__xiafeng",
  anim_type = "offensive", --哈哈
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.phase == Player.Play and player:getMark("@os__baonue") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    for i = 1, math.min(3, player:getMark("@os__baonue")) do
      table.insert(choices, tostring(i))
    end
    table.insert(choices, "Cancel")
    local choice = player.room:askForChoice(player, choices, self.name, "#os__xiafeng")
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local num = tonumber(self.cost_data)
    local room = player.room
    room:setPlayerMark(player, "_os__xiafeng-turn", num)
    room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, num)
    room:removePlayerMark(player, "@os__baonue", num)
    room:sendLog{
      type = "#os__xiafeng_log",
      from = player.id,
      arg = self.cost_data,
    }
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return player == target
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__xiafeng_count-turn", 1)
  end,
}
local os__xiafeng_disres = fk.CreateTriggerSkill{
  name = "#os__xiafeng_disres",
  mute = true,
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("_os__xiafeng_count-turn") <= player:getMark("_os__xiafeng-turn") and player:getMark("_os__xiafeng-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, target in ipairs(player.room.alive_players) do
      table.insertIfNeed(data.disresponsiveList, target.id)
    end
  end,
}
local os__xiafeng_buff = fk.CreateTargetModSkill{
  name = "#os__xiafeng_buff",
  residue_func = function(self, player, skill)
    return (player:getMark("_os__xiafeng_count-turn") <= player:getMark("_os__xiafeng-turn") and player:getMark("_os__xiafeng-turn") > 0) and 999 or 0
  end,
  distance_limit_func = function(self, player, skill)
    return (player:getMark("_os__xiafeng_count-turn") <= player:getMark("_os__xiafeng-turn") and player:getMark("_os__xiafeng-turn") > 0) and 999 or 0
  end,
}

os__xiafeng:addRelatedSkill(os__xiafeng_disres)
os__xiafeng:addRelatedSkill(os__xiafeng_buff)

local os__xiongjun = fk.CreateTriggerSkill{
  name = "os__xiongjun",
  anim_type = "drawcard",
  events = {fk.Damage},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("_damage_times-turn") == 1
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(player.room.alive_players) do
      if p:hasSkill(self.name) then
        p:drawCards(1, self.name)
      end
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_damage_times-turn", 1)
  end,
}

niufudongxie:addSkill(os__juntun)
niufudongxie:addSkill(os__xiongxi)
niufudongxie:addSkill(os__xiafeng)
niufudongxie:addRelatedSkill(os__xiongjun)

Fk:loadTranslationTable{
  ["niufudongxie"] = "牛辅董翓",
  ["os__juntun"] = "军屯",
  [":os__juntun"] = "游戏开始时或当其他角色死亡后，你可令一名没有〖凶军〗的角色获得〖凶军〗。当拥有〖凶军〗的其他角色造成伤害后，你获得等量暴虐值。<br/>" .. 
    "<font color='grey'>#\"<b>暴虐值</b>\"<br/>当你造成或受到伤害后，你获得等量暴虐值。暴虐值上限为5。</font>",
  ["os__xiongxi"] = "凶袭",
  [":os__xiongxi"] = "出牌阶段限一次，你可弃置X张牌对一名其他角色造成1点伤害。（X=5-暴虐值，且可为0）",
  ["os__xiafeng"] = "黠凤",
  [":os__xiafeng"] = "出牌阶段开始时，你可消耗至多3点暴虐值，令你本回合使用的前X张牌无距离和次数限制且不可被响应，手牌上限+X。（X为消耗暴虐值）",
  ["os__xiongjun"] = "凶军",
  [":os__xiongjun"] = "锁定技，当你于一个回合内第一次造成伤害后，所有拥有〖凶军〗的角色各摸一张牌。",

  ["@os__baonue"] = "暴虐值",
  ["#os__juntun-ask"] = "军屯：你可令一名没有〖凶军〗的角色获得〖凶军〗",
  ["#os__xiafeng"] = "黠凤：本回合使用的前X张牌无距离和次数限制且不能被响应，手牌上限+X",
  ["#os__xiafeng_log"] = "%from 消耗了 %arg 点暴虐值",
}

local baoxin = General(extension, "baoxin", "qun", 4)

local os__mutao = fk.CreateActiveSkill{
  name = "os__mutao",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function() return false end,
  card_num = 0,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local to = target
    while true do --判断有没有没有杀，又要考虑给出杀后又来杀的情况
      local cids = table.filter(target:getCardIds(Player.Hand), function(id)
        return Fk:getCardById(id).trueName == "slash"
      end)
      if #cids < 1 then break end
      to = to:getNextAlive()
      if to == target then to = to:getNextAlive() end
      local id = cids[math.random(1, #cids)]
      room:moveCardTo(id, Player.Hand, to, fk.ReasonGive, self.name, nil, false)
    end
    room:damage{
      from = target,
      to = to,
      damage = math.min(#table.filter(to:getCardIds(Player.Hand), function(id)
        return Fk:getCardById(id).trueName == "slash"
      end), 3),
      skillName = self.name,
    }
  end,
}

local os__yimou = fk.CreateTriggerSkill{
  name = "os__yimou",
  events = {fk.Damaged},
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target:distanceTo(player) < 2 and not (target.dead or player.dead)
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"os__yimou_slash"}
    if not target:isKongcheng() then table.insert(choices, "os__yimou_give") end
    if target ~= player and not player:isKongcheng() then table.insert(choices, "beishui_os__yimou") end
    table.insert(choices, "Cancel")
    local room = player.room
    local choice = room:askForChoice(player, choices, self.name, "#os__yimou::" .. target.id)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data
    if choice == "beishui_os__yimou" then
      room:moveCardTo(player:getCardIds(Player.Hand), Player.Hand, target, fk.ReasonGive, self.name, nil, false)
    end
    if choice ~= "os__yimou_give" then
      local id = room:getCardsFromPileByRule("slash")
      if #id > 0 then
        room:obtainCard(target, id[1], false, fk.ReasonPrey)
      end
    end
    if choice ~= "os__yimou_slash" and not target:isKongcheng() then
      local plist, cid = room:askForChooseCardAndPlayers(target, table.map(room:getOtherPlayers(target), function(p)
        return p.id
      end), 1, 1, ".|.|.|hand", "#os__yimou_give", self.name, false)
      room:moveCardTo(cid, Player.Hand, room:getPlayerById(plist[1]), fk.ReasonGive, self.name, nil, false)
      target:drawCards(2, self.name)
    end
  end,
}

baoxin:addSkill(os__mutao)
baoxin:addSkill(os__yimou)

Fk:loadTranslationTable{
  ["baoxin"] = "鲍信",
  ["os__mutao"] = "募讨",
  [":os__mutao"] = "出牌阶段限一次，你可选择一名角色，令其将手牌中的（系统选择）每一张【杀】依次交给由其下家开始的除其以外的角色，然后其对最后一名角色造成X点伤害（X为最后一名角色手牌中【杀】的数量且至多为3）。",
  ["os__yimou"] = "毅谋",
  [":os__yimou"] = "当至你距离1以内的角色受到伤害后，你可选择一项：1.令其从牌堆获得一张【杀】；2.令其将一张手牌交给另一名角色，摸两张牌。若为其他角色，则你可背水：将所有手牌交给其。",

  ["#os__mutao"] = "募讨：请选择交给 %dest 的【杀】",
  ["#os__yimou"] = "你想对 %dest 发动技能“毅谋”吗？",
  ["os__yimou_slash"] = "令其从牌堆获得一张【杀】",
  ["os__yimou_give"] = "令其将一张手牌交给另一名角色，摸两张牌",
  ["beishui_os__yimou"] = "背水：将所有手牌交给其",
  ["#os__yimou_give"] = "毅谋：将一张手牌交给一名其他角色，然后摸两张牌",
}

local os__guanqiujian = General(extension, "os__guanqiujian", "wei", 4) 

local os__zhengrong = fk.CreateTriggerSkill{
  name = "os__zhengrong",
  anim_type = "control",
  events = {fk.CardUseFinished, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play then
      if event == fk.Damage then
        local filterdEvents = player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function(e) 
          return e.data[1].from == player  --local damage = e.data[1]
        end, Player.HistoryPhase)
        return #filterdEvents == 1 and filterdEvents[1].id == player.room.logic:getCurrentEvent().id
      else
        if player:getMark("_os__zhengrong_card_able") > 0 then
          player.room:setPlayerMark(player, "_os__zhengrong_card_able", 0)
          return true
        end
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(
      table.filter(room:getOtherPlayers(player), function(p)
        return (not p:isNude())
      end),
      function(p)
        return p.id
      end
    )
    if #targets == 0 then return false end
    local target = room:askForChoosePlayers(player, targets, 1, 1, "#os__zhengrong-ask", self.name)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(self.cost_data)
    local card = room:askForCardChosen(player, target, "he", self.name)
    player:addToPile("os__glory", card, false, self.name)
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    if target ~= player then return false end
    local playerId = player.id
    return target == player and player.phase == Player.Play and data.firstTarget and #table.filter(AimGroup:getUndoneOrDoneTargets(data.tos), function(id)
      return id ~= playerId end --?
    ) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "_os__zhengrong_card_count", 1)
    if player:getMark("_os__zhengrong_card_count") % 2 == 0 then
      room:setPlayerMark(player, "_os__zhengrong_card_able", 1)
    end
  end,
}

local os__hongju = fk.CreateTriggerSkill{
  name = "os__hongju",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("os__glory") > 2
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player:getPile("os__glory") > 0 then
      player:drawCards(#player:getPile("os__glory"), self.name)
      local cids = room:askForExchange(player, {player:getPile("os__glory"), player:getCardIds(Player.Hand)}, {"os__glory", "$Hand"}, self.name)
      room:moveCards( 
        {
        ids = cids[2],
          from = player.id,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonExchange,
          proposer = player.id,
          skillName = self.name,
        },
        {
        ids = cids[1],
          from = player.id,
          to = player.id,
          toArea = Card.PlayerSpecial,
          moveReason = fk.ReasonExchange,
          proposer = player.id,
          specialName = "os__glory",
          skillName = self.name,
        }
      )
    end
    room:handleAddLoseSkills(player, "os__qingce", nil)
    local choices = {"os__hongju_saotao", "Cancel"}
    if room:askForChoice(player, choices, self.name) == "os__hongju_saotao" then
      room:changeMaxHp(player, -1)
      room:handleAddLoseSkills(player, "os__saotao", nil)
    end
  end,
}

local os__qingce = fk.CreateActiveSkill{
  name = "os__qingce",
  anim_type = "control",
  target_num = 1,
  card_num = 1,
  expand_pile = "os__glory",
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isAllNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "os__glory"
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    room:moveCardTo(use.cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, "os__glory")
    local card = room:askForCardChosen(player, target, "hej", self.name)
    room:throwCard(card, self.name, target, player)
  end,
}

local os__saotao = fk.CreateTriggerSkill{
  name = "os__saotao",
  frequency = Skill.Compulsory,
  anim_type = "offensive",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and 
      (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, target in ipairs(player.room.alive_players) do
      table.insertIfNeed(data.disresponsiveList, target.id)
    end
  end,
}

os__guanqiujian:addSkill(os__zhengrong)
os__guanqiujian:addSkill(os__hongju)
os__guanqiujian:addRelatedSkill(os__qingce)
os__guanqiujian:addRelatedSkill(os__saotao)

Fk:loadTranslationTable{
  ["os__guanqiujian"] = "毌丘俭",
  ["os__zhengrong"] = "征荣",
  [":os__zhengrong"] = "当你于你的出牌阶段对其他角色使用（此局游戏）累计偶数张牌结算结束后，或当你于出牌阶段第一次造成伤害后，你可选择一名其他角色，将其一张牌扣置于你的武将牌上，称为“荣”。",
  ["os__hongju"] = "鸿举",
  [":os__hongju"] = "觉醒技，准备阶段开始时，若“荣”的数量不小于3，则你摸等于“荣”数量的牌，然后用任意张手牌替换等量的“荣”，然后获得〖清侧〗并选择是否减1点体力上限获得技能〖扫讨〗。",
  ["os__qingce"] = "清侧",
  [":os__qingce"] = "出牌阶段，你可将一张“荣”置入弃牌堆，然后弃置其他角色区域内的一张牌。",
  ["os__saotao"] = "扫讨",
  [":os__saotao"] = "锁定技，你使用的【杀】和普通锦囊牌不能被响应。",

  ["#os__zhengrong-ask"] = "征荣：你可选择一名其他角色，将其一张牌置于你的武将牌上",
  ["os__glory"] = "荣",
  ["os__hongju_saotao"] = "减1点体力上限，获得〖扫讨〗（锁定技，你使用的【杀】和普通锦囊牌不能被响应）",
}


local os__daqiaoxiaoqiao = General(extension, "os__daqiaoxiaoqiao", "wu", 3, 3, General.Female)

local os__xingwu = fk.CreateTriggerSkill{
  name = "os__xingwu",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Discard and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cids = player.room:askForCard(player, 1, 1, true, self.name, true, nil, "#os__xingwu-put")
    if #cids > 0 then
      self.cost_data = cids[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("os__dance", self.cost_data, true, self.name)
    if #player:getPile("os__dance") > 2 then
      player.room:askForUseActiveSkill(player, "#os__xingwu_damage", "#os__xingwu-damage", true)
    end
  end,
}
local os__xingwu_damage = fk.CreateActiveSkill{
  name = "#os__xingwu_damage",
  anim_type = "offensive",
  can_use = function() return false end,
  target_num = 1,
  card_num = 3,
  expand_pile = "os__dance",
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 3 and Self:getPileNameOfId(to_select) == "os__dance"
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    room:throwCard(use.cards, self.name, player) 
    room:throwCard(target:getCardIds(Player.Equip), self.name, target, player)
    room:damage{
      from = player,
      to = target,
      damage = target.gender == General.Male and 2 or 1,
      skillName = self.name,
    }
  end,
}
os__xingwu:addRelatedSkill(os__xingwu_damage)

local os__pingting = fk.CreateTriggerSkill{
  name = "os__pingting",
  events = {fk.RoundStart, fk.EnterDying},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and (event == fk.RoundStart or (event == fk.EnterDying and player.phase ~= Player.NotActive and target ~= player))
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    if not player:isNude() then
      local cid = player.room:askForCard(player, 1, 1, true, self.name, false, nil, "#os__pingting-put")[1]
      player:addToPile("os__dance", cid, true, self.name)
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.EventLoseSkill, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(self.name, true) then return false end--……
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to and move.to == player.id and move.toArea == Card.PlayerSpecial and #player:getPile("os__dance") > 0 then
          return true
        elseif move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromSpecialName == "os__dance" and #player:getPile("os__dance") == 0 then
              return true
            end
          end
        end
      end
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if #player:getPile("os__dance") == 0 and (player:hasSkill("tianxiang", true) or player:hasSkill("liuli", true)) then
      room:handleAddLoseSkills(player, "-tianxiang|-liuli", nil, true, false)
    end
    if #player:getPile("os__dance") > 0 and not (player:hasSkill("tianxiang", true) and player:hasSkill("liuli", true)) then
      room:handleAddLoseSkills(player, "tianxiang|liuli", nil, true, false)
    end
  end,
}

os__daqiaoxiaoqiao:addSkill(os__xingwu)
os__daqiaoxiaoqiao:addSkill(os__pingting)
os__daqiaoxiaoqiao:addRelatedSkill("tianxiang")
os__daqiaoxiaoqiao:addRelatedSkill("liuli")

Fk:loadTranslationTable{
  ["os__daqiaoxiaoqiao"] = "大乔小乔",
  ["os__xingwu"] = "星舞",
  [":os__xingwu"] = "弃牌阶段开始时，你可将一张牌置于你的武将牌上（称为“星舞”），然后你可将三张“星舞”置入弃牌堆，选择一名其他角色，弃置其装备区里的所有牌，然后若其为男/非男性角色，你对其造成2/1点伤害。",
  ["os__pingting"] = "娉婷",
  [":os__pingting"] = "锁定技，①每轮开始时或当其他角色于你回合内进入濒死状态时，你摸一张牌，然后将一张牌置于武将牌上（称为“星舞”）。②若你有“星舞”，你拥有〖天香〗和〖流离〗。",
  
  ["#os__xingwu-put"] = "星舞：你可将一张牌置于你的武将牌上（称为“星舞”）",
  ["os__dance"] = "星舞",
  ["#os__xingwu-damage"] = "你可将三张“星舞”置入弃牌堆，对一名其他角色发动“星舞”",
  ["#os__xingwu_damage"] = "星舞",
  ["#os__pingting-put"] = "娉婷：将一张牌置于你的武将牌上（称为“星舞”）",
}

local os__wangchang = General(extension, "os__wangchang", "wei", 3)

local os__kaiji = fk.CreateTriggerSkill{
  name = "os__kaiji",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local num = player:getMark("@os__kaiji") + 1
    local result = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, function(p)
        return p.id
      end), 1, num, "#os__kaiji-ask:::" .. num, self.name, true)
    if #result > 0 then
      self.cost_data = result
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = self.cost_data
    local invoke = false
    for _, id in ipairs(targets) do
      local cid = room:getPlayerById(id):drawCards(1, self.name)[1]
      if not invoke and Fk:getCardById(cid).type ~= Card.TypeBasic then
        invoke = true
      end 
    end
    if invoke then
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target:getMark("_os__kaiji_enterdying") < 1 --其实是不对的，但@mark……
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(target, "_os__kaiji_enterdying", 1)
    player.room:addPlayerMark(player, "@os__kaiji", 1)
  end,
}

local os__shepan = fk.CreateTriggerSkill{
  name = "os__shepan",
  anim_type = "defensive",
  events = {fk.TargetConfirming},    
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name) < 1 and data.from ~= player.id
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local choices = {"os__shepan_draw", "Cancel"}
    if not from:isAllNude() then table.insert(choices, 2, "os__shepan_put") end
    local choice = room:askForChoice(player, choices, self.name, "#os__shepan::" .. data.from)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local choice = self.cost_data
    local room = player.room
    local from = room:getPlayerById(data.from)
    if choice == "os__shepan_draw" then
      player:drawCards(1, self.name)
    else
      room:moveCardTo({room:askForCardChosen(player, from, "hej", self.name)}, Card.DrawPile, nil, fk.ReasonPut, self.name, nil, false)
    end
    if player:getHandcardNum() == from:getHandcardNum() then
      player:addSkillUseHistory(self.name, -1)
      if room:askForChoice(player, {"os__shepan_nullify", "Cancel"}, self.name, "#os__shepan_nullify:::" .. data.card.name) == "os__shepan_nullify" then
        table.insertIfNeed(data.nullifiedTargets, player.id)
      end
    end
  end,
}

os__wangchang:addSkill(os__kaiji)
os__wangchang:addSkill(os__shepan)

Fk:loadTranslationTable{
  ["os__wangchang"] = "王昶",
  ["os__kaiji"] = "开济",
  [":os__kaiji"] = "准备阶段开始时，你可令至多X名角色各摸一张牌，若有角色以此法获得了非基本牌，你摸一张牌（X为本局游戏进入过濒死状态的角色数+1）。",
  ["os__shepan"] = "慑叛",
  [":os__shepan"] = "每回合限一次，当你成为其他角色使用牌的目标时，你可选择一项：1. 摸一张牌，2. 将其区域内一张牌置于牌堆顶，然后若你与其手牌数相同，则此技能视为未发动过，且你可令此牌对你无效。",

  ["#os__kaiji-ask"] = "开济：你可令至多 %arg 名角色各摸一张牌",
  ["#os__shepan"] = "你可选择一项，对 %dest 发动技能“慑叛”",
  ["@os__kaiji"] = "开济",
  ["os__shepan_draw"] = "摸一张牌",
  ["os__shepan_put"] = "将其区域内一张牌置于牌堆顶",
  ["#os__shepan_nullify"] = "慑叛：你可令【%arg】对你无效",
  ["os__shepan_nullify"] = "令此牌对你无效",
}

local os_sp__caocao = General(extension, "os_sp__caocao", "qun", 4)

local os__lingfa = fk.CreateTriggerSkill{
  name = "os__lingfa",
  anim_type = "control",
  events = {fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    local room = player.room
    local num = room:getTag("RoundCount")
    if num <= 2 then
      local targets = table.map(
        table.filter(room:getOtherPlayers(player), function(p)
          return (not p:isNude())
        end),
        function(p)
          return p.id
        end
      )
      if #targets == 0 then return false end
      return true
    elseif num > 2 then
      if #table.filter(room:getOtherPlayers(player), function(p)
        p:hasSkill(self.name)
      end) == 0 then
        table.forEach(room.alive_players, function(p)
          room:setPlayerMark(p, "@os__lingfa", 0)
        end)
      end
      room:handleAddLoseSkills(player, "os__zhian|-os__lingfa", nil)
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = room:getTag("RoundCount") == 1 and "slash" or "peach"
    table.forEach(table.filter(room:getOtherPlayers(player), function(p)
      return (not p:isNude())
    end), function(p)
      room:setPlayerMark(p, "@os__lingfa", mark)
    end)
  end,
}
local os__lingfa_use = fk.CreateTriggerSkill{
  name = "#os__lingfa_use",
  mute = true,
  anim_type = "control",
  events = {fk.CardUsing, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.CardUsing then
      return target:getMark("@os__lingfa") == "slash" and data.card.trueName == "slash"
    elseif event == fk.CardUseFinished then
      return target:getMark("@os__lingfa") == "peach" and data.card.name == "peach"
    end
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("os__lingfa")
    room:notifySkillInvoked(player, "os__lingfa")
    room:doIndicate(player.id, { target.id })
    local cids
    if event == fk.CardUsing then
      cids = room:askForDiscard(target, 1, 1, true, self.name, true, nil, "#os__lingfa-discard::" .. player.id)
    else
      cids = room:askForCard(target, 1, 1, true, self.name, true, nil, "#os__lingfa-give::" .. player.id)
      if #cids > 0 then
        room:moveCardTo(cids[1], Player.Hand, player, fk.ReasonGive, self.name, nil, false)
      end
    end
    if #cids == 0 then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
os__lingfa:addRelatedSkill(os__lingfa_use)

local os__zhian = fk.CreateTriggerSkill{
  name = "os__zhian",
  anim_type = "control",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and (data.card.type == Card.TypeEquip or data.card.sub_type == Card.SubtypeDelayedTrick) and player:usedSkillTimes(self.name) < 1
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    local room = player.room
    local card_area = room:getCardArea(data.card)
    if card_area == Card.PlayerEquip or card_area == Card.PlayerJudge then choices = {"os__zhian_discard"} end
    if not player:isKongcheng() then table.insert(choices, "os__zhian_get") end
    table.insertTable(choices, {"os__zhian_damage", "Cancel"})
    local choice = room:askForChoice(player, choices, self.name, "#os__zhian-ask::" .. target.id .. ":" .. data.card.name)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, { target.id })
    local choice = self.cost_data
    if choice == "os__zhian_discard" then
      local card = data.card
      local owner = room:getCardOwner(card)
      room:throwCard(card:isVirtual() and card.subcards or {card.id}, self.name, owner, player)
    elseif choice == "os__zhian_get" then
      room:askForDiscard(player, 1, 1, false, self.name, false)
      room:obtainCard(player, data.card, false, fk.ReasonJustMove)
    else
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}

os_sp__caocao:addSkill(os__lingfa)
os_sp__caocao:addRelatedSkill(os__zhian)

Fk:loadTranslationTable{
  ["os_sp__caocao"] = "曹操",
  ["os__lingfa"] = "令法",
  [":os__lingfa"] = "每轮开始时，若当前轮数不大于2，你可令第X项效果对所有有牌的其他角色生效（X为当前轮数）：1. 当使用【杀】时，弃置一张牌，否则你对其造成1点伤害；2. 当使用【桃】结算结束后，交给你一张牌，否则你对其造成1点伤害。若当前轮数大于2，则你失去此技能，获得〖治暗〗。",
  ["os__zhian"] = "治暗",
  [":os__zhian"] = "每回合限一次，当一名角色使用装备牌或延时锦囊牌结算结束后，你可选择一项：1. 从场上弃置此牌；2. 弃置一张手牌，获得此牌；3. 对其造成1点伤害。",

  ["@os__lingfa"] = "令法",
  ["#os__lingfa-discard"] = "令法：弃置一张牌，否则受到 %dest 造成的1点伤害",
  ["#os__lingfa-give"] = "令法：交给 %dest 一张牌，否则受到其造成的1点伤害",
  ["#os__zhian-ask"] = "治暗： %dest 使用了【%arg】，你可选择一项",
  ["os__zhian_discard"] = "从场上弃置此牌",
  ["os__zhian_get"] = "弃置一张手牌，获得此牌",
  ["os__zhian_damage"] = "对其造成1点伤害",
  ["#os__lingfa_use"] = "令法",
}

local os__zhangning = General(extension, "os__zhangning", "qun", 3, 3, General.Female)

local os__xingzhui = fk.CreateActiveSkill{
  name = "os__xingzhui",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and player:getMark("@os__xingzhui") == 0
  end,
  card_num = 0,
  target_num = 0,
  interaction = UI.Spin {
    from = 1, to = 3,
  },
  on_use = function(self, room, effect)
    local num = self.interaction.data
    if not num then return false end --权宜，ai
    local player = room:getPlayerById(effect.from)
    room:loseHp(player, 1, self.name)
    if not player.dead then
      room:setPlayerMark(player, "@os__xingzhui", num .. "-" .. num)
    end
  end,
}
local os__xingzhui_conjure = fk.CreateTriggerSkill{
  name = "#os__xingzhui_conjure",
  mute = true,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__xingzhui") ~= 0 and data.to == Player.NotActive
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__xingzhui"), "-")
    local num = nums[1]
    local num2 = tonumber(nums[2])
    num2 = num2 - 1
    if num2 > 0 then
      room:setPlayerMark(player, "@os__xingzhui", num .. "-" .. tostring(num2))
    else
      room:notifySkillInvoked(player, "os__xingzhui")
      room:broadcastSkillInvoke("os__xingzhui")
      num = tonumber(num)
      local cids = room:getNCards(2 * num)
      room:moveCards({
        ids = cids,
        toArea = Card.Processing,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        proposer = player.id,
      })
      room:delay(2000)

      local dummy = Fk:cloneCard("dilu")
      for _, cid in ipairs(cids) do
        if Fk:getCardById(cid).color == Card.Black then
          dummy:addSubcard(cid)
        end
      end
      local black = #dummy.subcards

      if black > 0 then
        local target = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
          return p.id
        end), 1, 1, black >= num and "#os__xingzhui-ask2:::" .. tostring(num) or "#os__xingzhui-ask", self.name, true)
        if #target > 0 then
          target = room:getPlayerById(target[1])
          room:obtainCard(target, dummy, true, fk.ReasonJustMove) --?

          if black >= num then
            room:damage{
              from = player,
              to = target,
              damage = num,
              damageType = fk.ThunderDamage,
              skillName = self.name,
            }
          end
        end
      end
      room:setPlayerMark(player, "@os__xingzhui", 0)
    end
  end,
}
os__xingzhui:addRelatedSkill(os__xingzhui_conjure)

local os__juchen = fk.CreateTriggerSkill{
  name = "os__juchen",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and not table.every(player.room:getOtherPlayers(player), function(p)
      return p:getHandcardNum() <= player:getHandcardNum()
    end) and not table.every(player.room:getOtherPlayers(player), function(p)
      return p.hp <= player.hp
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local promt = "#os__juchen-ask::" .. player.id
    local dummy = Fk:cloneCard("dilu")
    local ids = {}    
    for _, p in ipairs(room:getAlivePlayers()) do --顺序
      local cids = room:askForDiscard(p, 1, 1, true, self.name, false, nil, promt)
      
      if #cids > 0 then
        local id = cids[1]
        if Fk:getCardById(id).color == Card.Red then
          table.insert(ids, id)
        end
      end
    end
    for _, id in ipairs(ids) do
      if room:getCardArea(id) == Card.DiscardPile then
        dummy:addSubcard(id)
      end
    end
    room:obtainCard(player, dummy, true, fk.ReasonJustMove) --?
  end,
}

os__zhangning:addSkill(os__xingzhui)
os__zhangning:addSkill(os__juchen)

Fk:loadTranslationTable{
  ["os__zhangning"] = "张宁",
  ["os__xingzhui"] = "星坠",
  [":os__xingzhui"] = "出牌阶段限一次，你可以失去1点体力并施法X=1~3回合：亮出牌堆顶2X张牌，若其中有黑色牌，则你可令一名其他角色获得这些黑色牌，若这些牌的数量不小于X ，则你对其造成X点雷电伤害。" .. 
    "<br/><font color='grey'>#\"<b>施法</b>\"<br/>一名角色的回合结束前，施法标记-1，减至0时执行施法效果。施法期间不能重复施法同一技能。",
  ["os__juchen"] = "聚尘",
  [":os__juchen"] = "结束阶段开始时，若你的手牌数和体力值均非全场最大，你可令所有角色弃置一张牌，然后你获得其中处于弃牌堆中的红色牌。",

  ["@os__xingzhui"] = "星坠",
  ["#os__xingzhui-ask"] = "星坠：你可令一名其他角色获得其中的黑色牌",
  ["#os__xingzhui-ask2"] = "星坠：你可令一名其他角色获得其中的黑色牌，然后对其造成 %arg 点雷电伤害",
  ["#os__juchen-ask"] = "聚尘：弃置一张牌，若为红色，%dest 将获得之",
}

local os__mateng = General(extension, "os__mateng", "qun", 4)

local os__xiongzheng = fk.CreateTriggerSkill{
  name = "os__xiongzheng",
  anim_type = "offensive",
  events = {fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    player.room:setPlayerMark(player, "@" .. self.name, 0)
    local targets = table.map(
      table.filter(player.room.alive_players, function(p)
        return (p:getMark("_os__xiongzheng") == 0)
      end),
      function(p)
        return p.id
      end
    )
    if #targets > 0 then
      return true
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local target = player.room:askForChoosePlayers(player, table.map(
      table.filter(player.room.alive_players, function(p)
        return (p:getMark("_os__xiongzheng") == 0)
      end),
      function(p)
        return p.id
      end
    ), 1, 1, "#os__xiongzheng-ask", self.name, true)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(self.cost_data)
    room:setPlayerMark(player, "@" .. self.name, target.general)
    room:addPlayerMark(target, "_os__xiongzheng", 1)
    room:addPlayerMark(target, "_os__xiongzheng-round", 1)
  end,

  refresh_events = {fk.Damage, fk.Death}, --死了就没标记了
  can_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      return target == player and data.to and data.to:getMark("_os__xiongzheng-round") > 0 and player:getMark("_os__xiongzheng_damage-round") == 0
    else
      return target:getMark("_os__xiongzheng-round") > 0 and data.damage and data.damage.from and data.damage.from == player and player:getMark("_os__xiongzheng_damage-round") == 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__xiongzheng_damage-round", 1)
  end,
}
local os__xiongzheng_judge = fk.CreateTriggerSkill{
  name = "#os__xiongzheng_judge",
  mute = true,
  anim_type = "offensive",
  events = {fk.RoundEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:getMark("@os__xiongzheng") ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"os__xiongzheng_slash", "os__xiongzheng_draw", "Cancel"}
    local choice = player.room:askForChoice(player, choices, self.name)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke(self.name)
    local choice = self.cost_data
    if choice == "os__xiongzheng_slash" then
      local availableTargets = table.map(
        table.filter(room:getOtherPlayers(player), function(p)
          return (p:getMark("_os__xiongzheng_damage-round") == 0)
        end),
        function(p)
          return p.id
        end
      )
      local targets = room:askForChoosePlayers(player, availableTargets, 1, #availableTargets, "#os__xiongzheng-slash", self.name, true)
      if #targets > 0 then
        room:notifySkillInvoked(player, "os__xiongzheng")
        local slash = Fk:cloneCard("slash")
        slash.skillName = self.name
        local new_use = {} ---@type CardUseStruct
        new_use.from = player.id
        new_use.card = slash
        room:sortPlayersByAction(targets)
        for _, pid in ipairs(targets) do
          if player.dead or room:getPlayerById(pid).dead then return false end
          room:useVirtualCard("slash", nil, player, {room:getPlayerById(pid)}, self.name, true)
        end
      end
    else
      local availableTargets = table.map(
        table.filter(room.alive_players, function(p)
          return (p:getMark("_os__xiongzheng_damage-round") > 0)
        end),
        function(p)
          return p.id
        end
      )
      local targets = room:askForChoosePlayers(player, availableTargets, 1, #availableTargets, "#os__xiongzheng-draw", self.name, true)
      if #targets > 0 then
        room:notifySkillInvoked(player, "os__xiongzheng", "drawcard")
        room:sortPlayersByAction(targets)
        table.forEach(targets, function(pid)
          room:getPlayerById(pid):drawCards(2, self.name)
        end)
      end
    end
  end,
}
os__xiongzheng:addRelatedSkill(os__xiongzheng_judge)

local os__luannian = fk.CreateTriggerSkill{
  name = "os__luannian$",
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
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return (p.kingdom == "qun")
    end)
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self.name, true) then
        table.forEach(targets, function(p)
          room:handleAddLoseSkills(p, "os__luannian_other&", nil, false, true)
        end)
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      table.forEach(targets, function(p)
        room:handleAddLoseSkills(p, "-os__luannian_other&", nil, false, true)
      end)
    end
  end,
}

local os__luannian_other = fk.CreateActiveSkill{
  name = "os__luannian_other&",
  anim_type = "offensive",
  mute = true,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and player.kingdom == "qun" then
      local room = Fk:currentRoom()
      local lord --手动
      for _, p in ipairs(room.alive_players) do
        if p:hasSkill("os__luannian") then lord = p break end
      end
      if not lord then return false end
      local target
      for _, p in ipairs(room.alive_players) do
        if p:getMark("_os__xiongzheng-round") > 0 then
          target = p
          break
        end
      end
      if target then
        return true
      end
    end
    return false
  end,
  card_num = function(self)
    local lord
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:hasSkill("os__luannian") then lord = p break end
    end
    return lord:getMark("@os__luannian-round") + 1
  end,
  card_filter = function(self, to_select, selected)
    local lord
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:hasSkill("os__luannian") then lord = p break end
    end
    return #selected < lord:getMark("@os__luannian-round") + 1
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:notifySkillInvoked(player, "os__luannian")
    room:broadcastSkillInvoke("os__luannian")
    local target
    for _, p in ipairs(room.alive_players) do
      if p:getMark("_os__xiongzheng-round") > 0 then
        target = p
        break
      end
    end
    if not target then return false end
    room:doIndicate(effect.from, { target.id })
    local lord
    for _, p in ipairs(room.alive_players) do
      if p:hasSkill("os__luannian") then lord = p break end
    end
    room:addPlayerMark(lord, "@os__luannian-round", 1)
    room:throwCard(effect.cards, self.name, player)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = self.name,
    }
  end,
}

os__mateng:addSkill("mashu")
os__mateng:addSkill(os__xiongzheng)
os__mateng:addSkill(os__luannian)
Fk:addSkill(os__luannian_other)

Fk:loadTranslationTable{
  ["os__mateng"] = "马腾",
  ["os__xiongzheng"] = "雄争",
  [":os__xiongzheng"] = "每轮开始时，你可选择一名未被此技能选择过的角色。若如此做，则本轮结束时，你可选择一项：1. 视为依次对任意名本轮未对其造成过伤害的其他角色使用一张【杀】；2. 令任意名本轮对其造成过伤害的角色摸两张牌。",
  ["os__luannian"] = "乱年",
  [":os__luannian"] = "主公技，其他群势力角色出牌阶段限一次，其可弃置X张牌对“雄争”角色造成1点伤害（X为此技能本轮发动的次数+1）。",

  ["@os__xiongzheng"] = "雄争",
  ["#os__xiongzheng-ask"] = "你可对一名未被“雄争”选择过的角色发动“雄争”",
  ["#os__xiongzheng_judge"] = "雄争",
  ["os__xiongzheng_slash"] = "视为对任意名本轮未对“雄争”角色造成伤害的其他角色使用【杀】",
  ["os__xiongzheng_draw"] = "令任意名本轮对对“雄争”角色造成过伤害的角色摸两张牌",
  ["#os__xiongzheng-slash"] = "选择任意名角色，视为分别对这些角色使用【杀】",
  ["#os__xiongzheng-draw"] = "选择任意名角色，各摸两张牌",
  ["@os__luannian-round"] = "乱年",

  ["os__luannian_other&"] = "乱年",
  [":os__luannian_other&"] = "出牌阶段限一次，你可弃置X张牌对“雄争”角色造成1点伤害（X为“乱年”本轮发动的次数+1）。",
}

local os__hejin = General(extension, "os__hejin", "qun", 4)

local os__mouzhu = fk.CreateActiveSkill{
  name = "os__mouzhu",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local hp = player.hp
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return (p.hp <= hp and p ~= target)
    end),
    function(p)
      return p.id
    end)
    room:doIndicate(player.id, targets)
    local x = 0
    for _, p in ipairs(targets) do
      p = room:getPlayerById(p)
      local cids = room:askForCard(p, 1, 1, true, self.name, true, nil, "#os__mouzhu-card::" .. player.id)
      if #cids > 0 then
        room:moveCardTo(cids[1], Player.Hand, player, fk.ReasonGive, self.name, nil, false)
        x = x + 1
      end
    end

    if x == 0 then
      table.insert(targets, 1, player.id)
      table.forEach(targets, function(p)
        room:loseHp(room:getPlayerById(p), 1, self.name)
      end)
    else
      local card = Fk:cloneCard(room:askForChoice(target, {"slash", "duel"}, self.name, "#os__mouzhu-ask::" .. player.id .. ":" .. tostring(x)))
      card.skillName = self.name
      local new_use = {}
      new_use.from = player.id
      new_use.tos = { {target.id} }
      new_use.card = card
      new_use.additionalDamage = math.min(x - 1, 3)
      new_use.extraUse = true
      room:useCard(new_use)
    end
  end,
}

local os__yanhuo = fk.CreateTriggerSkill{
  name = "os__yanhuo",
  anim_type = "control",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    local num = #player:getCardIds(Player.Equip) + #player:getCardIds(Player.Hand)
    local choices = {"os__yanhuo_x:::" .. num, "os__yanhuo_1:::" .. num, "Cancel"}
    if num == 0 then return false 
    elseif num == 1 then choices = {"os__yanhuo_1:::" .. 1, "Cancel"} end
    local choice = player.room:askForChoice(player, choices, self.name)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return (not p:isNude())
    end),
    function(p)
      return p.id
    end)
    if #targets == 0 then return false end
    local choice = self.cost_data
    local num = #player:getCardIds(Player.Equip) + #player:getCardIds(Player.Hand)
    if choice == "os__yanhuo_x:::" .. num then
      local p = room:askForChoosePlayers(player, targets, 1, num, "#os__yanhuo-target_x:::" .. tostring(num), self.name, true)
      if #p > 0 then
        table.forEach(p, function(pid)
          room:askForDiscard(room:getPlayerById(pid), 1, 1, true, self.name, false)
        end)
      end
    else
      local p = room:askForChoosePlayers(player, targets, 1, 1, "#os__yanhuo-target_1:::" .. tostring(num), self.name, true)
      if #p > 0 then
        local target = room:getPlayerById(p[1])
        if #target:getCardIds(Player.Equip) + #target:getCardIds(Player.Hand) <= num then
          target:throwAllCards("he")
        else
          room:askForDiscard(target, num, num, true, self.name, false)
        end
      end
    end
  end,
}

os__hejin:addSkill(os__mouzhu)
os__hejin:addSkill(os__yanhuo)


Fk:loadTranslationTable{
  ["os__hejin"] = "何进",
  ["os__mouzhu"] = "谋诛",
  [":os__mouzhu"] = "出牌阶段限一次，你可选择一名其他角色A，然后除其外体力值不大于你的其他角色B依次选择是否交给你一张牌。若你未因此获得牌，则你与所有B失去1点体力；否则A选择你视为对其使用一张伤害值基数为X的【杀】或【决斗】（X为你以此法获得的牌数且至多为4）。",
  ["os__yanhuo"] = "延祸",
  [":os__yanhuo"] = "当你死亡时，你可选择一项：1. 令至多X名角色各弃置一张牌；2. 令一名角色弃置X张牌，不足则全弃（X为你的牌数）。",

  ["#os__mouzhu-card"] = "谋诛：你可将一张牌交给 %dest",
  ["#os__mouzhu-ask"] = "谋诛：选择 %dest 视为对你使用伤害基数为 %arg 的【杀】或【决斗】",
  ["os__yanhuo_x"] = "令至多%arg名角色各弃置一张牌",
  ["os__yanhuo_1"] = "令一名角色弃置%arg张牌",
  ["#os__yanhuo-target_x"] = "延祸：选择至多 %arg 名角色，各弃置一张牌",
  ["#os__yanhuo-target_1"] = "延祸：选择一名角色，令其弃置 %arg 张牌",
}


local os__jiakui = General(extension, "os__jiakui", "wei", 3)

local os__zhongzuo = fk.CreateTriggerSkill{
  name = "os__zhongzuo",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and player:hasSkill(self.name) and player:getMark("_os__zhongzuo_available-turn") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askForChoosePlayers(player, table.map(room.alive_players, function(p)
        return p.id
      end), 1, 1, "#os__zhongzuo-ask", self.name, true)

    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local p = room:getPlayerById(self.cost_data)
    p:drawCards(2, self.name)
    if p:isWounded() then player:drawCards(1, self.name) end
  end,

  refresh_events = {fk.Damage, fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os__zhongzuo_available-turn") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "_os__zhongzuo_available-turn", 1)
  end,
}

local os__wanlan = fk.CreateTriggerSkill{
  name = "os__wanlan",
  anim_type = "support",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:throwAllCards("h")
    room:recover({
      who = target,
      num = 1 - target.hp,
      recoverBy = player,
      skillName = self.name,
    })
    room:setPlayerMark(player, "_os__wanlan", 1)
  end,
}
local os__wanlan_damage = fk.CreateTriggerSkill{
  name = "#os__wanlan_damage",
  mute = true,
  events = {fk.AfterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:getMark("_os__wanlan") > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "_os__wanlan", 0)
    room:damage{
      from = player,
      to = room.current,
      damage = 1,
      skillName = self.name,
    }
  end,
}
os__wanlan:addRelatedSkill(os__wanlan_damage)

os__jiakui:addSkill(os__zhongzuo)
os__jiakui:addSkill(os__wanlan)

Fk:loadTranslationTable{
  ["os__jiakui"] = "贾逵",
  ["os__zhongzuo"] = "忠佐",
  [":os__zhongzuo"] = "一名角色的结束阶段结束时，若你于本回合内造成或受到过伤害，你可令一名角色摸两张牌，若其已受伤，你摸一张牌。",
  ["os__wanlan"] = "挽澜",
  [":os__wanlan"] = "限定技，当一名角色进入濒死状态时，你可发动此技能，若你有手牌则你弃置所有手牌，令其回复体力至1点，此次濒死结算结束后，你对当前回合角色造成1点伤害。",

  ["#os__zhongzuo-ask"] = "忠佐：你可令一名角色摸两张牌，若其已受伤，你摸一张牌",
}

local os__zangba = General(extension, "os__zangba", "wei", 4)

local os__hanyu = fk.CreateTriggerSkill{
  name = "os__hanyu",
  events = {fk.GameStart},
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dummy = Fk:cloneCard("slash")
    dummy:addSubcards(room:getCardsFromPileByRule(".|.|.|.|.|basic"))
    dummy:addSubcards(room:getCardsFromPileByRule(".|.|.|.|.|trick"))
    dummy:addSubcards(room:getCardsFromPileByRule(".|.|.|.|.|equip"))
    if #dummy.subcards > 0 then
      room:obtainCard(player, dummy, false, fk.ReasonPrey)
    end
  end,
}

local os__hengjiang = fk.CreateTriggerSkill{
  name = "os__hengjiang",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and player.phase == Player.Play and data.firstTarget and #AimGroup:getAllTargets(data.tos) == 1 and (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = data.card
    AimGroup:cancelTarget(data, data.to)
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:inMyAttackRange(p) and not player:isProhibited(p, card)
    end), function(p)
      return p.id 
    end)
    if #targets == 0 then return false end
    data.card.extra_data = data.card.extra_data or {}
    data.card.extra_data.os__hengjiangUser = player.id
    room:doIndicate(player.id, targets)
    table.forEach(targets, function(pid)
      AimGroup:addTargets(room, data, pid)
    end)
  end,
}
local os__hengjiang_judge = fk.CreateTriggerSkill{
  name = "#os__hengjiang_judge",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.card.extra_data or {}).os__hengjiangUser == player.id
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getMark("_os__hengjiang_count"), self.name)
    player.room:setPlayerMark(player, "_os__hengjiang_count", 0)
  end,

  refresh_events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_refresh = function(self, event, target, player, data)
    return ((event == fk.CardUseFinished and data.toCard and (data.toCard.extra_data or {}).os__hengjiangUser == player.id) or (event == fk.CardRespondFinished and (data.responseToEvent.card.extra_data or {}).os__hengjiangUser == player.id)) and
      data.responseToEvent and data.responseToEvent.from == player.id and target:getMark("_os__hengjiang_counted-phase") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__hengjiang_count")
    player.room:addPlayerMark(target, "_os__hengjiang_counted-phase")
  end,
}
os__hengjiang:addRelatedSkill(os__hengjiang_judge)

os__zangba:addSkill(os__hanyu)
os__zangba:addSkill(os__hengjiang)

Fk:loadTranslationTable{
  ["os__zangba"] = "臧霸",
  ["os__hanyu"] = "捍御",
  [":os__hanyu"] = "锁定技，游戏开始时，你从牌堆获得不同类别的牌各一张。",
  ["os__hengjiang"] = "横江",
  [":os__hengjiang"] = "当你使用基本牌或普通锦囊牌指定唯一目标后，若此时为你的出牌阶段且你于此阶段内未发动过此技能，你可将此牌的目标改为攻击范围内的所有角色，此牌结算结束后你摸X张牌（X为响应此牌的角色数）。",
}

local duosidawang = General(extension, "duosidawang", "qun", 4, 5)

local os__equan = fk.CreateTriggerSkill{
  name = "os__equan",
  anim_type = "offensive",
  events = {fk.Damaged, fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if event == fk.Damaged then
      return player:hasSkill(self.name) and player.phase ~= Player.NotActive
    else
      return target == player and player:hasSkill(self.name) and target.phase == Player.Start
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      room:addPlayerMark(target, "@os__poison", data.damage)
    else
      for _, p in ipairs(room.alive_players) do
        if p:getMark("@os__poison") > 0 and not p.dead then
          room:setPlayerMark(p, "_os__equan", 1)
          room:loseHp(p, p:getMark("@os__poison"), self.name)
          room:setPlayerMark(p, "@os__poison", 0)
          room:setPlayerMark(p, "_os__equan", 0)
        end
      end
    end
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target:getMark("_os__equan") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, "@@os__equan-turn", 1)
    room:setPlayerMark(target, "_os__equan", 0)
  end,
}
local os__equan_invalidity = fk.CreateInvaliditySkill {
  name = "#os__equan_invalidity",
  invalidity_func = function(self, from, skill)
    return from:getMark("@@os__equan-turn") > 0 and not skill.attached_equip
  end
}
os__equan:addRelatedSkill(os__equan_invalidity)

local os__manji = fk.CreateTriggerSkill{
  name = "os__manji",
  anim_type = "drawcard",
  events = {fk.HpLost},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and not target.dead
  end,
  on_use = function(self, event, target, player, data)
    if target.hp >= player.hp then
      local room = player.room
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    end
    if target.hp <= player.hp then
      player:drawCards(1, self.name)
    end
  end,
}

duosidawang:addSkill(os__equan)
duosidawang:addSkill(os__manji)

Fk:loadTranslationTable{
  ["duosidawang"] = "朵思大王",
  ["os__equan"] = "恶泉",
  [":os__equan"] = "锁定技，当一名角色于你回合内受到伤害后，其获得等同于伤害值的“毒”。准备阶段开始时，所有有“毒”的角色失去X点体力并弃所有“毒”（X为其拥有的“毒”数)，以此法进入濒死状态的角色本回合技能失效。",
  ["os__manji"] = "蛮汲",
  [":os__manji"] = "锁定技，当其他角色失去体力后，若你的体力值不大于其，你回复1点体力；若你的体力值不小于其，你摸一张牌。",

  ["@os__poison"] = "毒",
  ["@@os__equan-turn"] = "恶泉",
}

local os__bianfuren = General(extension, "os__bianfuren", "wei", 3, 3, General.Female)

local os__wanwei = fk.CreateTriggerSkill{
  name = "os__wanwei",
  anim_type = "defensive",
  events = {fk.DamageInflicted, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.DamageInflicted then
      return player:hasSkill(self.name) and table.every(player.room:getOtherPlayers(target), function(p)
        return p.hp >= target.hp
      end) and player:usedSkillTimes(self.name) < 1 
    else
      return target.phase == Player.Finish and player:getMark("_os__wanwei_get-turn") > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.DamageInflicted then
      local choices = {}
      if target ~= player then
        table.insert(choices, "os__wanwei_defend")
      end
      if target == player or table.every(player.room:getOtherPlayers(player), function(p)
        return p.maxHp <= player.maxHp
      end) then
        table.insert(choices, "os__wanwei_get")
      end
      if #choices == 2 then
        choices = {"os__wanwei_both"}
      end
      table.insert(choices, "Cancel")
      local choice = player.room:askForChoice(player, choices, self.name, "#os__wanwei-ask")
      if choice ~= "Cancel" then
        self.cost_data = choice
        return true
      end
    else
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      local choice = self.cost_data
      local invoke = false
      room:doIndicate(player.id, {target.id})
      if choice ~= "os__wanwei_get" then
        room:loseHp(player, 1, self.name)
        invoke = true
      end
      if choice ~= "os__wanwei_defend" then
        room:setPlayerMark(player, "_os__wanwei_get-turn", 1)
      end
      return invoke
    else
      local cids = player:drawCards(1, self.name, "bottom")
      player:showCards(cids)
      local card = Fk:getCardById(cids[1])
      if card.skill:canUse(player) and not player:prohibitUse(card) then
        local cardName = card.name
        local use = room:askForUseCard(player, cardName, ".|.|.|.|.|.|" .. cids[1], "#os__wanwei-use:::" .. cardName, false) --toLogString太丑了
        if use then
          room:useCard(use)
        end
      end
    end
  end,
}

local os__yuejian = fk.CreateActiveSkill{
  name = "os__yuejian",
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and player:getHandcardNum() > player:getMaxCards()
  end,
  card_num = function() return Self:getHandcardNum() - Self:getMaxCards() end,
  card_filter = function(self, to_select, selected)
    return #selected < Self:getHandcardNum() - Self:getMaxCards()
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local num = #effect.cards
    room:moveCardTo(effect.cards, Card.DrawPile, nil, fk.ReasonPut, self.name, nil, false)
    room:askForGuanxing(player, room:getNCards(num), nil, nil, "os__yuejianPut", false) --不会更新牌堆牌数！
    room:doBroadcastNotify("UpdateDrawPile", #room.draw_pile) --手动……
    if num > 0 then
      room:addPlayerMark(player, MarkEnum.AddMaxCards)
    end
    if num > 1 then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    end
    if num > 2 then
      room:changeMaxHp(player, 1)
    end
  end,
}

os__bianfuren:addSkill(os__wanwei)
os__bianfuren:addSkill(os__yuejian)

Fk:loadTranslationTable{
  ["os__bianfuren"] = "卞夫人",
  ["os__wanwei"] = "挽危",
  [":os__wanwei"] = "每回合限一次，当体力值最低的角色受到伤害时，若其不为你，你可以防止此伤害，然后失去1点体力；若其为你或你的体力上限全场最高，则你可在本回合结束阶段开始时获得牌堆底牌并展示之（若此牌能使用，则你使用之）。",
  ["os__yuejian"] = "约俭",
  [":os__yuejian"] = "出牌阶段限一次，你可以将X张牌置于牌堆顶或牌堆底（X为你手牌数减去手牌上限的差且至少为1），若因此失去的牌数不小于：1，你的手牌上限+1；2，你回复1点体力；3，你增加1点体力上限。",

  ["#os__wanwei-ask"] = "你可选择是否发动“挽危”",
  ["os__wanwei_defend"] = "防止此伤害，你失去1点体力",
  ["os__wanwei_get"] = "本回合结束阶段开始时，获得牌堆底牌并展示之，若能使用则使用之",
  ["os__wanwei_both"] = "防止此伤害，并于本回合结束阶段开始时，获得牌堆底牌",
  ["#os__wanwei-use"] = "挽危：请使用获得的【%arg】",
  ["os__yuejianPut"] = "约俭：置于牌堆顶或牌堆底",
}

local os__jiling = General(extension, "os__jiling", "qun", 4)

local os__shuangren = fk.CreateTriggerSkill{
  name = "os__shuangren",
  anim_type = "offensive",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.phase == Player.Play and not player:isKongcheng() and table.find(player.room:getOtherPlayers(player), function(p)
      return not p:isKongcheng()
    end) and (event == fk.EventPhaseStart or (player:getMark("_os__shuangren_invalid-turn") == 0 and player:usedSkillTimes(self.name) == 0))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      local cids = room:askForDiscard(player, 1, 1, true, self.name, true, nil, "#os__shuangren_end")
      if #cids == 0 then return false end
    end
    local availableTargets = table.map(
      table.filter(room:getOtherPlayers(player), function(p)
        return not p:isKongcheng()
      end),
      function(p)
        return p.id
      end
    )
    if #availableTargets == 0 then return false end
    local target = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__shuangren-ask", self.name, true)
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
      local slash = Fk:cloneCard("slash")
      if player:prohibitUse(slash) then return false end
      local availableTargets = table.map(
        table.filter(room:getOtherPlayers(player), function(p)
          return p:distanceTo(target) <= 1 and not player:isProhibited(p, slash)
        end),
        function(p)
          return p.id
        end
      )
      if #availableTargets == 0 then return false end
      local victims = room:askForChoosePlayers(player, availableTargets, 1, 2, "#os__shuangren_slash-ask:" .. target.id, self.name, true)
      if #victims > 0 then
        for _, pid in ipairs(victims) do
          if player.dead or room:getPlayerById(pid).dead then return false end
          room:useVirtualCard("slash", nil, player, {room:getPlayerById(pid)}, self.name, true)
        end
      end
    else
      if room:askForChoice(target, {"os__shuangren_counter", "Cancel"}, self.name, "#os__shuangren_counter-ask:" .. player.id) ~= "Cancel" then
        room:useVirtualCard("slash", nil, target, {player}, self.name, true)
      end
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return player == target and player.phase == player.Play and data.card and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__shuangren_invalid-turn")
  end,
}

os__jiling:addSkill(os__shuangren)


Fk:loadTranslationTable{
  ["os__jiling"] = "纪灵",
  ["os__shuangren"] = "双刃",
  [":os__shuangren"] = "出牌阶段开始时，你可与一名角色拼点。若你赢，可视为对至其距离不大于1的至多两名角色依次使用一张【杀】；若你没赢，其可视为对你使用一张【杀】。出牌阶段结束时，若你本回合未发动过〖双刃〗且未使用【杀】造成过伤害，则你可弃置一张牌发动〖双刃〗。",
  
  ["#os__shuangren-ask"] = "双刃：你可与一名角色拼点",
  ["#os__shuangren_slash-ask"] = "双刃：你可视为对至 %src 距离不大于1的至多两名角色依次使用一张【杀】",
  ["os__shuangren_counter"] = "双刃：你可视为对其使用一张【杀】",
  ["#os__shuangren_counter-ask"] = "双刃：你可视为对 %src 使用一张【杀】",
  ["#os__shuangren_end"] = "你可弃置一张牌发动〖双刃〗", 
}

local os__wuban = General(extension, "os__wuban", "shu", 4)

local os__jintao = fk.CreateTriggerSkill{
  name = "os__jintao",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and (player:usedCardTimes("slash", Player.HistoryPhase) == 1 or player:usedCardTimes("slash", Player.HistoryPhase) == 2) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local num = player:usedCardTimes("slash", Player.HistoryPhase)
    if num == 1 then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    elseif num == 2 then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, target in ipairs(player.room.alive_players) do
        table.insertIfNeed(data.disresponsiveList, target.id)
      end
    end
  end,
}
local os__jintao_buff = fk.CreateTargetModSkill{
  name = "#os__jintao_buff",
  anim_type = "offensive",
  residue_func = function(self, player, skill, scope, card)
    return (player:hasSkill("os__jintao") and skill.trueName == "slash_skill") and 1 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return (player:hasSkill("os__jintao") and skill.trueName == "slash_skill") and 999 or 0
  end,
}
os__jintao:addRelatedSkill(os__jintao_buff)

os__wuban:addSkill(os__jintao)

Fk:loadTranslationTable{
  ["os__wuban"] = "吴班",
  ["os__jintao"] = "进讨",
  [":os__jintao"] = "锁定技，你使用【杀】无距离限制且次数+1。你出牌阶段使用的第一张【杀】伤害值基数+1，第二张【杀】不可响应。",
}

local huchuquan = General(extension, "huchuquan", "qun", 4)
local os__fupan = fk.CreateTriggerSkill{
  name = "os__fupan",
  events = {fk.Damage, fk.Damaged},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and not player.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(data.damage, self.name)
    local os__fupan_invalid = player:getMark("_os__fupan_invalid") ~= 0 and player:getMark("_os__fupan_invalid") or {}
    local availableTargets = table.map(
      table.filter(room:getOtherPlayers(player), function(p)
        return not table.contains(os__fupan_invalid, p.id)
      end),
      function(p)
        return p.id
      end
    )
    if #availableTargets == 0 or player:isNude() then return false end
    local plist, cid = room:askForChooseCardAndPlayers(player, availableTargets, 1, 1, nil, "#os__fupan-give", self.name, false)
    local pid = plist[1]
    room:moveCardTo(cid, Player.Hand, room:getPlayerById(pid), fk.ReasonGive, self.name, nil, false)
    local os__fupan_once = player:getMark("_os__fupan_once") ~= 0 and player:getMark("_os__fupan_once") or {}
    if not table.contains(os__fupan_once, pid) then
      player:drawCards(2, self.name)
    else
      if room:askForChoice(player, {"os__fupan_dmg", "Cancel"}, self.name) ~= "Cancel" then
        table.insertIfNeed(os__fupan_invalid, pid)
        room:setPlayerMark(player, "_os__fupan_invalid", os__fupan_invalid)
        room:damage{
          from = player,
          to = room:getPlayerById(pid),
          damage = 1,
          skillName = self.name,
        }
      end
    end
    table.insertIfNeed(os__fupan_once, pid)
    room:setPlayerMark(player, "_os__fupan_once", os__fupan_once)
  end,
}

huchuquan:addSkill(os__fupan)

Fk:loadTranslationTable{
  ["huchuquan"] = "呼厨泉",
  ["os__fupan"] = "复叛",
  [":os__fupan"] = "当你造成或受到伤害后，你可摸X张牌（X为伤害值），然后交给一名其他角色一张牌。若你未以此法交给过其牌，你摸两张牌；否则，你可对其造成1点伤害，然后你不能再以此法交给其牌。",
  
  ["#os__fupan-give"] = "复叛：交给一名其他角色一张牌",
  ["os__fupan_dmg"] = "对其造成1点伤害，然后不能再以此法交给其牌",
}

local os__qiaozhou = General(extension, "os__qiaozhou", "shu", 3)

local os__zhiming = fk.CreateTriggerSkill{
  name = "os__zhiming",
  anim_type = "drawcard",
  mute = true,
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      ((event == fk.EventPhaseStart and player.phase == Player.Start) or (event == fk.EventPhaseEnd and player.phase == Player.Discard))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke(self.name)
    room:notifySkillInvoked(player, self.name)
    player:drawCards(1, self.name)
    local cids = room:askForCard(player, 1, 1, true, self.name, true, nil, "#os__zhiming-ask")
    if #cids > 0 then
      self.cost_data = cids
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(self.cost_data, Card.DrawPile, nil, fk.ReasonPut, self.name, nil, false)
  end,
}

local os__xingbu = fk.CreateTriggerSkill{
  name = "os__xingbu",
  events = {fk.EventPhaseStart},
  anim_type = "support",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cids = room:getNCards(3)
    room:moveCards({
      ids = cids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id,
    })
    room:delay(2000)
    local num = 0
    for _, cid in ipairs(cids) do
      if Fk:getCardById(cid).color == Card.Red then
        num = num + 1
      end
    end
    local result
    if num > 1 then
      result = "_os__xingbu_" .. tostring(num)
      room:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name)
    else
      result = "_os__xingbu_1"
      room:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")
    end
    local target = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
      return p.id
    end), 1, 1, "#os__xingbu-target:::" .. result, self.name, true)
    if #target > 0 then
      room:setPlayerMark(room:getPlayerById(target[1]), "@os__xingbu", result)
    end
  end,
}
local os__xingbu_do = fk.CreateTriggerSkill{
  name = "#os__xingbu_do",
  events = {fk.CardUseFinished, fk.DrawNCards},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or player:getMark("@os__xingbu-turn") == 0 then return false end
    if event == fk.CardUseFinished then 
      return player:getMark("@os__xingbu-turn") == "_os__xingbu_2" and player:getMark("_os__xingbu_2-phase") == 0
    else
      return player:getMark("@os__xingbu-turn") == "_os__xingbu_3"
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.CardUseFinished then 
      local room = player.room
      local cids = table.clone(player:getCardIds(Player.Hand))
      table.insertTable(cids, player:getCardIds(Player.Equip))
      if table.find(cids, function(id)
        return not player:prohibitDiscard(Fk:getCardById(id))
      end) and #room:askForDiscard(player, 1, 1, true, self.name, false, nil, "#os__xingbu-discard") > 0 then
        player:drawCards(2, self.name)
      end
      room:addPlayerMark(player, "_os__xingbu_2-phase")
    else
      data.n = data.n + 2
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@os__xingbu") ~= 0 and data.from == Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@os__xingbu-turn", player:getMark("@os__xingbu"))
    room:setPlayerMark(player, "@os__xingbu", 0)
    if player:getMark("@os__xingbu-turn") ~= 0 and player:getMark("@os__xingbu-turn") == "_os__xingbu_3" then player:skip(Player.Discard) end
  end,
}
local os__xingbu_buff = fk.CreateTargetModSkill{
  name = "#os__xingbu_buff",
  residue_func = function(self, player, skill, scope)
    if player:getMark("@os__xingbu-turn") ~= 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      if player:getMark("@os__xingbu-turn") == "_os__xingbu_3" then
        return 1
      elseif player:getMark("@os__xingbu-turn") == "_os__xingbu_1" then
        return -1
      end
    end
  end,
}
os__xingbu:addRelatedSkill(os__xingbu_do)
os__xingbu:addRelatedSkill(os__xingbu_buff)

os__qiaozhou:addSkill(os__zhiming)
os__qiaozhou:addSkill(os__xingbu)

Fk:loadTranslationTable{
  ["os__qiaozhou"] = "谯周",
  ["os__zhiming"] = "知命",
  [":os__zhiming"] = "准备阶段开始时或弃牌阶段结束时，你摸一张牌，然后你可将一张牌置于牌堆顶。",
  ["os__xingbu"] = "星卜",
  [":os__xingbu"] = "结束阶段开始时，你可亮出牌堆顶的三张牌，然后你可选择一名其他角色，令其根据其中红色牌的数量获得以下效果之一：<br/>为3：<font color='#CC3131'>«五星连珠»</font>，其下个回合摸牌阶段额定摸牌数+2、使用【杀】的次数上限+1、跳过弃牌阶段；<br/>为2：«白虹贯日»，其下个回合出牌阶段使用第一张牌结算结束后，弃置一张牌，摸两张牌；<br/>不大于1：<font color='grey'>«荧惑守心»</font>，其下个回合使用【杀】的次数上限-1。",

  ["#os__zhiming-ask"] = "知命：你可将一张牌置于牌堆顶",
  ["#os__xingbu-target"] = "星卜：你可选择一名其他角色，令其获得“%arg”",
  ["_os__xingbu_3"] = "<font color='#CC3131'>五星连珠</font>",
  ["_os__xingbu_2"] = "白虹贯日",
  ["_os__xingbu_1"] = "<font color='grey'>荧惑守心</font>",
  ["@os__xingbu"] = "星卜",
  ["@os__xingbu-turn"] = "星卜",
  ["#os__xingbu_do"] = "星卜",
  ["#os__xingbu-discard"] = "星卜：弃置一张牌，然后摸两张牌",
}

local bingyuan = General(extension, "bingyuan", "qun", 3)

local os__bingde = fk.CreateActiveSkill{
  name = "os__bingde",
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and (player:getMark("_os__bingde_done-turn") == 0 or #player:getMark("_os__bingde_done-turn") < 4)
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected < 1
  end,
  target_num = 0,
  interaction = function(self)
    local all = Self:getMark("_os__bingde_done-phase") ~= 0 and Self:getMark("_os__bingde_done-phase") or {}
    return UI.ComboBox { choices = table.filter({"log_spade", "log_club", "log_heart", "log_diamond"}, function(s)
      return not table.contains(all, s)
    end) }
  end,
  on_use = function(self, room, effect)
    local suit_log = self.interaction.data
    if not suit_log then return false end
    local card_suits_reverse_table = {
      log_spade = 1,
      log_club = 2,
      log_heart = 3,
      log_diamond = 4,
    }
    local suit = card_suits_reverse_table[suit_log]
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player)
    player:drawCards(player:getMark("_os__bingde_" .. suit .. "-phase"), self.name)
    if Fk:getCardById(effect.cards[1]).suit == suit then
      player:addSkillUseHistory(self.name, -1)
      local os__bingde_done = player:getMark("_os__bingde_done-phase") ~= 0 and player:getMark("_os__bingde_done-phase") or {}
      table.insert(os__bingde_done, suit_log)
      room:setPlayerMark(player, "_os__bingde_done-phase", os__bingde_done)
      room:setPlayerMark(player, "_os__bingde_" .. suit .. "-phase", "x")
      room:setPlayerMark(player, "@os__bingde-phase", string.format("%s-%s-%s-%s",
        player:getMark("_os__bingde_1-phase"),
        player:getMark("_os__bingde_2-phase"),
        player:getMark("_os__bingde_3-phase"),
        player:getMark("_os__bingde_4-phase")))
    end
  end,
}
local os__bingde_record = fk.CreateTriggerSkill{
  name = "#os__bingde_record",
  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.card.suit ~= Card.NoSuit and player:getMark("_os__bingde_" .. data.card.suit .. "-phase") ~= "x"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "_os__bingde_" .. data.card.suit .. "-phase")
    room:setPlayerMark(player, "@os__bingde-phase", string.format("%s-%s-%s-%s",
      player:getMark("_os__bingde_1-phase"),
      player:getMark("_os__bingde_2-phase"),
      player:getMark("_os__bingde_3-phase"),
      player:getMark("_os__bingde_4-phase")))
  end,
}
os__bingde:addRelatedSkill(os__bingde_record)

local os__qingtao = fk.CreateTriggerSkill{ --……
  name = "os__qingtao",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and ((event == fk.EventPhaseEnd and player.phase == Player.Draw) or (event == fk.EventPhaseStart and player.phase == Player.Finish and player:getMark("_os__qingtao_invoked-turn") == 0))
  end,
  on_cost = function(self, event, target, player, data)
    local id = player.room:askForCard(player, 1, 1, true, self.name, true, nil, "#os__qingtao-ask")
    if #id > 0 then
      self.cost_data = id
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recastCard(self.cost_data[1], player, self.name)
    local card = Fk:getCardById(self.cost_data[1])
    if card.name == "analeptic" or card.type ~= Card.TypeBasic then player:drawCards(1, self.name) end
    if event == fk.EventPhaseEnd then room:setPlayerMark(player, "_os__qingtao_invoked-turn", 1) end
  end,
}

bingyuan:addSkill(os__bingde)
bingyuan:addSkill(os__qingtao)

Fk:loadTranslationTable{
  ["bingyuan"] = "邴原",
  ["os__bingde"] = "秉德",
  [":os__bingde"] = "出牌阶段限一次，你可弃置一张牌并选择一种花色，然后摸X张牌（X为你此阶段使用此花色的牌数），若你弃置的牌的花色和选择的花色相同，此技能视为未发动过且此阶段不能再选择相同的花色。",
  ["os__qingtao"] = "清滔",
  [":os__qingtao"] = "摸牌阶段结束时，你可重铸一张牌，然后若此牌为【酒】或非基本牌，你摸一张牌。若你未发动此技能，你可于此回合的结束阶段开始时发动此技能。",

  ["#os__qingtao-ask"] = "清滔：你可重铸一张牌，然后若此牌为【酒】或非基本牌，你摸一张牌",
  ["@os__bingde-phase"] = "秉德",
}


--[[local zhangjih = General(extension, "zhangjih", "wei", 3)

local os__dingzhen = fk.CreateTriggerSkill{
  name = "os__dingzhen",
  anim_type = "defensive",
  events = {fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    local num = player.hp
    local targets = table.map(
      table.filter(player.room.alive_players, function(p)
        return (p:distanceTo(player) <= num)
      end),
      function(p)
        return p.id
      end
    )
    if #targets > 0 then
      return true
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local targets = player.room:askForChoosePlayers(
      player,
      table.map(
        table.filter(player.room.alive_players, function(p)
          return (p:distanceTo(player) <= num)
        end),
        function(p)
          return p.id
        end
      ),
      1,
      99,
      "#os__dingzhen-ask:::" .. tostring(player.hp),
      self.name,
      true
    )

    if #targets > 0 then
      self.cost_data = targets
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    table.forEach(self.cost_data, function(pid)
      local p = room:getPlayerById(pid)
      local discard = room:askForDiscard(p, 1, 1, true, self.name, true, "slash|.", "#os__dingzhen-discard::" .. pid)
      if #discard == 0 then
        room:addPlayerMark(p, "@@os__dingzhen-round", 1)
        room:addPlayerMark(p, "_os__dingzhen_to-round", player.id)
      end
    end)
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@os__dingzhen-round") > 0 and player.phase ~= Player.NotActive and player:getMark("_os__dingzhen_use-turn") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__dingzhen_use-turn", 1)
  end,
}
local os__dingzhen_prohibit = fk.CreateProhibitSkill{
  name = "#os__dingzhen_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:getMark("@@os__dingzhen-round") > 0 and from:getMark("_os__dingzhen_to-round") == to.id and from:getMark("_os__dingzhen_use-turn") == 0
  end,
}
os__dingzhen:addRelatedSkill(os__dingzhen_prohibit)

local os__youye = fk.CreateTriggerSkill{
  name = "os__youye",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and player:hasSkill(self.name) and target ~= player and target:getMark("_os__youye_damage_" .. player.id .. "-turn") == 0 and #player:getPile("os__poise") < 5
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("os__poise", player.room:getNCards(1)[1], true, self.name)
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target and target ~= nil and target == player and player.phase ~= Player.NotActive and not data.to.dead
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__youye_damage_" .. data.to.id .. "-turn", 1)
  end,
}

local os__youye_give = fk.CreateTriggerSkill{
  name = "#os__youye_give",
  mute = true,
  events = {fk.Damage, fk.Damaged},
  anim_type = "support",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and #player:getPile("os__poise") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("os__dingzhen")
    room:notifySkillInvoked(player, "os__dingzhen")
    local ids = room:askForCard(player, 1, #player:getPile("os__poise"), false, self.name, false, ".|.|.|os__poise", "#os__youye-give::" .. room.current.id, "os__poise")
    local move = {
      ids = ids,
      from = player.id,
      to = room.current.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonGive,
      proposer = player.id,
      skillName = self.name,
    }
    room:moveCards(move) --遗计
    while #player:getPile("os__poise") > 0 do
      ids = room:askForCard(player, 1, #player:getPile("os__poise"), false, self.name, false, ".|.|.|os__poise", "#os__youye-give2", "os__poise")
      local pid = room:askForChoosePlayers(player, table.map(room.alive_players, function(p)
        return p.id
      end), 1, 1, "#os__youye-target", self.name, false)[1]
      move = {
        ids = ids,
        from = player.id,
        to = pid,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        proposer = player.id,
        skillName = self.name,
      }
      room:moveCards(move)
    end
  end,
}
os__youye:addRelatedSkill(os__youye_give)

zhangjih:addSkill(os__dingzhen)
zhangjih:addSkill(os__youye)

Fk:loadTranslationTable{
  ["zhangjih"] = "张既",
  ["os__dingzhen"] = "定镇",
  [":os__dingzhen"] = "每轮开始时，你可选择至你距离为X以内的任意名角色（X为你当前体力值），令这些角色弃置一张【杀】，否则本轮中其回合内使用的第一张牌不能指定你为目标。",
  ["os__youye"] = "攸业",
  [":os__youye"] = "锁定技，其他角色的结束阶段开始时，若其本回合没有对你造成过伤害，则你将牌堆顶的一张牌置于你的武将牌上，称为“蓄”（至多5张）。当你造成或受到伤害后，你将所有“蓄”分配给任意角色，且当前回合角色至少须获得一张。",
  
  ["#os__dingzhen-ask"] = "你可对任意名至你距离 %arg 以内的角色发动“定镇”",
  ["#os__dingzhen-discard"] = "定镇：弃置一张【杀】，否则本轮中回合内使用的第一张牌不能指定 %dest 为目标",
  ["@@os__dingzhen-round"] = "定镇",
  ["os__poise"] = "蓄",
  ["#os__youye-give"] = "定镇：将至少一张“蓄”分配给 %dest",
  ["#os__youye-give2"] = "定镇：选择任意张“蓄”，点击“确定”后分配给任意角色。重复此流程，直到所有“蓄”分配完毕",
  ["#os__youye-target"] = "定镇：将选择的“蓄”分配给任意角色。重复此流程，直到所有“蓄”分配完毕",
}]]

local wufuluo = General(extension, "wufuluo", "qun", 6)

local os__jiekuang = fk.CreateTriggerSkill{
  name = "os__jiekuang",
  anim_type = "defensive",
  events = {fk.TargetConfirmed, fk.CardUseFinished},    
  can_trigger = function(self, event, target, player, data)
    if event == fk.TargetConfirmed then
      return player:hasSkill(self.name) and target.hp < player.hp and player:usedSkillTimes(self.name) < 1 and data.from ~= player.id and #AimGroup:getAllTargets(data.tos) == 1 
      and (data.card.type == Card.TypeBasic or (data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick)) and table.every(player.room.alive_players, function(p)
        return p.hp > 0 --旧周泰？
      end)
    else
      return data.card and (data.card.extra_data or {}).os__jiekuangUser == player.id and not player:prohibitUse(data.card) and not player:isProhibited(target, data.card)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetConfirmed then
      local choices = {"os__jiekuang_hp", "os__jiekuang_maxhp", "Cancel"}
      local choice = player.room:askForChoice(player, choices, self.name, "#os__jiekuang:" .. data.to .. "::" .. data.card.name)
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
    local room = player.room
    if event == fk.TargetConfirmed then
      local choice = self.cost_data
      if choice == "os__jiekuang_hp" then room:loseHp(player, 1, self.name)
      else room:changeMaxHp(player, -1) end
      if player.dead then return false end
      data.card.extra_data = data.card.extra_data or {}
      data.card.extra_data.os__jiekuangUser = player.id
      AimGroup:cancelTarget(data, data.to)
      local user = room:getPlayerById(data.from)
      if not (user:prohibitUse(card) or user:isProhibited(player, data.card)) then
        AimGroup:addTargets(room, data, player.id)
      end
    else
      room:useVirtualCard(data.card.name, nil, player, target, self.name)
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return data.card and (data.card.extra_data or {}).os__jiekuangUser == player.id
  end,
  on_refresh = function(self, event, target, player, data)
    data.card.extra_data.os__jiekuangUser = nil
  end,
}

local os__neirao = fk.CreateTriggerSkill{
  name = "os__neirao",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player.hp + player.maxHp < 10
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-os__jiekuang", nil)
    local num = #player:getCardIds(Player.Equip) + #player:getCardIds(Player.Hand)
    player:throwAllCards("he")
    local dummy = Fk:cloneCard("slash")
    dummy:addSubcards(room:getCardsFromPileByRule("slash", num, "allPiles"))
    if #dummy.subcards > 0 then
      room:obtainCard(player, dummy, false, fk.ReasonPrey)
    end
    room:handleAddLoseSkills(player, "os__luanlue", nil)
  end,
}

local os__luanlue = fk.CreateViewAsSkill{
  name = "os__luanlue",
  anim_type = "control",
  pattern = "snatch",
  card_num = function() return Self:getMark("@os__luanlue") end,
  card_filter = function(self, to_select, selected)
    return Fk:getCardById(to_select).trueName == "slash" and #selected < Self:getMark("@os__luanlue")
  end,
  view_as = function(self, cards)
    local c = Fk:cloneCard("snatch")
    c.skillName = self.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    player.room:addPlayerMark(player, "@os__luanlue")
  end,
}
local os__luanlue_prohibit = fk.CreateProhibitSkill{
  name = "#os__luanlue_prohibit",
  is_prohibited = function(self, from, to, card)
    return to:getMark("_os__luanlue-phase") > 0 and card and card.name == "snatch" and table.contains(card.skillNames, "os__luanlue")
  end,
}
local os__luanlue_trig = fk.CreateTriggerSkill{
  name = "#os__luanlue_trig",
  mute = true,
  frequency = Skill.Compulsory,
  refresh_events = {fk.CardUsing, fk.TargetConfirmed},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.name == "snatch" and
      ((event == fk.CardUsing and player:hasSkill(self.name)) or (event == fk.TargetConfirmed and player.room.current.phase == Player.Play))
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.CardUsing then
      data.disresponsiveList = data.disresponsiveList or {}
      table.forEach(player.room.alive_players, function(p)
        table.insertIfNeed(data.disresponsiveList, p.id)
      end)
    else
      player.room:addPlayerMark(player, "_os__luanlue-phase")
    end
  end,
}
os__luanlue:addRelatedSkill(os__luanlue_prohibit)
os__luanlue:addRelatedSkill(os__luanlue_trig)

wufuluo:addSkill(os__jiekuang)
wufuluo:addSkill(os__neirao)
wufuluo:addRelatedSkill(os__luanlue)

Fk:loadTranslationTable{
  ["wufuluo"] = "于夫罗",
  ["os__jiekuang"] = "竭匡",
  [":os__jiekuang"] = "每回合限一次，当一名体力值小于你的角色成为其他角色使用基本牌或普通锦囊牌的唯一目标后，若没有角色处于濒死状态，你可失去1点体力或减1点体力上限，然后你代替其成为此牌目标。当此牌结算结束后，若此牌未造成伤害且此牌的使用者可成为此牌的合法目标，则视为你对此牌的使用者使用一张同名牌。",
  ["os__neirao"] = "内扰",
  [":os__neirao"] = "觉醒技，准备阶段开始时，若你的体力值与体力上限之和不大于9，你失去〖竭匡〗，弃置全部牌并从牌堆或弃牌堆中获得等量的【杀】，然后获得技能〖乱掠〗。",
  ["os__luanlue"] = "乱掠",
  [":os__luanlue"] = "出牌阶段，你可将X张【杀】当做【顺手牵羊】对一名本阶段未成为过【顺手牵羊】目标的角色使用（X为你以此法使用过【顺手牵羊】的次数）。你使用的【顺手牵羊】不能被响应。",

  ["#os__jiekuang"] = "竭匡：你可失去1点体力或减1点体力上限，代替 %src 成为【%arg】的目标",
  ["os__jiekuang_hp"] = "失去1点体力",
  ["os__jiekuang_maxhp"] = "减1点体力上限",
  ["@os__luanlue"] = "乱掠",
  ["#os__luanlue_trig"] = "乱掠",
}

local os__puyangxing = General(extension, "os__puyangxing", "wu", 4)

local os__zhengjian = fk.CreateTriggerSkill{
  name = "os__zhengjian",
  anim_type = "control",
  events = {fk.GameStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self.name)
    else
      if target.phase ~= Player.Play or not player:hasSkill(self.name) or target == player then return false end
      return ((player:getMark("@os__zhengjian_use") ~= 0 and target:getMark("_os__zhengjian_use-phase") == 0) or (player:getMark("@os__zhengjian_obtain") ~= 0 and target:getMark("_os__zhengjian_obtain-phase") == 0))
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      self.cost_data = player.room:askForChoice(player, {"os__zhengjian_use", "os__zhengjian_obtain"}, self.name, "#os__zhengjian-ask")
      return true
    else
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:setPlayerMark(player, "@@" .. self.cost_data, 1)
      room:setPlayerMark(player, "@" .. self.cost_data, "0") --很怪
    else
      local current = player:getMark("@os__zhengjian_use") ~= 0 and "@os__zhengjian_use" or "@os__zhengjian_obtain"
      local invoke = false
      if player:usedSkillTimes("os__zhongchi", Player.HistoryGame) > 0 then
        if room:askForChoice(player, {"os__zhengjian_dmg", "Cancel"}, self.name, "#os__zhengjian_damage-ask:" .. target.id) ~= "Cancel" then
          room:damage{
            from = player,
            to = target,
            damage = 1,
            skillName = self.name,
          }
          invoke = true
        end
      elseif not target:isNude() then
        local cid = room:askForCard(target, 1, 1, true, self.name, false, nil, "#os__zhengjian-card:" .. player.id)[1]
        invoke = true
        if player:getMark("@" .. current) > 0 then room:setPlayerMark(player, "@" .. current, 0) end
        room:setPlayerMark(player, current, tonumber(player:getMark(current)) + 1) --！
        room:moveCardTo(cid, Player.Hand, player, fk.ReasonGive, self.name, nil, false)
      end
      if invoke then
        local choice = current == "@os__zhengjian_use" and "os__zhengjian_obtain" or "os__zhengjian_use"
        local result = room:askForChoice(player, {choice, "Cancel"}, self.name, "#os__zhengjian_change-ask")
        if result ~= "Cancel" then
          room:setPlayerMark(player, "@" .. result, player:getMark(current))
          room:setPlayerMark(player, current, 0)
        end
      end
    end
  end,

  refresh_events = {fk.PreCardUse, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      return target == player and player.phase == Player.Play and data.card.type ~= Card.TypeBasic
    elseif player.phase == Player.Play then
      for _, move in ipairs(data) do
        local target = move.to and player.room:getPlayerById(move.to) or nil
        if target and move.to == player.id and move.toArea == Card.PlayerHand then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      player.room:addPlayerMark(player, "_os__zhengjian_use-phase", 1)
    else
      player.room:addPlayerMark(player, "_os__zhengjian_obtain-phase", 1)
    end
  end,
}

local os__zhongchi = fk.CreateTriggerSkill{
  name = "os__zhongchi",
  events = {fk.AfterCardsMove, fk.DamageInflicted},
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      if not player:hasSkill(self.name) or player:usedSkillTimes(self.name, Player.HistoryGame) > 0 then return false end
      local num = (#player.room.players + 1) // 2
      if tonumber(player:getMark("@os__zhengjian_use")) < num and tonumber(player:getMark("@os__zhengjian_obtain")) < num then return false end
      for _, move in ipairs(data) do
        local target = move.to and player.room:getPlayerById(move.to) or nil
        if target and move.to == player.id and move.toArea == Card.PlayerHand then
          return true
        end
      end
    else
      return target == player and player:usedSkillTimes(self.name, Player.HistoryGame) > 0 and data.card and data.card.trueName == "slash"
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      return false
    else
      data.damage = data.damage + 1
    end
  end,
}

os__puyangxing:addSkill(os__zhengjian)
os__puyangxing:addSkill(os__zhongchi)

Fk:loadTranslationTable{
  ["os__puyangxing"] = "濮阳兴",
  ["os__zhengjian"] = "征建",
  [":os__zhengjian"] = "游戏开始时，你选择一项：1.使用过非基本牌；2.获得过牌。其他角色的出牌阶段结束时，若其此阶段未完成“征建”要求的选项，其交给你一张牌，然后你可变更〖征建〗的选项。",
  ["os__zhongchi"] = "众斥",
  [":os__zhongchi"] = "锁定技，当累计有X名角色因〖征建〗交给你牌后（X为游戏人数的一半，向上取整），你本局游戏受到【杀】的伤害+1，并将〖征建〗中的“其交给你一张牌”修改为“你可对其造成1点伤害”。",
  
  ["#os__zhengjian-ask"] = "征建：选择对其他角色的“征建”要求",
  ["os__zhengjian_use"] = "使用过非基本牌",
  ["os__zhengjian_obtain"] = "获得过牌",
  ["@os__zhengjian_use"] = "征建使用非基",
  ["@os__zhengjian_obtain"] = "征建获得牌",
  ["@@os__zhengjian_use"] = "征建使用非基",
  ["@@os__zhengjian_obtain"] = "征建获得牌",
  ["#os__zhengjian-card"] = "征建：交给 %src 一张牌",
  ["#os__zhengjian_change-ask"] = "征建：你可变更“征建”要求",
  ["#os__zhengjian_damage-ask"] = "征建：你可对 %src 造成1点伤害",
  ["os__zhengjian_dmg"] = "造成1点伤害",
}

local os__zhaoxiang = General(extension, "os__zhaoxiang", "shu", 4, 4, General.Female)

local os__fanghun_gain = fk.CreateTriggerSkill{
  name = "#os__fanghun_gain",
  events ={fk.TargetSpecified, fk.TargetConfirmed},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and (event == fk.TargetConfirmed or data.firstTarget)
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "os__fanghun")
    if not table.contains(data.card.skillNames, "os__fanghun") or event == fk.TargetConfirmed then --避免重叠
      room:broadcastSkillInvoke("os__fanghun")
    end
    room:addPlayerMark(player, "@meiying")
  end,
}
local os__fanghun = fk.CreateViewAsSkill{
  name = "os__fanghun",
  pattern = "slash,jink",
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
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local _c = Fk:getCardById(cards[1])
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    end
    --c.skillName = self.name
    c.skillNames = c.skillNames or {}
    table.insert(c.skillNames, "os__fanghun")
    table.insert(c.skillNames, "longdan")
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  enabled_at_response = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@meiying")
    player:drawCards(1, self.name)
  end,
}
os__fanghun:addRelatedSkill(os__fanghun_gain)

local os__fuhan = fk.CreateTriggerSkill{
  name = "os__fuhan",
  events = {fk.EventPhaseStart},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and player:getMark("@meiying") > 0 and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local maxHp = math.min(math.max(player:getMark("@meiying"), 2), 8)
    return player.room:askForSkillInvoke(player, self.name, nil, "#os__fuhan-invoke:::"..maxHp)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = player:getMark("@meiying")
    room:setPlayerMark(player, "@meiying", 0)
    local existingGenerals = {}
    table.forEach(room.players, function(p)
      table.insertTable(existingGenerals, {p.general, p.deputyGeneral})
    end)
    local generals = table.map(Fk:getGeneralsRandomly(5, Fk:getAllGenerals(), existingGenerals, (function(p) return (p.kingdom ~= "shu") end)), function(g) return g.name end)
    local general = Fk.generals[room:askForGeneral(player, generals, 1)]
    room:setPlayerMark(player, "@os__fuhan", general.name)
    local skills = general:getSkillNameList(player.role == "lord" and #room.players > 4)
    room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, false)
    local maxHp = math.min(math.max(num, 2), 8)
    room:changeMaxHp(player, maxHp - player.maxHp)
    room:recover({ who = player, num = 1, skillName = self.name })
    if player:hasSkill("os__queshi") then
      local moonSpear = nil
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id)
        if card.name == "moon_spear" and table.contains({Card.PlayerEquip, Card.PlayerJudge, Card.DiscardPile, Card.DrawPile}, room:getCardArea(card)) then
          moonSpear = card
          break
        end
      end
      if moonSpear then room:obtainCard(player, moonSpear, true, fk.ReasonPrey) end
    end
  end,
}

local os__queshi = fk.CreateTriggerSkill{
  name = "os__queshi",
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_cost = function() return true
  end,
  on_use = function(self, event, target, player, data)
    local moonSpear = nil
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.name == "moon_spear" then
        moonSpear = card
        break
      end
    end
    if moonSpear and not player:getEquipment(Card.SubtypeWeapon) then player.room:moveCardTo(moonSpear, Card.PlayerEquip, player, fk.ReasonJustMove, self.name) end
  end,
}

os__zhaoxiang:addSkill(os__fanghun)
os__zhaoxiang:addSkill(os__fuhan)
os__zhaoxiang:addSkill(os__queshi)
os__zhaoxiang:addRelatedSkill("longdan") --……

Fk:loadTranslationTable{
  ["os__zhaoxiang"] = "赵襄",
  ["os__fanghun"] = "芳魂",
  [":os__fanghun"] = "①当你使用【杀】指定第一个目标后或成为【杀】的目标后，你获得1枚“梅影”。②你可弃1枚“梅影”以发动〖龙胆〗并摸一张牌。",
  ["os__fuhan"] = "扶汉",
  [":os__fuhan"] = "限定技，准备阶段开始时，你可弃所有“梅影”，然后从五张未登场的蜀势力武将牌中选择一张，获得其所有技能，并将体力上限调整为以此移去“梅影”的数量（最少为2，最多为8），回复1点体力。",
  ["os__queshi"] = "鹊拾",
  [":os__queshi"] = "游戏开始时，你将【银月枪】置入你的装备区。当你发动“扶汉”后，你从场上、牌堆或弃牌堆中获得【银月枪】。",

  ["@meiying"] = "梅影",
  ["#os__fuhan-invoke"] = "扶汉：你可弃所有“梅影”，从5张蜀势力武将牌中选择一张获得其所有技能，将体力上限调整为%arg，回复1点体力",
  ["@os__fuhan"] = "扶汉",
  ["#os__fanghun_gain"] = "芳魂",
}

local xiahoushang = General(extension, "xiahoushang", "wei", 4)

local os__tanfeng = fk.CreateTriggerSkill{
  name = "os__tanfeng",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local availableTargets = table.map(
      table.filter(room:getOtherPlayers(player), function(p)
        return not p:isAllNude()
      end),
      function(p)
        return p.id
      end
    )
    if #availableTargets == 0 then return false end
    local target = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__tanfeng-ask", self.name, true)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(self.cost_data)
    if target:isAllNude() then return false end
    local cid = room:askForCardChosen(player, target, "hej", self.name)
    room:throwCard({cid}, self.name, target, player)
    local choices = {"os__tanfeng_damaged", "Cancel"}
    local slash = Fk:cloneCard("slash")
    slash.skillName = self.name
    if not target:isNude() and not target:prohibitUse(slash) and not target:isProhibited(slash, player) then table.insert(choices, 2, "os__tanfeng_slash") end
    local choice = room:askForChoice(target, choices, self.name, "#os__tanfeng-react:" .. player.id)
    if choice == "os__tanfeng_damaged" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = self.name,
      }
      if not target.dead then
        local phase = {"phase_judge", "phase_draw", "phase_play", "phase_discard", "phase_finish"}
        player:skip(table.indexOf(phase, room:askForChoice(target, phase, self.name, "#os__tanfeng-skip:" .. player.id)) + 2)
      end
    elseif choice == "os__tanfeng_slash" then
      local cids = room:askForCard(target, 1, 1, true, self.name, false, nil, "#os__tanfeng-slash:" .. player.id)
      if #cids > 0 then
        room:useVirtualCard("slash", cids, target, player, self.name)
      end
      --[[local success, dat = room:askForUseViewAsSkill(target, "os__tanfeng_vs", "#os__tanfeng-slash:" .. player.id, false, {must_targets = {player.id} }) --must_targets 没用
      if success then
        local card = Fk.skills["os__tanfeng_vs"]:viewAs(dat.cards)
        room:useCard{
          from = target.id,
          tos = table.map(dat.targets, function(e) return {e} end),
          card = card,
        }
      end]]
    end
  end,
}

xiahoushang:addSkill(os__tanfeng)

Fk:loadTranslationTable{
  ["xiahoushang"] = "夏侯尚",
  ["os__tanfeng"] = "探锋",
  [":os__tanfeng"] = "准备阶段开始时，你可弃置一名其他角色区域内的一张牌，然后其可选择一项：1. 受到你造成的1点火焰伤害，其令你跳过一个阶段；2. 将一张牌当【杀】对你使用。",

  ["#os__tanfeng-ask"] = "探锋：你可选择一名其他角色，弃置其区域内的一张牌",
  ["#os__tanfeng-react"] = "探锋：你可对 %src 选择一项",
  ["os__tanfeng_damaged"] = "受到其造成的1点火焰伤害，令其跳过一个阶段",
  ["os__tanfeng_slash"] = "将一张牌当【杀】对其使用",
  ["#os__tanfeng-skip"] = "探锋：令 %src 跳过此回合的一个阶段",
  ["#os__tanfeng-slash"] = "探锋：将一张牌当【杀】对 %src 使用",
}

local yanxiang = General(extension, "yanxiang", "qun", 3)

local os__kujian = fk.CreateActiveSkill{
  name = "os__kujian",
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  max_card_num = 3,
  min_card_num = 1,
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand and #selected < 3
  end,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local tag = room:getTag("os__kujian") or {}
    table.forEach(effect.cards, function(cid)
      table.insertIfNeed(tag, cid)
    end)
    room:setTag("os__kujian", tag)
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, self.name, nil, false)
  end,
}
local os__kujian_judge = fk.CreateTriggerSkill{
  name = "#os__kujian_judge",
  events = {fk.CardUsing, fk.CardResponding, fk.AfterCardsMove},
  anim_type = "drawcard",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    local tag = player.room:getTag("os__kujian")
    if not tag then return false end
    if event ~= fk.AfterCardsMove then
      if player == target then return false end
      return table.find(data.card:isVirtual() and data.card.subcards or {data.card.id}, function(id)
        return table.contains(tag, id)
      end)
    else
      local targets = {}
      for _, move in ipairs(data) do
        if move.from ~= player.id and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
          local num = #table.filter(move.moveInfo, function(info)
            return table.contains(tag, info.cardId) and info.fromArea == Card.PlayerHand
          end)
          if num > 0 then
            --targets[move.from] = (targets[move.from] or 0) + num
            table.insertIfNeed(targets, move.from)
            player.room:addPlayerMark(player.room:getPlayerById(move.from), "_os__kujian", num)
          end
        end
      end
      if #targets > 0 then
        return true
      end
    end
    return false
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "os__kujian", event == fk.AfterCardsMove and "negative" or "drawcard")
    room:broadcastSkillInvoke("os__kujian")
    if event ~= fk.AfterCardsMove then
      room:doIndicate(player.id, {target.id})
      player:drawCards(1, self.name)
      target:drawCards(1, self.name)
    else
      local targets = table.filter(room:getAlivePlayers(true), function(p) return p:getMark("_os__kujian") > 0 end)
      for _, to in ipairs(targets) do
        for i = 1, to:getMark("_os__kujian"), 1 do
          room:doIndicate(player.id, {to.id})
          if not player:isNude() and player:isAlive() then room:askForDiscard(player, 1, 1, true, self.name, false, nil, "#os__kujian-discard") end
          if not to:isNude() and to:isAlive() then room:askForDiscard(to, 1, 1, true, self.name, false, nil, "#os__kujian-discard") end
        end
        room:setPlayerMark(to, "_os__kujian", 0)
      end
    end
  end,

  can_refresh = {fk.AfterCardsMove}, --移出手牌区……
  can_refresh = function(self, event, target, player, data)
    local tag = player.room:getTag("os__kujian")
    if not tag then return false end
    local cids = {}
    for _, move in ipairs(data) do
      table.insertTable(cids, table.filter(move.moveInfo, function(info)
        return table.contains(tag, info.cardId) and info.toArea == Card.DiscardPile
      end))
    end
    if #cids > 0 then
      self.cost_data = cids --待改
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local tag = player.room:getTag("os__kujian")
    table.forEach(self.cost_data, function(cid)
      table.removeOne(tag, cid)
    end)
    player.room:setTag("os__kujian", tag)
  end,
}
os__kujian:addRelatedSkill(os__kujian_judge)

local os__ruilian = fk.CreateTriggerSkill{
  name = "os__ruilian",
  events = {fk.RoundStart, fk.EventPhaseChanging},
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and (event == fk.RoundStart or (tonumber(target:getMark("@os__ruilian-turn")) > 1 and data.to == Player.NotActive and table.contains(target:getMark("_os__ruilianGiver"), player.id)))
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.RoundStart then
      local target = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, function(p)
        return p.id
      end), 1, 1, "#os__ruilian-ask", self.name, true)
      if #target > 0 then
        self.cost_data = target[1]
        return true
      end
    else
      local cids = target:getMark("_os__ruilianCids-turn")
      local cardType = {}
      table.forEach(cids, function(cid)
        table.insertIfNeed(cardType, Fk:getCardById(cid):getTypeString())
      end)
      table.insert(cardType, "Cancel")
      local choice = player.room:askForChoice(player, cardType, self.name, "#os__ruilian-type:" .. target.id)
      if choice ~= "Cancel" then
        self.cost_data = choice
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundStart then
      local target = room:getPlayerById(self.cost_data)
      room:setPlayerMark(target, "@@os__ruilian", 1)
      local ruilianGiver = type(target:getMark("_os__ruilianGiver")) == "table" and target:getMark("_os__ruilianGiver") or {}
      table.insertIfNeed(ruilianGiver, player.id)
      room:setPlayerMark(target, "_os__ruilianGiver", ruilianGiver)
    else
      local id = room:getCardsFromPileByRule(".|.|.|.|.|" .. self.cost_data, 1, "discardPile")
      if #id > 0 then
        room:obtainCard(player, id[1], false, fk.ReasonPrey)
      end
      id = room:getCardsFromPileByRule(".|.|.|.|.|" .. self.cost_data, 1, "discardPile")
      if #id > 0 then
        room:obtainCard(target, id[1], false, fk.ReasonPrey)
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if player ~= player.room.current then return false end
    if event == fk.AfterCardsMove then
      if player:getMark("@os__ruilian-turn") == 0 then return false end
      local cids = {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              table.insert(cids, info.cardId)
            end
          end
        end
      end
      if #cids > 0 then
        self.cost_data = cids --待改
        return true
      end
      return false
    else
      return target == player and player:getMark("@@os__ruilian") ~= 0 and data.from == Player.NotActive
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local cids = type(player:getMark("_os__ruilianCids-turn")) == "table" and player:getMark("_os__ruilianCids-turn") or {}
      table.insertTable(cids, self.cost_data)
      room:setPlayerMark(player, "_os__ruilianCids-turn", cids)
      room:setPlayerMark(player, "@os__ruilian-turn", #player:getMark("_os__ruilianCids-turn"))
    else
      room:setPlayerMark(player, "@os__ruilian-turn", "0")
      room:setPlayerMark(player, "@@os__ruilian", 0)
    end
  end,
}

yanxiang:addSkill(os__kujian)
yanxiang:addSkill(os__ruilian)

Fk:loadTranslationTable{
  ["yanxiang"] = "阎象",
  ["os__kujian"] = "苦谏",
  [":os__kujian"] = "出牌阶段限一次，你可将至多三张手牌标记为“谏”并交给一名其他角色。当其他角色使用或打出“谏”牌时，你与其各摸一张牌。当其他角色非因使用或打出从手牌区失去“谏”牌后，你与其各弃置一张牌。",
  ["os__ruilian"] = "睿敛",
  [":os__ruilian"] = "每轮开始时，你可选择一名角色，其下个回合结束前，若其此回合弃置的牌数不小于2，你可选择其此回合弃置过的牌中的一种类别，你与其各从弃牌堆中获得一张此类别的牌。",

  ["#os__kujian-discard"] = "苦谏：请弃置一张牌",
  ["#os__kujian_judge"] = "苦谏",
  ["#os__ruilian-ask"] = "你可对一名角色发动“睿敛”",
  ["@@os__ruilian"] = "睿敛",
  ["@os__ruilian-turn"] = "睿敛",
  ["#os__ruilian-type"] = "睿敛：你可选择 %src 此回合弃置过的牌中的一种类别，你与其各从弃牌堆中获得一张此类别的牌",
  ["@os__kujian"] = "苦谏",
}

Fk:loadTranslationTable{
  ["os__caohong"] = "曹洪",
  ["os__yuanhu"] = "援护",
  [":os__yuanhu"] = "出牌阶段限一次，你可将一张装备牌置入一名角色的装备区，若此牌是：武器牌，你弃置其距离为1的一名角色区域里的一张牌；防具牌，其摸一张牌；坐骑牌或宝物牌，其回复1点体力。若其体力值或手牌数不大于你，你摸一张牌，且可于本回合结束阶段开始时再发动此技能。",
  ["os__juezhu"] = "决助",
  [":os__juezhu"] = "限定技，出牌阶段，你可废除一个坐骑栏，令一名其他角色获得〖飞影〗并废除其判定区。其死亡后，你恢复以此法废除的坐骑栏。",
}

return extension
