local extension = Package("overseas_ex")
extension.extensionName = "overseas"

Fk:loadTranslationTable{
  ["overseas_ex"] = "国际服界",
  ["os_ex"] = "国际界",
}

local os_ex__guohuai = General(extension, "os_ex__guohuai", "wei", 4)

local os_ex__jingce = fk.CreateTriggerSkill{
  name = "os_ex__jingce",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and (data.card.extra_data or {}).os_ex__jingce == player.hp
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

  refresh_events = {fk.AfterCardUseDeclared, fk.AfterCardsMove, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return target == player and player.phase == Player.Play --and player:hasSkill(self.name, true) 
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
    if event == fk.AfterCardUseDeclared then
      player.room:addPlayerMark(player, "_os_ex__jingce_use-phase", 1)
      data.card.extra_data = data.card.extra_data or {}
      data.card.extra_data.os_ex__jingce = player:getMark("_os_ex__jingce_use-phase")
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
      local choice = player.room:askForChoice(player, {"os_ex__yuzhang_disable", "os_ex__yuzhang_discard", "Cancel"}, self.name, "#os_ex__yuzhang-ask::" .. data.from.id)
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
        if #target:getCardIds({Player.Hand, Player.Equip}) <= 2 then
          target:throwAllCards("he")
        else
          room:askForDiscard(target, 2, 2, true, self.name, false)
        end
      else
        room:addPlayerMark(target, "_os_ex__yuzhang_pro-turn", 1)
      end
    end
  end,
}
local os_ex__yuzhang_prohibit = fk.CreateProhibitSkill{
  name = "#os_ex__yuzhang_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("_os_ex__yuzhang_pro-turn") > 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("_os_ex__yuzhang_pro-turn") > 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
}

os_ex__yuzhang:addRelatedSkill(os_ex__yuzhang_prohibit)
os_ex__guohuai:addSkill(os_ex__jingce)
os_ex__guohuai:addSkill(os_ex__yuzhang)

Fk:loadTranslationTable{
  ["os_ex__guohuai"] = "界郭淮",
  ["os_ex__jingce"] = "精策",
  [":os_ex__jingce"] = "当你出牌阶段使用的第X张牌结算结束后（X为你的体力值），你可摸两张牌，然后若这不是你本阶段第一次摸牌或本回合你已造成过伤害，你获得1枚“策”。",
  ["os_ex__yuzhang"] = "御嶂",
  [":os_ex__yuzhang"] = "①你可弃1枚“策”，跳过一个阶段。②当你受到伤害后，你可弃1枚“策”并选择一项，令伤害来源执行：1.本回合不能使用或打出手牌；2.弃置两张牌（不足全弃）。", 

  ["@os_ex__strategy"] = "策",
  ["#os_ex__yuzhang"] = "御嶂：你可弃1枚“策”，跳过 %arg",
  ["#os_ex__yuzhang-ask"] = "御嶂：你可弃1枚“策”，选择一项，令 %dest 执行",
  ["os_ex__yuzhang_disable"] = "令其本回合不能再使用或打出手牌",
  ["os_ex__yuzhang_discard"] = "其弃置两张牌",
}

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
    if not table.contains(player.player_cards[Player.Hand], card.id) then return false end
    if player:getMark("@qianxi-turn") ~= 0 then return card:getColorString() == player:getMark("@qianxi-turn") end
    if player:getMark("@os_ex__qianxi") ~= 0 then return card:getColorString() == player:getMark("@os_ex__qianxi") end
  end,
  prohibit_response = function(self, player, card)
    if not table.contains(player.player_cards[Player.Hand], card.id) then return false end
    if player:getMark("@qianxi-turn") ~= 0 then return card:getColorString() == player:getMark("@qianxi-turn") end
    if player:getMark("@os_ex__qianxi") ~= 0 then return card:getColorString() == player:getMark("@os_ex__qianxi") end
  end,
}
os_ex__qianxi:addRelatedSkill(os_ex__qianxi_prohibit)

os_ex__madai:addSkill("mashu")
os_ex__madai:addSkill(os_ex__qianxi)

Fk:loadTranslationTable{
  ["os_ex__madai"] = "界马岱",
  ["os_ex__qianxi"] = "潜袭",
  [":os_ex__qianxi"] = "准备阶段开始时，你可摸一张牌，然后弃置一张牌，令距离为1的一名角色本回合不能使用或打出与你以此法弃置的牌颜色相同的手牌，然后结束阶段开始时，若你于本回合使用【杀】对其造成过伤害，你令其不能使用或打出另一种颜色的牌至其下回合结束。",
  
  ["#os_ex__qianxi-choose"] = "潜袭：选择距离为1的一名角色，令其本回合不能使用或打出 %arg 的手牌",
  ["@qianxi-turn"] = "潜袭",
  ["@os_ex__qianxi"] = "潜袭",
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
os_ex__gongqi:addRelatedSkill(os_ex__gongqi_attackrange)
os_ex__gongqi:addRelatedSkill(os_ex__gongqi_buff)

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
os_ex__jiefan:addRelatedSkill(os_ex__jiefan_re)

os_ex__handang:addSkill(os_ex__gongqi)
os_ex__handang:addSkill(os_ex__jiefan)

Fk:loadTranslationTable{
  ["os_ex__handang"] = "界韩当",
  ["os_ex__gongqi"] = "弓骑",
  [":os_ex__gongqi"] = "①你的攻击范围无限。②出牌阶段限一次，你可弃置一张牌，你于此阶段内使用与弃置的牌花色相同的【杀】无次数限制。若弃置的为装备牌，你可弃置一名其他角色的一张牌。",
  ["os_ex__jiefan"] = "解烦",
  [":os_ex__jiefan"] = "限定技，出牌阶段，你可选择一名角色，令能攻击到其的所有角色选择一项：1.弃置一张武器牌；2.令其摸一张牌。当你上一次发动〖解烦〗指定的角色进入濒死状态时，此技能视为未发动过。",
  
  ["#os_ex__gongqi-ask"] = "弓骑：你可弃置一名其他角色的一张牌",
  ["#os_ex__jiefan-discard"] = "解烦：弃置一张武器牌，否则 %dest 摸一张牌",
}

local os_ex__chengpu = General(extension, "os_ex__chengpu", "wu", 4)

local os_ex__lihuo = fk.CreateTriggerSkill{
  name = "os_ex__lihuo",
  events = {fk.AfterCardUseDeclared, fk.AfterCardTargetDeclared},
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
        self.cost_data = targets
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
      data.extra_data = data.extra_data or {}
      data.extra_data.os_ex__lihuoUser = player.id
    else
      --TargetGroup:pushTargets(data.targetGroup, self.cost_data)
      table.insert(data.tos, self.cost_data)
    end
  end,
}
local os_ex__lihuo_judge = fk.CreateTriggerSkill{
  name = "#os_ex__lihuo_judge",
  events = {fk.CardUseFinished},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.extra_data or {}).os_ex__lihuoUser == player.id and data.extra_data and data.extra_data.os_ex__lihuoDying == true
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, self.name)
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    if target == player or not data.damage or not data.damage.card then return false end
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    return parentUseData and (parentUseData.data[1].extra_data or {}).os_ex__lihuoUser == player.id
  end,
  on_refresh = function(elf, event, target, player, data)
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    parentUseData.data[1].extra_data = parentUseData.data[1].extra_data or {}
    parentUseData.data[1].extra_data.os_ex__lihuoDying = true
  end,
}
os_ex__lihuo:addRelatedSkill(os_ex__lihuo_judge)

local os_ex__chunlao = fk.CreateTriggerSkill{
  name = "os_ex__chunlao",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and table.every(player.room.alive_players, function(p)
        return #p:getPile("os__dense_alcohol") == 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local availableTargets = table.map(
      table.filter(room.alive_players, function(p)
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
        table.filter(room.alive_players, function(p)
          return p:hasSkill("os_ex__chunlao")
        end),
        function(p)
          return p.id
        end
      )
      if #availableTargets == 0 then return false
      elseif #availableTargets == 1 then
        local prompt = availableTargets[1] == player.id and "#os_ex__chunlao-get" or "#os_ex__chunlao-give:" .. availableTargets[1]
        local cid = room:askForCard(player, 1, 1, true, self.name, true, nil, prompt)
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
      room:moveCardTo(cid, Player.Hand, chengpu, fk.ReasonGive, self.name, nil, false)
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
os_ex__chunlao:addRelatedSkill(os_ex__chunlao_do)

os_ex__chengpu:addSkill(os_ex__lihuo)
os_ex__chengpu:addSkill(os_ex__chunlao)

Fk:loadTranslationTable{
  ["os_ex__chengpu"] = "界程普",
  ["os_ex__lihuo"] = "疠火",
  [":os_ex__lihuo"] = "①你使用普【杀】可改为火【杀】，当此【杀】结算结束后，若此【杀】令其他角色进入过濒死状态，你失去1点体力。②当你使用火【杀】选择目标后，可多选择一个目标。",
  ["os_ex__chunlao"] = "醇醪",
  [":os_ex__chunlao"] = "准备阶段开始时，若场上没有“醇”，你可选择一名角色，将其区域内的一张牌置于其武将牌上，称为“醇”。有“醇”的角色使用【杀】时，｛若其为其他角色，其可交给你一张牌；若其为你，你可获得你一张牌｝，令此【杀】伤害值基数+1；其进入濒死状态时，你可将一张“醇”置入弃牌堆并摸一张牌，然后其回复1点体力。",

  ["#os_ex__lihuo-targets"] = "疠火：你可选择一名角色，令其也成为此火【杀】的目标",
  ["#os_ex__lihuo_judge"] = "疠火",
  ["os__dense_alcohol"] = "醇",
  ["#os_ex__chunlao-ask"] = "醇醪：你可选择一名角色，将其区域内的一张牌置于其武将牌上，称为“醇”",
  ["#os_ex__chunlao_do"] = "醇醪",
  ["#os_ex__chunlao-give"] = "醇醪：你可交给 %src 一张牌，令此【杀】伤害值基数+1",
  ["#os_ex__chunlao-get"] = "醇醪：你可获得你一张牌，令此【杀】伤害值基数+1",
  ["#os_ex__chunlao-choose_give"] = "醇醪：你可交给一名有“醇醪”的角色一张牌，令此【杀】伤害值基数+1",
}

local os_ex__zhangfei = General(extension, "os_ex__zhangfei", "shu", 4)

local os_ex__paoxiaoAudio = fk.CreateTriggerSkill{
  name = "#os_ex__paoxiaoAudio",
  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      data.card.trueName == "slash" and
      player:usedCardTimes("slash") > 1
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:broadcastSkillInvoke("os_ex__paoxiao")
    player.room:doAnimate("InvokeSkill", {
      name = "os_ex__paoxiao",
      player = player.id,
      skill_type = "offensive",
    })
  end,
}
local os_ex__paoxiao = fk.CreateTargetModSkill{
  name = "os_ex__paoxiao",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill(self.name) and skill.trueName == "slash_skill"
      and scope == Player.HistoryPhase then
      return 999
    end
  end,
  distance_limit_func = function(self, player, skill, scope)
    return player:hasSkill(self.name) and skill.trueName == "slash_skill" and player:usedCardTimes("slash", Player.HistoryPhase) > 0 and 999 or 0
  end,
}
os_ex__paoxiao:addRelatedSkill(os_ex__paoxiaoAudio)

local os_ex__xuhe = fk.CreateTriggerSkill{
  name = "os_ex__xuhe",
  anim_type = "offensive",
  events = {fk.CardUseFinished, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return player:hasSkill(self.name) and
        data.card.name == "jink" and data.toCard and data.toCard.trueName == "slash" and
        data.responseToEvent and data.responseToEvent.from == player.id and
        not player:isNude()
    else
      if target == player and data.to:getMark("@@os_ex__xuhe-turn") > 0 then
        local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        return parentUseData and (parentUseData.data[1].extra_data or {}).os_ex__xuheUser == player.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return player.room:askForSkillInvoke(player, self.name, data, "#os_ex__xuhe:" .. target.id)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      local choice = room:askForChoice(target, {"os_ex__xuhe_dmg", "os_ex__xuhe_next"}, self.name, "#os_ex__xuhe-ask:" .. player.id)
      if choice == "os_ex__xuhe_dmg" then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      else
        room:setPlayerMark(target, "@@os_ex__xuhe-turn", 1)
        room:setPlayerMark(player, "_os_ex__xuhe-turn", 1)
      end
    else
      data.damage = data.damage + 2
      room:setPlayerMark(data.to, "@@os_ex__xuhe-turn", 0)
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os_ex__xuhe-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "_os_ex__xuhe-turn", 1)
    data.extra_data = data.extra_data or {}
    data.extra_data.os_ex__xuheUser = player.id
  end,
}

os_ex__zhangfei:addSkill(os_ex__paoxiao)
os_ex__zhangfei:addSkill(os_ex__xuhe)

Fk:loadTranslationTable{
  ["os_ex__zhangfei"] = "界张飞",
  ["os_ex__paoxiao"] = "咆哮",
  [":os_ex__paoxiao"] = "锁定技，①你使用【杀】无次数限制。②若你于当前阶段使用过【杀】，则你于此阶段使用【杀】无距离限制。",
  ["os_ex__xuhe"] = "虚吓",
  [":os_ex__xuhe"] = "当你使用的【杀】被一名角色的【闪】抵消后，你可令其选择一项：1. 你对其造成1点伤害；2. 当本回合你使用的下一张牌对其造成伤害时，伤害+2。",

  ["#os_ex__xuhe"] = "你想对 %src 发动技能“虚吓”吗？",
  ["os_ex__xuhe_dmg"] = "受到其造成的1点伤害",
  ["os_ex__xuhe_next"] = "本回合其使用的下一张牌对你伤害+2",
  ["#os_ex__xuhe-ask"] = "%src 对你发动“虚吓”，请选择一项",
  ["@@os_ex__xuhe-turn"] = "虚吓 伤害+2",
}

return extension
