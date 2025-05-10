local jifa = fk.CreateSkill {
  name = "os__jifa",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__jifa"] = "冀筏",
  [":os__jifa"] = "锁定技，当你进入濒死状态时，你减X点体力上限（X为你上次发动〖赴曦〗时选择的项数），"..
  "选择此次“退幻”时保留〖煌烛〗或〖离渊〗，然后<a href='os_tuihuan_caoang'>“退幻”</a>并将体力回复至体力上限。",

  ["os_tuihuan_caoang"] = "变身为表形态：<br>"..
  "<b>炽灰</b>：其他角色的回合开始时，你可以废除一个装备栏，选择：1.弃置其区域里的一张牌；"..
  "2.将牌堆里的一张对应副类别的牌置入其装备区。若如此做，你失去1点体力，摸X张牌（X为你已损失的体力值且至多为2）。<br>"..
  "<b>赴曦</b>：持恒技，当你进入濒死状态时，或你的装备栏均被废除后，你可以选择一至两项，然后<a href='os_ruhuan_caoang'>“入幻”</a>"..
  "并将体力回复至体力上限：<br>1.获得一个额外回合；<br>2.此次“入幻”时保留〖炽灰〗；<br>3.将手牌摸至X张（X为你的体力上限且至多为5）；<br>"..
  "4.恢复所有装备栏（你的装备栏均被废除时方可选择此项）。",

  ["#os__jifa-choice"] = "冀筏：选择本次“退幻”时保留的技能",

  ["$os__jifa1"] = "往昔如水旧新事，身赴黄夕又经年。",
  ["$os__jifa2"] = "淯水川流如斯，难尽昔日扰攘。",
}

jifa:addEffect(fk.EnterDying, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jifa.name) and player.dying
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getMark("os__fuxi")
    if x > 0 then
      room:changeMaxHp(player, -x)
      if player.dead then return false end
    end

    if player:isWounded() then
      room:recover{
        who = player,
        num = player.maxHp - player.hp,
        recoverBy = player,
        skillName = jifa.name,
      }
      if player.dead then return end
    end
    local choices = {}
    if player:hasSkill("os__huangzhu", true) then
      table.insert(choices, "os__huangzhu")
    end
    if player:hasSkill("os__liyuan", true) then
      table.insert(choices, "os__liyuan")
    end
    local skills = ""
    if #choices == 2 then
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = jifa.name,
        prompt = "#os__jifa-choice",
        detailed = true,
      })
      table.removeOne(choices, choice)
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

return jifa
