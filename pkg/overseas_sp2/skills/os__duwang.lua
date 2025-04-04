local os__duwang = fk.CreateSkill {
  name = "os__duwang"
}

Fk:loadTranslationTable{
  ['os__duwang'] = '独往',
  ['os__duwang_obtain_xiayong'] = '获得〖狭勇〗',
  ['os__duwang_upgrade_yanshi'] = '复原并修改〖延势〗',
  ['#os__duwang-invoke'] = '你可以发动〖独往〗，选择至多三名其他角色并摸X+1张牌（X为选择的角色数），<br/>然后令这些角色依次将一张牌当【决斗】对你使用',
  ['os__xiayong'] = '狭勇',
  ['@@os__yanshiUp'] = '延势 已升级',
  ['os__yanshih'] = '延势',
  ['#os__duwang-duel'] = '独往：将一张牌当【决斗】对 %dest 使用',
  [':os__duwang'] = '①出牌阶段开始时，你可选择至多三名其他角色并摸X+1张牌（X为选择的角色数），然后令这些角色依次将一张牌当【决斗】对你使用。②<a href=>使命技</a>，准备阶段，你的上个回合你使用【决斗】与成为【决斗】目标的次数之和不小于4（若游戏人数小于4则改为3）。成功：你选择一项：1.获得〖狭勇〗；2.复原并修改〖延势〗。完成前：当你处于濒死状态时，其他角色不能对你使用【桃】。',
  ['$os__duwang1'] = '阿瞒聚众来犯，吾一人可挡万敌！',
  ['$os__duwang2'] = '勇绝河北，吾足以一柱擎天！',
}

os__duwang:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Quest,
  can_trigger = function (self, event, target, player)
    return target == player and player:hasSkill(os__duwang) and (player.phase == Player.Play or
      (player.phase == Player.Start and player:getMark("_os__duwang") > 0 and player:getQuestSkillState(os__duwang.name) ~= "succeed"))
  end,
  on_cost = function (self, event, target, player)
    local room = player.room
    if player.phase == Player.Start then
      event:setCostData(self, room:askToChoice(player, {
        choices = {"os__duwang_obtain_xiayong", "os__duwang_upgrade_yanshi"},
        skill_name = os__duwang.name,
      }))
      return true
    else
      local tos = room:askToChoosePlayers(player, {
        targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
        min_num = 1,
        max_num = 3,
        prompt = "#os__duwang-invoke",
        skill_name = os__duwang.name,
      })
      if #tos > 0 then
        event:setCostData(self, {tos = tos})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player)
    local room = player.room
    if player.phase == Player.Start then
      room:updateQuestSkillState(player, os__duwang.name, true)
      room:updateQuestSkillState(player, os__duwang.name, false)
      local choice = event:getCostData(self)
      if choice == "os__duwang_obtain_xiayong" then
        room:handleAddLoseSkills(player, "os__xiayong")
      else
        room:setPlayerMark(player, "@@os__yanshiUp", 1)
        player:setSkillUseHistory("os__yanshih", 0, Player.HistoryGame)
      end
    else
      local tos = event:getCostData(self).tos ---@type integer[]
      local num = #tos
      player:drawCards(num + 1, os__duwang.name)
      if player.dead then return end
      local card = Fk:cloneCard("duel")
      card.skillName = os__duwang.name
      for _, pid in ipairs(tos) do
        local to = room:getPlayerById(pid)
        if not (to.dead or player.dead or to:isNude()) then
          local cards = {}
          for _, id in ipairs(to:getCardIds("he")) do
            card:clearSubcards()
            card:addSubcard(id)
            if to:canUseTo(card, player, { bypass_times = true, bypass_distances = true }) then
              table.insert(cards, id)
            end
          end
          if #cards > 0 then
            cards = table.concat(cards, ",")
            local card = room:askToCards(to, {
              min_num = 1,
              max_num = 1,
              pattern = ".|.|.|.|.|.|" .. cards,
              prompt = "#os__duwang-duel::" .. player.id,
              skill_name = os__duwang.name,
            })
            room:useVirtualCard("duel", card, to, player, os__duwang.name, true)
          end
        end
      end
    end
  end,
})

os__duwang:addEffect(fk.TurnEnd, {
  can_trigger = function (self, event, target, player)
    return target == player and player:hasSkill(os__duwang) and player:getQuestSkillState(os__duwang.name) ~= "succeed"
  end,
  on_trigger = function (self, event, target, player)
    local room = player.room
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if turn_event == nil then return false end
    local end_id = turn_event.id
    local num = #room.players < 4 and 3 or 4
    if #room.logic:getEventsByRule(GameEvent.UseCard, num, function (e)
      local use = e.data[1]
      return use.card.trueName == "duel" and (use.from == player.id or table.contains(TargetGroup:getRealTargets(use.tos), player.id))
    end, end_id) == num then
      room:setPlayerMark(player, "_os__duwang", 1)
    end
  end,
})

local os__duwang_prohibit = fk.CreateSkill {
  name = "#os__duwang_prohibit"
}

os__duwang_prohibit:addEffect('prohibit', {
  is_prohibited = function (self, from, to, card)
    return card.trueName == "peach" and to:hasSkill(os__duwang) and to:getQuestSkillState(os__duwang.name) ~= "succeed" and from ~= to
  end,
})

return os__duwang
