local os__budao = fk.CreateSkill {
  name = "os__budao"
}

Fk:loadTranslationTable{
  ['os__budao'] = '布道',
  ['os__zhouhu'] = '咒护',
  ['os__zuhuo'] = '阻祸',
  ['os__fengqi'] = '丰祈',
  ['os__huangjin'] = '黄巾',
  ['os__zhouzu'] = '咒诅',
  ['os__didao'] = '地道',
  ['#os__budao-ask'] = '布道：选择一个技能获得，然后你可令一名其他角色获得相同技能并交给你一张牌',
  ['#os__budao-target'] = '布道：你可令一名其他角色获得〖%arg〗并交给你一张牌',
  ['#os__budao-card'] = '布道：交给 %src 一张牌',
  [':os__budao'] = '限定技，准备阶段开始时，你可减1点体力上限，回复1点体力，从布道技能库的随机三个技能中选择一个获得，然后你可令一名其他角色获得相同技能并交给你一张牌。<br/><font color=>#"<b>布道技能库</b>"<br/><b>咒护</b>: 出牌阶段结束时，你可弃置一张红色手牌并施法：回复X点体力。<br/><b>咒护</b>: 出牌阶段结束时，你可弃置一张红色手牌，选择一名角色并施法：令其回复X点体力。<br/><b>阻祸</b>: 出牌阶段结束时，你可弃置一张非基本牌并施法：防止你受到的下X次伤害。<br/><b>丰祈</b>: 出牌阶段结束时，你可弃置一张黑色手牌，选择一名角色并施法：其摸2X张牌。<br/><b>黄巾</b>: 锁定技，当你成为【杀】的目标时，你判定：若结果点数与此【杀】点数差值不大于1，则此【杀】对你无效。<br/>（暂无）<b>鬼门</b>: 锁定技，当你因弃置而失去黑桃牌后，你判定：若结果点数与你弃置的其中一张黑桃牌点数差值不大于1，则对一名其他角色造成2点雷电伤害。<br/><b>咒诅</b>: 出牌阶段限一次，你可选择一名其他角色并施法：令其弃置X张牌，若牌数不足则全部弃置并对其造成1点雷电伤害。<br/><b>地道</b>: 当一名角色的判定牌生效前，你可打出一张牌替换之，若与原判定牌颜色相同，你摸一张牌。</font>',
  ['$os__budao1'] = '得天之力，从天之道。',
  ['$os__budao2'] = '黄天大道，泽及苍生。',
}

os__budao:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__budao.name) and
      player.phase == Player.Start and player:usedSkillTimes(os__budao.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:recover({ who = player, num = 1, recoverBy = player, skillName = os__budao.name})
    local os__budaoSkills = table.random({"os__zhouhu", "os__zuhuo", "os__fengqi", "os__huangjin", "os__zhouzu", "os__didao"}, 3)
    local skillName = room:askToChoice(player, {
      choices = os__budaoSkills,
      skill_name = os__budao.name,
      prompt = "#os__budao-ask",
      detailed = true
    })
    room:handleAddLoseSkills(player, skillName, nil, true, false)
    local pid = room:askToChoosePlayers(player, {
      targets = table.map(
        table.filter(room:getOtherPlayers(player, false), function(p)
          return (not p:isNude())
        end),
        Util.IdMapper
      ),
      min_num = 1,
      max_num = 1,
      prompt = "#os__budao-target:::" .. skillName,
      skill_name = os__budao.name,
    })
    if #pid > 0 then
      local target = room:getPlayerById(pid[1])
      room:handleAddLoseSkills(target, skillName, nil, true, false)
      if not target:isNude() then
        local c = room:askToCards(target, {
          min_num = 1,
          max_num = 1,
          prompt = "#os__budao-card:" .. player.id
        })[1]
        room:moveCardTo(c, Player.Hand, player, fk.ReasonGive, os__budao.name, nil, false)
      end
    end
  end,
})

return os__budao
