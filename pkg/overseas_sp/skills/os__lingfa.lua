local os__lingfa = fk.CreateSkill {
  name = "os__lingfa"
}

Fk:loadTranslationTable{
  ['os__lingfa'] = '令法',
  ['@os__lingfa'] = '令法',
  ['#os__lingfa_use'] = '令法',
  ['#os__lingfa-discard'] = '令法：弃置一张牌，否则受到 %dest 造成的1点伤害',
  ['#os__lingfa-give'] = '令法：交给 %dest 一张牌，否则受到其造成的1点伤害',
  [':os__lingfa'] = '每轮开始时，若当前轮数不大于2，你可令第X项效果对所有有牌的其他角色生效（X为当前轮数）：1. 当使用【杀】时，弃置一张牌，否则你对其造成1点伤害；2. 当使用【桃】结算结束后，交给你一张牌，否则你对其造成1点伤害。若当前轮数大于2，则你失去此技能，获得〖治暗〗。',
  ['$os__lingfa1'] = '吾明令在此，汝何以犯之？',
  ['$os__lingfa2'] = '法不阿贵，绳不挠曲！',
}

os__lingfa:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(skill.name) then return false end
    local room = player.room
    local num = room:getBanner("RoundCount")
    if num <= 2 then
      local targets = table.map(
        table.filter(room:getOtherPlayers(player, false), function(p)
          return (not p:isNude())
        end),
        Util.IdMapper
      )
      if #targets == 0 then return false end
      return true
    elseif num > 2 then
      if table.every(room:getOtherPlayers(player, false), function(p)
        return not p:hasSkill(skill.name)
      end) then
        table.forEach(room.alive_players, function(p)
          room:setPlayerMark(p, "@os__lingfa", 0)
        end)
      end
      room:handleAddLoseSkills(player, "os__zhian|-os__lingfa", nil)
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local mark = room:getBanner("RoundCount") == 1 and "slash" or "peach"
    table.forEach(table.filter(room:getOtherPlayers(player, false), function(p)
      return (not p:isNude())
    end), function(p)
        room:setPlayerMark(p, "@os__lingfa", mark)
      end)
  end,
})

os__lingfa:addEffect(fk.CardUsing, {
  mute = true,
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(skill.name) then return false end
    return target:getMark("@os__lingfa") == "slash" and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("os__lingfa")
    room:notifySkillInvoked(player, "os__lingfa")
    room:doIndicate(player.id, { target.id })
    local cids = room:askToDiscard(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = skill.name,
      cancelable = true,
      prompt = "#os__lingfa-discard::" .. player.id
    })
    if #cids == 0 then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = skill.name,
      }
    end
  end,
})

os__lingfa:addEffect(fk.CardUseFinished, {
  mute = true,
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(skill.name) then return false end
    return target:getMark("@os__lingfa") == "peach" and data.card.name == "peach"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("os__lingfa")
    room:notifySkillInvoked(player, "os__lingfa")
    room:doIndicate(player.id, { target.id })
    local cids = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = skill.name,
      cancelable = true,
      prompt = "#os__lingfa-give::" .. player.id
    })
    if #cids > 0 then
      room:moveCardTo(cids[1], Player.Hand, player, fk.ReasonGive, skill.name, nil, false)
    else
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = skill.name,
      }
    end
  end,
})

return os__lingfa
