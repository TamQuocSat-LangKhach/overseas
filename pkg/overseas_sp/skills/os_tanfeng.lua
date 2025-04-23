local osTanfeng = fk.CreateSkill {
  name = "os__tanfeng",
}

Fk:loadTranslationTable{
  ["os__tanfeng"] = "探锋",
  [":os__tanfeng"] = "准备阶段开始时，你可弃置一名其他角色区域内的一张牌，然后其可选择一项：" ..
  "1. 受到你造成的1点火焰伤害，其令你跳过一个阶段；2. 将一张牌当【杀】对你使用。",

  ["#os__tanfeng-ask"] = "探锋：你可选择一名其他角色，弃置其区域内的一张牌",
  ["os__tanfeng_damaged"] = "受到其造成的1点火焰伤害，令其跳过一个阶段",
  ["os__tanfeng_slash"] = "将一张牌当【杀】对其使用",
  ["#os__tanfeng-react"] = "探锋：你可对 %src 选择一项",
  ["#os__tanfeng-skip"] = "探锋：令 %src 跳过此回合的一个阶段",
  ["#os__tanfeng-slash"] = "探锋：将一张牌当【杀】对 %src 使用",

  ["$os__tanfeng1"] = "探敌薄防之地，夺敌不备之间。",
  ["$os__tanfeng2"] = "探锋之锐，以待进取之机。",
}

osTanfeng:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return
      target == player and
      player:hasSkill(osTanfeng.name) and
      player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local availableTargets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isAllNude()
    end)
    if #availableTargets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = availableTargets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__tanfeng-ask",
        skill_name = osTanfeng.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
     ---@type string
     local skillName = osTanfeng.name
    local room = player.room
    local to = event:getCostData(self)
    if to:isAllNude() then
      return false
    end

    local cid = room:askToChooseCard(
      player,
      {
        target = to,
        flag = "hej",
        skill_name = skillName,
      }
    )
    room:throwCard(cid, skillName, to, player)
    local choices = { "os__tanfeng_damaged", "Cancel" }
    local slash = Fk:cloneCard("slash")
    slash.skillName = skillName
    if not to:isNude() and to:canUseTo(slash, player, { bypass_distances = true, bypass_times = true }) then
      table.insert(choices, 2, "os__tanfeng_slash")
    end
    local choice = room:askToChoice(
      to,
      {
        choices = choices,
        skill_name = skillName,
        prompt = "#os__tanfeng-react:" .. player.id,
      }
    )
    if choice == "os__tanfeng_damaged" then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = skillName,
      }
      if not to.dead then
        local phase = { "phase_judge", "phase_draw", "phase_play", "phase_discard", "phase_finish" }
        player:skip(table.indexOf(phase, room:askToChoice(
          to,
          {
            choices = phase,
            skill_name = skillName,
            prompt = "#os__tanfeng-skip:" .. player.id,
          }
        )) + 2)
      end
    elseif choice == "os__tanfeng_slash" then
      local cids = room:askToCards(
        to,
        {
          min_num = 1,
          max_num = 1,
          pattern = nil,
          prompt = "#os__tanfeng-slash:" .. player.id,
          skill_name = skillName,
        }
      )
      if #cids > 0 then
        room:useVirtualCard("slash", cids, to, player, skillName)
      end
    end
  end,
})

return osTanfeng
