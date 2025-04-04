local osJifa = fk.CreateSkill {
  name = "os__jifa"
}

Fk:loadTranslationTable{
  ['os__jifa'] = '冀筏',
  ['#os__jifa-choice'] = '冀筏：选择本次“退幻”时保留的技能',
  ['os_if_huan__caoang'] = '幻曹昂',
  ['os_if__caoang'] = '幻曹昂',
  [':os__jifa'] = '锁定技，当你进入濒死状态时，你减X点体力上限（X为你上次发动〖赴曦〗时选择的项数），选择此次“退幻”时保留〖煌烛〗或〖离渊〗，然后<a href=>“退幻”</a>并将体力回复至体力上限。',
  ['$os__jifa1'] = '往昔如水旧新事，身赴黄夕又经年。',
  ['$os__jifa2'] = '淯水川流如斯，难尽昔日扰攘。',
}

osJifa:addEffect(fk.EnterDying, {
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(osJifa.name) and player.dying
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local x = player:getMark(osFuxi.name)
    if x > 0 then
      room:changeMaxHp(player, -x)
      if player.dead then return false end
    end

    x = player.maxHp - player.hp
    if x > 0 then
      room:recover({
        who = player,
        num = x,
        recoverBy = player,
        skillName = osJifa.name,
      })
      if player.dead then return false end
    end
    local choices = {}
    if player:hasSkill(osHuangzhu, true) then
      table.insert(choices, osHuangzhu.name)
    end
    if player:hasSkill(osLiyuan, true) then
      table.insert(choices, osLiyuan.name)
    end
    local skills = ""
    if #choices == 2 then
      table.removeOne(choices, room:askToChoice(player, {
        choices = choices,
        skill_name = osJifa.name,
        prompt = "#os__jifa-choice",
        detailed = true
      }))
      skills = "-" .. choices[1] .. "|"
    end
    room:handleAddLoseSkills(player, skills .. "-os__jifa|os__chihui|os__fuxi", nil, true, false)
    if player.general == "os_if_huan__caoang" then
      room:setPlayerProperty(player, "general", "os_if__caoang")
    end
    if player.deputyGeneral == "os_if_huan__caoang" then
      room:setPlayerProperty(player, "deputyGeneral", "os_if__caoang")
    end
  end,
})

return osJifa
