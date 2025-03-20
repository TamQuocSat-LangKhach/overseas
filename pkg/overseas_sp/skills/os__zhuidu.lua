local os__zhuidu = fk.CreateSkill {
  name = "os__zhuidu"
}

Fk:loadTranslationTable{
  ['os__zhuidu'] = '追妒',
  ['os__zhuidu_damage'] = '对其造成1点伤害',
  ['os__zhuidu_discard'] = '弃置其装备区的一张牌',
  ['beishui_os__zhuidu'] = '背水：你弃置一张牌',
  [':os__zhuidu'] = '出牌阶段限一次，你可选择一名受伤的其他角色并选择一项：1.你对其造成1点伤害；2.你弃置其装备区的一张牌；若其为女性角色，则你可背水：（在其执行完所有可执行的选项后）弃置一张牌。',
  ['$os__zhuidu1'] = '到了阴司地府，你们也别想好过！',
  ['$os__zhuidu2'] = '髡头墨面，杀人诛心。',
}

os__zhuidu:addEffect('active', {
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(os__zhuidu.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and Fk:currentRoom():getPlayerById(to_select):isWounded()
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choices = {"os__zhuidu_damage"}
    if #target:getCardIds(Player.Equip) > 0 then table.insert(choices, "os__zhuidu_discard") end
    if target:isFemale() and not player:isNude() then table.insert(choices, "beishui_os__zhuidu") end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = os__zhuidu.name
    })
    if choice ~= "os__zhuidu_discard" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = os__zhuidu.name,
      }
    end
    if choice ~= "os__zhuidu_damage" and #target:getCardIds(Player.Equip) > 0 then
      local card = room:askToChooseCard(player, {
        target = target,
        flag = "e",
        skill_name = os__zhuidu.name
      })
      room:throwCard(card, os__zhuidu.name, target, player)
    end
    if choice == "beishui_os__zhuidu" and not player.dead then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = os__zhuidu.name,
        cancelable = false
      })
    end
  end,
})

return os__zhuidu
