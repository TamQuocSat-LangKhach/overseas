local os__yujue = fk.CreateSkill {
  name = "os__yujue"
}

Fk:loadTranslationTable{
  ['os__yujue'] = '鬻爵',
  ['os__yujue_others&'] = '鬻爵',
  ['#os__yujue-invoke'] = '你想对 %dest 发动技能“鬻爵”吗？',
  ['os__yujue_discard'] = '弃置攻击范围内的一名角色的一张牌',
  ['os__yujue_obtain'] = '使用下一张牌时获得一张同类型的牌',
  ['#os__yujue-target'] = '鬻爵：选择攻击范围内的一名角色，弃置其一张牌',
  ['@@os__yujue_obtain'] = '鬻爵拿牌',
  ['#os__yujue_do_obtain'] = '鬻爵',
  [':os__yujue'] = '①其他角色的出牌阶段，其可交给你任意张牌（每阶段至多两张）。②你的回合外，你每获得其他角色的一张牌，你可令其选择一项：1. 弃置攻击范围内的一名其他角色的一张牌；2. 使用下一张牌时获得一张同类型的牌。（每名角色每回合每项限一次）',
  ['$os__yujue1'] = '财物交足，官位任取。',
  ['$os__yujue2'] = '卖官鬻爵，取财之道。',
}

os__yujue:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  attached_skill_name = "os__yujue_others&",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(os__yujue.name) or player.phase ~= Player.NotActive then return false end
    for _, move in ipairs(data) do
      local from = move.from and player.room:getPlayerById(move.from) or nil
      if move.to == player.id and from and move.toArea == Card.PlayerHand then
        if from:getMark("_os__yujue-turn") < 3 then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, move in ipairs(data) do
      if not table.contains(targets, move.from) and move.from then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insert(targets, move.from)
          end
        end
      end
    end
    room:sortPlayersByAction(targets)
    for _, target_id in ipairs(targets) do
      if not player:hasSkill(os__yujue.name) then break end
      local skill_target = room:getPlayerById(target_id)
      if skill_target and not skill_target.dead and skill_target:getMark("_os__yujue-turn") < 3 and (skill_target:getMark("_os__yujue-turn") < 2 or table.find(room.alive_players, function(p)
        return not p:isNude() and skill_target:inMyAttackRange(p)
      end)) then
        self:doCost(event, skill_target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = os__yujue.name,
      prompt = "#os__yujue-invoke::"..target.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    --local choices = {"os__yujue_discard", "os__yujue_obtain"}
    local choices = {}
    local mark = target:getMark("_os__yujue-turn")
    local availableTargets
    if mark == 3 then return false end
    if mark ~= 1 then
      availableTargets = table.map(
        table.filter(room.alive_players, function(p)
          return not p:isNude() and target:inMyAttackRange(p)
        end),
        Util.IdMapper
      )
      if #availableTargets > 0 then table.insert(choices, "os__yujue_discard") end
    end
    if mark ~= 2 then table.insert(choices, "os__yujue_obtain") end
    if #choices == 0 then return false end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = os__yujue.name
    })
    if choice == "os__yujue_discard" then
      local to = room:askToChoosePlayers(target, {
        targets = availableTargets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__yujue-target",
        skill_name = os__yujue.name,
        cancelable = false
      })
      to = room:getPlayerById(to[1])
      local card = room:askToChooseCard(target, {
        target = to,
        flag = "he",
        skill_name = os__yujue.name
      })
      room:throwCard(card, os__yujue.name, to, target)
      room:addPlayerMark(target, "_os__yujue-turn")
    else
      room:addPlayerMark(target, "@@os__yujue_obtain") --还没做！
      room:addPlayerMark(target, "_os__yujue-turn", 2)
    end
  end,
})

local os__yujue_do_obtain = fk.CreateSkill {
  name = "#os__yujue_do_obtain"
}

os__yujue_do_obtain:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@os__yujue_obtain") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@@os__yujue_obtain")
    local cids = room:getCardsFromPileByRule(".|.|.|.|.|" .. data.card:getTypeString())
    if #cids > 0 then
      room:obtainCard(player, cids[1], false, fk.ReasonPrey)
    end
  end,
})

return os__yujue, os__yujue_do_obtain
