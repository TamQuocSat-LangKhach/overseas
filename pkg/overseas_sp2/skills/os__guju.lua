local os__guju = fk.CreateSkill {
  name = "os__guju"
}

Fk:loadTranslationTable{
  ['os__guju'] = '骨疽',
  ['@@os__puppet'] = '傀',
  ['@os__bingzhao'] = '秉诏',
  ['os__bingzhao'] = '秉诏',
  ['os__bingzhao_draw'] = '令其额外摸一张牌',
  [':os__guju'] = '锁定技，当有“傀”的角色受到伤害后，你摸一张牌。',
  ['$os__guju1'] = '你还没有见过真正的恐惧。',
  ['$os__guju2'] = '这些，你就感到害怕了吗？'
}

os__guju:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player)
    return target:getMark("@@os__puppet") > 0 and player:hasSkill(skill.name) and not target.dead
  end,
  on_use = function(self, event, target, player)
    local num = 1
    local room = player.room
    if target.kingdom == player:getMark("@os__bingzhao") and player:hasSkill("os__bingzhao") then
      if room:askToChoice(target, { choices = {"os__bingzhao_draw", "Cancel"}, skill_name = skill.name, prompt = "#os__bingzhao-ask:" .. player.id }) ~= "Cancel" then
        num = 2
      end
    end
    player:drawCards(num, skill.name)
    room:addPlayerMark(player, "@" .. skill.name, num)
  end,
})

return os__guju
