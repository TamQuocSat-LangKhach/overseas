local extension = Package("overseas")
--local extension_cards = Package:new("overseas_cards", Package.CardPack)

Fk:loadTranslationTable{
  ["overseas"] = "国际服",
  ["os"] = "国际",
  ["os_ex"] = "国际界",
  ["os_sp"] = "国际SP",

  --["overseas_cards"] = "国际服（特殊锦囊）",
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
      local target = room:askForChoosePlayers(
        player,
        availableTargets,
        1,
        1,
        "#os__qingkou-ask",
        self.name
      )

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
  [":os__qingkou"] = "准备阶段，你可视为使用一张【决斗】。此【决斗】结算后，造成伤害的角色摸一张牌，若为你，你跳过此回合的判定阶段和弃牌阶段。",
  ["#os__qingkou-ask"] = "轻寇：你可选择一名其他角色，视为对其使用一张【决斗】",
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
    local target = room:askForChoosePlayers(
      player,
      availableTargets,
      1,
      1,
      "#os__fenwu-ask",
      self.name
    )

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
    if basic_types > 1 then new_use.additionalDamage = 1 end
    room:useCard(new_use)
  end,
}
zhangnan:addSkill(os__fenwu)

Fk:loadTranslationTable{
  ["zhangnan"] = "张南",
  ["os__fenwu"] = "奋武",
  [":os__fenwu"] = "结束阶段，你可失去1点体力，视为你对一名其他角色使用一张【杀】。若本回合你使用过超过一种基本牌，此【杀】伤害值基数+1。",
  ["#os__fenwu-ask"] = "奋武：你可选择一名其他角色，失去1点体力，视为对其使用一张【杀】",
}

local yuejiu = General(extension, "yuejiu", "qun", 4)
local os__cuijin = fk.CreateTriggerSkill{ --写得有点奇怪
  name = "os__cuijin",
  anim_type = "offensive",
  events = {fk.CardUsing, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return (player:inMyAttackRange(target) or target == player) and
        player:hasSkill(self.name) and data.card.trueName == "slash" and not player:isNude()
    else
      return player:getMark("_os__cuijin_invoked") ~= 0 and data.card and player:getMark("_os__cuijin_invoked") == tostring(data.card.id)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUsing then
      local card = player.room:askForCard(player, 1, 1, true, self.name, true, "", "#os__cuijin-ask::" .. target.id)
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
      room:setPlayerMark(player, "_os__cuijin_invoked", tostring(data.card.id))
      data.additionalDamage = (data.additionalDamage or 0) + 1
    else
      room:setPlayerMark(player, "_os__cuijin_invoked", 0)
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
    return player:getMark("_os__cuijin_invoked") ~= 0 and data.card and player:getMark("_os__cuijin_invoked") == tostring(data.card.id)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "_os__cuijin_invoked", 0)
  end,
}
yuejiu:addSkill(os__cuijin)

Fk:loadTranslationTable{
  ["yuejiu"] = "乐就",
	["os__cuijin"] = "催进",
	[":os__cuijin"] = "当你或攻击范围内的角色使用【杀】时，你可弃置一张牌，令此【杀】伤害值基数+1。此【杀】结算后，若此【杀】未造成伤害，你对此【杀】的使用者造成1点伤害。",

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
      end), 1, 1, "#os__cuorui-target", self.name)
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
  events = {fk.BuryVictim},
  can_trigger = function(self, event, target, player, data)
    return data.damage and data.damage.from and player:hasSkill(self.name) and data.damage.from == player 
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
}

local os__chenwudongxi = General(extension, "os__chenwudongxi", "wu", 4)
local os__yilie = fk.CreateTriggerSkill{
  name = "os__yilie",
  anim_type = "offensive",
  events = {fk.EventPhaseStart, fk.CardUseFinished, fk.TargetSpecified},    
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player == target and player:hasSkill(self.name) and player.phase == Player.Play
    elseif event == fk.CardUseFinished then
      local use = data
      if use.card.name == "jink" and use.toCard and use.toCard.trueName == "slash" and 
      player:getMark("@os__yilie") ~= 0 and string.find(player:getMark("@os__yilie"), "draw") then
        local effect = use.responseToEvent
        return effect.from == player.id
      end
    else
      if target == player and player:hasSkill(self.name) and
      data.card.trueName == "slash" and 
      player:getMark("@os__yilie") ~= 0 and string.find(player:getMark("@os__yilie"), "draw") and data.to then
        local to = player.room:getPlayerById(data.to)
        return to.chained
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local choices = {"os__yilie_times", "os__yilie_draw", "beishui_os__yilie" ,"Cancel"}
      local choice = player.room:askForChoice(player, choices, self.name)
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
    if event == fk.EventPhaseStart then
      local room = player.room
      local choice = self.cost_data
      if choice == "beishui_os__yilie" then
        room:setPlayerMark(player, "@os__yilie", "yl_times_draw")
        room:loseHp(player, 1, self.name)
      elseif choice == "os__yilie_times" then
        room:setPlayerMark(player, "@os__yilie", "yl_times")
      elseif choice == "os__yilie_draw" then
        room:setPlayerMark(player, "@os__yilie", "yl_draw")
      end
    else
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("@os__yilie") ~= 0 and data.from == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@os__yilie", 0)
  end,
}
local os__yilieBuff = fk.CreateTargetModSkill{
  name = "#os__yilieBuff",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return (player:getMark("@os__yilie") ~= 0 and string.find(player:getMark("@os__yilie"), "times")) and 1 or 0
    end
  end,
}

local os__fenming = fk.CreateTriggerSkill{
  name = "os__fenming",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and
      player.phase == Player.Start and not table.every(player.room:getAlivePlayers(), function(p)
        return (p:isNude() and p.chained)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askForChoosePlayers(
      player,
      table.map(
        table.filter(room:getAlivePlayers(), function(p)
          return (not p:isNude() or not p.chained)
        end),
        function(p)
          return p.id
        end
      ),
      1,
      1,
      "#os__fenming-ask",
      self.name
    )

    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(self.cost_data)
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
os__yilie:addRelatedSkill(os__yilieBuff)
os__chenwudongxi:addSkill(os__fenming)

Fk:loadTranslationTable{
  ["os__chenwudongxi"] = "陈武董袭",
  ["os__yilie"] = "毅烈",
  [":os__yilie"] = "出牌阶段开始时，你可选择此阶段内：1.使用【杀】的次数上限+1；2.当你使用的【杀】指定处于连环状态的角色为目标后，或被【闪】抵消后，摸一张牌；背水：你失去1点体力。",
  ["os__fenming"] = "奋命",
  [":os__fenming"] = "准备阶段，你可选择一名角色并选择一项：1.你弃置其一张牌；2. 其进入连环状态；背水：你进入连环状态。",

  ["os__yilie_times"] = "使用【杀】的次数上限+1", 
  ["os__yilie_draw"] = "当你使用的【杀】指定处于连环状态的角色为目标后，或被【闪】抵消后，摸一张牌", 
  ["@os__yilie"] = "毅烈",
  ["yl_times_draw"] = "摸牌 多出杀",
  ["yl_times"] = "多出杀",
  ["yl_draw"] = "摸牌",

  ["beishui_os__yilie"] = "背水：你失去1点体力",
  ["#os__fenming-ask"] = "你可对一名角色发动 “奋命”",
  ["beishui_os__fenming"] = "背水：你横置",
  ["os__fenming_discard"] = "你弃置其牌",
  ["os__fenming_chained"] = "其横置",
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
  
  ["os__zhuidu_damage"] = "对其造成 1 点伤害",
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
    local card = room:askForCardChosen(player, target, "hej", self.name)
    room:obtainCard(effect.from, card, false)

    local c = room:askForCard(player, 1, 1, true, self.name, false, "", "#os__jimeng-card::" .. target.id)[1]
    room:obtainCard(target, c, false, fk.ReasonGive)

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
      self.name
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
      room:obtainCard(player, c, false, fk.ReasonGive)
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
  [":os__shuaiyan"] = "弃牌阶段开始时，若你的手牌数大于1，你可以展示所有手牌，令一名其他角色交给你一张牌。",

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
      end), 1, 1, "#os__dingfa-target", self.name)
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
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            x = x + 1
          end
        end
      end
    end
    if x > 0 then 
      self.cost_data = x
      return true
    end
    return false
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@os__dingfa-turn", self.cost_data)
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

local os__gongge = fk.CreateTriggerSkill{ --对地主神技
  name = "os__gongge",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return 
      target == player and
      player:hasSkill(self.name) and
      data.firstTarget and player:usedSkillTimes(self.name) < 1 and
      table.contains({"slash", "duel", "savage_assault", "archery_attack", "fire_attack" }, data.card.trueName)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local alivePlayers = room:getAlivePlayers()
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
    local room = player.room
    local prompt = "#os__zhenjun-target"
    local plist, cid = room:askForChooseCardAndPlayers(player, table.map(room:getOtherPlayers(player), function(p)
      return p.id
    end), 1, 1, nil, prompt, self.name, true)
    if #plist > 0 then
      self.cost_data = {plist[1], cid}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = self.cost_data[1]
    room:doIndicate(player.id, { to })
    room:obtainCard(to, self.cost_data[2], false, fk.ReasonGive)
    
    local target = room:getPlayerById(to)
    room:addPlayerMark(target, "_os__zhenjun_target", 1)
    local use = room:askForUseCard(target, "slash", "slash|.|heart,diamond,nonsuit", "#os__zhenjun_slash", true) --exppattern没有black，没有^
    if use then
      room:useCard(use)
      room:setPlayerMark(target, "_os__zhenjun_target", 0)
      local x = target:getMark("_os__zhenjun_damage") + 1
      player:drawCards(x, self.name)
    else
      room:setPlayerMark(target, "_os__zhenjun_target", 0)
      local victim = room:askForChoosePlayers(
        player,
        table.map(
          table.filter(room:getAlivePlayers(), function(p)
            return (p == target or target:inMyAttackRange(p)  )
          end),
          function(p)
            return p.id
          end
        ),
        1,
        1,
        "#os__zhenjun-damage::" .. to,
        self.name
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
    return target == player and player:getMark("_os__zhenjun_target") > 0 and data.card and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "_os__zhenjun_damage", data.damage)
  end,
}
os_sp__yujin:addSkill(os__zhenjun)

Fk:loadTranslationTable{
  ["os_sp__yujin"] = "于禁",
  ["os__zhenjun"] = "镇军",
  [":os__zhenjun"] = "出牌阶段开始时，你可以交给一名其他角色一张牌，令其使用一张非黑色的【杀】：若其执行，则此【杀】结算后你摸一张牌，若此【杀】造成过伤害，你额外摸伤害值数张牌；若其不执行，则你可对其或其攻击范围内的一名角色造成1点伤害。",

  ["#os__zhenjun-target"] = "镇军：你可选择一张牌，交给一名其他角色",
  ["#os__zhenjun_slash"] = "镇军：请使用一张非黑色的【杀】",
  ["#os__zhenjun-damage"] = "镇军：你可对 %dest 或其攻击范围内的一名角色造成1点伤害",
}

local os__tianyu = General(extension, "os__tianyu", "wei", 4) --但，国际服测试服先上线，十周年测试服后上线

--- 判断一名角色场上有没有可以被移动的牌。
---@param target ServerPlayer @ 被选牌的人
---@param flag string @ 用"ej"三个字母的组合表示能选择哪些区域, e - 装备区, j - 判定区
---@return boolean @ --TODO: add disabled_ids into function askForCardChosen, filt them in this function
function haveMoveAvailableCards(target, flag)
  local room = target.room
  if string.find(flag, "e") then
    for _, id in ipairs(target:getCardIds(Player.Equip)) do
      local subtype = Fk:getCardById(id).sub_type
      for _, p in ipairs(room:getOtherPlayers(target)) do
        if p:getEquipment(subtype) == nil then
          return true
        end
      end
    end
  end
  if string.find(flag, "h") then
    for _, id in ipairs(target:getCardIds(Player.Judge)) do
      local name = Fk:getCardById(id).name
      for _, p in ipairs(room:getOtherPlayers(target)) do
        if not p:hasDelayedTrick(name) then
          return true
        end
      end
    end
  end
  return false
end

local os__zhenxi = fk.CreateTriggerSkill{
  name = "os__zhenxi",
  anim_type = "control",
  events = {fk.TargetSpecified},    
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and
      data.card.trueName == "slash" and player:usedSkillTimes(self.name) < 1 and data.to then
      local target = player.room:getPlayerById(data.to)
      if target:getHandcardNum() >= player:distanceTo(target) then return true end
      if #target:getCardIds(Player.Equip) + #target:getCardIds(Player.Judge) > 0 then
        return haveMoveAvailableCards(target, "he")
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    local room = player.room
    local target = room:getPlayerById(data.to)
    if target:getHandcardNum() >= player:distanceTo(target) then
      table.insert(choices, "os__zhenxi_discard")
    end
    if haveMoveAvailableCards(target, "he") then
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
    if choice ~= "os__zhenxi_move" and target:getHandcardNum() >= player:distanceTo(target) then
      local n = player:distanceTo(target)
      local cards = room:askForCardsChosen(player, target, n, n, "h", self.name)
      room:throwCard(cards, self.name, target, player)
    end
    if choice ~= "os__zhenxi_discard" and haveMoveAvailableCards(target, "he") then
      local id = room:askForCardChosen(player, target, "ej", self.name) --没有不能选什么牌的功能
      local area = room:getCardArea(id)
      
      local tos = {}
      for _, p in ipairs(room:getOtherPlayers(target)) do
        if area == Player.Equip then
          local subtype = Fk:getCardById(id).sub_type
          if p:getEquipment(subtype) == nil then
            table.insert(tos, p.id)
          end
        else
          local name = Fk:getCardById(id).name
          if not p:hasDelayedTrick(name) then
            table.insert(tos, p.id)
          end
        end
      end
      if #tos == 0 then return false end

      local dest = room:askForChoosePlayers(player, tos, 1, 1, "#os__zhenxi-ask:::" .. Fk:getCardById(id).name, self.name)[1]

      local card_area = area == Player.Equip and Card.PlayerEquip or Card.PlayerJudge
      room:moveCards({
        ids = {id},
        from = data.to,
        to = dest,
        toArea = card_area,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
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
      local card = {getCardByPattern(room, "slash")}
      if #card > 0 then
        room:moveCards({
          ids = card,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
        })
      end
    else
      room:addPlayerMark(player, "@" .. self.name, 1)
    end
  end,
}

local os__yangshiAR = fk.CreateAttackRangeSkill{
  name = "#os__yangshiAR",
  global = true,
  correct_func = function(self, from, to)
    return from:getMark("@os__yangshi")
  end,
}

os__tianyu:addSkill(os__zhenxi)
os__yangshi:addRelatedSkill(os__yangshiAR)
os__tianyu:addSkill(os__yangshi)

Fk:loadTranslationTable{
  ["os__tianyu"] = "田豫",
  ["os__zhenxi"] = "震袭",
  [":os__zhenxi"] = "每回合限一次，当你使用【杀】指定目标后，你可选择一项：1.弃置其X张手牌（X为你至其的距离）；2.移动其场上的一张牌。若其体力值大于你或为全场最高，则你可背水。",
  ["os__yangshi"] = "扬师",
  [":os__yangshi"] = "锁定技，当你受到伤害后，你的攻击范围+1，若所有其他角色均在你的攻击范围内，则改为从牌堆获得一张【杀】。",

  ["os__zhenxi_discard"] = "弃置其X张手牌（X为你至其的距离）",
  ["os__zhenxi_move"] = "移动其场上的一张牌",
  ["beishui_os__zhenxi"] = "背水",
  ["#os__zhenxi-ask"] = "震袭：选择【%arg】移动的目标角色",
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
        room:setPlayerMark(player, "_beishui_os__moukui", data.card.id)
        room:addPlayerMark(target, "_beishui_os__moukui_target", 1)
      end
    end
  end,

  refresh_events = {fk.CardUseFinished, fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EnterDying then
      if player == target and player:getMark("_beishui_os__moukui_target") > 0 then
        return true
      end
    elseif player == target and player:getMark("_beishui_os__moukui") == data.card.id then
      return true
    end
    return false
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EnterDying then
      room:setPlayerMark(player, "_beishui_os__moukui_target", 0)
    else
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:getMark("_beishui_os__moukui_target") > 0 and not player:isNude() then
          local card = room:askForCardChosen(p, player, "he", self.name)
          room:throwCard(card, self.name, player, p)
          room:setPlayerMark(p, "_beishui_os__moukui_target", 0)
        end
      end
      room:setPlayerMark(player, "_beishui_os__moukui", 0)
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

local os__wujing = General(extension, "os__wujing", "wu", 4)

local os__fenghan = fk.CreateTriggerSkill{
  name = "os__fenghan",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return 
      target == player and
      player:hasSkill(self.name) and
      data.firstTarget and player:usedSkillTimes(self.name) < 1 and data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local num = #AimGroup:getAllTargets(data.tos)
    
    local result = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), function(p)
        return p.id
      end), 1, num, "#os__fenghan-ask:::" .. num, self.name, true)
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
    if player.phase == Player.NotActive and player:hasSkill(self.name) then
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
    local target = room:askForChoosePlayers(
      player,
      table.map(room:getOtherPlayers(player), function(p)
        return p.id
      end),
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
    local dummy = Fk:cloneCard'slash'
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
    dummy:addSubcards(cids)
    player.room:obtainCard(self.cost_data, dummy, false, fk.ReasonGive)
  end,
}

os__wujing:addSkill(os__fenghan)
os__wujing:addSkill(os__congji)

Fk:loadTranslationTable{
  ["os__wujing"] = "吴景",
  ["os__fenghan"] = "锋悍",
  [":os__fenghan"] = "每回合限一次，当你使用【杀】或伤害锦囊牌指定第一个目标后，你可令至多X名角色摸一张牌（X为目标数）。",
  ["os__congji"] = "从击",
  [":os__congji"] = "当你于回合外弃置牌后，你可将其中的所有红色牌交给一名其他角色。",

  ["#os__fenghan-ask"] = "锋悍：你可令至多 %arg 名角色各摸一张牌",
  ["#os__congji-ask"] = "从击：你可将弃置的牌中所有的红色牌交给一名其他角色",
}

local os__furong = General(extension, "os__furong", "shu", 4)

local os__xuewei = fk.CreateTriggerSkill{
  name = "os__xuewei",
  events = {fk.EventPhaseStart},
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self.name) and target.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryRound) < 1 and #player.room:getAlivePlayers() > 2
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
      self.name
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

local os__xuewei_max =  fk.CreateMaxCardsSkill{
  name = "#os__xuewei_max",
  correct_func = function(self, player)
    return - player:getMark("_os__xuewei_defence_from-turn") * 2
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
os__xuewei:addRelatedSkill(os__xuewei_max)
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
}

local liwei = General(extension, "liwei", "shu", 4)

local os__jiaohua = fk.CreateTriggerSkill{
  name = "os__jiaohua",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(self.name) and player:getMark("_os__jiaohua") ~= 0) then return false end
    for _, move in ipairs(data) do
      local target = move.to and player.room:getPlayerById(move.to) or nil --moveData没有target
      if target and (move.to == player.id or table.every(player.room:getAlivePlayers(), function(p)
          return p.hp >= target.hp
        end)) and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
        local cardType = string.split(player:getMark("_os__jiaohua"), ",")
        for _, info in ipairs(move.moveInfo) do
          table.removeOne(cardType, Fk:getCardById(info.cardId):getTypeString())
        end
        if #cardType > 0 then
          self.cost_data = {target.id, table.concat(cardType, ",")}
          return true
        end
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#os__jiaohua::" .. self.cost_data[1])
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pile = table.clone(room.draw_pile)
    table.insertTable(pile, room.discard_pile)
    local types = string.split(self.cost_data[2], ",")
    local type = room:askForChoice(player, types, self.name, "#os__jiaohua-ask::" .. self.cost_data[1])
    local card = {getCardByPattern(room, ".|.|.|.|.|" .. type, pile)}
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = self.cost_data[1],
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
      local cardType = string.split(player:getMark("_os__jiaohua"), ",")
      table.removeOne(cardType, Fk:getCardById(card[1]):getTypeString())
      room:setPlayerMark(player, "_os__jiaohua", table.concat(cardType, ","))
    end
  end,

  refresh_events = {fk.EventPhaseChanging, fk.GameStart}, --错误的，但是先这样……
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and ((event == fk.EventPhaseChanging and data.from == Player.NotActive) or event == fk.GameStart)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "_os__jiaohua", "basic,trick,equip")
  end,
}

liwei:addSkill(os__jiaohua)

Fk:loadTranslationTable{
  ["liwei"] = "李遗",
  ["os__jiaohua"] = "教化",
  [":os__jiaohua"] = "当你或体力值最小的角色摸牌后，你可选择一种其本次摸牌未获得的类型（每种类型每回合限一次），令其从牌堆中或弃牌堆中获得一张该类型的牌。",

  ["#os__jiaohua"] = "你想对 %dest 发动技能“教化”吗？",
  ["#os__jiaohua-ask"] = "教化：选择一种类型，令 %dest 从牌堆中或弃牌堆中获得一张该类型的牌",
  ["basic"] = "基本牌",
  ["trick"] = "锦囊牌",
  ["equip"] = "装备牌", --这好吗
}

local niufudongxie = General(extension, "niufudongxie", "qun", 4, 4, General.Bigender)

local os__juntun = fk.CreateTriggerSkill{
  name = "os__juntun",
  anim_type = "offensive",
  events = {fk.GameStart, fk.BuryVictim},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not table.every(player.room:getAlivePlayers(), function(p)
      return p:hasSkill("os__xiongjun")
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(
      table.filter(room:getAlivePlayers(), function(p)
        return (not p:hasSkill("os__xiongjun"))
      end),
      function(p)
        return p.id
      end
    )
    if #targets == 0 then return false end
    local target = room:askForChoosePlayers(player, targets, 1, 1, "#os__juntun-ask", self.name )
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(self.cost_data)
    room:handleAddLoseSkills(target, "os__xiongjun", nil)
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
    room:removePlayerMark(player, "@os__baonue", num)
    room:sendLog{
      type = "#os__xiafeng_log",
      from = player.id,
      arg = self.cost_data,
    }
  end,

  refresh_events = {fk.PreCardUse},
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
    for _, target in ipairs(player.room:getAlivePlayers()) do
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

local os__xiafeng_max =  fk.CreateMaxCardsSkill{
  name = "#os__xiafeng_max",
  correct_func = function(self, player)
    return player:getMark("_os__xiafeng-turn")
  end,
}

local os__xiongjun = fk.CreateTriggerSkill{
  name = "os__xiongjun",
  anim_type = "drawcard",
  events = {fk.Damage},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("_damage_times-turn") == 1
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(player.room:getAlivePlayers()) do
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
os__xiafeng:addRelatedSkill(os__xiafeng_disres)
os__xiafeng:addRelatedSkill(os__xiafeng_buff)
os__xiafeng:addRelatedSkill(os__xiafeng_max)
niufudongxie:addSkill(os__xiafeng)
niufudongxie:addRelatedSkill(os__xiongjun)

Fk:loadTranslationTable{
  ["niufudongxie"] = "牛辅董翓",
  ["os__juntun"] = "军屯",
  [":os__juntun"] = "游戏开始时或当其他角色死亡后，你可令一名没有〖凶军〗的角色获得〖凶军〗。当拥有〖凶军〗的其他角色造成伤害后，你获得等量暴虐值。<br></br>" .. 
    "<font color=\"grey\">#\"<b>暴虐值</b>\"<br></br>当你造成或受到伤害后，你获得等量暴虐值。暴虐值上限为5。</font>",
  ["os__xiongxi"] = "凶袭",
  [":os__xiongxi"] = "出牌阶段限一次，你可弃置X张牌对一名其他角色造成1点伤害。（X=5-暴虐值，可以为0）",
  ["os__xiafeng"] = "黠凤",
  [":os__xiafeng"] = "出牌阶段开始时，你可消耗至多3点暴虐值，令你本回合使用的前X张牌无距离和次数限制且不可被响应，手牌上限+X。（X为消耗暴虐值）",
  ["os__xiongjun"] = "凶军",
  [":os__xiongjun"] = "锁定技，当你于一个回合内第一次造成伤害后，所有拥有〖凶军〗的角色各摸一张牌。",

  ["@os__baonue"] = "暴虐值",
  ["#os__juntun-ask"] = "军屯：你可令一名没有〖凶军〗的角色获得〖凶军〗",
  ["#os__xiafeng"] = "黠凤：本回合使用的前X张牌无距离和次数限制且不能被响应，手牌上限+X",
  ["#os__xiafeng_log"] = "%from 消耗了 %arg 点暴虐值",
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
        moveReason = fk.ReasonGive,
        proposer = player.id,
        skillName = self.name,
      },
      {
        ids = cids,
        from = effect.tos[1],
        to = effect.from,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
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
      room:obtainCard(to, id, false, fk.ReasonGive)
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
    return target:distanceTo(player) < 2 and player:hasSkill(self.name) and not (target.dead or player.dead)
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
      local cards = player:getCardIds(Player.Hand)
      local dummy = Fk:cloneCard'slash'
      dummy:addSubcards(cards)
      room:obtainCard(target, dummy, false, fk.ReasonGive)
    end
    if choice ~= "os__yimou_give" then
      local card = {getCardByPattern(room, "slash")}
      if #card > 0 then
        room:moveCards({
          ids = card,
          to = target.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
    if choice ~= "os__yimou_slash" and not target:isKongcheng() then
      local plist, cid = room:askForChooseCardAndPlayers(target, table.map(room:getOtherPlayers(target), function(p)
        return p.id
      end), 1, 1, ".|.|.|hand", "#os__yimou_give", self.name, false)
      room:obtainCard(plist[1], cid, false, fk.ReasonGive)
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
        return player:getMark("_os__zhengrong_damage") == 1
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
    local target = room:askForChoosePlayers(
      player,
      targets,
      1,
      1,
      "#os__zhengrong-ask",
      self.name
    )

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

  refresh_events = {fk.TargetSpecified, fk.Damage, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if target ~= player then return false end
    if event == fk.EventPhaseChanging then
      return data.from == Player.Play
    elseif event == fk.TargetSpecified then
      local playerId = player.id
      return target == player and player.phase == Player.Play and data.firstTarget and #table.filter(AimGroup:getUndoneOrDoneTargets(data.tos), function(id)
        return id ~= playerId end --?
      ) > 0
    else
      return target == player and player.phase == Player.Play
    end
    return false
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      room:addPlayerMark(player, "_os__zhengrong_damage", 1)
    elseif event == fk.TargetSpecified then
      room:addPlayerMark(player, "_os__zhengrong_card_count", 1)
      if player:getMark("_os__zhengrong_card_count") % 2 == 0 then
        room:setPlayerMark(player, "_os__zhengrong_card_able", 1)
      end
    else
      room:setPlayerMark(player, "_os__zhengrong_damage", 0)
      --room:setPlayerMark(player, "_os__zhengrong_card_count", 0)
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
      #player:getPile("os__glory") > 2 and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(#player:getPile("os__glory"), self.name)
    local os__glory = room:askForCard(player, 1, player:getHandcardNum(), false, self.name, true, ".|.|.|os__glory", "#os__hongju_card1", "os__glory")
    local num = #os__glory
    if num > 0 then
      local cids = room:askForCard(player, num, num, false, self.name, false, ".|.|.|hand", "#os__hongju_card2:::" .. tostring(num), nil)
      room:moveCards( 
        {
          ids = os__glory,
          from = player.id,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonExchange,
          proposer = player.id,
          skillName = self.name,
        },
        {
          ids = cids,
          from = player.id,
          to = player.id,
          toArea = Card.PlayerSpecial,
          moveReason = fk.ReasonJustMove,
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
    room:moveCards({
      ids = use.cards,
      from = player.id,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      proposer = player.id,
      skillName = self.name,
    })
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
      (data.card.trueName == "slash" or (data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick))
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, target in ipairs(player.room:getAlivePlayers()) do
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
  [":os__hongju"] = "觉醒技，准备阶段，若“荣”的数量不小于3，则你摸等于“荣”数量的牌，然后用任意张手牌替换等量的“荣”，然后获得〖清侧〗并选择是否减1点体力上限获得技能〖扫讨〗。", --FIXME: Show these skills' names and descriptions in the geenral list, (but not in the game?)
  ["os__qingce"] = "清侧",
  [":os__qingce"] = "出牌阶段，你可将一张“荣”置入弃牌堆，然后弃置其他角色区域内的一张牌。",
  ["os__saotao"] = "扫讨",
  [":os__saotao"] = "锁定技，你使用的【杀】和普通锦囊牌不能被响应。",

  ["#os__zhengrong-ask"] = "征荣：你可选择一名其他角色，将其一张牌置于你的武将牌上",
  ["os__glory"] = "荣",
  ["#os__hongju_card1"] = "鸿举：你可选择任意张“荣”，点“确定”后选择等量意张手牌与之交换",
  ["#os__hongju_card2"] = "鸿举：选择 %arg 张手牌与选择过的“荣”交换",
  ["os__hongju_saotao"] = "减1点体力上限，获得〖扫讨〗（锁定技，你使用的【杀】和普通锦囊牌不能被响应）",
}

local os_ex__guohuai = General(extension, "os_ex__guohuai", "wei", 4)

local os_ex__jingce = fk.CreateTriggerSkill{
  name = "os_ex__jingce",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:getMark("_os_ex__jingce_use-phase") == player.hp
  end,
  on_use = function(self, event, target, player, data)
    local invoke = false
    if player:getMark("_os_ex__jingce_draw-phase") > 0 or player:getMark("_os_ex__jingce_damage-turn") > 0 then
      invoke = true
    end
    player:drawCards(2, self.name)
    if invoke then
      player.room:addPlayerMark(player, "@os_ex__strategy", 1)
    end
  end,

  refresh_events = {fk.PreCardUse, fk.AfterCardsMove, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      return target == player and player:hasSkill(self.name) and player.phase == Player.Play
    elseif event == fk.AfterCardsMove then
      if player.phase == Player.Play then
        for _, move in ipairs(data) do
          local target = move.to and player.room:getPlayerById(move.to) or nil
          if target and move.to == player.id and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
            return true
          end
        end
      end
    else
      return target and target == player and player.phase ~= Player.NotActive and not player.dead
    end
    return false
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      player.room:addPlayerMark(player, "_os_ex__jingce_use-phase", 1)
    elseif event == fk.AfterCardsMove then
      player.room:addPlayerMark(player, "_os_ex__jingce_draw-phase", 1)
    else
      player.room:addPlayerMark(player, "_os_ex__jingce_damage-turn", 1)
    end
  end,
}

local os_ex__yuzhang = fk.CreateTriggerSkill{
  name = "os_ex__yuzhang",
  events = {fk.EventPhaseChanging, fk.Damaged},
  anim_type = "masochism",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging then
      return target == player and player:hasSkill(self.name) and
        data.to >= Player.Start and data.to <= Player.Finish and player:getMark("@os_ex__strategy") > 0
    else
      return target == player and player:hasSkill(self.name) and player:getMark("@os_ex__strategy") > 0 and data.from and not data.from.dead
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging then
      local phase_name_table = {
        [2] = "phase_start",
        [3] = "phase_judge",
        [4] = "phase_draw",
        [5] = "phase_play",
        [6] = "phase_discard",
        [7] = "phase_finish",
      }
      return player.room:askForSkillInvoke(player, self.name, data, "#os_ex__yuzhang:::" .. phase_name_table[data.to])
    else
      local choices = {"os_ex__yuzhang_disable", "Cancel"}
      local target = data.from
      if #target:getCardIds(Player.Hand) + #target:getCardIds(Player.Equip) > 1 then
        table.insert(choices, 2, "os_ex__yuzhang_discard")
      end
      local choice = player.room:askForChoice(player, choices, self.name, "#os_ex__yuzhang-ask::" .. target.id)
      if choice ~= "Cancel" then
        self.cost_data = choice
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@os_ex__strategy")
    room:broadcastSkillInvoke(self.name)
    if event == fk.EventPhaseChanging then
      room:notifySkillInvoked(player, self.name, "defensive")
      return true
    else
      room:notifySkillInvoked(player, self.name)
      local choice = self.cost_data
      local target = data.from
      if choice == "os_ex__yuzhang_discard" then
        room:askForDiscard(target, 2, 2, true, self.name, false)
      else
        room:addPlayerMark(target, "_os_ex__yuzhang_pro-turn", 1)
      end
    end
  end,
}

local os_ex__yuzhang_prohibit = fk.CreateProhibitSkill{
  name = "#os_ex__yuzhang_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("_os_ex__yuzhang_pro-turn") > 0 --and card.area == Card.PlayerHand
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("_os_ex__yuzhang_pro-turn") > 0 --and card.area == Card.PlayerHand
  end,
}
os_ex__guohuai:addSkill(os_ex__jingce)
os_ex__yuzhang:addRelatedSkill(os_ex__yuzhang_prohibit)
os_ex__guohuai:addSkill(os_ex__yuzhang)


Fk:loadTranslationTable{
  ["os_ex__guohuai"] = "界郭淮",
  ["os_ex__jingce"] = "精策",
  [":os_ex__jingce"] = "当你出牌阶段使用的第X张牌结算结束后（X为你的体力值），你可摸两张牌，然后若这不是你本阶段第一次摸牌或本回合你已造成过伤害，你获得1枚“策”。",
  ["os_ex__yuzhang"] = "御嶂",
  [":os_ex__yuzhang"] = "你可弃1枚“策”，跳过一个阶段。当你受到伤害后，你可弃1枚“策”并选择一项，令伤害来源执行：1.本回合不能使用或打出手牌；2.弃置两张牌。", 

  ["@os_ex__strategy"] = "策",
  ["#os_ex__yuzhang"] = "御嶂：你可弃1枚“策”，跳过 %arg",
  ["#os_ex__yuzhang-ask"] = "御嶂：你可弃1枚“策”，选择一项，令 %dest 执行",
  ["os_ex__yuzhang_disable"] = "令其本回合不能再使用或打出手牌",
  ["os_ex__yuzhang_discard"] = "其弃置两张牌",

  ["phase_start"] = "准备阶段",
  ["phase_finish"] = "结束阶段",
}


local os__daqiaoxiaoqiao = General(extension, "os__daqiaoxiaoqiao", "wu", 3, 3, General.Female)

local os__xingwu = fk.CreateTriggerSkill{
  name = "os__xingwu",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Discard and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, true, self.name, true, nil, "#os__xingwu-put")
    if #card > 0 then
      self.cost_data = card[1]
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
    if #player:getPile("os__dance") == 0 then --由于下面的问题……什么耦合，改！
      local skills = {"tianxiang", "liuli"}
      for  _, skill in ipairs(skills) do
        if player:hasSkill(skill) then
          room:handleAddLoseSkills(player, "-" .. skill, nil)
        end
      end
    end
    room:throwCard(target:getCardIds(Player.Equip), self.name, target, player)
    room:damage{
      from = player,
      to = target,
      damage = target.gender == General.Male and 2 or 1,
      skillName = self.name,
    }
  end,
}

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

  refresh_events = {fk.AfterCardsMove},--还要再加上技能获得技能失去的时机
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.to and move.to == player.id and move.toArea == Card.PlayerSpecial and #player:getPile("os__dance") > 0 then
          self.cost_data = true
          return true
        elseif move.fromArea == Card.PlayerSpecial and #player:getPile("os__dance") == 0 then
          self.cost_data = false
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local skills = {"tianxiang", "liuli"}
    local room = player.room
    for _, skill in ipairs(skills) do
      if self.cost_data and not player:hasSkill(skill) then
        room:handleAddLoseSkills(player, skill, nil)
      elseif not self.cost_data and player:hasSkill(skill) then
        room:handleAddLoseSkills(player, "-" .. skill, nil)
      end
    end
  end,
}

os__xingwu:addRelatedSkill(os__xingwu_damage)
os__daqiaoxiaoqiao:addSkill(os__xingwu)
os__daqiaoxiaoqiao:addSkill(os__pingting)
os__daqiaoxiaoqiao:addRelatedSkill("tianxiang")
os__daqiaoxiaoqiao:addRelatedSkill("liuli")

Fk:loadTranslationTable{
  ["os__daqiaoxiaoqiao"] = "大乔小乔",
  ["os__xingwu"] = "星舞",
  [":os__xingwu"] = "弃牌阶段开始时，你可将一张牌置于你的武将牌上（称为“星舞”），然后你可将三张“星舞”置入弃牌堆，选择一名其他角色，弃置其装备区里的所有牌，然后若其为男/非男性角色，你对其造成2/1点伤害。",
  ["os__pingting"] = "娉婷",
  [":os__pingting"] = "锁定技，每轮开始时或当其他角色于你回合内进入濒死状态时，你摸一张牌，然后将一张牌置于武将牌上（称为“星舞”）。若你有“星舞”，你拥有〖天香〗和〖流离〗。",
  
  ["#os__xingwu-put"] = "星舞：你可将一张牌置于你的武将牌上（称为“星舞”）",
  ["os__dance"] = "星舞",
  ["#os__xingwu-damage"] = "你可将三张“星舞”置入弃牌堆，对一名其他角色发动“星舞”",
  ["#os__xingwu_damage"] = "星舞",
  ["#os__pingting-put"] = "娉婷：将一张牌置于你的武将牌上（称为“星舞”）",
}


local os__xujing = General(extension, "os__xujing", "shu", 3)

local os__boming = fk.CreateActiveSkill{
  name = "os__boming",
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = function() return true end,
  card_num = 1,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    room:moveCards({
      ids = effect.cards,
      from = effect.from,
      to = effect.tos[1],
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonGive,
      proposer = effect.from,
      skillName = self.name,
    })
  end,
}

local os__boming_draw = fk.CreateTriggerSkill{
  name = "#os__boming_draw",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and player:getMark("_os__boming_card-turn") > 1
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player.phase ~= Player.NotActive then
      local num = 0
      for _, move in ipairs(data) do
        local target = move.to and player.room:getPlayerById(move.to) or nil
        if target and move.to ~= player.id and move.toArea == Card.PlayerHand then
          num = num + #move.moveInfo
        end
      end
      if num > 0 then
        self.cost_data = num
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__boming_card-turn", self.cost_data)
  end,
}

local os__ejian = fk.CreateTriggerSkill{
  name = "os__ejian",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      local target = move.to and player.room:getPlayerById(move.to) or nil
      local from = move.from and player.room:getPlayerById(move.from) or nil
      if from and from == player and from:hasSkill(self.name) and target and move.to ~= player.id and move.toArea == Card.PlayerHand then
        local cardType = {}
        local fromCard = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          table.insertIfNeed(cardType, Fk:getCardById(id):getTypeString())
          table.insert(fromCard, id)
        end
        local cids = target:getCardIds(Player.Hand)
        table.insertTable(cids, target:getCardIds(Player.Equip))
        local cards = {}
        for _, id in ipairs(cids) do
          if table.contains(cardType, Fk:getCardById(id):getTypeString()) and not table.contains(fromCard, id) then
            table.insert(cards, id)
          end
        end
        if #cards > 0 then
          self.cost_data = {move.to, cards}
          return true --同时移动牌中同时给两名其他角色就有问题，怎么解决
        end
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(self.cost_data[1])
    local cards = self.cost_data[2]
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

os__boming:addRelatedSkill(os__boming_draw)
os__xujing:addSkill(os__boming)
os__xujing:addSkill(os__ejian)

Fk:loadTranslationTable{
  ["os__xujing"] = "许靖",
  ["os__boming"] = "博名",
  [":os__boming"] = "出牌阶段限两次，你可以将一张牌交给一名其他角色。结束阶段开始时，若其他角色于此回合内获得的牌数大于1，你摸两张牌。",
  ["os__ejian"] = "恶荐",
  [":os__ejian"] = "当其他角色获得你的牌后，若其有除此牌以外的牌与此牌类型相同的牌，你可令其选择：1. 弃置这些牌；2. 受到你造成的1点伤害。",

  ["#os__boming_draw"] = "博名",
  ["os__ejian_discard"] = "弃置除获得的牌外和获得的牌类型相同的牌",
  ["os__ejian_damage"] = "受到1点伤害",
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
    local result = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
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
      local id = room:askForCardChosen(player, from, "hej", self.name)
      room:moveCards({
        ids = {id},
        from = data.from,
        to = nil,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        proposer = player.id,
        skillName = self.name,
      })
      table.insert(room.draw_pile, 1, id)
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
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and player:getMark("@os__shelie-turn") ~= 0 and #string.split(player:getMark("@os__shelie-turn"), " ") == 4 and player:usedSkillTimes(self.name, Player.HistoryRound) < 1
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
    --player:play({self.cost_data == "phase_draw" and Player.Draw or Player.Play})
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase ~= Player.NotActive and data.card.suit ~= Card.NoSuit
  end,
  on_refresh = function(self, event, target, player, data)
    local card_suits = player:getMark("@os__shelie-turn") ~= 0 and string.split(player:getMark("@os__shelie-turn"), " ") or {}
    local card_suits_table = {
      [1] = "♠",
      [2] = "♣",
      [3] = "♥",
      [4] = "♦",
    }
    table.insertIfNeed(card_suits, card_suits_table[data.card.suit])
    player.room:setPlayerMark(player, "@os__shelie-turn", table.concat(card_suits, " "))
  end,
}

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
    local id = room:askForAG(player, cids, true, self.name)
    room:closeAG(player)
    if not id then return false end
    local choice = room:askForChoice(player, {"os__gongxin_discard", "os__gongxin_put", "Cancel"}, self.name, "#os__gongxin-treat:::" .. Fk:getCardById(id).name)
    if choice == "os__gongxin_discard" then
      room:throwCard({id}, self.name, target, player)
    elseif choice == "os__gongxin_put" then
      room:moveCards({
        ids = {id},
        from = target.id,
        to = nil,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        proposer = player.id,
        skillName = self.name,
      })
      table.insert(room.draw_pile, 1, id)
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
        room:setPlayerMark(player, "_os__gongxin-turn", 0)
      end
    end
  end,
}

os__shelie:addRelatedSkill(os__shelie_extra)
os__godlvmeng:addSkill(os__shelie)
os__gongxin:addRelatedSkill(os__gongxin_dr)
os__godlvmeng:addSkill(os__gongxin)

Fk:loadTranslationTable{
  ["os__godlvmeng"] = "神吕蒙",
  ["os__shelie"] = "涉猎",
  [":os__shelie"] = "摸牌阶段，你可以改为亮出牌堆顶的五张牌，然后获得其中每种花色的牌各一张。每轮限一次，结束阶段开始时，若你本回合使用了四种花色的牌，你选择执行一个额外的摸牌阶段或出牌阶段且不能与上次选择相同。",
  ["os__gongxin"] = "攻心",
  [":os__gongxin"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后你可展示其中一张牌，选择一项：1. 你弃置其此牌；2. 将此牌置于牌堆顶，然后若其手牌中花色数因此减少，其不能响应你本回合使用的下一张牌。",

  ["@os__shelie-turn"] = "涉猎",
  ["#os__shelie_extra"] = "涉猎",
  ["#os__shelie_extra-ask"] = "涉猎：选择执行一个额外的阶段",
  ["#os__shelie_extra_log"] = "%from 发动“%arg”，执行一个额外的 %arg2",
  ["#os__gongxin-treat"] = "攻心：你可对【%arg】选择一项",
  ["os__gongxin_discard"] = "弃置",
  ["os__gongxin_put"] = "置于牌堆顶",
  ["@@os__gongxin_dr-turn"] = "攻心",
}

--[[
local os__wangcan = General(extension, "os__wangcan", "wei", 3)

local os__dianyi = fk.CreateTriggerSkill{
  name = "os__dianyi",
  anim_type = "drawcard",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if player == target and data.to == Player.NotActive then
      if player:getMark("_os__dianyi") > 0 then
        player.room:setPlayerMark(player, "_os__dianyi", 0)
      end
      return player:hasSkill(self.name)
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke(self.name)
    if player:getMark("_os__dianyi") > 0 then
      room:notifySkillInvoked(player, self.name, "negative")
      player:throwAllCards("h")
    else
      local num = 4 - player:getHandcardNum()
      room:notifySkillInvoked(player, self.name)
      if num > 0 then
        player:drawCards(num, self.name)
      elseif num < 0 then
        player.room:askForDiscard(player, num, num, false, self.name, false)
      end
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase ~= Player.NotActive and player:getMark("_os__dianyi") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__dianyi", 1)
  end,
}

local basics_and_NDtricks = "slash,jink,peach,analeptic," .. 
"duel,savage_assault,archery_attack,fire_attack,dismantlement,snatch,collateral,nullification,ex_nihilo,amazing_grace,god_salvation,iron_chain" --好蠢

local os__yingji = fk.CreateViewAsSkill{
  name = "os__yingji",
  card_filter = function(self, card)
    return false
  end,
  card_num = 0,
  interaction = UI.ComboBox {
    choices = table.filter({"peach", "jink", "slash", "thunder__slash", "fire__slash", "analeptic", "duea", "savage_assault", "archery_attack", "fire_attack", "dismantlement", "snatch", "collateral", "nullification", "ex_nihilo", "amazing_grace", "god_salvation", "iron_chain"}, function(name)
      return (true) --Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard(name)))
    end)
  },
  view_as = function(self, cards)
    local choice = self.interaction.data
    if not choice then return end
    local c = Fk:cloneCard(choice)
    c.skillName = self.name
    return c
  end,
  enabled_at_play = function(self, player)
    return player:isKongcheng()
  end,
  enabled_at_response = function(self, player)
    return player.phase == Player.NotActive and player:isKongcheng()
  end,
}

local os__shanghe = fk.CreateTriggerSkill{
  name = "os__shanghe",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local not_include = true
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:isNude() then
        local id = room:askForCard(p, 1, 1, true, self.name, false)[1]
        if not_include and Fk:getCardById(id).name == "analeptic" then
          not_include = false
        end
        room:obtainCard(player, id, false, fk.ReasonGive)
      end
    end

    if not_include then
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
  [":os__shanghe"] = "限定技，当你进入濒死状态时，你可令所有其他角色各交给你一张牌。若其中没有【酒】，你将体力回复至1点。",
}
]]

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
      self.cost_data = targets
      return true
    elseif num > 2 then
      if #table.filter(room:getOtherPlayers(player), function(p)
        p:hasSkill(self.name)
      end) == 0 then
        table.forEach(room:getAlivePlayers(), function(p)
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
    table.forEach(self.cost_data, function(pid)
      room:setPlayerMark(room:getPlayerById(pid), "@os__lingfa", mark)
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
        room:obtainCard(player, cids[1], false, fk.ReasonGive)
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
      --room:throwCard(data.card.subcards, self.name, owner, player)
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

os__lingfa:addRelatedSkill(os__lingfa_use)
os_sp__caocao:addSkill(os__lingfa)
os_sp__caocao:addRelatedSkill(os__zhian)

Fk:loadTranslationTable{
  ["os_sp__caocao"] = "曹操",
  ["os__lingfa"] = "令法",
  [":os__lingfa"] = "每轮开始时，若当前轮数不大于2，你可令第X项效果对所有有牌的其他角色生效（X为当前轮数）：1. 当使用【杀】时，弃置一张牌，否则你对其造成1点伤害；2. 当使用【桃】结算完成后，交给你一张牌，否则你对其造成1点伤害。若当前轮数大于2，则你失去此技能，获得〖治暗〗。",
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
  interaction = UI.ComboBox {
    choices = {"1", "2", "3"}
  },
  on_use = function(self, room, effect)
    if not self.interaction.data then return false end
    local player = room:getPlayerById(effect.from)
    room:loseHp(player, 1, self.name)
    if not player.dead then
      local num = self.interaction.data
      room:setPlayerMark(player, "@os__xingzhui", num .. "-" .. num)
    end
  end,
}

local os__xingzhui_do = fk.CreateTriggerSkill{
  name = "#os__xingzhui_do",
  mute = true,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.to == Player.NotActive and player:getMark("@os__xingzhui") ~= 0
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
    for _, p in ipairs(room:getAlivePlayers()) do
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

os__xingzhui:addRelatedSkill(os__xingzhui_do)
os__zhangning:addSkill(os__xingzhui)
os__zhangning:addSkill(os__juchen)

Fk:loadTranslationTable{
  ["os__zhangning"] = "张宁",
  ["os__xingzhui"] = "星坠",
  [":os__xingzhui"] = "出牌阶段限一次，你可以失去1点体力并施法X=1~3回合：亮出牌堆顶2X张牌，若其中有黑色牌，则你可令一名其他角色获得这些黑色牌，若这些牌的数量不小于X ，则你对其造成X点雷电伤害。" .. 
    "<br></br><font color=\"grey\">#\"<b>施法</b>\"<br></br>一名角色的回合结束前，施法标记-1，减至0时执行施法效果。施法期间不能重复施法同一技能。",
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
      table.filter(player.room:getAlivePlayers(), function(p)
        return (p:getMark("_os__xiongzheng") == 0)
      end),
      function(p)
        return p.id
      end
    )
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local target = player.room:askForChoosePlayers(
      player,
      self.cost_data,
      1,
      1,
      "#os__xiongzheng-ask",
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
          if player.dead then break end
          new_use.tos = { { pid } }
          room:useCard(new_use)
        end
      end
    else
      local availableTargets = table.map(
        table.filter(room:getAlivePlayers(), function(p)
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

local os__luannian = fk.CreateTriggerSkill{
  name = "os__luannian$",
  mute = true,
  frequency = fk.Compulsory,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not table.every(player.room:getOtherPlayers(player), function(p)
      return p.kingdom ~= "qun"
    end)
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return (p.kingdom == "qun")
    end)
    table.forEach(targets, function(p)
      room:handleAddLoseSkills(p, "os__luannian_other", nil, false, false)
    end)
  end,
}

local os__luannian_other = fk.CreateActiveSkill{
  name = "os__luannian_other",
  anim_type = "offensive",
  mute = true,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and player.kingdom == "qun" then
      local room = Fk:currentRoom()
      local lord --手动getLord
      for _, p in ipairs(room.alive_players) do
        if p.role == "lord" and p:hasSkill("os__luannian") then lord = p break end
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
      if p.role == "lord" and p:hasSkill("os__luannian") then lord = p break end
    end
    return lord:getMark("@os__luannian-round") + 1
  end,
  card_filter = function(self, to_select, selected)
    local lord
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p.role == "lord" and p:hasSkill("os__luannian") then lord = p break end
    end
    return #selected < lord:getMark("@os__luannian-round") + 1
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:notifySkillInvoked(player, "os__luannian")
    room:broadcastSkillInvoke("os__luannian")
    local target
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:getMark("_os__xiongzheng-round") > 0 then
        target = p
        break
      end
    end
    if not target then return false end
    room:doIndicate(effect.from, { target.id })
    room:addPlayerMark(room:getLord(), "@os__luannian-round", 1)
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
os__xiongzheng:addRelatedSkill(os__xiongzheng_judge)
os__mateng:addSkill(os__xiongzheng)
os__mateng:addSkill(os__luannian)
Fk:addSkill(os__luannian_other) --FIXME! attached_skill

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

  ["os__luannian_other"] = "乱年",
  [":os__luannian_other"] = "出牌阶段限一次，你可弃置X张牌对“雄争”角色造成1点伤害（X为“乱年”本轮发动的次数+1）。",
}




--[[local wangyue = General(extension, "wangyue", "qun", 4)

local os__yulong = fk.CreateTriggerSkill{
  name = "os__yulong",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.firstTarget and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local alivePlayers = room:getAlivePlayers()
    local availableTargets = {}
    for _, p in ipairs(alivePlayers) do
      if table.contains(AimGroup:getAllTargets(data.tos), p.id) then
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
      room:setPlayerMark(player, "_os__yulong_id", data.card.id)
      if pd.fromCard.color == Card.Black then
        room:setPlayerMark(player, "_os__yulong", 1)
      elseif pd.fromCard.color == Card.Red then
        data.disresponsive = true
      end
    end
  end,

  refresh_events = {fk.Damage, fk.DamageCaused, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    local invoke = (target == player and data.card and data.card.trueName == "slash" and player:getMark("_os__yulong_id") == data.card.id)
    if event == fk.DamageCaused then --加伤
      return invoke and player:getMark("_os__yulong") == 1
    else --FIXME: GlobalCardDamagedTag
      return invoke
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      player:addCardUseHistory("slash", -1)
    elseif event == fk.DamageCaused then
      data.damage = data.damage + 1
    else
      player.room:setPlayerMark(player, "_os__yulong_id", 0) --不然又摸到同一张……
      player.room:setPlayerMark(player, "_os__yulong", 0)
    end
  end,
}

local os__jianming = fk.CreateTriggerSkill{
  name = "os__jianming",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardUseDeclared, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target == player and data.card.trueName == "slash" and player:getMark("_os__jianming:" .. data.card.suit .. "-turn") == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    player.room:addPlayerMark(player, "_os__jianming:" .. data.card.suit .. "-turn", 1)
  end,
}

wangyue:addSkill(os__yulong)
wangyue:addSkill(os__jianming)

Fk:loadTranslationTable{
  ["wangyue"] = "王越",
	["os__yulong"] = "驭龙",
	[":os__yulong"] = "当你使用【杀】指定第一个目标后，你可与其中一名目标拼点。若你：赢，若此【杀】造成了伤害则不计入次数，" .. 
    "且你此次的拼点牌为：黑色，此【杀】对其的伤害+1；红色，此【杀】不可被响应。",
	["os__jianming"] = "剑鸣",
	[":os__jianming"] = "锁定技，每回合每花色限一次，当你使用或打出一种花色的【杀】时，你摸一张牌。",

  ["#os__yulong-ask"] = "驭龙：你可与一名目标拼点",
}]]

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
      local c = room:askForCard(p, 1, 1, true, self.name, true, nil, "#os__mouzhu-card::" .. player.id)
      if #c > 0 then
        room:obtainCard(player, c[1], false, fk.ReasonGive)
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
    local choices = {"os__yanhuo_x", "os__yanhuo_1", "Cancel"}
    if num == 0 then return false 
    elseif num == 1 then choices = {"os__yanhuo_1", "Cancel"} end
    local choice = player.room:askForChoice(player, choices, self.name, "#os__yanhuo-ask:::" .. tostring(num))
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
      return (not p:isNude())
    end),
    function(p)
      return p.id
    end)
    if #targets == 0 then return false end
    local choice = self.cost_data
    local num = #player:getCardIds(Player.Equip) + #player:getCardIds(Player.Hand)
    if choice == "os__yanhuo_x" then
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
  ["#os__yanhuo-ask"] = "你可发动“延祸”（X=%arg）",
  ["os__yanhuo_x"] = "令至多X名角色各弃置一张牌",
  ["os__yanhuo_1"] = "令一名角色弃置X张牌",
  ["#os__yanhuo-target_x"] = "延祸：选择至多 %arg 名角色，各弃置一张牌",
  ["#os__yanhuo-target_1"] = "延祸：选择一名角色，令其弃置 %arg 张牌",
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
      table.filter(player.room:getAlivePlayers(), function(p)
        return (p:distanceTo(player) <= num)
      end),
      function(p)
        return p.id
      end
    )
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local targets = player.room:askForChoosePlayers(
      player,
      self.cost_data,
      1,
      1,
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
    room:moveCards(move) --实际不是这样的，要用郭嘉遗计的cheakMove
    while #player:getPile("os__poise") > 0 do
      ids = room:askForCard(player, 1, #player:getPile("os__poise"), false, self.name, false, ".|.|.|os__poise", "#os__youye-give2", "os__poise")
      local pid = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), function(p)
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

os__dingzhen:addRelatedSkill(os__dingzhen_prohibit)
zhangjih:addSkill(os__dingzhen)
os__youye:addRelatedSkill(os__youye_give)
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

local os_ex__madai = General(extension, "os_ex__madai", "shu", 4)

local os_ex__qianxi = fk.CreateTriggerSkill{ --……
  name = "os_ex__qianxi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    local card = room:askForDiscard(player, 1, 1, true, self.name, false, ".", "#qianxi-discard")
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:distanceTo(p) == 1 end), function(p)
      return p.id end)
    if #targets == 0 then return false end
    local color = Fk:getCardById(card[1]):getColorString()
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#os_ex__qianxi-choose:::" .. color, self.name, false)
    --if #to == 0 then to = table.random(targets, 1) end --权宜
    if #to > 0 then
      room:setPlayerMark(room:getPlayerById(to[1]), "@qianxi-turn", color)
      room:setPlayerMark(player, "_os_ex__qianxi_target-turn", to[1])
    end
  end,

  refresh_events = {fk.Damage, fk.EventPhaseChanging, fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    if event == fk.Damage then return target == player and not data.to.dead and player:getMark("_os_ex__qianxi_target-turn") == data.to.id and data.card and data.card.trueName == "slash" and player.phase ~= Player.NotActive 
    elseif event == fk.EventPhaseChanging then return target == player and data.to == Player.NotActive and player:getMark("@os_ex__qianxi") ~= 0 
    else return target == player and player.phase == Player.Finish and player:getMark("_os_ex__qianxi_done-turn") > 0 end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then room:setPlayerMark(player, "_os_ex__qianxi_done-turn", 1)
    elseif event == fk.EventPhaseChanging then room:setPlayerMark(player, "@os_ex__qianxi", 0)
    else 
      local p = room:getPlayerById(player:getMark("_os_ex__qianxi_target-turn"))
      player.room:setPlayerMark(p, "@os_ex__qianxi", p:getMark("@qianxi-turn") == "red" and "black" or "red")
    end
  end,
}

local os_ex__qianxi_prohibit = fk.CreateProhibitSkill{
  name = "#os_ex__qianxi_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@qianxi-turn") ~= 0 then return card:getColorString() == player:getMark("@qianxi-turn") end
    if player:getMark("@os_ex__qianxi") ~= 0 then return card:getColorString() == player:getMark("@os_ex__qianxi") end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@qianxi-turn") ~= 0 then return card:getColorString() == player:getMark("@qianxi-turn") end
    if player:getMark("@os_ex__qianxi") ~= 0 then return card:getColorString() == player:getMark("@os_ex__qianxi") end
  end,
}

os_ex__madai:addSkill("mashu")
os_ex__qianxi:addRelatedSkill(os_ex__qianxi_prohibit)
os_ex__madai:addSkill(os_ex__qianxi)

Fk:loadTranslationTable{
  ["os_ex__madai"] = "界马岱",
  ["os_ex__qianxi"] = "潜袭",
  [":os_ex__qianxi"] = "准备阶段开始时，你可摸一张牌，然后弃置一张牌，令距离为1的一名角色本回合不能使用或打出与你以此法弃置的牌颜色相同的手牌，然后结束阶段开始时，若你于本回合使用【杀】对其造成过伤害，你令其不能使用或打出另一种颜色的牌至其下回合结束。",
  
  ["#os_ex__qianxi-choose"] = "潜袭：选择距离为1的一名角色，令其本回合不能使用或打出 %arg 的手牌",
  ["@qianxi-turn"] = "潜袭",
  ["@os_ex__qianxi"] = "潜袭",
}

--[[local bingyuan = General(extension, "bingyuan", "qun", 3)

local os__bingde = fk.CreateActiveSkill{
  name = "os__bingde",
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    --return Self:getMark("_os__bingde_done-turn") == 0 or not string.find(Self:getMark("_os__bingde_done-turn"), card_suits_table(Fk:getCardById(to_select):getSuitString()))
    return true
  end,
  target_num = 0,
  interaction = UI.ComboBox { choices = {"♠", "♣", "♥", "♦"} },--return UI.ComboBox { choices = table.filter({"♠", "♣", "♥", "♦"}, function(suitString) return Self:getMark("_os__bingde_done-turn") == 0 or not string.find(Self:getMark("_os__bingde_done-turn"), suitString) end) }
  on_use = function(self, room, effect)
    local suit = self.interaction.data
    if not suit then return false end
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player)
    player:drawCards(player:getMark("_os__bingde-turn")[suit], self.name)
    if Fk:getCardById(effect.cards[1]):getSuitString() == suit then
      player:addSkillUseHistory(self.name, -1)
      room:setPlayerMark(player, "_os__bingde_done-turn", table.insert(player:getMark("_os__bingde_done-turn"), suit))
    end
  end,
}

local os__bingde_record = fk.CreateActiveSkill{
  name = "#os__bingde_record",
  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase ~= Player.NotActive and data.card.suit ~= Card.NoSuit
  end,
  on_refresh = function(self, event, target, player, data)
    local bingde_mapper = player:getMark("_os__bingde-turn") or {}
    local card_suits_table = {
      [1] = "♠",
      [2] = "♣",
      [3] = "♥",
      [4] = "♦",
    }
    local suit = card_suits_table[data.card.suit]
    bingde_mapper[suit] = bingde_mapper[suit] + 1
    player.room:setPlayerMark(player, "_os__bingde-turn", bingde_mapper)
  end,
}

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
    room:throwCard(self.cost_data, "recast", player)
    player:drawCards(1, "recast")
    local card = Fk:getCardById(self.cost_data[1])
    if card.name == "analeptic" or card.type ~= Card.TypeBasic then player:drawCards(1, self.name) end
    if event == fk.EventPhaseEnd then room:setPlayerMark(player, "_os__qingtao_invoked-turn", 1) end
  end,
}

os__bingde:addRelatedSkill(os__bingde_record)
bingyuan:addSkill(os__bingde)
bingyuan:addSkill(os__qingtao)

Fk:loadTranslationTable{
  ["bingyuan"] = "邴原",
  ["os__bingde"] = "秉德",
  [":os__bingde"] = "出牌阶段限一次，你可弃置一张牌并选择一种花色，然后摸X张牌（X为你此阶段使用此花色的牌数），若你弃置的牌的花色为选择的花色，此技能视为未发动过且此阶段不能再选择相同的花色。",
  ["os__qingtao"] = "清滔",
  [":os__qingtao"] = "摸牌阶段结束时，你可重铸一张牌，然后若此牌为【酒】或非基本牌，你摸一张牌。若你未发动此技能，你可于此回合的结束阶段开始时发动此技能。",

  ["#os__qingtao-ask"] = "清滔：你可重铸一张牌，然后若此牌为【酒】或非基本牌，你摸一张牌",
}
]]
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

os__xia__dianwei:addSkill(os__liexi)
os__shezhong:addRelatedSkill(os__shezhong_draw)
os__xia__dianwei:addSkill(os__shezhong)

Fk:loadTranslationTable{
  ["os__xia__dianwei"] = "侠典韦",
  ["os__liexi"] = "烈袭",
  [":os__liexi"] = "准备阶段开始时，你可弃置任意张牌并选择一名其他角色，若你弃置的牌数大于其体力值，则你对其造成1点伤害；否则其对你造成1点伤害；若你弃置的牌中包含武器牌，你对其造成1点伤害。",
  ["os__shezhong"] = "慑众",
  [":os__shezhong"] = "结束阶段开始时，你可依次选择执行以下效果：1. 若你本回合对其他角色造成过伤害，则令至多X名其他角色下个摸牌阶段的摸牌数-1（X为你本回合造成的伤害值）；2. 若你本回合受到过伤害，则将手牌摸至与其中一名伤害来源的体力值相同（最多摸至5张）。",

  ["#os__liexi-ask"] = "烈袭：你可弃置任意张牌，点击“确定”后选择一名其他角色",
  ["#os__liexi-target"] = "烈袭：你可选择一名其他角色",
  ["@os__shezhong"] = "慑众",
  ["#os__shezhong1-target"] = "慑众：你可令至多 %arg 名其他角色下个摸牌阶段的摸牌数-1",
  ["#os__shezhong2-target"] = "慑众：你可将手牌摸至与其中一名伤害来源的体力值相同（最多摸至5张）",
  ["#os__shezhong_draw"] = "慑众",
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

local os__duoren = fk.CreateTriggerSkill{
  name = "os__duoren",
  events = {fk.BuryVictim},
  can_trigger = function(self, event, target, player, data)
    return data.damage and data.damage.from and player:hasSkill(self.name) and data.damage.from == player 
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

os__xuechang:addRelatedSkill(os__xuechang_damage)
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
}

--[[local os__xia__xushu = General(extension, "os__xia__xushu", "qun", 4)

local os__jiange = fk.CreateViewAsSkill{
  name = "os__jiange",
  anim_type = "offensive",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    return Fk:getCardById(to_select).type ~= Card.TypeBasic
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
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name) < 1
  end,
}

local os__jiange_buff = fk.CreateTargetModSkill{
  name = "#os__jiange_buff",
  residue_func = function(self, player, skill, scope, card)
    return skill.name == "slash__skill" and card.skillName == "os__jiange" and 1 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return skill.name == "slash__skill" and card.skillName == "os__jiange" and 1 or 0
  end,
}

local os__jiange_draw = fk.CreateTriggerSkill{
  name = "#os__jiange_draw",
  mute = true,
  events = {fk.CardUsing, fk.CardResponding},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.NotActive
  end,
  on_use = function(self, event, player, target, data)
    player:drawCards(1, self.name)
  end,
}

os__jiange:addRelatedSkill(os__jiange_buff)
os__jiange:addRelatedSkill(os__jiange_draw)
os__xia__xushu:addSkill(os__jiange)

Fk:loadTranslationTable{
  ["os__xia__xushu"] = "侠徐庶",
  ["os__jiange"] = "剑歌",
  [":os__jiange"] = "每回合限一次，你可将一张非基本牌当【杀】使用或打出（无距离与次数限制且不计入次数）。若此时为你的回合外，你摸一张牌。",
  ["os__xiawang"] = "侠望",
  [":os__xiawang"] = "当至你距离不大于1的角色受到黑色牌造成的伤害后，你可对伤害来源使用一张【杀】。若此【杀】造成了伤害，则在【杀】结算后结束当前阶段。",
}]]

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
    local target = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), function(p)
        return p.id
      end), 1, 1, "#os__zhongzuo-ask", self.name)

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

os__jiakui:addSkill(os__zhongzuo)
os__wanlan:addRelatedSkill(os__wanlan_damage)
os__jiakui:addSkill(os__wanlan)

Fk:loadTranslationTable{
  ["os__jiakui"] = "贾逵",
  ["os__zhongzuo"] = "忠佐",
  [":os__zhongzuo"] = "一名角色的结束阶段结束时，若你于本回合内造成或受到过伤害，你可令一名角色摸两张牌，若其已受伤，你摸一张牌。",
  ["os__wanlan"] = "挽澜",
  [":os__wanlan"] = "限定技，当一名角色进入濒死状态时，你可发动此技能，若你有手牌则你弃置所有手牌，令其回复体力至1点，此次濒死结算结束后，你对当前回合角色造成1点伤害。",

  ["#os__zhongzuo-ask"] = "忠佐：你可令一名角色摸两张牌，若其已受伤，你摸一张牌",
}

--[[local os__feiyi = General(extension, "os__feiyi", "shu", 3)

local os__shengxi = fk.CreateTriggerSkill{
  name = "os__shengxi",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and (player.phase == Player.Start or (player.phase == Player.Finish and player:getMark("_os__shengxi_use-turn") > 0 and player:getMark("_os__shengxi_damage-turn") == 0))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      local pile = table.clone(Card.DrawPile)
      table.insertTable(Card.DiscardPile)
      table.insertTable(Card.Void)
      local cids = {getCardByPattern(room, "redistribute", pile)}
      if #cids > 0 then
        room:moveCards({
          ids = cids,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
        })
      end
    else
      local cids = {getCardByPattern(room, "dismantlement,nullification,ex_nihilo")}
      if #cids > 0 then
        room:moveCards({
          ids = cids,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
        })
      end
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.GameStart, fk.PreCardUse, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.GameStart then
      return table.every(player.room:getAlivePlayers(), function(p)
        return p:usedSkillTimes(self.name, Player.HistoryGame) == 0
      end)
    else return player.phase ~= Player.NotActive end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      local cids = table.filter(Fk:getAllCardIds(), function(cid)
        return Fk:getCardById(cid).name == "redistribute" 
      end)
      player.room:moveCards({
        ids = cids,
        toArea = Card.Void,
        proposer = player.id,
      })
    elseif event == fk.PreCardUse then
      player.room:addPlayerMark(player, "_os__shengxi_use-turn", 1)
    else
      player.room:addPlayerMark(player, "_os__shengxi_damage-turn", 1)
    end
  end,
}

local redistributeCardSkill = fk.CreateActiveSkill{
  name = "redistribute_skill",
  min_target_num = 1,
  max_target_num = 2,
  target_filter = function() return true end,
  on_effect = function(self, room, cardEffectEvent)
    local to = room:getPlayerById(cardEffectEvent.to)
    
  end,
}

local redistribute = fk.CreateTrickCard{
  name = "redistribute",
  skill = redistributeCardSkill,
  special_skills = { "recast" },
}

extension_cards:addCards{
  redistribute:clone(Card.Spade, 6),
  redistribute:clone(Card.Club, 6),
  redistribute:clone(Card.Heart, 6),
  redistribute:clone(Card.Diamond, 6),
}

local os__kuanji = fk.CreateTriggerSkill{
  name = "os__kuanji",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player.phase == Player.NotActive and player:hasSkill(self.name) and player:usedSkillTimes(self.name) == 0 then
      local cids = {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.toArea == Card.DiscardPile then
          cids = table.insertTable(table.map(move.moveInfo, function(info)
          return info.cardId end))
        end
      end
      if #cids > 0 then
        self.cost_data = cids
        return true
      end
    end 
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askForChoosePlayers(
      player, table.map(room:getOtherPlayers(player), function(p)
        return p.id
      end), 1, 1, "#os__kuanji-ask", self.name, true)
    if #target > 0 then
      room:fillAG(player, self.cost_data)
      --Not yet
      room:closeAG(player)
      self.cost_data = {target[1], self.cost_data}
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local dummy = Fk:cloneCard'slash'
    dummy:addSubcards(self.cost_data[2])
    player.room:obtainCard(self.cost_data[1], dummy, false, fk.ReasonGive)
  end,
}

os__feiyi:addSkill(os__shengxi)
os__feiyi:addSkill(os__kuanji)

Fk:loadTranslationTable{
  ["os__feiyi"] = "费祎",
  ["os__shengxi"] = "生息",
  [":os__shengxi"] = "准备阶段开始时，你可从游戏外、牌堆或弃牌堆中获得一张【调剂盐梅】。结束阶段开始时，若你于此回合内使用过牌且没有造成过伤害，你可从牌堆中获得一张智囊并摸一张牌。" ..
  "<br></br><font color=\"grey\">#【<b>调剂盐梅</b>】（♠6/♣6/♥6/♦6）<br></br>出牌阶段，对两名手牌数不同的角色使用。手牌较多的目标角色弃置一张牌，手牌较少的目标角色摸一张牌。然后若这两名角色手牌数相同，你可将以此法弃置的牌交给一名角色。<br></br>重铸：出牌阶段，你可将此牌置入弃牌堆，摸一张牌。" ..
  "<br></br>#\"<b>智囊</b>\"<br></br>过河拆桥、无懈可击、无中生有（线下可由面杀玩家自行约定选取三种锦囊）</font>",
  ["os__kuanji"] = "宽济",
  [":os__kuanji"] = "每回合限一次，当你的牌非因使用而置入弃牌堆后，你可令一名其他角色获得其中的任意张牌。",

  ["#os__kuanji-ask"] = "宽济：你可令一名其他角色获得其中的任意张牌。",
}]]

--[[local xiahoushang = General(extension, "xiahoushang", "wei", 4)

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
    local target = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os__tanfeng-ask", self.name)
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
    if not target:isNude() then table.insert(choices, 2, "os__tanfeng_slash") end
    local choice = room:askForChoice(target, choices, self.name, "#os__tanfeng-react::" .. player.id)
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
        local phase_name_table = {
          ["phase_judge"] = 3,
          ["phase_draw"] = 4,
          ["phase_play"] = 5,
          ["phase_discard"] = 6,
          ["phase_finish"] = 7,
        }
        player:skip(phase_name_table[room:askForChoice(target, phase, self.name, "#os__tanfeng-skip::" .. player.id)])
      end
    else
      room:askForViewAsSkill() --Not yet
    end
  end,
}

xiahoushang:addSkill(os__tanfeng)

Fk:loadTranslationTable{
  ["xiahoushang"] = "夏侯尚",
  ["os__tanfeng"] = "探锋",
  [":os__tanfeng"] = "准备阶段开始时，你可弃置一名其他角色区域内的一张牌，然后其可选择一项：1. 受到你造成的1点火焰伤害，其令你跳过一个阶段；2. 将一张牌当做【杀】对你使用。",

  ["#os__tanfeng-ask"] = "探锋：你可选择一名其他角色，弃置其区域内的一张牌",
  ["#os__tanfeng-react"] = "探锋：你可对 %dest 选择一项",
  ["#os__tanfeng-skip"] = "探锋：你令 %dest 跳过本回合的一个阶段",
}]]


local os__godguanyu = General(extension, "os__godguanyu", "god", 4)

local os__wushen = fk.CreateFilterSkill{ --你的红桃手牌视为【杀】
  name = "os__wushen",
  card_filter = function(self, to_select, player)
    return player:hasSkill(self.name) and to_select.suit == Card.Heart --and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand 
  end,
  view_as = function(self, to_select)
    local card = Fk:cloneCard("slash", Card.Heart, to_select.number)
    card.skillName = "os__wushen"
    return card
  end,
}

local os__wushen_buff = fk.CreateTargetModSkill{
  name = "#os__wushen_buff",
  anim_type = "offensive",
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
      room:addPlayerMark(data.from, "@os__nightmare", data.damage) --和描述有点出入…好懒
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
        for _, id in ipairs(targets) do
          local p = room:getPlayerById(id)
          room:loseHp(p, p:getMark("@os__nightmare"), self.name)
        end
      end
    end
  end,
}

os__wushen:addRelatedSkill(os__wushen_buff)
os__wushen:addRelatedSkill(os__wushen_trg)
os__godguanyu:addSkill(os__wushen)
os__godguanyu:addSkill(os__wuhun)


Fk:loadTranslationTable{
  ["os__godguanyu"] = "神关羽",
  ["os__wushen"] = "武神",
  [":os__wushen"] = "锁定技，你的红桃手牌视为【杀】。你使用红桃【杀】无距离和次数限制且额外选择所有有“梦魇”的角色为目标。你于每个阶段内使用的第一张【杀】不能被响应。",
  ["os__wuhun"] = "武魂",
  [":os__wuhun"] = "锁定技，当你受到1点伤害后，伤害来源获得1枚“梦魇”；当你对有“梦魇”的角色造成伤害后，其获得1枚“梦魇”；当你死亡时，你可判定：若结果不为【桃】或【桃园结义】，你选择至少一名有“梦魇”的角色，这些角色失去X点体力（X为其“梦魇”数）。",
  
  ["@os__nightmare"] = "梦魇",
  ["os__wuhun_judge"] = "判定，若结果不为【桃】或【桃园结义】，你选择至少一名有“梦魇”的角色失去X点体力（X为其“梦魇”数）",
  ["#os__wuhun-targets"] = "武魂：选择至少一名有“梦魇”的角色，各失去X点体力（X为其“梦魇”数）",
}

local os_ex__handang = General(extension, "os_ex__handang", "wu", 4)
local os_ex__gongqi = fk.CreateActiveSkill{
  name = "os_ex__gongqi",
  anim_type = "offensive",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player)
    room:setPlayerMark(player, "_os_ex__gongqi-turn", Fk:getCardById(effect.cards[1]).suit)
    if Fk:getCardById(effect.cards[1]).type == Card.TypeEquip then
      local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not p:isNude() end), function(p) return p.id end), 1, 1, "#os_ex__gongqi-ask", self.name)
      if #to > 0 then
        local target = room:getPlayerById(to[1])
        local id = room:askForCardChosen(player, target, "he", self.name)
        room:throwCard({id}, self.name, target, player)
      end
    end
  end,
}
local os_ex__gongqi_attackrange = fk.CreateAttackRangeSkill{
  name = "#os_ex__gongqi_attackrange",
  correct_func = function (self, from, to)
    return from:hasSkill(self.name) and 999 or 0
  end,
}
local os_ex__gongqi_buff = fk.CreateTargetModSkill{
  name = "#os_ex__gongqi_buff",
  anim_type = "offensive",
  residue_func = function(self, player, skill, scope, card)
    return (player:getMark("_os_ex__gongqi-turn") ~= 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase and card and card.suit == player:getMark("_os_ex__gongqi-turn")) and 999 or 0
  end,
}

local os_ex__jiefan = fk.CreateActiveSkill{
  name = "os_ex__jiefan",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) < 1
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(room:getPlayerById(effect.from), "_os_ex__jiefan", target.id)
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if p:inMyAttackRange(target) then
        if #room:askForDiscard(p, 1, 1, true, self.name, true, "crossbow,qinggang_sword,ice_sword,double_swords,blade,spear,axe,halberd,kylin_bow,guding_blade,fan|.", "#os_ex__jiefan-discard::"..target.id) == 0 then --手动…………
          target:drawCards(1, self.name)
        end
      end
    end
  end,
}
local os_ex__jiefan_re = fk.CreateTriggerSkill{
  name = "#os_ex__jiefan_re",
  mute = true,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:getMark("_os_ex__jiefan") == target.id
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("os_ex__jiefan")
    room:notifySkillInvoked(player, "os_ex__jiefan")
    room:setPlayerMark(player, "_os_ex__jiefan", 0)
    player:addSkillUseHistory("os_ex__jiefan", -1)
  end,
}

os_ex__gongqi:addRelatedSkill(os_ex__gongqi_attackrange)
os_ex__gongqi:addRelatedSkill(os_ex__gongqi_buff)
os_ex__handang:addSkill(os_ex__gongqi)
os_ex__jiefan:addRelatedSkill(os_ex__jiefan_re)
os_ex__handang:addSkill(os_ex__jiefan)

Fk:loadTranslationTable{
  ["os_ex__handang"] = "界韩当",
  ["os_ex__gongqi"] = "弓骑",
  [":os_ex__gongqi"] = "你的攻击范围无限。出牌阶段限一次，你可弃置一张牌，你于此阶段内使用与弃置的牌花色相同的【杀】无次数限制。若弃置的为装备牌，你可弃置一名其他角色的一张牌。",
  ["os_ex__jiefan"] = "解烦",
  [":os_ex__jiefan"] = "限定技，出牌阶段，你可选择一名角色，令能攻击到该角色的所有角色选择一项：1.弃置一张武器牌；2.令该角色摸一张牌。当你上一次发动〖解烦〗指定的角色进入濒死状态时，此技能视为未发动过。",
  
  ["#os_ex__gongqi-ask"] = "弓骑：你可弃置一名其他角色的一张牌",
  ["#os_ex__jiefan-discard"] = "解烦：弃置一张武器牌，否则 %dest 摸一张牌",
}

local os__zangba = General(extension, "os__zangba", "wei", 4)

local os__hanyu = fk.CreateTriggerSkill{
  name = "os__hanyu",
  events = {fk.GameStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local cards = {}
    local room = player.room
    table.insert(cards, getCardByPattern(room, ".|.|.|.|.|basic"))
    table.insert(cards, getCardByPattern(room, ".|.|.|.|.|trick"))
    table.insert(cards, getCardByPattern(room, ".|.|.|.|.|equip"))
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}

local os__hengjiang = fk.CreateTriggerSkill{
  name = "os__hengjiang",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and player.phase == Player.Play and data.firstTarget and #AimGroup:getAllTargets(data.tos) == 1 and (data.card.type == Card.TypeBasic or (data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick))
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
    room:doIndicate(player.id, targets)
    table.forEach(targets, function(pid)
      AimGroup:addTargets(room, data, pid)
    end)
    room:setPlayerMark(player, "_os__hengjiang", data.card.id)
  end,
}

local os__hengjiang_judge = fk.CreateTriggerSkill{
  name = "#os__hengjiang_judge",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return data.card and data.card.id == player:getMark("_os__hengjiang")
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getMark("_os__hengjiang_count"), self.name)
    player.room:setPlayerMark(player, "_os__hengjiang", 0)
    player.room:setPlayerMark(player, "_os__hengjiang_count", 0)
  end,

  refresh_events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_refresh = function(self, event, target, player, data)
    return ((event == fk.CardUseFinished and data.toCard and data.toCard.id == player:getMark("_os__hengjiang")) or (event == fk.CardRespondFinished and data.responseToEvent.card.id == player:getMark("_os__hengjiang")) ) and
      data.responseToEvent and data.responseToEvent.from == player.id and target:getMark("_os__hengjiang_counted-phase") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__hengjiang_count")
    player.room:addPlayerMark(target, "_os__hengjiang_counted-phase")
  end,
}

os__zangba:addSkill(os__hanyu)
os__hengjiang:addRelatedSkill(os__hengjiang_judge)
os__zangba:addSkill(os__hengjiang)

Fk:loadTranslationTable{
  ["os__zangba"] = "臧霸",
  ["os__hanyu"] = "捍御",
  [":os__hanyu"] = "锁定技，游戏开始时，你从牌堆获得不同类别的牌各一张。",
  ["os__hengjiang"] = "横江",
  [":os__hengjiang"] = "出牌阶段限一次，你使用基本牌或普通锦囊牌指定唯一目标后，你可将此牌的目标改为攻击范围内的所有角色，此牌结算结束后你摸X张牌（X为响应此牌的角色数）。",
  ["#os__hengjiang_judge"] = "横江",
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
      for _, p in ipairs(room:getAlivePlayers()) do
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

os__equan:addRelatedSkill(os__equan_invalidity)
duosidawang:addSkill(os__equan)
duosidawang:addSkill(os__manji)

Fk:loadTranslationTable{
  ["duosidawang"] = "朵思大王",
  ["os__equan"] = "恶泉",
  [":os__equan"] = "锁定技，当一名角色于你回合内受到伤害后，其获得等同于伤害值的“毒”。准备阶段，所有有“毒”的角色失去X点体力并弃所有“毒”（X为其拥有的“毒”数)，以此法进入濒死状态的角色本回合技能失效。",
  ["os__manji"] = "蛮汲",
  [":os__manji"] = "锁定技，当其他角色失去体力后，若你的体力值不大于其，你回复1点体力；若你的体力值不小于其，你摸一张牌。",

  ["@os__poison"] = "毒",
  ["@@os__equan-turn"] = "恶泉",
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
  interaction = UI.ComboBox { choices = {"slash", "jink", "peach", "analeptic", "duel", "savage_assault", "archery_attack", "fire_attack", "dismantlement", "snatch", "collateral", "nullification", "ex_nihilo", "amazing_grace", "god_salvation", "iron_chain"} },
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
    local card = {getCardByPattern(room, name)}
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}

local os__chayi = fk.CreateTriggerSkill{
  name = "os__chayi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askForChoosePlayers(
      player,
      table.map(room:getOtherPlayers(player), function(p)
        return p.id
      end),
      1,
      1,
      "#os__chayi-ask",
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
    local target = room:getPlayerById(self.cost_data)
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

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return player == target and data.to == Player.NotActive and player:getMark("_os__chayi") > 0
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
      room:setPlayerMark(player, "@os__chayi_discard", 0)
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
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "_os__chayi_discarded", 1)
    if not player:isNude() then
      room:askForDiscard(player, 1, 1, true, self.name, false, nil, "#os__chayi-discard")
    end
    room:setPlayerMark(player, "@@os__chayi_discard", 0)
  end,
}

os__chenzhen:addSkill(os__muyue)
os__chayi:addRelatedSkill(os__chayi_using)
os__chenzhen:addSkill(os__chayi)

Fk:loadTranslationTable{
  ["os__chenzhen"] = "陈震",
  ["os__muyue"] = "睦约",
  [":os__muyue"] = "出牌阶段限一次，你选择一个基本牌或普通锦囊牌的牌名，弃置一张牌并选择一名角色，令其从牌堆中获得该牌名的牌。若你弃置的牌的牌名与该牌名相同，你下次发动此技能无需弃牌。",
  ["os__chayi"] = "察异",
  [":os__chayi"] = "结束阶段开始时，你可令一名其他角色选择一项：1. 展示其手牌；2. 其下一次使用牌时弃置一张牌。其下回合结束前，若其手牌数与你选择该角色时不同，则该角色执行另一项。",

  ["#os__chayi-ask"] = "你可对一名其他角色发动“察异”",
  ["#os__chayi-choice"] = "察异：你的下回合结束前，若你的手牌数与此时不同，你执行此时选择的另一项",
  ["os__chayi_show"] = "展示手牌",
  ["os__chayi_discard"] = "下一次使用牌时弃置一张牌",
  ["@os__chayi_show"] = "察异 展示",
  ["@os__chayi_discard"] = "察异 弃牌",
  ["#os__chayi-discard"] = "察异：你使用了一张牌，须弃置一张牌",
  ["@@os__chayi_discard"] = "察异 弃牌",
  ["#os__chayi_using"] = "察异",
}

--[[local os__bianfuren = General(extension, "os__bianfuren", "wei", 3, 3, General.Female)

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
        local use = room:askForUseCard(player, card.name, card.name .. "|.|.|.|.|.|" .. cids[1], "#os__wanwei-use:::" .. card.name, false) --八卦阵的pattern……
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
    local num = player:getHandcardNum() - player:getMaxCards()
    local cids = effect.cards
    room:moveCards({
      ids = cids,
      from = player.id,
      fromArea = Player.Hand,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      moveVisible = false,
      proposer = player.id,
      skillName = self.name,
    })
    room:askForGuanxing(player, cids)
    if num > 0 then
      room:addPlayerMark(player, "@os__yuejian", 1)
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

local os__yuejian_max =  fk.CreateMaxCardsSkill{
  name = "#os__yuejian_max",
  correct_func = function(self, player)
    return player:getMark("@os__yuejian")
  end,
}

os__bianfuren:addSkill(os__wanwei)
os__yuejian:addRelatedSkill(os__yuejian_max)
os__bianfuren:addSkill(os__yuejian)

Fk:loadTranslationTable{
  ["os__bianfuren"] = "卞夫人",
  ["os__wanwei"] = "挽危",
  [":os__wanwei"] = "每回合限一次，当体力值最低的角色受到伤害时，若该角色不为你，你可以防止此伤害，然后失去1点体力；若该角色为你或你的体力上限全场最高，则你可在本回合结束阶段开始时获得牌堆底牌并展示之（若此牌能使用，则你使用之）。",
  ["os__yuejian"] = "约俭",
  [":os__yuejian"] = "出牌阶段限一次，你可以将X张牌置于牌堆顶或牌堆底（X为你手牌数减去手牌上限的差且至少为1），若因此失去的牌数不小于：1，你的手牌上限+1；2，你回复1点体力；3，你增加1点体力上限。",

  ["#os__wanwei-ask"] = "你可选择是否发动“挽危”",
  ["os__wanwei_defend"] = "防止此伤害，你失去1点体力",
  ["os__wanwei_get"] = "本回合结束阶段开始时，获得牌堆底牌并展示之，若能使用则使用之",
  ["os__wanwei_both"] = "防止此伤害，并于本回合结束阶段开始时，获得牌堆底牌",
  ["#os__wanwei-use"] = "挽危：请使用获得的【%arg】",
  ["@os__yuejian"] = "约俭",
}]]

local os__himiko = General(extension, "os__himiko", "qun", 3, 3, General.Female)

local os__zongkui = fk.CreateTriggerSkill{
  name = "os__zongkui",
  anim_type = "control",
  events = {fk.RoundStart, fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.TurnStart and target ~= player then return false end
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
    if event == fk.TurnStart then
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
    player.room:setPlayerMark(player.room:getPlayerById(self.cost_data), "@@os__puppet", 1)
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
      player:getMark("@os__guju") > 6 and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
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
      room:setPlayerMark(p, "@@os__puppet", 1)
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
  events = {fk.TargetConfirming, fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and #AimGroup:getAllTargets(data.tos) == 1 and ((event == fk.TargetConfirming and player.room:getPlayerById(data.from):getMark("@@os__puppet") > 0) or event == fk.TargetSpecifying) 
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
      room:setPlayerMark(room:getPlayerById(data.from), "@@os__puppet", 0)
    else
      room:doIndicate(player.id, self.cost_data)
      table.forEach(self.cost_data, function(pid) 
        TargetGroup:pushTargets(data.targetGroup, pid)
        room:setPlayerMark(room:getPlayerById(pid), "@@os__puppet", 0)
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
  [":os__zongkui"] = "回合开始后，你可指定一名没有“傀”的其他角色，令其获得一枚“傀”。每轮开始时，体力值最小且没有“傀”的一名其他角色获得一枚“傀”。", --关于轮次开始的问题……
  ["os__guju"] = "骨疽",
  [":os__guju"] = "锁定技，当有“傀”的角色受到伤害后，你摸一张牌。",
  ["os__baijia"] = "拜假",
  [":os__baijia"] = "觉醒技，准备阶段开始时，若你因〖骨疽〗获得牌不小于7张，则你加1点体力上限，回复1点体力，然后令所有未拥有“傀”的其他角色获得一枚“傀”，最后失去〖骨疽〗，并获得〖蚕食〗。",
  ["os__bingzhao"] = "秉诏",
  [":os__bingzhao"] = "主公技，游戏开始时，你选择一个其他势力，该势力有“傀”的角色受到伤害后，可令你因〖骨疽〗额外摸一张牌。",
  ["os__canshi"] = "蚕食",
  [":os__canshi"] = "当一名角色使用基本牌或普通锦囊牌指定你为唯一目标时，若其有“傀”，你可取消之，然后其弃“傀”。你使用基本牌或普通锦囊牌仅指定一名角色为目标时，你可多指定任意名带有“傀”的角色为目标，然后这些角色弃“傀”。",

  ["@@os__puppet"] = "傀",
  ["#os__zongkui-ask"] = "纵傀：选择一名其他角色，令其获得一枚“傀”",
  ["os__bingzhao_draw"] = "令其额外摸一张牌",
  ["@os__guju"] = "骨疽",
  ["#os__bingzhao-choose"] = "秉诏：选择一个其他势力，该势力有“傀”的角色受到伤害后，可令你因〖骨疽〗额外摸一张牌",
  ["@os__bingzhao"] = "秉诏",
  ["#os__canshi"] = "蚕食：你可取消【%arg】的目标，然后 %dest 弃“傀”",
  ["#os__canshi-targets"] = "蚕食：你可多指定任意名带有“傀”的角色为目标，然后这些角色弃“傀”",
}

local os__jiling = General(extension, "os__jiling", "qun", 4)

local os__shuangren = fk.CreateTriggerSkill{
  name = "os__shuangren",
  anim_type = "offensive",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.phase == Player.Play and not player:isKongcheng() and not table.every(player.room:getOtherPlayers(player), function(p)
      return p:isKongcheng()
    end) and (event == fk.EventPhaseStart or (player:getMark("_os__shuangren_invalid-turn") == 0 and player:getMark("_os__shuangren-turn") == 0))
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
    room:setPlayerMark(player, "_os__shuangren-turn", 1)
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
          if player.dead then return false end
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
      for _, target in ipairs(player.room:getAlivePlayers()) do
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

local os_ex__chengpu = General(extension, "os_ex__chengpu", "wu", 4)

local os_ex__lihuo = fk.CreateTriggerSkill{
  name = "os_ex__lihuo",
  events = {fk.AfterCardUseDeclared, fk.TargetSpecified},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self.name)) then return false end
    if event == fk.AfterCardUseDeclared then return data.card.name == "slash"
    else return data.card.name == "fire__slash" end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return player.room:askForSkillInvoke(player, self.name)
    else
      local availableTargets = table.map(table.filter(player.room:getOtherPlayers(player), function(p)
        return not table.contains(TargetGroup:getRealTargets(data.tos), p.id) and data.card.skill:getDistanceLimit(p, data.card) + player:getAttackRange() >= player:distanceTo(p) and not player:isProhibited(p, data.card)
      end), function(p)
        return p.id 
      end)
      if #availableTargets == 0 then return false end
      local targets = player.room:askForChoosePlayers(player, availableTargets, 1, 1, "#os_ex__lihuo-targets", self.name, true)
      if #targets > 0 then
        self.cost_data = targets[1]
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then  
      local fireSlash = Fk:cloneCard("fire__slash")
      fireSlash.skillName = self.name
      fireSlash:addSubcard(data.card)
      data.card = fireSlash
      player.room:setPlayerMark(player, "_os_ex__lihuo", tostring(data.card.id)) --0!
    else
      TargetGroup:pushTargets(data.targetGroup, self.cost_data)
    end
  end,
}

local os_ex__lihuo_judge = fk.CreateTriggerSkill{
  name = "#os_ex__lihuo_judge",
  events = {fk.CardUseFinished},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("_os_ex__lihuo") == tostring(data.card.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("_os_ex__lihuo_dying") > 0 then
      room:loseHp(player, 1, self.name)
      room:setPlayerMark(player, "_os_ex__lihuo_dying", 0)
    end
    room:setPlayerMark(player, "_os_ex__lihuo",0)
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("_os_ex__lihuo") ~= 0 and target ~= player and data.damage and data.damage.card and player:getMark("_os_ex__lihuo") == tostring(data.damage.card.id)
  end,
  on_refresh = function(elf, event, target, player, data)
    player.room:addPlayerMark(player, "_os_ex__lihuo_dying")
  end,
}

local os_ex__chunlao = fk.CreateTriggerSkill{
  name = "os_ex__chunlao",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and table.every(player.room:getAlivePlayers(), function(p)
        return #p:getPile("os__dense_alcohol") == 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local availableTargets = table.map(
      table.filter(room:getAlivePlayers(), function(p)
        return not p:isAllNude()
      end),
      function(p)
        return p.id
      end
    )
    if #availableTargets == 0 then return false end
    local target = room:askForChoosePlayers(player, availableTargets, 1, 1, "#os_ex__chunlao-ask", self.name)
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
    target:addToPile("os__dense_alcohol", cid, true, self.name)
  end,
}

local os_ex__chunlao_do = fk.CreateTriggerSkill{
  name = "#os_ex__chunlao_do",
  anim_type = "offensive",
  mute = true,
  events = {fk.CardUsing, fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardUsing then return target == player and #player:getPile("os__dense_alcohol") > 0 and data.card.trueName == "slash"
    else return player:hasSkill("os_ex__chunlao") and #target:getPile("os__dense_alcohol") > 0 end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      local availableTargets = table.map(
        table.filter(room:getOtherPlayers(player), function(p)
          return p:hasSkill("os_ex__chunlao")
        end),
        function(p)
          return p.id
        end
      )
      if #availableTargets == 0 then return false
      elseif #availableTargets == 1 then
        local cid = room:askForCard(player, 1, 1, true, self.name, true, nil, "#os_ex__chunlao-give:" .. availableTargets[1])
        if #cid > 0 then
          self.cost_data = {availableTargets[1], cid[1]}
          return true
        end
      else
        local plist, cid = room:askForChooseCardAndPlayers(player, availableTargets, 1, 1, nil, "#os_ex__chunlao-choose_give", self.name, true)
        if #plist > 0 then
          self.cost_data = {plist[1], cid}
          return true
        end
      end
    else
      return room:askForSkillInvoke(player, self.name)
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("os_ex__chunlao", "offensive")
    if event == fk.CardUsing then
      local chengpu = room:getPlayerById(self.cost_data[1])
      room:notifySkillInvoked(chengpu, "os_ex__chunlao")
      local cid = self.cost_data[2]
      room:obtainCard(chengpu, cid, false, fk.ReasonGive)
      data.additionalDamage = (data.additionalDamage or 0) + 1
    else
      room:notifySkillInvoked(player, "os_ex__chunlao")
      room:moveCards({
        ids = target:getPile("os__dense_alcohol"),
        from = target.id,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        proposer = player.id,
        skillName = self.name,
      })
      player:drawCards(1, self.name)
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    end
  end,
}

os_ex__lihuo:addRelatedSkill(os_ex__lihuo_judge)
os_ex__chengpu:addSkill(os_ex__lihuo)
os_ex__chunlao:addRelatedSkill(os_ex__chunlao_do)
os_ex__chengpu:addSkill(os_ex__chunlao)

Fk:loadTranslationTable{
  ["os_ex__chengpu"] = "界程普",
  ["os_ex__lihuo"] = "疠火",
  [":os_ex__lihuo"] = "你使用普【杀】可改为火【杀】，当此【杀】结算结束后，若此【杀】令其他角色进入过濒死状态，你失去1点体力。你使用火【杀】指定目标后，可多选择一个目标。",
  ["os_ex__chunlao"] = "醇醪",
  [":os_ex__chunlao"] = "准备阶段开始时，若场上没有“醇”，你可选择一名角色，将其区域内的一张牌置于其武将牌上，称为“醇”。有“醇”的角色使用【杀】时，可交给你一张牌令此【杀】伤害值基数+1；其进入濒死状态时，你可将一张“醇”置入弃牌堆并摸一张牌，然后其回复1点体力。",

  ["#os_ex__lihuo-targets"] = "疠火：你可选择一名角色，令其也成为此火【杀】的目标",
  ["#os_ex__lihuo_judge"] = "疠火",
  ["os__dense_alcohol"] = "醇",
  ["#os_ex__chunlao-ask"] = "醇醪：你可选择一名角色，将其区域内的一张牌置于其武将牌上，称为“醇”",
  ["#os_ex__chunlao_do"] = "醇醪",
  ["#os_ex__chunlao-give"] = "醇醪：你可交给 %src 一张牌，令此【杀】伤害值基数+1",
  ["#os_ex__chunlao-choose_give"] = "醇醪：你可交给一名有“醇醪”的角色一张牌，令此【杀】伤害值基数+1",
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
    room:obtainCard(pid, cid, false, fk.ReasonGive)
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
  [":os__fupan"] = "当你造成或受到伤害后，你可摸X张牌（X为伤害值），然后交给一名其他角色一张牌。若你未以此法交给过该角色牌，你摸两张牌；否则，你可对该角色造成1点伤害，然后你不能再以此法交给其牌。",
  
  ["#os__fupan-give"] = "复叛：交给一名其他角色一张牌",
  ["os__fupan_dmg"] = "对其造成1点伤害，然后不能再以此法交给其牌",
}

--[[local yufuluo = General(extension, "yufuluo", "qun", 6)

local os__jiekuang = fk.CreateTriggerSkill{
  name = "os__jiekuang",
  anim_type = "defensive",
  events = {fk.TargetConfirmed, fk.CardUseFinished},    
  can_trigger = function(self, event, target, player, data)
    if event == fk.TargetConfirmed then
      return player:hasSkill(self.name) and target.hp < player.hp and player:usedSkillTimes(self.name) < 1 and data.from ~= player.id and #AimGroup:getAllTargets(data.tos) == 1 
      and (data.card.type == Card.TypeBasic or (data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick)) and table.every(player.room:getAlivePlayers(), function(p)
        return p.hp > 0 --旧周泰？
      end)
    else
      return player:getMark("_os__jiekuang") ~= 0 and data.card and tostring(data.card.id) == player:getMark("_os__jiekuang") and not player:prohibitUse(data.card) and not player:isProhibited(target, data.card)
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
      room:setPlayerMark(player, "_os__jiekuang", tostring(data.card.id))
      AimGroup:cancelTarget(data, data.to)
      AimGroup:addTargets(room, data, player.id) --合法性……
    else
      room:useVirtualCard(data.card.name, nil, player, target, self.name)
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("_os__jiekuang") ~= 0 and data.card and tostring(data.card.id) == player:getMark("_os__jiekuang")
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "_os__jiekuang", 0)
  end,
}

local os__neirao = fk.CreateTriggerSkill{
  name = "os__neirao",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player.hp + player.maxHp < 10 and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-os__jiekuang", nil)
    local num = #player:getCardIds(Player.Equip) + #player:getCardIds(Player.Hand)
    player:throwAllCards("he")
    local pile = table.clone(room.draw_pile)
    table.insertTable(pile, room.discard_pile)
    local cards = {}
    for i = 1, num, 1 do
      table.insert(cards, getCardByPattern(room, "slash", pile))
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
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
    return Fk:getCardById(to_select).trueName == "slash"
  end,
}
local os__luanlue_prohibit = fk.CreateProhibitSkill{
  name = "#os__luanlue_prohibit",
  is_prohibited = function(self, from, to, card)
    return to:getMark("_os__luanlue-turn") > 0 and card.name == "snatch"
  end,
}]]

Fk:loadTranslationTable{
  ["yufuluo"] = "于夫罗",
  ["os__jiekuang"] = "竭匡",
  [":os__jiekuang"] = "每回合限一次，当一名体力值小于你的角色成为其他角色使用基本牌或普通锦囊牌的唯一目标后，若没有角色处于濒死状态，你可失去1点体力或减少1点体力上限，然后你代替该角色成为此牌目标。当此牌结算结束后，若此牌未造成伤害且此牌的使用者可成为此牌的合法目标，则视为你对此牌的使用者使用一张同名牌。",
  ["os__neirao"] = "内扰",
  [":os__neirao"] = "觉醒技，准备阶段开始时，若你的体力值与体力上限之和不大于9，你失去〖竭匡〗，弃置全部牌并从牌堆或弃牌堆中获得等量的【杀】，然后获得技能〖乱掠〗。",
  ["os__luanlue"] = "乱掠",
  [":os__luanlue"] = "出牌阶段，你可以将X张【杀】当做【顺手牵羊】对一名本阶段未被指定为【顺手牵羊】目标的角色使用（X为你以此法使用过【顺手牵羊】的次数）。你使用的【顺手牵羊】无法被响应。",

  ["#os__jiekuang"] = "竭匡：你可失去1点体力或减少1点体力上限，代替 %src 成为【%arg】的目标",
  ["@os__luanlue"] = "乱掠",
}

Fk:loadTranslationTable{
  ["os_ex__zhangfei"] = "界张飞",
  ["os_ex__paoxiao"] = "咆哮",
  [":os_ex__paoxiao"] = "锁定技，你使用【杀】无次数限制；若你于当前阶段使用过【杀】，则你于此阶段使用【杀】无距离限制。",
  ["os_ex__xuhe"] = "虚吓",
  [":os_ex__xuhe"] = "当你使用的【杀】被一名角色的【闪】抵消后，你可弃置一张牌，令其选择一项：1. 你对其造成1点伤害；2. 本回合你使用的下一张牌对其造成的伤害+2。",

  ["caozhao"] = "曹肇",
  
  ["os__puyangxing"] = "濮阳兴",
	["os__zhengjian"] = "征建",
	[":os__zhengjian"] = "游戏开始时，你选择一项：1.使用过非基本牌；2.获得过牌。其他角色的出牌阶段结束时，若其此阶段未完成“征建”要求的选项，其交给你一张牌，然后你可变更〖征建〗的选项。",
	["os__zhongchi"] = "众斥",
	[":os__zhongchi"] = "锁定技，当累计有X名角色因〖征建〗交给你牌后（X为游戏人数的一半，向上取整），你本局游戏受到【杀】的伤害+1，并将〖征建〗中的“其交给你一张牌”修改为“你可对其造成1点伤害”。",
}
return {extension}