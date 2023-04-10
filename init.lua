local extension = Package("overseas")

Fk:loadTranslationTable{
  ["overseas"] = "国际服",
  ["os"] = "国际",
  ["os_ex"] = "国际界",
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
      new_use.tos = { {self.cost_data} }
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
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return target == player and player:hasSkill(self.name) and
        player.phase == Player.Finish and player.hp > 0
    end
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
    local slash = Fk:cloneCard("slash")
    slash.skillName = self.name
    local new_use = {} ---@type CardUseStruct
    new_use.from = player.id
    new_use.tos = { {self.cost_data} }
    new_use.card = slash
    local basic_types = 0
    local basic_cards = {"peach", "slash", "jink", "analeptic"}
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
  [":os__fenwu"] = "结束阶段，你可失去1点体力，视为你对一名其他角色使用一张【杀】。若本回合你使用过超过一种基本牌，此【杀】伤害+1。",
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
      room:throwCard(self.cost_data, self.name, player, player)
      room:addPlayerMark(player, "_os__cuijin_invoked", 1)
      room:setPlayerMark(target, "_os__cuijin_achieved", 0) --很蠢
      data.additionalDamage = (data.additionalDamage or 0) + 1
    else
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
    return target == player and data.card and data.card.trueName == "slash" and
    #table.filter(player.room:getAlivePlayers(), function(p)
      return p:getMark("_os__cuijin_invoked") > 0
    end) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__cuijin_achieved", 1)
  end,
}
yuejiu:addSkill(os__cuijin)

Fk:loadTranslationTable{
  ["yuejiu"] = "乐就",
	["os__cuijin"] = "催进",
	[":os__cuijin"] = "当你或攻击范围内的角色使用【杀】时，你可弃置一张牌，令此【杀】伤害+1。此【杀】结算后，若此【杀】未造成伤害，你对此【杀】的使用者造成1点伤害。",

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
	[":os__cuorui"] = "限定技，准备阶段开始时，你可将手牌摸至X张（X为场上最大的手牌数，至多摸五张），跳过此回合的判定阶段。若你发动过〖挫锐〗，你可选择一名其他角色，对其造成1点伤害。", --其实是废除判定区
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
    if not player.chained and room:askForChoice(player, {"beishui_os__fenming", "Cancel"}, self.name) == "beishui_os__fenming" then 
      player:setChainState(true)
      if not target:isNude() then
        local card = room:askForCardChosen(player, target, "he", self.name)
        room:throwCard(card, self.name, target, player)
      end
      if not target.chained then target:setChainState(true) end
    else
      local choices = {}
      if not target:isNude() then table.insert(choices, "os__fenming_discard") end
      if not target.chained then table.insert(choices, "os__fenming_chained") end
      if #choices == 0 then return false end
      if room:askForChoice(target, choices, self.name, "#os__fenming-target::" .. player.id) == "os__fenming_discard" then
        local card = room:askForCardChosen(player, target, "he", self.name)
        room:throwCard(card, self.name, target, player)
      else
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
  [":os__fenming"] = "准备阶段，你可选择一名角色，令其选择：1.你弃置其一张牌；2. 横置；背水：你横置。",

  ["os__yilie_times"] = "使用【杀】的次数上限+1", 
  ["os__yilie_draw"] = "当你使用的【杀】指定处于连环状态的角色为目标后，或被【闪】抵消后，摸一张牌", 
  ["@os__yilie"] = "毅烈",
  ["yl_times_draw"] = "摸牌 多出杀",
  ["yl_times"] = "多出杀",
  ["yl_draw"] = "摸牌",

  ["beishui_os__yilie"] = "背水：你失去1点体力",
  ["#os__fenming-ask"] = "奋命：你可令一名角色选择：1.你弃置其一张牌；2. 横置；背水：你横置",
  ["beishui_os__fenming"] = "背水：你横置",
  ["#os__fenming-target"] = "奋命：请选择：1. %dest 弃置你一张牌；2. 横置",
  ["os__fenming_discard"] = "被弃置牌",
  ["os__fenming_chained"] = "横置",
}

local liufuren = General:new(extension, "liufuren", "qun", 3, 3, General.Female)
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
    if target.gender == General.Female and not player:isNude() and room:askForChoice(player, {"beishui_os__zhuidu", "Cancel"}, self.name) ~= "Cancel" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
      if #target:getCardIds(Player.Equip) > 0 then
        --local card = room:askForCardChosen(target, target, "e", self.name)
        --room:throwCard(card, self.name, target, target)
        room:askForDiscard(target, 1, 1, true, self.name, false, ".|.|.|equip", "#os__chuidu-discard1")
      end
      if not player:isNude() then room:askForDiscard(player, 1, 1, true, self.name, false) end
    else
      --local choices = {"os__zhuidu_damage"}
      --if #target:getCardIds(Player.Equip) > 0 then table.insert(choices, "os__zhuidu_equip") end
      --if room:askForChoice(target, choices, self.name) == "os__zhuidu_equip" then
        --local card = room:askForCardChosen(target, target, "e", self.name)
        --room:throwCard(card, self.name, target, target)
      if #target:getCardIds(Player.Equip) < 1 or #room:askForDiscard(target, 1, 1, true, self.name, true, ".|.|.|equip", "#os__chuidu-discard2::" .. player.id) == 0 then
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
  [":os__zhuidu"] = "出牌阶段限一次，你可选择一名受伤的其他角色并选择一项：1.你对其造成1点伤害；2.弃置装备区的一张牌；若其为女性角色，则你可背水：（在其执行完所有可执行的选项后）弃置一张牌。",
  ["os__shigong"] = "示恭",
  [":os__shigong"] = "限定技，当你回合外进入濒死状态时，你可令当前回合者选择一项：1. 增加1点体力上限，回复1点体力，摸一张牌，令你体力回复至体力上限；2. 弃置X张手牌（X为其当前体力值），令你体力回复至1点。",

  ["beishui_os__zhuidu"] = "背水：你弃置一张牌",
  ["#os__chuidu-discard1"] = "追妒：弃置装备区的一张牌",
  ["#os__chuidu-discard2"] = "追妒：弃置装备区的一张牌，否则受到 %dest 1点伤害",
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
--[[
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
    local use = room:askForUseCard(target, "slash", "slash|.|heart,diamond,nonsuit", "#os__zhenjun_slash", true) --exppattern没有black，没有^。另外，丈八颜色判断有问题，贯石斧可以弃置自己。
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
  ["os__sp_yujin"] = "于禁",
  ["os__zhenjun"] = "镇军",
  [":os__zhenjun"] = "出牌阶段开始时，你可以交给一名其他角色一张牌，令其使用一张非黑色的【杀】：若其执行，则此【杀】结算后你摸一张牌，若此【杀】造成过伤害，你额外摸伤害值数张牌；若其不执行，则你可对其或其攻击范围内的一名角色造成1点伤害。",

  ["#os__zhenjun-target"] = "镇军：你可选择一张牌，交给一名其他角色",
  ["#os__zhenjun_slash"] = "镇军：请使用一张非黑色的【杀】",
  ["#os__zhenjun-damage"] = "镇军：你可对 %dest 或其攻击范围内的一名角色造成1点伤害",
}
]]--
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
    local drawer = room:askForChoosePlayers(player, {effect.from, effect.tos[1]}, 1, 1, "#os__beini-target::" .. effect.tos[1], self.name)
    if #drawer > 0 then
      local slasher = drawer[1] == effect.tos[1] and player or target
      drawer = room:getPlayerById(drawer[1]) 
      drawer:drawCards(2, self.name)
      local slash = Fk:cloneCard("slash")
      slash.skillName = self.name
      local new_use = {} ---@type CardUseStruct
      new_use.from = slasher.id
      new_use.tos = { {drawer.id} }
      new_use.card = slash --TODO: canUseCardToTarget
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
        self.os__dingfa_num = x
        return true
      end
    else
      return data.to == Player.NotActive
    end
    return false
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      room:addPlayerMark(player, "@" .. self.name, self.os__dingfa_num)
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
  [":os__beini"] = "出牌阶段限一次，你可以选择一名体力值不小于你的角色，令你或其摸两张牌，然后未摸牌的角色视为对摸牌的角色使用一张【杀】。",
  ["os__dingfa"] = "定法",
  [":os__dingfa"] = "弃牌阶段结束时，若本回合你失去的牌数不小于你的体力值，你可以选择一项：1、回复1点体力；2、对一名其他角色造成1点伤害。",

  ["#os__beini-target"] = "悖逆：选择你或 %dest ，令其摸两张牌并被【杀】",
  ["@os__dingfa"] = "定法",
  ["os__dingfa_damage"] = "对一名其他角色造成1点伤害",
  ["os__dingfa_recover"] = "回复1点体力",
  ["#os__dingfa-target"] = "定法：选择一名其他角色，对其造成1点伤害",
}

local os__haomeng = General(extension, "os__haomeng", "qun", 4)

function getSkillsNum(player)  --判断技能数，装备技能除外，飞扬跋扈手动
  local skills = {}
  for _, s in ipairs(player.player_skills) do
    if not (s.attached_equip or s.name == "m_feiyang" or s.name == "m_bahu") then
      table.insert(skills, s)
    end
  end
  for _, s in ipairs(player.derivative_skills) do
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
        return effect and effect.from == player.id and use.toCard
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
  "2、弃置其X+1张牌，此牌结算后，若其体力值不小于你，你交给其X张牌。3、此牌对其造成伤害+X，此牌结算后其回复X点体力。（X为其武将技能数）",
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

local os__tianyu = General(extension, "os__tianyu", "wei", 4) --但，国际服测试服先上线，十周年测试服后上线

--- 判断一名角色场上有没有可以被移动的牌。
---@param target ServerPlayer @ 被选牌的人
---@param flag string @ 用"ej"三个字母的组合表示能选择哪些区域, e - 装备区, j - 判定区
---@return boolean @ TODO: 在askForCardChosen中加入disabled_ids，disabled_ids在这个函数中筛选出来
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

--拷贝自郭照……
---@param pattern string
---@param fromPiles integer[]
---@return integer[] | nil
function getCardByPattern(room, pattern, fromPiles)
  pattern = pattern or "."
  fromPiles = fromPiles or room.draw_pile

  --THIS IS STUPID!
  if pattern == "damage_card" then
    pattern = "slash,duel,savage_assault,archery_attack,fire_attack,thunder"
  elseif pattern == "nondamage_card" then
    pattern = "jink,peach,dismantlement,snatch,collateral,nullification,indulgence,amazing_grace,god_salvation"..
      "crossbow,double_swords,qinggang_sword,ice_sword,axe,spear,blade,halberd,kylin_bow,eight_diagram,nioh_shield,chitu,dayuan,dilu,jueying,zixing,zhuahuangfeidian"..
      "analeptic,iron_chain,supply_shortage"..
      "guding_blade,fan,silver_lion,vine,hualiu"
  end

  --THIS IS STUPID!
  if pattern == "damage_card" then
    pattern = "slash,duel,savage_assault,archery_attack,fire_attack,thunder"
  elseif pattern == "nondamage_card" then
    pattern = "jink,peach,dismantlement,snatch,collateral,nullification,indulgence,amazing_grace,god_salvation"..
      "crossbow,double_swords,qinggang_sword,ice_sword,axe,spear,blade,halberd,kylin_bow,eight_diagram,nioh_shield,chitu,dayuan,dilu,jueying,zixing,zhuahuangfeidian"..
      "analeptic,iron_chain,supply_shortage"..
      "guding_blade,fan,silver_lion,vine,hualiu"
  end

  local cards = {}
  for i = 1, #fromPiles, 1 do
    local card = Fk:getCardById(fromPiles[i])
    if card:matchPattern(pattern) then
      table.insertIfNeed(cards, fromPiles[i])
    end
  end
  if #cards > 0 then
    return(cards[math.random(1, #cards)])
  else
    return nil
  end
end

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
Fk:addSkill(os__yangshiAR)

os__tianyu:addSkill(os__zhenxi)
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
        local card = room:askForCardChosen(player, target, "he", self.name)
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
  [":os__moukui"] = "当你使用【杀】指定目标后，你可选择一项：1.摸一张牌；2.弃置其一张牌；背水：此【杀】结算后，若此【杀】未令其进入濒死状态，其弃置你一张牌。",

  ["os__moukui_draw"] = "摸一张牌",
  ["os__moukui_discard"] = "弃置其一张牌",
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
      data.firstTarget and
      table.contains({"slash", "duel", "savage_assault", "archery_attack", "fire_attack" }, data.card.trueName)
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
      if #cids > 0 then
        self.cids = cids
        return true
      end
    end
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
    dummy:addSubcards(self.cids)
    player.room:obtainCard(self.cost_data, dummy, false, fk.ReasonGive)
  end,
}

os__wujing:addSkill(os__fenghan)
os__wujing:addSkill(os__congji)

Fk:loadTranslationTable{
  ["os__wujing"] = "吴景",
  ["os__fenghan"] = "锋悍",
  [":os__fenghan"] = "当你使用【杀】或伤害锦囊牌指定第一个目标后，你可令至多X名角色摸一张牌（X为目标数）。",
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
      room:addPlayerMark(target, "_os__xuewei_defence_from", 1)
      room:addPlayerMark(to, "_os__xuewei_defence_to", 1)
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

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os__xuewei_defence_from") > 0 and player.phase == Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "_os__xuewei_defence_from", 0)
    for _, p in ipairs(room:getAlivePlayers()) do
      room:setPlayerMark(p, "_os__xuewei_defence_to", 0)
    end
  end,
}

local os__xuewei_prohibit = fk.CreateProhibitSkill{
  name = "#os__xuewei_prohibit",
  is_prohibited = function(self, from, to, card)
    if from:getMark("_os__xuewei_defence_from") > 0 and to:getMark("_os__xuewei_defence_to") > 0 then
      return card.trueName == "slash"
    end
  end,
}

local os__xuewei_max =  fk.CreateMaxCardsSkill{
  name = "#os__xuewei_max",
  correct_func = function(self, player)
    return - player:getMark("_os__xuewei_defence_from") * 2
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
    if player:getMark("_os__liechi_dying") > 0 then
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

  refresh_events = {fk.EnterDying, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EnterDying then
      return target == player
    else
      return target.phase == Player.NotActive and player:getMark("_os__liechi_dying") > 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EnterDying then player.room:addPlayerMark(player, "_os__liechi_dying", 1)
    else player.room:setPlayerMark(player, "_os__liechi_dying", 0) end
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
    local pile = room.draw_pile
    table.insertTable(pile, room.discard_pile)
    local card = {getCardByPattern(room, ".|.|.|.|.|" .. self.cost_data[2], pile)}
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

  refresh_events = {fk.EventPhaseChanging, fk.GameStart},
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
  [":os__jiaohua"] = "当你或体力值最小的角色摸牌后，你可令其从牌堆中或弃牌堆中获得一张本次摸牌未获得的类型的牌（每种类型每回合限一次）。",

  ["#os__jiaohua"] = "你想对 %dest 发动技能“教化”吗？",
}

local niufudongxie = General(extension, "niufudongxie", "qun", 4) --FIXME：性别：男&女（）

local os__juntun = fk.CreateTriggerSkill{
  name = "os__juntun",
  anim_type = "offensive", --哈哈
  events = {fk.GameStart, fk.BuryVictim},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not table.every(player.room:getOtherPlayers(player), function(p)
      return p:hasSkill("os__xiongjun")
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(
      table.filter(room:getOtherPlayers(player), function(p)
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
    return (target and target == player or (target:hasSkill("os__xiongjun") and event == fk.Damage )) and player:hasSkill(self.name) and player:getMark("@baonue") < 5 and not player.dead
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@baonue", math.min(data.damage, 5 - player:getMark("@baonue")))
  end,
}

local os__xiongxi = fk.CreateActiveSkill{
  name = "os__xiongxi",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 5 - Self:getMark("@baonue")
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return to_select ~= Self.id and #selected_cards == 5 - Self:getMark("@baonue")
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
    return player:hasSkill(self.name) and player.phase == Player.Play and player:getMark("@baonue") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    for i = 1, math.min(3, player:getMark("@baonue")) do
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
    room:setPlayerMark(player, "_os__xiafeng", num)
    room:removePlayerMark(player, "@baonue", num)
  end,

  refresh_events = {fk.EventPhaseChanging, fk.PreCardUse, fk.PreCardRespond},
  can_refresh = function(self, event, target, player, data)
    if player == target then
      if event == fk.EventPhaseChanging then
        return data.to == Player.NotActive --所有的回合计数写的有点混乱
      else
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseChanging then
      room:setPlayerMark(player, "_os__xiafeng", 0)
      room:setPlayerMark(player, "_os__xiafeng_count", 0)
    else
      room:addPlayerMark(player, "_os__xiafeng_count", 1)
    end
  end,
}

local os__xiafeng_disres = fk.CreateTriggerSkill{
  name = "#os__xiafeng_disres",
  mute = true,
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("_os__xiafeng_count") <= player:getMark("_os__xiafeng") and player:getMark("_os__xiafeng") > 0
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
    return (player:getMark("_os__xiafeng_count") <= player:getMark("_os__xiafeng") and player:getMark("_os__xiafeng") > 0) and 999 or 0
  end,
  distance_limit_func = function(self, player, skill)
    return (player:getMark("_os__xiafeng_count") <= player:getMark("_os__xiafeng") and player:getMark("_os__xiafeng") > 0) and 999 or 0
  end,
}

local os__xiafeng_max =  fk.CreateMaxCardsSkill{
  name = "#os__xiafeng_max",
  correct_func = function(self, player)
    return player:getMark("_os__xiafeng")
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

  refresh_events = {fk.Damage, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if event == fk.Damage then return target == player
    else return data.from == Player.NotActive end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then player.room:addPlayerMark(player, "_damage_times-turn", 1)
    else player.room:setPlayerMark(player, "_damage_times-turn", 0) end
  end,
}

niufudongxie:addSkill(os__juntun)
niufudongxie:addSkill(os__xiongxi)
os__xiafeng:addRelatedSkill(os__xiafeng_disres)
os__xiafeng:addRelatedSkill(os__xiafeng_buff)
os__xiafeng:addRelatedSkill(os__xiafeng_max)
niufudongxie:addSkill(os__xiafeng)
Fk:addSkill(os__xiongjun)

Fk:loadTranslationTable{
  ["niufudongxie"] = "牛辅董翓",
  ["os__juntun"] = "军屯",
  [":os__juntun"] = "游戏开始时或当其他角色死亡后，你可令一名没有〖凶军〗的其他角色获得〖凶军〗。当拥有〖凶军〗的其他角色造成伤害后，你获得等量暴虐值。<br></br>" .. 
    "<font color=\"grey\">#\"<b>暴虐值</b>\"<br></br>当你造成或受到伤害后，你获得等量暴虐值。暴虐值上限为5。</font>",
  ["os__xiongxi"] = "凶袭",
  [":os__xiongxi"] = "出牌阶段限一次，你可弃置X张牌对一名其他角色造成1点伤害。（X=5-暴虐值，可以为0）",
  ["os__xiafeng"] = "黠凤",
  [":os__xiafeng"] = "出牌阶段开始时，你可消耗至多3点暴虐值，令你本回合使用的前X张牌无距离和次数限制且不可被响应，手牌上限+X。（X为消耗暴虐值）",
  ["os__xiongjun"] = "凶军",
  [":os__xiongjun"] = "锁定技，当你于一个回合内第一次造成伤害后，所有拥有〖凶军〗的角色各摸一张牌。",

  ["@baonue"] = "暴虐值",
  ["#os__juntun-ask"] = "军屯：你可令一名没有〖凶军〗的其他角色获得〖凶军〗",
  ["#os__xiafeng"] = "黠凤：本回合使用的前X张牌无距离和次数限制且不能被响应，手牌上限+X",
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
    if #selected == 0 and to_select ~= Self.id and #selected_cards > 0 then
      local to = Fk:currentRoom():getPlayerById(to_select)
      return to:getHandcardNum() + #to:getCardIds(Player.Equip) >= #selected_cards
    end
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cids = target:getCardIds(Player.Hand)
    table.insertTable(cids, target:getCardIds(Player.Equip))
    
    local card_ids = {}
    for i = 1, #effect.cards, 1 do
      if #cids > 0 then
        local id = cids[math.random(1, #cids)]
        table.insert(card_ids, id)
        table.removeOne(cids, id)
      end
    end
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
        ids = card_ids,
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
    local choices = {"os__waishi_times", "os__renshe_draw", "Cancel"}
    local room = player.room
    if not table.every(room:getOtherPlayers(player), function(p)
      return p.kingdom == player.kingdom
    end) then
      table.insert(choices, 1, "os__renshe_change")
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
        local target = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
          return p.id
        end), 1, 1, "#os__renshe-target", self.name, false)
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
  [":os__waishi"] = "出牌阶段限一次，你可选择至多X张牌，并选择一名其他角色，令系统选择其X张牌（X为现存势力数），你与其交换这些牌，然后若其与你势力相同或手牌多于你，你摸一张牌。",
  ["os__renshe"] = "忍涉",
  [":os__renshe"] = "当你受到伤害后，你可选择一项：1.将势力改为现存的另一个势力；2.令〖外使〗的发动次数上限于你的出牌阶段结束前+1；3.与一名其他角色各摸一张牌。",

  ["#os__chijie-choose"] = "持节：你可更改你的势力",
  ["@os__chijie"] = "持节",
  ["@chijie_general"] = "持节",
  ["os__renshe_change"] = "将势力改为现存的另一个势力",
  ["os__waishi_times"] = "令〖外使〗的发动次数上限于你的出牌阶段结束前+1",
  ["@os__waishi_times"] = "外使次数+",
  ["os__renshe_draw"] = "与一名其他角色各摸一张牌",
  ["#os__renshe-target"] = "忍涉：选择一名其他角色，与其各摸一张牌",
}



Fk:loadTranslationTable{
  ["os__guanqiujian"] = "毌丘俭",
  ["os__zhengrong"] = "征荣",
  [":os__zhengrong"] = "当你于你的出牌阶段对其他角色使用累计偶数张牌结算结束后，或当你于出牌阶段第一次造成伤害后，你可选择一名其他角色，将其一张牌置于你的武将牌上，称为“荣”。",
  ["os__hongju"] = "鸿举",
  [":os__hongju"] = "觉醒技，准备阶段，若“荣”的数量不小于3，则你摸等于“荣”数量的牌，然后用任意张手牌替换等量的“荣”，然后获得〖清侧〗（出牌阶段，你可将一张“荣”置入弃牌堆，然后弃置其他角色区域内的一张牌）并选择是否减1点体力上限获得技能〖扫讨〗（锁定技，你使用的【杀】和普通锦囊牌不能被响应）。", --FIXME：把获得的技能描述展示在武将一览的技能里
  ["os__qingce"] = "清侧",
  [":os__qingce"] = "出牌阶段，你可将一张“荣”置入弃牌堆，然后弃置其他角色区域内的一张牌。",
  ["os__saotao"] = "扫讨",
  [":os__saotao"] = "锁定技，你使用的【杀】和普通锦囊牌不能被响应。",

  ["#os__zhengrong-ask"] = "征荣：你可选择一名其他角色，将其一张牌置于你的武将牌上",
  ["gqj__glory"] = "荣",
  ["#os__hongju_card"] = "鸿举：你可选择任意张手牌，替换等量的“荣”",

  ["os__xia_xushu"] = "徐庶",
  ["os__jiange"] = "剑歌",
  [":os__jiange"] = "每回合限一次，你可将一张非基本牌当【杀】使用或打出（无距离与次数限制且不计入次数）。若此时为你的回合外，你摸一张牌。",
  ["os__xiawang"] = "侠望",
  [":os__xiawang"] = "当至你距离不大于1的角色受到黑色牌造成的伤害后，你可对伤害来源使用一张【杀】。若此【杀】造成了伤害，则在【杀】结算后结束当前阶段。",

  ["os_ex__guohuai"] = "郭淮",
  ["os_ex__jingce"] = "精策",
  [":os_ex__jingce"] = "出牌阶段，当你使用了第X张牌时（X为你当前体力值），你可以摸两张牌。若这不是你本阶段第一次摸牌或本回合你已造成过伤害，你获得1枚“策”。",
  ["os_ex__yuzhang"] = "御嶂",
  [":os_ex__yuzhang"] = "你可弃1枚“策”以跳过一个阶段。当你受到伤害后，你可弃1枚“策”并选择一项，令伤害来源执行：1.本回合不可再使用或打出手牌；2.弃置两张牌。", 

  ["os__puyangxing"] = "濮阳兴",
	["zhengjian"] = "征建",
	[":zhengjian"] = "游戏开始时，你选择一项：1.使用过非基本牌；2.获得过牌。其他角色的出牌阶段结束时，若其此阶段未完成“征建”要求的选项，其交给你一张牌，然后你可变更〖征建〗的选项。",
	["zhongchi"] = "众斥",
	[":zhongchi"] = "锁定技，当累计有X名角色因〖征建〗交给你牌后（X为游戏人数的一半，向上取整），你本局游戏受到【杀】的伤害+1，并将〖征建〗中的“其交给你一张牌”修改为“你可对其造成1点伤害”。",
}
return {extension}