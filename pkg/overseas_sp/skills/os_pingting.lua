local osPingting = fk.CreateSkill {
  name = "os__pingting",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__pingting"] = "娉婷",
  [":os__pingting"] = "锁定技，①每轮开始时或当其他角色于你回合内进入濒死状态时，你摸一张牌，" ..
  "然后将一张牌置于武将牌上（称为“星舞”）。②若你有“星舞”，你拥有〖天香〗和〖流离〗。",

  ["#os__pingting-put"] = "娉婷：将一张牌置于你的武将牌上（称为“星舞”）",

  ["$os__pingting1"] = "哼，我才不怕你呢~",
  ["$os__pingting2"] = "替我挡着吧~",
}

local osPingtingOnUse = function(self, event, target, player, data)
  ---@type string
  local skillName = osPingting.name
  player:drawCards(1, skillName)
  if not player:isNude() then
    local cid = player.room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skillName,
        prompt = "#os__pingting-put",
        cancelable = false,
      }
    )[1]
    player:addToPile("os__dance", cid, true, skillName, player)
  end
end

osPingting:addEffect(fk.RoundStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osPingting.name)
  end,
  on_use = osPingtingOnUse,
})

osPingting:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osPingting.name) and player.phase ~= Player.NotActive and target ~= player
  end,
  on_use = osPingtingOnUse,
})

local osPingtingHandleSkills = function(skill, player)
  ---@type string
  local skillName = osPingting.name
  local skills = (#player:getPile("os__dance") > 0 and player:hasSkill(skillName, true)) and "tianxiang|liuli" or "-tianxiang|-liuli"
  player.room:handleAddLoseSkills(player, skills, skillName, false, true)
end

osPingting:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if
        move.to and move.to == player and
        move.toArea == Card.PlayerSpecial and
        move.specialName == "os__dance"
        and #player:getPile("os__dance") > 0
      then
        return true
      elseif move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromSpecialName == "os__dance" and #player:getPile("os__dance") == 0 then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    osPingtingHandleSkills(self, player)
  end,
})

osPingting:addAcquireEffect(osPingtingHandleSkills)

osPingting:addLoseEffect(osPingtingHandleSkills)

return osPingting
