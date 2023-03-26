local extension = Package("overseas")

Fk:loadTranslationTable{
  ["overseas"] = "海外服",
  ["os"] = "海外",
}

local fengxi = General(extension, "fengxi", "shu", 4)
local os__qingkou = fk.CreateTriggerSkill{
  name = "os__qingkou",
  anim_type = "offensive",
  events = {fk.EventPhaseStart, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start
    else
      return data.card.skillName == self.name and player:getMark("_os__qingkou_damage") > 0 --不能用 target == player
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      local target = room:askForChoosePlayers(
        player,
        table.map(room:getOtherPlayers(player), function(p)
          return p.id
        end),
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
      local room = player.room
      local duel = Fk:cloneCard("duel")
      duel.skillName = self.name
      local new_use = {} ---@type CardUseStruct
      new_use.from = player.id
      new_use.tos = { {room:getPlayerById(self.cost_data).id} }
      new_use.card = duel
      room:useCard(new_use)
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
  events = {fk.EventPhaseStart, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return target == player and player:hasSkill(self.name) and
       player.phase == Player.Finish and player.hp > 0
    else
      if target == player and player:hasSkill(self.name) and
       data.card and data.card.skillName == self.name then
        local basic_types = 0
        local basic_cards = {"peach", "slash", "jink", "analeptic"}
        for _, b in ipairs(basic_cards) do
          if player:usedCardTimes(b, Player.HistoryTurn) > 0 then
            basic_types = basic_types + 1
          end
        end
        return basic_types > 1
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      local target = room:askForChoosePlayers(
        player,
        table.map(
          table.filter(room:getOtherPlayers(player), function(p)
            return p
          end),
          function(p)
            return p.id
          end
        ),
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
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      room:loseHp(player, 1, self.name)
      local slash = Fk:cloneCard("slash")
      slash.skillName = self.name
      local new_use = {} ---@type CardUseStruct
      new_use.from = player.id
      new_use.tos = { {room:getPlayerById(self.cost_data).id} }
      new_use.card = slash
      room:useCard(new_use)
    else
      data.damage = data.damage + 1
    end
  end,
}
zhangnan:addSkill(os__fenwu)

Fk:loadTranslationTable{
  ["zhangnan"] = "张南",
  ["os__fenwu"] = "奋武",
  [":os__fenwu"] = "结束阶段，你可失去1点体力，视为你对一名其他角色使用一张（无距离限制的）【杀】。若本回合你使用过超过一种基本牌，此【杀】伤害+1。",
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
      if player:hasSkill(self.name) and data.card.trueName == "slash" and
       player:getMark("_os__cuijin_invoked") > 0 then
        player.room:setPlayerMark(player, "_os__cuijin_invoked", 0)
        return target:getMark("_os__cuijin_achieved") < 1 
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUsing then
      local card = player.room:askForCard(player, 1, 1, true, self.name, true, ".")
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
      room:throwCard(self.cost_data, self.name, player, player)
      room:addPlayerMark(player, "_os__cuijin_invoked", 1)
      room:setPlayerMark(target, "_os__cuijin_achieved", 0) --很蠢
    else
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,

  refresh_events = {fk.Damage, fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      return target == player and data.card and data.card.trueName == "slash" and
      #table.filter(player.room:getAlivePlayers(), function(p)
        return p:getMark("_os__cuijin_invoked") > 0
      end) > 0
    else
      return player == target and 
      #table.filter(player.room:getAlivePlayers(), function(p)
        return p:getMark("_os__cuijin_invoked") > 0
      end) > 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      player.room:addPlayerMark(player, "_os__cuijin_achieved", 1)
    else
      local room = player.room
      data.damage = data.damage + #table.filter(room:getAlivePlayers(), function(p)
        return p:getMark("_os__cuijin_invoked") > 0
      end)
      for _, p in ipairs(room:getAlivePlayers()) do
        room:setPlayerMark(p, "_os__cuijin_invoked", 0)
      end
    end
  end,
}
yuejiu:addSkill(os__cuijin)

Fk:loadTranslationTable{
  ["yuejiu"] = "乐就",
	["os__cuijin"] = "催进",
	[":os__cuijin"] = "当你或攻击范围内的角色使用【杀】时，你可弃置一张牌，令此【杀】伤害+1。此【杀】结算后，若此【杀】未造成伤害，你对此【杀】的使用者造成1点伤害。",
}

local os__niujin = General(extension, "os__niujin", "wei", 4)
local os__cuorui = fk.CreateTriggerSkill{
  name = "os__cuorui",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and
     player.phase == Player.Start and player:usedSkillTimes(self.name, Player.HistoryGame) <= player:getMark("_os__cuorui_available") and 
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
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return data.damage and data.damage.from and player:hasSkill(self.name) and data.damage.from == player 
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if room:askForChoice(player, {"lw_draw2", "plus_os__cuorui"}, self.name) == "draw" then
      player:drawCards(2, self.name)
    else
      --player:addSkillUseHistory("os__cuorui", -1)
      room:addPlayerMark(player, "_os__cuorui_available", 1)
    end
  end,
}
os__niujin:addSkill(os__cuorui)
os__niujin:addSkill(os__liewei)

Fk:loadTranslationTable{
  ["os__niujin"] = "牛金",
	["os__cuorui"] = "挫锐",
	[":os__cuorui"] = "限定技，准备阶段开始时，你可将手牌摸至X张（X为场上最大的手牌数，至多摸五张），跳过此回合的判定阶段。若你发动过〖挫锐〗，你可选择一名其他角色，对其造成1点伤害。",
	["os__liewei"] = "裂围",
	[":os__liewei"] = "锁定技，当一名角色死亡时，若其是你杀死的，你选择：1.摸两张牌；2.令〖挫锐〗于此局游戏内的发动次数上限+1。",	

  ["lw_draw2"] = "摸两张牌",
  ["plus_os__cuorui"] = "令〖挫锐〗于此局游戏内的发动次数上限+1",
  ["#os__cuorui-target"] = "挫锐：你可对一名其他角色造成1点伤害",
}

local os__chenwudongxi = General(extension, "os__chenwudongxi", "wu", 4)
local os__yilie = fk.CreateTriggerSkill{
  name = "os__yilie",
  anim_type = "offensive",
  events = {fk.EventPhaseStart, fk.CardUseFinished, fk.TargetSpecified},    
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
     return player == target and player:hasSkill(self.name) and
     player.phase == Player.Play
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
        room:loseHp(player, 1, self.name)
        room:setPlayerMark(player, "@os__yilie", "yl_times_draw")
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
    if not player.chained and room:askForChoice(player, {"beishui_os__fenming", "Cancel"}, self.name) == "beishui_os__fenming" then 
      player:setChainState(true)
      if not target:isNude() then room:askForDiscard(target, 1, 1, true, self.name, false) end
      target:setChainState(true)
    else
      if target:isNude() or #room:askForDiscard(target, 1, 1, true, self.name, not target.chained) == 0 then --如果不能弃牌，或者可以弃牌但不弃牌（但如果处于连环状态则必须弃牌）
        target:setChainState(true)
      end
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
  [":os__fenming"] = "准备阶段，你可选择一名角色，令其选择：1.弃置一张牌；2. 横置；背水：你横置。",

  ["os__yilie_times"] = "使用【杀】的次数上限+1", 
  ["os__yilie_draw"] = "当你使用的【杀】指定处于连环状态的角色为目标后，或被【闪】抵消后，摸一张牌", 
  ["@os__yilie"] = "毅烈",
  ["yl_times_draw"] = "摸牌 多出杀",
  ["yl_times"] = "多出杀",
  ["yl_draw"] = "摸牌",

  ["beishui_os__yilie"] = "背水：你失去1点体力",
  ["#os__fenming-ask"] = "奋命：你可选择一名角色，令其选择：1.弃置一张牌；2. 横置；背水：你横置",
  ["beishui_os__fenming"] = "背水：你横置",
}

local liufuren = General:new(extension, "liufuren", "qun", 3, 3, General.Female)
local os__zhuidu = fk.CreateActiveSkill{
  name = "os__zhuidu",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) < 1
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):isWounded()
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if target.gender == General.Female and not player:isNude() and room:askForChoice(player, {"beishui_os__zhuidu", "Cancel"}, self.name) ~= "Cancel" then
      room:askForDiscard(player, 1, 1, true, self.name, false)
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
      if #target:getCardIds(Player.Equip) > 0 then
        local card = room:askForCardChosen(target, target, "e", self.name)
        room:throwCard(card, self.name, target, target)
      end
    else
      local choices = {"os__zhuidu_damage"}
      if #target:getCardIds(Player.Equip) > 0 then table.insert(choices, "os__zhuidu_equip") end
      if room:askForChoice(target, choices, self.name) == "os__zhuidu_equip" then
        local card = room:askForCardChosen(target, target, "e", self.name)
        room:throwCard(card, self.name, target, target)
      else
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}

local os__shigong = fk.CreateTriggerSkill{
  name = "os__shigong",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and
     player.phase == Player.NotActive and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
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
  [":os__zhuidu"] = "阶段技，你可选择一名受伤的其他角色并选择一项：1.你对其造成1点伤害；2.弃置装备区的一张牌；若其为女性角色，则你可背水：弃置一张牌。",
  ["os__shigong"] = "示恭",
  [":os__shigong"] = "限定技，当你回合外进入濒死状态时，你可令当前回合者选择一项：1. 增加1点体力上限，回复1点体力，摸一张牌，令你体力回复至体力上限；2. 弃置X张手牌（X为其当前体力值），令你体力回复至1点。",

  ["beishui_os__zhuidu"] = "背水：你弃置一张牌",
  ["os__zhuidu_damage"] = "受到1点伤害",
  ["os__zhuidu_equip"] = "弃置装备区的一张牌",
  ["os__shigong_max"] = "令其体力回复至体力上限",
  ["os__shigong_dis"] = "令其体力回复至1点",
}

local os__dengzhi = General(extension, "os__dengzhi", "shu", 3)
local os__jimeng = fk.CreateActiveSkill{
  name = "os__jimeng",
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) < 1
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

    local c = room:askForCard(player, 1, 1, true, self.name, false)[1]
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
    local c = room:askForCard(room:getPlayerById(self.cost_data), 1, 1, true, self.name, false)[1]
    room:obtainCard(player, c, false, fk.ReasonGive)
  end,
}
os__dengzhi:addSkill(os__jimeng)
os__dengzhi:addSkill(os__shuaiyan)

Fk:loadTranslationTable{
  ["os__dengzhi"] = "邓芝",
  ["os__jimeng"] = "急盟",
  [":os__jimeng"] = "阶段技，你可以获得一名其他角色区域内的一张牌，然后交给其一张牌。若其体力值不小于你，你摸一张牌。",
  ["os__shuaiyan"] = "率言",
  [":os__shuaiyan"] = "弃牌阶段开始时，若你的手牌数大于1，你可以展示所有手牌，令一名其他角色交给你一张牌。",

  ["#os__shuaiyan-ask"] = "率言：你可展示所有手牌，选择一名其他角色，令其交给你一张牌",
}

local os__sp_yujin = General(extension, "os__sp_yujin", "qun", 4)
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
    end), 1, 1, nil, prompt, self.name)
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
    local use = room:askForUseCard(target, "slash", "slash|.|heart,diamond", "#os__zhenjun_slash", true) --exppattern没有black，没有^。另外，丈八颜色判断有问题，贯石斧可以弃置自己。
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
os__sp_yujin:addSkill(os__zhenjun)

Fk:loadTranslationTable{
  ["os__sp_yujin"] = "SP于禁",
  ["os__zhenjun"] = "镇军",
  [":os__zhenjun"] = "出牌阶段开始时，你可以交给一名其他角色一张牌，令其使用一张非黑色的【杀】：若其执行，则此【杀】结算后你摸一张牌，若此【杀】造成过伤害，你额外摸伤害值数张牌；若其不执行，则你可对其或其攻击范围内的一名角色造成1点伤害。",

  ["#os__zhenjun-target"] = "镇军：你可选择一张牌，交给一名其他角色",
  ["#os__zhenjun_slash"] = "镇军：请使用一张非黑色的【杀】",
  ["#os__zhenjun-damage"] = "镇军：你可对 %dest 或其攻击范围内的一名角色造成1点伤害",
}

local os__jiachong = General(extension, "os__jiachong", "qun", 3)

local os__beini = fk.CreateActiveSkill{
  name = "os__beini",
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) < 1
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select).hp >= Self.hp
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local drawer = room:askForChoosePlayers(player, {effect.from, effect.tos[1]}, 1, 1, "#os__beini-target::" .. effect.tos[1], self.name)
    if #drawer > 0 then
      local slasher = drawer == effect.tos[1] and player or target
      drawer = room:getPlayerById(drawer[1]) 
      drawer:drawCards(2, self.name)
      local slash = Fk:cloneCard("slash")
      slash.skillName = self.name
      local new_use = {} ---@type CardUseStruct
      new_use.from = slasher.id
      new_use.tos = { {drawer.id} }
      new_use.card = slash
      room:useCard(new_use)
    end
  end,
}

local os__dingfa = fk.CreateTriggerSkill{
  name = "os__dingfa",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self.name) and player.phase == Player.Discard and player:getMark("@" .. self.name) >= player.hp
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

  refresh_events = {fk.AfterCardsMove, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.AfterCardsMove then
      if player.phase == Player.NotActive then return false end
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    else
      return data.to == Player.NotActive
    end
    return false
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
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
      room:addPlayerMark(player, "@" .. self.name, x)
    else
      room:setPlayerMark(player, "@" .. self.name, 0)
    end
  end,
}

os__jiachong:addSkill(os__beini)
os__jiachong:addSkill(os__dingfa)

Fk:loadTranslationTable{
  ["os__jiachong"] = "贾充",
  ["os__beini"] = "悖逆",
  [":os__beini"] = "阶段技，你可以选择一名体力值不小于你的角色，令你或其摸两张牌，然后未摸牌的角色视为对摸牌的角色使用一张【杀】。",
  ["os__dingfa"] = "定法",
  [":os__dingfa"] = "弃牌阶段结束时，若本回合你失去的牌数不小于你的体力值，你可以选择一项：1、回复1点体力；2、对一名其他角色造成1点伤害。",

  ["#os__beini-target"] = "悖逆：选择你或 %dest ，令其摸两张牌并被【杀】",
  ["@os__dingfa"] = "定法",
  ["os__dingfa_damage"] = "对一名其他角色造成1点伤害",
  ["os__dingfa_recover"] = "回复1点体力",
  ["#os__dingfa-target"] = "定法：选择一名其他角色，对其造成1点伤害",
}

local os__haomeng = General(extension, "os__haomeng", "qun", 4)

function getSkillsNum(player)  --判断技能数，装备技能除外
  local skills = {}
  for _, s in ipairs(player.player_skills) do
    if not s.attached_equip then
      table.insert(skills, s)
    end
  end
  for _, s in ipairs(player.derivative_skills) do
    if not s.attached_equip then
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
      data.firstTarget and
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
    local choice = room:askForChoice(player, choices, self.name, "#os__gongge-choice")
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
      room:setPlayerMark(player, "@os__gongge", "gh_draw")
    elseif choice == "os__gongge_discard" then
      local cards = room:askForCardsChosen(player, target, x+1, x+1, "he", self.name)
      room:throwCard(cards, self.name, target, player)
      room:setPlayerMark(player, "@os__gongge", "gh_discard")
    elseif choice == "os__gongge_damage" then
      room:setPlayerMark(player, "@os__gongge", "gh_damage")
    end
  end,

  refresh_events = {fk.CardUseFinished, fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return false end
    if event == fk.CardUseFinished then
      if player:getMark("@os__gongge") == "gh_draw" then
        local use = data
        local effect = use.responseToEvent
        return effect and effect.from == player.id and use.toCard
      end
      if player:getMark("@os__gongge") ~= 0 then
        return (data.card.id and data.card.id == player:getMark("_os__gongge"))
      end
    else
      return player:getMark("@os__gongge") == "gh_damage" and player:getMark("_os__gongge_target") == data.to.id
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
        if player:getMark("@os__gongge") == "gh_discard" then
          if target.hp >= player.hp then
            local cids
            if #player:getCardIds(Player.Equip) + #player:getCardIds(Player.Hand) > x then
              cids = room:askForCard(player, x, x, true, self.name, false)
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
        elseif player:getMark("@os__gongge") == "gh_damage" then
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
      local target = player.room:getPlayerById(player:getMark("_os__gongge_target"))
      local x = getSkillsNum(target)
      data.damage = data.damage + x
    end
  end,
}

os__haomeng:addSkill(os__gongge)

Fk:loadTranslationTable{
  ["os__haomeng"] = "郝萌",
  ["os__gongge"] = "攻阁",
  [":os__gongge"] = "当你使用伤害类的牌指定第一个目标后，你可选择其中一个目标并选择：1、摸X+1张牌，若此牌被其响应，你跳过下次摸牌阶段。" .. 
  "2、弃置其X+1张牌，此牌结算后，若其体力值不小于你，你交给其X张牌。3、此牌对其造成伤害+X，此牌结算后其回复X点体力。（X为其武将技能数）",
  ["#os__gongge-ask"] = "攻阁：你可对一名目标发动“攻阁”",

  ["#os__gongge-choice"] = "攻阁：请选择一项（X为其武将技能数+1）",
  ["os__gongge_draw"] = "摸X张牌",
  ["os__gongge_discard"] = "弃置其X张牌",
  ["os__gongge_damage"] = "伤害+X",
  ["@os__gongge"] = "攻阁",
  ["gh_draw"] = "摸牌",
  ["gh_discard"] = "弃牌",
  ["gh_damage"] = "加伤",
}

Fk:loadTranslationTable{
  ["nanshengmi"] = "难升米",
  ["chijie"] = "持节",
  [":chijie"] = "游戏开始时，你可以选择一个现有势力，你的势力视为该势力。",
  ["waishi"] = "外使",
  [":waishi"] = "阶段技，你可以用至多X张牌交换一名其他角色等量的手牌（X为现存势力数），然后若其与你势力相同或手牌多于你，你摸一张牌。",
  ["renshe"] = "忍涉",
  [":renshe"] = "当你受到伤害后，你可以选择一项：1.将势力改为现存的另一个势力：2.令〖外使〗的发动次数上限于你的出牌阶段结束前+1；3.与另一名其他角色各摸一张牌。",

  ["wangyue"] = "王越",
	["yulong"] = "驭龙",
	[":yulong"] = "当你使用【杀】指定目标后，你可与其中一名目标拼点。若你：赢，此【杀】{若造成伤害则不计入次数}，且你此次的拼点牌为：黑色，此【杀】的伤害+1；红色，此【杀】不可被响应。",
	["jianming"] = "剑鸣",
	[":jianming"] = "锁定技，每回合每花色限一次，当你使用或打出一种花色的【杀】时，你摸一张牌。",

  ["puyangxing"] = "濮阳兴",
	["zhengjian"] = "征建",
	[":zhengjian"] = "游戏开始时，你选择一项：1.使用过非基本牌；2.获得过牌。其他角色的出牌阶段结束时，若其此阶段未完成“征建”要求的选项，其交给你一张牌，然后你可变更〖征建〗的选项。",
	["zhongchi"] = "众斥",
	[":zhongchi"] = "锁定技，当累计有X名角色因〖征建〗交给你牌后（X为游戏人数的一半，向上取整），你本局游戏受到【杀】的伤害+1，并将〖征建〗中的“其交给你一张牌”修改为“你可对其造成1点伤害”。",

  ["os__tianyu"] = "田豫",
  ["zhenxi"] = "震袭",
  [":zhenxi"] = "每回合限一次，当你使用【杀】指定目标后，你可选择一项：1.弃置其X张手牌（X为你与其的距离）2.移动其场上的一张牌；若其体力值大于你或为全场最高，则你可背水。",
  ["yangshi"] = "扬师",
  [":yangshi"] = "锁定技，当你受到伤害后，你的攻击范围+1，若你可攻击到所有角色，则改为从牌堆中获得一张【杀】。",
}
return {extension}