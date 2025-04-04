local os__chenglong = fk.CreateSkill {
  name = "os__chenglong"
}

Fk:loadTranslationTable{
  ['os__chenglong'] = '成龙',
  ['os__protect'] = '荫',
  ['#os__chenglong-choice'] = '成龙：选择并获得至多两个技能',
  [':os__chenglong'] = '觉醒技，一名角色的结束阶段，若你已执行过〖慈荫〗的所有选项，你获得武将牌上所有“荫”，然后失去〖慈荫〗，从四张蜀势力或群势力武将牌中选择并获得至多两个描述中含有“【杀】”或“【闪】”的技能（觉醒技、限定技、使命技、主公技除外）。',
  ['$os__chenglong1'] = '这次，换孩儿来保护母亲！',
  ['$os__chenglong2'] = '儿虽年幼，亦当立丈夫之志！'
}

os__chenglong:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(os__chenglong.name) and
      target.phase == Player.Finish and
      player:usedSkillTimes(os__chenglong.name, Player.HistoryGame) == 0
  end,
  can_wake = function (self, event, target, player, data)
    return player:getMark("_os__ciyin_choice") == "allDone"
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:obtainCard(player, player:getPile("os__protect"), true, fk.ReasonPrey, player.id, os__chenglong.name)
    if player.dead then return end
    room:handleAddLoseSkills(player, "-os__ciyin")
    if player.dead then return end
    local kingdoms = {"shu", "qun"}
    local generals, skillList = {}, {}
    local index = 1
    while #generals < 4 and index <= #room.general_pile do
      local g = room.general_pile[index]
      if (table.contains(kingdoms, Fk.generals[g].kingdom) or table.contains(kingdoms, Fk.generals[g].subkingdom)) then
        local skills = table.filter(Fk.generals[g]:getSkillNameList(false), function(s) return
          Fk.skills[s].frequency < Skill.Limited and (string.find(Fk:getDescription(s, "zh_CN"), "【杀】") or string.find(Fk:getDescription(s, "zh_CN"), "【闪】"))
        end)
        if #skills > 0 then
          table.insert(generals, table.remove(room.general_pile, index))
          table.insert(skillList, skills)
        else
          index = index + 1
        end
      else
        index = index + 1
      end
    end
    local choice = {}
    if #generals == 0 then return false else choice = {skillList[1]} end
    if #generals > 0 then
      local result = player.room:askToCustomDialog(player, {
        skill_name = os__chenglong.name,
        qml_path = "packages/tenyear/qml/ChooseGeneralSkillsBox.qml",
        extra_data = {generals, skillList, 1, 2, "#os__chenglong-choice", false}
      })
      if result ~= "" then
        choice = json.decode(result)
      end
      room:handleAddLoseSkills(player, table.concat(choice, "|"), nil)
      room:returnToGeneralPile(generals, "bottom")
    end
  end
})

return os__chenglong
