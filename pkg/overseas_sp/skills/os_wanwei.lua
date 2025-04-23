local osWanwei = fk.CreateSkill {
  name = "os__wanwei"
}

Fk:loadTranslationTable{
  ["os__wanwei"] = "挽危",
  [":os__wanwei"] = "每回合限一次，当体力值最低的角色受到伤害时，若其不为你，你可以防止此伤害，然后失去1点体力；" ..
  "若其为你或你的体力上限全场最高，则你可在本回合结束阶段开始时获得牌堆底牌并展示之（若此牌能使用，则你使用之）。",

  ["os__wanwei_defend"] = "防止此伤害，你失去1点体力",
  ["os__wanwei_get"] = "本回合结束阶段开始时，获得牌堆底牌并展示之，若能使用则使用之",
  ["os__wanwei_both"] = "防止此伤害，并于本回合结束阶段开始时，获得牌堆底牌",
  ["#os__wanwei-ask"] = "你可选择是否发动“挽危”",
  ["#os__wanwei-use"] = "挽危：请使用获得的 %arg",

  ["$os__wanwei1"] = "梁、沛之间，无子廉焉有今日？",
  ["$os__wanwei2"] = "汝兄弟皆为手足，何必苦苦相逼？"
}

osWanwei:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(osWanwei.name) and
      table.every(player.room:getOtherPlayers(target, false), function(p)
        return p.hp >= target.hp
      end) and
      player:usedSkillTimes(osWanwei.name) < 1
  end,
  on_cost = function(self, event, target, player, data)
    ---@type string
    local skillName = osWanwei.name
    local choices = {}
    if target ~= player then
      table.insert(choices, "os__wanwei_defend")
    end
    if
      target == player or
      table.every(player.room:getOtherPlayers(player, false), function(p)
        return p.maxHp <= player.maxHp
      end)
    then
      table.insert(choices, "os__wanwei_get")
    end
    if #choices == 2 then
      choices = { "os__wanwei_both" }
    end
    table.insert(choices, "Cancel")
    local choice = player.room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = skillName,
        prompt = "#os__wanwei-ask",
      }
    )
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self)

    room:doIndicate(player, { target })
    if choice ~= "os__wanwei_get" then
      data:preventDamage()
      room:loseHp(player, 1, osWanwei.name)
    end
    if choice ~= "os__wanwei_defend" then
      room:setPlayerMark(player, "_os__wanwei_get-turn", 1)
    end
  end,
})

osWanwei:addEffect(fk.EventPhaseStart, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and player:getMark("_os__wanwei_get-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osWanwei.name
    local room = player.room
    local cids = player:drawCards(1, skillName, "bottom")
    player:showCards(cids)
    local card = Fk:getCardById(cids[1])
    if not table.contains(player:getCardIds("h"), cids[1]) then
      return false
    end

    if player:canUse(card, { bypass_times = true }) then
      room:askToUseRealCard(
        player,
        {
          pattern = cids,
          prompt = "#os__wanwei-use:::" .. card:toLogString(),
          skill_name = skillName,
          cancelable = false,
        }
      )
    end
  end,
})

return osWanwei
