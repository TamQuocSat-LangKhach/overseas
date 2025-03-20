local os__pingting = fk.CreateSkill {
  name = "os__pingting"
}

Fk:loadTranslationTable{
  ['os__pingting'] = '娉婷',
  ['#os__pingting-put'] = '娉婷：将一张牌置于你的武将牌上（称为“星舞”）',
  ['os__dance'] = '星舞',
  [':os__pingting'] = '锁定技，①每轮开始时或当其他角色于你回合内进入濒死状态时，你摸一张牌，然后将一张牌置于武将牌上（称为“星舞”）。②若你有“星舞”，你拥有〖天香〗和〖流离〗。',
  ['$os__pingting1'] = '哼，我才不怕你呢~',
  ['$os__pingting2'] = '替我挡着吧~',
}

os__pingting:addEffect(fk.RoundStart, {
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return player:hasSkill(skill.name) and (event == fk.RoundStart or (event == fk.EnterDying and player.phase ~= Player.NotActive and target ~= player))
  end,
  on_use = function(self, event, target, player)
    player:drawCards(1, skill.name)
    if not player:isNude() then
      local cid = player.room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skill.name,
        prompt = "#os__pingting-put",
      })[1]
      player:addToPile("os__dance", cid, true, skill.name)
    end
  end,
})

os__pingting:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.to and move.to == player.id and move.toArea == Card.PlayerSpecial and move.specialName == "os__dance"
        and #player:getPile("os__dance") > 0 then
        return true
      elseif move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromSpecialName == "os__dance" and #player:getPile("os__dance") == 0 then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player)
    local skills = (#player:getPile("os__dance") > 0 and player:hasSkill(skill.name, true)) and "tianxiang|liuli" or "-tianxiang|-liuli"
    player.room:handleAddLoseSkills(player, skills, skill.name, false, true)
  end,
})

os__pingting:addEffect(fk.AcquireSkill, {
  on_acquire = function (skill, player, is_start)
    local skills = (#player:getPile("os__dance") > 0 and player:hasSkill(skill.name, true)) and "tianxiang|liuli" or "-tianxiang|-liuli"
    player.room:handleAddLoseSkills(player, skills, skill.name, false, true)
  end,
})

os__pingting:addEffect(fk.LoseSkill, {
  on_lose = function (skill, player, is_death)
    local skills = (#player:getPile("os__dance") > 0 and player:hasSkill(skill.name, true)) and "tianxiang|liuli" or "-tianxiang|-liuli"
    player.room:handleAddLoseSkills(player, skills, skill.name, false, true)
  end,
})

return os__pingting
