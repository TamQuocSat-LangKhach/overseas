local os__cuorui = fk.CreateSkill {
  name = "os__cuorui"
}

Fk:loadTranslationTable{
  ['os__cuorui'] = '挫锐',
  ['@@os__cuorui'] = '挫锐',
  ['#os__cuorui_dmg-ask'] = '挫锐：你可摸 %arg 张牌，废除判定区，然后可以选择一名其他角色，对其造成1点伤害',
  ['#os__cuorui-ask'] = '挫锐：你可摸 %arg 张牌，废除判定区',
  ['#os__cuorui-target'] = '挫锐：你可对一名其他角色造成1点伤害',
  [':os__cuorui'] = '限定技，准备阶段开始时，你可将手牌摸至X张（X为全场最大的手牌数，至多摸五张），废除判定区。若你发动过〖挫锐〗，你可选择一名其他角色，对其造成1点伤害。',
  ['$os__cuorui1'] = '区区乌合之众，如何困得住我？！',
  ['$os__cuorui2'] = '今日就让你见识见识老牛的厉害！',
}

os__cuorui:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player)
    return player == target and player:hasSkill(os__cuorui.name) and
      player.phase == Player.Start and 
      player:usedSkillTimes(os__cuorui.name, Player.HistoryGame) < 1 and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:getHandcardNum() > player:getHandcardNum()
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local num = player:getHandcardNum()
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if p:getHandcardNum() > num then
        num = p:getHandcardNum()
      end
    end
    num = math.min(num - player:getHandcardNum(), 5)
    event:setCostData(self, num)
    return room:askToSkillInvoke(player, {
      skill_name = os__cuorui.name,
      prompt = player:getMark("@@os__cuorui") > 0 and "#os__cuorui_dmg-ask:::" .. num or "#os__cuorui-ask:::" .. num
    })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:drawCards(event:getCostData(self), os__cuorui.name)
    if player.dead then return end
    room:abortPlayerArea(player, {Player.JudgeSlot})
    room:addPlayerMark(player, "@@os__cuorui")
    if player:getMark("@@os__cuorui") > 1 and not player.dead then
      local victim = room:askToChoosePlayers(player, {
        targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#os__cuorui-target",
        skill_name = os__cuorui.name
      })
      if #victim > 0 then victim = room:getPlayerById(victim[1]) end
      room:damage{
        from = player,
        to = victim,
        damage = 1,
        skillName = os__cuorui.name,
      }
    end
  end,
})

return os__cuorui
