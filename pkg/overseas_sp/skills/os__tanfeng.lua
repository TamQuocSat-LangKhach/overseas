local os__tanfeng = fk.CreateSkill {
  name = "os__tanfeng"
}

Fk:loadTranslationTable{
  ['os__tanfeng'] = '探锋',
  ['#os__tanfeng-ask'] = '探锋：你可选择一名其他角色，弃置其区域内的一张牌',
  ['os__tanfeng_damaged'] = '受到其造成的1点火焰伤害，令其跳过一个阶段',
  ['os__tanfeng_slash'] = '将一张牌当【杀】对其使用',
  ['#os__tanfeng-react'] = '探锋：你可对 %src 选择一项',
  ['#os__tanfeng-skip'] = '探锋：令 %src 跳过此回合的一个阶段',
  ['#os__tanfeng-slash'] = '探锋：将一张牌当【杀】对 %src 使用',
  [':os__tanfeng'] = '准备阶段开始时，你可弃置一名其他角色区域内的一张牌，然后其可选择一项：1. 受到你造成的1点火焰伤害，其令你跳过一个阶段；2. 将一张牌当【杀】对你使用。',
  ['$os__tanfeng1'] = '探敌薄防之地，夺敌不备之间。',
  ['$os__tanfeng2'] = '探锋之锐，以待进取之机。',
}

os__tanfeng:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__tanfeng.name) and
      player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local availableTargets = table.map(
      table.filter(room:getOtherPlayers(player, false), function(p)
        return not p:isAllNude()
      end),
      Util.IdMapper
    )
    if #availableTargets == 0 then return false end
    local target = room:askToChoosePlayers(player, {
      targets = availableTargets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__tanfeng-ask",
      skill_name = os__tanfeng.name,
      cancelable = true,
    })
    if #target > 0 then
      event:setCostData(skill, target[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local target = room:getPlayerById(event:getCostData(skill))
    if target:isAllNude() then return false end
    local cid = room:askToChooseCard(player, {
      target = target,
      flag = "hej",
      skill_name = os__tanfeng.name,
    })
    room:throwCard({cid}, os__tanfeng.name, target, player)
    local choices = {"os__tanfeng_damaged", "Cancel"}
    local slash = Fk:cloneCard("slash")
    slash.skillName = os__tanfeng.name
    if not target:isNude() and not target:prohibitUse(slash) and not target:isProhibited(slash, player) then table.insert(choices, 2, "os__tanfeng_slash") end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = os__tanfeng.name,
      prompt = "#os__tanfeng-react:" .. player.id,
    })
    if choice == "os__tanfeng_damaged" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = os__tanfeng.name,
      }
      if not target.dead then
        local phase = {"phase_judge", "phase_draw", "phase_play", "phase_discard", "phase_finish"}
        player:skip(table.indexOf(phase, room:askToChoice(target, {
          choices = phase,
          skill_name = os__tanfeng.name,
          prompt = "#os__tanfeng-skip:" .. player.id,
        })) + 2)
      end
    elseif choice == "os__tanfeng_slash" then
      local cids = room:askToCards(target, {
        min_num = 1,
        max_num = 1,
        pattern = nil,
        prompt = "#os__tanfeng-slash:" .. player.id,
        skill_name = os__tanfeng.name,
      })
      if #cids > 0 then
        room:useVirtualCard("slash", cids, target, player, os__tanfeng.name)
      end
    end
  end,
})

return os__tanfeng
