local os__zongquan = fk.CreateSkill{
  name = "os__zongquan"
}

Fk:loadTranslationTable{
  ['os__zongquan'] = '纵权',
  ['#os__zongquan-invoke'] = '你可对一名角色发动〖纵权〗',
  ['#os__zongquan-discard'] = '纵权：请弃置 %arg 张牌',
  ['#os__zongquan-obtain'] = '纵权：你令一名角色获得%arg',
  [':os__zongquan'] = '准备阶段或结束阶段，你可以选择一名角色，然后你进行判定：若结果为红色，你令其摸一张牌；若结果为黑色，你令其弃置一张牌；若你本次与上一次发动〖纵权〗所选择的目标角色相同但结果颜色不同，则改为摸/弃置三张牌。若如此做，你令一名角色获得判定牌。',
  ['$os__zongquan1'] = '大权不可旁落，且由老夫暂领。',
  ['$os__zongquan2'] = '再立大魏新政，诏天下怀魏之人。',
}

os__zongquan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(skill.name) and target == player and (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_cost = function (skill, event, target, player)
    local tos = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os__zongquan-invoke",
      skill_name = skill.name
    })
    if #tos > 0 then
      event:setCostData(skill, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill).tos[1])
    local judge = {
      who = player,
      reason = skill.name,
      pattern = ".|.|heart,diamond",
    }
    room:judge(judge)
    local card = judge.card
    if not to.dead then
      local record = player:getTableMark("_os__zongquan")
      local num = (record[1] == to.id and record[2] ~= card.color and
      card.color ~= Card.NoColor and record[2] ~= Card.NoColor) and 3 or 1
      record = {to.id, card.color}
      room:setPlayerMark(player, "_os__zongquan", record)
      if card.color == Card.Red then
        to:drawCards(num)
      elseif card.color == Card.Black and not to:isNude() then
        room:askToDiscard(to, {
          min_num = num,
          max_num = num,
          include_equip = true,
          skill_name = skill.name,
          prompt = "#os__zongquan-discard:::" .. num
        })
      end
    end
    if room:getCardArea(card) == Card.Processing and not player.dead then
      local tar = room:askToChoosePlayers(player, {
        targets = table.map(player.room.alive_players, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#os__zongquan-obtain:::" .. card:toLogString(),
        skill_name = skill.name
      })[1]
      room:obtainCard(tar, card, true, fk.ReasonPrey, player.id, skill.name)
    end
  end,
})

return os__zongquan
